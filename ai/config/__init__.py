"""Configuration module for AI service"""

from .settings import settings
from .logging_config import setup_logging

__all__ = ["settings", "setup_logging"]
