# Source utilities
if [ -f "./utils.sh" ]; then
    source ./utils.sh
else
    echo "ERROR: utils.sh not found in current directory"
    exit 1
fi

# Function to clean up Docker environment
cleanup_docker() {
    log "Cleaning up Docker environment..."

    # First stop all Docker containers
    log "Stopping all containers..."
    docker compose --profile gpu-nvidia down || warn "No containers to stop"

    # Force remove any remaining containers
    log "Force removing any stuck containers..."
    docker rm -f $(docker ps -aq) 2>/dev/null || true

    # Handle system-level ollama before port checks
    log "Checking for system-level ollama..."
    # Try to stop ollama service if it exists
    sudo systemctl stop ollama 2>/dev/null || true

    # Check specifically for ollama process
    if pgrep -x "ollama" > /dev/null; then
        log "Found system ollama process, stopping it..."
        sudo pkill -9 ollama
        sleep 2
    fi

    # Kill any processes using our required ports
    for port in 11434 6333 5678; do
        log "Checking port $port..."
        if sudo lsof -ti :$port > /dev/null; then
            log "Killing process using port $port"
            sudo lsof -ti :$port | xargs sudo kill -9
        fi

        # Double check with fuser
        log "Double checking port $port with fuser..."
        sudo fuser -k $port/tcp 2>/dev/null || true

        # Verify port is free
        if sudo lsof -i :$port > /dev/null 2>&1; then
            warn "Port $port is still in use after cleanup attempts"
        else
            log "Port $port is free"
        fi
    done

    # Wait a moment for ports to be released
    sleep 5

    # Prune Docker system
    log "Pruning Docker system..."
    if docker system prune -f; then
        log "Docker system pruned successfully"
    else
        warn "Docker system prune failed"
    fi

    # Final verification
    log "Verifying cleanup..."
    running_containers=$(docker ps -q | wc -l)
    if [ "$running_containers" -gt 0 ]; then
        warn "There are still $running_containers containers running"
    else
        log "No containers running"
    fi
}
