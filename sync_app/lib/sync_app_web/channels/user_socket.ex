defmodule SyncAppWeb.UserSocket do
  @moduledoc """
  WebSocket entry point; routes doc:* channels to DocChannel.
  """
  use Phoenix.Socket

  channel "doc:*", SyncAppWeb.DocChannel

  @impl true
  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  @impl true
  def id(_socket), do: nil
end
