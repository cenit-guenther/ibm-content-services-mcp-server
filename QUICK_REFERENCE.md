# Quick Reference: Docker HTTP MCP Server

## ✅ Server Status: RUNNING

**Container:** `cs-mcp-server-local`  
**Endpoint:** `http://localhost:8000/cs-mcp-server/mcp`  
**Transport:** streamable-http  
**Object Store:** ECM  
**FileNet:** localhost:9080

---

## Quick Commands

### View Logs
```bash
docker logs -f cs-mcp-server-local
```

### Stop Server
```bash
docker stop cs-mcp-server-local
```

### Restart Server
```bash
cd /home/guenther_d/gitrepos/presales/ibm-content-services-mcp-server
./start-docker-http.sh
```

### Remove Container
```bash
docker rm cs-mcp-server-local
```

---

## Testing the Server

### 1. Health Check
```bash
curl http://localhost:8000/cs-mcp-server/mcp
```

### 2. List Available Tools
The server exposes 27 tools including the new `create_document_from_url`.

### 3. Test create_document_from_url

**Prerequisites:**
- Create folder structure in FileNet:
  ```
  /Ideen/Personalakte
  ```

**Test with PDF from earlier:**
```json
{
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
```

---

## Server Logs Summary

✅ **Core tools registered** (27 tools including new one)  
✅ **GraphQL client connected** to localhost:9080  
✅ **Object store ECM** is accessible  
✅ **HTTP server running** on port 8000  
✅ **StreamableHTTP transport** initialized  

⚠️ `/resources` folder not found (expected, can be ignored)

---

## Tools Available

All Core Server tools are available, including:

**New Tool:**
- `create_document_from_url` - Create documents from URL content

**Document Tools:**
- create_document
- update_document_properties
- get_document_properties
- checkout_document
- checkin_document
- delete_document_version
- ... and more

**Folder Tools:**
- create_folder
- get_folder_documents
- file_document
- ... and more

---

## Next Steps

1. **Create test folder structure** in FileNet
2. **Test the new tool** with the PDF URL
3. **Verify document** was created in `/Ideen/Personalakte`

---

## Troubleshooting

### FileNet Not Accessible
Check if FileNet is running:
```bash
ss -tlnp | grep 9080
```

### Port 8000 Already in Use
Modify `MCP_PORT` in `start-docker-http.sh`

### Container Logs Show Errors
```bash
docker logs cs-mcp-server-local | grep ERROR
```

---

**Created:** March 4, 2026  
**Status:** ✅ Ready for testing
