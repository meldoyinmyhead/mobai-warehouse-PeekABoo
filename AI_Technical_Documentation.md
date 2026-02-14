# AI Warehouse Management System - Technical Documentation

## Overview

This document provides technical documentation for the AI-powered warehouse management system.

## Architecture

- **Core Module**: Data loading, feature engineering, segmentation
- **Forecasting Module**: Demand prediction using ML models
- **Optimization Module**: Storage and picking optimization
- **API Module**: RESTful API for integration

## Models

### Forecasting Models

1. **Naive Baseline**: 7-day moving average
2. **Exponential Smoothing**: Holt-Winters method
3. **Random Forest**: Tree-based ensemble
4. **XGBoost**: Gradient boosting

### Optimization Algorithms

1. **Storage Optimization**: ABC-XYZ analysis + distance minimization
2. **Picking Optimization**: Wave/batch/zone picking strategies
3. **Route Optimization**: TSP-based route planning

## API Endpoints

- `POST /api/v1/forecast`: Generate demand forecast
- `POST /api/v1/optimize-storage`: Optimize storage locations
- `POST /api/v1/optimize-picking`: Optimize picking operations
- `GET /api/v1/health`: Health check

## Configuration

See [config/settings.py](ai/config/settings.py) for all configuration options.

## Usage Examples

See API documentation at `/api/v1/docs` when running the service.
