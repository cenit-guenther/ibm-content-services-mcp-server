# Agent Development Guide

This guide contains essential information for AI agents working in the IBM Content Services MCP Server codebase.

## Project Overview

**IBM Content Services MCP Server** is a [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server that exposes IBM FileNet Content Manager (FNCM) capabilities to AI agents via a GraphQL API. It's a Python package managed with `uv`.

### Architecture

The server provides **multiple deployable server types**, each registering a different subset of tools:

| Entry Point | Server Type | Tools Registered |
|-------------|-------------|------------------|
| `core-cs-mcp-server` | `CORE` | documents, folders, classes, search |
| `property-extraction-and-classification-cs-mcp-server` | `PROPERTY_EXTRACTION_AND_CLASSIFICATION` | property_extraction, classification |
| `legal-hold-cs-mcp-server` | `LEGAL_HOLD` | legal_hold |
| `ai-document-insight-cs-mcp-server` | `AI_DOCUMENT_INSIGHT` | advanced_search, vector_search |

### Key Design Principles

1. **Single Entry Point**: All server types go through `mcp_server_main.py`
2. **Dependency Injection**: `GraphQLClient` and `MetadataCache` are injected into tool registration functions
3. **Closure-Based Tools**: Tools are async closures that capture injected dependencies
4. **No Exceptions in Tools**: Tools return `ToolError` Pydantic models instead of raising exceptions
5. **Constants-First**: All magic strings/numbers live in `utils/constants.py`

## Essential Commands

### Development Setup

```bash
# Install dependencies
uv sync

# Install from local checkout as uvx tool
uvx --from /path/to/cs-mcp-server core-cs-mcp-server
```

### Running Servers Locally

All servers use stdio transport by default and read config from environment variables:

```bash
# Core server
USERNAME=user PASSWORD=pass SERVER_URL=https://host/content-services-graphql/graphql OBJECT_STORE=os_name uv run core-cs-mcp-server

# Property extraction and classification server
uv run property-extraction-and-classification-cs-mcp-server

# Legal hold server
uv run legal-hold-cs-mcp-server

# AI document insight server
uv run ai-document-insight-cs-mcp-server
```

### Docker

```bash
# Build image
docker build -t cs-mcp-server .

# Run with environment variables
docker run -e SERVER_CMD=core-cs-mcp-server -e USERNAME=user -e PASSWORD=pass -e SERVER_URL=https://host/graphql -e OBJECT_STORE=os cs-mcp-server
```

The `SERVER_CMD` environment variable selects which server to run. Valid values:
- `core-cs-mcp-server`
- `legal-hold-cs-mcp-server`
- `ai-document-insight-cs-mcp-server`
- `property-extraction-and-classification-cs-mcp-server`

### Testing and Quality

**Important**: There are no automated tests, lint commands, or formatters in this project. Manual testing is required.

## Code Organization

```
src/cs_mcp_server/
├── mcp_server_main.py           # Single entry point for all server types
├── client/
│   ├── graphql_client.py        # GraphQL client with auth (Basic, OAuth, ZEN/IAM)
│   ├── ssl_adapter.py           # SSL configuration handling
│   └── csdeploy/                # GraphQL connection wrapper
├── tools/                       # One file per domain, each with register_*_tools()
│   ├── documents.py
│   ├── folders.py
│   ├── search.py
│   ├── classes.py
│   ├── legal_hold.py
│   ├── property_extraction.py
│   ├── classification.py
│   ├── advanced_search.py
│   ├── vector_search.py
│   ├── annotations.py
│   └── custom_objects.py
├── cache/
│   ├── metadata.py              # MetadataCache - caches class/property descriptions
│   └── metadata_loader.py       # Helper to fetch metadata from GraphQL
├── resources/
│   ├── dynamic_resources.py     # MCP resources (CORE server only)
│   └── documents.py
└── utils/
    ├── common.py                # Pydantic models (ToolError, SearchProperty, etc.)
    ├── constants.py             # ALL magic strings and numeric thresholds
    ├── scoring.py               # Fuzzy matching helpers
    ├── utils.py                 # Shared utilities
    └── model/                   # Additional Pydantic models
```

## Tool Registration Pattern

### Standard Pattern

All tools follow this closure-based pattern:

```python
def register_document_tools(
    mcp: FastMCP, 
    graphql_client: GraphQLClient, 
    metadata_cache: MetadataCache
) -> None:
    """
    Register document-related tools.
    
    Args:
        mcp: FastMCP instance
        graphql_client: Injected GraphQL client (captured as closure)
        metadata_cache: Injected cache (captured as closure)
    """
    
    @mcp.tool(name="get_document_versions")
    async def get_document_versions(identifier: str) -> dict:
        """
        Tool docstring becomes the tool description for LLMs.
        
        :param identifier: The document id or path (required).
        :returns: Version series details
        """
        method_name = "get_document_versions"  # For logging/errors
        
        try:
            query = """query GetVersions($identifier: String!) { ... }"""
            variables = {
                "identifier": identifier,
                "object_store_name": graphql_client.object_store,  # Closure access
            }
            
            response = await graphql_client.execute_async(
                query=query, 
                variables=variables
            )
            
            if "errors" in response:
                logger.error("GraphQL error: %s", response["errors"])
                return ToolError(
                    message=f"{method_name} failed: {response['errors']}",
                    suggestions=["Check if identifier exists", "Verify permissions"]
                )
            
            return response["data"]
            
        except Exception as e:
            logger.error("%s failed: %s", method_name, str(e))
            logger.error(traceback.format_exc(limit=TRACEBACK_LIMIT))
            return ToolError(
                message=f"{method_name} failed: {str(e)}",
                suggestions=["Check server logs for details"]
            )
```

### Key Conventions

1. **Registration function naming**: `register_<domain>_tools()`
2. **Tool naming**: Use `snake_case` in `@mcp.tool(name="...")`
3. **Closure variables**: Never pass `graphql_client` or `metadata_cache` as tool parameters
4. **Method naming**: Store method name as string at start for logging
5. **Return types**: Use `Union[ReturnType, ToolError]` for type hints
6. **Async vs Sync**: Use `async def` when calling `graphql_client.execute_async()`, otherwise `def` for sync

### Error Handling

**Critical**: Never raise exceptions in tools. Always return `ToolError`:

```python
from cs_mcp_server.utils import ToolError

# Pattern A: Manual error handling
try:
    response = await graphql_client.execute_async(query, variables)
    if "errors" in response:
        return ToolError(
            message=f"{method_name} failed: {response['errors']}",
            suggestions=["Check query syntax", "Verify permissions"]
        )
    return response["data"]
except Exception as e:
    logger.error("%s failed: %s", method_name, str(e))
    return ToolError(
        message=f"{method_name} failed: {str(e)}",
        suggestions=["Check server logs"]
    )

# Pattern B: Using wrapper (handles errors automatically)
from cs_mcp_server.client.graphql_client import graphql_client_execute_async_wrapper

response = await graphql_client_execute_async_wrapper(
    logger, method_name, graphql_client,
    query=mutation, variables=variables
)
if isinstance(response, ToolError):
    return response  # Already formatted error
```

## Constants Convention

**Never hardcode values**. All magic strings and numbers must be in `utils/constants.py`:

```python
from cs_mcp_server.utils.constants import (
    DEFAULT_DOCUMENT_CLASS,        # "Document"
    VERSION_STATUS_RELEASED,       # 1
    TEXT_EXTRACT_ANNOTATION_CLASS, # "TxeTextExtractAnnotation"
    MAX_SEARCH_RESULTS,            # 20
    TRACEBACK_LIMIT,               # 15
)
```

Categories in constants.py:
- **Class identifiers**: `DEFAULT_DOCUMENT_CLASS`, `VERSION_SERIES_CLASS`, etc.
- **Property names**: `ID_PROPERTY`, `HELD_OBJECT_PROPERTY`, `EXCLUDED_PROPERTY_NAMES`
- **Scoring**: All fuzzy matching thresholds and multipliers
- **Search limits**: `MAX_SEARCH_RESULTS`, `MAX_CLASS_MATCHES`
- **Version status codes**: `VERSION_STATUS_RELEASED`, `VERSION_STATUS_IN_PROCESS`, etc.
- **Data types**: `DATA_TYPE_STRING`, `CARDINALITY_LIST`, etc.
- **Operators**: `SQL_LIKE_OPERATOR`, `OPERATOR_CONTAINS`, etc.

## Authentication

`GraphQLClient` supports three auth methods, inferred from environment variables:

### Basic Authentication
```bash
SERVER_URL=https://...
USERNAME=user
PASSWORD=pass
OBJECT_STORE=os_name
SSL_ENABLED=true  # or "false" or "/path/to/cert.pem"
```

### OAuth Authentication
```bash
SERVER_URL=https://...
USERNAME=user
PASSWORD=pass
TOKEN_URL=https://.../token
GRANT_TYPE=password
SCOPE=openid
CLIENT_ID=client_id
CLIENT_SECRET=secret
OBJECT_STORE=os_name
```

### CP4BA ZEN/IAM Authentication
```bash
SERVER_URL=https://...
OBJECT_STORE=os_name
ZENIAM_ZEN_URL=https://zen-route/v1/preauth/validateAuth
ZENIAM_ZEN_SSL_ENABLED=true
ZENIAM_IAM_URL=https://iam-route/idprovider/v1/auth/identitytoken
ZENIAM_IAM_SSL_ENABLED=true
ZENIAM_IAM_GRANT_TYPE=password
ZENIAM_IAM_SCOPE=openid
ZENIAM_IAM_USER=user
ZENIAM_IAM_PASSWORD=pass
```

### SSL Configuration

SSL flags accept three forms (parsed in `parse_ssl_flag()` in `mcp_server_main.py`):
- `"true"`: Use system cert store via `truststore`
- `"false"`: Disable verification (not recommended for production)
- `/path/to/cert.pem`: Path to certificate file

## Identifier Convention

All tools that operate on FileNet objects accept an `identifier` parameter that can be:
- **GUID**: `{12345678-1234-1234-1234-123456789012}`
- **Repository path**: `/Folder1/Subfolder/document.pdf`

The GraphQL API resolves both forms automatically.

## MetadataCache

`MetadataCache` caches class and property descriptions to avoid repeated GraphQL queries:

```python
from cs_mcp_server.cache.metadata import MetadataCache

# Root class types supported
ROOT_CLASS_TYPES = ["Document", "Folder", "Annotation", "CustomObject"]

# Usage in tools
class_metadata = await metadata_cache.get_class_data(
    class_name="Document", 
    graphql_client=graphql_client
)
```

Cache structure:
```python
{
    "Document": {
        "MyDocumentClass": CacheClassDescriptionData(...),
        "AnotherClass": CacheClassDescriptionData(...),
    },
    "Folder": { ... },
}
```

## Adding New Tools

### Step 1: Create Tool File

Create `src/cs_mcp_server/tools/my_domain.py`:

```python
import logging
from typing import Union
from mcp.server.fastmcp import FastMCP
from cs_mcp_server.client import GraphQLClient
from cs_mcp_server.cache import MetadataCache
from cs_mcp_server.utils import ToolError
from cs_mcp_server.utils.constants import TRACEBACK_LIMIT

logger = logging.getLogger(__name__)

def register_my_domain_tools(
    mcp: FastMCP,
    graphql_client: GraphQLClient,
    metadata_cache: MetadataCache
) -> None:
    @mcp.tool(name="my_new_tool")
    async def my_new_tool(param: str) -> Union[dict, ToolError]:
        """
        Description for LLM.
        
        :param param: Parameter description
        :returns: Return value description
        """
        method_name = "my_new_tool"
        try:
            query = """query MyQuery { ... }"""
            variables = {"object_store_name": graphql_client.object_store}
            response = await graphql_client.execute_async(query, variables)
            
            if "errors" in response:
                return ToolError(
                    message=f"{method_name} failed",
                    suggestions=["Check parameters"]
                )
            return response["data"]
        except Exception as e:
            logger.error("%s failed: %s", method_name, str(e))
            return ToolError(message=f"{method_name} failed: {str(e)}")
```

### Step 2: Register in Server Type

Edit `src/cs_mcp_server/mcp_server_main.py`:

```python
from cs_mcp_server.tools.my_domain import register_my_domain_tools

def register_server_tools(
    mcp: FastMCP,
    server_type: ServerType,
    graphql_client: GraphQLClient,
    metadata_cache: MetadataCache,
) -> None:
    if server_type == ServerType.CORE:
        register_document_tools(mcp, graphql_client, metadata_cache)
        register_folder_tools(mcp, graphql_client)
        register_my_domain_tools(mcp, graphql_client, metadata_cache)  # Add here
        # ... other registrations
```

## MCP Resources (CORE Server Only)

Resources expose documents from a configured folder as read-only LLM context:

```python
# In mcp_server_main.py
if server_type == ServerType.CORE:
    register_dynamic_resources(mcp, graphql_client)
```

- Default folder: `/resources` (configurable via `RESOURCES_FOLDER` env var)
- URI pattern: `ibm-cs://{object_store}/documents/{path}`
- Display name: `[IBM CS] {document_name}`
- Requires Persistent Text Extract add-on

## Environment Variables

### Required
- `SERVER_URL`: CS GraphQL API endpoint
- `USERNAME`: Auth username (basic/OAuth)
- `PASSWORD`: Auth password (basic/OAuth)
- `OBJECT_STORE`: FileNet object store name

### Optional
- `LOG_LEVEL`: `DEBUG`/`INFO`/`WARNING`/`ERROR` (default: `INFO`)
- `RESOURCES_FOLDER`: Core server only, default `/resources`
- `MCP_TRANSPORT`: `stdio` (default), `sse`, or `streamable-http`
- `MCP_HOST`: Bind host for HTTP transports (default: `0.0.0.0`)
- `MCP_PORT`: Bind port for HTTP transports (default: `8000`)
- `SSL_ENABLED`: SSL verification (default: `true`)
- `TOKEN_REFRESH`: Token refresh interval in seconds (default: `1800`)

Full list in README.md and `.github/copilot-instructions.md`.

## Common Patterns

### GraphQL Query Execution

```python
# Async execution
response = await graphql_client.execute_async(query=query, variables=variables)

# Sync execution (use sparingly)
response = graphql_client.execute(query=query, variables=variables)

# With error wrapper
from cs_mcp_server.client.graphql_client import graphql_client_execute_async_wrapper

response = await graphql_client_execute_async_wrapper(
    logger, method_name, graphql_client,
    query=query, variables=variables
)
if isinstance(response, ToolError):
    return response
```

### Accessing Object Store

```python
# Always from closure, never as parameter
variables = {
    "object_store_name": graphql_client.object_store,
    # ... other vars
}
```

### Logging

```python
import logging
logger = logging.getLogger(__name__)

# Levels
logger.debug("Detailed info")
logger.info("Normal operation")
logger.warning("Warning message")
logger.error("Error occurred: %s", str(e))

# With traceback
import traceback
from cs_mcp_server.utils.constants import TRACEBACK_LIMIT

logger.error(traceback.format_exc(limit=TRACEBACK_LIMIT))
```

### Pydantic Models

```python
from cs_mcp_server.utils import (
    ToolError,           # Error return type
    Document,            # Document model
    Folder,              # Folder model
    SearchProperty,      # Search filter
    SearchOperator,      # Search operators enum
    Cardinality,         # Property cardinality
    TypeID,              # Property type
)

# Create ToolError
return ToolError(
    message="Operation failed: reason",
    suggestions=["Try this", "Check that"]
)

# Use SearchProperty
search_filter = SearchProperty(
    property_name="DocumentTitle",
    property_value="Invoice",
    operator=SearchOperator.CONTAINS
)
```

### HTTP Requests with httpx

For tools that need to fetch external content (e.g., downloading files from URLs):

```python
import httpx
import tempfile
import os

async def my_tool_with_http(url: str) -> Union[dict, ToolError]:
    """Example tool that downloads content from a URL."""
    method_name = "my_tool_with_http"
    temp_file_path = None
    
    try:
        # Use httpx AsyncClient for async HTTP operations
        async with httpx.AsyncClient(follow_redirects=True, timeout=60.0) as client:
            response = await client.get(url)
            response.raise_for_status()  # Raises HTTPError for 4xx/5xx responses
            
            # Create temporary file for downloaded content
            temp_file = tempfile.NamedTemporaryFile(delete=False, suffix=".tmp")
            temp_file_path = temp_file.name
            temp_file.write(response.content)
            temp_file.close()
            
            # Process temp_file_path...
            
    except httpx.HTTPError as e:
        logger.error("%s failed: HTTP error: %s", method_name, str(e))
        return ToolError(
            message=f"{method_name} failed: HTTP error: {str(e)}",
            suggestions=["Check URL is accessible", "Verify URL is correct"]
        )
    finally:
        # Always clean up temporary files
        if temp_file_path and os.path.exists(temp_file_path):
            try:
                os.unlink(temp_file_path)
                logger.info("Cleaned up temporary file: %s", temp_file_path)
            except Exception as e:
                logger.warning("Failed to clean up temporary file: %s", str(e))
```

**Key points:**
- Use `httpx.AsyncClient` for async HTTP operations
- Set `follow_redirects=True` to handle redirects automatically
- Set appropriate timeouts (default: 60 seconds)
- Always clean up temporary files in `finally` block
- Handle `httpx.HTTPError` separately from other exceptions

## Version Management

The project uses semantic versioning. To update version:

1. Edit `pyproject.toml`:
   ```toml
   [project]
   version = "1.0.4"
   ```

2. Update `CHANGELOG.md` following [Keep a Changelog](https://keepachangelog.com/) format

3. Commit changes (don't create version tags unless you're a maintainer)

## Gotchas and Non-Obvious Patterns

### 1. Tool Return Types Must Be Serializable

Tools return values that get serialized to JSON for the MCP protocol. Don't return Python-specific objects:

```python
# Bad
return some_python_object

# Good
return {"key": "value"}  # Plain dict
return ToolError(...)     # Pydantic model (serializes to dict)
```

### 2. SSL Flag Parsing

The `SSL_ENABLED` and related flags are **not booleans** in env vars. They're strings parsed as:
- String `"true"` → use system cert store
- String `"false"` → disable verification
- Any other string → treat as cert file path

```python
# In environment
SSL_ENABLED=true                 # Uses truststore
SSL_ENABLED=false                # Disables verification
SSL_ENABLED=/path/to/cert.pem   # Uses specified cert
```

### 3. Async Everywhere for GraphQL

Most GraphQL operations should be async to avoid blocking:

```python
# Preferred
async def my_tool(param: str) -> dict:
    response = await graphql_client.execute_async(...)

# Only use sync if you have a reason
def my_tool(param: str) -> dict:
    response = graphql_client.execute(...)
```

### 4. Entry Points in pyproject.toml

Server entry points are defined in `pyproject.toml` and call specific `main_*()` functions:

```toml
[project.scripts]
core-cs-mcp-server = "cs_mcp_server.mcp_server_main:main_core"
legal-hold-cs-mcp-server = "cs_mcp_server.mcp_server_main:main_legal_hold"
```

Each `main_*()` function initializes the server with a specific `ServerType` enum value.

### 5. No Tool Parameter for graphql_client

**Never** add `graphql_client` as a tool parameter:

```python
# WRONG - don't do this
@mcp.tool(name="bad_tool")
async def bad_tool(identifier: str, graphql_client: GraphQLClient):
    pass

# CORRECT - capture from closure
def register_tools(mcp: FastMCP, graphql_client: GraphQLClient):
    @mcp.tool(name="good_tool")
    async def good_tool(identifier: str):
        # graphql_client captured from enclosing scope
        response = await graphql_client.execute_async(...)
```

The LLM should only see user-facing parameters, not infrastructure dependencies.

### 6. Object Store is Required in Variables

Most GraphQL queries require `object_store_name` in variables:

```python
variables = {
    "object_store_name": graphql_client.object_store,  # Required
    "identifier": document_id,
    # ... other vars
}
```

### 7. Version Status Codes

FileNet uses numeric status codes for document versions:

```python
from cs_mcp_server.utils.constants import (
    VERSION_STATUS_RELEASED,    # 1 - released version
    VERSION_STATUS_IN_PROCESS,  # 2 - current, not released
    VERSION_STATUS_RESERVATION, # 3 - checked out
    VERSION_STATUS_SUPERSEDED,  # 4 - old version
)
```

### 8. Text Extract Requires Add-on

The Persistent Text Extract add-on must be installed for:
- `get_document_text_extract` tool
- MCP resources (CORE server)
- Property extraction tools
- AI document insight tools

### 9. Global MCP Instance

The `mcp` variable in `mcp_server_main.py` is global and initialized once per server start:

```python
# Global
mcp = None

def _initialize_mcp_server(server_name: str) -> FastMCP:
    global mcp
    if mcp is None:
        mcp = FastMCP(...)
    return mcp
```

Don't create multiple MCP instances.

### 10. Transport Configuration

The server supports three transports via `MCP_TRANSPORT`:
- `stdio`: Standard input/output (default for local/CLI)
- `sse`: Server-Sent Events (for web integrations)
- `streamable-http`: HTTP with streaming (default for Docker)

Docker deployments default to `streamable-http` with host `0.0.0.0:8000`.

## Dependencies

Key dependencies from `pyproject.toml`:

```toml
requires-python = ">=3.13"
dependencies = [
    "httpx>=0.28.1",        # HTTP client
    "mcp[cli]>=1.15.0",     # Model Context Protocol
    "fastmcp>=2.11.3",      # Fast MCP framework
    "aiohttp>=3.8.0",       # Async HTTP
    "pydantic>=2.0.0",      # Data validation
    "requests>=2.31.0",     # HTTP requests
    "truststore>=0.8.0",    # System cert store
]
```

## Troubleshooting

### "old_string not found" errors when editing

This project has complex Python code with significant whitespace and indentation. When editing:
1. Always read the file first
2. Copy exact text including all whitespace
3. Include 3-5 lines of context
4. Count indentation spaces/tabs carefully

### GraphQL client connection issues

Check:
1. `SERVER_URL` points to `/content-services-graphql/graphql` endpoint
2. SSL configuration matches server cert setup
3. Auth credentials are correct
4. Network connectivity to FileNet server

### Tool not showing up in MCP client

Verify:
1. Tool is registered in correct server type's registration function
2. Server was restarted after code changes
3. MCP client config points to correct server entry point
4. No Python import errors in server logs

### MetadataCache returning stale data

The cache is in-memory and persists for server lifetime. To force refresh:
- Restart the server
- Or call `metadata_cache.reset()` if you add that capability

## Testing Approach

Since there are no automated tests:

1. **Manual testing**: Run server locally and test with MCP client (Claude Desktop, Bob-IDE, VS Code Copilot)
2. **Check logs**: Set `LOG_LEVEL=DEBUG` to see detailed execution
3. **Test error paths**: Verify `ToolError` returns work correctly
4. **Test with real FileNet**: Connect to actual CPE server, not mocks

## Additional Resources

- [Model Context Protocol Specification](https://modelcontextprotocol.io/)
- [FastMCP Documentation](https://github.com/jlowin/fastmcp)
- Project README: `README.md`
- Copilot instructions: `.github/copilot-instructions.md`
- Setup guides: `docs/bob-setup.md`, `docs/vscode-copilot-setup.md`
- Changelog: `CHANGELOG.md`

---

**Last Updated**: Generated for codebase version 1.0.3
