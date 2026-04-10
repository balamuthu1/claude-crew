# Data Engineering Standards

These rules apply to all data pipeline and ML infrastructure development.

## Pipeline design principles

1. **Idempotent by default** — re-running a pipeline must produce identical results; no append-only without deduplication
2. **Incremental over full reload** — scan only new/changed data using watermarks
3. **Explicit over implicit** — column selection, type coercions, null handling must be deliberate
4. **Observable** — every pipeline emits: records processed, records failed, processing duration, data freshness
5. **Testable** — pipeline logic must be testable in isolation with sample data

## Data quality checks

Every pipeline boundary must validate:
- Row count is within expected range (not zero, not anomalously large)
- Primary keys are unique and non-null
- Foreign keys exist in referenced tables
- Dates are within plausible range
- Categorical fields have expected values
- Numeric fields are within expected statistical range (flag outliers, don't reject)

## Incremental load pattern

```python
# Standard watermark pattern
last_processed = get_watermark(pipeline_name)
new_records = source.query(f"WHERE updated_at > {last_processed}")
process(new_records)
save_watermark(pipeline_name, max(new_records.updated_at))
```

Watermarks must be stored durably (database, not memory). Handle clock skew with a small overlap window.

## Error handling

- **Dead letter queue**: failed records go to a separate store for investigation — never silently dropped
- **Partial failure**: pipeline fails loud on unexpected errors; skips and logs on expected data quality issues
- **Alerting**: pipeline failures page on-call; data freshness breaches alert within SLA

## Schema evolution

- **Additive changes** (new columns): pipelines must handle gracefully — ignore unknown columns or apply defaults
- **Removals**: deprecated columns must remain available for one release cycle before removal
- **Type changes**: treat as breaking — require explicit migration

## Data freshness SLOs

| Pipeline type | Freshness target |
|---------------|-----------------|
| Real-time (streaming) | < 5 minutes |
| Near real-time (micro-batch) | < 30 minutes |
| Hourly batch | < 90 minutes |
| Daily batch | Available by 06:00 UTC next day |

Define freshness SLOs in `data.config.md` for each pipeline.

## dbt project conventions

```
models/
  staging/          # stg_<source>__<entity>.sql
  intermediate/     # int_<description>.sql
  marts/
    core/           # dim_*, fct_* for shared metrics
    <team>/         # team-specific marts

tests/              # custom singular tests
macros/             # reusable SQL logic
seeds/              # static reference data only
```

## Secrets and credentials

- All database connections via environment variables or secrets manager
- dbt profiles (`~/.dbt/profiles.yml`) must never be committed
- GCP service account JSON must never be committed
- Airflow connections stored in Airflow's encrypted connection store — not in DAG files
