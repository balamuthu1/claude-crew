---
name: mobile-code-review
description: >
  Cross-platform mobile code review workflow. Detects platform (Android/iOS/both)
  from context and delegates to the appropriate reviewer agent. Produces a unified
  review report. Invoke with /mobile-code-review.
---

# Mobile Code Review Workflow

When invoked, run this workflow:

## Step 1 — Detect Platform

Scan the changed/provided files:
- `.kt` or `.gradle` → Android review
- `.swift` or `.pbxproj` → iOS review
- Both present → Dual platform review

## Step 2 — Delegate to Specialist Agent

- Android code → invoke `android-reviewer` agent
- iOS code → invoke `ios-reviewer` agent
- Both → run both agents, merge findings

## Step 3 — Apply Universal Mobile Standards

Regardless of platform, check:

### Security (always)
- [ ] No secrets, API keys, or tokens in source
- [ ] No PII in logs or crash reports
- [ ] Sensitive data stored in platform secure storage (Keystore / Keychain)

### Architecture (always)
- [ ] No business logic in View layer (Activity/Fragment/ViewController/View)
- [ ] Single responsibility: each class does one thing
- [ ] Dependency direction flows toward domain (not away from it)

### Testing (always)
- [ ] New public methods have unit tests
- [ ] Edge cases covered: empty, error, null/nil inputs

### Accessibility (always)
- [ ] Interactive elements have accessibility labels / content descriptions
- [ ] Touch targets meet minimum size (48dp / 44pt)
- [ ] Color is not the only differentiator for important UI states

### Performance (always)
- [ ] No heavy work on main thread
- [ ] No memory leaks obvious from code inspection

## Step 4 — Produce Unified Report

```
## Mobile Code Review

### Files Reviewed
- [List of files]

### Platform(s)
[Android / iOS / Cross-platform]

---

### Critical (block merge)
[From platform-specific + universal checks]

### Major (fix before release)
[From platform-specific + universal checks]

### Minor (improvements)
[From platform-specific + universal checks]

### Accessibility Flags
[Any a11y issues spotted]

### Security Flags
[Any security issues spotted]

### Positive Observations
[What was done well]

---

### Overall Assessment
[ ] LGTM — ready to merge
[ ] Needs changes — see Critical/Major items above
[ ] Needs discussion — architectural questions raised
```
