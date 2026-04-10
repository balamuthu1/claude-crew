---
description: Auto-detect the backend tech stack and write backend.config.md. Reads build files, package.json, requirements.txt, go.mod, pom.xml, Dockerfile.
---

Detect the project's backend stack by reading:
- `package.json` / `package-lock.json` (Node.js)
- `requirements.txt` / `pyproject.toml` / `setup.py` (Python)
- `go.mod` (Go)
- `pom.xml` / `build.gradle` (Java/Kotlin)
- `Cargo.toml` (Rust)
- `Gemfile` (Ruby)
- `Dockerfile` / `docker-compose.yml` (container/deployment info)

From these, determine:
- Language and runtime version
- Web framework (Express, FastAPI, Django, Gin, Spring Boot, etc.)
- ORM / database client
- Primary database
- Auth library
- Test framework
- Deployment target (Docker, K8s, Lambda, etc.)

Write `backend.config.md`:

```yaml
language: <python|node|go|java|ruby|rust>
runtime: <version>
framework: <express|fastapi|django|gin|spring-boot|...>
orm: <prisma|sqlalchemy|gorm|hibernate|...>
database: <postgresql|mysql|mongodb|redis|...>
auth: <jwt|session|oauth2|...>
testing: <jest|pytest|go-test|junit|...>
deployment: <docker|kubernetes|lambda|...>
```

Write the file and confirm to the user.
