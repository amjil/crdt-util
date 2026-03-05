# SyncApp — CRDT Sync Backend

Elixir/Phoenix backend for document state storage and WebSocket sync for CRDT collaborative editing. Works with ClojureDart and other frontends.

## Quick Start

```bash
cd sync_app
mix setup
mix phx.server
```

The server runs at `http://localhost:4000` by default.

## WebSocket Connection

- **URL**: `ws://localhost:4000/socket/websocket` (or your production domain)
- **Phoenix default transport**: Use `websocket` and optional `params` to establish the connection

## Channel & Event Protocol

### Joining a Document Channel

- **Topic**: `doc:<doc_id>`, e.g. `doc:room-1`
- **Payload**: Any (no auth enforced currently)

After joining, the server pushes **init_sync** once with the current document state so clients can replay or merge.

### Server → Client

| Event        | Description |
|--------------|-------------|
| `init_sync`  | Sent once after joining. Payload: `%{snapshot: list, events: list, last_seq: number}` for client init/catch-up. |
| `new_event`  | Broadcast when another client produces a new operation. Payload: `%{event: event_payload}`. |

### Client → Server

| Event           | Payload | Description |
|-----------------|---------|-------------|
| `new_event`     | `%{"event" => event_payload}` | Report one local operation; server appends to log and broadcasts to other clients in the same channel. |
| `save_snapshot` | `%{"snapshot" => snapshot, "last_seq" => seq}` | Report a snapshot and truncate this doc’s event log (GC), reducing memory and sync load. |

## Backend Modules

- **SyncApp.DocStore**: GenServer storing `snapshot`, `events`, `last_seq` per `doc_id`; provides `get_state/1`, `append_event/2`, `save_snapshot/3`.
- **SyncAppWeb.UserSocket**: Mounted at `/socket`, routes `doc:*` to DocChannel.
- **SyncAppWeb.DocChannel**: Handles join, `new_event`, `save_snapshot`, and pushes `init_sync` after join.

## Production Notes

- Use a separate GenServer per `doc_id` (e.g. via Registry) to avoid a single process bottleneck.
- Add auth in `UserSocket.connect/3` from `params` or token, and validate document access in `DocChannel.join/3`.
- Persist snapshots and events to a database or object store for recovery and offline sync.

## Integrating with ClojureDart Frontend

Implement the Phoenix Channel protocol (connect to `/socket/websocket`, join `doc:<doc_id>`, listen for `init_sync` / `new_event`, send `new_event` / `save_snapshot`) to sync with this backend.
