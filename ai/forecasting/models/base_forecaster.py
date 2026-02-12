"""
Base Forecaster
Abstract base class for all forecasting models
"""

from abc import ABC, abstractmethod
import pandas as pd
import numpy as np
from typing import Dict, Any, Optional
import pickle
from pathlib import Path

from ...config.logging_config import get_logger

logger = get_logger("base_forecaster")


class BaseForecaster(ABC):
    """Abstract base class for forecasting models"""
    
    def __init__(self, model_name: str):
        """
        Initialize base forecaster
        
        Args:
            model_name: Name of the forecasting model
        """
        self.model_name = model_name
        self.model = None
        self.is_trained = False
        self.feature_columns = []
        self.target_column = 'demand'
    
    @abstractmethod
    def train(
        self,
        X_train: pd.DataFrame,
        y_train: pd.Series,
        **kwargs
    ):
        """
        Train the forecasting model
        
        Args:
            X_train: Training features
            y_train: Training target
            **kwargs: Additional training parameters
        """
        pass
    
    @abstractmethod
    def predict(
        self,
        X_test: pd.DataFrame
    ) -> np.ndarray:
        """
        Make predictions
        
        Args:
            X_test: Test features
            
        Returns:
            Array of predictions
        """
        pass
    
    def fit(self, X: pd.DataFrame, y: pd.Series, **kwargs):
        """Alias for train method"""
        return self.train(X, y, **kwargs)
    
    def forecast(self, X: pd.DataFrame) -> np.ndarray:
        """Alias for predict method"""
        return self.predict(X)
    
    def save_model(self, filepath: Path):
        """
        Save trained model to disk
        
        Args:
            filepath: Path to save the model
        """
        if not self.is_trained:
            raise ValueError("Model is not trained yet")
        
        model_data = {
            'model': self.model,
            'model_name': self.model_name,
            'feature_columns': self.feature_columns,
            'target_column': self.target_column
        }
        
        with open(filepath, 'wb') as f:
            pickle.dump(model_data, f)
        
        logger.info(f"Saved model to {filepath}")
    
    def load_model(self, filepath: Path):
        """
        Load trained model from disk
        
        Args:
            filepath: Path to the saved model
        """
        with open(filepath, 'rb') as f:
            model_data = pickle.load(f)
        
        self.model = model_data['model']
        self.model_name = model_data['model_name']
        self.feature_columns = model_data['feature_columns']
        self.target_column = model_data['target_column']
        self.is_trained = True
        
        logger.info(f"Loaded model from {filepath}")
    
    def get_feature_importance(self) -> Optional[pd.DataFrame]:
        """
        Get feature importance (if supported by model)
        
        Returns:
            DataFrame with feature importances or None
        """
        return None
    
    def __repr__(self):
        return f"{self.__class__.__name__}(model_name='{self.model_name}', trained={self.is_trained})"
