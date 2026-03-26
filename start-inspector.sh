#!/bin/bash
# Launch MCP Inspector with Local Configuration
# This provides an interactive web UI to test MCP tools

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
echo "=========================================="
echo "MCP Inspector - Local Configuration"
echo "=========================================="
echo "SERVER_URL: $SERVER_URL"
echo "USERNAME: $USERNAME"
echo "PASSWORD: ****"
echo "OBJECT_STORE: $OBJECT_STORE"
echo "SSL_ENABLED: $SSL_ENABLED"
echo "=========================================="
echo ""
echo "Starting MCP Inspector..."
echo "This will open a web browser with the MCP Inspector UI."
echo ""
echo "In the Inspector, you can:"
echo "  - View all available tools (including create_document_from_url)"
echo "  - Test tools interactively"
echo "  - View request/response JSON"
echo ""
echo "Press Ctrl+C to stop the inspector"
echo ""

# Change to project directory
cd "$SCRIPT_DIR"

# Launch MCP Inspector
# It will start the core-cs-mcp-server as a subprocess
npx @modelcontextprotocol/inspector uv run core-cs-mcp-server
