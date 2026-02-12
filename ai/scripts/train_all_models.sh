#!/bin/bash
# Train all forecasting models

echo "Training all forecasting models..."

python -m ai.training.train_forecast_models

echo "Model training complete!"
