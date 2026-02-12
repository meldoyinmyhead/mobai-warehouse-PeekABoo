"""Request logging middleware"""

from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware
import time

from ...config.logging_config import get_logger

logger = get_logger("request_logger")


class RequestLoggerMiddleware(BaseHTTPMiddleware):
    """Log all API requests and responses"""
    
    async def dispatch(self, request: Request, call_next):
        start_time = time.time()
        
        # Log request
        logger.info(f"Request: {request.method} {request.url.path}")
        
        # Process request
        response = await call_next(request)
        
        # Calculate duration
        duration = time.time() - start_time
        
        # Log response
        logger.info(f"Response: {response.status_code} | Duration: {duration:.3f}s")
        
        return response
