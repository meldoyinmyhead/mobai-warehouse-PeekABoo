# MobAI WMS - Technical Architecture & Offline Capabilities

## 1. System Architecture

The MobAI WMS follows a **Client-Server Architecture** extended for **Offline-First** capabilities.

- **Mobile App (Client)**: Built with **Flutter**. Uses **Bloc/Cubit** for state management and **Drift (SQLite)** for local persistence.
- **Backend (Server)**: Built with **FastAPI**. Handles business logic, AI orchestration, and security.
- **Database**: **PostgreSQL** (via Supabase) serves as the primary source of truth.
- **AI Engine**: Integrated directly into the backend for Forecasting and Optimization, with extensibility for microservices.

### Data Flow
1.  **Online**: Mobile App <--> FastAPI <--> PostgreSQL.
    *   *Note*: The app listens to **Supabase Realtime** channels to receive instant updates (e.g., new task assigned).
2.  **Offline**: Mobile App <--> SQLite (Drift).
    *   Reads are served from the local cache.
    *   Writes are queued in a local `sync_queue` table.

---

## 2. Offline & Real-Time Strategy

### 2.1 Capability Per Role

| Role | Online | Offline |
|------|--------|---------|
| **Employee** | Real-time task receipt, map navigation, stock updates. | **View assigned tasks**, **View AI optimized map**, **Complete tasks**. (Actions are queued). |
| **Supervisor** | Approve AI orders, Monitor operations live. | **View cached pending reviews**. Approvals are queued. |
| **Admin** | Full Management. | Limited (View cached data). |

### 2.2 Sync Mechanism (`SyncService`)

The `SyncService` is a singleton in the Flutter app responsible for data consistency.

1.  **Connectivity Monitoring**: Listens to network status changes.
2.  **Push (Client -> Server)**:
    *   When connectivity is restored, the service reads the `sync_queue`.
    *   It iterates through pending actions (`COMPLETE_TASK`, `AI_OVERRIDE`) and sends them to the Backend API.
    *   On success, the local queue item is marked `synced`.
3.  **Pull (Server -> Client)**:
    *   Periodically (every 45s) and on Reconnect, the app fetches the latest Tasks and Orders from the Backend `GET` endpoints.
    *   Local SQLite tables (`LocalTasks`, `LocalPendingReviews`) are updated ("Upsert") to match the server state.

### 2.3 Conflict Resolution

*   **Strategy**: **Server Wins** (with Optimistic Locking).
*   **Implementation**:
    *   Critical resources (Stock) have a `version` column.
    *   If an offline action tries to modify an outdated version, the server rejects it.
    *   The app will receive a fresh state on the next Pull, effectively reverting the invalid local change (or flagging it for review).
*   **Data Loss Prevention**: Pending actions are **never deleted** from the queue until the server confirms receipt (HTTP 200).

---

## 3. Database Schema Overview

### Core Entities
-   **Entrepots, Etages, Emplacements**: Hierarchical warehouse structure.
-   **Produits**: Catalog with SKU, dimensions, and weights.
-   **StockParEmplacement**: Link table tracking quantity per product per location.

### Operational Entities
-   **PreparationOrder**: Demand forecast; parent of Picking Orders.
-   **PickingOrder**: Assignable task with optimized route.
-   **PickingOrderStop**: Individual steps in a route (Source -> Dest).
-   **Transactions**: Ledger for all stock movements (Receipt, Transfer, etc.).

### AI & Audit
-   **HistoriqueDemande**: Training data for forecasting.
-   **AIOverride**: Logs where humans disagreed with AI (RLHF data source).
-   **AuditLog**: Immutable security log of all critical actions.

---

## 4. AI Integration

The AI is embedded in the workflow, not just a side feature:

1.  **Forecasting**: Running nightly (Scheduler), it creates `PreparationOrders` for the next day.
2.  **Human Review**: Supervisors see these orders. They can *Approve* (triggers picking generation) or *Override* (adjust quantities).
3.  **Optimization**: When Approved, the backend runs the **Route Optimizer** (TSP) to create efficient `PickingOrders` for employees.
4.  **Execution**: Employees follow the AI-generated path on their mobile device.

---

## 5. Security

-   **Authentication**: Bearer Token (JWT-like UUIDs for MVP).
-   **RBAC**:
    *   **Admin**: Schema control, User management.
    *   **Supervisor**: Approvals, Overrides.
    *   **Employee**: Task execution only.
