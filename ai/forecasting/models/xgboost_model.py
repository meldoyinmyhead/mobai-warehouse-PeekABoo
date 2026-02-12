"""
XGBoost Forecaster
XGBoost regressor for demand forecasting
"""

import pandas as pd
import numpy as np
from xgboost import XGBRegressor
from typing import Optional

from .base_forecaster import BaseForecaster
from ...config.settings import settings
from ...config.logging_config import get_logger

logger = get_logger("xgboost_model")


class XGBoostForecaster(BaseForecaster):
    """XGBoost forecaster"""
    
    def __init__(
        self,
        n_estimators: int = None,
        learning_rate: float = None,
        max_depth: int = None,
        random_state: int = 42,
        **kwargs
    ):
        """
        Initialize XGBoost forecaster
        
        Args:
            n_estimators: Number of boosting rounds
            learning_rate: Learning rate
            max_depth: Maximum tree depth
            random_state: Random seed
            **kwargs: Additional XGBoost parameters
        """
        super().__init__("xgboost")
        self.n_estimators = n_estimators or settings.XGBOOST_N_ESTIMATORS
        self.learning_rate = learning_rate or settings.XGBOOST_LEARNING_RATE
        self.max_depth = max_depth or settings.XGBOOST_MAX_DEPTH
        self.random_state = random_state
        self.kwargs = kwargs
    
    def train(
        self,
        X_train: pd.DataFrame,
        y_train: pd.Series,
        **kwargs
    ):
        """
        Train the XGBoost model
        
        Args:
            X_train: Training features
            y_train: Training target
        """
        logger.info(f"Training XGBoost (n_estimators={self.n_estimators}, "
                   f"learning_rate={self.learning_rate}, max_depth={self.max_depth})")
        
        # Store feature columns
        self.feature_columns = X_train.columns.tolist()
        
        # Initialize model
        self.model = XGBRegressor(
            n_estimators=self.n_estimators,
            learning_rate=self.learning_rate,
            max_depth=self.max_depth,
            random_state=self.random_state,
            n_jobs=-1,
            **self.kwargs
        )
        
        # Train model
        self.model.fit(X_train, y_train)
        self.is_trained = True
        
        logger.info(f"XGBoost trained with {len(self.feature_columns)} features")
    
    def predict(self, X_test: pd.DataFrame) -> np.ndarray:
        """
        Make predictions
        
        Args:
            X_test: Test features
            
        Returns:
            Array of predictions
        """
        if not self.is_trained:
            raise ValueError("Model must be trained before making predictions")
        
        # Ensure features match training
        if self.feature_columns:
            X_test = X_test[self.feature_columns]
        
        predictions = self.model.predict(X_test)
        
        # Ensure non-negative predictions
        predictions = np.maximum(predictions, 0)
        
        logger.debug(f"Generated {len(predictions)} predictions")
        
        return predictions
    
    def get_feature_importance(self) -> pd.DataFrame:
        """
        Get feature importance
        
        Returns:
            DataFrame with feature importances
        """
        if not self.is_trained:
            raise ValueError("Model must be trained first")
        
        importance_df = pd.DataFrame({
            'feature': self.feature_columns,
            'importance': self.model.feature_importances_
        }).sort_values('importance', ascending=False)
        
        return importance_df
