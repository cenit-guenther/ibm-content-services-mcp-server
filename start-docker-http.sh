#!/bin/bash
# Start IBM Content Services MCP Server with Docker (HTTP Streamable Transport)
# This script runs the server in a Docker container with HTTP transport for remote access.
#
# Usage: ./start-docker-http.sh [server] [port]
#
#   server  Which MCP server to start (default: core)
#             core         - Core Content Services Server          (default port 8000)
#             legal-hold   - Legal Hold Server                     (default port 8001)
#             ai-insight   - AI Document Insight Server            (default port 8002)
#             property     - Property Extraction & Classification   (default port 8003)
#
#   port    Override the default port (optional)
#
# Examples:
#   ./start-docker-http.sh                    # starts core server on port 8000
#   ./start-docker-http.sh legal-hold         # starts legal-hold server on port 8001
#   ./start-docker-http.sh ai-insight 9000    # starts ai-insight server on port 9000

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# ---------------------------------------------------------------------------
# Server selection
# ---------------------------------------------------------------------------
SERVER_SHORT="${1:-core}"

case "$SERVER_SHORT" in
  core)
    SERVER_CMD="core-cs-mcp-server"
    DEFAULT_PORT=8000
    ;;
  legal-hold)
    SERVER_CMD="legal-hold-cs-mcp-server"
    DEFAULT_PORT=8001
    ;;
  ai-insight)
    SERVER_CMD="ai-document-insight-cs-mcp-server"
    DEFAULT_PORT=8002
    ;;
  property)
    SERVER_CMD="property-extraction-and-classification-cs-mcp-server"
    DEFAULT_PORT=8003
    ;;
  *)
    echo "Error: Unknown server '$SERVER_SHORT'"
    echo ""
    echo "Valid values: core | legal-hold | ai-insight | property"
    echo "Usage: ./start-docker-http.sh [server] [port]"
    exit 1
    ;;
esac

MCP_PORT="${2:-${MCP_PORT:-$DEFAULT_PORT}}"

# ---------------------------------------------------------------------------
# Load environment variables from .env.local
# ---------------------------------------------------------------------------
if [ -f "$SCRIPT_DIR/.env.local" ]; then
    echo "Loading environment variables from .env.local..."
    export $(grep -v '^#' "$SCRIPT_DIR/.env.local" | xargs)
else
    echo "Error: .env.local file not found!"
    exit 1
fi

# Docker image and container configuration
DOCKER_IMAGE="docker.eim.cloud-cenit.com/mcp/cs-mcp-server:latest"
CONTAINER_NAME="cs-mcp-server-${SERVER_SHORT}"

# MCP Transport configuration for Docker
MCP_TRANSPORT="streamable-http"
MCP_HOST="0.0.0.0"

# Display configuration (hide password)
echo ""
echo "=========================================="
echo "MCP Server Docker Configuration (Local)"
echo "=========================================="
echo "Server:         $SERVER_SHORT ($SERVER_CMD)"
echo "Docker Image:   $DOCKER_IMAGE"
echo "Container Name: $CONTAINER_NAME"
echo "SERVER_URL:     $SERVER_URL"
echo "USERNAME:       $USERNAME"
echo "PASSWORD:       ****"
echo "OBJECT_STORE:   $OBJECT_STORE"
echo "SSL_ENABLED:    $SSL_ENABLED"
echo "MCP_TRANSPORT:  $MCP_TRANSPORT"
echo "MCP_HOST:       $MCP_HOST"
echo "MCP_PORT:       $MCP_PORT"
echo "=========================================="
echo ""

# Check if container is already running
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo "Stopping and removing existing container '$CONTAINER_NAME'..."
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
echo "  http://localhost:${MCP_PORT}/cs-mcp-server/mcp"
echo ""
echo "To view logs: docker logs -f $CONTAINER_NAME"
echo "To stop:      docker stop $CONTAINER_NAME"
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
  -e SERVER_CMD="$SERVER_CMD" \
  "$DOCKER_IMAGE"

# Wait for container to start
echo "Waiting for container to start..."
sleep 3

# Check if container is running
if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo ""
    echo "✓ Container '$CONTAINER_NAME' started successfully!"
    echo ""
    echo "View logs:"
    echo "  docker logs -f $CONTAINER_NAME"
    echo ""
    echo "Test the server:"
    echo "  curl http://localhost:${MCP_PORT}/cs-mcp-server/mcp"
    echo ""
    echo "Stop the server:"
    echo "  docker stop $CONTAINER_NAME"
    echo ""
else
    echo ""
    echo "✗ Container '$CONTAINER_NAME' failed to start. Check logs:"
    echo "  docker logs $CONTAINER_NAME"
    echo ""
    exit 1
fi
