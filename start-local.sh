#!/bin/bash
# Start IBM Content Services MCP Server - Local Development
# Loads environment variables from .env.local and starts the core server

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

# Display configuration (hide password)
echo ""
echo "==================================="
echo "MCP Server Configuration (Local)"
echo "==================================="
echo "SERVER_URL: $SERVER_URL"
echo "USERNAME: $USERNAME"
echo "PASSWORD: ****"
echo "OBJECT_STORE: $OBJECT_STORE"
echo "SSL_ENABLED: $SSL_ENABLED"
echo "LOG_LEVEL: $LOG_LEVEL"
echo "MCP_TRANSPORT: $MCP_TRANSPORT"
echo "==================================="
echo ""

# Start the Core MCP Server
echo "Starting Core Content Services MCP Server..."
cd "$SCRIPT_DIR"
uv run core-cs-mcp-server
