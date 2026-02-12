"""Input validation utilities"""

import pandas as pd
from typing import List, Optional

from ..config.logging_config import get_logger

logger = get_logger("validators")


def validate_dataframe(df: pd.DataFrame, name: str = "DataFrame") -> bool:
    """
    Validate DataFrame is not empty
    
    Args:
        df: DataFrame to validate
        name: Name for logging
        
    Returns:
        True if valid
        
    Raises:
        ValueError: If invalid
    """
    if df is None:
        raise ValueError(f"{name} cannot be None")
    
    if not isinstance(df, pd.DataFrame):
        raise ValueError(f"{name} must be a pandas DataFrame")
    
    if len(df) == 0:
        raise ValueError(f"{name} cannot be empty")
    
    logger.debug(f"{name} validated: {df.shape}")
    return True


def validate_columns(df: pd.DataFrame, required_columns: List[str], name: str = "DataFrame") -> bool:
    """
    Validate DataFrame has required columns
    
    Args:
        df: DataFrame to validate
        required_columns: List of required column names
        name: Name for logging
        
    Returns:
        True if valid
        
    Raises:
        ValueError: If missing columns
    """
    missing_columns = set(required_columns) - set(df.columns)
    
    if missing_columns:
        raise ValueError(f"{name} missing required columns: {missing_columns}")
    
    logger.debug(f"{name} has all required columns")
    return True


def validate_product_data(df: pd.DataFrame) -> bool:
    """Validate product data structure"""
    validate_dataframe(df, "Product data")
    validate_columns(df, ["product_id"], "Product data")
    return True


def validate_demand_data(df: pd.DataFrame) -> bool:
    """Validate demand data structure"""
    validate_dataframe(df, "Demand data")
    validate_columns(df, ["product_id", "date", "demand"], "Demand data")
    return True


def validate_location_data(df: pd.DataFrame) -> bool:
    """Validate location data structure"""
    validate_dataframe(df, "Location data")
    validate_columns(df, ["location_id"], "Location data")
    return True
