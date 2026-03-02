# Copyright contributors to the IBM Core Content Services MCP Server project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

FROM python:3.13-slim

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

WORKDIR /app

# Copy dependency files first for better layer caching
COPY pyproject.toml uv.lock README.md ./

# Install dependencies (no dev dependencies, use frozen lockfile)
RUN uv sync --frozen --no-dev --no-install-project

# Copy source code
COPY src/ ./src/

# Install the project itself
RUN uv sync --frozen --no-dev

# MCP transport defaults to streamable-http for container deployments
ENV MCP_TRANSPORT=streamable-http
ENV MCP_HOST=0.0.0.0
ENV MCP_PORT=8000

EXPOSE 8000

# SERVER_CMD selects which server entry point to run.
# Valid values: core-cs-mcp-server | legal-hold-cs-mcp-server |
#              ai-document-insight-cs-mcp-server |
#              property-extraction-and-classification-cs-mcp-server
ENV SERVER_CMD=core-cs-mcp-server

CMD ["sh", "-c", "uv run $SERVER_CMD"]
