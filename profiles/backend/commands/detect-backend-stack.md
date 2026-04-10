---
description: Interactive setup for the backend profile. Auto-detects tech stack from build files, then asks about infrastructure, tooling, and workflow preferences. Writes backend.config.md.
---

Run directly — do not spawn a sub-agent.

## Step 1 — Check prerequisites

Read `workflow.config.md`. If it doesn't exist, say:
```
⚠  workflow.config.md not found.
Run /detect-workflow first to set your ticket system and docs platform.
Continuing with detection — you can run /detect-workflow afterwards.
```

Read `backend.config.md` if it exists. If found, show current values and ask:
```
backend.config.md already exists. Update it? [y/N]
```

---

## Step 2 — Auto-detect language and framework

Scan for build/dependency files in this order:

| File | Language | Clues to check |
|------|----------|---------------|
| `package.json` | Node.js | dependencies for express, fastify, nest, koa, hapi |
| `requirements.txt` / `pyproject.toml` | Python | fastapi, django, flask, sanic, starlette |
| `go.mod` | Go | gin, echo, fiber, chi, gorilla/mux |
| `pom.xml` / `build.gradle` | Java/Kotlin | spring-boot, quarkus, micronaut |
| `Gemfile` | Ruby | rails, sinatra, grape |
| `Cargo.toml` | Rust | actix-web, axum, warp, rocket |
| `*.csproj` / `*.sln` | .NET | ASP.NET Core |

Read the detected file and extract:
- Language + runtime version
- Web framework and version
- ORM / database client
- Test framework
- Any cloud SDK (aws-sdk, google-cloud, azure)

Show what was detected:
```
Detected:
  Language  : Node.js 20
  Framework : Express 4.18
  ORM       : Prisma
  Tests     : Jest
  Cloud SDK : AWS SDK v3
```

Ask: "Is this correct? [Y/n]"

If N, ask the user to specify values manually.

---

## Step 3 — Database

Ask:
```
What is your primary database?

  1) PostgreSQL
  2) MySQL / MariaDB
  3) MongoDB
  4) SQLite (local / edge)
  5) DynamoDB
  6) Firestore / Cloud Firestore
  7) CockroachDB
  8) PlanetScale (MySQL-compatible)
  9) Supabase (PostgreSQL)
  10) Other

Enter number (or type name):
```

Ask:
```
Do you use a separate caching layer?
  1) Redis
  2) Memcached
  3) None / in-memory cache only

Enter number:
```

Ask:
```
How are database migrations managed?
  1) Prisma Migrate
  2) Alembic (Python)
  3) Flyway
  4) Liquibase
  5) Goose (Go)
  6) Active Record Migrations (Rails)
  7) TypeORM migrations
  8) Custom SQL files
  9) None / managed externally

Enter number:
```

---

## Step 4 — API style

Ask:
```
What API style does this service expose?
  1) REST (JSON over HTTP)
  2) GraphQL
  3) gRPC
  4) tRPC
  5) Mixed (REST + GraphQL, etc.)

Enter number:
```

Ask:
```
Do you maintain an OpenAPI / Swagger spec? [y/N]
```

---

## Step 5 — Auth strategy

Ask:
```
How does this service handle authentication?
  1) JWT (Bearer token in Authorization header)
  2) Session cookies (httpOnly)
  3) OAuth 2.0 / OpenID Connect
  4) API keys
  5) mTLS (mutual TLS)
  6) Handled externally (API gateway / service mesh)
  7) None (internal service)

Enter number:
```

---

## Step 6 — Infrastructure

Ask:
```
Which CI/CD system does your team use?
  1) GitHub Actions
  2) GitLab CI/CD
  3) CircleCI
  4) Jenkins
  5) Azure DevOps Pipelines
  6) Bitbucket Pipelines
  7) TeamCity
  8) Other / none

Enter number:
```

Ask:
```
Which cloud provider?
  1) AWS
  2) Google Cloud (GCP)
  3) Microsoft Azure
  4) DigitalOcean
  5) Fly.io
  6) Render
  7) Railway
  8) Self-hosted / on-prem
  9) Other

Enter number:
```

Ask:
```
How is the service deployed/run?
  1) Kubernetes (self-managed)
  2) AWS ECS / Fargate
  3) Google Cloud Run
  4) AWS Lambda / serverless
  5) Azure Container Apps
  6) Heroku / Render / Railway (PaaS)
  7) Bare VM / EC2 / GCE
  8) Other

Enter number:
```

Ask:
```
Where are secrets / credentials stored?
  1) AWS Secrets Manager
  2) GCP Secret Manager
  3) Azure Key Vault
  4) HashiCorp Vault
  5) Environment variables (injected by CI/CD)
  6) .env files (local dev only, not committed)
  7) Other

Enter number:
```

---

## Step 7 — Monitoring

Ask:
```
What logging/observability stack do you use?
  1) Datadog
  2) Prometheus + Grafana
  3) AWS CloudWatch
  4) Google Cloud Logging / Monitoring
  5) New Relic
  6) OpenTelemetry (collector to be determined)
  7) None / standard stdout

Enter number (or multiple separated by commas):
```

---

## Step 8 — Workflow preferences check

Read `workflow.config.md`. Show:
```
Workflow tools (from workflow.config.md):
  Ticket system  : <value or "not set — run /detect-workflow">
  Docs platform  : <value or "not set — run /detect-workflow">
```

Ask:
```
Backend agents will create tickets in <system> and link docs in <platform>.
Is this correct for this project? [Y/n]
```

If N, ask which system to use for this project (override in backend.config.md).

---

## Step 9 — Write backend.config.md

Write the file with all detected and answered values. Use the format from the template.

---

## Step 10 — Confirm

```
✓ backend.config.md written.

Detected stack:
  Language    : <language> <version>
  Framework   : <framework>
  Database    : <db>
  Auth        : <auth>
  CI/CD       : <ci>
  Cloud       : <cloud>

All backend agents will now review and build against this stack.

Next steps:
  /detect-workflow      ← set ticket system + docs platform (if not done)
  /detect-gitflow       ← configure git branching conventions
  /api-sdlc <feature>   ← build your first backend feature
```
