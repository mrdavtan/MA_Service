#!/bin/bash

echo "Stopping and removing Ollama containers..."
docker ps -q --filter "name=ollama" | xargs -r docker stop
docker ps -aq --filter "name=ollama" | xargs -r docker rm

echo "Cleaning up orphaned containers..."
docker compose --profile gpu-nvidia down --remove-orphans

echo "Checking for processes using port 11434..."
if command -v lsof >/dev/null 2>&1; then
    PROC=$(sudo lsof -t -i:11434)
    if [ ! -z "$PROC" ]; then
        echo "Found process using port 11434. Attempting to terminate..."
        echo $PROC | xargs sudo kill -9
    fi
fi

#echo "Cleanup complete. Starting containers..."
#./bring_up_container.sh
