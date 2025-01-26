#!/bin/bash

# Bring up the container with GPU support and open relevant web pages

echo "Pulling the latest images..."
docker compose --profile gpu-nvidia pull || {
    echo "Failed to pull images. Please check your Docker configuration."
    exit 1
}

echo "Starting the container with GPU support..."
if ! docker compose --profile gpu-nvidia up -d; then
    echo "Failed to start the container. Docker error: $(docker logs)"
    exit 1
fi

# Waiting for services to start (retry mechanism)
echo "Waiting for services to start..."
until curl -s http://localhost:5678 > /dev/null; do
    echo "Waiting for n8n to be available..."
    sleep 2
done
until curl -s http://localhost:6333/dashboard > /dev/null; do
    echo "Waiting for Qdrant to be available..."
    sleep 2
done

# Function to open URLs in the browser
open_url() {
    URL=$1
    echo "Opening $URL..."
    if command -v xdg-open &> /dev/null; then
        xdg-open "$URL"
    elif command -v open &> /dev/null; then
        open "$URL"
    else
        echo "Please open your browser and navigate to: $URL"
    fi
}

# Open web pages
open_url "http://localhost:5678"
open_url "http://localhost:6333/dashboard"

echo "Containers are up and services are accessible!"

