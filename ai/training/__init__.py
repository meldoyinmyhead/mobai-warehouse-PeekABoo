"""Training module"""

from .train_forecast_models import train_all_models
from .evaluate_models import evaluate_all_models

__all__ = ["train_all_models", "evaluate_all_models"]
