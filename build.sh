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

# Check Docker before proceeding
echo "Checking Docker daemon..."
if ! check_docker; then
    echo "Unable to connect to Docker daemon. Please ensure Docker Desktop is running."
    exit 1
fi

# Build the services
echo "Building nginx-chat and n8n services..."
if ! docker compose build nginx-chat n8n; then
    echo "Build failed. Check the error messages above."
    exit 1
fi

echo "Build completed successfully!"
