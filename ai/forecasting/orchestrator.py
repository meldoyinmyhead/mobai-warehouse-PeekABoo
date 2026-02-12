"""
Forecast Orchestrator
Main coordinator for forecasting operations
"""

import pandas as pd
import numpy as np
from typing import Dict, List, Optional, Type
from pathlib import Path

from .models import (
    BaseForecaster,
    NaiveBaseline,
    ExponentialSmoothing,
    RandomForestForecaster,
    XGBoostForecaster
)
from ..core import DataLoader, FeatureEngineer
from ..config.settings import settings
from ..config.logging_config import get_logger

logger = get_logger("orchestrator")


class ForecastOrchestrator:
    """Coordinate forecasting operations"""
    
    MODEL_REGISTRY = {
        'naive': NaiveBaseline,
        'exponential_smoothing': ExponentialSmoothing,
        'random_forest': RandomForestForecaster,
        'xgboost': XGBoostForecaster
    }
    
    def __init__(self, model_type: str = None):
        """
        Initialize ForecastOrchestrator
        
        Args:
            model_type: Type of forecasting model to use
        """
        self.model_type = model_type or settings.FORECAST_MODEL
        self.model: Optional[BaseForecaster] = None
        self.data_loader = DataLoader()
        self.feature_engineer = FeatureEngineer()
        
    def get_model(self, model_type: Optional[str] = None) -> BaseForecaster:
        """
        Get forecasting model instance
        
        Args:
            model_type: Type of model (overrides instance model_type)
            
        Returns:
            Forecaster instance
        """
        model_type = model_type or self.model_type
        
        if model_type not in self.MODEL_REGISTRY:
            raise ValueError(f"Unknown model type: {model_type}. "
                           f"Available: {list(self.MODEL_REGISTRY.keys())}")
        
        model_class = self.MODEL_REGISTRY[model_type]
        return model_class()
    
    def prepare_training_data(
        self,
        demand_df: pd.DataFrame,
        product_df: Optional[pd.DataFrame] = None,
        test_size: float = None
    ) -> tuple:
        """
        Prepare training and test data
        
        Args:
            demand_df: Demand history DataFrame
            product_df: Product attributes DataFrame
            test_size: Proportion of data for testing
            
        Returns:
            Tuple of (X_train, X_test, y_train, y_test)
        """
        logger.info("Preparing training data")
        
        test_size = test_size or (1 - settings.TRAIN_TEST_SPLIT_RATIO)
        
        # Create features
        df = self.feature_engineer.create_all_features(
            demand_df,
            product_df,
            date_column='date',
            value_column='demand',
            group_column='product_id'
        )
        
        # Split features and target
        target_col = 'demand'
        feature_cols = [col for col in df.columns if col != target_col]
        
        # Time-based split
        split_idx = int(len(df) * (1 - test_size))
        
        df_train = df.iloc[:split_idx]
        df_test = df.iloc[split_idx:]
        
        X_train = df_train[feature_cols]
        y_train = df_train[target_col]
        X_test = df_test[feature_cols]
        y_test = df_test[target_col]
        
        logger.info(f"Training set: {X_train.shape}, Test set: {X_test.shape}")
        
        return X_train, X_test, y_train, y_test
    
    def train_model(
        self,
        demand_df: pd.DataFrame,
        product_df: Optional[pd.DataFrame] = None,
        model_type: Optional[str] = None
    ) -> BaseForecaster:
        """
        Train forecasting model
        
        Args:
            demand_df: Demand history DataFrame
            product_df: Product attributes DataFrame
            model_type: Type of model to train
            
        Returns:
            Trained model
        """
        logger.info(f"Training {model_type or self.model_type} model")
        
        # Prepare data
        X_train, X_test, y_train, y_test = self.prepare_training_data(
            demand_df, product_df
        )
        
        # Get model
        self.model = self.get_model(model_type)
        
        # Train
        self.model.train(X_train, y_train)
        
        logger.info("Model training complete")
        
        return self.model
    
    def forecast(
        self,
        demand_df: pd.DataFrame,
        product_df: Optional[pd.DataFrame] = None,
        horizon_days: int = None,
        model: Optional[BaseForecaster] = None
    ) -> pd.DataFrame:
        """
        Generate demand forecast
        
        Args:
            demand_df: Historical demand data
            product_df: Product attributes
            horizon_days: Number of days to forecast
            model: Pre-trained model (if None, uses self.model)
            
        Returns:
            DataFrame with forecasts
        """
        horizon_days = horizon_days or settings.FORECAST_HORIZON_DAYS
        model = model or self.model
        
        if model is None:
            raise ValueError("No model available. Train a model first.")
        
        logger.info(f"Generating {horizon_days}-day forecast")
        
        # Prepare features for forecast period
        # For simplicity, we'll use the last available data
        df = self.feature_engineer.create_all_features(
            demand_df,
            product_df,
            date_column='date',
            value_column='demand',
            group_column='product_id'
        )
        
        # Get feature columns
        feature_cols = [col for col in df.columns if col != 'demand']
        X_forecast = df[feature_cols].tail(horizon_days)
        
        # Generate predictions
        predictions = model.predict(X_forecast)
        
        # Create forecast DataFrame
        forecast_df = pd.DataFrame({
            'date': pd.date_range(
                start=demand_df['date'].max() + pd.Timedelta(days=1),
                periods=horizon_days
            ),
            'forecast': predictions
        })
        
        logger.info(f"Generated forecast: {forecast_df.shape}")
        
        return forecast_df
    
    def save_model(self, filepath: Optional[Path] = None):
        """Save trained model"""
        if self.model is None:
            raise ValueError("No model to save")
        
        filepath = filepath or (settings.MODELS_DIR / f"{self.model_type}_model.pkl")
        self.model.save_model(filepath)
    
    def load_model(self, filepath: Optional[Path] = None):
        """Load trained model"""
        filepath = filepath or (settings.MODELS_DIR / f"{self.model_type}_model.pkl")
        
        self.model = self.get_model()
        self.model.load_model(filepath)
        
        return self.model
