# WMS Backend API Documentation

## Overview

REST API for the MobAI Warehouse Management System. Implemented in **FastAPI** (`server/main.py`). No version prefix: all routes are at the **root** of the base URL.

## Base URL

- Local: `http://localhost:8000`
- Replace with your server IP when using the mobile app (e.g. `http://10.80.23.251:8000`).

## Authentication & Security

- **Token**: Login returns a bearer-style token (`mock_token_<uuid>`). Include it in subsequent requests: `Authorization: Bearer <access_token>`.
- **RBAC**: Role-Based Access Control is enforced on sensitive endpoints.
  - **ADMIN**: Full access (Users, Warehouses, Configuration).
  - **SUPERVISOR**: Operational management (Approvals, Overrides).
  - **EMPLOYEE**: Task execution.

---

## Endpoints

### Health / Root

| Method | Path | Description | Roles |
|--------|------|-------------|-------|
| GET | `/` | Service info (message, system, warehouse). | Public |

### Auth

| Method | Path | Description | Roles |
|--------|------|-------------|-------|
| POST | `/auth/login` | Login. Returns `access_token`, `user`. | Public |

### Audit

| Method | Path | Description | Roles |
|--------|------|-------------|-------|
| POST | `/audit/log` | Create audit log. | Authenticated |

### Users

| Method | Path | Description | Roles |
|--------|------|-------------|-------|
| GET | `/users/` | List users. | **ADMIN** |
| POST | `/users/` | Create user. | **ADMIN** |
| PUT | `/users/{user_id}` | Update user. | **ADMIN** |
| DELETE | `/users/{user_id}` | Delete user. | **ADMIN** |

### Warehouses (Entrepots)

| Method | Path | Description | Roles |
|--------|------|-------------|-------|
| GET | `/entrepots/` | List warehouses. | Authenticated |
| POST | `/entrepots/` | Create warehouse. | **ADMIN** |
| PUT | `/entrepots/{entrepot_id}` | Update warehouse. | **ADMIN** |
| DELETE | `/entrepots/{entrepot_id}` | Delete warehouse. | **ADMIN** |

### Floors (Etages)

| Method | Path | Description | Roles |
|--------|------|-------------|-------|
| POST | `/entrepots/{entrepot_id}/etages` | Create floor. | **ADMIN** |
| DELETE | `/etages/{etage_id}` | Delete floor. | **ADMIN** |

### Locations (Emplacements)

| Method | Path | Description | Roles |
|--------|------|-------------|-------|
| GET | `/emplacements/` | List locations. | Authenticated |

### Products & Stock

| Method | Path | Description | Roles |
|--------|------|-------------|-------|
| GET | `/produits/` | List products. | Authenticated |
| GET | `/stock/` | List stock. | Authenticated |

### AI Services

| Method | Path | Description | Roles |
|--------|------|-------------|-------|
| GET | `/ai/available-slots` | Empty slots for storage. | Authenticated |
| GET | `/ai/inventory` | Current inventory for AI. | Authenticated |
| POST | `/ai/forecast` | Generate demand forecast (Prep Order). | Authenticated |
| POST | `/ai/prescribe-storage` | Storage assignment logic. | Authenticated |
| POST | `/ai/optimize-picking` | Generate optimized picking route (TSP). | Authenticated |
| POST | `/ai/log-override` | Log decision override. | **SUPERVISOR**, **ADMIN** |

### Supervisor Operations

| Method | Path | Description | Roles |
|--------|------|-------------|-------|
| GET | `/supervisor/pending-reviews` | Get orders waiting for approval. | Authenticated |
| POST | `/supervisor/preparation-orders/{id}/approve` | Approve Prep Order. | **SUPERVISOR**, **ADMIN** |
| POST | `/supervisor/picking-orders/{id}/approve` | Approve Picking Order. | **SUPERVISOR**, **ADMIN** |

### Employee Tasks

| Method | Path | Description | Roles |
|--------|------|-------------|-------|
| GET | `/employee/tasks/{user_id}` | Pending picking tasks for employee (with stops and map-related fields). | Authenticated |
| POST | `/employee/tasks/{task_id}/complete` | Mark task completed. | Authenticated |

### Scheduler

| Method | Path | Description | Roles |
|--------|------|-------------|-------|
| POST | `/scheduler/trigger-daily` | Manually trigger forecast job. | **ADMIN** |

---

## Request / Response Examples

### Login

**Request**
```http
POST /auth/login
Content-Type: application/json

{
  "email": "admin@mobai.com",
  "password": "password123"
}
```

**Response**
```json
{
  "access_token": "mock_token_<uuid>",
  "token_type": "bearer",
  "user": { "role": "ADMIN", ... }
}
```

### Optimize Picking (AI)

**Request**
```http
POST /ai/optimize-picking
{
  "id_preparation_order": "<uuid>",
  "available_employees": ["<uuid>"]
}
```

**Response**
```json
{
  "id": "<uuid>",
  "total_distance_m": 150.0,
  "stops": [
    { "sequence": 0, "location_code": "ENTRANCE", "product_name": "Start", ... },
    { "sequence": 1, "location_code": "A-01-01", "product_name": "ITEM-1", ... }
  ]
}
```
