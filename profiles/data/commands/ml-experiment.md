Set up a complete ML experiment for the problem described in the argument.

You are the **orchestrator**. Do NOT implement models yourself — spawn dedicated sub-agents for each stage.

---

## Before starting

Read `data.config.md` and `workflow.config.md`. Extract:
- `{{ML_FRAMEWORK}}` — pytorch, tensorflow, sklearn, xgboost, etc.
- `{{EXPERIMENT_TRACKER}}` — mlflow, wandb, comet, neptune, none
- `{{FEATURE_STORE}}` — feast, tecton, vertex-feature-store, none
- `{{WAREHOUSE}}` — bigquery, snowflake, redshift, etc.
- `{{TICKET_SYSTEM}}` — from workflow.config.md
- `{{DOCS_PLATFORM}}` — from workflow.config.md

If `data.config.md` does not exist, tell the user to run `/detect-data-stack` first and stop.

---

## Stage Definitions

### Stage 1 — PROBLEM FRAMING
Spawn the `ml-engineer` agent.

Agent prompt:
```
You are the ml-engineer agent.

ML problem: {{PROBLEM}}

Frame the ML problem correctly before writing any code.

1. **Problem type**:
   - Classification (binary, multi-class, multi-label)?
   - Regression (point estimate, interval)?
   - Ranking / recommendation?
   - Clustering?
   - Anomaly detection?
   - Sequence modelling (NLP, time series)?
   - Generation?

2. **Label definition**:
   - What exactly are we predicting? Be precise — not "user churn" but
     "user who does not log in for 30 consecutive days"
   - Where does ground truth come from?
   - Is there label noise? How significant?
   - For ranking/recommendation: what constitutes a positive signal (click, purchase, rating)?

3. **Baseline definition** (non-ML approach to beat):
   - What is the current rule-based or heuristic approach?
   - What is its performance? (precision/recall, RMSE, hit-rate, etc.)
   - Why is ML expected to improve on it?

4. **Offline success metric**:
   - Classification: AUC-ROC, F1, precision@k, recall@k, log-loss
   - Regression: RMSE, MAE, MAPE, R²
   - Ranking: NDCG@k, MAP@k, MRR
   - Chosen metric: [one metric] — justified as the right one for this problem

5. **Online success metric** (business metric):
   - Which business KPI will improve if the model works?
   - How is it measured? (A/B test, holdout group, before/after)
   - Minimum detectable effect size: what improvement is commercially meaningful?

6. **Training data**:
   - Where does it live? (table in {{WAREHOUSE}}, S3, etc.)
   - How much is available? (rows, date range)
   - Is it labeled? If not, how do we get labels?
   - Class imbalance: what is the positive:negative ratio?
   - Temporal structure: is the data time-ordered? (affects split strategy)

7. **Feature candidates**:
   - List 5-15 features likely to be predictive
   - For each: data source, availability at inference time, computation cost
   - Leakage check: is any feature derived from the label, directly or indirectly?

8. **Inference constraints**:
   - Latency: online (< 100ms), near-real-time (< 1s), or batch (minutes/hours)?
   - Throughput: requests/second?
   - Model size limit? (edge deployment vs cloud API)
   - Explainability required? (SHAP, LIME, model cards for regulatory reasons?)

9. **Failure mode analysis**:
   - False positive: what happens when the model incorrectly predicts positive?
   - False negative: what happens when the model misses a true positive?
   - Which is more costly? (determines the classification threshold strategy)

Output: complete problem framing document.
```
Tools: Read, Glob

Gate: Print problem framing. Ask "Framing correct? Proceed to DATA ANALYSIS? [y/N]"

---

### Stage 2 — DATA ANALYSIS
Spawn the `ml-engineer` agent.

Agent prompt:
```
You are the ml-engineer agent.

ML problem: {{PROBLEM}}
Framing from Stage 1: {{FRAMING_OUTPUT}}
Warehouse: {{WAREHOUSE}}
Feature store: {{FEATURE_STORE}}

Analyse the training data and design the preprocessing pipeline.

1. **Data availability check**:
   Scan the codebase and data config for tables relevant to this problem.
   List each relevant table: name, approx row count, date range, key columns.

2. **Label analysis**:
   - Class balance (for classification): positive rate
   - Target distribution (for regression): mean, std, min, max, histogram shape
   - Label quality: are there obviously mislabeled examples? How to detect?
   - If imbalanced: recommend oversampling (SMOTE), undersampling, or class_weight?

3. **Feature audit** — for each candidate feature from Stage 1:
   | Feature | Source table | Missing rate | Cardinality | Distribution | Leakage risk |
   |---------|-------------|-------------|-------------|--------------|-------------|

4. **Data split strategy**:
   - Random split: appropriate only if data is i.i.d. (no temporal or group dependencies)
   - Time-based split: use for time series or when label is future event
     Split point: train on events before [date], evaluate on events after [date]
   - Group-based split: use when rows within a group must stay together
     (e.g. all rows for a given user in same split)
   - Test set: held-out set that is touched EXACTLY ONCE for final evaluation

5. **Feature engineering pipeline** (order matters):
   Step 1: join and filter raw tables → training dataframe
   Step 2: compute time-based features (recency, frequency, time-since-event)
   Step 3: encode categoricals (target encoding, one-hot, embeddings)
   Step 4: scale numerics (StandardScaler, MinMaxScaler — fit on train ONLY)
   Step 5: handle missing values (impute or create missingness indicator feature)
   Step 6: feature selection (drop correlated features, check variance threshold)

6. **Feature store check** (for {{FEATURE_STORE}}):
   - Which features are already computed and served?
   - Which new features should be added to {{FEATURE_STORE}} for reuse?
   - What is the freshness of existing features? Sufficient for this use case?

7. **Data leakage audit**:
   - Any feature computed using information from AFTER the label event? → remove
   - Any feature that directly contains the label? → remove
   - Any feature that is a proxy for the label? → evaluate carefully
   - Temporal leakage: are features computed with a correct point-in-time window?

Output: data analysis report + feature engineering pipeline design.
```
Tools: Read, Grep, Glob

Gate: Ask "Data analysis complete. Proceed to EXPERIMENT DESIGN? [y/N]"

---

### Stage 3 — EXPERIMENT DESIGN
Spawn the `ml-engineer` agent.

Agent prompt:
```
You are the ml-engineer agent.

ML problem: {{PROBLEM}}
Framing: {{FRAMING_OUTPUT}}
Experiment tracker: {{EXPERIMENT_TRACKER}}
ML framework: {{ML_FRAMEWORK}}

Design the experiment structure.

1. **{{EXPERIMENT_TRACKER}} setup**:
   - Project/experiment naming convention: [project_name/experiment_name]
   - Parameters to log: all hyperparameters used in training
   - Metrics to track: train loss, val loss, chosen offline metric — per epoch
   - Artifacts to save: model weights, preprocessing pipeline, feature importance plot,
     confusion matrix (classification) or residual plot (regression)
   - Tags: model_type, feature_set_version, data_split_date, environment

2. **Model candidates** (3 in order of complexity):

   BASELINE — simple, interpretable, fast to train:
   - For classification: logistic regression, decision tree
   - For regression: linear regression, gradient boosted trees (shallow)
   - Purpose: establishes minimum acceptable performance bar

   MAIN CANDIDATE — appropriate complexity for the problem:
   - For tabular: gradient boosted trees (XGBoost/LightGBM/CatBoost)
   - For text: fine-tuned transformer (DistilBERT, BERT, etc.)
   - For images: fine-tuned CNN (ResNet, EfficientNet)
   - For sequences: LSTM or Transformer
   - Hyperparameter search: list 3-5 key hyperparameters to tune

   STRETCH — if time and compute allow:
   - Ensemble of main candidate + baseline
   - Larger pretrained model

3. **Hyperparameter search strategy**:
   - Grid search: for ≤ 3 hyperparameters with small ranges
   - Random search: for > 3 hyperparameters (often better than grid)
   - Bayesian optimization (Optuna, Ray Tune): for expensive training runs
   - Number of trials: N (budget based on compute cost)

4. **Evaluation protocol**:
   - Cross-validation: k=5 for small datasets; k=3 for large
   - Offline evaluation: metric(s) on held-out test set
   - Threshold selection (classification): ROC curve + business cost analysis
   - Calibration check: are predicted probabilities calibrated? (Brier score, reliability diagram)

5. **File structure**:
   ```
   ml/{{experiment-name}}/
     data/           # data loading + feature engineering
       pipeline.py   # sklearn Pipeline or custom transformer
       features.py   # feature definitions
     models/         # model definitions / wrappers
       baseline.py
       main_model.py
     train.py        # training script (reads config.yaml)
     evaluate.py     # evaluation script (metrics + plots)
     predict.py      # inference script
     config.yaml     # all hyperparameters — no hardcoding
     requirements.txt
     README.md       # how to run the experiment
   ```

Output: experiment design document.
```
Tools: Read

Gate: Ask "Experiment design approved. Proceed to IMPLEMENTATION? [y/N]"

---

### Stage 4 — IMPLEMENTATION
Spawn the `ml-engineer` agent.

Agent prompt:
```
You are the ml-engineer agent.

ML problem: {{PROBLEM}}
Framework: {{ML_FRAMEWORK}}
Experiment tracker: {{EXPERIMENT_TRACKER}}
Experiment design from Stage 3: {{DESIGN_OUTPUT}}

Write the complete experiment code. Every file must be production-ready.
No pseudocode, no TODOs, no placeholder functions.

Requirements for all code:
- No hardcoded file paths — use config.yaml and argparse / Hydra
- Reproducibility: set random seeds everywhere (numpy, torch, sklearn, python random)
- Log software versions in {{EXPERIMENT_TRACKER}} run metadata
- No data leakage: all preprocessing fit on train set only, then transform val/test
- Progress bars for loops (tqdm)
- Proper error handling for file I/O and API calls
- Type hints on all function signatures
- Docstrings for all public functions

Write:
1. `data/pipeline.py` — feature engineering pipeline (sklearn Pipeline or equivalent)
2. `data/features.py` — feature definitions and computation
3. `models/baseline.py` — baseline model class
4. `models/main_model.py` — main candidate model class
5. `train.py` — full training script with {{EXPERIMENT_TRACKER}} logging
6. `evaluate.py` — evaluation script producing: metrics table, confusion matrix, feature importance, calibration curve
7. `predict.py` — inference script (batch prediction on new data)
8. `config.yaml` — all hyperparameters externalized here
9. `requirements.txt` — pinned dependency versions

In train.py, include:
- Data loading and preprocessing
- Cross-validation loop
- {{EXPERIMENT_TRACKER}} run: log params, log metrics per fold, log final test metrics
- Model artifact saving (include preprocessing pipeline, not just weights)
- Final evaluation on held-out test set

List all files written.
```
Tools: Read, Write

### Stage 5 — DOCUMENTATION
Spawn the `ml-engineer` agent.

Agent prompt:
```
You are the ml-engineer agent.

ML problem: {{PROBLEM}}
Docs platform: {{DOCS_PLATFORM}}
Ticket system: {{TICKET_SYSTEM}}
Framing from Stage 1: {{FRAMING_OUTPUT}}

Produce:

1. **Model card** formatted for {{DOCS_PLATFORM}}:
   - Model name and version
   - Purpose: what the model predicts and why it exists
   - Intended use: correct use cases
   - Out-of-scope use: what the model should NOT be used for
   - Training data: description, date range, size
   - Evaluation results: metrics on test set
   - Known limitations and failure modes
   - Fairness considerations: any demographic groups that may be differently affected?
   - Maintenance: retraining trigger, monitoring plan

2. **Experiment log**:
   - What approaches were tried
   - Results table (model variant × metric)
   - Why certain approaches were abandoned
   - Final model selection rationale

3. **Deployment checklist**:
   - [ ] Model passes offline evaluation threshold
   - [ ] Preprocessing pipeline serialized with model (not just weights)
   - [ ] Inference latency tested and within SLA
   - [ ] Online A/B test design approved
   - [ ] Monitoring dashboards set up (predictions distribution, label drift)
   - [ ] Retraining pipeline scheduled
   - [ ] Model card reviewed by stakeholders

4. **Tickets for {{TICKET_SYSTEM}}**:
   "Create Epic: ML Experiment — {{PROBLEM}}"
   Sub-tasks:
   - "Data pipeline for {{PROBLEM}} training data | P1"
   - "Baseline model + evaluation | P1"
   - "Main model training + hyperparameter search | P1"
   - "Online A/B test setup | P1"
   - "Monitoring dashboards | P2"
   - "Retraining pipeline | P2"
```
Tools: Read, Write

---

## ML Experiment Summary Report

After all stages complete, print:

```
════════════════════════════════════════════════════════
  ML Experiment — {{PROBLEM}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — FRAMING       Type: <classification/regression/etc.>
  [✓] Stage 2 — DATA ANALYSIS Features: N, Split: <strategy>
  [✓] Stage 3 — DESIGN        Models: baseline + main + stretch
  [✓] Stage 4 — IMPLEMENTED   Files: N, Tracker: {{EXPERIMENT_TRACKER}}
  [✓] Stage 5 — DOCUMENTED    Model card + deployment checklist
════════════════════════════════════════════════════════

Primary offline metric: [metric name]
Baseline performance: [value or "TBD"]
Success threshold: [model must beat baseline by X%]

Files created: [list from Stage 4]
Tickets: [list from Stage 5]
```

---

## Variables

- `{{PROBLEM}}` = argument passed to this command
- `{{FRAMING_OUTPUT}}` = Stage 1 output (first 3000 chars)
- `{{DESIGN_OUTPUT}}` = Stage 3 output (first 2000 chars)
- `{{ML_FRAMEWORK}}`, `{{EXPERIMENT_TRACKER}}`, `{{FEATURE_STORE}}`, `{{WAREHOUSE}}` = from data.config.md
- `{{TICKET_SYSTEM}}`, `{{DOCS_PLATFORM}}` = from workflow.config.md
