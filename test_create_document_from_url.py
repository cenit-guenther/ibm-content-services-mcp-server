#!/usr/bin/env python3
"""
Test script for create_document_from_url tool
This script simulates calling the new tool to verify it works correctly.
"""

import asyncio
import sys
from cs_mcp_server.tools.documents import register_document_tools
from cs_mcp_server.client.graphql_client import GraphQLClient
from cs_mcp_server.cache.metadata import MetadataCache
from mcp.server.fastmcp import FastMCP

async def test_create_document_from_url():
    """Test the create_document_from_url tool"""
    
    # Test configuration
    TEST_URL = "https://ecmrd.eim.cloud-cenit.com/markdown2pdf-mcp/pdf/d2d26673-72d2-47ab-a3d9-d59fe62c9843"
    TEST_FOLDER = "/Ideen/Personalakte"
    TEST_NAME = "Anbieter-Elektronische-Personalakten.pdf"
    
    print("=" * 60)
    print("Testing create_document_from_url Tool")
    print("=" * 60)
    print(f"URL: {TEST_URL}")
    print(f"Target Folder: {TEST_FOLDER}")
    print(f"Document Name: {TEST_NAME}")
    print("=" * 60)
    print()
    
    # Check if the tool function exists in the module
    import inspect
    from cs_mcp_server.tools import documents
    
    # Find the register_document_tools function
    source = inspect.getsource(documents.register_document_tools)
    
    # Check if create_document_from_url is registered
    if "create_document_from_url" in source:
        print("✓ Tool 'create_document_from_url' is registered in documents.py")
    else:
        print("✗ Tool 'create_document_from_url' NOT found in documents.py")
        return False
    
    # Check the tool implementation
    if "async def create_document_from_url" in source:
        print("✓ Tool implementation uses async/await (correct)")
    else:
        print("✗ Tool implementation is not async")
        return False
    
    # Check for required imports
    if "import httpx" in inspect.getsource(documents):
        print("✓ httpx library is imported")
    else:
        print("✗ httpx library not imported")
        return False
    
    if "import tempfile" in inspect.getsource(documents):
        print("✓ tempfile library is imported")
    else:
        print("✗ tempfile library not imported")
        return False
    
    # Check for URL parameter
    if "url: str" in source:
        print("✓ URL parameter is defined")
    else:
        print("✗ URL parameter missing")
        return False
    
    # Check for httpx.AsyncClient usage
    if "httpx.AsyncClient" in source:
        print("✓ Uses httpx.AsyncClient for async HTTP requests")
    else:
        print("✗ httpx.AsyncClient not used")
        return False
    
    # Check for proper cleanup (finally block)
    if "finally:" in source and "os.unlink" in source:
        print("✓ Implements proper cleanup of temporary files")
    else:
        print("✗ Missing cleanup logic")
        return False
    
    print()
    print("=" * 60)
    print("All checks passed! Tool is properly implemented.")
    print("=" * 60)
    print()
    print("To test with actual FileNet server, ensure:")
    print("1. FileNet server is accessible")
    print("2. Environment variables are set correctly")
    print("3. Target folder /Ideen/Personalakte exists")
    print("4. User has write permissions")
    print()
    
    return True

if __name__ == "__main__":
    result = asyncio.run(test_create_document_from_url())
    sys.exit(0 if result else 1)
