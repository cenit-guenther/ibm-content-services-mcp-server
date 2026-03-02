# GitHub Copilot Instructions

## Project Overview

This is an **IBM Content Services MCP Server** — a [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) server that exposes IBM FileNet Content Manager (FNCM) capabilities to AI agents via a GraphQL API. It is a Python package managed with `uv`.

## Build & Run

**Install dependencies:**
```bash
uv sync
```

**Run a server locally** (all servers use stdio transport and read config from environment variables):
```bash
# Core server
USERNAME=user PASSWORD=pass SERVER_URL=https://host/content-services-graphql/graphql OBJECT_STORE=os_name uv run core-cs-mcp-server

# Other servers: property-extraction-and-classification-cs-mcp-server | legal-hold-cs-mcp-server | ai-document-insight-cs-mcp-server
```

**Install from local checkout (as uvx tool):**
```bash
uvx --from /path/to/cs-mcp-server core-cs-mcp-server
```

There are no automated tests or lint commands in this project.

## Architecture

The server is structured around **multiple deployable server types**, each registering a different subset of tools:

| Entry Point | Server Type | `register_*` functions called |
|---|---|---|
| `core-cs-mcp-server` | `CORE` | documents, folders, classes, search |
| `property-extraction-and-classification-cs-mcp-server` | `PROPERTY_EXTRACTION_AND_CLASSIFICATION` | property_extraction, classification |
| `legal-hold-cs-mcp-server` | `LEGAL_HOLD` | legal_hold |
| `ai-document-insight-cs-mcp-server` | `AI_DOCUMENT_INSIGHT` | advanced_search, vector_search |

**Key layers:**

- **`mcp_server_main.py`** — single entry point; reads env vars, creates `GraphQLClient` and `MetadataCache`, dispatches to `register_server_tools()` / `register_server_resources()`.
- **`client/graphql_client.py`** — wraps `GraphqlConnection` (from `client/csdeploy/`); handles Basic auth, OAuth, and ZEN/IAM (CP4BA) token flows with automatic refresh. Exposes `execute_async()`.
- **`tools/`** — one file per domain (documents, folders, search, etc.). Each file has a single `register_*_tools(mcp, graphql_client, [metadata_cache])` function that uses `@mcp.tool()` decorators to register async tool handlers inline (closures over the injected clients).
- **`cache/metadata.py`** — `MetadataCache` caches class/property descriptions fetched from FileNet to avoid repeated GraphQL round-trips. Root class types: `Document`, `Folder`, `Annotation`, `CustomObject`.
- **`utils/`** — shared Pydantic models (`common.py`), constants (`constants.py`), and scoring helpers (`scoring.py`). `ToolError` (a Pydantic `BaseModel`) is the standard error return type from tools.
- **`resources/`** — MCP resources (read-only LLM context), only registered for `CORE` server. Exposes documents from the folder at `RESOURCES_FOLDER` (default `/resources`) as URIs `ibm-cs://{object_store}/documents/{path}`.

## Key Conventions

### Tool Registration Pattern
All tools are async closures defined inside `register_*_tools()` functions and decorated with `@mcp.tool(name="snake_case_name")`. The `graphql_client` and `metadata_cache` are captured from the enclosing scope — never passed as tool parameters.

```python
def register_document_tools(mcp: FastMCP, graphql_client: GraphQLClient, metadata_cache: MetadataCache) -> None:
    @mcp.tool(name="get_document_versions")
    async def get_document_versions(identifier: str) -> dict:
        ...
        return await graphql_client.execute_async(query=query, variables=variables)
```

### Error Handling
Tools return `ToolError` (a Pydantic model with `isError: True`, `message`, and `suggestions` fields) instead of raising exceptions. This lets the LLM read and act on error details.

### Constants
All magic strings and numeric thresholds live in `utils/constants.py` (scoring weights, version status codes, class names, etc.). Never hardcode these in tool files.

### Authentication
`GraphQLClient.__init__` accepts all auth variants (basic, OAuth, ZEN/IAM). The auth method is inferred from which env vars are set — no explicit auth-mode flag. Token refresh is handled automatically by the background session management in `graphql_client.py`.

### `SSL_ENABLED` / `*_SSL_ENABLED` flags
These accept three forms: `"true"` (use system cert store via `truststore`), `"false"` (disable verification), or a **file path** to a PEM certificate. Parsing is done in `parse_ssl_flag()` in `mcp_server_main.py`.

### Identifier convention
All tools that operate on FileNet objects accept an `identifier` parameter that can be either a GUID or a repository path (e.g., `/Folder1/doc.pdf`). The GraphQL API resolves both forms.

## Required Environment Variables

| Variable | Required | Description |
|---|---|---|
| `SERVER_URL` | Yes | CS GraphQL API endpoint |
| `USERNAME` | Yes (basic/OAuth) | Auth username |
| `PASSWORD` | Yes (basic/OAuth) | Auth password |
| `OBJECT_STORE` | Yes | FileNet object store name |
| `LOG_LEVEL` | No | `DEBUG`/`INFO`/`WARNING`/`ERROR` (default: `INFO`) |
| `RESOURCES_FOLDER` | No | Core server only; default `/resources` |
| `MCP_TRANSPORT` | No | `stdio` (default), `sse`, or `streamable-http` |
| `MCP_HOST` | No | Bind host for HTTP transports (default: `0.0.0.0`) |
| `MCP_PORT` | No | Bind port for HTTP transports (default: `8000`) |

For OAuth add: `TOKEN_URL`, `GRANT_TYPE`, `SCOPE`, `CLIENT_ID`, `CLIENT_SECRET`.  
For CP4BA/ZenIAM add: `ZENIAM_ZEN_URL`, `ZENIAM_IAM_URL`, and related `ZENIAM_*` vars.
