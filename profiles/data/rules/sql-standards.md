# SQL Standards

These rules apply to all SQL written for data pipelines, analytics, and application queries.

## Style

### Formatting
```sql
-- Correct: uppercase keywords, lowercase identifiers, CTE-first
WITH
  active_users AS (
    SELECT
      u.id,
      u.email,
      u.created_at
    FROM users AS u
    WHERE u.deleted_at IS NULL
  ),
  user_orders AS (
    SELECT
      o.user_id,
      COUNT(*) AS order_count,
      SUM(o.total_amount) AS lifetime_value
    FROM orders AS o
    WHERE o.status = 'completed'
    GROUP BY o.user_id
  )
SELECT
  au.id,
  au.email,
  COALESCE(uo.order_count, 0) AS order_count,
  COALESCE(uo.lifetime_value, 0) AS lifetime_value
FROM active_users AS au
LEFT JOIN user_orders AS uo
  ON au.id = uo.user_id
ORDER BY uo.lifetime_value DESC NULLS LAST
```

### Rules
- **UPPERCASE** SQL keywords: `SELECT`, `FROM`, `WHERE`, `JOIN`, `GROUP BY`
- **lowercase** identifiers: table names, column names, alias names
- Always alias tables, always qualify column references in multi-table queries
- CTEs over nested subqueries for anything more than one level deep
- One column per line in `SELECT`
- Explicit `JOIN` type: `INNER JOIN`, `LEFT JOIN` — never implicit comma join
- `COALESCE` for null handling — make nulls explicit, not accidental

## Query quality rules

### Always
- Explicit column list — never `SELECT *` in production code
- `LIMIT` on all exploratory and list queries
- Qualify every column with table alias in multi-table queries
- Use parameterised queries — never string concatenation

### Never
- `SELECT DISTINCT` as a quick fix — understand and fix the root cause of duplicates
- `NOT IN` with a subquery — use `NOT EXISTS` or `LEFT JOIN ... IS NULL` (handles NULLs correctly)
- Functions on indexed columns in `WHERE` clauses: `WHERE YEAR(created_at) = 2024` (use `WHERE created_at >= '2024-01-01'` instead)
- Subqueries in `SELECT` list for per-row lookup — use JOIN
- `HAVING` to filter what `WHERE` could filter

## dbt-specific standards

- Staging models: rename and cast only — no business logic
- Intermediate models: single clear transformation purpose
- Mart/fact/dim models: business-ready, fully documented
- Every model has a YAML schema with at minimum:
  - `not_null` tests on primary keys
  - `unique` tests on primary keys
  - `accepted_values` on status/enum columns
- Source freshness tests defined for upstream tables
- Model names reflect grain: `fct_orders` (one row per order), `fct_order_items` (one row per item)

## Performance

### PostgreSQL
- `EXPLAIN ANALYZE` before deploying queries on tables >100k rows
- `CREATE INDEX CONCURRENTLY` for large tables
- Partial indices for large tables with frequent filtered queries
- `VACUUM ANALYZE` after large deletes/updates

### BigQuery / Snowflake / Redshift
- Partition and cluster on the columns most commonly used in `WHERE`
- Avoid `SELECT *` — reads all columns, all partitions
- Use `APPROX_COUNT_DISTINCT` for large cardinality estimates
- `INFORMATION_SCHEMA` for query cost estimation before running
