# 🚀 Quick Start Guide

## Prerequisites

- Python 3.11 or higher
- pip (Python package manager)
- Git

## Setup Instructions

### 1. Install Dependencies

```powershell
cd d:\Warehouse\mobai-warehouse-PeekABoo
pip install -r requirements.txt
```

### 2. Configure Environment

```powershell
# Copy environment template
copy .env.example .env

# Edit .env file with your settings (optional)
notepad .env
```

### 3. Inspect Your Data

```powershell
# Run data inspection script
python -m ai.scripts.load_sample_data
```

This will show:

- Data file sizes and row counts
- Column names and data types
- Sample data preview
- Creates initial processed files

### 4. Preprocess Data

```powershell
# Run preprocessing pipeline
python -m ai.scripts.preprocess_data
```

This will:

- Load raw CSV files from `ai/data/raw/`
- Clean and transform data
- Create features
- Save to `ai/data/processed/`

### 5. Train Models

```powershell
# Train all forecasting models
python -m ai.training.train_forecast_models

# Or use the shell script
bash ai/scripts/train_all_models.sh
```

Models will be saved to `ai/data/models/`

### 6. Start the API

```powershell
# Start FastAPI server with auto-reload
uvicorn ai.api.app:app --reload --host 0.0.0.0 --port 8000
```

API will be available at:

- Main API: http://localhost:8000
- Swagger Docs: http://localhost:8000/api/v1/docs
- Health Check: http://localhost:8000/api/v1/health

## Quick Test

### Test Forecasting Endpoint

```powershell
# Using curl
curl -X POST "http://localhost:8000/api/v1/forecast" ^
  -H "Content-Type: application/json" ^
  -d "{\"product_id\":12345,\"periods\":7,\"model\":\"xgboost\"}"
```

Or use Python:

```python
import requests

response = requests.post(
    "http://localhost:8000/api/v1/forecast",
    json={
        "product_id": 12345,
        "periods": 7,
        "model": "xgboost"
    }
)
print(response.json())
```

## Jupyter Notebooks (Optional)

For exploratory data analysis and experimentation, check out the Jupyter notebooks in `ai/notebooks/`:

```powershell
# Option 1: Open in VS Code (built-in support)
# Just open the .ipynb files in VS Code

# Option 2: Use Jupyter Notebook
cd ai\notebooks
jupyter notebook

# Option 3: Use Jupyter Lab
cd ai\notebooks
jupyter lab
```

**Available notebooks:**

- **explore_data.ipynb** - Initial data exploration and table joins
- **preprocessing.ipynb** - Data cleaning and preparation
- **training.ipynb** - Model training experiments

See [notebooks/README.md](notebooks/README.md) for detailed documentation.

## File Structure Overview

```
ai/
├── config/              # Configuration settings
├── core/                # Core data processing
│   ├── data_loader.py
│   ├── feature_engineering.py
│   └── product_segmentation.py
├── forecasting/         # Forecasting models
│   ├── models/
│   ├── orchestrator.py
│   └── evaluator.py
├── optimization/        # Storage & picking optimization
│   ├── storage_optimizer.py
│   ├── picking_optimizer.py
│   └── route_optimizer.py
├── services/            # Business logic services
├── api/                 # FastAPI application
│   ├── app.py
│   ├── routes/
│   └── schemas/
├── notebooks/           # 📓 Jupyter notebooks for exploration
│   ├── explore_data.ipynb
│   ├── preprocessing.ipynb
│   └── training.ipynb
├── scripts/             # Utility scripts
│   ├── load_sample_data.py
│   └── preprocess_data.py
├── data/
│   ├── raw/             # ✅ Your CSV and Excel files are here
│   ├── processed/       # Processed parquet files
│   ├── models/          # Trained ML models
│   └── cache/           # Cached computations
└── tests/               # Unit tests
```

## Available Data Files

Your `ai/data/raw/` directory contains:

- ✅ `WMS_Hackathon_DataPack_Templates_FR_FV_B7_ONLY.xlsx` (5.5 MB) - Original Excel dataset
- ✅ `products_for_ts_grouped.csv` (4.2 MB) - Product demand time series
- ✅ `products_for_ts.csv` (9.3 MB) - Detailed product data
- ✅ `final.csv` (4.9 MB) - Final processed dataset
- ✅ `tempo_ts.csv` (14.4 MB) - Temporal data
- ✅ And 3 more CSV files

## Next Steps

1. **Explore Your Data**

   ```python
   import pandas as pd
   df = pd.read_csv("ai/data/raw/products_for_ts_grouped.csv")
   print(df.head())
   ```

2. **Explore with Notebooks**
   - `ai/notebooks/explore_data.ipynb` - Data exploration and table joins
   - `ai/notebooks/preprocessing.ipynb` - Data cleaning and preparation
   - `ai/notebooks/training.ipynb` - Model training experiments

   Open in VS Code or run `jupyter notebook` in the `ai/notebooks/` directory

3. **Run Tests**

   ```powershell
   pytest ai/tests/
   ```

4. **View Documentation**
   - [AI Technical Documentation](ai/docs/AI_Technical_Documentation.md)
   - [API Documentation](ai/docs/API_Documentation.md)
   - [Data README](ai/data/README.md)

## Docker Deployment (Alternative)

```powershell
# Build and start services
docker-compose up --build

# API will be available at http://localhost:8000
```

## Troubleshooting

### Import Errors

```powershell
# Make sure you're in the root directory
cd d:\Warehouse\mobai-warehouse-PeekABoo

# Install dependencies again
pip install -r requirements.txt
```

### Data Not Found

```powershell
# Verify data files exist
dir ai\data\raw

# Should show 8 files including WMS_Hackathon_DataPack_Templates_FR_FV_B7_ONLY.xlsx
```

### API Not Starting

```powershell
# Check if port 8000 is available
netstat -ano | findstr :8000

# Use different port
uvicorn ai.api.app:app --reload --port 8080
```

## Support

For issues or questions:

1. Check the [main README](README.md)
2. Review [AI Documentation](ai/docs/AI_Technical_Documentation.md)
3. Check [API docs](http://localhost:8000/api/v1/docs) when server is running

---

**🎯 Your AI Service is Ready!** All data files are properly organized in `ai/data/raw/` and the complete codebase is set up and ready to use.
