#!/bin/bash

echo "Stopping and removing all containers..."
# Stop and remove all running containers
docker ps -q | xargs -r docker stop
docker ps -aq | xargs -r docker rm

echo "Cleaning up orphaned containers and networks..."
# Remove orphaned containers and networks
docker compose down --remove-orphans

echo "Checking for processes using ports 11434 and 6333..."
# Function to free a specific port
free_port() {
    PORT=$1
    if command -v lsof >/dev/null 2>&1; then
        PROC=$(sudo lsof -t -i:$PORT)
        if [ ! -z "$PROC" ]; then
            echo "Found process using port $PORT. Attempting to terminate..."
            echo $PROC | xargs -r sudo kill -9
            echo "Port $PORT has been freed."
        else
            echo "No process is using port $PORT."
        fi
    else
        echo "lsof command not found. Cannot check port $PORT."
    fi
}

# Check and free ports
free_port 11434
free_port 6333

echo "Pruning unused Docker resources..."
# Remove unused images, volumes, and networks
docker system prune -af --volumes

echo "Cleanup complete."

