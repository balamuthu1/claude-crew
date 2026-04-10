Run a full data pipeline review workflow for the file or pipeline described in the argument.

You are the **orchestrator**. Do NOT review the pipeline yourself — spawn dedicated
sub-agents for each stage.

**For stages 2 and 3 (quality + security): call `Agent` twice in a single message to run them in parallel.**

---

## Before starting

Read `data.config.md` and `workflow.config.md`. Extract:
- `{{WAREHOUSE}}` — target data warehouse
- `{{TRANSFORMATION_TOOL}}` — dbt, spark, pandas, etc.
- `{{ORCHESTRATOR}}` — airflow, prefect, dagster, etc.
- `{{DATA_QUALITY_TOOL}}` — dbt-tests, great-expectations, etc.
- `{{TICKET_SYSTEM}}` — from workflow.config.md
- `{{DOCS_PLATFORM}}` — from workflow.config.md
- `{{BI_TOOL}}` — downstream consumers of this pipeline's output

---

## Stage Definitions

### Stage 1 — CODE REVIEW
Spawn the `data-reviewer` agent.

Agent prompt:
```
You are the data-reviewer agent.

Pipeline to review: {{PIPELINE}}

Read data.config.md:
  - Warehouse: {{WAREHOUSE}}
  - Transformation tool: {{TRANSFORMATION_TOOL}}
  - Orchestrator: {{ORCHESTRATOR}}

Review ALL pipeline code for:

**Correctness**
- [ ] Idempotency: re-running produces the same result (no duplicate rows)
- [ ] Incremental logic: watermark column correct? No gaps possible?
- [ ] Deduplication: is it needed? Is it applied correctly?
- [ ] NULL handling: nulls handled explicitly, not accidentally coerced
- [ ] Type coercions: safe and intentional
- [ ] JOIN correctness: no accidental fan-out (many-to-many joins inflating row counts)
- [ ] Aggregation grain: correct grouping keys, no double-counting

**Data quality**
- [ ] Row count validation at pipeline output (not zero, not anomalous)
- [ ] Primary key uniqueness checked
- [ ] Foreign key referential integrity checked
- [ ] Categorical values validated (accepted_values or equivalent)
- [ ] Date range sanity check (no dates in the future, no dates before business start)

**Performance**
- [ ] No full warehouse scan when partition pruning is possible
- [ ] Indices / clustering keys used on filter columns ({{WAREHOUSE}} conventions)
- [ ] No SELECT * in production models
- [ ] Aggregations happen after filtering, not before
- [ ] No N+1 lookup patterns

**Observability**
- [ ] Row count metric emitted at pipeline completion
- [ ] Processing duration logged
- [ ] Failed records go to dead letter queue (not silently dropped)
- [ ] Alerts defined for pipeline failure and data freshness breach

**For dbt models (if applicable)**
- [ ] Model in correct layer (stg_ / int_ / fct_ / dim_)?
- [ ] YAML schema file present with column descriptions
- [ ] not_null + unique tests on primary key columns
- [ ] accepted_values tests on status/enum columns
- [ ] Source freshness test defined

Output format:
## Data Pipeline Review

### Critical (incorrect results or data loss risk)
- [FILE:LINE] Issue — Impact — Fix

### Major (performance or observability gap)
- [FILE:LINE] Issue — Fix

### Minor (style or documentation)
- [FILE:LINE] Suggestion

### Approved patterns
- [FILE:LINE] Good practice worth noting

Write specific file:line references for every finding.
Apply rules from profiles/data/rules/data-engineering.md and profiles/data/rules/sql-standards.md.
```
Tools: Read, Grep, Glob

Gate: Print review summary. Ask "Issues noted. Proceed to QUALITY + SECURITY in parallel? [y/N]"

---

### Stage 2 — DATA QUALITY CHECKS  ← spawn in PARALLEL with Stage 3
Spawn the `data-engineer` agent.

Agent prompt:
```
You are the data-engineer agent focused on data quality.

Pipeline: {{PIPELINE}}

Review from Stage 1:
{{REVIEW_OUTPUT}}

Read data.config.md:
  - Data quality tool: {{DATA_QUALITY_TOOL}}
  - dbt default tests: {{DBT_DEFAULT_TESTS}}
  - Warehouse: {{WAREHOUSE}}

Write comprehensive data quality checks for this pipeline using {{DATA_QUALITY_TOOL}}.

For dbt models, write YAML schema tests:
  - not_null: all primary key and required columns
  - unique: all primary key columns
  - accepted_values: all status, type, enum columns
  - relationships: all foreign key columns → parent table
  - custom tests (dbt-expectations or singular tests) for:
    - row count within expected range
    - date column within valid range
    - numeric column within business-valid range

For Great Expectations / Soda, write expectation suites / checks that mirror the above.

Also write:
1. **Source freshness check** — how old is the source data allowed to be?
2. **Freshness SLO alert** — what triggers an alert if data is stale?
3. **Dead letter queue** — where do failed/invalid records go?
4. **Reconciliation check** — does output row count match source row count (if applicable)?

Write production-ready check files with comments.
```
Tools: Read, Write, Edit, Glob

---

### Stage 3 — SECURITY & PII REVIEW  ← spawn in PARALLEL with Stage 2
Spawn the `data-reviewer` agent.

Agent prompt:
```
You are the data-reviewer agent focused on security and PII.

Pipeline: {{PIPELINE}}

Read profiles/data/rules/data-security-guardrails.md.

Audit for:

**PII exposure**
- Which columns in the output contain PII (names, emails, phone, IP, device IDs)?
- Are PII columns hashed/masked in the staging layer?
- Are there any PII columns exposed directly in mart/analytics models?
- Is user-level granularity exposed to BI tools ({{BI_TOOL}})?

**Credential exposure**
- Any hardcoded database credentials, API keys, or connection strings?
- Are secrets loaded from environment variables or secret manager?
- Is any sensitive config committed to git?

**Access control**
- Is row-level security applied for multi-tenant data?
- Are column-level masks applied for PII in {{WAREHOUSE}}?
- Does the service account follow least-privilege?

**Audit trail**
- Are data modification operations (DELETE, UPDATE) logged?
- Is there a clear data lineage from source to output?

**Data retention**
- Is a retention period defined for each dataset?
- Is there a documented deletion process for GDPR/CCPA requests?

Output:
## Security & PII Audit

### Critical (immediate action required)
- [FILE:LINE] Issue — Risk — Remediation

### High (fix before production)
- [FILE:LINE] Issue — Remediation

### Medium (address in next sprint)
- [FILE:LINE] Suggestion

### PII inventory
| Column | Table | PII Type | Current masking | Required masking |
|--------|-------|----------|-----------------|-----------------|
```
Tools: Read, Grep, Glob

After both Stage 2 and Stage 3 complete, print their combined outputs.
Gate: Ask "Proceed to DOCUMENTATION? [y/N]"

---

### Stage 4 — DOCUMENTATION & TICKETS
Spawn the `data-engineer` agent.

Agent prompt:
```
You are the data-engineer agent.

Pipeline: {{PIPELINE}}

Review, quality checks, and security findings from previous stages:
{{REVIEW_OUTPUT}}
{{QUALITY_OUTPUT}}
{{SECURITY_OUTPUT}}

Read data.config.md and workflow.config.md:
  - Docs platform: {{DOCS_PLATFORM}}
  - Ticket system: {{TICKET_SYSTEM}}
  - BI tool: {{BI_TOOL}}

Produce:

1. **Pipeline documentation** formatted for {{DOCS_PLATFORM}}:
   - Purpose: what this pipeline does and why it exists
   - Data flow diagram (ASCII/text): source → transformation → output
   - Source description: table/API, refresh cadence, owner
   - Output description: tables/datasets produced, grain (one row = one X)
   - Schedule: when it runs and expected completion time
   - SLOs: freshness SLO, row count range, data quality thresholds
   - Runbook: how to manually trigger, how to backfill, how to investigate failures
   - Owner: team responsible

2. **Column data dictionary** for each output table:
   | Column | Type | Description | PII | Example value |
   |--------|------|-------------|-----|---------------|

3. **Ticket creation instructions** for {{TICKET_SYSTEM}}:
   For each Critical and High finding:
   "Create [issue type]: [summary] | Priority: [P0/P1] | Component: Data"
   
   For quality checks not yet implemented:
   "Create [issue type]: Add data quality checks for [model] | Priority: P1"
```
Tools: Read, Write

---

## Pipeline Review Summary Report

After all stages complete, print:

```
════════════════════════════════════════════════════════
  Data Pipeline Review — {{PIPELINE}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — CODE REVIEW      Critical: N, Major: N, Minor: N
  [✓] Stage 2 — DATA QUALITY     Checks written: N
  [✓] Stage 3 — SECURITY/PII     PII columns found: N, Critical issues: N
  [✓] Stage 4 — DOCUMENTED       Docs ready for {{DOCS_PLATFORM}}
════════════════════════════════════════════════════════

Tickets to create in {{TICKET_SYSTEM}}:
  [list Critical and High items]

PII requiring masking:
  [list unmasked PII columns found in Stage 3]
```

---

## Variables

- `{{PIPELINE}}` = argument passed to this command (file path or pipeline name)
- `{{REVIEW_OUTPUT}}` = Stage 1 output (first 3000 chars)
- `{{QUALITY_OUTPUT}}` = Stage 2 output summary
- `{{SECURITY_OUTPUT}}` = Stage 3 output summary
- `{{WAREHOUSE}}`, `{{TRANSFORMATION_TOOL}}`, `{{ORCHESTRATOR}}`,
  `{{DATA_QUALITY_TOOL}}`, `{{DBT_DEFAULT_TESTS}}`, `{{BI_TOOL}}` = from data.config.md
- `{{TICKET_SYSTEM}}`, `{{DOCS_PLATFORM}}` = from workflow.config.md
