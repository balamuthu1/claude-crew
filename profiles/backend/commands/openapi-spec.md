Generate or update the OpenAPI 3.0 specification for the API described in the argument.
If no argument is given, generate a spec for the entire project.

You are the **orchestrator**. Do NOT write the spec yourself — spawn dedicated sub-agents.

---

## Before starting

Read `backend.config.md` and `workflow.config.md`. Extract:
- `{{LANGUAGE}}` — node, python, go, java, etc.
- `{{FRAMEWORK}}` — express, fastapi, gin, spring-boot, etc.
- `{{API_STYLE}}` — rest, graphql, grpc
- `{{AUTH_MECHANISM}}` — jwt, session, oauth2, api-key
- `{{DOCS_PLATFORM}}` — from workflow.config.md
- `{{TICKET_SYSTEM}}` — from workflow.config.md

If `{{API_STYLE}}` is not REST, note the limitation:
- GraphQL → suggest GraphQL SDL + introspection instead of OpenAPI
- gRPC → suggest proto file review instead

---

## Stage Definitions

### Stage 1 — API DISCOVERY
Spawn the `api-reviewer` agent.

Agent prompt:
```
You are the api-reviewer agent.

Task: Discover and catalogue all API endpoints.
Target: {{TARGET}}
Framework: {{FRAMEWORK}} ({{LANGUAGE}})
Auth: {{AUTH_MECHANISM}}

Scan the codebase for all route/endpoint definitions. For each endpoint, extract:

1. **HTTP method** (GET/POST/PUT/PATCH/DELETE)
2. **Path** including path parameters (e.g. /users/:id)
3. **Handler function name** and file location
4. **Request shape**:
   - Path parameters: name, type, required
   - Query parameters: name, type, required, default value
   - Request body: schema (inspect validation schemas, DTOs, Pydantic models, Zod schemas)
5. **Response shapes**:
   - Success status code and response body schema
   - All documented error responses (400, 401, 403, 404, 409, 422, 500)
6. **Authentication required**: Yes/No — which auth scheme?
7. **Authorization**: which roles/permissions required?
8. **Tags/groups**: which resource or domain does this endpoint belong to?

Patterns to look for per framework:
- Express: `router.get()`, `app.post()`, etc.
- FastAPI: `@app.get()`, `@router.post()`, etc.
- Gin: `r.GET()`, `r.POST()`, route groups
- Spring Boot: `@GetMapping`, `@PostMapping`, `@RequestMapping`
- NestJS: `@Get()`, `@Post()`, controller decorators

Output: a complete API inventory table:
| Method | Path | Auth | Handler | Request body | Response | Tags |
|--------|------|------|---------|--------------|----------|------|
```
Tools: Read, Grep, Glob

Gate: Print endpoint count by resource group. Ask "API inventory looks complete? Proceed to WRITE SPEC? [y/N]"

---

### Stage 2 — WRITE OPENAPI SPEC
Spawn the `api-developer` agent.

Agent prompt:
```
You are the api-developer agent.

API inventory from Stage 1:
{{INVENTORY_OUTPUT}}

Framework: {{FRAMEWORK}}  Auth: {{AUTH_MECHANISM}}

Write a complete OpenAPI 3.0.3 specification in YAML.

Structure:
```yaml
openapi: 3.0.3
info:
  title: [Project Name] API
  version: [version from package.json / build file]
  description: |
    [Brief description of the API]
  contact:
    name: API Support
    email: [from config or placeholder]

servers:
  - url: https://api.example.com/v1
    description: Production
  - url: https://staging-api.example.com/v1
    description: Staging
  - url: http://localhost:3000/v1
    description: Development

security:
  - [auth scheme]: []

components:
  securitySchemes:
    [Define based on {{AUTH_MECHANISM}}]
    # JWT: BearerAuth with bearerFormat: JWT
    # API key: ApiKeyAuth with in: header
    # OAuth2: OAuth2 with flows

  schemas:
    [One schema per resource/DTO — reuse with $ref]
    [Error response schema — reused across all error responses]

  responses:
    UnauthorizedError:
      description: Authentication required
      content:
        application/json:
          schema: $ref ErrorResponse
    [other reusable responses]

  parameters:
    [Reusable query params: pagination (page, limit, cursor), filters]

paths:
  [All endpoints from the inventory]
```

For EACH endpoint:
```yaml
/resource/{id}:
  get:
    summary: [One-line description]
    description: |
      [More detailed explanation if needed]
    operationId: getResource  # camelCase, unique across spec
    tags:
      - Resources
    security:
      - BearerAuth: []
    parameters:
      - name: id
        in: path
        required: true
        schema:
          type: string
          format: uuid
        description: Resource identifier
    responses:
      '200':
        description: Resource found
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ResourceResponse'
            example:
              id: "550e8400-e29b-41d4-a716-446655440000"
              [other fields with realistic example values]
      '401':
        $ref: '#/components/responses/UnauthorizedError'
      '403':
        description: Insufficient permissions
      '404':
        description: Resource not found
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/ErrorResponse'
```

Schema requirements:
- All properties have `type` and `description`
- All string properties with constraints have `minLength`, `maxLength`, `pattern` where applicable
- All numeric properties have `minimum`, `maximum` where applicable
- Required fields listed in `required` array
- Nullable fields use `nullable: true`
- Enum values listed in `enum` array
- Date/time fields use `format: date-time` (ISO 8601)
- IDs use `format: uuid` where applicable
- Example values are realistic (not "string" or 123)

Write the complete spec to `openapi.yaml` in the project root.
If openapi.yaml already exists, update it (do not delete existing content not covered by this run).
```
Tools: Read, Write

Gate: Print spec summary (endpoint count, schema count). Ask "Spec looks complete? Proceed to VALIDATION? [y/N]"

---

### Stage 3 — VALIDATE AND LINT
Spawn the `api-reviewer` agent.

Agent prompt:
```
You are the api-reviewer agent.

OpenAPI spec: openapi.yaml (just written by Stage 2)

Read and validate the spec for:

**Structural correctness**
- [ ] All $ref references resolve to existing components
- [ ] All operationIds are unique
- [ ] Required fields present: openapi, info, paths
- [ ] All path parameters defined in `parameters` section
- [ ] Response schemas defined for all documented status codes

**Completeness**
- [ ] All endpoints from the inventory are present
- [ ] Every endpoint has at least one 2xx and one 4xx response documented
- [ ] All request body schemas have required fields marked
- [ ] All response schemas have descriptions
- [ ] No empty `{}` schemas without properties

**Quality**
- [ ] No inline schemas that should be $ref'd (schemas used in more than one place)
- [ ] Consistent naming: snake_case properties, PascalCase schema names
- [ ] Examples are realistic values (not "string", not 0)
- [ ] Error responses all use the shared ErrorResponse schema via $ref
- [ ] Security applied at operation level where it differs from global default

**Security documentation**
- [ ] Auth scheme correctly documented (JWT Bearer / API Key / OAuth2)
- [ ] Endpoints that don't require auth have `security: []` override
- [ ] Scopes documented for OAuth2 endpoints

Output: list of issues found (with line references). If no issues, state "Spec passes validation."
Fix any issues directly in openapi.yaml.
```
Tools: Read, Edit, Grep

Gate: Ask "Validation complete. Proceed to DOCUMENTATION PUBLISH? [y/N]"

---

### Stage 4 — DOCUMENTATION
Spawn the `api-developer` agent.

Agent prompt:
```
You are the api-developer agent.

OpenAPI spec: openapi.yaml
Docs platform: {{DOCS_PLATFORM}}
Ticket system: {{TICKET_SYSTEM}}

Produce:

1. **README section** — API documentation quick-start:
   - Authentication: how to get a token / API key
   - Base URL for each environment
   - Rate limits (if documented)
   - Versioning strategy
   - How to run the spec locally (Swagger UI / Redoc command)

2. **Changelog entry** — what endpoints were added/modified in this spec update:
   ```
   ## API v[version] — [date]
   ### Added
   - POST /resource — creates a new resource
   ### Changed
   - GET /resource/{id} — added `include` query parameter
   ### Deprecated
   - GET /old-endpoint — use GET /new-endpoint instead
   ```

3. **Ticket for {{TICKET_SYSTEM}}**:
   "Create Chore: Update API documentation — publish openapi.yaml to {{DOCS_PLATFORM}} | Priority: P2"

4. **CI check snippet** (optional):
   Show how to add an OpenAPI lint step to CI (using redocly or spectral):
   ```yaml
   - name: Lint OpenAPI spec
     run: npx @redocly/cli lint openapi.yaml
   ```
```
Tools: Read, Write

---

## OpenAPI Summary Report

After all stages complete, print:

```
════════════════════════════════════════════════════════
  OpenAPI Spec — {{TARGET}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — DISCOVERY    N endpoints across N resource groups
  [✓] Stage 2 — SPEC WRITTEN openapi.yaml — N paths, N schemas
  [✓] Stage 3 — VALIDATED    N issues found and fixed
  [✓] Stage 4 — DOCS         README updated, changelog written
════════════════════════════════════════════════════════

Spec file: openapi.yaml
Preview: npx @redocly/cli preview-docs openapi.yaml
   or: npx swagger-ui-express (if using Express)

Endpoints documented:
  [resource group]: N endpoints
  ...

Next steps:
  [ ] Publish to {{DOCS_PLATFORM}}
  [ ] Add lint step to CI
  [ ] Create ticket in {{TICKET_SYSTEM}}
```

---

## Variables

- `{{TARGET}}` = argument passed to this command (file path, feature name, or "all")
- `{{INVENTORY_OUTPUT}}` = Stage 1 output (first 3000 chars)
- `{{LANGUAGE}}`, `{{FRAMEWORK}}`, `{{API_STYLE}}`, `{{AUTH_MECHANISM}}` = from backend.config.md
- `{{DOCS_PLATFORM}}`, `{{TICKET_SYSTEM}}` = from workflow.config.md
