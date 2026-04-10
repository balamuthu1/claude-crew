Review frontend code for quality, security, and accessibility. Argument is one or more file paths, a glob pattern, or a feature name.

You are the **orchestrator**. Do NOT review code yourself — spawn dedicated sub-agents. All three stages run sequentially; the accessibility audit benefits from seeing the code review findings first.

---

## Before starting

Read `frontend.config.md` and `workflow.config.md`. Extract:
- `{{FRAMEWORK}}` — react, vue, angular, svelte, etc.
- `{{LANGUAGE}}` — TypeScript (strict) / JavaScript
- `{{COMPONENT_LIB}}` — shadcn/ui, MUI, Ant Design, etc.
- `{{STYLING}}` — tailwind, css-modules, styled-components, etc.
- `{{SERVER_STATE}}` — react-query, swr, apollo, etc.
- `{{TICKET_SYSTEM}}` — from workflow.config.md

If `{{FILES}}` is a feature name rather than file paths, use Glob to find matching
component/hook/service files before spawning Stage 1.

---

## Stage Definitions

### Stage 1 — CODE REVIEW
Spawn the `frontend-reviewer` agent.

Agent prompt:
```
You are the frontend-reviewer agent.

Files to review: {{FILES}}
Framework: {{FRAMEWORK}}
Language: {{LANGUAGE}}
Component library: {{COMPONENT_LIB}}
Styling: {{STYLING}}
Server state: {{SERVER_STATE}}

Read frontend.config.md and profiles/frontend/rules/typescript.md,
profiles/frontend/rules/css-standards.md, and
profiles/frontend/rules/frontend-security-guardrails.md before reviewing.

Review every file listed. Every finding requires a FILE:LINE reference.

---

### TypeScript quality

- [ ] No `any` types — every value has a precise type
- [ ] No non-null assertions (`!`) without a justification comment on the same line
- [ ] No `as` type assertions without a comment explaining why it's safe
- [ ] Strict null checks respected — no unchecked access on `T | null | undefined`
- [ ] Discriminated unions used for loading/error/success state — not boolean flags
  (prefer `{ status: 'loading' | 'error' | 'success'; data?: T; error?: Error }`)
- [ ] Generic types used correctly — type parameters constrained where needed
- [ ] Enums avoided — use `const` objects with `as const` or string literal unions instead
- [ ] No `Object`, `Function`, `{}` as types — use specific interfaces

### Component design

- [ ] Single responsibility: each component does one thing and has one reason to change
- [ ] Props interface is minimal — no prop drilling beyond 2 levels
  (if drilling 3+ levels, consider context or state lift)
- [ ] No business logic in presentational components — props in, events out
- [ ] State is hoisted to the lowest common ancestor, not higher
- [ ] `React.memo` / `useMemo` / `useCallback` used only where a re-render is actually expensive
  — not applied preemptively to every component
- [ ] No inline object or function definitions in JSX that defeat memoization:
  `style={{ color: 'red' }}` → extract to constant
  `onChange={() => handler(item)}` → use `useCallback`
- [ ] List keys are stable, unique IDs — never array index (causes reconciliation bugs)
- [ ] `useEffect` dependency arrays are complete — no stale closure bugs
- [ ] `useEffect` cleanup returned where necessary (subscriptions, timers, abort controllers)
- [ ] No `useLayoutEffect` where `useEffect` would suffice

### State management ({{SERVER_STATE}} and local state)

- [ ] Store shape is flat and normalised — no deeply nested mutable state
- [ ] No derived state stored — computed values from selectors, not stored separately
- [ ] Selectors are memoized (reselect, zustand selectors with equality fn)
- [ ] No direct state mutation — all updates via actions/reducers/setters
- [ ] Server state loading/error/empty states all handled in UI
- [ ] Stale time and cache time appropriate for the data freshness requirement
- [ ] Mutations invalidate or optimistically update correct query keys
- [ ] Error boundary wraps sections that fetch async data

### Styling ({{STYLING}})

- [ ] No magic spacing/sizing numbers — use design token scale (e.g. Tailwind `p-4` not `p-[16px]`)
- [ ] No hardcoded hex colours — use CSS variables / theme tokens
- [ ] Responsive: mobile-first breakpoints, no layout that breaks at small viewports
- [ ] No z-index conflicts — z-index values come from a documented scale
- [ ] No `!important` without an inline comment explaining why it was necessary
- [ ] Animations: prefer `transform` and `opacity` (compositor) over `width`/`height`/`top` (layout)
- [ ] `prefers-reduced-motion` respected for animations (use `@media (prefers-reduced-motion)`)

### Security

- [ ] No `dangerouslySetInnerHTML` without `DOMPurify.sanitize()` wrapping the value
- [ ] Auth tokens NOT stored in `localStorage` or `sessionStorage` (use httpOnly cookies)
- [ ] No hardcoded API keys, tokens, or secrets — use env vars / build-time injection
- [ ] All external links: `rel="noopener noreferrer"` on `target="_blank"` anchors
- [ ] No `eval()`, `new Function()`, or `setTimeout(string)` — XSS vectors
- [ ] No user-supplied values interpolated into CSS (`style={{ color: userInput }}` — CSS injection)
- [ ] Content-Security-Policy compatible: no inline event handlers (`onclick="..."`)
- [ ] No sensitive data (tokens, PII) logged to `console.*`

### Performance

- [ ] Heavy third-party components lazily imported (charts, maps, rich text editors)
- [ ] Route components code-split with `React.lazy` / `dynamic()` where applicable
- [ ] Large lists virtualised (react-window, @tanstack/virtual)
- [ ] Images: use `next/image` or native `loading="lazy"` for below-fold images
- [ ] No barrel file (index.ts re-exporting everything) preventing tree-shaking
- [ ] No full library import when a named import works: `import _ from 'lodash'` → `import debounce from 'lodash/debounce'`

### Testing

- [ ] Tests exist for all new public APIs and business logic
- [ ] Tests target behaviour (what the user sees), not implementation details
- [ ] No `.querySelector('.my-class')` in tests — use `data-testid` or accessible roles
- [ ] Async tests properly awaited — no race conditions
- [ ] Mocks reset between tests — no shared state leaking

---

Output format:
## Frontend Code Review — {{FILES}}

### Critical (security risk or user-facing bug)
- [FILE:LINE] Issue — Impact — Exact fix

### Major (type safety, performance, or UX gap)
- [FILE:LINE] Issue — Exact fix

### Minor (style, naming, convention)
- [FILE:LINE] Suggestion

### Approved patterns
- [FILE:LINE] Good practice worth noting

Write a specific FILE:LINE reference for every finding. No general observations.
```
Tools: Read, Grep, Glob

Gate: Print review summary (count per severity). Ask "Code review complete. Proceed to ACCESSIBILITY AUDIT? [y/N]"

---

### Stage 2 — ACCESSIBILITY AUDIT
Spawn the `accessibility-auditor` agent.

Agent prompt:
```
You are the accessibility-auditor agent.

Files: {{FILES}}
Framework: {{FRAMEWORK}}
Code review findings from Stage 1: {{REVIEW_OUTPUT}}

Read profiles/frontend/rules/accessibility.md.

Audit every component against WCAG 2.1 Level AA:

**Perceivable**
- [ ] All non-text content has a text alternative (alt, aria-label, aria-labelledby)
- [ ] Decorative images: alt="" and role="presentation"
- [ ] Colour is not the ONLY means of conveying information (e.g. error state uses icon + text, not just red colour)
- [ ] Text contrast ≥ 4.5:1 for normal text (< 18px non-bold), ≥ 3:1 for large text
- [ ] UI component contrast (button borders, input borders) ≥ 3:1 against background
- [ ] No fixed `px` font sizes that block browser zoom (use `rem`/`em`)
- [ ] Content reflows at 320px width without horizontal scrolling

**Operable**
- [ ] All interactive elements reachable by Tab key
- [ ] No keyboard trap — user can always navigate away
- [ ] Focus indicator visible (no `outline: none` without a styled replacement)
- [ ] Skip link at page start (for pages with nav before main content)
- [ ] All interactive elements ≥ 44×44 CSS px touch target
- [ ] No time-limited content without controls

**Understandable**
- [ ] `lang` attribute on `<html>` element
- [ ] All form inputs have a visible label associated via `htmlFor` / `aria-labelledby`
- [ ] Error messages describe the problem AND suggest a fix
- [ ] Required fields marked (`required` or `aria-required="true"`)
- [ ] Autocomplete attributes on common fields (name, email, tel, address)

**Robust**
- [ ] Semantic HTML: `<button>` not `<div onClick>`, `<nav>` not `<div className="nav">`, etc.
- [ ] ARIA roles used only when native semantics are insufficient
- [ ] ARIA attributes complete and valid:
  - `aria-expanded` paired with `aria-controls`
  - `aria-haspopup` with correct value (menu/listbox/dialog)
  - `aria-selected` only on role=option/tab/gridcell
- [ ] Dynamic content changes announced via `aria-live` or `role="status"/"alert"`
- [ ] Modal dialogs: focus trapped inside, Escape closes, focus returns to trigger on close
- [ ] `aria-modal="true"` on dialog elements

**Pattern-specific (check each present in these files)**
- Dropdown/Combobox: arrow keys navigate, Enter selects, Escape closes, aria-activedescendant updated
- Tab panel: aria-selected, arrow key navigation, tabpanel shown/hidden
- Tooltip: triggered by focus AND hover, role="tooltip", aria-describedby link
- Alert/notification: role="alert" for urgent, aria-live="polite" for non-urgent
- Form: error messages associated via aria-describedby, aria-invalid="true" on invalid inputs

Output:
## Accessibility Audit — {{FILES}}

### Critical (WCAG failure — prevents access for disabled users)
- [FILE:LINE] Criterion [e.g. 1.4.3] — Issue — Fix

### Major (significant barrier)
- [FILE:LINE] Criterion — Issue — Fix

### Minor (best practice / enhancement)
- [FILE:LINE] Suggestion

### Passing checks
- [FILE:LINE] ✓ Criterion — Compliant implementation noted
```
Tools: Read, Grep, Glob

Gate: Ask "Accessibility audit complete. Proceed to SECURITY SCAN? [y/N]"

---

### Stage 3 — SECURITY SCAN
Spawn the `frontend-reviewer` agent with a security-focused task.

Agent prompt:
```
You are the frontend-reviewer agent focused on security.

Files: {{FILES}}
Framework: {{FRAMEWORK}}
Language: {{LANGUAGE}}

Read profiles/frontend/rules/frontend-security-guardrails.md.

Perform a targeted security scan. For each finding, provide FILE:LINE and exact remediation.

Scan for:

**XSS vectors**
- `dangerouslySetInnerHTML` without DOMPurify sanitisation
- `v-html` (Vue) without sanitisation
- `[innerHTML]` (Angular) without DomSanitizer
- User input interpolated into CSS values (CSS injection)
- `eval()`, `new Function()`, `setTimeout(string)` calls

**Sensitive data exposure**
- Auth tokens, API keys, or secrets stored in localStorage / sessionStorage
- Sensitive data logged to console
- PII or auth data in URL query parameters (appears in server logs and browser history)
- Sensitive state persisted to localStorage via state management middleware

**Credential and key leaks**
- Hardcoded API keys, tokens, or secrets in source files
- `.env.local` or `.env.production` accidentally imported or committed

**Third-party risks**
- `<script>` tags loading external scripts without `integrity` (SRI) attribute
- Dynamic script injection based on user input (open redirect to script)
- `postMessage` listeners without `event.origin` validation

**Authentication risks**
- `Authorization` header built from client-side state that could be manipulated
- JWT decoded but signature not verified (client-side decode of sensitive data)
- Auth state stored in a place accessible to XSS (localStorage over httpOnly cookie)

**Open redirect**
- `router.push(userInput)` without URL validation
- `window.location.href = userInput` without validation
- Redirect URLs in query params not validated against allowlist

Output:
## Security Scan — {{FILES}}

### Critical (exploitable vulnerability)
- [FILE:LINE] Vulnerability type — Attack scenario — Exact fix

### High (significant risk)
- [FILE:LINE] Issue — Fix

### Medium (defence in depth)
- [FILE:LINE] Suggestion

### Clean checks
- [FILE:LINE] ✓ Pattern — Implemented correctly
```
Tools: Read, Grep, Glob

---

## Frontend Review Summary Report

After all stages complete, print:

```
════════════════════════════════════════════════════════
  Frontend Review — {{FILES}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — CODE REVIEW     Critical: N, Major: N, Minor: N
  [✓] Stage 2 — ACCESSIBILITY   WCAG failures: N, Major: N, Minor: N
  [✓] Stage 3 — SECURITY        Critical: N, High: N, Medium: N
════════════════════════════════════════════════════════

Action items (must fix before merge):
  [list all Critical findings across all stages]

Tickets to create in {{TICKET_SYSTEM}}:
  [one ticket per Critical/High finding]
```

---

## Variables

- `{{FILES}}` = argument passed to this command
- `{{REVIEW_OUTPUT}}` = Stage 1 output (first 2000 chars)
- `{{FRAMEWORK}}`, `{{LANGUAGE}}`, `{{COMPONENT_LIB}}`, `{{STYLING}}`,
  `{{SERVER_STATE}}` = from frontend.config.md
- `{{TICKET_SYSTEM}}` = from workflow.config.md
