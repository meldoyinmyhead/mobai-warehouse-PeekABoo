# MobAI WMS – Hackathon Deliverables & Gap Analysis

This document organizes what you have, what’s wrong or redundant, how you score against the **evaluation criteria**, and what to fix or add for submission.

---

## 1. Architecture Overview

### 1.1 Backend (server/)

- **Stack**: FastAPI + SQLAlchemy, PostgreSQL (Supabase) or SQLite fallback.
- **Entry**: `main.py` – single app, no `/api/v1` prefix; base URL is root (e.g. `http://localhost:8000/`).
- **DB**: `database.py` (Supabase Postgres or SQLite), `models.py` (entities), `schemas.py` (Pydantic).
- **AI**: In-process in `main.py` (forecast, prescribe-storage, optimize-picking); optional external AI via `services/ai_client.py` (calls `http://localhost:8001/api/v1` – different service).
- **Scheduler**: `scheduler.py` – daily forecast job; uses `models.Role` and `PreparationOrderLine` (fixed in code).

**Important**: `API_Documentation.md` and `AI_Technical_Documentation.md` refer to **`/api/v1`** and a separate AI service. Your **real** API is in `main.py` with **no** `/api/v1` prefix. Align docs or add a v1 router.

### 1.2 Mobile (wms/) – Flutter

- **State**: Bloc/Cubit.
- **Local DB**: Drift (SQLite) – `core/database/app_database.dart`: `LocalTasks`, `LocalInventory`, `SyncQueue`.
- **Sync**: `SyncService` – on reconnect pushes from `SyncQueue` and pulls into `LocalTasks`. Uses **Supabase** (RPCs + Realtime on `tasks`).
- **Dual backend**:
  - **FastAPI** (`AppConfig.backendUrl`): auth (`/auth/login`), users, entrepots, employee tasks (`/employee/tasks/:id`, `/employee/tasks/:id/complete`), audit, AI endpoints.
  - **Supabase**: init in `main.dart`, Realtime subscription, and SyncService RPCs (`process_task_completion`, `sync_pull`, `process_receipt`, etc.). If Supabase DB is not the same as FastAPI’s DB, sync and real-time will be inconsistent.

**Real-time / “CDC”**: You use **Supabase Realtime** (`.from('tasks').stream(...)`) to push changes into the app and write into Drift. There is no CDC on the FastAPI backend itself; task completion in the app goes to FastAPI, while SyncService pushes to Supabase RPCs. Clarify which is source of truth (FastAPI vs Supabase) and document it.

---

## 2. Files & Folders to Delete or Fix

### 2.1 Server – One-off / debug scripts (safe to delete or move to `scripts/`)

These are not part of the running app; they clutter the repo and can confuse judges:

| File | Purpose | Action |
|------|---------|--------|
| `server/check_tasks.py` | One-off: create sample tasks for one employee | Delete or move to `scripts/` |
| `server/debug_env.py` | Print env keys | Delete or move to `scripts/` |
| `server/test_login_response.py` | One-off login test | Delete or move to `scripts/` |
| `server/check_roles.py` | Inspect roles | Move to `scripts/` if needed |
| `server/check_users.py` | Inspect users | Move to `scripts/` |
| `server/check_passwords.py` | Inspect passwords | Move to `scripts/` |
| `server/check_auth_users.py` | Auth check | Move to `scripts/` |
| `server/inspect_db.py` | DB inspection | Move to `scripts/` |
| `server/inspect_constraints.py` | Constraints | Move to `scripts/` |
| `server/inspect_xlsx.py` | Excel inspection | Move to `scripts/` |
| `server/debug_auth.py` | Auth debug | Move to `scripts/` |
| `server/reset_users.py` | Reset users | Move to `scripts/` |
| `server/create_admin.py` | Create admin user | Move to `scripts/` |
| `server/create_employee.py` | Create employee | Move to `scripts/` |
| `server/create_supervisor.py` | Create supervisor | Move to `scripts/` |
| `server/elevate_admin.py` | Elevate admin | Move to `scripts/` |
| `server/update_supervisor_name.py` | One-off update | Move to `scripts/` |
| `server/add_column.py` | Schema change | Move to `scripts/` |
| `server/drop_constraint.py` | Schema change | Move to `scripts/` |
| `server/apply_sql.py` | Apply SQL | Move to `scripts/` |
| `server/apply_missing_schema.py` | Schema | Move to `scripts/` |
| `server/fix_db.py` | DB fix | Move to `scripts/` |
| `server/check_sync_objects.py` | Sync check | Move to `scripts/` |
| `server/sync_auth_profiles.py` | Auth sync | Move to `scripts/` |
| `server/migrate_flags.py` | Flags migration | Move to `scripts/` |
| `server/seed_flags.py` | Seed flags | Keep or move to `scripts/` |
| `server/seed_tasks.py` | Seed tasks | Keep or move to `scripts/` |
| `server/seed.py` | Seed data | Keep (or move to `scripts/`) |
| `server/seed_from_excel.py` | Seed from Excel | Move to `scripts/` |
| `server/seed_data_csv.py` | Seed from CSV | Move to `scripts/` |
| `server/seed_supervisor_data.py` | Seed supervisor | Move to `scripts/` |
| `server/create_tasks_table.py` | Create table | Move to `scripts/` |
| `server/setup_db.py` | DB setup | Keep if used for first-time setup, else move to `scripts/` |

**Recommendation**: Create `server/scripts/` and move all one-off/debug/seed/migration scripts there. Keep in `server/` only: `main.py`, `models.py`, `schemas.py`, `database.py`, `scheduler.py`, `services/` (e.g. `ai_client.py`).

### 2.2 Documentation mismatches

| File | Issue | Action |
|------|--------|--------|
| `API_Documentation.md` | Describes `/api/v1`, `GET /health`, `POST /forecast`, etc. Your API has no prefix and different paths (e.g. `POST /ai/forecast`). | Rewrite to match `main.py` (see Section 5 below) or add `/api/v1` in FastAPI and redirect. |
| `AI_Technical_Documentation.md` | Refers to `ai/config/settings.py` and `/api/v1` endpoints. | Update to describe in-process AI in `main.py` and optional `services/ai_client.py`; remove or fix references to non-existent paths. |

### 2.3 WMS – Duplicate / placeholder files

| File | Issue | Action |
|------|--------|--------|
| `adminBottomBar.dart` (core/widgets) | Duplicate of `admin_bottom_bar.dart` (different casing). | Prefer one (e.g. `admin_bottom_bar.dart`), delete the other, fix imports. |
| `create_user.dart` vs `create_new_user_screen.dart` | Two “create user” screens. | Use one flow; remove or redirect the other. |
| `i_admin_dashboard.dart`, `i_supervisor_approval.dart`, `i_employee_task_view.dart` | “i_” often = interface/placeholder. | Ensure they’re used; if empty or redundant, remove. |
| `admin_placeholders.dart` | Likely placeholder. | Replace with real content or remove. |

### 2.4 Empty or near-empty files

- Run in repo root:  
  `Get-ChildItem -Recurse -File | Where-Object { $_.Length -eq 0 }`  
  (PowerShell). Delete or fill any source files that are 0 bytes.

---

## 3. Evaluation Criteria vs Your Current Work

Weights from the brief:

- Functional Completeness **20%**
- Stability and Performance **7.5%**
- Technical Architecture and Code Quality **15%**
- **Offline Capability and Real-Time Operations 30%**
- Backend and Data Handling **10%**
- AI Integration **10%**
- Fidelity to Design or Specification **7.5%**

### 3.1 Functional Completeness (20%)

| Area | SRS / FRs | Current state | Gap |
|------|-----------|----------------|-----|
| Auth & roles | FR-1–FR-3: Auth, RBAC, ADMIN/SUPERVISOR/EMPLOYEE | Login via FastAPI; roles in backend and app | Mostly OK; ensure role enforced on every protected endpoint. |
| Admin user management | FR-4 | Admin repo + create user screens | OK. |
| Supervisor validate AI | FR-5, FR-7, FR-8 | AI review screen, override logging in backend | Ensure override calls `/ai/log-override` and justification is required. |
| Employee sees only validated orders | FR-6 | Employee gets tasks from FastAPI; no “override” visibility | OK if tasks are only approved ones. |
| Warehouse CRUD | FR-10–FR-17 | Entrepots, etages, emplacements in main.py | OK. |
| SKU & inventory | FR-20–FR-27 | Produits, StockParEmplacement; no negative stock check in API visible | Add server-side check to prevent negative stock; log movements. |
| Chariot | FR-30–FR-34 | Model exists; no CRUD in main.py | Add chariot CRUD if required. |
| Orders | FR-40–FR-47 | Command, Preparation, Picking, overrides | Preparation/Picking from main.py; overrides logged. |
| Operations | FR-50–FR-57 | Receipt/Transfer/Picking/Delivery | Partially in backend; app uses Supabase RPCs for some. Unify with FastAPI or document clearly. |
| Offline & sync | FR-70–FR-71 | Drift + SyncQueue + SyncService | Document clearly; ensure no data loss (NFR-9). |

**Edge cases (judges check)**: Invalid input, no internet, permission denial, API errors. Add validation and clear error messages; offline path should show “saved locally, will sync” and retry.

### 3.2 Stability and Performance (7.5%)

- Avoid crashes/freezes: test on device, handle nulls and network errors.
- Smooth navigation: ensure no duplicate or missing routes.
- Loading times: cache where appropriate (you already cache tasks in Drift).
- Consistent behavior: same flow online vs offline (degraded but clear).

### 3.3 Technical Architecture and Code Quality (15%)

- **Modular structure**: WMS has features (admin, auth, logistics, supervisor, inventory); server has main, models, schemas, services. Good.
- **State management**: Cubit/Bloc. Good.
- **Separation of concerns**: Repositories vs Cubits vs UI. Good.
- **Scalability**: Document that FastAPI can scale horizontally; mobile uses local DB to reduce server load.
- **Clean code**: Remove dead code and one-off scripts from root server folder (move to `scripts/`).

### 3.4 Offline Capability and Real-Time Operations (30% – highest weight)

What judges check:

| Requirement | Your implementation | Gap |
|-------------|----------------------|-----|
| Offline capabilities per role (Employee / Supervisor / Admin) | Employee: tasks from Drift, queue completions; Supervisor/Admin: not clearly defined | **Document** exactly what each role can do offline (e.g. Employee: view tasks, complete, receipt, transfer, delivery; Supervisor: view snapshots, approve when back online; Admin: read-only or limited). |
| Execute operational tasks without internet | Task completion and receipt/transfer/delivery queued in SyncQueue | Ensure all critical actions write to SyncQueue and UI shows “pending sync”. |
| Local data persistence | Drift: LocalTasks, LocalInventory, SyncQueue | OK. |
| Auto sync when connection restored | SyncService.runSync() on connectivity; trigger on reconnect | Ensure connectivity listener actually calls runSync() when going from offline to online. |
| Conflict resolution | No explicit strategy in code | **Define and document**: e.g. server-wins for stock, or last-write-wins with override log. NFR-2: “preserve stock consistency”. |
| No data loss | Queue then push; mark synced only after success | Avoid deleting pending queue items before server confirms. |
| Instant task assignment visibility | Supabase Realtime updates LocalTasks | If source of truth is FastAPI, Realtime may not reflect FastAPI changes unless you mirror to Supabase. **Align** backend (FastAPI vs Supabase) and document. |
| Live monitoring, employee/chariot location, path visualization | Warehouse map / real-time map screens | Implement or mock: last known position, paths; document what is “live” vs cached. |
| Sync latency and reliability | Realtime + periodic pull | Document and test. |

**Action**: Write a short “Offline and real-time” section: what works offline per role, how sync runs, conflict rules, and how “real-time” is achieved (Supabase Realtime + Drift).

### 3.5 Backend and Data Handling (10%)

- Stable API: FastAPI is stable; ensure Supabase RPCs exist if used.
- Error handling: return consistent JSON errors; app shows explicit messages (NFR-8).
- Data persistence: PostgreSQL/SQLite + Drift.
- Auth/session: Token in response; app should store and send it (e.g. header) on each request.
- Consistency: Transactions for stock moves; avoid double-spend.

**Gap**: If app uses both FastAPI and Supabase, document which system owns which data and how they stay in sync (e.g. “FastAPI is source of truth; Supabase Realtime is fed by triggers” or “only Supabase is used for tasks”).

### 3.6 AI Integration (10%)

- Forecasting and optimization are in `main.py` (and optionally `ai_client.py`).
- Judges want: AI features connected and usable, smooth interaction, meaningful contribution, reliable handling of errors.
- **Action**: Ensure mobile calls `/ai/forecast`, `/ai/prescribe-storage`, `/ai/optimize-picking` where applicable; show AI-generated orders and routes in UI; display errors clearly.

### 3.7 Fidelity to Design or Specification (7.5%)

- Screens and navigation: Match SRS flows (Employee: receipt → transfer → picking → delivery; Supervisor: validate AI, monitor; Admin: users, config, audit).
- Implement or stub all main screens; remove or repurpose placeholders.
- Ensure product logic (e.g. overrides require justification, employee sees only validated orders) matches spec.

---

## 4. FR/NFR Quick Checklist

- **FR-1–FR-9**: Auth, RBAC, overrides with justification, logging. ✓ Mostly; enforce on API and document.
- **FR-10–FR-17**: Warehouse/locations. ✓
- **FR-20–FR-27**: SKU, stock, history, no negative stock. Add checks and logging.
- **FR-30–FR-34**: Chariot. Add CRUD if required.
- **FR-40–FR-47**: Orders and overrides. ✓
- **FR-50–FR-57**: Operations atomicity, concurrency, no partial commit. Implement in API.
- **FR-70–FR-71**: Offline + auto sync. ✓ Concept; document and test.
- **NFR-1**: 4h offline. Document and test (e.g. no sync for 4h, then sync).
- **NFR-2**: Conflict resolution preserves stock consistency. Define and document.
- **NFR-3**: 100% traceability. Audit log + stock ledger. ✓
- **NFR-4**: Role enforced server-side. ✓
- **NFR-5**: Concurrency safety. Use transactions and optimistic locking (you have `version` on stock).
- **NFR-6**: Overrides auditable. ✓
- **NFR-7**: UI distinguishes decision vs execution. Supervisor/Admin see AI vs override; Employee does not. ✓
- **NFR-8**: Explicit errors. Add in API and app.
- **NFR-9**: No data loss on sync. Queue + retry. ✓
- **NFR-10**: Historical logs immutable. DB constraints / append-only. ✓

---

## 5. What to Do Before Submission

### 5.1 Code and repo

1. **Fix scheduler**: Already fixed (`Role`, `PreparationOrderLine`).
2. **Move server one-off scripts** to `server/scripts/` (or delete); keep only app + shared scripts.
3. **Align backends**: Either (a) use FastAPI as single source of truth and mirror to Supabase for Realtime, or (b) use only Supabase for tasks and document it. Then make SyncService and TaskRepository consistent (e.g. complete task only via FastAPI, or only via Supabase).
4. **API docs**: Update `API_Documentation.md` to match `main.py`: base URL, list of endpoints (e.g. `POST /auth/login`, `GET /entrepots/`, `POST /ai/forecast`, `GET /employee/tasks/:id`, `POST /employee/tasks/:id/complete`, `POST /ai/log-override`, etc.), and example request/response.
5. **AI doc**: Update `AI_Technical_Documentation.md` to describe in-app AI (main.py + optional ai_client) and remove references to non-existent paths/config.
6. **WMS**: Resolve duplicate files (admin bar, create user); add connectivity listener to trigger sync when back online if not already; show “Offline – will sync when online” and sync status where relevant.

### 5.2 Deliverables required by the brief

- **APK**: Build release/debug APK from `wms/` and submit.
- **UI/UX prototype**: Figma (or similar) – link or attach.
- **User workflows/diagrams**:  
  - Warehouse Employee (Operator)  
  - Warehouse Supervisor  
  - Warehouse Manager / Admin  
- **AI**: Multi-service agent (forecasting + optimization), decision flow diagram, baseline vs your algorithm, technical doc (max 4 pages).
- **Technical document (max 6 pages PDF)** including:
  1. **Backend and DB**: Schema (ERD), main entities, stock movement and logging, auth/roles, API overview, list of endpoints, request/response examples.
  2. **Offline**: Per-role offline capabilities, actions without connectivity, local data, sync triggers and restoration, conflict resolution; **diagram**: offline vs online workflow, sync lifecycle (Local → Queue → Server → Resolution).
  3. **Architecture and state**: 3 lines – architecture style (e.g. Clean/Feature-based), state management (Bloc/Cubit), data flow (Mobile ↔ Backend ↔ AI).
  4. **Repo link**: Public repo URL.

Use this document as the basis for Section 2 (Offline) and Section 3 (Architecture) of that PDF; expand Backend and AI from your code and existing docs.

---

## 6. Summary: Where You’re Off and What to Modify

| Priority | Item | Action |
|----------|------|--------|
| High | Offline & real-time (30%) | Document per-role offline behavior, sync lifecycle, conflict resolution; align FastAPI vs Supabase; ensure sync runs on reconnect. |
| High | API vs docs | Make `API_Documentation.md` match `main.py`; fix `AI_Technical_Documentation.md`. |
| High | Single source of truth | Decide FastAPI vs Supabase for tasks/completions; make SyncService and TaskRepository consistent. |
| Medium | Backend consistency | Ensure stock checks (no negative), audit logs, and role checks on all protected routes. |
| Medium | Clean repo | Move server one-off scripts to `server/scripts/`; remove or merge duplicate/placeholder files in WMS. |
| Medium | Deliverables | Prepare 6-page technical PDF, workflow diagrams, APK, Figma link, AI doc (≤4 pages). |
| Lower | Chariot CRUD | Add if required by spec. |
| Lower | Edge cases | Explicit error messages, offline indicator, permission denial handling. |

Once these are done, you’ll be in good shape for the evaluation criteria and the required deliverables. If you want, I can next (1) create `server/scripts/` and list exact move commands, (2) draft the updated `API_Documentation.md` from `main.py`, or (3) outline the 6-page PDF section-by-section.
