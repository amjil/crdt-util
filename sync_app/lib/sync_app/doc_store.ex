defmodule SyncApp.DocStore do
  @moduledoc """
  GenServer for document state storage.
  Stores snapshot and event log per doc_id for CRDT sync.
  In production, use Registry to run a separate process per doc_id.
  """
  use GenServer
  require Logger

  # --- API ---

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, %{}, Keyword.merge([name: __MODULE__], opts))
  end

  @doc "Returns the current snapshot and unmerged events for the document"
  def get_state(doc_id) do
    GenServer.call(__MODULE__, {:get_state, doc_id})
  end

  @doc "Appends a new event to the log"
  def append_event(doc_id, event) do
    GenServer.cast(__MODULE__, {:append_event, doc_id, event})
  end

  @doc "Client reports snapshot and truncates event history"
  def save_snapshot(doc_id, snapshot, last_seq) do
    GenServer.cast(__MODULE__, {:save_snapshot, doc_id, snapshot, last_seq})
  end

  # --- Callbacks ---

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_call({:get_state, doc_id}, _from, state) do
    default_doc = %{snapshot: [], events: [], last_seq: 0}
    doc_state = Map.get(state, doc_id, default_doc)
    {:reply, doc_state, state}
  end

  @impl true
  def handle_cast({:append_event, doc_id, event}, state) do
    default_doc = %{snapshot: [], events: [], last_seq: 0}

    new_state =
      Map.update(state, doc_id, default_doc, fn doc ->
        %{doc | events: doc.events ++ [event]}
      end)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:save_snapshot, doc_id, snapshot, last_seq}, state) do
    Logger.info("Saving snapshot for doc #{doc_id} at sequence #{last_seq}")

    new_state =
      Map.update(state, doc_id, %{}, fn _old_doc ->
        %{snapshot: snapshot, events: [], last_seq: last_seq}
      end)

    {:noreply, new_state}
  end
end
