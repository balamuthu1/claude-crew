---
description: 3-stage bug lifecycle management command. Argument is a bug description or existing bug ID. Spawns bug-triager to investigate, writes a formatted ticket, then automation-engineer writes a regression test.
argument: bug description (free text) or existing bug ID (e.g. "BUG-442" or "checkout fails when promo code applied to free shipping item")
---

Run the full bug lifecycle workflow for the bug described in the argument.

You are the **orchestrator**. Do NOT investigate, write tickets, or write tests
yourself — spawn a dedicated sub-agent for each stage using the `Agent` tool.
Each sub-agent gets an isolated context window focused on its domain.

---

## Before starting

Read `qa.config.md` and `workflow.config.md`. Extract the following variables and
inject them into every agent prompt below:

- `{{BUG}}` — argument passed to this command (bug description or ID)
- `{{TICKET_SYSTEM}}` — e.g. Jira, Linear, GitHub Issues (from workflow.config.md)
- `{{SEVERITY_LABELS}}` — e.g. "Critical/High/Medium/Low" or "S1/S2/S3/S4" (from qa.config.md)
- `{{E2E_FRAMEWORK}}` — e.g. Playwright, Cypress, Appium (from qa.config.md)
- `{{UNIT_FRAMEWORK}}` — e.g. JUnit, pytest, Vitest, Jest (from qa.config.md)
- `{{TEST_DIR}}` — path to the test directory (from qa.config.md, default: `tests/` or `__tests__/`)

If any config file is missing, note the missing values and proceed using the
defaults shown above in parentheses.

---

## Stage Definitions

### Stage 1 — BUG INVESTIGATION
Spawn the `bug-triager` agent.

Agent prompt:
```
You are the bug-triager agent conducting a systematic bug investigation.

Bug reported: {{BUG}}
Ticket system: {{TICKET_SYSTEM}}
Severity labels: {{SEVERITY_LABELS}}

Read qa.config.md and workflow.config.md.
Read profiles/qa/rules/qa-security-guardrails.md.

Investigate the bug thoroughly. Work through each section below completely.

---

**Section 1 — Reproduction Steps**

Write exact, numbered, deterministic steps to reproduce the bug. Steps must be
written as if for a QA engineer who has never seen the feature before:
1. Start from an explicit precondition state (logged in as X, on page Y)
2. Each step is a single action — no compound steps ("go to X and click Y" is two steps)
3. Final step describes the triggering action (the last thing you do before the bug appears)

If reproduction is intermittent, note the frequency and any conditions that
affect whether it reproduces (specific data, timing, concurrency, feature flags).

---

**Section 2 — Environment**

Document the full environment context:
- Operating system and version
- Browser name and version (for web) OR app version and device (for mobile)
- Backend version or API version (if known)
- Feature flags active (scan for feature flag config files in the project)
- User account type / role / subscription tier (if relevant)
- Data conditions (e.g. "user with 0 items in cart", "account with expired trial")
- Network conditions (if relevant: VPN, slow 3G, offline)

---

**Section 3 — Expected vs Actual Behaviour**

State these precisely — vague descriptions produce unresolvable bugs.

Expected behaviour:
- Describe the SPECIFIC outcome the user should see (text, UI state, API response)
- Reference the requirements, specs, or acceptance criteria if findable in the project
- If no spec exists, describe what a reasonable user would expect

Actual behaviour:
- Describe EXACTLY what happens: error message text, UI state change, incorrect value
- Include exact error messages, status codes, or log output (no paraphrasing)
- Describe the visual state of the UI if this is a UI bug

---

**Section 4 — Severity Assessment**

Classify using {{SEVERITY_LABELS}} scale:

Critical (Sev 1): data loss, security breach, authentication bypass, service completely
  down, payment processing failure, PII exposure
High (Sev 2): major feature completely broken with no workaround, affects a significant
  portion of users, data integrity issue without immediate loss
Medium (Sev 3): feature partially broken but has a workaround; affects a subset of
  users; non-critical workflow impaired
Low (Sev 4): cosmetic defect, minor text error, very rare edge case, easy workaround

Justify your severity choice with reference to the criteria above.
Also assign priority: P0 (fix now), P1 (this sprint), P2 (next sprint), P3 (backlog).
Priority = Severity × Business impact × User volume affected.

---

**Section 5 — Root Cause Hypothesis**

Based on the symptoms, what likely went wrong technically? Search the codebase:
- Find the code path that handles the described user action (Grep for relevant
  function names, API endpoints, component names, error message strings)
- Identify the most likely location where the bug is introduced
- Form a hypothesis: "This is likely caused by X because Y"
- Rate confidence: High (strong evidence) / Medium (plausible) / Low (speculation)

If you find candidate source files, note them with their paths and relevant
line numbers. Do not make changes — investigation only.

---

**Section 6 — Impact Assessment**

Estimate the real-world impact:
- Which user segments are affected? (all users / authenticated users / specific role)
- Rough estimate of affected users (if user count data is available in config/docs)
- Since when is this broken? (scan git log or CHANGELOG for recent changes to
  the affected area — identify any suspicious recent commits)
- Is there data corruption risk? (i.e. could this bug corrupt existing user data?)
- Is there a security implication? (could this be exploited or does it expose data?)

---

**Section 7 — Related Issues**

Search for related bugs and prior art:
- Grep the codebase for the error message, function name, or component name
- Search for TODO/FIXME/HACK comments near the suspected code location
- Check CHANGELOG or KNOWN_ISSUES files for prior mentions
- Note any related issues found (IDs, descriptions, code locations)

---

Output a structured bug report:

## Bug Investigation Report — {{BUG}}

### Summary
[One sentence: what breaks, where, under what condition]

### Reproduction Steps
[numbered steps]

### Environment
[full environment details]

### Expected Behaviour
[precise description]

### Actual Behaviour
[precise description with exact error text]

### Severity & Priority
- Severity: [using {{SEVERITY_LABELS}}]
- Priority: [P0/P1/P2/P3]
- Justification: [one sentence]

### Root Cause Hypothesis
- Hypothesis: [description]
- Confidence: High / Medium / Low
- Candidate files:
  - [path:line] — [why this is suspicious]

### Impact Assessment
- Users affected: [estimate]
- User segments: [description]
- Introduced in: [version or commit if findable]
- Data risk: Yes / No / Unknown
- Security implication: Yes / No / Unknown — [details if yes]

### Related Issues
[list of related bugs, TODOs, or code comments found]

Tools: Read, Grep, Glob
```

Gate: Print the bug report. Ask "Report looks correct? Proceed to WRITE TICKET? [y/N]"

---

### Stage 2 — WRITE TICKET
Spawn the `bug-triager` agent.

Agent prompt:
```
You are the bug-triager agent writing a formal bug ticket.

Bug: {{BUG}}
Ticket system: {{TICKET_SYSTEM}}
Severity labels: {{SEVERITY_LABELS}}

Investigation report from Stage 1 (first 2000 chars):
{{INVESTIGATION_OUTPUT}}

Read qa.config.md and workflow.config.md.

Write a complete, formally structured bug ticket formatted for {{TICKET_SYSTEM}}.
Use the exact field names and conventions that {{TICKET_SYSTEM}} uses.
(Jira uses "Affects Version", Linear uses "Cycle", GitHub Issues uses labels.)

Every field must be filled in — no empty fields. If a value is unknown,
write "Unknown — to be determined" rather than leaving it blank.

---

**Ticket format:**

Title: [Bug] [Component]: [one-sentence description of what breaks under what condition]

  Title rules:
  - Start with [Bug] prefix
  - Include the component or area in brackets
  - Describe the failure, not the fix
  - Under 80 characters
  - Example: "[Bug] Checkout: promo code applied after free shipping threshold causes negative total"

Type: Bug
Severity: [from Stage 1, using {{SEVERITY_LABELS}}]
Priority: [P0/P1/P2/P3 from Stage 1]
Affects Version: [version string from investigation, or "Unknown"]
Found In Environment: [environment from Stage 1]
Component/Area: [component label]
Assigned To: [Unassigned — to be triaged]
Labels: [bug, severity-N, component-name]

## Summary

[2–3 sentence paragraph that gives a developer everything they need to understand
the bug without reading the full ticket. Include: what feature is broken, under
what condition, what the user experiences. Do not pad — every word should add
information.]

## Steps to Reproduce

Preconditions:
- [list the required state: logged in as X, on page Y, with data condition Z]

Steps:
1. [single action]
2. [single action]
3. [single action — the triggering action]

Reproducibility: Always / Intermittent (X% of the time) / Rare

## Expected Result

[Precise description of what SHOULD happen. Reference acceptance criteria or
spec if available. Use present tense: "The cart total shows..."]

## Actual Result

[Precise description of what DOES happen. Include exact error text in quotes.
Use present tense: "The cart total shows -$4.99..."]

## Environment

- OS: [value]
- Browser / App Version: [value]
- Backend / API Version: [value]
- Feature Flags Active: [list or "none confirmed"]
- User Account Type: [value]
- Test Data Conditions: [specific data state that triggers the bug]

## Root Cause Hypothesis

[From Stage 1 investigation. Technical explanation of likely cause.
Include candidate file paths. Mark confidence level.]

## Impact

- Users affected: [estimate or "unknown — requires analytics query"]
- Affected user segment: [description]
- Introduced in: [version or commit if known, else "unknown"]
- Data integrity risk: Yes / No / Unknown
- Security implication: Yes / No — [details if yes]
- Workaround available: Yes / No — [describe workaround if yes]

## Evidence

[List the types of evidence that should be attached to this ticket.
Include placeholders so the reporter knows what to collect:]
- [ ] Screenshot showing actual behaviour at step N
- [ ] Browser/device console log output
- [ ] Network request/response trace (HAR file or browser DevTools screenshot)
- [ ] Server-side error log extract (if accessible)
- [ ] Video recording of reproduction (for intermittent bugs)

## Suggested Fix

[From Stage 1 root cause hypothesis. Write this only if confidence is Medium+.
If confidence is Low, omit this section and note "root cause under investigation".]

## Regression Test Required

Yes — a regression test must be written and added to the test suite before
this ticket can be closed. See Stage 3 of the bug-report workflow.

---

Print the complete formatted ticket, ready to be copy-pasted into {{TICKET_SYSTEM}}.

Tools: Read
```

Gate: Print "Ticket ready for {{TICKET_SYSTEM}}." Ask "Ticket looks correct? Proceed to WRITE REGRESSION TEST? [y/N]"

---

### Stage 3 — WRITE REGRESSION TEST
Spawn the `automation-engineer` agent.

Agent prompt:
```
You are the automation-engineer writing a regression test to prevent this bug
from reappearing undetected.

Bug: {{BUG}}
E2E framework: {{E2E_FRAMEWORK}}
Unit framework: {{UNIT_FRAMEWORK}}
Test directory: {{TEST_DIR}}

Investigation from Stage 1 (first 2000 chars):
{{INVESTIGATION_OUTPUT}}

Ticket from Stage 2 (first 1500 chars):
{{TICKET_OUTPUT}}

Read qa.config.md.
Read profiles/qa/rules/testing-standards.md.

Decide which test type to write based on the root cause:

- **E2E test with {{E2E_FRAMEWORK}}**: use for bugs that manifest in the UI,
  require browser interaction, or involve a multi-step user journey
- **Integration test**: use for bugs in API contracts, database queries,
  or service-to-service interactions
- **Unit test with {{UNIT_FRAMEWORK}}**: use for bugs in pure business logic,
  data transformations, validation rules, or calculation errors

Choose the LOWEST level that still catches the bug. A unit test that proves
the bug is fixed is better than an E2E test that does too.

**Test quality requirements — non-negotiable:**

Naming:
- Test name must describe the bug scenario, not the fix
- Format: `should [expected behaviour] when [bug condition]`
- Example: `should not produce negative cart total when promo code applied after free shipping threshold`
- Include the ticket ID in a comment on the line above the test

Determinism:
- The test must reproduce the bug deterministically (not flaky)
- If the original bug was intermittent, write the test to force the race condition
  or use a direct unit test of the underlying logic instead

Isolation:
- The test must be independent — runnable in any order, passes in isolation
- Set up all required state in beforeEach / test setup
- Clean up all created data in afterEach / test teardown
- No dependencies on other tests, no shared mutable state

Selectors (for E2E tests):
- Use data-testid attributes for element selection
- Never use CSS classes, element positions, or text content as selectors
- Never use sleep() — use explicit waits for conditions (network idle, element visible)
- Use Page Object Model — no selectors directly in the test body

Assertions:
- Assert the specific incorrect behaviour that the bug caused
- Assert both the intermediate state AND the final state if the bug involved state changes
- Use the most specific assertion available — prefer toEqual over toBeTruthy

Ticket reference:
- Add a comment immediately above the test: `// Regression: {{TICKET_SYSTEM}} [BUG-ID] — [one-line bug summary]`
- This makes it easy to trace test failures back to the original bug report

Write the complete test file, including:
- All imports
- Page object class (if E2E — in a separate file)
- Setup / teardown hooks
- The regression test(s)
- Any test fixtures or factory functions needed

Place the test file in the correct location:
- Unit tests: co-located with the source file or in {{TEST_DIR}}/unit/
- Integration tests: {{TEST_DIR}}/integration/
- E2E tests: {{TEST_DIR}}/e2e/ with page objects in {{TEST_DIR}}/e2e/pages/

Write ready-to-commit test code. No TODOs. No pseudocode.

Tools: Read, Write, Glob
```

---

## Bug Report Summary

After all stages complete, print:

```
════════════════════════════════════════════════════════
  Bug Report — {{BUG}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — INVESTIGATION
      Severity: [label]   Priority: [P0/P1/P2/P3]
      Impact: [user estimate] users affected
      Root cause confidence: High / Medium / Low
      Candidate file(s): [list if found]

  [✓] Stage 2 — TICKET
      Format: {{TICKET_SYSTEM}}-ready
      Title: [ticket title]
      Workaround available: Yes / No

  [✓] Stage 3 — REGRESSION TEST
      Test type: [E2E / Integration / Unit]
      Framework: [framework used]
      File written: [path]
      Test name: [test name]
════════════════════════════════════════════════════════

Next steps:
  [ ] Copy ticket from Stage 2 into {{TICKET_SYSTEM}}
  [ ] Assign ticket to correct component owner
  [ ] Add evidence (screenshots, logs) to ticket
  [ ] Commit regression test from Stage 3 to the test suite
  [ ] Verify regression test FAILS on current code (confirms it catches the bug)
  [ ] After fix: verify regression test PASSES
```

---

## Variables

- `{{BUG}}` = argument passed to this command (bug description or ID)
- `{{TICKET_SYSTEM}}` = from workflow.config.md (e.g. Jira, Linear, GitHub Issues)
- `{{SEVERITY_LABELS}}` = from qa.config.md (e.g. Critical/High/Medium/Low)
- `{{E2E_FRAMEWORK}}` = from qa.config.md (e.g. Playwright, Cypress, Appium)
- `{{UNIT_FRAMEWORK}}` = from qa.config.md (e.g. JUnit 5, pytest, Vitest, Jest)
- `{{TEST_DIR}}` = from qa.config.md (default: `tests/` or `__tests__/`)
- `{{INVESTIGATION_OUTPUT}}` = Stage 1 output (first 2000 chars)
- `{{TICKET_OUTPUT}}` = Stage 2 ticket text (first 1500 chars)
