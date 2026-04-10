# Claude Crew — Data Config
# Run /detect-data-stack to auto-fill this file.
# All data agents read this before every task.

## Data Warehouse

warehouse: bigquery             # bigquery | snowflake | redshift | databricks | duckdb | postgresql | other
warehouse_project_or_account:   # GCP project, Snowflake account, Redshift cluster, etc.
warehouse_default_dataset:      # default schema/dataset/database for queries

## Transformation

transformation_tool: dbt        # dbt | spark | pandas | polars | custom-sql | none

# dbt (when transformation_tool: dbt)
dbt_project_name: analytics
dbt_profiles_dir: ~/.dbt/
dbt_target_dev: dev
dbt_target_prod: prod
dbt_model_path: models/

# dbt layer conventions
dbt_staging_prefix: stg_       # e.g. stg_stripe__payments
dbt_intermediate_prefix: int_
dbt_mart_fact_prefix: fct_
dbt_mart_dim_prefix: dim_

# Spark (when transformation_tool: spark)
# spark_master: yarn | k8s | local
# spark_language: python | scala

## Orchestration / Scheduling

orchestrator: airflow           # airflow | prefect | dagster | dbt-cloud | cron | github-actions | none

# Airflow
# airflow_url: https://airflow.example.com
# airflow_dag_path: dags/

# Prefect
# prefect_workspace: my-workspace
# prefect_project: analytics

## BI / Reporting

bi_tool: looker                 # looker | metabase | tableau | power-bi | superset | redash | mode | none

# Looker
# looker_url: https://yourcompany.looker.com
# lookml_project: analytics

# Metabase
# metabase_url: https://analytics.example.com

## Data Quality

data_quality_tool: dbt-tests    # dbt-tests | great-expectations | monte-carlo | soda | custom | none

# dbt tests applied by default
dbt_default_tests: not_null,unique,accepted_values,relationships

## Data Sources

# List primary data sources (one per line)
sources: |
  - name: postgres-prod
    type: postgresql
  - name: stripe
    type: api
  - name: segment
    type: s3-events

## Freshness SLOs

# Default freshness expectations
slo_streaming_minutes: 5        # streaming pipelines must be < N minutes behind
slo_batch_daily_utc: "06:00"    # daily batch must be complete by this UTC time

## Cloud & Infra

cloud: gcp                      # gcp | aws | azure | other
secret_manager: gcp-secret-manager  # gcp-secret-manager | aws-secrets | azure-keyvault | vault | env | none

## ML (if applicable)

ml_framework: none              # pytorch | tensorflow | sklearn | xgboost | lightgbm | jax | none
experiment_tracker: none        # mlflow | wandb | comet | neptune | none
model_registry: none            # mlflow | wandb | vertex-ai | sagemaker | none
feature_store: none             # feast | tecton | vertex-ai | sagemaker | none

## Workflow Tools
# Set by /detect-workflow

ticket_system: jira             # from workflow.config.md
docs_platform: confluence       # from workflow.config.md
