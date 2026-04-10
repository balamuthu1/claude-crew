Review dbt models for SQL correctness, layer conventions, test coverage, and documentation completeness. Argument is a model name, directory, or glob pattern.

You are the **orchestrator**. Do NOT review models yourself — spawn dedicated sub-agents.

**Stages 2 and 3 (test coverage + documentation): call `Agent` twice in a single message to run them in parallel.**

---

## Before starting

Read `data.config.md` and `workflow.config.md`. Extract:
- `{{WAREHOUSE}}` — bigquery, snowflake, redshift, databricks, postgres
- `{{DBT_VERSION}}` — e.g. 1.7.0
- `{{DBT_PROJECT_NAME}}` — project name from dbt_project.yml
- `{{TICKET_SYSTEM}}` — from workflow.config.md

---

## Stage Definitions

### Stage 1 — MODEL REVIEW
Spawn the `data-reviewer` agent.

Agent prompt:
```
You are the data-reviewer agent.

dbt models to review: {{TARGET}}
Warehouse: {{WAREHOUSE}}
dbt version: {{DBT_VERSION}}
dbt project: {{DBT_PROJECT_NAME}}

Read data.config.md and profiles/data/rules/sql-standards.md and
profiles/data/rules/data-engineering.md before reviewing.

Review every model and YAML file. Every finding requires a FILE:LINE reference.

---

## Layer conventions

- [ ] Model prefix is correct for its location:
  - models/staging/ → prefix stg_
  - models/intermediate/ → prefix int_
  - models/marts/core/ or models/marts/ → prefix fct_ or dim_
  - Snapshot files → no prefix requirement, but named [entity]_snapshot
- [ ] Staging models reference ONLY source() — no ref() to other models
- [ ] Staging models contain ONLY: renaming, type casting, deduplication, NULL normalisation
  No joins, no business logic, no aggregations in staging
- [ ] Intermediate models use ref() to staging or other intermediate models
- [ ] Mart models (fct_/dim_) use ref() to intermediate or staging — not source()
- [ ] No circular dependencies (model A refs model B which refs model A)

## SQL quality

- [ ] ref() used for all model-to-model references — never hardcoded schema.table
- [ ] source() used for all raw table references — never hardcoded raw_schema.table
- [ ] No SELECT * — all columns listed explicitly
- [ ] CTEs named descriptively (not cte1, cte2, subquery, tmp)
- [ ] Complex business logic has an inline SQL comment explaining the rule
- [ ] SQL keywords UPPERCASE (SELECT, FROM, WHERE, JOIN, GROUP BY, ORDER BY)
- [ ] Consistent 4-space indentation
- [ ] Lines ≤ 100 characters (or project's configured max)
- [ ] No trailing whitespace

## Correctness

- [ ] JOINs: ON clause is correct — no accidental Cartesian product
- [ ] JOIN type appropriate: INNER, LEFT, FULL OUTER — documented if non-obvious
- [ ] Many-to-many JOIN risk: if either side can have duplicates, DISTINCT applied or fan-out acknowledged
- [ ] Aggregation grain: GROUP BY includes ALL non-aggregated columns
- [ ] Window functions: PARTITION BY and ORDER BY are correct for the intended calculation
- [ ] NULL handling: NULLs in JOIN keys, CASE expressions, and comparisons handled explicitly
- [ ] COALESCE used deliberately — not masking data quality issues silently
- [ ] Date arithmetic: timezone-aware? No implicit tz conversion?

## Performance ({{WAREHOUSE}}-specific)

For ALL warehouses:
- [ ] No full table scan when a partition filter could be applied
- [ ] No SELECT * on tables that could grow large
- [ ] Filtering before aggregation (not aggregating then filtering)
- [ ] Correlated subqueries replaced with CTEs or JOIN

For BigQuery specifically:
- [ ] Partition filter on partition column in WHERE clause (avoid full scan charges)
- [ ] ARRAY_AGG and UNNEST used instead of self-joins where applicable

For Snowflake specifically:
- [ ] Clustering key columns used in WHERE/JOIN to enable micro-partition pruning
- [ ] QUALIFY used instead of subquery for window function filtering

For Redshift specifically:
- [ ] DISTKEY matches the JOIN key for large tables
- [ ] SORTKEY matches the most common filter column

## Incremental models

If model has `materialized='incremental'`:
- [ ] unique_key is defined and is truly unique in the source data
- [ ] {% if is_incremental() %} filter block present and correct
- [ ] Watermark column (e.g. updated_at, created_at) used for incremental filter
- [ ] Strategy is appropriate: append, merge, or delete+insert — documented
- [ ] Full refresh fallback considered (what happens on dbt run --full-refresh?)

## dbt configuration

- [ ] {{ config(...) }} block present with appropriate materialisation
- [ ] tags configured for scheduling (e.g. tags=['daily', 'finance'])
- [ ] meta fields present (owner, pii, data_classification)
- [ ] contract: enforced on models with strict downstream consumers (dbt ≥ 1.5)

---

Output:
## dbt Review — {{TARGET}}

### Critical (incorrect results or data loss risk)
- [FILE:LINE] Issue — Impact — Fix

### Major (performance or architecture gap)
- [FILE:LINE] Issue — Fix

### Minor (style, naming, or documentation)
- [FILE:LINE] Suggestion

### Approved patterns
- [FILE:LINE] Good practice worth noting
```
Tools: Read, Grep, Glob

Gate: Print review summary. Ask "Review complete. Proceed to TEST COVERAGE + DOCUMENTATION in parallel? [y/N]"

---

### Stage 2 — TEST COVERAGE  ← spawn in PARALLEL with Stage 3
Spawn the `data-engineer` agent.

Agent prompt:
```
You are the data-engineer agent focused on dbt test coverage.

dbt models: {{TARGET}}
dbt version: {{DBT_VERSION}}

Read the existing schema YAML files for all models in {{TARGET}}.

1. **Coverage inventory** — for each model, list:
   - Does a .yml schema file exist? Yes/No
   - Primary key column(s): has unique + not_null test? Yes/No
   - Foreign key columns: has relationships test? Yes/No
   - Status/enum columns: has accepted_values test? Yes/No
   - Required columns: has not_null test? Yes/No
   - Source: has freshness test defined? Yes/No

2. **Write missing tests** — for every gap identified above:

   For each model missing schema YAML, create [model_name].yml with:
   ```yaml
   version: 2
   models:
     - name: [model_name]
       description: "[infer from SQL — describe grain in first sentence]"
       columns:
         - name: [pk_column]
           description: "[primary key description]"
           tests:
             - not_null
             - unique
         - name: [fk_column]
           description: "[foreign key description]"
           tests:
             - not_null
             - relationships:
                 to: ref('[parent_model]')
                 field: [parent_pk_column]
         - name: [status_column]
           description: "[status description]"
           tests:
             - not_null
             - accepted_values:
                 values: ['active', 'inactive', ...]  # infer from SQL CASE statements
   ```

   For sources missing freshness, add:
   ```yaml
   sources:
     - name: [source_name]
       freshness:
         warn_after: {count: 12, period: hour}
         error_after: {count: 24, period: hour}
       loaded_at_field: _loaded_at
       tables:
         - name: [table_name]
   ```

3. **Custom singular tests** — write SQL tests for business rules that schema tests cannot express:
   For each model, write at least one singular test covering a non-trivial business rule.
   File path: tests/assert_[model]_[rule].sql
   Must return 0 rows to pass.

Write all YAML and test SQL files.
List each file path and what was added.
```
Tools: Read, Write, Grep, Glob

---

### Stage 3 — DOCUMENTATION PASS  ← spawn in PARALLEL with Stage 2
Spawn the `data-reviewer` agent.

Agent prompt:
```
You are the data-reviewer agent focused on documentation quality.

dbt models: {{TARGET}}
dbt version: {{DBT_VERSION}}

Read all schema YAML files for models in {{TARGET}}.

1. **Documentation audit** — for each model:
   - Model description: present and meaningful? (not just the table name)
   - Column descriptions: present for ALL columns? Meaningful (not just column name repeated)?
   - Grain statement: does the model description include "one row represents ONE [X]"?
   - meta tags: owner, pii, sla fields present?

2. **Write missing descriptions**:
   For every model or column with a missing or generic description:
   - Infer the description from the SQL logic, column name, and context
   - Add the grain statement if it's a model description
   - Mark columns that are PII: meta: {pii: true}
   - Flag any column where the business meaning is ambiguous (needs human input)

   Format: "⚠ NEEDS HUMAN INPUT: [column] in [model] — purpose unclear from SQL"

3. **Meta tag standardisation**:
   For every model, ensure the config block includes:
   ```yaml
   meta:
     owner: "[team — infer from model name/domain]"
     pii: false  # or true if the model contains PII columns
     sla: "daily"  # or "hourly" / "weekly" based on materialisation schedule
   ```

Write updated schema YAML files.
List what was added vs what was flagged for human input.
```
Tools: Read, Write, Grep

After both Stage 2 and Stage 3 complete, print their combined outputs.
Gate: Ask "Test coverage and documentation complete. Proceed to SUMMARY? [y/N]"

---

## dbt Review Summary Report

After all stages complete, print:

```
════════════════════════════════════════════════════════
  dbt Review — {{TARGET}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — MODEL REVIEW    Critical: N, Major: N, Minor: N
  [✓] Stage 2 — TEST COVERAGE   Tests added: N, Models fully tested: N/N
  [✓] Stage 3 — DOCUMENTATION   Descriptions added: N, Needs human input: N
════════════════════════════════════════════════════════

Validate changes:
  dbt compile --select {{TARGET}}
  dbt test --select {{TARGET}}

Tickets to create in {{TICKET_SYSTEM}}:
  [list Critical and Major findings]

Models needing human input for documentation:
  [list flagged columns/models from Stage 3]
```

---

## Variables

- `{{TARGET}}` = argument passed to this command (model name, directory, or glob)
- `{{WAREHOUSE}}`, `{{DBT_VERSION}}`, `{{DBT_PROJECT_NAME}}` = from data.config.md
- `{{TICKET_SYSTEM}}` = from workflow.config.md
