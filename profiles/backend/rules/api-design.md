# API Design Standards

These rules apply to all backend API development. Read before reviewing or writing any API code.

## REST API conventions

### URL structure
- Resource-based: `/users`, `/orders`, `/products`
- Hierarchical only when resources are truly nested: `/users/{id}/orders`
- Avoid verbs in URLs: `/orders` + `POST` not `/create-order`
- Use plural nouns for collections
- Versioning in path: `/v1/users`

### HTTP methods
- `GET`: safe, idempotent — no side effects
- `POST`: create a new resource or non-idempotent action
- `PUT`: replace a resource entirely (idempotent)
- `PATCH`: partial update (send only changed fields)
- `DELETE`: remove a resource (idempotent)

### Status codes
| Code | When |
|------|------|
| `200 OK` | Successful GET, PUT, PATCH |
| `201 Created` | Successful POST that creates a resource (include `Location` header) |
| `204 No Content` | Successful DELETE |
| `400 Bad Request` | Validation failure (include field-level errors) |
| `401 Unauthorized` | Missing or invalid authentication |
| `403 Forbidden` | Authenticated but not authorised |
| `404 Not Found` | Resource does not exist |
| `409 Conflict` | Business rule conflict (duplicate, wrong state) |
| `422 Unprocessable Entity` | Valid JSON but semantic error |
| `429 Too Many Requests` | Rate limit exceeded |
| `500 Internal Server Error` | Unhandled server error |

### Error response shape (standard)
```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "The request contains invalid fields",
    "details": [
      { "field": "email", "message": "Must be a valid email address" }
    ]
  }
}
```

Never expose: stack traces, internal error codes, database error messages, or internal service names.

## Request/response standards

- Accept and respond with `application/json`
- Use ISO 8601 for dates: `2024-03-15T10:30:00Z`
- Use snake_case for JSON fields
- Paginate all list endpoints: `{ data: [...], meta: { page, per_page, total } }`
- Filter with query params: `GET /orders?status=pending&from=2024-01-01`
- Sort with query params: `GET /orders?sort=created_at&order=desc`

## Authentication and authorisation

- Use JWT Bearer tokens: `Authorization: Bearer <token>`
- Access tokens: short-lived (15 min - 1 hour)
- Refresh tokens: longer-lived, rotated on use, stored in httpOnly cookie
- Verify token on every protected request — no session caching without explicit invalidation support
- Authorisation checks: verify ownership, not just authentication

## OpenAPI documentation

Every API endpoint must have OpenAPI/Swagger documentation covering:
- Summary and description
- All request parameters (path, query, body)
- All response codes with example responses
- Authentication requirements
- Rate limit headers
