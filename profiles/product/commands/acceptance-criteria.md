---
description: Write complete, testable acceptance criteria for a story or feature. 2-stage workflow — write AC, quality check. Argument is a user story, feature description, or ticket ID.
---

Run a full acceptance criteria workflow for the story or feature described in the argument.

You are the **orchestrator**. Do NOT write the AC yourself — spawn dedicated sub-agents
for each stage. Each gets an isolated context window.

---

## Before Starting

Read `product.config.md` and `workflow.config.md`. Extract these variables before spawning any agent:

- `{{FEATURE}}` — argument passed to this command (story text, feature description, or ticket ID)
- `{{AC_FORMAT}}` — `gherkin` (Given/When/Then scenarios) or `checklist` (- [ ] observable criteria)
- `{{TICKET_SYSTEM}}` — `jira`, `linear`, `github`, `shortcut`, or other
- `{{STORY_FORMAT}}` — `user-story` or `job-story` (used to understand the story's intent)
- `{{DOCS_PLATFORM}}` — where to paste the final AC output

If the argument is a ticket ID, read the ticket from context (if available) or note that
the AC will be written based on the description provided.

If `product.config.md` does not exist, default to:
- `{{AC_FORMAT}}` = `gherkin`
- `{{TICKET_SYSTEM}}` = `jira`

---

## Stage 1 — WRITE ACCEPTANCE CRITERIA

Spawn the `prd-author` agent.

Agent prompt:
```
You are the prd-author agent.

Story / Feature: {{FEATURE}}
AC format: {{AC_FORMAT}}
Story format: {{STORY_FORMAT}}
Ticket system: {{TICKET_SYSTEM}}

Your task: write a complete, exhaustive set of acceptance criteria for this story
or feature. The AC must be testable by a QA engineer without any clarifying questions
to the PM. If a QA engineer must ask "what counts as success here?" the criterion
is not good enough — rewrite it.

---

RULES THAT APPLY TO ALL AC REGARDLESS OF FORMAT:

1. Every criterion tests ONE thing. Never combine two outcomes with "and" in a single
   criterion or scenario.

2. Use concrete values, not vague adjectives:
   WRONG: "the form loads quickly"
   RIGHT: "the form loads in under 2 seconds on a 4G connection"

   WRONG: "shows an appropriate error message"
   RIGHT: "shows the error message: 'Please enter a valid email address'"

   WRONG: "users can search"
   RIGHT: "a user who enters 'john' in the search field sees all contacts whose
           first name, last name, or email contains 'john' (case-insensitive)"

3. Test observable outcomes — what the user sees or can do — not internal system state:
   WRONG: "the database record is updated"
   RIGHT: "the user sees a success toast: 'Changes saved'"

4. Do not test implementation. AC is about WHAT, not HOW:
   WRONG: "the API returns a 200 status"
   RIGHT: "the user's profile is updated and the new values are displayed"

---

WRITE AC IN {{AC_FORMAT}} FORMAT:

[IF {{AC_FORMAT}} IS gherkin:]

Write every scenario using strict Gherkin syntax. Organize into named scenario groups.

SCENARIO GROUP: Happy Path
—————————————————————————

Scenario: [Descriptive name — describes the flow, not the feature]
  Given [Initial state / precondition — must be a state, not an action.
         "the user is logged in" is a state.
         "the user logs in" is an action — use When for actions.]
  When  [User action — specific and observable. One action per When.]
  Then  [Expected outcome — what the user sees, receives, or can do.
         Quote exact UI text where it is fixed. Include element names.]
  And   [Additional outcome from the same action, if necessary.
         Only use And if truly part of the same scenario — do not stack
         unrelated outcomes here.]

[Write all scenarios for the core happy path — the user successfully accomplishes
the primary job of this story.]

---

SCENARIO GROUP: Validation and Form Input (if applicable)
——————————————————————————————————————————————————————————

Scenario: Required field left empty
  Given [user is on the form / at the relevant step]
  When  the user submits the form without entering [field name]
  Then  an inline error appears below [field name]: "[exact error message text]"
  And   the form is not submitted

Scenario: Invalid [field type] format
  Given [user is on the form]
  When  the user enters "[example invalid value]" in the [field name] field
  Then  an inline error appears: "[exact error message text]"

Scenario: Input at maximum character limit
  Given [user is in the [field name] field]
  When  the user has typed [N] characters (the maximum)
  Then  the field does not accept additional characters
  And   a character counter shows "0 characters remaining"

Scenario: XSS attempt in text input
  Given [user is on the form]
  When  the user enters "<script>alert('xss')</script>" in [field name]
  Then  the input is displayed as plain text: "<script>alert('xss')</script>"
  And   no script is executed

[Add more validation scenarios as relevant to this specific story.]

---

SCENARIO GROUP: Error States
————————————————————————————

Scenario: Network connection lost during action
  Given [the user is performing the primary action of this story]
  When  the network connection is unavailable
  Then  the user sees an error message: "[error text — should not expose internals]"
  And   a "Try again" button is displayed
  And   no data is partially saved or corrupted

Scenario: Server error (5xx)
  Given [the user triggers the server call]
  When  the server returns a 5xx error
  Then  the user sees a generic error message that does not expose stack traces
        or internal error codes
  And   the user can retry the action

Scenario: Resource not found
  Given [the user navigates to or requests a resource that does not exist]
  Then  the user sees a "not found" state with a clear description and a way
        to navigate back to a valid screen

Scenario: Unauthorised access attempt
  Given a user who is not logged in (or lacks the required permission)
  When  they attempt to access [the protected resource or action]
  Then  they are redirected to [the login page / a permission error screen]
  And   after login (or with correct permissions), they are returned to
        their original destination

[Add server-specific error scenarios relevant to this story's API calls.]

---

SCENARIO GROUP: Edge Cases
——————————————————————————

Scenario: Empty state — no data exists
  Given [the user navigates to the screen / section]
  And   there is no existing [data type] to display
  Then  an empty state is shown with:
        - An illustration or icon (not a blank screen)
        - A message explaining why it is empty: "[example message]"
        - A clear call to action: "[example CTA text]"

Scenario: Single item
  Given [there is exactly one [item] in the list / result set]
  Then  [describe how a list of one renders — no pagination, correct pluralisation, etc.]

Scenario: Large data set / pagination
  Given [there are more than [N] [items] to display]
  Then  [pagination controls / infinite scroll / load-more behaviour is shown]
  And   [performance: the page renders in under [N] seconds even with [N] items]

Scenario: Long text content
  Given [a [field/item] contains [N] characters (at the display limit)]
  Then  the text is truncated at [N] characters with an ellipsis ("...")
  And   a tooltip or expand control shows the full text on [hover/tap]

[Add edge cases specific to the data model and UI of this story.]

---

SCENARIO GROUP: Accessibility
———————————————————————————————

Scenario: Keyboard navigation
  Given a user who does not use a mouse
  When  they navigate the [feature UI] using only Tab, Shift+Tab, Enter, and Arrow keys
  Then  every interactive element is reachable and activatable via keyboard
  And   the visible focus indicator is never lost between steps

Scenario: Screen reader announces state changes
  Given a user using a screen reader (VoiceOver / TalkBack / NVDA)
  When  [a dynamic state change occurs — e.g. error appears, loading completes,
         item is added to list]
  Then  the screen reader announces the new state without requiring the user
        to navigate away from their current position

Scenario: Colour contrast
  Given the [primary text / interactive element] on [background colour]
  Then  the colour contrast ratio meets WCAG AA minimum:
        - Normal text (< 18pt): ≥ 4.5:1
        - Large text (≥ 18pt or bold ≥ 14pt): ≥ 3:1

---

[IF {{AC_FORMAT}} IS checklist:]

Organise criteria into labelled groups. Each criterion must:
- Start with a verb (Shows, Displays, Allows, Prevents, Redirects, Returns,
  Navigates, Updates, Sends, Validates, Truncates, Announces)
- Describe an observable outcome (what the user sees or can do)
- Use concrete values (exact text, specific numbers, named elements)
- Be independently verifiable (a QA engineer can write a single test for it)

**Happy Path**
- [ ] [Primary success criterion — user can complete the core job end-to-end]
- [ ] [Secondary success criterion — result is visible to the user]
- [ ] [Persistence criterion — the state survives a page refresh / app restart
      if applicable]

**Validation** (if the story involves input)
- [ ] Shows inline error "[exact text]" below [field name] when [field] is submitted empty
- [ ] Shows inline error "[exact text]" when [field] contains [invalid input type]
- [ ] Prevents submission of the form until all required fields contain valid input
- [ ] Enforces [N]-character limit on [field name] — does not accept further input at limit
- [ ] Displays plain text output for inputs containing HTML/script tags (XSS safe)
- [ ] [Add field-specific validation criteria]

**Error States**
- [ ] Shows "[exact error message]" when the network is unavailable, with a "Try again" button
- [ ] Shows a generic error (no stack trace, no internal codes) when the server returns 5xx
- [ ] Shows a "not found" state when the requested resource does not exist, with
      a navigation link back to [screen]
- [ ] Redirects to [login / permission error screen] when an unauthenticated user attempts
      to access [protected resource]
- [ ] [Add API/service-specific error criteria]

**Edge Cases**
- [ ] Shows the empty state design (illustration + message + CTA) when there is no
      [data type] to display
- [ ] Renders correctly with exactly one [item] (no plural text, no pagination)
- [ ] Shows pagination / load-more control when the list exceeds [N] items
- [ ] Truncates [field/item] text at [N] characters with "..." and shows full text
      on [hover/tap]
- [ ] [Add feature-specific edge case criteria]

**Accessibility**
- [ ] All interactive elements are keyboard navigable (Tab / Shift+Tab / Enter)
- [ ] Visible focus indicator is present on every focused element
- [ ] Screen reader announces [specific state change] when [trigger event] occurs
- [ ] Colour contrast ratio meets WCAG AA: ≥ 4.5:1 for normal text,
      ≥ 3:1 for large text
- [ ] Touch targets on mobile are at minimum 44×44pt / 48×48dp

---

AFTER WRITING ALL AC:

Count your criteria by type:
- Happy path scenarios/criteria: [N]
- Validation scenarios/criteria: [N]
- Error state scenarios/criteria: [N]
- Edge case scenarios/criteria: [N]
- Accessibility scenarios/criteria: [N]
- Total: [N]

Flag any of the following if they are missing and are clearly needed for this story:
- Empty state (if the story shows a list or result)
- Pagination (if the list could exceed 10-20 items)
- 5xx error handling (if the story makes a server call)
- Auth/permission guard (if the story involves protected data)
- Accessibility (always required)
```
Tools: Read

Gate: Print AC count by scenario type. Ask:
"AC looks complete? Proceed to QUALITY CHECK? [y/N]"

---

## Stage 2 — QUALITY CHECK

Spawn the `product-manager` agent. Pass the full Stage 1 AC output (first 3000 chars) as `{{AC_DRAFT}}`.

Agent prompt:
```
You are the product-manager agent.

Story / Feature: {{FEATURE}}
AC format: {{AC_FORMAT}}
Ticket system: {{TICKET_SYSTEM}}

Draft AC from Stage 1:
{{AC_DRAFT}}

Your task: perform a ruthless quality review. Your job is to find every criterion
that would fail in a real QA cycle — and fix it before it gets there.

Apply these checks to EVERY criterion or scenario:

CHECK 1 — TESTABLE
Question: "Can a QA engineer write a single automated test for this criterion
without asking anyone for clarification?"
If no → it is not testable. Rewrite it.

Common untestable patterns and fixes:
- "loads quickly" → "loads in under [N] seconds on [connection type]"
- "shows an error" → "shows the error message: '[exact text]'"
- "works correctly" → remove. Write what correct means in observable terms.
- "is user-friendly" → not testable. Delete.
- "handles edge cases" → not testable. Name the edge case.

CHECK 2 — UNAMBIGUOUS
Question: "Could two engineers independently implement this and produce
different behaviour, both claiming they met the criterion?"
If yes → it is ambiguous. Add the specifics that remove the ambiguity.

Common ambiguous patterns and fixes:
- "the list is sorted" → "the list is sorted alphabetically A-Z by [field name]"
- "the user is notified" → "the user sees a toast notification: '[text]'"
- "the data is saved" → "the user sees the updated value immediately without
  refreshing the page, and the value persists after page refresh"

CHECK 3 — OBSERVABLE OUTCOME (not internal state)
Question: "Does this criterion describe what the USER sees or can DO,
rather than what the system does internally?"
If it describes internals → step back to the observable outcome.

WRONG: "the API call includes the user_id parameter"
RIGHT: "the user's personalised content is displayed correctly after login"

WRONG: "the event is fired to the analytics platform"
RIGHT: (this is an instrumentation criterion — move it to the engineering
ticket's instrumentation checklist, not user-facing AC)

CHECK 4 — SINGLE OUTCOME
Question: "Does this criterion test exactly ONE thing?"
If it uses "and" to combine two verifiable outcomes → split it into two criteria.

CHECK 5 — COVERAGE GAPS
Review the full AC set for missing coverage:
- Is there a happy path scenario? (yes/no — add if missing)
- Are required fields validated? (yes/no — add if missing)
- Is the empty state defined? (yes/no — add if this story shows a list)
- Is there a network error scenario? (yes/no — add if story makes API calls)
- Is there an auth/permission guard? (yes/no — add if story accesses protected data)
- Are accessibility criteria present? (yes/no — always add if missing)

After your review, output:

QUALITY REPORT:
Criteria reviewed: [N]
Criteria passing all checks: [N]
Criteria rewritten: [N]
  - [criterion identifier]: [original] → [rewritten version]
Criteria split: [N]
  - [criterion identifier] split into: [new criterion A] / [new criterion B]
Criteria deleted (not testable, not observable): [N]
  - [criterion identifier]: [reason deleted]
Coverage gaps filled: [list any scenarios/criteria added]

THEN: output the FINAL, POLISHED AC ready to paste into {{TICKET_SYSTEM}}.

The final output must:
- Be complete (every scenario/criterion including new ones you added)
- Be properly formatted in {{AC_FORMAT}}
- Have no vague language, no combined outcomes, no internal-state descriptions
- Be organized by group (Happy Path, Validation, Errors, Edge Cases, Accessibility)
- Include the count summary at the bottom:
  Total: [N] | Happy: [N] | Validation: [N] | Errors: [N] | Edge: [N] | A11y: [N]
```
Tools: Read

---

## Summary Report

After both stages complete, print:

```
════════════════════════════════════════════════════════
  Acceptance Criteria — {{FEATURE}}
════════════════════════════════════════════════════════
  Format: {{AC_FORMAT}}
  Total criteria: N
    Happy path:  N
    Validation:  N
    Error states:N
    Edge cases:  N
    Accessibility:N
  Rewritten for clarity: N
  Coverage gaps filled:  N
════════════════════════════════════════════════════════

Ready to paste into {{TICKET_SYSTEM}}.

Quality flags resolved:
  [ ] All criteria independently testable
  [ ] No vague language ("fast", "easy", "works", "properly")
  [ ] All outcomes observable (user sees / user can — not system internals)
  [ ] No compound criteria (each criterion tests one thing)
  [ ] Empty state covered: [yes/N/A]
  [ ] Error states covered: [yes/N/A]
  [ ] Accessibility criteria: [yes]
════════════════════════════════════════════════════════
```

---

## Variables

- `{{FEATURE}}` = argument passed to this command (story text, feature description, or ticket ID)
- `{{AC_DRAFT}}` = Stage 1 agent output (first 3000 chars)
- `{{AC_FORMAT}}`, `{{TICKET_SYSTEM}}`, `{{STORY_FORMAT}}`, `{{DOCS_PLATFORM}}` = from product.config.md / workflow.config.md
