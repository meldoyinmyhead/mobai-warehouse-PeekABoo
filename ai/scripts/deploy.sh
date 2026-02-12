#!/bin/bash
# Deployment script

echo "Deploying AI Warehouse Service..."

# Build Docker image
echo "Building Docker image..."
docker build -t ai-warehouse-service:latest .

# Run Docker compose
echo "Starting services..."
docker-compose up -d

echo "Deployment complete!"
echo "API available at http://localhost:8000/api/v1/docs"
