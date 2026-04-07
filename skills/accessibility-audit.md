---
name: accessibility-audit
description: >
  Full accessibility audit for a mobile screen or feature. Checks WCAG 2.1 AA
  compliance, TalkBack/VoiceOver usability, color contrast, touch targets, and
  dynamic text. Delegates to the ui-accessibility agent.
  Invoke with /accessibility-audit <screen or feature>.
---

# Accessibility Audit Workflow

When invoked, delegate to `ui-accessibility` agent and follow this process:

## Step 1 — Read the UI Code

Read all View/Composable/ViewController files for the specified screen.

## Step 2 — Run the Audit

Apply the full WCAG 2.1 AA checklist from `agents/ui-accessibility.md`.

Focus areas for mobile:
1. Every interactive element has a label (content description / accessibility label)
2. Decorative images are hidden from assistive tech
3. Touch targets ≥ 48dp (Android) / 44pt (iOS)
4. Text uses scalable units (sp / Dynamic Type)
5. Color contrast meets 4.5:1 ratio
6. Focus/reading order is logical
7. Error states communicated beyond color alone
8. Loading states announced to screen readers

## Step 3 — Generate a11y Code Fixes

For each issue found, provide the corrected code snippet inline.

## Step 4 — Output Report

```
## Accessibility Audit: [Screen/Feature Name]

### WCAG 2.1 AA Compliance: [Pass / Partial / Fail]

### Critical Barriers (blocks users)
- [Criterion] [File:Line] Issue — Fix

### Major Issues
- [Criterion] [File:Line] Issue — Fix

### Minor Issues
- [File:Line] Suggestion

### Passes
- [✓] Labels on interactive elements
- [✓] ...

### Manual Testing Steps
1. Enable TalkBack/VoiceOver
2. Navigate to [Screen]
3. Verify: [what to check]
```
