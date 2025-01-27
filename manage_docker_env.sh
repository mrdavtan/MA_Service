#!/bin/bash

# Set strict error handling
set -euo pipefail

# Source utilities
if [ -f "./utils.sh" ]; then
    source ./utils.sh
else
    echo "ERROR: utils.sh not found in current directory"
    exit 1
fi

# Source cleanup script
if [ -f "./cleanup.sh" ]; then
    source ./cleanup.sh
else
    error "cleanup.sh not found in current directory"
    exit 1
fi

# Source stop script
if [ -f "./stop.sh" ]; then
    source ./stop.sh
else
    error "stop.sh not found in current directory"
    exit 1
fi

# Function to check Docker daemon
check_docker() {
    log "Checking Docker daemon status..."
    if ! docker info &>/dev/null; then
        warn "Docker is not running, attempting to restart Docker Desktop..."
        if command -v systemctl &>/dev/null; then
            systemctl --user restart docker-desktop
            log "Waiting for Docker to initialize (10 seconds)..."
            sleep 10
        else
            error "Please manually restart Docker Desktop and try again."
            return 1
        fi
    fi

    if ! docker info &>/dev/null; then
        error "Unable to connect to Docker daemon after restart."
        return 1
    fi

    log "Docker is running properly!"
    return 0
}

# Function to build services
build_services() {
    log "Building nginx-chat and n8n services..."
    if ! docker compose build nginx-chat n8n; then
        error "Build failed"
        return 1
    fi
    log "Build completed successfully!"

    # Stop any services that might have started during build
    log "Stopping any services started during build..."
    stop_services
}

# Function to bring up services
bring_up_services() {
    log "Starting services with GPU support..."

    # Pull latest images
    log "Pulling latest images..."
    if ! docker compose --profile gpu-nvidia pull; then
        error "Failed to pull images"
        return 1
    fi

    # Start containers
    if ! docker compose --profile gpu-nvidia up -d; then
        error "Failed to start containers"
        return 1
    fi

    # Wait for services with timeout
    TIMEOUT=60
    log "Waiting for services to start (timeout: ${TIMEOUT}s)..."

    # Wait for n8n
    start_time=$(date +%s)
    while ! curl -s http://localhost:5678 > /dev/null; do
        current_time=$(date +%s)
        if [ $((current_time - start_time)) -gt $TIMEOUT ]; then
            error "Timeout waiting for n8n to start"
            return 1
        fi
        echo "Waiting for n8n..."
        sleep 2
    done

    # Wait for Qdrant
    start_time=$(date +%s)
    while ! curl -s http://localhost:6333/dashboard > /dev/null; do
        current_time=$(date +%s)
        if [ $((current_time - start_time)) -gt $TIMEOUT ]; then
            error "Timeout waiting for Qdrant to start"
            return 1
        fi
        echo "Waiting for Qdrant..."
        sleep 2
    done

    log "All services are up and running!"

    # Open services in browser
    if command -v xdg-open &>/dev/null; then
        xdg-open "http://localhost:5678"
        xdg-open "http://localhost:6333/dashboard"
    elif command -v open &>/dev/null; then
        open "http://localhost:5678"
        open "http://localhost:6333/dashboard"
    else
        log "Please open your browser and navigate to:"
        log "- http://localhost:5678"
        log "- http://localhost:6333/dashboard"
    fi
}

# Main script execution
main() {
    case "${1:-help}" in
        fix)
            check_docker
            ;;
        clean)
            cleanup_docker
            ;;
        stop)
            stop_services
            ;;
        build)
            check_docker && build_services
            ;;
        bring-up)
            check_docker && bring_up_services
            ;;
        restart)
            stop_services && check_docker && bring_up_services
            ;;
        help|*)
            echo "Usage: $0 <command>"
            echo "Commands:"
            echo "  fix      - Fix Docker Desktop connection issues"
            echo "  clean    - Clean up Docker environment"
            echo "  stop     - Stop running services"
            echo "  build    - Build services"
            echo "  bring-up - Pull images and bring up all services"
            echo "  restart  - Stop and restart services"
            ;;
    esac
}

main "$@"
