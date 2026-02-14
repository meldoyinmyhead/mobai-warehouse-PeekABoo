# MobAI WMS - Architecture & State Management

## 1. High-Level Architecture

The MobAI WMS is built on a **Clean Architecture** principle, separating concerns into distinct layers: **Presentation** (UI & State), **Domain** (Business Logic - implicit in Repositories/Cubits for this MVP), and **Data** (Repositories, Data Sources).

### Layers
1.  **Presentation Layer (Flutter)**:
    -   **UI**: Widgets/Screens.
    -   **State Management**: `Bloc` / `Cubit` pattern.
2.  **Service Layer (Dependency Injection)**:
    -   `GetIt` service locator (`core/di/dependency_injection.dart`).
3.  **Data Layer**:
    -   **Repositories**: Abstract the data source from the UI.
    -   **Local Data Source**: `Drift` (SQLite) for offline-first capabilities.
    -   **Remote Data Source**: `FastAPI` (REST) and `Supabase` (Realtime/RPC).
    -   **Sync Service**: Bridges Local and Remote data.

---

## 2. State Management (Bloc/Cubit)

We use the **Bloc** library (specifically `Cubit`) to manage state. Cubits expose functions to the UI and emit States.

### Core Cubits

| Cubit | Feature | Responsibility | Data Source |
|-------|---------|----------------|-------------|
| **AuthCubit** | Authentication | Login, User Session, `logUserAction` (Audit). | `AuthRepository` (FastAPI + SharedPreferences) |
| **EmployeeTaskCubit** | Logistics | Fetch tasks, execute tasks (Receipt, Transfer, Picking), offline queuing. | `TaskRepository` (Drift + SyncService) |
| **SupervisorDashboardCubit**| Supervisor | Aggregates stats (pending reviews, flags) for the dashboard. | `AiReviewRepository` + `FlagRepository` |
| **AiReviewCubit** | Supervisor | Fetches AI-generated orders, handles Approve/Override actions. | `AiReviewRepository` |
| **FlagCubit** | Supervisor | Manages operational flags/alerts. | `FlagRepository` |
| **ReceiptCubit** | Inventory | Handles goods receipt (Reception). | `ReceiptRepository` |
| **WarehouseCubit** | Admin | Manage Warehouse, Floor, and Location structure. | `AdminRepository` |
| **AdminUserCubit** | Admin | User management (CRUD). | `AdminRepository` |

### State Flow Example (Task Completion)
1.  **UI**: User clicks "Complete" on `EmployeeTaskDetailScreen`.
2.  **Cubit**: `EmployeeTaskCubit.completeTask(taskId)` is called.
3.  **Repository**: `TaskRepository` updates the local `Drift` database status to `COMPLETED` and adds an entry to `SyncQueue`.
4.  **State Emission**: Cubit emits `EmployeeTaskUpdated` state.
5.  **UI**: Rebuilds to show "Completed" badge.
6.  **Background**: `SyncService` detects the new `SyncQueue` item and pushes it to `FastAPI`.

---

## 3. Dependency Injection (DI)

We use `GetIt` for Service Locator pattern, initialized in `lib/core/di/dependency_injection.dart`.

### Registered Singletons & Factories
-   **AppDatabase**: Singleton for Drift (SQLite).
-   **SharedPreferences**: Singleton for key-value storage (Token).
-   **AuthRepository**: Singleton.
-   **SyncService**: Singleton. Initialized *after* AuthRepo to ensure user context.
-   **Cubits**: Registered as `Factory` (create new instance on demand) to ensure clean state on screen re-entry.

---

## 4. Data Layer & Persistence

### 4.1 Repositories
Repositories are the single source of truth for the app.

-   **Offline-First Repositories** (`TaskRepository`, `AiReviewRepository`):
    -   **Read**: Always read from **Local DB** (Drift).
    -   **Write**: Write to **Local DB** + **SyncQueue**.
    -   **Sync**: `SyncService` populates Local DB from Remote API in the background.

-   **Online-Only Repositories** (`AdminRepository`, `ReceiptRepository`):
    -   Directly call `FastAPI` or `Supabase`. Used for features where offline support is not critical (e.g., Admin setup).

### 4.2 Local Schema (Drift)
Defined in `lib/core/database/tables.dart`:
-   `LocalTasks`: Stores picking orders/tasks.
-   `LocalInventory`: Caches stock levels (snapshots).
-   `SyncQueue`: Stores pending modifications (`action`, `payload`, `status`).

### 4.3 Remote API (FastAPI)
-   **Authentication**: Bearer Token.
-   **Endpoints**: e.g., `/employee/tasks/{id}/complete`, `/ai/log-override`.
-   **Stock Logic**: Handles transactional updates to prevent negative stock (server-side validation).

---

## 5. Sync Strategy (`SyncService`)

The heartbeat of the offline architecture.

1.  **Push (Upstream)**: Use `SyncQueue` table.
    -   Trigger: Connectivity restoration OR immediate if online.
    -   Action: POST to FastAPI.
    -   Result: Mark queue item `synced`.

2.  **Pull (Downstream)**:
    -   Trigger: Periodic timer (45s), App Start, Connectivity restoration.
    -   Action: GET from FastAPI.
    -   Result: `batchInsert` (Upsert) into Drift tables.

This ensures that the **Local DB** eventually converges with the **Server DB**.
