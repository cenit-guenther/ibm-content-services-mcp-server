# Docker HTTP Transport Configuration

This guide explains how to run the IBM Content Services MCP Server locally using Docker with HTTP streamable transport.

## Quick Start

```bash
cd /home/guenther_d/gitrepos/presales/ibm-content-services-mcp-server
./start-docker-http.sh
```

## What It Does

The script:
1. Loads configuration from `.env.local`
2. Pulls the latest Docker image
3. Stops any existing container
4. Starts a new container with HTTP transport
5. Exposes the server on `localhost:8000`

## Configuration

**Transport:** `streamable-http`  
**Endpoint:** `http://localhost:8000/cs-mcp-server/mcp`  
**Network:** Host network (Linux) for localhost access

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
- `MCP_PORT=8000`
- `LOG_LEVEL=DEBUG`
- `SERVER_CMD=core-cs-mcp-server`

## Usage

### Start the Server

```bash
./start-docker-http.sh
```

**Output:**
```
✓ Container started successfully!

View logs:
  docker logs -f cs-mcp-server-local

Test the server:
  curl http://localhost:8000/cs-mcp-server/mcp

Stop the server:
  docker stop cs-mcp-server-local
```

### View Logs

```bash
docker logs -f cs-mcp-server-local
```

### Stop the Server

```bash
docker stop cs-mcp-server-local
```

### Remove the Container

```bash
docker rm cs-mcp-server-local
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
docker logs cs-mcp-server-local
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
docker stop cs-mcp-server-local
docker rm cs-mcp-server-local
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

1. **Verify it's running**: `docker ps | grep cs-mcp-server-local`
2. **Check logs**: `docker logs -f cs-mcp-server-local`
3. **Test endpoint**: `curl http://localhost:8000/cs-mcp-server/mcp`
4. **Connect MCP client** to `http://localhost:8000/cs-mcp-server/mcp`
5. **Test the new tool**: `create_document_from_url`

---

**Note**: Make sure `.env.local` is configured with correct credentials before running the script.
