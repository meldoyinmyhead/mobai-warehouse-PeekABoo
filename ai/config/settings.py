"""
AI Service Configuration Settings
Centralized configuration management using environment variables
"""

import os
from pathlib import Path
from typing import Optional
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings with environment variable support"""
    
    # Application
    APP_NAME: str = "AI Warehouse Service"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    
    # API Configuration
    API_HOST: str = "0.0.0.0"
    API_PORT: int = 8000
    API_PREFIX: str = "/api/v1"
    CORS_ORIGINS: list = ["*"]
    
    # Paths
    BASE_DIR: Path = Path(__file__).parent.parent
    DATA_DIR: Path = BASE_DIR / "data"
    RAW_DATA_DIR: Path = DATA_DIR / "raw"
    PROCESSED_DATA_DIR: Path = DATA_DIR / "processed"
    MODELS_DIR: Path = DATA_DIR / "models"
    CACHE_DIR: Path = DATA_DIR / "cache"
    
    # Data Files
    RAW_DATA_FILE: str = "WMS_Hackathon_DataPack_Templates_FR_FV_B7_ONLY.xlsx"
    
    # Model Configuration
    FORECAST_MODEL: str = "xgboost"  # Options: naive, exponential_smoothing, random_forest, xgboost
    FORECAST_HORIZON_DAYS: int = 7
    TRAIN_TEST_SPLIT_RATIO: float = 0.8
    
    # Feature Engineering
    ROLLING_WINDOW_SIZES: list = [7, 14, 30]
    LAG_FEATURES: list = [1, 7, 14, 30]
    
    # Product Segmentation (ABC-XYZ)
    ABC_THRESHOLDS: dict = {"A": 0.8, "B": 0.95, "C": 1.0}
    XYZ_CV_THRESHOLDS: dict = {"X": 0.5, "Y": 1.0, "Z": float('inf')}
    
    # Storage Optimization
    STORAGE_ZONES: list = ["PICKING", "RESERVE", "BULK"]
    DISTANCE_WEIGHT: float = 0.4
    FREQUENCY_WEIGHT: float = 0.3
    VELOCITY_WEIGHT: float = 0.3
    
    # Picking Optimization
    PICKING_STRATEGY: str = "wave"  # Options: wave, batch, zone
    MAX_PICK_DISTANCE: float = 1000.0
    PICKING_BATCH_SIZE: int = 20
    
    # ML Model Hyperparameters
    RANDOM_FOREST_N_ESTIMATORS: int = 100
    RANDOM_FOREST_MAX_DEPTH: Optional[int] = None
    XGBOOST_N_ESTIMATORS: int = 100
    XGBOOST_LEARNING_RATE: float = 0.1
    XGBOOST_MAX_DEPTH: int = 6
    
    # Database (Optional - for future use)
    DATABASE_URL: Optional[str] = None
    
    # Logging
    LOG_LEVEL: str = "INFO"
    LOG_FORMAT: str = "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    
    # Cache
    ENABLE_CACHE: bool = True
    CACHE_TTL_SECONDS: int = 3600
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = True


# Global settings instance
settings = Settings()


# Ensure directories exist
for directory in [
    settings.DATA_DIR,
    settings.RAW_DATA_DIR,
    settings.PROCESSED_DATA_DIR,
    settings.MODELS_DIR,
    settings.CACHE_DIR,
]:
    directory.mkdir(parents=True, exist_ok=True)
