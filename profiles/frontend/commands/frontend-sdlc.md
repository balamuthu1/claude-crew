Run a full frontend SDLC pipeline for the UI feature described in the argument.

You are the **orchestrator**. Do NOT implement features yourself — spawn dedicated
sub-agents for each stage. Each gets an isolated context window.

**For stages 4 and 5 (accessibility + performance): call `Agent` twice in a single message to run them in parallel.**

---

## Before starting

Read `frontend.config.md` and `workflow.config.md`. Extract:
- `{{FRAMEWORK}}` — e.g. React 18 + Next.js 14
- `{{LANGUAGE}}` — TypeScript (strict) / JavaScript
- `{{COMPONENT_LIB}}` — shadcn/ui, MUI, Ant Design, etc.
- `{{STATE_MGT}}` — zustand, redux, pinia, context, etc.
- `{{SERVER_STATE}}` — react-query, swr, apollo, etc.
- `{{STYLING}}` — tailwind, css-modules, styled-components, etc.
- `{{E2E_FRAMEWORK}}` — playwright, cypress, etc.
- `{{UNIT_FRAMEWORK}}` — vitest, jest, etc.
- `{{DESIGN_TOOL}}` — figma, sketch, etc.
- `{{API_STYLE}}` — REST, GraphQL, tRPC
- `{{AUTH_STRATEGY}}` — cookie, localStorage, provider, etc.
- `{{TICKET_SYSTEM}}` — from workflow.config.md
- `{{DOCS_PLATFORM}}` — from workflow.config.md

---

## Stage Definitions

### Stage 1 — ARCHITECT
Spawn the `frontend-architect` agent.

Agent prompt:
```
You are the frontend-architect agent.

Feature request: {{FEATURE}}

Read frontend.config.md and workflow.config.md.

Design the complete frontend architecture for this feature. Produce:

1. **Component hierarchy**
   Draw a tree of every component needed:
   - Page / Route components (top-level)
   - Feature components (domain-specific)
   - UI components (reusable, stateless)
   - Layout components (structural wrappers)
   For each: name, responsibility (one sentence), props surface, internal state vs lifted state.

2. **State management design**
   Using {{STATE_MGT}} and {{SERVER_STATE}}:
   - What state lives locally (useState / useReducer)?
   - What state is global / shared ({{STATE_MGT}} store)?
   - What state is server state ({{SERVER_STATE}} queries/mutations)?
   - Define the store shape (TypeScript interface) for any new global state.
   - Define query keys for any new server state.

3. **Routing plan**
   - New routes / paths required
   - Dynamic segments and their types
   - Protected routes (auth required)?
   - Middleware or layout nesting changes?

4. **API integration design**
   Using {{API_STYLE}}:
   - List every endpoint/query/mutation this feature consumes
   - Request shape (TypeScript type) and response shape
   - Error states to handle (4xx, 5xx, network timeout)
   - Optimistic update strategy (if applicable)
   - Caching / revalidation strategy for {{SERVER_STATE}}

5. **Data flow diagram** (ASCII)
   User action → component → state change → API call → UI update

6. **File structure**
   List every file to create, in the correct directory:
   ```
   src/
     features/{{feature-name}}/
       components/           # Feature-specific components
       hooks/                # Custom hooks
       api/                  # API service / query definitions
       store/                # State slice (if needed)
       types/                # TypeScript types
       __tests__/            # Unit tests
     pages/ or app/          # Route entry point(s)
   ```

7. **TypeScript contract**
   Define the core types / interfaces (not full implementations):
   - Props for each major component
   - API request/response types
   - Store state shape
   - Any discriminated union types (loading / success / error states)

8. **Design system alignment**
   Using {{COMPONENT_LIB}} and {{STYLING}}:
   - Which existing design tokens / components will be used
   - Any new design tokens or component variants needed
   - Spacing, colour, and typography references

9. **Performance considerations**
   - Code splitting: should this feature be lazy-loaded?
   - Memoization: which computations need useMemo / useCallback?
   - List virtualization: any long lists?
   - Image optimization: any images?

10. **Accessibility plan**
    - Semantic HTML structure
    - ARIA roles and labels required
    - Keyboard navigation flow
    - Focus management (especially modals / drawers)

Output: a complete architecture document the `frontend-developer` agent can implement from.
```
Tools: Read, Glob

Gate: Print architecture summary (component count, state design, API surface). Ask "Architecture looks good? Proceed to BUILD? [y/N]"

---

### Stage 2 — BUILD
Spawn the `frontend-developer` agent.

Agent prompt:
```
You are the frontend-developer agent.

Feature: {{FEATURE}}

Architecture from Stage 1:
{{ARCH_OUTPUT}}

Read frontend.config.md:
  - Framework: {{FRAMEWORK}}
  - Language: {{LANGUAGE}}
  - Component library: {{COMPONENT_LIB}}
  - State management: {{STATE_MGT}} + {{SERVER_STATE}}
  - Styling: {{STYLING}}
  - API style: {{API_STYLE}}
  - Auth strategy: {{AUTH_STRATEGY}}

Implement the full feature following the Stage 1 architecture exactly.

**Implementation checklist:**

TypeScript types (implement first):
- [ ] Props interface for every component
- [ ] API request/response types
- [ ] Store state interface
- [ ] Utility/helper types

API service layer:
- [ ] API client / fetcher for each endpoint
- [ ] Request types with runtime validation (Zod if available)
- [ ] Error normalisation (all errors → `AppError` shape)
- [ ] Auth header injection (using {{AUTH_STRATEGY}})
- [ ] Loading / success / error state types

State management ({{STATE_MGT}}):
- [ ] Store slice / atom / store definition
- [ ] Actions and selectors
- [ ] Server state: query / mutation definitions ({{SERVER_STATE}})
- [ ] Query key factory functions
- [ ] Optimistic update handlers (if applicable)

Components — for EACH component in the hierarchy:
- [ ] Stateless UI components: accept all data via props, emit callbacks
- [ ] Props typed with exact TypeScript interface (no `any`)
- [ ] Loading state: skeleton / spinner
- [ ] Error state: error message + retry action
- [ ] Empty state: empty list / no data message
- [ ] Responsive layout using {{STYLING}}
- [ ] Design tokens / {{COMPONENT_LIB}} primitives used correctly
- [ ] No hardcoded colours or spacing values
- [ ] All interactive elements keyboard-accessible (Tab, Enter, Space, Escape)
- [ ] Content descriptions on all non-text interactive elements
- [ ] Minimum touch target 44×44px / 48×48dp

Custom hooks:
- [ ] One hook per concern (data fetching, form state, UI state)
- [ ] Return consistent `{ data, isLoading, error }` shape
- [ ] Cleanup on unmount (abort controllers, subscriptions)
- [ ] Dependencies array correct — no stale closures

Route / page entry point:
- [ ] Code split with React.lazy / dynamic import (if applicable)
- [ ] Suspense boundary with fallback
- [ ] Auth guard applied if route requires authentication
- [ ] Meta tags / page title (if SSR/SSG)

**Security — mandatory checks:**
- No API keys or tokens hardcoded in any file
- Auth tokens NOT stored in localStorage (use {{AUTH_STRATEGY}} convention)
- All user-generated content rendered safely (no dangerouslySetInnerHTML unless sanitised)
- External links have rel="noopener noreferrer"
- No eval() or new Function() calls

**Output**: list every file created with its path.
```
Tools: Read, Write, Edit, Glob

Gate: Print list of files created. Ask "Build looks complete? Proceed to TEST? [y/N]"

---

### Stage 3 — TEST
Spawn the `automation-engineer` agent (if QA profile active) or `frontend-developer` agent.

Agent prompt:
```
You are writing tests for a frontend feature.

Feature: {{FEATURE}}

Implementation from Stage 2:
{{BUILD_OUTPUT}}

Read frontend.config.md:
  - Unit framework: {{UNIT_FRAMEWORK}}
  - E2E framework: {{E2E_FRAMEWORK}}

Write a complete test suite covering:

**Unit / Component tests ({{UNIT_FRAMEWORK}}):**
For each component:
- Renders without crashing (smoke test)
- Renders loading state correctly
- Renders error state correctly
- Renders empty state correctly
- Renders populated data correctly
- User interactions trigger correct callbacks
- Conditional rendering works for each branch

For each custom hook:
- Returns correct initial state
- Updates state correctly on async resolution
- Handles error case
- Cleans up on unmount

For each API service function:
- Makes request with correct URL, method, headers
- Parses success response correctly
- Handles 4xx error → correct AppError
- Handles 5xx error → correct AppError
- Handles network failure

**Integration tests:**
- Full user flow: start → action → expected UI outcome
- Form validation: invalid → error message shown; valid → submit triggered
- Optimistic update: UI updates immediately, reverts on error

**E2E tests ({{E2E_FRAMEWORK}}):**
Use page object / app action pattern — NO selectors in test files.
Use data-testid attributes for element selection.
No sleep() — explicit waits only.
Each test fully independent (no shared state).

- Happy path: complete user journey from entry to success
- Error path: server returns error → user sees error message
- Edge cases from risk analysis

Write:
1. `__tests__/` unit test files (co-located with source)
2. `e2e/` spec files (one per major flow)
3. `e2e/pages/` page object files
4. `e2e/fixtures/` test data fixtures
```
Tools: Read, Write, Edit, Glob

Gate: Print test summary (unit count, E2E count). Ask "Tests look good? Proceed to REVIEW + ACCESSIBILITY in parallel? [y/N]"

---

### Stage 4 — CODE REVIEW  ← spawn in PARALLEL with Stage 5
Spawn the `frontend-reviewer` agent.

Agent prompt:
```
You are the frontend-reviewer agent.

Feature: {{FEATURE}}

Files from Stage 2:
{{BUILD_OUTPUT}}

Read frontend.config.md and profiles/frontend/rules/typescript.md,
profiles/frontend/rules/css-standards.md, profiles/frontend/rules/frontend-security-guardrails.md.

Review ALL files produced in Stage 2. Check for:

**TypeScript quality**
- [ ] No `any` types — every value has a precise type
- [ ] Strict null checks respected — no unchecked access on nullable
- [ ] No non-null assertions (`!`) without justification comment
- [ ] Discriminated unions used for state (not booleans isLoading + isError)
- [ ] Generic types used correctly — no unnecessary type assertions
- [ ] Enums avoided — use const objects or literal union types

**Component quality**
- [ ] Single responsibility: each component does one thing
- [ ] Props interface is minimal — no prop drilling beyond 2 levels
- [ ] No business logic in presentational components
- [ ] State hoisted to correct level — not too high, not too low
- [ ] Memoization used only where measured, not preemptively
- [ ] No inline function definitions in JSX (performance trap)
- [ ] Keys on list items are stable IDs, not array indices
- [ ] useEffect dependencies are complete and correct

**State management ({{STATE_MGT}})**
- [ ] Store shape is flat and normalised
- [ ] No derived state stored — computed from selectors
- [ ] Selectors are memoized (reselect / zustand selectors)
- [ ] No direct state mutation

**API / data fetching ({{SERVER_STATE}})**
- [ ] Loading, error, and empty states all handled
- [ ] Stale time and cache time configured appropriately
- [ ] Mutations invalidate correct query keys
- [ ] Error boundary wraps async data sections

**Styling ({{STYLING}})**
- [ ] No magic numbers — use design tokens / spacing scale
- [ ] No hardcoded colours — use CSS variables / theme tokens
- [ ] Responsive: mobile-first, defined breakpoints
- [ ] No z-index wars — z-index values documented
- [ ] No `!important` without comment

**Security**
- [ ] No dangerouslySetInnerHTML without DOMPurify sanitisation
- [ ] No localStorage for sensitive tokens
- [ ] External links have rel="noopener noreferrer"
- [ ] Content-Security-Policy compatible (no inline scripts)
- [ ] No sensitive data logged to console

Output format:
## Frontend Code Review

### Critical (incorrect behaviour or security risk)
- [FILE:LINE] Issue — Impact — Fix

### Major (performance or type safety gap)
- [FILE:LINE] Issue — Fix

### Minor (style or convention)
- [FILE:LINE] Suggestion

### Approved patterns
- [FILE:LINE] Good practice worth noting
```
Tools: Read, Grep, Glob

---

### Stage 5 — ACCESSIBILITY AUDIT  ← spawn in PARALLEL with Stage 4
Spawn the `accessibility-auditor` agent.

Agent prompt:
```
You are the accessibility-auditor agent.

Feature: {{FEATURE}}

Files from Stage 2:
{{BUILD_OUTPUT}}

Read profiles/frontend/rules/accessibility.md.

Audit every component and page against WCAG 2.1 Level AA.

**Perceivable**
- [ ] All non-text content has a text alternative (alt, aria-label, aria-labelledby)
- [ ] Images that are purely decorative have alt="" and role="presentation"
- [ ] Colour is not the only means of conveying information
- [ ] Text colour contrast ≥ 4.5:1 for normal text, ≥ 3:1 for large text (18px+ or 14px bold+)
- [ ] UI component contrast ≥ 3:1 against adjacent colours
- [ ] Responsive text: no fixed px font sizes that prevent browser zoom

**Operable**
- [ ] All functionality reachable by keyboard (Tab, Shift+Tab, Enter, Space, Escape, Arrow keys)
- [ ] No keyboard trap — user can always navigate away
- [ ] Focus indicator visible (not removed with outline:none without replacement)
- [ ] Skip link present on pages with nav blocks before main content
- [ ] Minimum touch target: 44×44 CSS px for interactive elements
- [ ] No time limits or adequate time-limit controls

**Understandable**
- [ ] lang attribute set on <html>
- [ ] Labels associated with all form inputs (htmlFor / aria-labelledby)
- [ ] Error messages describe the problem AND suggest a fix
- [ ] Required fields marked (aria-required or required attribute)
- [ ] Input autocomplete attributes set for common fields (name, email, etc.)

**Robust**
- [ ] Semantic HTML elements used (button not div, nav not div, etc.)
- [ ] ARIA roles used only when native semantics are insufficient
- [ ] ARIA attributes are valid and complete (no aria-expanded without aria-controls)
- [ ] Dynamic content changes announced (aria-live or role="status")
- [ ] Modal dialogs: focus trapped, Escape closes, focus returns to trigger
- [ ] Custom widgets follow ARIA authoring practices (menu, combobox, etc.)

**Interactive pattern audit (check each used in this feature)**
- Dropdown / Combobox: up/down arrows navigate, Enter selects, Escape closes
- Modal / Dialog: focus trap active, aria-modal="true", aria-labelledby set
- Tab panel: arrow keys navigate tabs, selected panel visible, aria-selected
- Tooltip: triggered by focus AND hover, role="tooltip", referenced by aria-describedby
- Form: all inputs labelled, errors associated via aria-describedby, no colour-only validation

Output:
## Accessibility Audit — {{FEATURE}}

### Critical (WCAG failure — blocks users)
- [FILE:LINE] Criterion — Issue — Fix

### Major (significant barrier)
- [FILE:LINE] Criterion — Issue — Fix

### Minor (best practice)
- [FILE:LINE] Suggestion

### Passed checks
- [FILE:LINE] Criterion — Compliant implementation noted
```
Tools: Read, Grep, Glob

After both Stage 4 and Stage 5 complete, print their combined outputs.
Gate: Ask "Proceed to FINAL SUMMARY? [y/N]"

---

## Frontend SDLC Summary Report

After all stages complete, print:

```
════════════════════════════════════════════════════════
  Frontend SDLC — {{FEATURE}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — ARCHITECT     Components: N, API surface: N endpoints
  [✓] Stage 2 — BUILD         Files created: N
  [✓] Stage 3 — TEST          Unit: N, E2E: N
  [✓] Stage 4 — CODE REVIEW   Critical: N, Major: N, Minor: N
  [✓] Stage 5 — ACCESSIBILITY Critical: N, Major: N, Minor: N
════════════════════════════════════════════════════════

Code review action items:
  [list Critical and Major findings]

Accessibility action items:
  [list Critical findings]

Next steps:
  [ ] Fix Critical/Major review findings
  [ ] Fix Critical accessibility issues
  [ ] Run {{E2E_FRAMEWORK}} suite end-to-end
  [ ] Open PR — reference ticket in {{TICKET_SYSTEM}}
```

---

## Variables

- `{{FEATURE}}` = argument passed to this command
- `{{ARCH_OUTPUT}}` = Stage 1 output (first 3000 chars)
- `{{BUILD_OUTPUT}}` = Stage 2 file list + key implementation notes
- `{{FRAMEWORK}}`, `{{LANGUAGE}}`, `{{COMPONENT_LIB}}`, `{{STATE_MGT}}`,
  `{{SERVER_STATE}}`, `{{STYLING}}`, `{{E2E_FRAMEWORK}}`, `{{UNIT_FRAMEWORK}}`,
  `{{DESIGN_TOOL}}`, `{{API_STYLE}}`, `{{AUTH_STRATEGY}}` = from frontend.config.md
- `{{TICKET_SYSTEM}}`, `{{DOCS_PLATFORM}}` = from workflow.config.md
