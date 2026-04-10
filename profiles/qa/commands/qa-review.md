---
description: 4-stage release sign-off workflow. Argument is a release version or feature name. Spawns qa-lead for readiness check, bug-triager for triage, qa-lead for sign-off document, then qa-lead for ticket updates.
argument: release version or feature name (e.g. "v2.4.0" or "checkout-redesign")
---

Run a full QA release sign-off for the release or feature described in the argument.

You are the **orchestrator**. Do NOT perform any stage yourself — spawn a dedicated
sub-agent for each stage using the `Agent` tool. Each sub-agent gets an isolated
context window focused on its domain.

---

## Before starting

Read `qa.config.md` and `workflow.config.md`. Extract the following variables and
inject them into every agent prompt below:

- `{{RELEASE}}` — argument passed to this command
- `{{TICKET_SYSTEM}}` — e.g. Jira, Linear, GitHub Issues (from workflow.config.md)
- `{{TEST_MGMT}}` — e.g. TestRail, Zephyr, Xray, spreadsheet (from qa.config.md)
- `{{DOCS_PLATFORM}}` — e.g. Confluence, Notion, GitHub Wiki (from workflow.config.md)
- `{{E2E_FRAMEWORK}}` — e.g. Playwright, Cypress, Appium (from qa.config.md)
- `{{SEVERITY_LABELS}}` — e.g. "Critical/High/Medium/Low" or "S1/S2/S3/S4" (from qa.config.md)
- `{{COVERAGE_THRESHOLD}}` — minimum coverage % required for release (from qa.config.md, default 80%)

If any config file is missing, note the missing values and proceed using the
defaults shown above in parentheses.

---

## Stage Definitions

### Stage 1 — RELEASE READINESS CHECK
Spawn the `qa-lead` agent.

Agent prompt:
```
You are the qa-lead agent running a pre-release readiness check.

Release: {{RELEASE}}
Ticket system: {{TICKET_SYSTEM}}
Test management: {{TEST_MGMT}}
E2E framework: {{E2E_FRAMEWORK}}
Severity labels: {{SEVERITY_LABELS}}
Coverage threshold: {{COVERAGE_THRESHOLD}}

Read qa.config.md and workflow.config.md.
Read profiles/qa/rules/testing-standards.md.

Investigate the current state of this release across all quality gates. For each
gate below, scan available files, test result artifacts, and project directories
to determine the real status. If you cannot determine status from files, mark it
as "Unknown — manual check required" and explain what to look for.

**Gate 1 — Test Execution**
- Did all P0 tests pass in the latest test run?
- Are there any P1 test failures still open?
- What is the total pass/fail count for the regression suite?
- Scan for test result files: JUnit XML, Allure reports, cucumber reports, etc.

**Gate 2 — Open Bugs**
- How many {{SEVERITY_LABELS}} Severity-1 (Critical) bugs are currently open?
- How many Severity-2 (High) bugs are open without an assigned owner?
- Any bug open for > 2 sprints without progress?
- Search for bug tracking files, CHANGELOG, known-issues docs.

**Gate 3 — Test Coverage**
- Does current coverage meet the {{COVERAGE_THRESHOLD}} threshold?
- Which modules are below threshold (if coverage report is available)?
- Scan for coverage report files: lcov.info, coverage.xml, coverage-summary.json.

**Gate 4 — Regression Suite**
- What is the overall regression suite status?
- How many tests passed / failed / skipped?
- Are there any tests marked as flaky or excluded from this run?

**Gate 5 — Performance**
- Were performance tests run for this release?
- Are P95 latency targets met per the SLOs in qa.config.md?
- Any endpoints degraded compared to previous baseline?

**Gate 6 — Accessibility**
- Were accessibility checks run against UI changes in this release?
- Are all Critical WCAG 2.1 AA failures resolved?
- Any open accessibility bugs with Severity-1 or Severity-2 classification?

**Gate 7 — Security**
- Was a security scan run for this release?
- Are there any Critical or High severity security findings unresolved?
- Check for SAST/DAST report files, security scan output.

**Gate 8 — Documentation**
- Have release notes been written and reviewed?
- Has the runbook been updated for any operational changes?
- Are API docs / changelogs updated to reflect this release?

Output a readiness matrix in this exact format:

## Release Readiness Matrix — {{RELEASE}}

| Gate | Status | Blocker? | Notes |
|------|--------|----------|-------|
| P0/P1 tests | ✓ Pass / ✗ Fail / ⚠ Unknown | Yes/No | details |
| Open Sev-1 bugs | N open | Yes if N > 0 | list IDs if known |
| Open Sev-2 (unowned) | N open | Yes if N > 0 | list IDs if known |
| Coverage | N% (threshold: {{COVERAGE_THRESHOLD}}%) | Yes if below | modules below threshold |
| Regression suite | N pass / N fail / N skip | Yes if failures | suite name |
| Performance SLOs | Met / Not met / Unknown | Yes if not met | which endpoints |
| Accessibility | N critical open | Yes if > 0 | WCAG criteria |
| Security | N critical/high open | Yes if > 0 | severity breakdown |
| Release notes | Written / Missing | Yes if missing | doc link if found |
| Runbook | Updated / Not updated / N/A | No | note if N/A |

**Overall Verdict**: READY TO SHIP / BLOCKED / NEEDS REVIEW
**Release blockers** (if any):
1. [blocker description — gate — recommended action]

Tools: Read, Glob, Grep
```

Gate: Print the readiness matrix. Ask "Readiness review complete. Proceed to BUG TRIAGE? [y/N]"

---

### Stage 2 — BUG TRIAGE
Spawn the `bug-triager` agent.

Agent prompt:
```
You are the bug-triager agent performing pre-release bug triage.

Release: {{RELEASE}}
Ticket system: {{TICKET_SYSTEM}}
Severity labels: {{SEVERITY_LABELS}}

Read qa.config.md and workflow.config.md.

Your job is to triage all known open bugs for this release and produce a
ship/defer/hold recommendation.

**Step 1 — Bug inventory**
Search the project for known open bugs. Check:
- CHANGELOG, KNOWN_ISSUES, or BUGS files
- Any markdown files listing open issues
- Test failure summaries from Stage 1 (if passed in context)
- Comments in source files referencing bug IDs (e.g. "TODO: BUG-123")

For each open bug found, determine:
- **Severity**: using {{SEVERITY_LABELS}} scale
  - Sev 1 / Critical: data loss, security breach, service down, payment failure
  - Sev 2 / High: major feature broken, no workaround, affects significant user base
  - Sev 3 / Medium: feature degraded, workaround exists
  - Sev 4 / Low: cosmetic, minor inconvenience, affects very few users
- **Component**: which area of the product (auth, payments, search, etc.)
- **Reproducibility**: Always (100% repro) / Sometimes (intermittent) / Rare (< 10%)
- **Classification decision**:
  - Fix Required: Sev 1 or Sev 2 with no workaround → must fix before ship
  - Ship with Known Issues: Sev 2 with documented workaround, or Sev 3 affecting many
  - Defer: Sev 3/4 with clear workaround → schedule for next release
  - Won't Fix: Sev 4 cosmetic, edge case, not worth the risk of a last-minute fix

**Step 2 — Blast radius for "Fix Required" bugs**
For each Fix Required bug:
- Estimate user impact: which user segments affected? What % of users?
- What is the failure mode? Does it fail silently or visibly?
- Is there a workaround teams can apply while the fix is developed?
- What is the estimated fix effort (hours)?

**Step 3 — Release recommendation**
Based on the triage above:
- SHIP: no Fix Required bugs remaining
- SHIP WITH KNOWN ISSUES: Fix Required bugs have workarounds and are documented
- HOLD RELEASE: one or more Fix Required bugs with no workaround

Output:

## Bug Triage — {{RELEASE}}

### Summary
- Total open bugs: N
- Fix Required (blocking): N
- Ship with Known Issues: N
- Defer to next release: N
- Won't Fix: N
- **Recommendation: SHIP / SHIP WITH KNOWN ISSUES / HOLD**

### Must Fix Before Release
| Bug ID | Summary | Severity | Component | Owner | Blast Radius | ETA |
|--------|---------|----------|-----------|-------|-------------|-----|

### Ship With Known Issues
| Bug ID | Summary | Severity | Workaround | User Impact | Comms needed? |
|--------|---------|----------|------------|-------------|---------------|

### Deferred to Next Release
| Bug ID | Summary | Severity | Reason for Deferral | Target Release |
|--------|---------|----------|--------------------|----------------|

### Won't Fix
| Bug ID | Summary | Severity | Reason |
|--------|---------|----------|--------|

Tools: Read, Glob, Grep
```

Gate: Print triage tables. Ask "Bug triage reviewed. Proceed to SIGN-OFF DOCUMENT? [y/N]"

---

### Stage 3 — SIGN-OFF DOCUMENT
Spawn the `qa-lead` agent.

Agent prompt:
```
You are the qa-lead agent writing the official release sign-off document.

Release: {{RELEASE}}
Docs platform: {{DOCS_PLATFORM}}
Ticket system: {{TICKET_SYSTEM}}

Stage 1 readiness summary (first 2000 chars):
{{READINESS_OUTPUT}}

Stage 2 bug triage summary (first 2000 chars):
{{TRIAGE_OUTPUT}}

Read qa.config.md and workflow.config.md.

Write a complete, professional release sign-off document formatted for
{{DOCS_PLATFORM}}. This document is the permanent quality record for this release.

The document must include every section below — do not omit any section.

---

# QA Release Sign-Off — {{RELEASE}}

**Date**: [today's date]
**QA Lead**: [QA Lead name — placeholder if unknown]
**Release Type**: [Major / Minor / Patch / Hotfix]

---

## 1. Release Scope

### Features Included
List every feature or change included in this release, as best you can determine
from available files (CHANGELOG, PR descriptions, commit history, release notes):
- [Feature name] — [one-sentence description]

### Out of Scope (Explicitly Not Tested)
List anything known to NOT have been tested, and why:
| Area | Reason Not Tested | Risk Level |
|------|------------------|------------|

---

## 2. Test Execution Summary

### Test Coverage by Type
| Test Type | Total | Passed | Failed | Skipped | Pass Rate |
|-----------|-------|--------|--------|---------|-----------|
| Unit tests | | | | | |
| Integration tests | | | | | |
| E2E / Regression | | | | | |
| Performance tests | | | | | |
| Accessibility checks | | | | | |
| Security scan | | | | | |

Fill in from Stage 1 readiness data. Use "N/A" where not applicable.

### Coverage
- Code coverage: N% (threshold: required {{COVERAGE_THRESHOLD}}%)
- Status: MEETS THRESHOLD / BELOW THRESHOLD

---

## 3. Quality Gate Results

Reproduce the readiness matrix from Stage 1. Include the overall verdict.

---

## 4. Known Issues Shipping With This Release

From Stage 2 triage — "Ship With Known Issues" list.
For each known issue provide:
- Bug ID and summary
- User impact and affected user segment
- Workaround steps (exact steps users or support can take)
- Fix target (next release version or sprint)
- Customer comms required: Yes / No

If none: state "No known issues are shipping with this release."

---

## 5. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| [risk description] | High/Med/Low | High/Med/Low | [mitigation] |

Include at minimum:
- Rollback risk (how hard is it to roll back if something goes wrong post-deploy?)
- Data migration risk (if applicable)
- Third-party dependency risk
- Performance risk under peak load

---

## 6. Rollback Procedure

- Rollback trigger: [define the condition that triggers a rollback — e.g. error rate > 1%]
- Rollback steps: [numbered procedure or link to runbook]
- Data rollback required: Yes / No
- Estimated rollback time: [minutes]
- Rollback tested: Yes / No / Not applicable

---

## 7. Sign-Off

Approval required from all three roles before deployment proceeds.

| Role | Name | Signature | Date | Decision |
|------|------|-----------|------|----------|
| QA Lead | [name] | ___________ | | Approved / Rejected |
| Engineering Lead | [name] | ___________ | | Approved / Rejected |
| Product Owner | [name] | ___________ | | Approved / Rejected |

**Deployment approved**: YES / NO (pending signatures above)
**Earliest deploy window**: [date/time]

---

*Document generated by Claude Crew QA workflow. Validate all data against live
test management system ({{TEST_MGMT}}) before use as official record.*

---

Write the full document to `qa-sign-off-{{RELEASE}}.md` in the project root or
docs directory. Use {{DOCS_PLATFORM}}-appropriate markdown formatting (e.g. Confluence
uses different heading syntax than GitHub Wiki — apply the right format).

Tools: Read, Write, Glob
```

Gate: Print the sign-off document filename and section summary. Ask "Sign-off document written. Proceed to TICKET UPDATES? [y/N]"

---

### Stage 4 — TICKET UPDATES
Spawn the `qa-lead` agent.

Agent prompt:
```
You are the qa-lead agent generating ticket update instructions.

Release: {{RELEASE}}
Ticket system: {{TICKET_SYSTEM}}

Bug triage from Stage 2 (first 2000 chars):
{{TRIAGE_OUTPUT}}

Sign-off document location from Stage 3:
{{SIGNOFF_DOC_PATH}}

Read qa.config.md and workflow.config.md.

Generate exact, copy-pasteable ticket update instructions for every action
required in {{TICKET_SYSTEM}} to close out this release. A developer or QA
engineer should be able to work through this list mechanically.

**Section A — Deferred Bugs**
For each bug in the "Deferred to Next Release" list from Stage 2:
```
Update [BUG-ID] — [Bug Summary]:
  - Set "Fix Version" field to: [next release version]
  - Add label: deferred
  - Add comment: "Deferred from {{RELEASE}}. Reason: [reason from triage].
    Workaround: [workaround if any]. Target: [next release]."
  - Change status to: Backlog / Won't Fix This Sprint (use {{TICKET_SYSTEM}} status)
```

**Section B — Won't Fix Bugs**
For each bug in the "Won't Fix" list from Stage 2:
```
Update [BUG-ID] — [Bug Summary]:
  - Set status to: Won't Fix / Closed (use {{TICKET_SYSTEM}} status)
  - Add comment: "Closing as Won't Fix for {{RELEASE}}. Reason: [reason].
    If this becomes relevant again, reopen with updated context."
```

**Section C — Release Ticket / Epic**
```
Update [RELEASE TICKET or EPIC for {{RELEASE}}]:
  - Set status to: QA Approved
  - Add label: qa-approved
  - Add comment: "QA sign-off complete for {{RELEASE}}.
    Sign-off document: [{{SIGNOFF_DOC_PATH}}]
    Known issues shipping: [count from triage]
    Approval status: pending Engineering Lead + Product Owner sign-off"
  - Attach or link: sign-off document
```

**Section D — Known Issues (if any shipping)**
For each bug in the "Ship With Known Issues" list:
```
Update [BUG-ID] — [Bug Summary]:
  - Add label: known-issue-{{RELEASE}}
  - Set "Ships In" field to: {{RELEASE}}
  - Add comment: "Shipping in {{RELEASE}} as known issue.
    Workaround: [workaround]. Customer comms: [Yes/No]. Fix target: [target]."
```

**Section E — Post-release actions to schedule**
List any follow-up tickets that should be created now but actioned after deploy:
- Create ticket: "Post-{{RELEASE}} regression run" — assigned to QA team
- Create ticket: "Monitor error rates for 48h post-{{RELEASE}} deploy" — assigned to oncall
- Create ticket: "Fix deferred bugs — [next release]" — assigned to tech lead

Print all update instructions grouped by section. The output of this stage is a
checklist that can be handed to any team member to execute in {{TICKET_SYSTEM}}.

Tools: Read, Glob
```

---

## QA Review Summary Report

After all stages complete, print:

```
════════════════════════════════════════════════════════
  QA Release Sign-Off — {{RELEASE}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — READINESS CHECK
      Overall verdict: [READY TO SHIP / BLOCKED / NEEDS REVIEW]
      Blockers: [N blockers — list if any]

  [✓] Stage 2 — BUG TRIAGE
      Recommendation: [SHIP / SHIP WITH KNOWN ISSUES / HOLD]
      Fix Required: N bugs
      Known issues shipping: N bugs
      Deferred: N bugs

  [✓] Stage 3 — SIGN-OFF DOCUMENT
      Written to: [filename]
      Awaiting signatures: QA Lead, Engineering Lead, Product Owner

  [✓] Stage 4 — TICKET UPDATES
      Ticket actions generated: N
      Deferred bugs updated: N
      Won't Fix bugs closed: N
════════════════════════════════════════════════════════

FINAL RECOMMENDATION: [SHIP / HOLD — based on Stage 1 verdict + Stage 2 recommendation]

Action items before deployment:
  [ ] All "Fix Required" bugs resolved (Stage 2)
  [ ] Sign-off document signed by all three approvers (Stage 3)
  [ ] Ticket updates executed in {{TICKET_SYSTEM}} (Stage 4)
  [ ] Known issues documented in release notes
  [ ] Rollback procedure confirmed ready

Post-deployment:
  [ ] Monitor error rate vs baseline for 48h
  [ ] Run smoke suite against production
  [ ] Confirm known-issues workarounds accessible to support team
```

---

## Variables

- `{{RELEASE}}` = argument passed to this command
- `{{TICKET_SYSTEM}}` = from workflow.config.md (e.g. Jira, Linear, GitHub Issues)
- `{{TEST_MGMT}}` = from qa.config.md (e.g. TestRail, Zephyr, Xray)
- `{{DOCS_PLATFORM}}` = from workflow.config.md (e.g. Confluence, Notion, GitHub Wiki)
- `{{E2E_FRAMEWORK}}` = from qa.config.md (e.g. Playwright, Cypress, Appium)
- `{{SEVERITY_LABELS}}` = from qa.config.md (e.g. Critical/High/Medium/Low or S1/S2/S3/S4)
- `{{COVERAGE_THRESHOLD}}` = from qa.config.md (default: 80%)
- `{{READINESS_OUTPUT}}` = Stage 1 output summary (first 2000 chars)
- `{{TRIAGE_OUTPUT}}` = Stage 2 output summary (first 2000 chars)
- `{{SIGNOFF_DOC_PATH}}` = path of file written in Stage 3
