# API Documentation

## Overview

RESTful API for AI Warehouse Management System

## Base URL

```
http://localhost:8000/api/v1
```

## Endpoints

### Health Check

```
GET /health
```

Returns service health status.

### Forecast Demand

```
POST /forecast
```

Generate demand forecast for products.

**Request Body:**

```json
{
  "demand_data": [...],
  "product_data": [...],
  "horizon_days": 7,
  "model_type": "xgboost"
}
```

### Optimize Storage

```
POST /optimize-storage
```

Optimize product storage locations.

**Request Body:**

```json
{
  "products_data": [...],
  "locations_data": [...],
  "demand_data": [...]
}
```

### Optimize Picking

```
POST /optimize-picking
```

Optimize picking operations.

**Request Body:**

```json
{
  "picks_data": [...],
  "locations_data": [...],
  "strategy": "wave",
  "optimize_route": false
}
```

## Interactive Documentation

Visit `/api/v1/docs` for Swagger UI with interactive API testing.
