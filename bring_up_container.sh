#!/bin/bash

# Function to check Docker daemon
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        echo "Docker daemon is not running or not accessible. Attempting to restart Docker Desktop..."
        systemctl --user restart docker-desktop

        echo "Waiting for Docker daemon to become available..."
        for i in {1..30}; do
            if docker info >/dev/null 2>&1; then
                echo "Docker daemon is now available"
                return 0
            fi
            sleep 1
        done
        echo "Docker daemon failed to start after 30 seconds"
        return 1
    fi
    return 0
}

# Function to open URLs (unchanged from your original)
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

# Main script execution
echo "Checking Docker daemon..."
if ! check_docker; then
    echo "Unable to connect to Docker daemon. Please ensure Docker Desktop is running."
    exit 1
fi

echo "Pulling the latest images..."
if ! docker compose --profile gpu-nvidia pull; then
    echo "Failed to pull images. Please check your Docker configuration."
    exit 1
fi

echo "Starting the container with GPU support..."
if ! docker compose --profile gpu-nvidia up -d; then
    echo "Failed to start the container. Docker error: $(docker logs)"
    exit 1
fi

# Waiting for services to start with timeout
echo "Waiting for services to start..."
TIMEOUT=60
start_time=$(date +%s)

# Wait for n8n
while ! curl -s http://localhost:5678 > /dev/null; do
    current_time=$(date +%s)
    if [ $((current_time - start_time)) -gt $TIMEOUT ]; then
        echo "Timeout waiting for n8n to start"
        exit 1
    fi
    echo "Waiting for n8n to be available..."
    sleep 2
done

# Reset timer for Qdrant
start_time=$(date +%s)

# Wait for Qdrant
while ! curl -s http://localhost:6333/dashboard > /dev/null; do
    current_time=$(date +%s)
    if [ $((current_time - start_time)) -gt $TIMEOUT ]; then
        echo "Timeout waiting for Qdrant to start"
        exit 1
    fi
    echo "Waiting for Qdrant to be available..."
    sleep 2
done

# Open web pages
open_url "http://localhost:5678"
open_url "http://localhost:6333/dashboard"

echo "Containers are up and services are accessible!"
