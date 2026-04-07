---
name: performance-profile
description: >
  Mobile performance profiling workflow. Analyzes code for Android/iOS performance
  anti-patterns, estimates impact, and provides a prioritized optimization plan.
  Delegates to the mobile-performance agent.
  Invoke with /performance-profile <file, screen, or symptom>.
---

# Performance Profiling Workflow

When invoked, delegate to `mobile-performance` agent and follow this process:

## Step 1 — Identify the Symptom

Ask or infer:
- What is the user-visible problem? (slow startup, jank, ANR, battery drain, large download)
- Platform: Android, iOS, or both?
- Do we have profiler output? (Android Studio CPU/Memory trace, Instruments trace)

## Step 2 — Static Code Analysis

Read the relevant files and scan for:

**Android:**
- Main thread I/O (Strict Mode violations)
- RecyclerView without DiffUtil
- Bitmaps loaded at full resolution
- Heavy work in `onDraw()` or `onMeasure()`
- `GlobalScope` coroutines that can't be cancelled
- Compose: unstable types causing excessive recomposition

**iOS:**
- Synchronous URLSession calls on main queue
- `UIImage(named:)` used for large one-time images (should use `contentsOfFile:`)
- Heavy `body` computations in SwiftUI views
- Missing `[weak self]` in long-lived closures (potential retain cycles → memory growth)
- `NotificationCenter` observers not removed

## Step 3 — Estimate Impact

For each issue, estimate:
- **Severity**: Critical (user-visible, reproducible) / Medium (accumulates) / Low (micro)
- **Frequency**: Every render / per-session / one-time
- **Fix effort**: Trivial / Hours / Days

## Step 4 — Profiling Commands

Provide platform-specific profiling commands:

**Android:**
```bash
# Enable Strict Mode in debug builds
StrictMode.setThreadPolicy(StrictMode.ThreadPolicy.Builder()
    .detectAll()
    .penaltyLog()
    .build())

# Profile with systrace
python $ANDROID_SDK/platform-tools/systrace/systrace.py --time=10 -o trace.html gfx view sched

# Baseline Profiles (startup optimization)
./gradlew generateBaselineProfile
```

**iOS (Instruments CLI):**
```bash
# Time Profiler
instruments -t "Time Profiler" -D ~/Desktop/trace.trace MyApp.app

# Leaks
instruments -t "Leaks" -D ~/Desktop/leaks.trace MyApp.app
```

## Step 5 — Output

```
## Performance Analysis: [Component/Symptom]

### Platform: [Android / iOS / Both]

### Root Cause Summary
[1-2 sentences describing the main bottleneck]

### Critical Issues
- [File:Line] Anti-pattern — estimated impact — fix

### Medium Issues
- [File:Line] Anti-pattern — fix

### Quick Wins
- [File:Line] Small change, meaningful gain

### Optimization Plan (prioritized)
1. [Highest impact fix] — estimated gain
2. ...

### Profiling Steps to Validate
[Specific steps to measure before/after]
```
