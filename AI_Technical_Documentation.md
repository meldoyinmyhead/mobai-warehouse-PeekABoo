# AI Warehouse Management System - Technical Documentation

## Overview

This document provides technical documentation for the AI-powered warehouse management system. The AI logic is integrated directly into the Backend (`server/main.py`) and optionally delegates complex tasks to a specialized AI Service via `server/services/ai_client.py`.

## Architecture

- **Backend (server/main.py)**: Orchestrates AI requests.
- **Forecasting Module**: Generates `PreparationOrder` based on historical demand (`/ai/forecast`).
- **Optimization Module**:
    - **Storage**: Assigns slots using business logic (`/ai/prescribe-storage`).
    - **Picking**: Optimizes routes using TSP-like algorithms (`/ai/optimize-picking`).
- **AI Client (server/services/ai_client.py)**: Interface to external AI microservices (if deployed).

## Models & Algorithms

### Forecasting
1. **Naive Baseline**: 7-day moving average (MVP).
2. **Planned**: Exponential Smoothing (Holt-Winters), XGBoost.

### Optimization
1. **Storage Optimization**:
   - Finds first available empty slot in the `STORAGE` zone.
   - Future: ABC analysis to place high-velocity items closer to dispatch.
2. **Picking Optimization**:
   - **TSP (Travelling Salesperson)**: Orders stops to minimize travel distance.
   - **Start Location**: Considers employee's last known location.

## API Endpoints (AI Specific)

These endpoints are exposed by `server/main.py`:

- `POST /ai/forecast`: Generate demand forecast.
- `POST /ai/prescribe-storage`: Optimize storage locations.
- `POST /ai/optimize-picking`: Optimize picking operations (Route generation).
- `POST /ai/log-override`: Tracks human-in-the-loop decisions (Supervisor overrides).

## Override & Human-in-the-Loop

The system enforces a **Human-in-the-Loop** workflow:
1. AI generates a proposal (Forecast or Picking Route).
2. Proposal acts as `PENDING_REVIEW` (PreparationOrder).
3. Supervisor reviews and can **Approve** or **Override**.
4. Overrides are logged (`AIOverride` table) to retrain/improve the model.

## Configuration

Settings are managed via `server/.env` and `models.py` constants.

