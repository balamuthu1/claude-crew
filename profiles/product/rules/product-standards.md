# Product Standards

These rules apply to all product documentation and requirement writing.

## Requirement writing principles

1. **Specific over vague** — "Reduce checkout completion rate by 10%" not "Improve checkout"
2. **Testable** — every requirement must be verifiable; if you can't test it, rewrite it
3. **User-centric** — requirements from the user's perspective, not the implementation's
4. **Complete error handling** — every happy path needs corresponding error paths
5. **Measurable outcomes** — every feature needs a success metric with baseline

## PRD quality checklist

Before handing off a PRD to engineering:
- [ ] Problem statement written in user terms (not technical terms)
- [ ] Success metrics defined with current baseline
- [ ] All user types / personas addressed
- [ ] Edge cases documented
- [ ] Error states documented with recovery paths
- [ ] Out-of-scope explicitly listed
- [ ] Open questions assigned to owners with due dates
- [ ] Dependencies on other teams identified
- [ ] Privacy/data considerations addressed (does this collect new data?)
- [ ] Accessibility requirements stated

## User story quality checklist

Before a story enters sprint:
- [ ] "As a... I want... so that..." format
- [ ] Acceptance criteria in Given/When/Then
- [ ] All edge cases covered in acceptance criteria
- [ ] No implementation details (unless a constraint)
- [ ] Story is independently deliverable (vertical slice)
- [ ] Small enough to complete in one sprint

## Metric definition standards

Metrics must be:
- **Defined before the feature ships** — not retrospectively
- **Agreed by stakeholders** — one source of truth
- **Instrumented correctly** — verify tracking before launch
- **Baselined** — you need before/after to measure impact
- **Time-bounded** — "measure for 4 weeks post-launch"

## Privacy and data requirements

Every feature that collects, processes, or displays user data must address:
- What data is collected?
- Why is it needed? (data minimisation principle)
- Where is it stored?
- Who has access?
- How long is it retained?
- Does it require user consent?
- Is it subject to GDPR/CCPA deletion requests?

Flag any new data collection for privacy review before committing to build.

## Stakeholder communication standards

- Weekly written updates > ad-hoc verbal updates
- Decisions documented in writing with rationale
- Scope changes communicated with impact analysis
- Trade-offs presented explicitly — not hidden in implementation
