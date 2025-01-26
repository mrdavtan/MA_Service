#!/bin/bash

# Bring up the container with GPU support and open relevant web pages

echo "Pulling the latest images..."
docker compose --profile gpu-nvidia pull || {
    echo "Failed to pull images. Please check your Docker configuration."
    exit 1
}

echo "Creating the container..."
docker compose create || {
    echo "Failed to create the container. Please check your Docker configuration."
    exit 1
}

echo "Starting the container with GPU support..."
docker compose --profile gpu-nvidia up -d || {
    echo "Failed to start the container. Please check your Docker configuration."
    exit 1
}

echo "Waiting for services to start..."
sleep 5  # Adjust the delay if needed

echo "Opening n8n web page..."
if command -v xdg-open &> /dev/null; then
    xdg-open http://localhost:5678
elif command -v open &> /dev/null; then
    open http://localhost:5678
else
    echo "Please open your browser and navigate to: http://localhost:5678"
fi

echo "Opening Qdrant web page..."
if command -v xdg-open &> /dev/null; then
    xdg-open http://localhost:6333/dashboard
elif command -v open &> /dev/null; then
    open http://localhost:6333/dashboard
else
    echo "Please open your browser and navigate to: http://localhost:6333/dashboard"
fi

echo "Containers are up and services are accessible!"

