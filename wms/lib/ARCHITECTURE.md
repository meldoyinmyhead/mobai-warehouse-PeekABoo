# WMS Flutter App – Architecture (lib/)

Everything lives under `lib/`. This doc describes the layout and where to find things.

## Top-level layout

- **`main.dart`** – App entry, Supabase init, dependency injection, `MultiBlocProvider`, router.
- **`core/`** – Shared infrastructure (theme, routes, DI, database, sync, widgets).
- **`features/`** – Role/domain modules: auth, admin, supervisor, logistics, inventory.

## core/

| Path | Purpose |
|------|--------|
| **app_config.dart** | Backend URL, Supabase URL/anon key. |
| **di/dependency_injection.dart** | GetIt registration: DB, SyncService, repositories, cubits. |
| **database/app_database.dart** | Drift DB: LocalTasks, LocalInventory, SyncQueue, LocalPendingReviews, LocalAdminCache. |
| **services/sync_service.dart** | Push queue to FastAPI, pull tasks + supervisor pending reviews; connectivity listener; 45s periodic sync. |
| **repositories/offline_repository.dart** | Local task + sync-queue helpers for employee offline. |
| **routes/app_router.dart** | Named routes and `generateRoute`. |
| **theme/app_theme.dart** | Colors, text styles. |
| **widgets/layout/** | Shared layout: admin_bottom_bar, admin_app_bar. |
| **widgets/task_views/** | Picking/storage task UI. |
| **utils/** | Helpers (e.g. snackbar). |
| **data/repositories/** | Base repository impl (legacy). |

## features/

Each feature follows **presentation / data** under one folder.

### auth

- **data**: user_model, auth_repository (login, session, getCurrentUserId).
- **presentation**: landing, onboarding, role_selection, login, cubits (AuthCubit). Triggers sync after login/session.

### admin

- **data**: admin_repository (users, warehouses – online fetch + **LocalAdminCache** when offline), warehouse_model.
- **presentation**: admin_dashboard_screen, admin_main_screen, user_management, create_new_user_screen, warehouse_config screens, cubits (AdminUserCubit, WarehouseCubit). Uses **admin_bottom_bar** from core/widgets/layout.

### supervisor

- **data**: ai_review_repository (pending reviews from API + **LocalPendingReviews** when offline; approve/override queue to SyncQueue), flag_repository, location_point_model.
- **presentation**: supervisor_dashboard_screen, ai_review_screen, warehouse_map_screen, flag_management_screen, cubits (AiReviewCubit, DashboardCubit, FlagCubit). AI review: online → API + cache; offline → read cache; overrides with justification stored in SyncQueue.

### logistics (employee tasks)

- **data**: task_repository (FastAPI employee/tasks + **LocalTasks** cache + SyncQueue for complete), task_model, picking/delivery/transfer repositories (SyncQueue for offline actions).
- **presentation**: employee_all_tasks_screen, employee_task_detail_screen, task_detail_screen, employee_task_cubit.

### inventory

- **data**: receipt_repository, transfer_repository, entrepot_repository, emplacement_repository.
- **presentation**: employee_dashboard_screen (with connectivity + offline banner), employee_main_screen, receipt_cubit.

## Local DB (Drift) – roles

| Table | Used by | Purpose |
|-------|--------|--------|
| **LocalTasks** | Employee | Cache of assigned tasks; updated on sync and when completing (then queue if offline). |
| **SyncQueue** | All | Pending actions: COMPLETE_TASK, AI_OVERRIDE, AI_APPROVE, CONFIRM_RECEIPT, etc. Pushed by SyncService when online. |
| **LocalPendingReviews** | Supervisor | Cache of preparation/picking orders pending AI review; filled when online (API + periodic sync) or by AiReviewRepository; read when offline. |
| **LocalAdminCache** | Admin | Cache of users and warehouses (key: `users` \| `warehouses`); read when offline. |
| **LocalInventory** | Optional | Product–location quantity cache. |

## Real-time behaviour

- **No WebSocket on FastAPI.** “Real-time” is implemented by:
  - **Connectivity restored** → run full sync (push queue, pull tasks + supervisor pending reviews).
  - **Periodic sync** every 45s when app is running (SyncService `_periodicSyncTimer`).
  - **After login / session restore** → run sync.
- Optional: Supabase Realtime on `tasks` if you use Supabase for that stream; SyncService still pushes to FastAPI for task completion and overrides.

## Conventions

- **Single source of truth for sync**: FastAPI (`/employee/tasks`, `/supervisor/pending-reviews`, `/ai/log-override`, `/supervisor/.../approve`). SyncService and repositories use `AppConfig.backendUrl`.
- **Naming**: `snake_case` for files; layout widgets in `core/widgets/layout/` (e.g. `admin_bottom_bar.dart`). No duplicate widgets (e.g. only one admin bottom bar).
- **State**: Bloc/Cubit per feature or screen where needed.
