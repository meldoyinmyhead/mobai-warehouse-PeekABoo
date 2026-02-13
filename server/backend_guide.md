# FastAPI Backend Guide: MobAI WMS

This guide explains how to run the backend and how the architecture works.

## 1. Installation

First, ensure you have Python installed. Then, install the dependencies:

```bash
cd server
pip install -r requirements.txt
```

## 2. Running the Server

Run the server using `uvicorn` with the `--reload` flag for auto-restart on changes:

```bash
uvicorn main:app --reload
```

- **URL**: `http://127.0.0.1:8000`
- **Docs (Swagger UI)**: `http://127.0.0.1:8000/docs`
- **Docs (ReDoc)**: `http://127.0.0.1:8000/redoc`

## 3. Database Seeding

To populate the database with initial data (Depot B7 dataset), run the seeding script:

```bash
python seed.py
```

## 4. Architecture Overview

FastAPI is a modern, high-performance web framework for Python. This backend uses:

- **SQLAlchemy (`models.py`)**: The Object-Relational Mapper (ORM) that defines the database structure.
- **Pydantic (`schemas.py`)**: Data validation and serialization. It ensures that the JSON sent to/from the API matches the expected structure.
- **CRUD Operations (`main.py`)**: The endpoints that handle requests (GET, POST, etc.) and interact with the database.
- **Dependency Injection (`get_db`)**: A robust way to manage database connections for each request.

### Key Endpoints
- `POST /auth/login`: Authenticates a user and returns their role and a mock token.
- `POST /audit/log`: Records user actions (e.g., submitting a task log) for traceability.
- `GET /entrepots/`, `GET /emplacements/`: Manage warehouse infrastructure.
- `GET /produits/`, `GET /stock/`: Manage inventory and products.
