# Testing create_document_from_url with Local Server

## Configuration Verified ✅

The local MCP server is now configured with:
- **Object Store**: `ECM` (successfully connected)
- **Server URL**: `http://localhost:9080/content-services-graphql/graphql`
- **Username**: `p8admin`
- **Connection**: Successful

## Server Startup Log Summary

```
✓ Server initialized successfully
✓ GraphQL client connected to localhost:9080
✓ Object store 'ECM' is accessible
✓ Tools registered (including create_document_from_url)
✓ Server started in stdio mode
```

## Tool Availability

The `create_document_from_url` tool is now registered and available in the local server instance.

## Testing Options

### Option 1: Test via MCP Inspector (Recommended)

The MCP Inspector provides an interactive web UI to test MCP tools:

```bash
# Install MCP Inspector (if not already installed)
npm install -g @modelcontextprotocol/inspector

# Start with local configuration
cd /home/guenther_d/gitrepos/presales/ibm-content-services-mcp-server
export $(grep -v '^#' .env.local | xargs)
npx @modelcontextprotocol/inspector uv run core-cs-mcp-server
```

This will open a web interface where you can:
1. See all available tools (including `create_document_from_url`)
2. Interactively test the tool with parameters
3. View request/response in real-time

### Option 2: Test via Claude Desktop

Add to `~/.config/Claude/claude_desktop_config.json`:

```json
{
  "mcpServers": {
    "ibm-content-services-local": {
      "command": "bash",
      "args": [
        "-c",
        "cd /home/guenther_d/gitrepos/presales/ibm-content-services-mcp-server && source .env.local && uv run core-cs-mcp-server"
      ]
    }
  }
}
```

Then restart Claude Desktop and the tool will be available.

### Option 3: Test via Current Crush Connection

The IBM Content Services MCP server you're currently connected to through Crush needs to be restarted to pick up the new tool. This is the server providing the `mcp_ibm-content-services_*` tools.

## Test Command

Once the tool is available in your MCP client, test with:

```python
create_document_from_url(
    url="https://ecmrd.eim.cloud-cenit.com/markdown2pdf-mcp/pdf/d2d26673-72d2-47ab-a3d9-d59fe62c9843",
    file_in_folder_identifier="/Ideen/Personalakte",
    document_properties={"name": "Anbieter-Elektronische-Personalakten.pdf"},
    class_identifier="Document",
    checkin_action={"checkinMinorVersion": false}
)
```

## Expected Result

If successful, the tool will:
1. Download the PDF from the URL
2. Create a temporary file
3. Upload to FileNet at `/Ideen/Personalakte`
4. Return a Document object with properties
5. Clean up the temporary file

## Prerequisites

Before testing, ensure:
- [ ] The folder `/Ideen/Personalakte` exists in the ECM object store
- [ ] User `p8admin` has write permissions
- [ ] The FileNet server is running and accessible

## Create Test Folder

If the folder doesn't exist, create it first:

```bash
# Via MCP tool
create_folder(
    name="Ideen",
    parent_folder="/",
    class_identifier="Folder"
)

create_folder(
    name="Personalakte", 
    parent_folder="/Ideen",
    class_identifier="Folder"
)
```

---

**Status**: Ready for testing once MCP client is configured to use the updated server.
