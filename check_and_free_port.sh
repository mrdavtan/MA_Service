#!/bin/bash

# Function to check and free a port
check_and_free_port() {
  PORT=$1

  echo "Checking if port $PORT is in use..."

  # Use lsof to find the process holding the port
  PROCESS_INFO=$(sudo lsof -i :$PORT | grep LISTEN)

  if [[ -n "$PROCESS_INFO" ]]; then
    echo "Port $PORT is in use."
    echo "$PROCESS_INFO"

    # Extract the PID of the process
    PID=$(echo "$PROCESS_INFO" | awk '{print $2}')

    if [[ -n "$PID" ]]; then
      echo "Killing process with PID $PID..."
      sudo kill -9 $PID
      echo "Process $PID killed. Port $PORT should now be free."
    else
      echo "Could not determine the PID. Manual intervention required."
    fi
  else
    echo "Port $PORT is not in use."
  fi
}

# Check if a port number was provided
if [[ -z "$1" ]]; then
  echo "Usage: $0 <port-number>"
  exit 1
fi

# Call the function with the provided port number
check_and_free_port $1

