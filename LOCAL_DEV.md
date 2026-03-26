# Local Development Environment Configuration

This directory contains configuration for local development and testing.

## Files

- **`.env.local`**: Environment variables for local FileNet CPE server
- **`start-local.sh`**: Script to start the MCP server with local configuration

## Quick Start

### 1. Start the Local MCP Server

```bash
cd /home/guenther_d/gitrepos/presales/ibm-content-services-mcp-server
./start-local.sh
```

### 2. Test the Server

The server will start in stdio mode. You can test it by sending MCP protocol messages via stdin.

### 3. Configuration Details

**Local FileNet CPE Server:**
- URL: `http://localhost:9080/content-services-graphql/graphql`
- Username: `p8admin`
- Password: `CENIT-master1!`
- Object Store: `ecm_test`
- SSL: Disabled

**MCP Server Settings:**
- Transport: `stdio` (standard input/output)
- Log Level: `DEBUG` (detailed logging for development)

## Environment Variables

All configuration is stored in `.env.local`:

| Variable | Value | Description |
|----------|-------|-------------|
| `SERVER_URL` | `http://localhost:9080/content-services-graphql/graphql` | Content Services GraphQL API endpoint |
| `USERNAME` | `p8admin` | FileNet username |
| `PASSWORD` | `CENIT-master1!` | FileNet password |
| `OBJECT_STORE` | `ecm_test` | Object store name |
| `SSL_ENABLED` | `false` | SSL verification disabled for local dev |
| `LOG_LEVEL` | `DEBUG` | Detailed logging |
| `MCP_TRANSPORT` | `stdio` | Standard I/O transport |

## Testing the New Tool

To test the `create_document_from_url` tool:

```bash
# Start the server
./start-local.sh

# The server will be ready to accept MCP protocol messages
# The new create_document_from_url tool will be available
```

## Alternative: Use with MCP Inspector

For interactive testing, you can use the MCP Inspector:

```bash
# Install MCP Inspector (if not already installed)
npm install -g @modelcontextprotocol/inspector

# Run with local configuration
export $(grep -v '^#' .env.local | xargs)
npx @modelcontextprotocol/inspector uv run core-cs-mcp-server
```

This will open a web interface where you can interactively test all MCP tools.

## Docker Alternative

If you prefer to run in Docker with local configuration:

```bash
docker run -it --rm \
  -e SERVER_URL=http://host.docker.internal:9080/content-services-graphql/graphql \
  -e USERNAME=p8admin \
  -e PASSWORD='CENIT-master1!' \
  -e OBJECT_STORE=ecm_test \
  -e SSL_ENABLED=false \
  -e LOG_LEVEL=DEBUG \
  -e MCP_TRANSPORT=stdio \
  docker.eim.cloud-cenit.com/mcp/cs-mcp-server:latest
```

Note: Use `host.docker.internal` to access localhost from within Docker container.

## Security Note

⚠️ **Important**: The `.env.local` file contains sensitive credentials and should **never** be committed to version control.

It is already included in `.gitignore` to prevent accidental commits.
