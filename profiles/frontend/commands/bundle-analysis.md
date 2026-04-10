---
description: Analyse bundle size and identify optimisation opportunities. Spawns frontend-architect to review imports, code splitting, and lazy loading.
---

Spawn `frontend-architect` with a focused task: analyse the build output and source for:
1. Large dependencies that could be replaced or lazy-loaded
2. Missing code splitting on large routes
3. Unused imports and dead code
4. Images not optimised or lazy-loaded
5. Recommendations for reducing initial bundle size

If a bundle stats file (webpack-bundle-analyzer, vite-bundle-visualizer) output is available, include it.
