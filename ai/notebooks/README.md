# 📓 Jupyter Notebooks

This directory contains Jupyter notebooks for the complete data science workflow: from setup to model evaluation.

## 🎯 Workflow - Follow These Notebooks in Order

### 00. Setup & Overview

**File**: `00_setup_and_overview.ipynb`

**Purpose**: Project introduction and environment verification

**What it does**:

- ✅ Verifies Python environment and installed packages
- ✅ Checks data files availability
- ✅ Loads sample data for quick verification
- ✅ Provides project overview and next steps

**Start here if**: This is your first time using the project

---

### 01. Explore Data

**File**: `01_explore_data.ipynb`

**Purpose**: Initial data exploration and understanding

**What it does**:

- Loads the original Excel file (WMS_Hackathon_DataPack_Templates_FR_FV_B7_ONLY.xlsx)
- Explores all sheets in the workbook
- Joins `produits` and `historique_demande` tables → creates `products_for_ts.csv`
- Joins `transactions`, `lignes_transaction`, and `produits` → creates `tempo_ts.csv`
- Filters and groups data → creates `tempo_ts_grouped.csv`

**Output files** (saved to `../data/raw/`):

- `products_for_ts.csv` - Product demand history
- `tempo_ts.csv` - Transaction-based time series
- `tempo_ts_grouped.csv` - Grouped transaction data

---

### 02. Preprocessing

**File**: `02_preprocessing.ipynb`

**Purpose**: Data cleaning and preprocessing for time series analysis

**What it does**:

- Loads merged datasets
- Checks for missing values and data quality
- Removes unnecessary columns
- Groups transactions by date to avoid duplicates
- Merges tempo and products datasets → creates `final.csv`
- Provides summary statistics and data validation

**Output files** (saved to `../data/raw/`):

- `products_for_ts_grouped.csv` (cleaned and grouped)
- `tempo_for_ts_final.csv` (grouped by date)
- `final.csv` - **Final merged dataset ready for modeling**

---

### 03. Training

**File**: `03_training.ipynb`

**Purpose**: Model training experiments

**What it does**:

- Splits data into train/test sets
- Trains multiple forecasting models:
  - Naive baseline (7-day moving average)
  - Exponential Smoothing
  - Random Forest Regressor
  - XGBoost Regressor
- Saves trained models
- Generates predictions

**Output** (saved to `../data/models/`):

- Trained model files (.pkl)
- Test predictions for evaluation

---

### 04. Evaluation

**File**: `04_evaluation.ipynb`

**Purpose**: Model performance evaluation and comparison

**What it does**:

- Calculates evaluation metrics (MAE, RMSE, MAPE, R²)
- Compares different models side-by-side
- Visualizes predictions vs actual values
- Analyzes errors and performance by product category
- Identifies best performing models

**Output**:

- Comprehensive evaluation report
- Visualizations and insights
- Recommendations for model selection

---

## 📊 Complete Data Flow

```
📁 Raw Data (Excel + CSV)
    ↓
┌─────────────────────────────────────┐
│ 00. Setup & Overview                │ ← Verify environment
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 01. Explore Data                    │ → CSVs created
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 02. Preprocessing                   │ → final.csv ready
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 03. Training                        │ → Models trained
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ 04. Evaluation                      │ → Best model identified
└─────────────────────────────────────┘
    ↓
🎯 Production Ready Model
```

## 🚀 Quick Start

### Open in VS Code (Recommended)

1. Open any `.ipynb` file in VS Code
2. Select Python kernel
3. Run cells with Shift+Enter

### Or use Jupyter

```powershell
cd ai\notebooks
jupyter notebook
```

### Or use JupyterLab

```powershell
cd ai\notebooks
jupyter lab
```

## 📁 File Locations

**Input data**: `../data/raw/`

- `WMS_Hackathon_DataPack_Templates_FR_FV_B7_ONLY.xlsx` - Original Excel file
- All CSV files

**Output data**:

- Intermediate files → `../data/raw/`
- Final processed → `../data/processed/`

**Models**: `../data/models/`

## 💡 Tips

### Running Notebooks

- **Run cells in order** - Use Shift+Enter to execute cells sequentially
- **Restart & Run All** - Use this to verify everything works end-to-end
- **Save frequently** - Ctrl+S (or Cmd+S on Mac)

### File Paths

All notebooks use relative paths like `../data/raw/`. This works because:

- Notebooks are in `ai/notebooks/`
- Data is in `ai/data/raw/`
- `..` goes up one level from notebooks to ai

### Installing Missing Packages

If you see import errors:

```powershell
pip install pandas numpy matplotlib seaborn scikit-learn xgboost
```

## ⚠️ Common Issues

**Issue**: Can't find data files

- **Solution**: Make sure you're running notebooks from `ai/notebooks/` directory
- Verify files exist in `ai/data/raw/`

**Issue**: Kernel not found

- **Solution**: In VS Code, click "Select Kernel" and choose your Python environment
- Or install jupyter: `pip install jupyter`

**Issue**: Import errors

- **Solution**: Install required packages: `pip install -r ../../requirements.txt`

## 📚 Integration with Production Code

These notebooks are for **exploratory analysis and experimentation**.

For production use:

- See Python modules in `../core/`, `../forecasting/`, etc.
- Use scripts in `../scripts/` for automation
- Deploy via API in `../api/`

Use notebooks for:

- 🔍 Quick data exploration
- 🧪 Testing new features
- 📊 Experimenting with models
- 📝 Documentation and sharing insights

Use production code for:

- 🔄 Automated preprocessing
- ⚙️ Model training pipelines
- 🌐 API integration
- 🚀 Deployment

## 📖 Additional Resources

- **Main README**: `../../README.md`
- **Quick Start Guide**: `../QUICKSTART.md`
- **Data Documentation**: `../data/README.md`
- **API Documentation**: `../docs/API_Documentation.md`

---

**📊 Happy analyzing!** Follow the notebooks in order for the best experience.
