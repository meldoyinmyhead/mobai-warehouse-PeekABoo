"""
Feature Engineering
Create features for ML models from raw data
"""

import pandas as pd
import numpy as np
from typing import List, Optional
from datetime import datetime, timedelta

from ..config.settings import settings
from ..config.logging_config import get_logger

logger = get_logger("feature_engineering")


class FeatureEngineer:
    """Create features for demand forecasting and optimization"""
    
    def __init__(self):
        """Initialize FeatureEngineer"""
        self.rolling_windows = settings.ROLLING_WINDOW_SIZES
        self.lag_features = settings.LAG_FEATURES
    
    def create_time_features(self, df: pd.DataFrame, date_column: str = 'date') -> pd.DataFrame:
        """
        Create time-based features from date column
        
        Args:
            df: DataFrame with date column
            date_column: Name of date column
            
        Returns:
            DataFrame with time features added
        """
        logger.info("Creating time features")
        
        df = df.copy()
        df[date_column] = pd.to_datetime(df[date_column])
        
        # Extract time components
        df['year'] = df[date_column].dt.year
        df['month'] = df[date_column].dt.month
        df['day'] = df[date_column].dt.day
        df['day_of_week'] = df[date_column].dt.dayofweek
        df['day_of_year'] = df[date_column].dt.dayofyear
        df['week_of_year'] = df[date_column].dt.isocalendar().week
        df['quarter'] = df[date_column].dt.quarter
        
        # Is weekend
        df['is_weekend'] = df['day_of_week'].isin([5, 6]).astype(int)
        
        # Is month start/end
        df['is_month_start'] = df[date_column].dt.is_month_start.astype(int)
        df['is_month_end'] = df[date_column].dt.is_month_end.astype(int)
        
        logger.info(f"Created {11} time features")
        
        return df
    
    def create_lag_features(
        self,
        df: pd.DataFrame,
        value_column: str = 'demand',
        group_column: Optional[str] = 'product_id',
        lags: Optional[List[int]] = None
    ) -> pd.DataFrame:
        """
        Create lag features for time series
        
        Args:
            df: DataFrame with time series data
            value_column: Column to create lags from
            group_column: Column to group by (e.g., product_id)
            lags: List of lag periods
            
        Returns:
            DataFrame with lag features
        """
        logger.info("Creating lag features")
        
        df = df.copy()
        lags = lags or self.lag_features
        
        for lag in lags:
            feature_name = f'{value_column}_lag_{lag}'
            if group_column:
                df[feature_name] = df.groupby(group_column)[value_column].shift(lag)
            else:
                df[feature_name] = df[value_column].shift(lag)
        
        logger.info(f"Created {len(lags)} lag features")
        
        return df
    
    def create_rolling_features(
        self,
        df: pd.DataFrame,
        value_column: str = 'demand',
        group_column: Optional[str] = 'product_id',
        windows: Optional[List[int]] = None
    ) -> pd.DataFrame:
        """
        Create rolling window statistics
        
        Args:
            df: DataFrame with time series data
            value_column: Column to compute rolling stats
            group_column: Column to group by
            windows: List of window sizes
            
        Returns:
            DataFrame with rolling features
        """
        logger.info("Creating rolling features")
        
        df = df.copy()
        windows = windows or self.rolling_windows
        
        for window in windows:
            if group_column:
                grouped = df.groupby(group_column)[value_column]
                df[f'{value_column}_rolling_mean_{window}'] = grouped.transform(
                    lambda x: x.rolling(window, min_periods=1).mean()
                )
                df[f'{value_column}_rolling_std_{window}'] = grouped.transform(
                    lambda x: x.rolling(window, min_periods=1).std()
                )
                df[f'{value_column}_rolling_max_{window}'] = grouped.transform(
                    lambda x: x.rolling(window, min_periods=1).max()
                )
                df[f'{value_column}_rolling_min_{window}'] = grouped.transform(
                    lambda x: x.rolling(window, min_periods=1).min()
                )
            else:
                df[f'{value_column}_rolling_mean_{window}'] = (
                    df[value_column].rolling(window, min_periods=1).mean()
                )
                df[f'{value_column}_rolling_std_{window}'] = (
                    df[value_column].rolling(window, min_periods=1).std()
                )
                df[f'{value_column}_rolling_max_{window}'] = (
                    df[value_column].rolling(window, min_periods=1).max()
                )
                df[f'{value_column}_rolling_min_{window}'] = (
                    df[value_column].rolling(window, min_periods=1).min()
                )
        
        logger.info(f"Created {len(windows) * 4} rolling features")
        
        return df
    
    def create_trend_features(
        self,
        df: pd.DataFrame,
        value_column: str = 'demand',
        group_column: Optional[str] = 'product_id'
    ) -> pd.DataFrame:
        """
        Create trend-based features
        
        Args:
            df: DataFrame with time series data
            value_column: Column to analyze trends
            group_column: Column to group by
            
        Returns:
            DataFrame with trend features
        """
        logger.info("Creating trend features")
        
        df = df.copy()
        
        # Growth rate (percentage change)
        if group_column:
            df[f'{value_column}_growth_rate'] = df.groupby(group_column)[value_column].pct_change()
        else:
            df[f'{value_column}_growth_rate'] = df[value_column].pct_change()
        
        # Difference from previous period
        if group_column:
            df[f'{value_column}_diff'] = df.groupby(group_column)[value_column].diff()
        else:
            df[f'{value_column}_diff'] = df[value_column].diff()
        
        logger.info("Created 2 trend features")
        
        return df
    
    def create_product_features(
        self,
        demand_df: pd.DataFrame,
        product_df: pd.DataFrame
    ) -> pd.DataFrame:
        """
        Merge and create product-related features
        
        Args:
            demand_df: Demand history DataFrame
            product_df: Product attributes DataFrame
            
        Returns:
            DataFrame with product features
        """
        logger.info("Creating product features")
        
        df = demand_df.merge(
            product_df,
            on='product_id',
            how='left'
        )
        
        logger.info(f"Merged with product attributes: {df.shape}")
        
        return df
    
    def create_all_features(
        self,
        demand_df: pd.DataFrame,
        product_df: Optional[pd.DataFrame] = None,
        date_column: str = 'date',
        value_column: str = 'demand',
        group_column: str = 'product_id'
    ) -> pd.DataFrame:
        """
        Create all features for forecasting
        
        Args:
            demand_df: Demand history DataFrame
            product_df: Product attributes DataFrame (optional)
            date_column: Date column name
            value_column: Value column name
            group_column: Group column name
            
        Returns:
            DataFrame with all features
        """
        logger.info("Creating all features")
        
        df = demand_df.copy()
        
        # Time features
        df = self.create_time_features(df, date_column)
        
        # Lag features
        df = self.create_lag_features(df, value_column, group_column)
        
        # Rolling features
        df = self.create_rolling_features(df, value_column, group_column)
        
        # Trend features
        df = self.create_trend_features(df, value_column, group_column)
        
        # Product features
        if product_df is not None:
            df = self.create_product_features(df, product_df)
        
        # Drop rows with NaN (from lag/rolling features)
        initial_rows = len(df)
        df = df.dropna()
        logger.info(f"Dropped {initial_rows - len(df)} rows with missing values")
        
        logger.info(f"Final feature shape: {df.shape}")
        
        return df
