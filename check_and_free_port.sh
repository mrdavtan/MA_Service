#!/bin/bash
check_and_free_port() {
  PORT=$1
  echo "Checking if port $PORT is in use..."

  # First check if it's a Docker container
  DOCKER_CONTAINER=$(docker ps --format '{{.Names}}' --filter "publish=$PORT")

  if [[ -n "$DOCKER_CONTAINER" ]]; then
    echo "Port $PORT is used by Docker container: $DOCKER_CONTAINER"
    echo "Use docker-compose down to properly stop containers"
    return
  }

  # If not Docker, then check other processes
  PROCESS_INFO=$(sudo lsof -i :$PORT | grep LISTEN)
  if [[ -n "$PROCESS_INFO" ]]; then
    echo "Port $PORT is in use."
    echo "$PROCESS_INFO"
    PID=$(echo "$PROCESS_INFO" | awk '{print $2}')
    if [[ -n "$PID" ]]; then
      echo "Attempting graceful shutdown of process $PID..."
      sudo kill -15 $PID  # Using SIGTERM instead of SIGKILL
      sleep 2
      if kill -0 $PID 2>/dev/null; then
        echo "Process didn't shut down gracefully, using force..."
        sudo kill -9 $PID
      fi
    fi
  else
    echo "Port $PORT is not in use."
  fi
}

if [[ -z "$1" ]]; then
  echo "Usage: $0 <port-number>"
  exit 1
fi

check_and_free_port $1
