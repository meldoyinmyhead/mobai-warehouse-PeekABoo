# Offline Capability and Real-Time Operations (For Technical PDF)

Use this section in your **6-page technical document** to satisfy the “Offline Functionality Documentation” and “Real-Time” requirements.

---

## Offline Capabilities by Role

| Role | Offline capabilities | Limits |
|------|------------------------|--------|
| **Employee** | View assigned tasks (from local DB), record receipt counts, confirm storage placement, complete picking stops, confirm delivery. All actions are written to a **local sync queue** and applied to the local task/inventory cache so the UI stays consistent. | New task assignments and up-to-date stock levels require connectivity. When back online, queued actions are pushed and latest data is pulled. |
| **Supervisor** | View cached preparation/picking orders and dashboard snapshot (data last synced). Approve/override decisions are **queued** and sent when online. | Live monitoring, real-time employee/chariot positions, and live path visualization require connectivity. |
| **Admin** | View cached user list and warehouse config (read-only from cache). User create/update/delete and system config changes are **queued** and applied when online. | Full audit logs and live AI performance metrics require connectivity. |

## Executable Actions Without Connectivity

- **Employee**: Complete task, complete picking stop, confirm receipt, record transfer, delivery validation/failure.
- **Supervisor**: Approve or override AI (stored locally, pushed on sync).
- **Admin**: (Optional) Create/update user or warehouse (queued).

All such actions insert a record into the **Sync Queue** (action type + JSON payload). No record is removed from the queue until the server confirms success.

## Data Stored Locally During Offline

- **LocalTasks**: Task list (id, type, status, JSON data, sync status, timestamps).
- **LocalInventory**: Product–location–quantity cache (optional, for display).
- **SyncQueue**: Pending actions (action type, payload, timestamp, status, retry count).

Storage: SQLite via Drift in app documents directory (`mobai_wms.sqlite`).

## Sync Triggers and Restoration Logic

1. **On app start**: If online, run full sync (push queue, then pull latest tasks/data).
2. **On connectivity restored**: Listen to connectivity plugin; when switching from none to wifi/mobile, trigger the same sync.
3. **After successful push**: Mark queue item as “synced” only when server returns success (or conflict resolved).
4. **Pull**: After push, call pull endpoint (or Supabase `sync_pull`) and merge results into LocalTasks (and cache) with conflict handling as below.

## Conflict Detection and Resolution Strategy

- **Stock movements**: Server is source of truth. If server rejects a move (e.g. negative stock), mark queue item as failed and surface error to user; do not overwrite server state with local state.
- **Task completion**: First-wins or server-wins. If server already has the task completed, treat as success and mark synced.
- **Overrides**: Always append; no overwrite. Server stores override with justification; conflicts are rare (single writer per order).
- **Goal**: Preserve **stock consistency** (no negative stock, no double-spend). NFR-2 compliant.

## Offline vs Online Workflow Diagram (Conceptual)

```
[OFFLINE]                          [ONLINE]
   |                                   |
   v                                   v
User action --> SyncQueue          User action --> API
   |                                   |
   v                                   v
Update LocalTasks/cache             Update server + LocalTasks/cache
   |                                   |
   v                                   v
Show "Pending sync"                 Show "Synced"
   |                                   |
   +------ Connectivity restored ------+
   |                                   |
   v                                   v
   Push SyncQueue --> Server --> Pull latest --> Update LocalTasks
   |                                   |
   v                                   v
   Mark synced / resolve conflicts
```

## Sync Lifecycle (Local → Queue → Server → Resolution)

1. **Local**: User performs action; app writes to SyncQueue and updates local cache (e.g. task status).
2. **Queue**: Record stays with status “pending” and optional retry count.
3. **Server**: When online, app sends each pending item to the backend (FastAPI or Supabase RPC, per your design).
4. **Resolution**: On 2xx or “CONFLICT” resolved, mark “synced”; on 4xx/5xx or business rule failure, keep “pending” and show error; optionally retry with backoff.
5. **Pull**: After push, fetch latest tasks (and optionally stock) and merge into LocalTasks; resolve duplicates by id and updated_at or version.

## Real-Time Updates

- **Mechanism**: Supabase Realtime subscription on the `tasks` table (or equivalent). On insert/update/delete, the client receives a stream event and updates LocalTasks so the employee sees new or updated tasks without manual refresh.
- **Latency**: Sub-second under normal conditions; depends on Supabase and network.
- **Fallback**: If Realtime is unavailable, periodic pull (e.g. on app resume or every N minutes) can be used; document which mode is used in production.

## Data Validation and Integrity

- Before applying a pulled update to LocalTasks, validate required fields (id, type, status, etc.).
- Before pushing a queued action, validate payload (e.g. task_id, user_id, quantities).
- Server enforces business rules (no negative stock, unique codes, role checks). Client does not overwrite server state on conflict; it surfaces the error and keeps the action in queue or marks it failed.

---

*Copy the above (and adapt table names/endpoints to your actual implementation) into your technical PDF under “Offline Functionality Documentation” and “Real-Time Operations”.*
