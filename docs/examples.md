# IBM Content Services MCP Server - Usage Examples

This document provides practical examples of common workflows using the IBM Content Services MCP Server.

## Document Creation

### Creating a Document from a Local File

```
User: Create a document from the file /tmp/contract.pdf in the /Contracts folder

Assistant will:
1. Call determine_class with keywords ["contract"]
2. Call get_class_property_descriptions for the identified class
3. Call create_document with:
   - file_paths: ["/tmp/contract.pdf"]
   - file_in_folder_identifier: "/Contracts"
   - document_properties: { name: "contract.pdf" }
```

### Creating a Document from a URL

The `create_document_from_url` tool allows you to create documents with content downloaded directly from URLs.

```
User: Create a document from https://example.com/files/report.pdf and put it in /Reports

Assistant will:
1. Call determine_class with keywords ["report"]
2. Call get_class_property_descriptions for the identified class
3. Call create_document_from_url with:
   - url: "https://example.com/files/report.pdf"
   - file_in_folder_identifier: "/Reports"
   - document_properties: { name: "report.pdf" } (auto-derived from URL if not specified)
```

**Features:**
- Automatically downloads content from the URL
- Derives document name from URL or Content-Disposition header
- Supports HTTP redirects
- Automatic cleanup of temporary files
- 60-second timeout for downloads

**Example URLs:**
- Direct file links: `https://example.com/files/document.pdf`
- Content delivery networks: `https://cdn.example.com/assets/report.docx`
- GitHub raw files: `https://raw.githubusercontent.com/user/repo/main/file.txt`
- SharePoint links (if accessible without authentication)

**Common Use Cases:**
1. **Ingesting public documents**: Download and store public reports, whitepapers, or legal documents
2. **Archiving web content**: Create permanent copies of web-based documents
3. **Integration workflows**: Connect with external systems that provide file URLs
4. **Batch imports**: Import multiple documents from a web server or CDN

**Error Handling:**
- HTTP errors (404, 403, etc.) return ToolError with suggestions
- Network timeouts are caught and reported
- Invalid URLs are rejected with clear error messages

## Document Properties

### Updating Document Properties

```
User: Update the document /Contracts/contract.pdf to set the author to "John Doe"

Assistant will:
1. Call get_document_properties to retrieve current document
2. Call get_class_property_descriptions for the document's class
3. Call update_document_properties with:
   - identifier: "/Contracts/contract.pdf"
   - document_properties: { properties: [{ id: "Author", value: "John Doe" }] }
```

### Extracting Text from a Document

Requires Persistent Text Extract add-on.

```
User: Extract the text from /Contracts/contract.pdf

Assistant will:
1. Call get_document_text_extract with:
   - identifier: "/Contracts/contract.pdf"
```

## Document Search

### Basic Content Search

```
User: Find all documents containing "quarterly report"

Assistant will:
1. Call determine_class with keywords ["document"]
2. Call get_searchable_property_descriptions for Document class
3. Call document_search with:
   - search_term: "quarterly report"
   - search_parameters: { search_class: "Document" }
```

### Combined Content and Metadata Search

```
User: Find all InvoiceDocument documents created by "John Doe" that contain "overdue"

Assistant will:
1. Call determine_class with keywords ["invoice", "document"]
2. Call get_searchable_property_descriptions for InvoiceDocument class
3. Call document_search with:
   - search_term: "overdue"
   - search_parameters: {
       search_class: "InvoiceDocument",
       search_properties: [
         { property_name: "Creator", operator: "=", property_value: "John Doe" }
       ]
     }
```

## Document Checkout/Checkin

### Checkout, Modify, and Checkin Workflow

```
User: Check out /Contracts/contract.pdf, I'll modify it locally

Assistant will:
1. Call checkout_document with:
   - identifier: "/Contracts/contract.pdf"
   - download_folder_path: "/tmp"

User: Now check it back in with the updated file /tmp/contract_v2.pdf

Assistant will:
1. Call checkin_document with:
   - identifier: "/Contracts/contract.pdf" (or reservation_id from checkout)
   - file_paths: ["/tmp/contract_v2.pdf"]
```

### Cancel Checkout

```
User: Cancel the checkout for /Contracts/contract.pdf

Assistant will:
1. Call cancel_document_checkout with:
   - identifier: "/Contracts/contract.pdf" (or reservation_id)
```

## Folder Operations

### Creating a Folder Hierarchy

```
User: Create a folder structure /Projects/2024/Q1

Assistant will:
1. Call create_folder for "/Projects" if it doesn't exist
2. Call create_folder for "/Projects/2024" with parent_folder: "/Projects"
3. Call create_folder for "/Projects/2024/Q1" with parent_folder: "/Projects/2024"
```

### Listing Folder Contents

```
User: List all documents in /Contracts

Assistant will:
1. Call get_folder_documents with:
   - folder_id_or_path: "/Contracts"
```

### Filing a Document

```
User: File the document {doc-id-guid} into /Archive

Assistant will:
1. Call file_document with:
   - document_id_or_path: "{doc-id-guid}"
   - folder_id_or_path: "/Archive"
```

## Class and Property Discovery

### Finding the Right Class

```
User: I need to create a PurchaseOrder document

Assistant will:
1. Call list_root_classes to get valid root classes
2. Call determine_class with:
   - root_class: "Document"
   - keywords: ["purchase", "order"]
3. Get top matches and their scores
```

### Getting Property Descriptions

```
User: What properties does a PurchaseOrderDocument have?

Assistant will:
1. Call get_class_property_descriptions with:
   - class_symbolic_name: "PurchaseOrderDocument"
2. Return list of properties with data types, cardinality, and descriptions
```

## Document Versions

### Retrieving Version History

```
User: Show me all versions of /Contracts/contract.pdf

Assistant will:
1. Call get_document_versions with:
   - identifier: "/Contracts/contract.pdf"
2. Display version numbers (major.minor) and document IDs
```

### Deleting a Specific Version

```
User: Delete version 2.1 of the contract

Assistant will:
1. Call get_document_versions to find the document ID for version 2.1
2. Call delete_document_version with:
   - identifier: "{document-id-for-v2.1}"
```

### Deleting All Versions

```
User: Delete all versions of the contract document

Assistant will:
1. Call get_document_properties to get the version_series_id
2. Call delete_version_series with:
   - version_series_id: "{version-series-id}"
```

## Property Extraction (Requires Property Extraction Server)

### Extract Properties from Document Content

```
User: Extract invoice properties from /Invoices/inv-2024-001.pdf

Assistant will:
1. Call property_extraction with:
   - identifier: "/Invoices/inv-2024-001.pdf"
   - class_symbolic_name: "InvoiceDocument"
2. Receive document text and property definitions
3. Use AI to extract values from text
4. Call update_document_properties (from Core Server) with extracted values
```

## Legal Hold (Requires Legal Hold Server)

### Creating and Managing Legal Holds

```
User: Create a legal hold named "Case-2024-001" and add document /Contracts/contract.pdf

Assistant will:
1. Call create_hold with:
   - hold_name: "Case-2024-001"
   - description: "Legal hold for case 2024-001"
2. Call add_object_to_hold with:
   - hold_identifier: "{hold-id}"
   - object_identifier: "/Contracts/contract.pdf"
```

## AI Document Insight (Requires AI Document Insight Server)

### Smart Document Search

```
User: Find documents related to "machine learning algorithms" created in 2024

Assistant will:
1. Call document_smart_search with:
   - search_query: "machine learning algorithms"
   - metadata_filters: [
       { property_name: "DateCreated", operator: ">=", property_value: "2024-01-01" }
     ]
```

### Document Summarization

```
User: Summarize the contract document at /Contracts/contract.pdf

Assistant will:
1. Call document_quick_summary with:
   - document_identifiers: ["/Contracts/contract.pdf"]
```

### Document Comparison

```
User: Compare /Contracts/contract_v1.pdf and /Contracts/contract_v2.pdf

Assistant will:
1. Call document_compare_insights with:
   - document_identifier_1: "/Contracts/contract_v1.pdf"
   - document_identifier_2: "/Contracts/contract_v2.pdf"
```

## Best Practices

### Always Check Prerequisites

Many tools require calling prerequisite tools first:
- `create_document` and `create_document_from_url`: Call `determine_class` and `get_class_property_descriptions`
- `update_document_properties`: Call `get_class_property_descriptions`
- `update_document_class`: Call `determine_class`
- Property extraction: Call `property_extraction`, then use Core Server's `update_document_properties`

### Use Paths When Possible

For better readability, use folder paths instead of GUIDs:
- Good: `/Contracts/contract.pdf`
- Less readable: `{12345678-1234-1234-1234-123456789012}`

### Handle Errors Gracefully

All tools return `ToolError` objects when operations fail. Check for error responses and provide helpful suggestions to users.

### Leverage Content-Based Search

The `document_search` tool supports full-text CBR search. Use it to find documents based on their content, not just metadata.

### Clean Up After Operations

When using `create_document_from_url`, temporary files are automatically cleaned up. For other file operations, ensure temporary files are removed after use.

## Common Error Scenarios

### URL Download Failures

**Problem**: `create_document_from_url` fails with HTTP error

**Solutions**:
- Verify the URL is accessible (not behind authentication)
- Check for typos in the URL
- Ensure the server hosting the file is online
- Try the URL in a browser first

### Missing Text Extract

**Problem**: `get_document_text_extract` returns empty or error

**Solutions**:
- Verify Persistent Text Extract add-on is installed
- Check if text extraction has completed (may take time for large documents)
- Ensure the document format supports text extraction (PDF, Office docs, etc.)

### Property Not Found

**Problem**: Setting a property fails with "property not found"

**Solutions**:
- Call `get_class_property_descriptions` first to get valid property names
- Check for typos in property names (case-sensitive)
- Verify the document's class supports the property

### Class Not Found

**Problem**: `determine_class` doesn't find the expected class

**Solutions**:
- Call `list_root_classes` to see available root classes
- Use more specific keywords that match the class name
- Check if the class exists in your FileNet repository
- Verify spelling and capitalization

## Additional Resources

- [Setup Guides](./bob-setup.md)
- [README](../README.md)
- [CHANGELOG](../CHANGELOG.md)
- [Agent Development Guide](../AGENTS.md)
