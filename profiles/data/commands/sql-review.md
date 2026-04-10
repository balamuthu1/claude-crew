Review SQL queries or dbt models for correctness, performance, style, and test coverage. Argument is a file path, glob pattern, or dbt model name.

You are the **orchestrator**. Do NOT review any SQL yourself — spawn dedicated sub-agents for each stage using the `Agent` tool. Each sub-agent gets an isolated context window focused on its domain.

**For stages 1 and 2: run sequentially (Stage 2 depends on Stage 1 output). Stage 3 can begin after Stage 2.**

---

## Before starting

Read `data.config.md` and `workflow.config.md`. Extract:
- `{{WAREHOUSE}}` — target data warehouse (bigquery, snowflake, redshift, databricks, postgres)
- `{{TRANSFORMATION_TOOL}}` — dbt, spark, pandas, raw SQL
- `{{DBT_VERSION}}` — dbt version if applicable (e.g. 1.7.0)
- `{{DBT_PROJECT_NAME}}` — dbt project name from dbt_project.yml
- `{{TICKET_SYSTEM}}` — from workflow.config.md (jira, linear, github, etc.)
- `{{DOCS_PLATFORM}}` — from workflow.config.md

Set `{{FILES}}` = the argument passed to this command.

If `data.config.md` does not exist, tell the user to run `/detect-data-stack` first and stop.

---

## Stage Definitions

### Stage 1 — SQL QUALITY REVIEW
Spawn the `sql-specialist` agent.

Agent prompt:
```
You are the sql-specialist agent conducting a thorough SQL and dbt model quality review.

Files to review: {{FILES}}
Warehouse: {{WAREHOUSE}}
Transformation tool: {{TRANSFORMATION_TOOL}}
dbt version: {{DBT_VERSION}}

Read each file completely before forming any finding. Apply rules from
profiles/data/rules/sql-standards.md.

Review for ALL of the following:

---
CORRECTNESS
---
- [ ] JOINs use the correct keys — no accidental cross-join (missing ON clause)
- [ ] JOIN type is appropriate for the use case:
      INNER JOIN only when both sides must have a match
      LEFT JOIN when the left side must be preserved even without a match
      FULL OUTER JOIN documented with explicit reason
- [ ] Many-to-many JOINs: fan-out risk detected? Flag any JOIN that could multiply rows
      unexpectedly. Require explicit DISTINCT or aggregation as guard.
- [ ] Aggregation grain: every non-aggregated column appears in GROUP BY
- [ ] Window functions: PARTITION BY and ORDER BY are correct for the intended calculation.
      Verify frame clause (ROWS BETWEEN / RANGE BETWEEN) is intentional.
- [ ] NULL handling in JOIN keys: NULLs never equal NULLs in JOIN conditions — flag any
      JOIN on a nullable key without explicit NULL handling
- [ ] NULL handling in aggregations: SUM/AVG/COUNT behave differently on NULLs —
      document where COALESCE or NULLIF is needed
- [ ] NULL handling in comparisons: `col != 'value'` silently excludes NULLs —
      flag unless IS NOT NULL guard is present
- [ ] Date arithmetic: is timezone handling explicit? No implicit CAST to a different TZ?
      Flag any CURRENT_DATE / NOW() used without TZ conversion in {{WAREHOUSE}}
- [ ] String comparisons: is case sensitivity handled? UPPER/LOWER applied consistently?
      Flag any comparison without normalization that could miss rows
- [ ] Deduplication: when ROW_NUMBER / QUALIFY is used for deduplication, verify the
      PARTITION BY and ORDER BY correctly select the intended "winner" row
- [ ] Incremental logic (dbt): is the watermark column the right one? Is the filter
      `>` or `>=`? Could records in the watermark window be missed?

---
PERFORMANCE — {{WAREHOUSE}}-SPECIFIC
---
For BigQuery:
- [ ] Partition filter present on partitioned tables — no full table scans
- [ ] Clustering key alignment: filter columns match cluster key order
- [ ] CROSS JOIN with UNNEST used correctly (not accidentally generating a cross join)
- [ ] Approximate aggregation functions (APPROX_COUNT_DISTINCT) used where exact count
      not required

For Snowflake:
- [ ] Micro-partition pruning: filters on cluster key columns placed early
- [ ] No cartesian products (CROSS JOIN without WHERE clause)
- [ ] QUALIFY used instead of outer ROW_NUMBER subquery where possible
- [ ] COPY INTO and INSERT patterns reviewed for warehouse size appropriateness

For Redshift:
- [ ] Distribution key matches the JOIN key (prevents data redistribution)
- [ ] DISTKEY and SORTKEY alignment reviewed for each large table reference
- [ ] No broadcast joins on tables > 1M rows (DISTSTYLE ALL only for small dims)
- [ ] VACUUM and ANALYZE recommended where stale statistics likely

For Databricks / Spark:
- [ ] Broadcast hints (/*+ BROADCAST(t) */) on small lookup tables (< 100MB)
- [ ] Z-ORDER clustering column alignment with filter predicates
- [ ] Shuffle partition count commented when explicitly set
- [ ] No multiple passes through the same large RDD/DataFrame (cache() if reused)

All warehouses:
- [ ] No SELECT * in any production model — explicit column list required
- [ ] Filtering happens before aggregation (WHERE before GROUP BY, not HAVING for base filters)
- [ ] CTEs used instead of nested subqueries for readability and optimizer hints
- [ ] No N+1 patterns: no subquery in SELECT clause that executes per row
- [ ] Large tables filtered early — no unnecessary full scan of a large table as a build side
- [ ] DISTINCT used only when duplicates are genuinely expected, not as a "just in case" fix

---
STYLE AND MAINTAINABILITY
---
- [ ] CTEs named descriptively (not cte1, cte2, tmp, final_final)
- [ ] Complex business logic explained in inline comments
- [ ] Column aliases use snake_case consistently
- [ ] No magic numbers — use dbt variables (var('discount_threshold')) or named CTEs
- [ ] Lines ≤ 100 characters (longer lines wrapped)
- [ ] SQL keywords UPPERCASE (SELECT, FROM, WHERE, JOIN, GROUP BY, ORDER BY, HAVING, WITH)
- [ ] Consistent 4-space indentation throughout
- [ ] No trailing whitespace, no inconsistent blank lines between CTEs

---
DBT-SPECIFIC (if {{TRANSFORMATION_TOOL}} is dbt)
---
- [ ] Model in correct layer:
      stg_  = source cleaning only, one model per source table, no joins
      int_  = joins between staging / intermediate models, no raw source refs
      fct_  = fact tables (events, transactions), grain defined in model header comment
      dim_  = dimension tables (entities), surrogate key pattern consistent
- [ ] ref() used for ALL model-to-model references — no hardcoded schema.table
- [ ] source() used for ALL raw source table references — no hardcoded raw.table
- [ ] YAML schema file exists alongside every model (or in a shared schema.yml in same dir)
- [ ] not_null + unique tests present on every primary key column
- [ ] accepted_values tests present on every status/type/enum column
- [ ] relationships tests present for every foreign key column
- [ ] Materialisation choice commented with justification:
      view: small, freshness needed, cheap reads
      table: large, full refresh OK, many downstream reads
      incremental: large, append/merge pattern, partitioned
      ephemeral: single downstream consumer, no direct query needed
- [ ] Incremental model has unique_key set and is_incremental() block correct
- [ ] Incremental full-refresh fallback is safe (no data loss on full refresh)
- [ ] dbt_utils or dbt-expectations packages used appropriately for complex tests
- [ ] No Jinja logic that would break if a variable is undefined (default() used)

---
OUTPUT FORMAT
---
## SQL Quality Review — {{FILES}}

### Critical (incorrect results or data loss risk)
- [FILE:LINE] Issue description — Business impact — Exact fix required

### Major (performance issue or missing test coverage on key column)
- [FILE:LINE] Issue description — Estimated impact — Recommended fix

### Minor (style, naming, maintainability)
- [FILE:LINE] Suggestion — Reason

### Approved patterns
- [FILE:LINE] Good practice worth noting for the team

Write a file:line reference for every single finding. No vague findings.
```
Tools: Read, Grep, Glob

Gate: Print the full review output. Ask "SQL quality review complete. Proceed to QUERY PLAN ANALYSIS? [y/N]"

---

### Stage 2 — QUERY PLAN ANALYSIS
Spawn the `sql-specialist` agent.

Agent prompt:
```
You are the sql-specialist agent performing static query plan analysis.

Files reviewed: {{FILES}}
Warehouse: {{WAREHOUSE}}

Quality review from Stage 1:
{{REVIEW_OUTPUT}}

Perform STATIC analysis only — do not attempt to run any query.
Infer likely execution behavior from the query structure.

For each SQL model or query in {{FILES}}, analyze:

1. ESTIMATED SCAN SIZE
   - Does every reference to a large table have a filter on the partition/cluster key?
   - If no partition filter is present, flag as "likely full scan — cost risk"
   - Identify tables referenced without any WHERE predicate

2. JOIN ORDER ANALYSIS
   - Identify the largest table in each JOIN chain (by naming convention or comments)
   - Is the largest table on the probe side (right side) rather than build side (left side)?
   - Flag any sequence where a large unfiltered table is joined first, inflating intermediate
     result size before filters are applied

3. CORRELATED SUBQUERIES
   - Identify any subquery in the SELECT or WHERE clause that references a column from
     an outer query (executes once per row — O(n) rather than O(1))
   - Rewrite as a JOIN or window function

4. WINDOW FUNCTION STACKING
   - Identify models with 3+ window functions over the same partition
   - Can they be merged into fewer passes using conditional aggregation?
   - Show the merged version

5. AGGREGATION PUSHDOWN OPPORTUNITIES
   - Can a large table be pre-aggregated in a CTE before joining?
   - Identify any JOIN where one side could be reduced significantly by
     grouping before the join rather than after

6. RECOMMENDED EXPLAIN ANALYZE
   List the 2-3 most important queries the team should run EXPLAIN ANALYZE on manually:
   ```sql
   -- Run this to validate partition pruning on orders:
   EXPLAIN ANALYZE SELECT ...
   ```

7. REWRITTEN QUERY
   For each model with a Major or Critical performance finding:
   - Show a diff of the original vs optimized version
   - Annotate each change with a one-line comment explaining the optimization

Output format:
## Query Plan Analysis — {{FILES}}

### Scan risk (full table scans or missing partition filters)
### Join order issues
### Correlated subqueries
### Window function optimization opportunities
### Aggregation pushdown opportunities
### Recommended EXPLAIN ANALYZE commands
### Rewritten queries (diff format)
```
Tools: Read

Gate: Ask "Optimization analysis complete. Proceed to DBT TEST COVERAGE? [y/N]"

---

### Stage 3 — DBT TEST COVERAGE
Spawn the `data-engineer` agent.

Agent prompt:
```
You are the data-engineer agent writing comprehensive dbt test coverage.

Models reviewed: {{FILES}}
dbt version: {{DBT_VERSION}}
Warehouse: {{WAREHOUSE}}

Quality review: {{REVIEW_OUTPUT}}

For every dbt model in scope, produce a complete YAML schema test block.
If a schema.yml file already exists for a model, read it first and EXTEND it
rather than replace it. Write only what is missing.

For each model, write:

1. MODEL-LEVEL TESTS
   ```yaml
   models:
     - name: <model_name>
       description: "<clear description of what this model represents, one row = ...>"
       config:
         tags: ["<layer>"]
   ```

2. COLUMN-LEVEL TESTS — apply the following rules:
   - Primary key columns: not_null + unique (both required, no exceptions)
   - Foreign key columns: relationships test to the parent model
   - Status / type / enum columns: accepted_values with an explicit list of values
     (infer values from WHERE clauses, CASE statements, or column names in the SQL)
   - Date columns: dbt-expectations date range test if dbt-expectations is available,
     otherwise a singular test
   - Amount / numeric columns: dbt-expectations expression test (value >= 0) where
     business rules imply non-negative
   - Boolean columns: accepted_values: [true, false] (catches NULL surprises)

3. SOURCE FRESHNESS (for staging models using source()):
   ```yaml
   sources:
     - name: <source_name>
       freshness:
         warn_after: {count: 12, period: hour}
         error_after: {count: 24, period: hour}
       loaded_at_field: _loaded_at
   ```

4. CUSTOM SINGULAR TESTS
   Write a SQL file in tests/ for any business rule not expressible as a schema test:
   - `tests/assert_<model>_amount_is_positive.sql` — returns rows that violate the rule
   - `tests/assert_<model>_end_date_after_start_date.sql`
   - `tests/assert_<model>_no_orphaned_<fk>.sql` — custom referential integrity
   Each singular test must return 0 rows to pass.

Write ALL YAML blocks completely — do not truncate or add TODO comments.
Write each singular test as a complete SQL file.
```
Tools: Read, Write, Glob

---

## SQL Review Summary Report

After all stages complete, print:

```
════════════════════════════════════════════════════════
  SQL Review — {{FILES}}
  Warehouse: {{WAREHOUSE}}  |  Tool: {{TRANSFORMATION_TOOL}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — SQL QUALITY       Critical: N, Major: N, Minor: N
  [✓] Stage 2 — QUERY PLAN        Full-scan risks: N, Rewrites: N
  [✓] Stage 3 — TEST COVERAGE     Tests added: N, Singular tests: N
════════════════════════════════════════════════════════

Critical findings requiring immediate action:
  - [FILE:LINE] <summary>
  ...

Tickets to create in {{TICKET_SYSTEM}}:
  For each Critical finding:
  "Create Bug: [summary] | Priority: P0 | Component: Data / SQL"
  For each Major finding:
  "Create Task: [summary] | Priority: P1 | Component: Data / SQL"
```

---

## Variables

- `{{FILES}}` = argument passed to this command (file path, glob, or dbt model name)
- `{{REVIEW_OUTPUT}}` = Stage 1 output (first 3000 chars) injected into Stage 2 prompt
- `{{WAREHOUSE}}`, `{{TRANSFORMATION_TOOL}}`, `{{DBT_VERSION}}`, `{{DBT_PROJECT_NAME}}` = from data.config.md
- `{{TICKET_SYSTEM}}`, `{{DOCS_PLATFORM}}` = from workflow.config.md
