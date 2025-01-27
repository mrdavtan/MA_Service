# Source utilities
if [ -f "./utils.sh" ]; then
    source ./utils.sh
else
    echo "ERROR: utils.sh not found in current directory"
    exit 1
fi

# Function to stop all services
stop_services() {
    log "Stopping services..."

    # Stop Docker containers
    log "Stopping Docker containers..."
    docker compose --profile gpu-nvidia down || warn "No containers to stop"

    # Handle system-level ollama
    log "Checking for system-level ollama..."
    # Try to stop ollama service if it exists
    sudo systemctl stop ollama 2>/dev/null || true

    # Check specifically for ollama process
    if pgrep -x "ollama" > /dev/null; then
        log "Found system ollama process, stopping it..."
        sudo pkill -9 ollama
        sleep 2
    fi

    # Verify all ports are free
    for port in 11434 6333 5678; do
        if sudo lsof -i :$port > /dev/null 2>&1; then
            warn "Port $port is still in use"
        else
            log "Port $port is free"
        fi
    done

    # Final verification
    log "Verifying services are stopped..."
    running_containers=$(docker ps -q | wc -l)
    if [ "$running_containers" -gt 0 ]; then
        warn "There are still $running_containers containers running"
    else
        log "No containers running"
    fi
}

# Run the stop function
stop_services
