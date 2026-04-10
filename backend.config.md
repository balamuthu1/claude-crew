# Claude Crew — Backend Config
# Run /detect-backend-stack to auto-fill this file.
# All backend agents read this before every task.

## Tech Stack

language: node              # node | python | go | java | ruby | rust | dotnet | php
runtime: 20                 # version number
framework: express          # express | fastapi | django | flask | gin | echo | spring-boot | rails | laravel | actix
orm: prisma                 # prisma | sqlalchemy | gorm | hibernate | activerecord | sequelize | typeorm | none

## Database

database_primary: postgresql # postgresql | mysql | mongodb | redis | sqlite | dynamodb | firestore | other
database_cache: redis        # redis | memcached | none
migration_tool: prisma       # prisma | alembic | flyway | liquibase | goose | active-record | none

## Auth

auth_strategy: jwt           # jwt | session | oauth2 | api-key | mtls | none
token_storage: httponly-cookie # httponly-cookie | bearer-header | both

## API Style

api_style: rest              # rest | graphql | grpc | trpc | mixed
api_versioning: path         # path (/v1/) | header | none
openapi_spec: true           # true | false

## Testing

test_framework: jest         # jest | pytest | go-test | junit | rspec | vitest | mocha
test_runner: npm test
integration_db: docker       # docker (test containers) | in-memory | shared-dev | none

## Infrastructure

ci_cd: github-actions        # github-actions | gitlab-ci | circleci | jenkins | azure-devops | none
cloud: aws                   # aws | gcp | azure | digitalocean | fly | render | other
container: docker            # docker | podman | none
orchestration: kubernetes    # kubernetes | ecs | cloud-run | app-engine | none
secrets_manager: aws-secrets # aws-secrets | gcp-secret-manager | azure-keyvault | hashicorp-vault | env-file | none

## Monitoring

logging: structured-json     # structured-json | plain | winston | pino | loguru | zerolog
metrics: prometheus          # prometheus | datadog | cloudwatch | new-relic | none
tracing: opentelemetry       # opentelemetry | jaeger | datadog | none

## Workflow Tools
# Set by /detect-workflow — agents use these to create tickets and link docs

ticket_system: jira          # from workflow.config.md
docs_platform: confluence    # from workflow.config.md
