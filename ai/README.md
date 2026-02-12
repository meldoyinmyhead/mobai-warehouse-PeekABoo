# AI Warehouse Management System

## Overview

AI-powered warehouse management system providing demand forecasting, storage optimization, and picking optimization.

## Features

- **Demand Forecasting**: ML-based demand prediction using multiple models (Naive, Exponential Smoothing, Random Forest, XGBoost)
- **Storage Optimization**: ABC-XYZ analysis with intelligent location assignment
- **Picking Optimization**: Wave/batch/zone picking strategies with route optimization
- **RESTful API**: Easy integration with existing warehouse systems

## Project Structure

```
ai/
├── config/              # Configuration and settings
├── core/                # Core data processing modules
├── forecasting/         # Demand forecasting models
├── optimization/        # Storage and picking optimization
├── services/            # Business logic services
├── api/                 # FastAPI REST API
├── utils/               # Utility functions
├── training/            # Model training scripts
├── evaluation/          # Evaluation and metrics
├── tests/               # Unit tests
├── scripts/             # Utility scripts
├── docs/                # Documentation
└── data/                # Data storage
    ├── raw/             # Raw data files
    ├── processed/       # Processed data
    ├── models/          # Trained models
    └── cache/           # Cached computations
```

## Installation

### Prerequisites

- Python 3.11+
- pip

### Setup

```bash
# Clone repository
cd ai

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy environment configuration
cp .env.example .env
```

## Usage

### 1. Preprocess Data

```bash
python -m ai.scripts.preprocess_data
```

### 2. Train Models

```bash
python -m ai.training.train_forecast_models
```

### 3. Start API Server

```bash
uvicorn ai.api.app:app --reload
```

API documentation available at: `http://localhost:8000/api/v1/docs`

### 4. Docker Deployment

```bash
# Build and run
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

## API Examples

### Forecast Demand

```bash
curl -X POST "http://localhost:8000/api/v1/forecast" \
  -H "Content-Type: application/json" \
  -d '{
    "demand_data": [...],
    "horizon_days": 7,
    "model_type": "xgboost"
  }'
```

### Optimize Storage

```bash
curl -X POST "http://localhost:8000/api/v1/optimize-storage" \
  -H "Content-Type: application/json" \
  -d '{
    "products_data": [...],
    "locations_data": [...],
    "demand_data": [...]
  }'
```

### Optimize Picking

```bash
curl -X POST "http://localhost:8000/api/v1/optimize-picking" \
  -H "Content-Type: application/json" \
  -d '{
    "picks_data": [...],
    "locations_data": [...],
    "strategy": "wave"
  }'
```

## Configuration

Edit `.env` file to configure:

- Model parameters
- API settings
- Optimization weights
- Storage zones
- Picking strategies

See `.env.example` for all available options.

## Development

### Run Tests

```bash
pytest ai/tests/
```

### Code Formatting

```bash
black ai/
flake8 ai/
```

### Type Checking

```bash
mypy ai/
```

## Models

- **Naive Baseline**: 7-day moving average
- **Exponential Smoothing**: Holt-Winters seasonal model
- **Random Forest**: Ensemble tree-based regressor
- **XGBoost**: Gradient boosting regressor

## Evaluation Metrics

- MAE (Mean Absolute Error)
- RMSE (Root Mean Squared Error)
- MAPE (Mean Absolute Percentage Error)
- R² Score

## Documentation

- [Technical Documentation](ai/docs/AI_Technical_Documentation.md)
- [API Documentation](ai/docs/API_Documentation.md)
- [Interactive API Docs](http://localhost:8000/api/v1/docs) (when running)

## License

Proprietary - Warehouse Management System

## Support

For issues and questions, please contact the development team.
