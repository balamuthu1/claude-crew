Design a complete data model for a new entity or domain. Argument is an entity or domain name (e.g. "orders", "user events", "subscription lifecycle").

You are the **orchestrator**. Do NOT design or implement any model yourself — spawn dedicated sub-agents for each stage using the `Agent` tool. Each sub-agent runs in an isolated context window.

---

## Before starting

Read `data.config.md` and `workflow.config.md`. Extract:
- `{{WAREHOUSE}}` — target data warehouse (bigquery, snowflake, redshift, databricks, postgres)
- `{{TRANSFORMATION_TOOL}}` — dbt, spark, pandas, raw SQL
- `{{DBT_VERSION}}` — dbt version (e.g. 1.7.0)
- `{{DBT_PROJECT_NAME}}` — dbt project name
- `{{BI_TOOL}}` — downstream BI tool (looker, metabase, tableau, power bi, etc.)
- `{{TICKET_SYSTEM}}` — from workflow.config.md
- `{{DOCS_PLATFORM}}` — from workflow.config.md (confluence, notion, datahub, atlan, etc.)

Set `{{ENTITY}}` = the argument passed to this command.

If `data.config.md` does not exist, tell the user to run `/detect-data-stack` first and stop.

---

## Stage Definitions

### Stage 1 — DISCOVERY
Spawn the `data-engineer` agent.

Agent prompt:
```
You are the data-engineer agent conducting discovery for a new data model.

Entity / domain: {{ENTITY}}
Warehouse: {{WAREHOUSE}}
Transformation tool: {{TRANSFORMATION_TOOL}}
BI tool (downstream consumer): {{BI_TOOL}}

Scan the existing codebase for any related data artifacts:
- Search for tables, models, or files that mention "{{ENTITY}}" in their name or content
- Read any dbt models, SQL files, or schema definitions that are related
- Read any existing ERDs or data dictionary documents if present

Then produce a complete discovery document covering all of the following:

1. SOURCE SYSTEMS
   For each source system or raw table that contains data about {{ENTITY}}:
   - System name and type (e.g. PostgreSQL production DB, Stripe API, S3 event logs)
   - Table/endpoint name
   - Approximate row count and daily volume
   - Refresh mechanism (CDC, batch extract, streaming, webhook)
   - Known data quality issues

2. BUSINESS QUESTIONS THIS MODEL MUST ANSWER
   List 8-12 specific analytical questions the model must support. Be concrete:
   - "What is the total revenue per customer per month?"
   - "What is the conversion rate from trial to paid subscription?"
   Frame each as an actual business stakeholder question.

3. GRAIN DEFINITION
   State explicitly: "One row in this model represents ONE [X] at [Y] granularity."
   If multiple grains are needed (e.g. order header vs order line item), identify each.
   Misdefining grain is the single most common data modeling mistake — be precise.

4. UPDATE PATTERN
   Choose the correct strategy with justification:
   - Append-only: new events only, never update existing rows (event streams)
   - SCD Type 1 (overwrite): current state only, history discarded (config tables)
   - SCD Type 2 (history rows): full history, valid_from/valid_to, surrogate key (customer attributes)
   - Snapshot: dbt snapshot, periodic capture of slowly changing state
   State WHY this pattern is correct for this entity.

5. CARDINALITY AND GROWTH
   - Current expected row count at launch
   - Monthly growth rate (rows/month)
   - Partition strategy implication (daily? monthly?)
   - Storage estimate (rough)

6. CONSUMERS
   List every consumer of this model:
   - BI dashboards (which {{BI_TOOL}} dashboards or reports)
   - Downstream dbt models that will ref() this model
   - ML feature pipelines
   - Operational teams / business stakeholders
   For each consumer note their freshness requirement.

7. SLO — FRESHNESS REQUIREMENT
   What is the maximum acceptable data staleness?
   - Real-time (< 5 min): requires streaming ingestion
   - Near-real-time (< 1 hour): requires frequent incremental runs
   - Daily (< 24 hours): standard batch pipeline
   - Weekly: low-frequency snapshot
   Who to alert when SLO is breached?

8. KNOWN RISKS AND EDGE CASES
   - Duplicate source records? How identified?
   - Late-arriving data (events that arrive days after they occurred)?
   - Historical backfill needed? How far back?
   - Multi-currency, multi-timezone concerns?
   - PII columns present?

Output the discovery document clearly with each section labeled.
```
Tools: Read, Grep, Glob

Gate: Print the discovery document. Ask "Discovery complete. Proceed to SCHEMA DESIGN? [y/N]"

---

### Stage 2 — SCHEMA DESIGN
Spawn the `data-engineer` agent.

Agent prompt:
```
You are the data-engineer agent designing the complete data model schema.

Entity: {{ENTITY}}
Warehouse: {{WAREHOUSE}}
Transformation tool: {{TRANSFORMATION_TOOL}}

Discovery document from Stage 1:
{{DISCOVERY_OUTPUT}}

Design the complete multi-layer data model. Cover every section below.

---
SECTION A: STAGING LAYER (stg_{{entity}}.sql)
---
Staging models must contain ONLY:
- Source-to-staging column mapping (document each rename)
- Type casting (every column explicitly cast — no implicit types)
- Deduplication logic (if source has duplicates, use ROW_NUMBER with documented tie-breaking rule)
- NULL normalization (NULLIF('', NULL), COALESCE where appropriate)
- NO business logic, NO joins, NO aggregations

Present as a mapping table:
| Raw column name | Staged column name | Cast type | Notes |
|---|---|---|---|

---
SECTION B: CORE MODEL (fct_{{entity}}.sql or dim_{{entity}}.sql)
---
Decide fct_ vs dim_:
- fct_: grain is an event or transaction (orders, page views, payments, sessions)
- dim_: grain is an entity (customers, products, locations, campaigns)

Final schema — every column:
| Column name | Data type | Nullable | PII | Description | Test(s) |
|---|---|---|---|---|---|

Primary key: which column(s) form the unique identifier?
Surrogate key: if natural key is complex, define a surrogate (dbt_utils.generate_surrogate_key)
Foreign keys: which columns reference other models? (name the parent model)

Business logic transformations — for each non-trivial derived column:
  Transformation: <derived column> = <formula / CASE statement>
  Reason: <why this calculation exists>

---
SECTION C: SCD TYPE 2 DESIGN (if applicable based on Stage 1)
---
If the update pattern from discovery is SCD Type 2, define:
- dbt snapshot strategy: timestamp or check
- check_cols: list of columns to monitor for changes
- unique_key: natural key of the entity
- valid_from / valid_to column names
- is_current boolean flag (CASE WHEN valid_to IS NULL THEN TRUE ELSE FALSE)
- Surrogate key derivation (natural_key + valid_from)

---
SECTION D: ERD (ASCII TEXT)
---
Draw the entity relationships for this domain:

  dim_users ─────────────────< fct_orders >──────────── dim_products
                                    │
                                    └───────────────── dim_promotions

Use ─────< for one-to-many (many on the "crow's foot" side).
Label each relationship line with the JOIN key column name.

---
SECTION E: MATERIALISATION DECISION
---
For each model, choose and justify:
  view        → ≤ 1M rows, freshness critical, cheap to compute
  table       → > 1M rows, expensive joins, many downstream reads, full refresh OK
  incremental → > 10M rows, append/merge pattern, daily batches, partition required
  ephemeral   → single downstream consumer, no direct queries, small

For incremental models, define:
  unique_key: <column(s)>
  watermark column: <column used to detect new/changed rows>
  merge strategy: append | merge | delete+insert | insert_overwrite

---
SECTION F: PARTITION AND CLUSTER KEYS
---
For {{WAREHOUSE}}, define:
  Partition column: <date column> — reasoning
  Cluster/sort columns: <columns frequently used in WHERE / JOIN> — reasoning
  Estimated partition size: <rows per partition>
  Expected number of partitions: <count>

Output each section labeled clearly. This document is the complete spec that
the implementation agent will build from — leave nothing ambiguous.
```
Tools: Read, Grep, Glob

Gate: Print the schema design. Ask "Schema design looks correct? Proceed to IMPLEMENTATION? [y/N]"

---

### Stage 3 — IMPLEMENTATION
Spawn the `data-engineer` agent.

Agent prompt:
```
You are the data-engineer agent implementing the complete dbt data model.

Entity: {{ENTITY}}
Warehouse: {{WAREHOUSE}}
dbt version: {{DBT_VERSION}}
dbt project: {{DBT_PROJECT_NAME}}

Schema design from Stage 2:
{{SCHEMA_OUTPUT}}

Write ALL of the following files completely. No pseudocode, no TODOs, no stubs.
Every file must be production-ready.

---
FILE 1: models/staging/stg_{{entity}}.sql
---
- Use source() references for every raw table
- Cast every column explicitly
- Apply deduplication if required (ROW_NUMBER + QUALIFY or subquery)
- Add a header comment documenting: source, grain, update pattern, owner
- Use dbt_utils.star() only if column list is documented in a comment
- Follow SQL style: UPPERCASE keywords, 4-space indent, 100-char line limit

---
FILE 2: models/staging/stg_{{entity}}.yml
---
Complete YAML:
  version: 2
  models:
    - name: stg_{{entity}}
      description: "..."
      columns:
        - name: <every column>
          description: "..."
          tests: [not_null]  (for all required columns)
  sources:
    - name: <source>
      freshness:
        warn_after: {count: 12, period: hour}
        error_after: {count: 24, period: hour}
      loaded_at_field: _loaded_at
      tables:
        - name: <table>

---
FILE 3: models/<layer>/fct_{{entity}}.sql or dim_{{entity}}.sql
---
- Use ref() references for all upstream models — never hardcode schema names
- Write every transformation with an inline comment explaining the business rule
- If incremental: include {{ config(materialized='incremental', ...) }} block
  and {% if is_incremental() %} ... {% endif %} filter block
- Add a header comment: grain definition, owner, SLO, created date

---
FILE 4: models/<layer>/fct_{{entity}}.yml or dim_{{entity}}.yml
---
Complete YAML with:
  - Model description (grain statement in first sentence)
  - All columns with descriptions
  - not_null + unique on primary key
  - relationships tests on all foreign keys
  - accepted_values on all status/enum columns (list the values)
  - dbt-expectations expression tests on numeric columns where applicable

---
FILE 5: snapshots/{{entity}}_snapshot.sql (only if SCD Type 2)
---
{% snapshot {{entity}}_snapshot %}
  {{ config(
      target_schema='snapshots',
      unique_key='<natural_key>',
      strategy='<timestamp|check>',
      updated_at='<updated_at_column>',       -- if timestamp strategy
      check_cols=['<col1>', '<col2>'],          -- if check strategy
  ) }}
  SELECT * FROM {{ source('<source>', '<table>') }}
{% endsnapshot %}

---
FILE 6: tests/assert_{{entity}}_no_duplicate_keys.sql
---
Returns rows with duplicate primary keys (must return 0 rows to pass):
SELECT <pk_column>, COUNT(*) as cnt
FROM {{ ref('<model_name>') }}
GROUP BY <pk_column>
HAVING COUNT(*) > 1

Write at least 2 additional singular tests for business rules from the schema design.

After writing all files, list them:
Files written:
- models/staging/stg_{{entity}}.sql
- models/staging/stg_{{entity}}.yml
- models/<layer>/<model>.sql
- models/<layer>/<model>.yml
- (snapshots/{{entity}}_snapshot.sql if applicable)
- tests/assert_{{entity}}_*.sql (N files)
```
Tools: Read, Write, Glob

Gate: Print list of files created. Ask "Implementation complete. Proceed to DOCUMENTATION? [y/N]"

---

### Stage 4 — DOCUMENTATION
Spawn the `data-engineer` agent.

Agent prompt:
```
You are the data-engineer agent writing data asset documentation.

Entity: {{ENTITY}}
Docs platform: {{DOCS_PLATFORM}}
Ticket system: {{TICKET_SYSTEM}}
BI tool: {{BI_TOOL}}

Discovery from Stage 1: {{DISCOVERY_OUTPUT}}
Schema design from Stage 2: {{SCHEMA_OUTPUT}}

Produce all documentation formatted for {{DOCS_PLATFORM}}.

---
1. DATA DICTIONARY
---
A complete column-level reference table for every model created:

## <Model name>
Description: <one sentence>
Grain: one row represents ONE <X>
Owner: <team / person>
Freshness SLO: data must be < <N> hours old

| Column | Type | Required | PII | Description | Example value |
|--------|------|----------|-----|-------------|---------------|
<one row per column>

---
2. LINEAGE DESCRIPTION
---
Describe the full data flow in plain language:

  [Source system: <name>]
      ↓ (via <ingestion method>)
  [Raw: <raw_schema.table_name>]
      ↓ (stg_{{entity}}.sql — cleaning + type casting)
  [Staging: stg_{{entity}}]
      ↓ (<model>.sql — business logic transformations)
  [Core: <fct/dim model>]
      ↓ (queried by)
  [<{{BI_TOOL}} dashboard / downstream models>]

List any branching in the lineage (one staging model feeding multiple core models).

---
3. USAGE GUIDE
---
How to use this model correctly:

Common query patterns:
  -- [Description of what this query answers]
  SELECT ...
  FROM <model>
  WHERE ...

  -- [Second common pattern]
  SELECT ...

What NOT to do:
  - Do not JOIN directly to the raw source table — always use stg_ or fct_/dim_ models
  - Do not filter on <column> without also filtering on <partition_column> (full scan risk)
  - <any other model-specific gotchas>

Freshness: this model is rebuilt <schedule>. Data is stale if >  <N> hours old.
Backfill command: dbt run --select <model> --full-refresh

---
4. OWNER AND SLO BLOCK
---
| Property | Value |
|---|---|
| Owner | <team> |
| Oncall | <rotation or contact> |
| Freshness SLO | Data < <N> hours old |
| Row count range | <min> – <max> rows expected |
| Quality check | dbt test --select <model> |
| Alert channel | <slack channel / pagerduty> |
| Review cadence | Quarterly schema review |

---
5. TICKET CREATION INSTRUCTIONS
---
Create one ticket per model in {{TICKET_SYSTEM}}:

  Ticket 1: "Data Model: stg_{{entity}} — staging layer"
    Type: Story | Priority: P1 | Component: Data / dbt
    Acceptance criteria: model passes dbt test, freshness SLO documented

  Ticket 2: "Data Model: <fct/dim model> — core layer"
    Type: Story | Priority: P1 | Component: Data / dbt
    Acceptance criteria: model passes all schema tests, data dictionary merged to docs

  Ticket 3 (if snapshot): "Snapshot: {{entity}}_snapshot — SCD Type 2 history"
    Type: Story | Priority: P2

  Ticket 4: "Data quality: {{entity}} — singular tests and freshness checks"
    Type: Task | Priority: P1
```
Tools: Read, Write

---

## Data Model Summary Report

After all stages complete, print:

```
════════════════════════════════════════════════════════
  Data Model — {{ENTITY}}
  Warehouse: {{WAREHOUSE}}  |  Tool: {{TRANSFORMATION_TOOL}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — DISCOVERY      Sources: N, Consumers: N, SLO: <freshness>
  [✓] Stage 2 — SCHEMA         Grain: <one row = ...>, Pattern: <SCD1/SCD2/append>
  [✓] Stage 3 — IMPLEMENTATION Files created: N, Tests written: N
  [✓] Stage 4 — DOCUMENTATION  Docs ready for {{DOCS_PLATFORM}}, Tickets: N
════════════════════════════════════════════════════════

Models created:
  - stg_{{entity}}         (staging — cleaning + type casting)
  - <fct/dim model>        (core — business logic)
  - <snapshot model>       (if SCD Type 2)

Validate with:
  dbt run --select stg_{{entity}}+ && dbt test --select stg_{{entity}}+
```

---

## Variables

- `{{ENTITY}}` = argument passed to this command
- `{{DISCOVERY_OUTPUT}}` = Stage 1 output (first 3000 chars) injected into Stage 2 + Stage 4
- `{{SCHEMA_OUTPUT}}` = Stage 2 output (first 3000 chars) injected into Stage 3 + Stage 4
- `{{WAREHOUSE}}`, `{{TRANSFORMATION_TOOL}}`, `{{DBT_VERSION}}`, `{{DBT_PROJECT_NAME}}`, `{{BI_TOOL}}` = from data.config.md
- `{{TICKET_SYSTEM}}`, `{{DOCS_PLATFORM}}` = from workflow.config.md
