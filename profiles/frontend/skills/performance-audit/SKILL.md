---
user-invocable: true
description: Frontend performance audit — bundle size, render performance, Core Web Vitals, and optimisation plan
allowed-tools: Read, Bash, Glob, Grep
---

# Frontend Performance Audit Workflow

1. Spawn `frontend-architect` to analyse:
   - Bundle size and composition (large dependencies, unused code)
   - Code splitting and lazy loading coverage
   - Image optimisation
   - Render performance (unnecessary re-renders, layout thrashing)
2. Check Core Web Vitals impact (LCP, INP, CLS)
3. Produce prioritised optimisation plan with expected improvements
4. Output: audit report + ordered fix list
