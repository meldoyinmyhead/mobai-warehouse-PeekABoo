"""
Data Loader
Load and preprocess data from various sources (Excel, DB, API)
"""

import pandas as pd
from pathlib import Path
from typing import Dict, Optional, Tuple
import pickle

from ..config.settings import settings
from ..config.logging_config import get_logger

logger = get_logger("data_loader")


class DataLoader:
    """Load and manage warehouse data from various sources"""
    
    def __init__(self, data_path: Optional[Path] = None):
        """
        Initialize DataLoader
        
        Args:
            data_path: Path to the raw data file
        """
        self.data_path = data_path or settings.RAW_DATA_DIR / settings.RAW_DATA_FILE
        self.demand_history: Optional[pd.DataFrame] = None
        self.product_attributes: Optional[pd.DataFrame] = None
        self.warehouse_layout: Optional[pd.DataFrame] = None
        
    def load_from_excel(self, sheet_mapping: Optional[Dict[str, str]] = None) -> Dict[str, pd.DataFrame]:
        """
        Load data from Excel file
        
        Args:
            sheet_mapping: Dictionary mapping sheet names to data types
                          e.g., {'Demand': 'demand', 'Products': 'products', 'Layout': 'layout'}
        
        Returns:
            Dictionary of loaded DataFrames
        """
        logger.info(f"Loading data from {self.data_path}")
        
        if not self.data_path.exists():
            raise FileNotFoundError(f"Data file not found: {self.data_path}")
        
        # Default sheet mapping
        if sheet_mapping is None:
            sheet_mapping = {
                'Demand': 'demand',
                'Products': 'products',
                'Layout': 'layout'
            }
        
        data = {}
        
        try:
            excel_file = pd.ExcelFile(self.data_path)
            
            for sheet_name, data_key in sheet_mapping.items():
                if sheet_name in excel_file.sheet_names:
                    data[data_key] = pd.read_excel(excel_file, sheet_name=sheet_name)
                    logger.info(f"Loaded sheet '{sheet_name}': {data[data_key].shape}")
                else:
                    logger.warning(f"Sheet '{sheet_name}' not found in Excel file")
            
            # Store in instance variables
            self.demand_history = data.get('demand')
            self.product_attributes = data.get('products')
            self.warehouse_layout = data.get('layout')
            
            return data
            
        except Exception as e:
            logger.error(f"Error loading Excel file: {str(e)}")
            raise
    
    def load_processed_data(self) -> Tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
        """
        Load preprocessed data from parquet files
        
        Returns:
            Tuple of (demand_history, product_attributes, warehouse_layout)
        """
        logger.info("Loading processed data")
        
        try:
            self.demand_history = pd.read_parquet(
                settings.PROCESSED_DATA_DIR / "demand_history.parquet"
            )
            self.product_attributes = pd.read_parquet(
                settings.PROCESSED_DATA_DIR / "product_attributes.parquet"
            )
            self.warehouse_layout = pd.read_parquet(
                settings.PROCESSED_DATA_DIR / "warehouse_layout.parquet"
            )
            
            logger.info(f"Demand history: {self.demand_history.shape}")
            logger.info(f"Product attributes: {self.product_attributes.shape}")
            logger.info(f"Warehouse layout: {self.warehouse_layout.shape}")
            
            return self.demand_history, self.product_attributes, self.warehouse_layout
            
        except FileNotFoundError as e:
            logger.error(f"Processed data not found: {str(e)}")
            logger.info("Please run preprocessing first")
            raise
    
    def save_processed_data(self):
        """Save processed data to parquet files"""
        logger.info("Saving processed data")
        
        if self.demand_history is not None:
            self.demand_history.to_parquet(
                settings.PROCESSED_DATA_DIR / "demand_history.parquet",
                index=False
            )
            logger.info("Saved demand_history.parquet")
        
        if self.product_attributes is not None:
            self.product_attributes.to_parquet(
                settings.PROCESSED_DATA_DIR / "product_attributes.parquet",
                index=False
            )
            logger.info("Saved product_attributes.parquet")
        
        if self.warehouse_layout is not None:
            self.warehouse_layout.to_parquet(
                settings.PROCESSED_DATA_DIR / "warehouse_layout.parquet",
                index=False
            )
            logger.info("Saved warehouse_layout.parquet")
    
    def get_demand_history(self, product_id: Optional[str] = None) -> pd.DataFrame:
        """Get demand history for a specific product or all products"""
        if self.demand_history is None:
            raise ValueError("Demand history not loaded")
        
        if product_id:
            return self.demand_history[self.demand_history['product_id'] == product_id]
        
        return self.demand_history
    
    def get_product_attributes(self, product_id: Optional[str] = None) -> pd.DataFrame:
        """Get product attributes for a specific product or all products"""
        if self.product_attributes is None:
            raise ValueError("Product attributes not loaded")
        
        if product_id:
            return self.product_attributes[self.product_attributes['product_id'] == product_id]
        
        return self.product_attributes
    
    def get_warehouse_layout(self, location_id: Optional[str] = None) -> pd.DataFrame:
        """Get warehouse layout for a specific location or all locations"""
        if self.warehouse_layout is None:
            raise ValueError("Warehouse layout not loaded")
        
        if location_id:
            return self.warehouse_layout[self.warehouse_layout['location_id'] == location_id]
        
        return self.warehouse_layout
