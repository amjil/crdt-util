# crdt-util

A ClojureDart library for **CRDT-based collaborative text editing**, with pure CRDT logic and a Phoenix WebSocket sync client. Use it in Flutter apps (via [ClojureDart](https://github.com/tensegritics/ClojureDart)) for real-time shared documents.

## Project layout

| Path | Description |
|------|-------------|
| `src/crdt/` | Library: `pure.cljd` (CRDT math) and `sync_client.cljd` (Phoenix channel sync) |
| `example/` | Flutter example app: a single CRDT text field that syncs over WebSocket |
| `sync_app/` | Elixir/Phoenix backend: document store + WebSocket channel (see [sync_app/README.md](sync_app/README.md)) |

## Prerequisites

- [ClojureDart](https://github.com/tensegritics/ClojureDart) tooling and Flutter SDK (for the example app)
- Elixir/Phoenix (for the sync backend, if you want real-time sync)

## Quick start

**1. Start the sync backend** (optional; required for multi-device sync):

```bash
cd sync_app
mix setup
mix phx.server
```

Runs at `http://localhost:4000`; WebSocket at `ws://127.0.0.1:4000/socket/websocket`.

**2. Run the Flutter example:**

```bash
cd example
clj -M:cljd flutter run
```

The example connects to the backend, joins channel `doc:default-doc`, and syncs edits via `init_sync` / `new_event`.

## Library usage

Add the library as a local dependency:

```clojure
;; deps.edn
{:deps {crdt-util/crdt-util {:local/root "../path/to/crdt-util"}}
 ...}
```

**Namespaces:**

- **`crdt.pure`** — Pure CRDT operations (no I/O):
  - `make-id`, `make-node` — construct IDs and nodes
  - `insert-node`, `delete-node` — update document list
  - `process-incoming-event` — apply one remote event (handles out-of-order)
  - `apply-snapshot` — apply server snapshot + pending events
  - `render-text`, `get-node-id-at` — project state to visible text / index

- **`crdt.sync-client`** — Phoenix sync (stateful):
  - `app-state` — atom holding `{:doc [] :pending-events [] :site _ :seq _}`
  - `connect-socket! [doc-id]` — connect WebSocket, join `doc:<doc-id>`, returns channel
  - `push-local-insert! [channel char origin-id?]` — local insert, push to server, returns new node ID
  - `push-local-delete! [channel target-id]` — local delete, push to server

**Example pattern** (as in `example/src/my_app/crdt_editor.cljd`):

1. Connect: `(sync/connect-socket! doc-id)` and subscribe to channel messages.
2. On `init_sync`: call `(crdt/apply-snapshot state snapshot events)` and update UI from `(crdt/render-text doc)`.
3. On `new_event`: call `(crdt/process-incoming-event state event)` and refresh UI.
4. On user typing: compute diff (e.g. prefix/suffix), call `push-local-delete!` for deletions and `push-local-insert!` (chaining returned IDs as `origin`) for insertions.

## Backend protocol

The client expects a Phoenix channel with:

- **Topic:** `doc:<doc_id>`
- **Server → client:** `init_sync` (snapshot + events on join), `new_event` (broadcast)
- **Client → server:** `new_event` (single op), `save_snapshot` (optional, for GC)

See [sync_app/README.md](sync_app/README.md) for the full backend API and setup.

## License

[MIT](LICENSE)
