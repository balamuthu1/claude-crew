---
description: Generate or update an OpenAPI specification for the project's API. Reads existing routes and produces a complete OpenAPI 3.0 YAML spec.
---

Spawn `api-developer` with a focused task: read the existing controller/route files and produce or update the OpenAPI 3.0 spec.

Include:
- All endpoints with HTTP methods and paths
- Request parameters (path, query, body) with types
- Response schemas for all status codes
- Authentication scheme
- Error response shapes

Output as `openapi.yaml` in the project root (or update existing).
