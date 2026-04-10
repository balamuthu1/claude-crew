Review or define product metrics for the feature or area described in the argument.

You are the **orchestrator**. Do NOT define metrics yourself — spawn dedicated sub-agents.

**Stages 2 and 3 (event schema + instrumentation): call `Agent` twice in a single message to run them in parallel.**

---

## Before starting

Read `product.config.md` and `workflow.config.md`. Extract:
- `{{ANALYTICS_PLATFORM}}` — amplitude, mixpanel, ga4, posthog, segment, etc.
- `{{TICKET_SYSTEM}}` — from workflow.config.md
- `{{DOCS_PLATFORM}}` — from workflow.config.md

---

## Stage Definitions

### Stage 1 — METRIC FRAMEWORK
Spawn the `metrics-analyst` agent.

Agent prompt:
```
You are the metrics-analyst agent.

Feature / area: {{FEATURE}}
Analytics platform: {{ANALYTICS_PLATFORM}}

Read product.config.md.

Define a complete metric framework. If metrics already exist (check for a metrics doc or
analytics ticket), review them for completeness and correctness instead of creating new ones.

---

1. PRIMARY METRIC — the ONE number that determines success or failure

   Name: [metric name]
   Type: Ratio | Count | Duration | Revenue | Retention
   Definition: [precise business definition — no ambiguity]
   Numerator: [exact count / sum that goes on top]
   Denominator: [exact count / sum that goes on bottom, if ratio]
   Calculation: [exact formula, e.g. conversions / unique_visitors × 100]
   Unit: [%, users, seconds, $, events]
   Measurement window: [30-day rolling | weekly | session-level]
   Current baseline: [value, or "TBD — measure N weeks before launch"]
   Target: [absolute value OR % change, e.g. "increase from 12% to 15%"]
   Target timeline: [e.g. "30 days post full rollout"]
   Why this is the primary metric: [one sentence justification]

---

2. SECONDARY METRICS (2-4 leading indicators)

   For each: name, definition, why it's a leading indicator for the primary metric.
   Leading indicators are things you can move quickly that predict the primary will follow.
   Example: if primary = paid conversion rate, a leading indicator might be "trial feature usage rate".

---

3. GUARDRAIL METRICS (2-3 metrics that must NOT regress)

   For each: name, current value, minimum acceptable value, why regression = problem.
   Guardrails catch unintended harm: a feature that improves one metric by harming another.
   Examples: core retention, support ticket volume, page load time, error rate.

---

4. ANTI-METRICS (explicitly NOT optimising for)

   List 1-3 metrics that could be gamed, or that conflict with actual user value.
   Rationale: prevents the team from optimising for vanity metrics.
   Example: "NOT optimising for: session duration — we want fast task completion, not engagement."

---

5. NORTH STAR ALIGNMENT

   How does this feature's primary metric connect to the product/company North Star metric?
   Draw the causal chain: [this feature's metric] → [intermediate metric] → [North Star]

---

6. METRIC RISKS

   For each primary and secondary metric:
   - Gaming risk: could this metric be inflated artificially?
   - Confounding risk: what else could move this metric besides this feature?
   - Measurement lag: how long before we see a real signal? (important for deciding launch gate)

Output: complete metric framework document.
```
Tools: Read, Glob

Gate: Print metric framework. Ask "Metrics make sense? Proceed to EVENT SCHEMA + INSTRUMENTATION in parallel? [y/N]"

---

### Stage 2 — EVENT SCHEMA  ← spawn in PARALLEL with Stage 3
Spawn the `metrics-analyst` agent.

Agent prompt:
```
You are the metrics-analyst agent focused on analytics event design.

Feature / area: {{FEATURE}}
Analytics platform: {{ANALYTICS_PLATFORM}}
Metric framework from Stage 1: {{METRICS_OUTPUT}}

Design every analytics event needed to measure the metrics from Stage 1.

---

NAMING CONVENTIONS (apply to all events):

Event names:
  - Format: snake_case verb_noun (e.g. button_clicked, form_submitted, page_viewed)
  - Past tense for completed actions: item_added, checkout_completed
  - Present tense for impressions: modal_viewed, banner_displayed
  - Do NOT use: "click_x", "pressed_button", "did_thing" — must describe the specific action

Property names:
  - snake_case always
  - Boolean properties: is_* or has_* prefix (e.g. is_logged_in, has_premium_plan)
  - ID properties: *_id suffix (e.g. user_id, product_id)
  - Timestamp properties: *_at suffix (e.g. created_at) — ISO 8601 format
  - Never send raw PII — always anonymise/hash before sending

---

For EACH user action to track, document:

EVENT: event_name_here
TRIGGER: [exact user action — be specific: "User clicks the 'Add to Cart' button on the product detail page"]
WHERE TO FIRE: [component name / file / function — so engineer knows where to put the code]

PROPERTIES:
| Property | Type | Required | PII | Description | Example value |
|----------|------|----------|-----|-------------|---------------|
| user_id | string | Yes | No | Anonymised user identifier | "usr_abc123" |
| session_id | string | Yes | No | Current session identifier | "sess_xyz789" |
| [feature context] | [type] | [req] | [pii] | [description] | [value] |

PII HANDLING:
  [List any PII present in properties]
  [Specify anonymisation method: hash, truncate, omit]
  [Confirm: no email, no name, no phone, no IP sent in raw form]

---

EVENTS TO DEFINE (at minimum — add more as needed):

Page/screen views:
  - page_viewed for each new page/route introduced

Conversion funnel events (in order):
  - One event per step in the key user journey

Success events:
  - The event that fires when the user completes the primary goal

Error events (analytics for key errors, separate from logging):
  - error_encountered with error_type property

Feature discovery events:
  - How do we know users found the feature?
  - How do we know users understood it?

---

FUNNEL DEFINITION:
Define the ordered event sequence that represents a conversion:
  Step 1: [event_name] — [what it means]
  Step 2: [event_name]
  ...
  Conversion: [final event]

Drop-off analysis: we will measure conversion rate at each step.

---

Output: complete event catalog formatted as a table for {{DOCS_PLATFORM}}.
List total event count at the end.
```
Tools: Read

---

### Stage 3 — INSTRUMENTATION PLAN  ← spawn in PARALLEL with Stage 2
Spawn the `metrics-analyst` agent.

Agent prompt:
```
You are the metrics-analyst agent focused on implementation guidance.

Feature / area: {{FEATURE}}
Analytics platform: {{ANALYTICS_PLATFORM}}
Metric framework from Stage 1: {{METRICS_OUTPUT}}

Write the engineering implementation plan for instrumentation.

---

1. SDK SETUP CHECKLIST (check what's already done vs what's needed):
   - [ ] {{ANALYTICS_PLATFORM}} SDK installed and initialised
   - [ ] SDK version is current (check changelog for breaking changes)
   - [ ] User identification: identify() called after login, not before
   - [ ] Anonymous tracking: anonymous_id set before identify()
   - [ ] Super properties / group traits set correctly (plan, region, etc.)
   - [ ] GDPR/CCPA: events do NOT fire if user has opted out of analytics
   - [ ] Bot filtering: bot traffic excluded from analytics (check SDK docs)

2. PLATFORM-SPECIFIC NOTES for {{ANALYTICS_PLATFORM}}:

   For Amplitude:
   - Use track() for events, identify() for user properties, setGroup() for accounts
   - Session replay: is it enabled? Are sensitive fields masked?
   - Funnel analysis: confirm event names match exactly (case-sensitive)

   For Mixpanel:
   - Use track() for events, people.set() for user properties
   - Super properties: use register() for properties that apply to all events
   - Distinct ID: call alias() to link anonymous to identified user on first login

   For Google Analytics 4 (GA4):
   - Use gtag('event', ...) or dataLayer.push(...)
   - Custom dimensions must be created in GA4 admin before they appear in reports
   - Enhanced measurement: review what GA4 tracks automatically vs custom events

   For PostHog:
   - posthog.capture() for events, posthog.identify() for users
   - Feature flags: use posthog.isFeatureEnabled() for experiment assignment
   - Session recording: confirm sensitive inputs are masked

3. INSTRUMENTATION CHECKLIST (engineering ticket content):
   For each event defined in Stage 2:
   - [ ] [event_name]: fire on [trigger] in [component/file] — properties: [list]

4. BASELINE MEASUREMENT PLAN:
   "Before launching to users, instrument the existing flow and collect data for [N] weeks.
   Measure: [list baseline metrics]
   Gate: proceed to launch only after N weeks of baseline data confirms: [baseline values]."

5. A/B TEST SETUP (if applicable):
   - Control: [what the control group experiences]
   - Treatment: [what the test group experiences]
   - Assignment: [feature flag / random split / cohort-based]
   - Sample size: to detect [X]% change in [metric] with 80% power, need N users per group
   - Minimum experiment duration: N weeks (to account for weekly traffic patterns)
   - Analysis: [t-test / chi-square / Bayesian] — use the method {{ANALYTICS_PLATFORM}} recommends
   - Decision criteria: ship if [primary metric] improves by [threshold] AND [guardrail] doesn't regress

Output: complete instrumentation plan.
```
Tools: Read

After both Stage 2 and Stage 3 complete, print their combined outputs.
Gate: Ask "Proceed to DOCUMENTATION + TICKET? [y/N]"

---

### Stage 4 — DOCUMENTATION + TICKET
Spawn the `metrics-analyst` agent.

Agent prompt:
```
You are the metrics-analyst agent.

Feature: {{FEATURE}}
Analytics platform: {{ANALYTICS_PLATFORM}}
Ticket system: {{TICKET_SYSTEM}}
Docs platform: {{DOCS_PLATFORM}}
All previous stage outputs: {{METRICS_OUTPUT}} {{EVENTS_OUTPUT}}

Produce:

1. **Analytics documentation page** for {{DOCS_PLATFORM}}:
   - Metric definitions (copy from Stage 1)
   - Event catalog (table from Stage 2)
   - Dashboard setup guide: how to build the KPI dashboard in {{ANALYTICS_PLATFORM}}
     List: which events + properties to use for each metric
   - Alerting guide: which metric thresholds trigger an alert? How to set them up?

2. **Engineering ticket** for {{TICKET_SYSTEM}}:
   Title: "Instrument analytics events: {{FEATURE}}"
   Type: Task | Priority: P1
   Body:
     - Links to this doc
     - SDK setup checklist (from Stage 3)
     - Instrumentation checklist (one checkbox per event)
     - Baseline measurement plan
     - QA acceptance criteria: "Verify N events fire correctly using {{ANALYTICS_PLATFORM}} debugger"

3. **QA checklist for analytics**:
   - [ ] Open {{ANALYTICS_PLATFORM}} event debugger / live view
   - [ ] Trigger each user action in the app
   - [ ] Confirm each event fires with correct name
   - [ ] Confirm each event has required properties with correct values
   - [ ] Confirm no PII in event properties
   - [ ] Confirm events do NOT fire when user has opted out
   - [ ] Confirm funnel events fire in correct order
```
Tools: Read, Write

---

## Metrics Review Summary Report

After all stages complete, print:

```
════════════════════════════════════════════════════════
  Metrics Review — {{FEATURE}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — METRIC FRAMEWORK Primary: 1, Secondary: N, Guardrails: N
  [✓] Stage 2 — EVENT SCHEMA     Events defined: N, PII fields flagged: N
  [✓] Stage 3 — INSTRUMENTATION  Checklist: N items, A/B test: Yes/No
  [✓] Stage 4 — DOCUMENTED       Docs + ticket ready
════════════════════════════════════════════════════════

Primary metric: [name] → target [value] by [date]
Funnel: [Step 1] → [Step 2] → ... → [Conversion event]
Baseline measurement needed: N weeks before launch

PII fields requiring anonymisation: [list]
Tickets to create in {{TICKET_SYSTEM}}: [list]
```

---

## Variables

- `{{FEATURE}}` = argument passed to this command
- `{{METRICS_OUTPUT}}` = Stage 1 output (first 2000 chars)
- `{{EVENTS_OUTPUT}}` = Stage 2 output summary
- `{{ANALYTICS_PLATFORM}}` = from product.config.md
- `{{TICKET_SYSTEM}}`, `{{DOCS_PLATFORM}}` = from workflow.config.md
