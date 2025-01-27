#!/bin/bash

# Ensure Docker Desktop socket is used
DOCKER_SOCKET_PATH="$HOME/.docker/desktop/docker.sock"

# Check if Docker Desktop socket exists
if [ ! -S "$DOCKER_SOCKET_PATH" ]; then
    echo "Docker Desktop socket not found at $DOCKER_SOCKET_PATH. Exiting..."
    exit 1
fi

# Set the Docker host to the Docker Desktop socket
export DOCKER_HOST="unix://$DOCKER_SOCKET_PATH"

# Add the user to the docker group if not already a member
if ! groups $USER | grep &>/dev/null '\bdocker\b'; then
    echo "Adding $USER to the docker group..."
    sudo usermod -aG docker $USER
    echo "You need to log out and log back in for group changes to take effect."
fi

# Clean up Docker system (prune)
echo "Pruning Docker system..."
docker system prune -f

# Check if Docker daemon is running using the Docker Desktop socket
echo "Checking if Docker is running..."
if ! docker ps &>/dev/null; then
    echo "Docker is not running, attempting to restart Docker Desktop..."
    # Attempt to restart Docker Desktop service (this may vary depending on your OS)
    if command -v systemctl &>/dev/null; then
        sudo systemctl restart docker
    else
        echo "Please manually restart Docker Desktop and try again."
        exit 1
    fi

    # Retry Docker ps command
    if ! docker ps &>/dev/null; then
        echo "Unable to connect to Docker daemon after restart."
        exit 1
    fi
fi

# Confirm Docker is now working
echo "Docker is running. Displaying active containers..."
docker ps

# Print logs if necessary (optional)
echo "Checking Docker Desktop logs..."
cat "$HOME/.docker/desktop/logs"

