# Data Directory

## Structure

### raw/

Raw data files from the warehouse system

**Original Dataset:**

- `WMS_Hackathon_DataPack_Templates_FR_FV_B7_ONLY.xlsx` (5.5 MB) - Main warehouse data pack with multiple sheets

**Processed CSV Files:**

- `products_for_ts_grouped.csv` (4.2 MB) - Time series data for products (80,653 rows)
  - Columns: id_produit, date, categorie, colisage fardeau, colisage palette, volume pcs (m3), Is_Gerbable, quantite_demande
  - Product demand history grouped by date

- `products_for_ts.csv` (9.3 MB) - Detailed product time series data
  - Individual product demand records

- `tempo_for_ts_final.csv` (1.8 MB) - Temporal features for time series
  - Date-based features and patterns

- `tempo_ts_grouped.csv` (4.2 MB) - Grouped temporal data
  - Aggregated temporal patterns

- `tempo_ts.csv` (14.4 MB) - Detailed temporal data
  - Raw temporal information

- `final.csv` (4.9 MB) - Final processed dataset
  - Combined and cleaned data ready for analysis

### Data Schema

**Product Attributes:**

- `id_produit` (int): Unique product identifier
- `categorie` (str): Product category (e.g., MOULURE)
- `colisage fardeau` (int): Bundle packaging size
- `colisage palette` (int): Pallet packaging size
- `volume pcs (m3)` (float): Unit volume in cubic meters
- `Is_Gerbable` (bool): Whether product is stackable

**Demand Data:**

- `date` (date): Demand date
- `quantite_demande` (int): Quantity demanded

### processed/

Cleaned and preprocessed data

- `demand_history.parquet` - Processed demand history
- `product_attributes.parquet` - Product characteristics
- `warehouse_layout.parquet` - Warehouse location data

### models/

Trained machine learning models

- `forecast_model_rf.pkl` - Random Forest forecaster
- `forecast_model_xgb.pkl` - XGBoost forecaster
- `product_segments.pkl` - ABC-XYZ segmentation
- `scaler.pkl` - Feature scaler

### cache/

Cached computations

- `distance_matrix.pkl` - Pairwise location distances
- `location_features.pkl` - Pre-computed location features

## Data Processing Pipeline

1. Load raw data from `raw/WMS_Hackathon_DataPack_Templates_FR_FV_B7_ONLY.xlsx`
2. Extract and transform data -> use CSV files in `raw/`
3. Clean and engineer features -> save to `processed/`
4. Train forecasting models -> save to `models/`
5. Cache heavy computations -> save to `cache/`

## Quick Start

```python
from ai.core import DataLoader

# Load processed data
loader = DataLoader()
demand_df, product_df, layout_df = loader.load_processed_data()

# Or load from raw CSV
products_df = pd.read_csv("ai/data/raw/products_for_ts_grouped.csv")

# Or from Excel
raw_data = loader.load_from_excel()
```
