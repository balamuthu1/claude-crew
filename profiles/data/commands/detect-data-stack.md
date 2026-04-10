---
description: Interactive setup for the data profile. Detects or asks about warehouse, transformation tool, orchestrator, BI tool, and workflow preferences. Writes data.config.md.
---

Run directly — do not spawn a sub-agent.

## Step 1 — Check prerequisites

Read `workflow.config.md`. If it doesn't exist, say:
```
⚠  workflow.config.md not found.
Run /detect-workflow first to set your ticket system and docs platform.
Continuing — you can run /detect-workflow afterwards.
```

Read `data.config.md` if it exists and ask to update if found.

---

## Step 2 — Auto-detect from project files

Scan for data tooling clues:

| File | Clues |
|------|-------|
| `dbt_project.yml` | dbt, read profile name, model paths |
| `profiles.yml` / `~/.dbt/profiles.yml` | warehouse type (bigquery, snowflake, redshift, postgres) |
| `airflow.cfg` / `dags/*.py` | Airflow orchestration |
| `prefect.yaml` / `flows/*.py` | Prefect |
| `dagster.yaml` | Dagster |
| `pyproject.toml` / `requirements.txt` | Python packages (pyspark, pandas, polars, great-expectations, mlflow) |
| `*.tf` (Terraform) | Cloud provider clues |

Show detected values:
```
Detected:
  Transformation : dbt (dbt_project.yml found)
  Warehouse      : BigQuery (from dbt profiles.yml)
  Orchestrator   : Airflow (dags/ directory found)
```

Ask: "Is this correct? [Y/n]"

---

## Step 3 — Data warehouse

Ask (or confirm if detected):
```
Which data warehouse / analytical database does your team use?

  1) Google BigQuery
  2) Snowflake
  3) Amazon Redshift
  4) Databricks (Delta Lake)
  5) DuckDB
  6) PostgreSQL (as analytical store)
  7) ClickHouse
  8) Azure Synapse
  9) Apache Hive / Spark
  10) Other

Enter number:
```

Follow-up based on choice:

For BigQuery (1):
```
  GCP project ID:
  Default dataset for analytics (e.g. analytics_prod):
```

For Snowflake (2):
```
  Snowflake account identifier:
  Default database and schema (e.g. ANALYTICS.PUBLIC):
```

For Redshift (3):
```
  Cluster endpoint:
  Default schema:
```

For Databricks (4):
```
  Workspace URL:
  Default catalog and schema (Unity Catalog):
```

---

## Step 4 — Transformation tool

Ask (or confirm if detected):
```
How does your team transform data?

  1) dbt (SQL-first transformations)
  2) Apache Spark (PySpark / Scala)
  3) Pandas / Polars (Python)
  4) dbt + Spark (hybrid)
  5) Custom SQL scripts
  6) No transformation layer (raw queries only)

Enter number:
```

For dbt (choice 1 or 4):
```
  dbt project name (from dbt_project.yml):
  dbt version:
  dbt target for dev:
  dbt target for prod:
  Model directory path (e.g. models/):

  Staging model prefix (e.g. stg_):
  Intermediate model prefix (e.g. int_):
  Fact model prefix (e.g. fct_):
  Dim model prefix (e.g. dim_):

  Do you use dbt packages? (dbt-utils, dbt-expectations, etc.) [y/N]
  Do you use dbt Semantic Layer / MetricFlow? [y/N]
```

For Spark:
```
  Spark mode: yarn | kubernetes | local | emr | dataproc | databricks
  Primary language: python | scala
```

---

## Step 5 — Orchestration

Ask (or confirm if detected):
```
What orchestrates / schedules your pipelines?

  1) Apache Airflow
  2) Prefect
  3) Dagster
  4) dbt Cloud (hosted runs)
  5) Cron (server-side)
  6) GitHub Actions (scheduled workflows)
  7) AWS Glue / Step Functions
  8) GCP Workflows / Cloud Composer
  9) Azure Data Factory
  10) None / manual

Enter number:
```

For Airflow (1):
```
  Airflow URL (e.g. https://airflow.company.com):
  DAGs directory path (e.g. dags/):
  Airflow version:
```

For Prefect (2):
```
  Prefect Cloud workspace:
  Flows directory path:
```

---

## Step 6 — BI / Reporting tool

Ask:
```
Which BI tool does your team use for reporting and dashboards?

  1) Looker (LookML)
  2) Metabase
  3) Tableau
  4) Power BI
  5) Apache Superset
  6) Redash
  7) Mode Analytics
  8) Observable
  9) Multiple tools / embedded analytics
  10) None — direct SQL queries only

Enter number:
```

For Looker (1):
```
  Looker instance URL:
  LookML project/repo:
```

For Metabase (2):
```
  Metabase URL:
```

---

## Step 7 — Data quality

Ask:
```
How does your team validate data quality?

  1) dbt tests (built-in: not_null, unique, accepted_values, relationships)
  2) dbt Expectations (dbt-expectations package)
  3) Great Expectations
  4) Soda Core / Soda Cloud
  5) Monte Carlo (data observability)
  6) Bigeye
  7) Custom SQL assertions
  8) None

Enter number (or multiple separated by commas):
```

Ask:
```
What dbt tests do you apply by default to all models?
(Press Enter for default, or list your own)
Default: not_null, unique on primary keys; accepted_values on status fields
```

---

## Step 8 — ML platform (if applicable)

Ask:
```
Does your data team work on machine learning / AI projects? [y/N]
```

If yes:
```
ML framework:
  1) PyTorch
  2) TensorFlow / Keras
  3) scikit-learn
  4) XGBoost / LightGBM
  5) JAX
  6) Multiple / varies by project

Experiment tracking:
  1) MLflow
  2) Weights & Biases (wandb)
  3) Comet ML
  4) Neptune
  5) None

Model registry / serving:
  1) MLflow Model Registry
  2) Vertex AI Model Registry
  3) AWS SageMaker
  4) Azure ML
  5) Weights & Biases
  6) Custom

Feature store:
  1) Feast
  2) Tecton
  3) Vertex AI Feature Store
  4) SageMaker Feature Store
  5) None
```

---

## Step 9 — Data documentation

Ask:
```
Where does your team document data assets (tables, columns, metrics)?

  1) dbt docs (auto-generated from YAML)
  2) Atlan
  3) DataHub
  4) Alation
  5) Collibra
  6) Confluence / Notion / Google Docs
  7) No dedicated data catalog

Enter number:
```

---

## Step 10 — Ticket system for data work

Read `workflow.config.md`. Confirm or override for data-specific work:
```
Ticket system from workflow.config.md: <system>
Data engineers will create pipeline tickets and data model requests in <system>.
Is this correct? [Y/n]
```

If Jira, ask:
```
  Jira project key for data work (may differ from product/engineering):
  Issue type for pipeline tasks (e.g. Task, Story):
  Issue type for data model requests (e.g. Story, Data Request):
```

---

## Step 11 — Write data.config.md

Write `data.config.md` with all gathered values.

---

## Step 12 — Confirm

```
✓ data.config.md written.

Data Stack:
  Warehouse     : <warehouse>
  Transformation: <tool>
  Orchestration : <orchestrator>
  BI Tool       : <bi>
  Data Quality  : <tool>
  ML            : <framework or 'none'>

Next steps:
  /pipeline-review <file>    ← review an existing pipeline
  /sql-review <file>         ← review SQL / dbt models
  /data-model <entity>       ← design a new data model
```
