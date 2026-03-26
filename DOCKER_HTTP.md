# Docker HTTP Transport Configuration

This guide explains how to run the IBM Content Services MCP Server locally using Docker with HTTP streamable transport.

## Quick Start

```bash
cd /home/guenther_d/gitrepos/presales/ibm-content-services-mcp-server

# Core server (default)
./start-docker-http.sh

# Other servers
./start-docker-http.sh legal-hold
./start-docker-http.sh ai-insight
./start-docker-http.sh property
```

## Available Servers

| Kurzname     | MCP Server                                              | Default-Port | Endpoint                                                                        |
|--------------|---------------------------------------------------------|:------------:|---------------------------------------------------------------------------------|
| `core`       | `core-cs-mcp-server`                                    | 8000         | `http://localhost:8000/core-cs-mcp-server/mcp`                                  |
| `legal-hold` | `legal-hold-cs-mcp-server`                              | 8001         | `http://localhost:8001/legal-hold-cs-mcp-server/mcp`                            |
| `ai-insight` | `ai-document-insight-cs-mcp-server`                     | 8002         | `http://localhost:8002/ai-document-insight-cs-mcp-server/mcp`                   |
| `property`   | `property-extraction-and-classification-cs-mcp-server`  | 8003         | `http://localhost:8003/property-extraction-and-classification-cs-mcp-server/mcp`|

## Usage

### Syntax

```bash
./start-docker-http.sh [server] [port]
```

- `server` — Kurzname des Servers (default: `core`)
- `port`   — Port überschreiben (optional, überschreibt auch `$MCP_PORT`)

### Beispiele

```bash
# Core Server auf Port 8000 (Standard)
./start-docker-http.sh

# Legal Hold Server auf Port 8001
./start-docker-http.sh legal-hold

# AI Document Insight Server auf Port 8002
./start-docker-http.sh ai-insight

# Property Extraction Server auf Port 8003
./start-docker-http.sh property

# Beliebiger Server auf eigenem Port
./start-docker-http.sh core 9000
```

## What It Does

The script:
1. Loads configuration from `.env.local`
2. Resolves `SERVER_CMD` and default port from the server short name
3. Pulls the latest Docker image
4. Stops any existing container with the same name
5. Starts a new container with HTTP transport
6. Exposes the server on the configured port

## Configuration

**Transport:** `streamable-http`  
**Endpoint:** `http://localhost:<port>/<server-name>-cs-mcp-server/mcp`  
**Network:** Host network (Linux) for localhost access

Container names are server-specific: `cs-mcp-server-<kurzname>` (e.g. `cs-mcp-server-legal-hold`).

## Environment Variables

The script automatically loads from `.env.local`:
- `SERVER_URL`: FileNet GraphQL endpoint
- `USERNAME`: FileNet username
- `PASSWORD`: FileNet password
- `OBJECT_STORE`: Object store name (ECM)
- `SSL_ENABLED`: false (local dev)

Additional variables set by script:
- `MCP_TRANSPORT=streamable-http`
- `MCP_HOST=0.0.0.0`
- `MCP_PORT=<default or override>`
- `LOG_LEVEL=DEBUG`
- `SERVER_CMD=<resolved from server short name>`

### Start the Server

```bash
./start-docker-http.sh [server] [port]
```

**Output (Beispiel für `core`):**
```
✓ Container 'cs-mcp-server-core' started successfully!

View logs:
  docker logs -f cs-mcp-server-core

Test the server:
  curl http://localhost:8000/cs-mcp-server/mcp

Stop the server:
  docker stop cs-mcp-server-core
```

### View Logs

```bash
docker logs -f cs-mcp-server-<kurzname>
# z.B.:
docker logs -f cs-mcp-server-core
docker logs -f cs-mcp-server-legal-hold
```

### Stop the Server

```bash
docker stop cs-mcp-server-<kurzname>
```

### Remove the Container

```bash
docker rm cs-mcp-server-<kurzname>
```

## Testing the Server

### Health Check

```bash
curl http://localhost:8000/cs-mcp-server/mcp
```

### Test with MCP Client

You can connect any MCP client to:
```
http://localhost:8000/cs-mcp-server/mcp
```

### Test create_document_from_url Tool

Once connected, you can test the new tool:

```json
{
  "tool": "create_document_from_url",
  "arguments": {
    "url": "https://ecmrd.eim.cloud-cenit.com/markdown2pdf-mcp/pdf/1015da91-766f-470d-891c-cd3baf006da9",
    "file_in_folder_identifier": "/Ideen/Personalakte",
    "document_properties": {
      "name": "Anbieter-Elektronische-Personalakten.pdf"
    },
    "class_identifier": "Document",
    "checkin_action": {
      "checkinMinorVersion": false
    }
  }
}
```

## Network Configuration

**Linux:** Uses `--network host` to allow container to access `localhost:9080`

**Windows/Mac:** Modify the script to use:
```bash
-e SERVER_URL="http://host.docker.internal:9080/content-services-graphql/graphql" \
```

## Troubleshooting

### Container Won't Start

Check logs:
```bash
docker logs cs-mcp-server-<kurzname>
```

### Can't Access FileNet

Verify FileNet is running:
```bash
ss -tlnp | grep 9080
```

### Port Already in Use

Change `MCP_PORT` in the script:
```bash
MCP_PORT="8001"
```

### Container Already Exists

The script automatically removes existing containers, but if needed:
```bash
docker stop cs-mcp-server-<kurzname>
docker rm cs-mcp-server-<kurzname>
```

## Advantages of Docker HTTP Transport

1. **Remote Access**: Can be accessed from other machines
2. **No stdio Complexity**: Standard HTTP requests
3. **Easy Testing**: Use curl, Postman, or any HTTP client
4. **Production-Like**: Similar to deployment environment
5. **Container Isolation**: Doesn't affect local Python environment

## Comparison with Other Transports

| Transport | Use Case | Access |
|-----------|----------|--------|
| `stdio` | Local development, MCP Inspector | stdin/stdout |
| `sse` | Server-Sent Events, web integrations | HTTP EventSource |
| `streamable-http` | **Docker, remote access, production** | **HTTP POST** |

## Docker vs Local Script

| Aspect | Docker (`start-docker-http.sh`) | Local (`start-local.sh`) |
|--------|--------------------------------|--------------------------|
| Environment | Container | Host Python |
| Dependencies | Bundled | Requires uv, Python 3.13+ |
| Transport | HTTP (remote access) | stdio (local only) |
| Testing | HTTP clients, curl | MCP Inspector |
| Isolation | Full | None |
| Production-like | Yes | No |

## Next Steps

After starting the Docker container:

1. **Verify it's running**: `docker ps | grep cs-mcp-server-<kurzname>`
2. **Check logs**: `docker logs -f cs-mcp-server-<kurzname>`
3. **Test endpoint**: `curl http://localhost:<port>/<server-name>-cs-mcp-server/mcp`
4. **Connect MCP client** to `http://localhost:<port>/<server-name>-cs-mcp-server/mcp`

---

**Note**: Make sure `.env.local` is configured with correct credentials before running the script.
