defmodule SyncAppWeb.DocChannel do
  @moduledoc """
  CRDT sync channel for documents: pushes init_sync on join, handles new_event and save_snapshot.
  """
  use SyncAppWeb, :channel
  alias SyncApp.DocStore

  @impl true
  def join("doc:" <> doc_id, _payload, socket) do
    doc_state = DocStore.get_state(doc_id)
    send(self(), {:send_init_sync, doc_state})
    {:ok, assign(socket, :doc_id, doc_id)}
  end

  @impl true
  def handle_info({:send_init_sync, doc_state}, socket) do
    push(socket, "init_sync", doc_state)
    {:noreply, socket}
  end

  @impl true
  def handle_in("new_event", %{"event" => event_payload}, socket) do
    doc_id = socket.assigns.doc_id
    DocStore.append_event(doc_id, event_payload)
    broadcast_from!(socket, "new_event", %{event: event_payload})
    {:reply, :ok, socket}
  end

  @impl true
  def handle_in("save_snapshot", %{"snapshot" => snapshot, "last_seq" => seq}, socket) do
    doc_id = socket.assigns.doc_id
    DocStore.save_snapshot(doc_id, snapshot, seq)
    {:reply, :ok, socket}
  end
end
