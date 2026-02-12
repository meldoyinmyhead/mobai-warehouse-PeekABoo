"""
Load Sample Data
Quick script to load and inspect the warehouse data
"""

import pandas as pd
from pathlib import Path

from ai.config.settings import settings
from ai.config.logging_config import get_logger

logger = get_logger("load_sample_data")


def load_products_time_series():
    """Load product time series data"""
    logger.info("Loading products_for_ts_grouped.csv")
    
    file_path = settings.RAW_DATA_DIR / "products_for_ts_grouped.csv"
    df = pd.read_csv(file_path)
    
    # Convert date column
    df['date'] = pd.to_datetime(df['date'])
    
    # Rename columns to English
    df = df.rename(columns={
        'id_produit': 'product_id',
        'categorie': 'category',
        'quantite_demande': 'demand'
    })
    
    logger.info(f"Loaded {len(df)} records")
    logger.info(f"Date range: {df['date'].min()} to {df['date'].max()}")
    logger.info(f"Unique products: {df['product_id'].nunique()}")
    logger.info(f"Categories: {df['category'].unique()}")
    
    return df


def load_final_dataset():
    """Load final processed dataset"""
    logger.info("Loading final.csv")
    
    file_path = settings.RAW_DATA_DIR / "final.csv"
    df = pd.read_csv(file_path)
    
    logger.info(f"Loaded {len(df)} records")
    logger.info(f"Columns: {list(df.columns)}")
    
    return df


def inspect_data():
    """Inspect all data files"""
    logger.info("=" * 50)
    logger.info("Data Inspection Report")
    logger.info("=" * 50)
    
    # Check all CSV files
    csv_files = [
        "products_for_ts_grouped.csv",
        "products_for_ts.csv",
        "tempo_for_ts_final.csv",
        "tempo_ts_grouped.csv",
        "tempo_ts.csv",
        "final.csv"
    ]
    
    for filename in csv_files:
        file_path = settings.RAW_DATA_DIR / filename
        if file_path.exists():
            df = pd.read_csv(file_path)
            logger.info(f"\n{filename}:")
            logger.info(f"  Rows: {len(df):,}")
            logger.info(f"  Columns: {len(df.columns)}")
            logger.info(f"  Size: {file_path.stat().st_size / 1024 / 1024:.2f} MB")
            logger.info(f"  Columns: {', '.join(df.columns[:5])}...")
    
    # Check Excel file
    excel_file = settings.RAW_DATA_DIR / "WMS_Hackathon_DataPack_Templates_FR_FV_B7_ONLY.xlsx"
    if excel_file.exists():
        logger.info(f"\n{excel_file.name}:")
        logger.info(f"  Size: {excel_file.stat().st_size / 1024 / 1024:.2f} MB")
        
        # Try to read sheet names
        try:
            excel = pd.ExcelFile(excel_file)
            logger.info(f"  Sheets: {', '.join(excel.sheet_names)}")
        except Exception as e:
            logger.error(f"  Error reading sheets: {e}")


def create_sample_processed_data():
    """Create sample processed data from raw files"""
    logger.info("Creating sample processed data")
    
    # Load products time series
    products_df = load_products_time_series()
    
    # Save as parquet
    output_path = settings.PROCESSED_DATA_DIR / "demand_history.parquet"
    products_df.to_parquet(output_path, index=False)
    logger.info(f"Saved demand_history.parquet")
    
    # Create product attributes
    product_attributes = products_df.groupby('product_id').agg({
        'category': 'first',
        'colisage fardeau': 'first',
        'colisage palette': 'first',
        'volume pcs (m3)': 'first',
        'Is_Gerbable': 'first'
    }).reset_index()
    
    output_path = settings.PROCESSED_DATA_DIR / "product_attributes.parquet"
    product_attributes.to_parquet(output_path, index=False)
    logger.info(f"Saved product_attributes.parquet")
    
    logger.info("Sample processed data created successfully")


if __name__ == "__main__":
    print("\n" + "=" * 60)
    print("Warehouse Data Loader - Sample Data Inspector")
    print("=" * 60 + "\n")
    
    # Inspect all data
    inspect_data()
    
    # Load and display sample
    print("\n" + "-" * 60)
    print("Sample Data Preview")
    print("-" * 60 + "\n")
    
    df = load_products_time_series()
    print(df.head(10))
    print(f"\nData shape: {df.shape}")
    print(f"\nData types:\n{df.dtypes}")
    
    # Create processed samples
    print("\n" + "-" * 60)
    print("Creating processed data samples...")
    print("-" * 60 + "\n")
    create_sample_processed_data()
    
    print("\n" + "=" * 60)
    print("Inspection complete!")
    print("=" * 60 + "\n")
