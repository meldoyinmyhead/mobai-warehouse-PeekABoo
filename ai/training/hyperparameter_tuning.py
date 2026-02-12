"""
Hyperparameter Tuning
Grid search and random search for model optimization
"""

from sklearn.model_selection import GridSearchCV, RandomizedSearchCV
from sklearn.ensemble import RandomForestRegressor
from xgboost import XGBRegressor
import pandas as pd

from ..config.logging_config import get_logger

logger = get_logger("hyperparameter_tuning")


def tune_random_forest(X_train: pd.DataFrame, y_train: pd.Series, method: str = "grid") -> dict:
    """Hyperparameter tuning for Random Forest"""
    logger.info(f"Tuning Random Forest using {method} search")
    
    param_grid = {
        'n_estimators': [50, 100, 200],
        'max_depth': [None, 10, 20, 30],
        'min_samples_split': [2, 5, 10],
        'min_samples_leaf': [1, 2, 4]
    }
    
    rf = RandomForestRegressor(random_state=42)
    
    if method == "grid":
        search = GridSearchCV(rf, param_grid, cv=3, scoring='neg_mean_absolute_error', n_jobs=-1)
    else:
        search = RandomizedSearchCV(rf, param_grid, n_iter=10, cv=3, scoring='neg_mean_absolute_error', n_jobs=-1)
    
    search.fit(X_train, y_train)
    
    logger.info(f"Best parameters: {search.best_params_}")
    logger.info(f"Best score: {-search.best_score_:.4f}")
    
    return {
        'best_params': search.best_params_,
        'best_score': -search.best_score_,
        'best_model': search.best_estimator_
    }


def tune_xgboost(X_train: pd.DataFrame, y_train: pd.Series, method: str = "grid") -> dict:
    """Hyperparameter tuning for XGBoost"""
    logger.info(f"Tuning XGBoost using {method} search")
    
    param_grid = {
        'n_estimators': [50, 100, 200],
        'max_depth': [3, 6, 9],
        'learning_rate': [0.01, 0.1, 0.3],
        'subsample': [0.7, 0.8, 1.0]
    }
    
    xgb = XGBRegressor(random_state=42)
    
    if method == "grid":
        search = GridSearchCV(xgb, param_grid, cv=3, scoring='neg_mean_absolute_error', n_jobs=-1)
    else:
        search = RandomizedSearchCV(xgb, param_grid, n_iter=10, cv=3, scoring='neg_mean_absolute_error', n_jobs=-1)
    
    search.fit(X_train, y_train)
    
    logger.info(f"Best parameters: {search.best_params_}")
    logger.info(f"Best score: {-search.best_score_:.4f}")
    
    return {
        'best_params': search.best_params_,
        'best_score': -search.best_score_,
        'best_model': search.best_estimator_
    }
