# Data Security Guardrails

These rules apply to all data engineering and ML work.

## Non-bypassable rules

1. **Never commit service account keys or cloud credentials** — use workload identity, instance profiles, or a secrets manager.
2. **Never log PII** — names, emails, phone numbers, IDs, payment data must not appear in pipeline logs or error messages.
3. **Never hardcode connection strings or passwords** — use environment variables or secrets manager references.
4. **Never query production data directly from a developer machine** — use a dedicated analytics environment with row/column masking.
5. **Never store ML training data containing PII unencrypted** — apply pseudonymisation or k-anonymity before training.

## Sensitive file patterns (block read/write/commit)

```
service-account.json
*-service-account.json
~/.dbt/profiles.yml
.dbt/profiles.yml
airflow.cfg               # contains Fernet key
~/.aws/credentials
.aws/credentials
kubeconfig
*.pem
*.key
```

## PII handling

### Identify PII in data
Direct PII: name, email, phone, address, government ID, IP address, device ID
Quasi-identifier: birthdate + gender + zip code can re-identify individuals

### PII pipeline controls
- Stage 1 (raw): PII in encrypted raw storage, access restricted to data engineers
- Stage 2 (staging): PII pseudonymised using consistent hash or tokenisation
- Stage 3 (mart): aggregate-level only; no individual-level PII
- ML features: derived features only; never raw PII columns in feature stores

### Data retention
Every dataset with PII must have a documented retention period. Deletion pipelines must execute on schedule. Deletion must cascade across derived tables and ML training sets.

## Access controls

- Row-level security for multi-tenant data warehouses
- Column masking for PII columns in analytical queries
- Service accounts scoped per pipeline — not shared super-credentials
- Data access audit logs enabled for all production datasets

## ML-specific security

- Training data: version-controlled with provenance (which source, when extracted)
- Model artefacts: stored in model registry with access control
- Inference API: authenticated; rate-limited; inputs validated
- Prompt injection (LLM): treat all user-provided text as untrusted input; never concatenate into system prompts
