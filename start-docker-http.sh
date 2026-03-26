#!/bin/bash
# Start IBM Content Services MCP Server with Docker (HTTP Streamable Transport)
# This script runs the server in a Docker container with HTTP transport for remote access

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Load environment variables from .env.local
if [ -f "$SCRIPT_DIR/.env.local" ]; then
    echo "Loading environment variables from .env.local..."
    export $(grep -v '^#' "$SCRIPT_DIR/.env.local" | xargs)
else
    echo "Error: .env.local file not found!"
    exit 1
fi

# Docker image configuration
DOCKER_IMAGE="docker.eim.cloud-cenit.com/mcp/cs-mcp-server:latest"
CONTAINER_NAME="cs-mcp-server-local"

# MCP Transport configuration for Docker
MCP_TRANSPORT="streamable-http"
MCP_HOST="0.0.0.0"
MCP_PORT="8000"

# Display configuration (hide password)
echo ""
echo "=========================================="
echo "MCP Server Docker Configuration (Local)"
echo "=========================================="
echo "Docker Image: $DOCKER_IMAGE"
echo "Container Name: $CONTAINER_NAME"
echo "SERVER_URL: $SERVER_URL"
echo "USERNAME: $USERNAME"
echo "PASSWORD: ****"
echo "OBJECT_STORE: $OBJECT_STORE"
echo "SSL_ENABLED: $SSL_ENABLED"
echo "MCP_TRANSPORT: $MCP_TRANSPORT"
echo "MCP_HOST: $MCP_HOST"
echo "MCP_PORT: $MCP_PORT"
echo "=========================================="
echo ""

# Check if container is already running
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Stopping and removing existing container..."
    docker stop "$CONTAINER_NAME" 2>/dev/null
    docker rm "$CONTAINER_NAME" 2>/dev/null
fi

# Pull latest image
echo "Pulling latest Docker image..."
docker pull "$DOCKER_IMAGE"

echo ""
echo "Starting MCP Server in Docker container..."
echo ""
echo "The server will be accessible at:"
echo "  http://localhost:8000/cs-mcp-server/mcp"
echo ""
echo "To view logs: docker logs -f $CONTAINER_NAME"
echo "To stop: docker stop $CONTAINER_NAME"
echo ""

# Start the container
# Note: Use host.docker.internal for accessing localhost from within container on Windows/Mac
# On Linux, use --network host instead
docker run -d \
  --name "$CONTAINER_NAME" \
  --network host \
  -e SERVER_URL="$SERVER_URL" \
  -e USERNAME="$USERNAME" \
  -e PASSWORD="$PASSWORD" \
  -e OBJECT_STORE="$OBJECT_STORE" \
  -e SSL_ENABLED="$SSL_ENABLED" \
  -e LOG_LEVEL="DEBUG" \
  -e MCP_TRANSPORT="$MCP_TRANSPORT" \
  -e MCP_HOST="$MCP_HOST" \
  -e MCP_PORT="$MCP_PORT" \
  -e SERVER_CMD="core-cs-mcp-server" \
  "$DOCKER_IMAGE"

# Wait for container to start
echo "Waiting for container to start..."
sleep 3

# Check if container is running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo ""
    echo "✓ Container started successfully!"
    echo ""
    echo "View logs:"
    echo "  docker logs -f $CONTAINER_NAME"
    echo ""
    echo "Test the server:"
    echo "  curl http://localhost:8000/cs-mcp-server/mcp"
    echo ""
    echo "Stop the server:"
    echo "  docker stop $CONTAINER_NAME"
    echo ""
else
    echo ""
    echo "✗ Container failed to start. Check logs:"
    echo "  docker logs $CONTAINER_NAME"
    echo ""
    exit 1
fi
