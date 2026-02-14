# WMS Backend API Documentation

## Overview

REST API for the MobAI Warehouse Management System. Implemented in **FastAPI** (`server/main.py`). No version prefix: all routes are at the **root** of the base URL.

## Base URL

- Local: `http://localhost:8000`
- Replace with your server IP when using the mobile app (e.g. `http://10.80.23.251:8000`).

## Authentication

Login returns a bearer-style token. Include it in subsequent requests (e.g. `Authorization: Bearer <access_token>`). The current implementation returns a mock token; role is embedded in the user object.

---

## Endpoints

### Health / Root

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Service info (message, system, warehouse). |

### Auth

| Method | Path | Description |
|--------|------|-------------|
| POST | `/auth/login` | Login. Body: `{ "email": "...", "password": "..." }`. Returns `access_token`, `token_type`, `user`. |

### Audit

| Method | Path | Description |
|--------|------|-------------|
| POST | `/audit/log` | Create audit log. Body: `id_utilisateur`, `action`, `entity_type`, `entity_id`, `payload`. |

### Users (Admin)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/users/` | List users (optional `skip`, `limit`). |
| POST | `/users/` | Create user. |
| PUT | `/users/{user_id}` | Update user. |
| DELETE | `/users/{user_id}` | Delete user. |

### Warehouses (Entrepots)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/entrepots/` | List warehouses. |
| POST | `/entrepots/` | Create warehouse. |
| PUT | `/entrepots/{entrepot_id}` | Update warehouse. |
| DELETE | `/entrepots/{entrepot_id}` | Delete warehouse. |

### Floors (Etages)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/entrepots/{entrepot_id}/etages` | Create floor for warehouse. |
| DELETE | `/etages/{etage_id}` | Delete floor. |

### Locations (Emplacements)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/emplacements/` | List locations. Optional query: `zone`. |

### Products & Stock

| Method | Path | Description |
|--------|------|-------------|
| GET | `/produits/` | List products (SKUs). |
| GET | `/stock/` | List stock per location. |

### AI Services

| Method | Path | Description |
|--------|------|-------------|
| GET | `/ai/available-slots` | Empty slots for storage (optional `zone`). |
| GET | `/ai/inventory` | Current inventory for AI (non-zero stock). |
| POST | `/ai/forecast` | Generate preparation order(s). Body: `{ "target_date": "YYYY-MM-DD" }`. |
| POST | `/ai/prescribe-storage` | Storage assignment for received items. Body: `{ "received_items": [{ "id_produit": "uuid", ... }] }`. |
| POST | `/ai/optimize-picking` | Optimized picking route and create picking order. Body: `id_preparation_order`, `available_employees`, etc. |
| POST | `/ai/log-override` | Log supervisor/admin override. Body: `order_type`, `order_id`, `user_id`, `justification`, `original_ai_suggestion`, `user_override_value`. |

### Employee Tasks

| Method | Path | Description |
|--------|------|-------------|
| GET | `/employee/tasks/{user_id}` | Pending picking tasks for employee (with stops and map-related fields). |
| POST | `/employee/tasks/{task_id}/complete` | Mark task completed (and audit). |

### Scheduler (Testing)

| Method | Path | Description |
|--------|------|-------------|
| POST | `/scheduler/trigger-daily` | Manually trigger daily forecast job. |

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
  "user": {
    "id_utilisateur": "<uuid>",
    "nom_complet": "...",
    "email": "...",
    "role": "ADMIN",
    "actif": true,
    "created_at": "...",
    "last_login": null
  }
}
```

### Get employee tasks

**Request**

```http
GET /employee/tasks/<user_uuid>
```

**Response**

```json
[
  {
    "id": "<uuid>",
    "reference": "PICK-...",
    "assigned_to": "<uuid>",
    "order_type": "PICKING",
    "total_distance_m": 120.5,
    "stops": [
      {
        "sequence": 1,
        "location_code": "B7-N1-C5",
        "product_name": "...",
        "quantity": 10,
        "niveau": 1,
        "rangee": 5,
        "colonne": 5
      }
    ]
  }
]
```

---

## Notes

- **Roles**: `ADMIN`, `SUPERVISOR`, `EMPLOYEE`. Enforce in middleware or dependencies for protected routes.
- **IDs**: Most entities use UUIDs.
- **Dates**: Use ISO format where applicable (e.g. `target_date` for forecast).
- The mobile app may also use **Supabase** for Realtime and sync RPCs; see technical document for data flow and source of truth.
