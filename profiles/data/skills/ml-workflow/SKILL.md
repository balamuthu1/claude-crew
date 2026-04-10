---
user-invocable: true
description: ML experiment workflow — frame problem, build features, train model, evaluate, set up serving
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

# ML Workflow

1. Spawn `ml-engineer` to frame the problem (classification/regression/ranking)
2. Establish baseline (simple heuristic first)
3. Design and implement feature engineering
4. Write training script with experiment tracking (MLflow)
5. Evaluate on held-out test set (ML metrics + business metrics)
6. Set up model serving API
7. Define monitoring (data drift + prediction drift)
8. Output: full ML implementation + model card + monitoring setup
