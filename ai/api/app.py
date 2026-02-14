"""
FastAPI Application
Main API application for AI warehouse service
"""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from ..config.settings import settings
from ..config.logging_config import get_logger
from .routes import forecast, storage, picking, health, route, storage_assignment
from .middleware.error_handler import ErrorHandlerMiddleware
from .middleware.request_logger import RequestLoggerMiddleware

logger = get_logger("api")

# Create FastAPI app
app = FastAPI(
    title=settings.APP_NAME,
    version=settings.APP_VERSION,
    description="AI Service for Warehouse Management: Forecasting, Storage & Picking Optimization",
    docs_url=f"{settings.API_PREFIX}/docs",
    redoc_url=f"{settings.API_PREFIX}/redoc",
    openapi_url=f"{settings.API_PREFIX}/openapi.json"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add custom middleware
app.add_middleware(ErrorHandlerMiddleware)
app.add_middleware(RequestLoggerMiddleware)

# Include routers
app.include_router(health.router, prefix=settings.API_PREFIX, tags=["Health"])
app.include_router(forecast.router, prefix=settings.API_PREFIX, tags=["Forecast"])
app.include_router(storage.router, prefix=settings.API_PREFIX, tags=["Storage"])
app.include_router(picking.router, prefix=settings.API_PREFIX, tags=["Picking"])
app.include_router(route.router,   prefix=settings.API_PREFIX, tags=["Route Optimization"])
app.include_router(storage_assignment.router, prefix=settings.API_PREFIX, tags=["Storage Assignment"])

logger.info(f"FastAPI application initialized: {settings.APP_NAME} v{settings.APP_VERSION}")


@app.on_event("startup")
async def startup_event():
    """Startup event handler"""
    logger.info("Starting AI Warehouse Service")
    logger.info(f"API documentation: http://{settings.API_HOST}:{settings.API_PORT}{settings.API_PREFIX}/docs")


@app.on_event("shutdown")
async def shutdown_event():
    """Shutdown event handler"""
    logger.info("Shutting down AI Warehouse Service")
