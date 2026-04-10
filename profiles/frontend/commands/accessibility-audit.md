Run a deep standalone accessibility audit against WCAG 2.1 Level AA. Argument is a file path, directory, or component name.

You are the **orchestrator**. Do NOT audit components yourself — spawn dedicated sub-agents.

---

## Before starting

Read `frontend.config.md` and `workflow.config.md`. Extract:
- `{{FRAMEWORK}}` — react, vue, angular, svelte, etc.
- `{{COMPONENT_LIB}}` — shadcn/ui, MUI, Ant Design, etc.
- `{{TICKET_SYSTEM}}` — from workflow.config.md
- `{{DOCS_PLATFORM}}` — from workflow.config.md

---

## Stage Definitions

### Stage 1 — ELEMENT INVENTORY
Spawn the `accessibility-auditor` agent.

Agent prompt:
```
You are the accessibility-auditor agent.

Target: {{TARGET}}
Framework: {{FRAMEWORK}}
Component library: {{COMPONENT_LIB}}

Read all files in {{TARGET}}. Build a complete accessibility inventory:

1. **Interactive elements** — for each: element type, label source, keyboard accessible?
   | Element | File:Line | Label | Type | Keyboard? | Notes |
   |---------|-----------|-------|------|-----------|-------|

2. **Images and icons** — alt text present? Decorative?
   | Element | File:Line | Alt/Label | Decorative? | Issue? |
   |---------|-----------|-----------|-------------|--------|

3. **Forms** — for each form input:
   | Input | File:Line | Label | Required marker | Error display | Issue? |
   |-------|-----------|-------|-----------------|---------------|--------|

4. **Dynamic content regions** — aria-live, role=status, role=alert:
   | Element | File:Line | Role/Live value | Trigger | Issue? |
   |---------|-----------|-----------------|---------|--------|

5. **Modal / Dialog / Drawer components** — for each:
   | Component | File:Line | aria-modal | aria-labelledby | Focus trap | Escape closes |
   |-----------|-----------|------------|-----------------|------------|---------------|

6. **Navigation landmarks** — nav, main, aside, header, footer, role=navigation, role=main:
   | Landmark | File:Line | Label | Notes |
   |----------|-----------|-------|-------|

7. **Heading structure** — h1-h6 hierarchy:
   | Heading | File:Line | Level | Text | Issue? |
   |---------|-----------|-------|------|--------|

8. **Colour combinations found** (for contrast checking):
   List unique foreground/background colour pairs used.

Output: complete inventory tables. Flag anything suspicious with ⚠.
```
Tools: Read, Grep, Glob

Gate: Print inventory summary (count per element type, flagged items). Ask "Inventory complete. Proceed to WCAG AUDIT? [y/N]"

---

### Stage 2 — WCAG 2.1 AA SYSTEMATIC AUDIT
Spawn the `accessibility-auditor` agent.

Agent prompt:
```
You are the accessibility-auditor agent.

Target: {{TARGET}}  Framework: {{FRAMEWORK}}
Inventory from Stage 1: {{INVENTORY_OUTPUT}}

Systematically audit every WCAG 2.1 Level AA criterion.
For each: state ✓ Pass / ✗ Fail / ⚠ Needs manual test / N/A.
Every Fail must have [FILE:LINE] — exact issue — exact fix.

## Principle 1: Perceivable

1.1.1 Non-text content (A) — every image, icon, chart has text alternative; decorative images alt=""
1.3.1 Info and relationships (A) — semantic HTML; headings, lists, tables, form labels in code not just visually
1.3.3 Sensory characteristics (A) — no instructions relying solely on colour, shape, or position
1.4.1 Use of colour (A) — colour not the only way to convey state (errors use icon + text + colour)
1.4.3 Contrast minimum (AA) — normal text ≥ 4.5:1; large text (≥ 18px or 14px bold) ≥ 3:1; placeholder ≥ 4.5:1
1.4.4 Resize text (AA) — content usable at 200% zoom, no fixed px that prevents scaling
1.4.10 Reflow (AA) — single-column layout at 320px, no horizontal scroll needed
1.4.11 Non-text contrast (AA) — UI component borders ≥ 3:1; focus indicators ≥ 3:1
1.4.12 Text spacing (AA) — no loss at 1.5× line-height, 0.12em letter-spacing, 0.16em word-spacing
1.4.13 Content on hover/focus (AA) — tooltips are dismissible, hoverable, and persistent

## Principle 2: Operable

2.1.1 Keyboard (A) — all functionality operable without mouse; every interactive element Tab-reachable
2.1.2 No keyboard trap (A) — user can always Tab away (modals: Escape to close)
2.4.1 Bypass blocks (A) — skip link as first focusable element on pages with nav blocks
2.4.3 Focus order (A) — logical Tab sequence matching visual layout; no unexpected focus jumps
2.4.4 Link purpose (A) — link text describes destination without context; "click here" fails
2.4.6 Headings and labels (AA) — headings describe sections; labels describe input purpose
2.4.7 Focus visible (AA) — keyboard focus indicator visible; no outline:none without replacement
2.5.3 Label in name (A) — accessible name contains visible label text for interactive elements

## Principle 3: Understandable

3.1.1 Language of page (A) — lang attribute set on <html>
3.2.1 On focus (A) — no context change on focus alone (no auto-navigation)
3.2.2 On input (A) — no unexpected context change from input before submission
3.3.1 Error identification (A) — errors identified in text describing what went wrong
3.3.2 Labels or instructions (A) — format instructions provided before or at the input
3.3.3 Error suggestion (AA) — error messages suggest how to fix ("Enter valid email like name@example.com")
3.3.4 Error prevention (AA) — legal/financial submissions are reversible/verifiable/confirmable

## Principle 4: Robust

4.1.1 Parsing (A) — no duplicate IDs; well-formed HTML
4.1.2 Name, role, value (A) — all UI components have accessible name, role, state
4.1.3 Status messages (AA) — status changes announced via aria-live without moving focus

## Interactive pattern audit (check each present in these files)

Modal/Dialog: aria-modal="true", aria-labelledby, focus trap active, Escape closes, focus returns to trigger
Dropdown/Combobox: aria-expanded, aria-haspopup, arrow keys navigate, Enter selects, Escape closes
Tab panel: role=tablist/tab/tabpanel, aria-selected, arrow keys navigate tabs
Tooltip: role=tooltip, triggered by focus AND hover, aria-describedby link, dismissible
Alert: role=alert (urgent) or aria-live=polite (non-urgent) — not both on same element
Accordion: button in heading, aria-expanded on button, aria-controls to panel

---

Output:
## WCAG 2.1 AA Audit — {{TARGET}}

### Critical violations
| Criterion | Level | File:Line | Issue | Fix |
|-----------|-------|-----------|-------|-----|

### Major issues
| Criterion | File:Line | Issue | Fix |
|-----------|-----------|-------|-----|

### Minor issues
| File:Line | Suggestion |
|-----------|------------|

### Full criterion checklist
| Criterion | Status | Notes |
|-----------|--------|-------|
| 1.1.1 Non-text content | ✓/✗/⚠/N/A | |
... (all 20 criteria listed)
```
Tools: Read, Grep, Glob

Gate: Print pass/fail table summary. Ask "Audit complete. Proceed to REMEDIATION PLAN? [y/N]"

---

### Stage 3 — REMEDIATION PLAN
Spawn the `accessibility-auditor` agent.

Agent prompt:
```
You are the accessibility-auditor agent.

Target: {{TARGET}}
WCAG audit from Stage 2: {{AUDIT_OUTPUT}}
Ticket system: {{TICKET_SYSTEM}}
Docs platform: {{DOCS_PLATFORM}}

For every Critical and Major finding, write:

1. **Before/after code fix**:
   Show the exact change with the line that needs updating.

2. **Priority**:
   P0 — blocks screen reader users completely (no label, keyboard trap, focus invisible)
   P1 — significant barrier but workaround exists
   P2 — best practice / enhancement

3. **Ticket for {{TICKET_SYSTEM}}**:
   "Create Accessibility Bug: [summary] | Priority: [P0/P1/P2] | WCAG: [criterion]"

Produce:

**Manual QA checklist**:
- [ ] Navigate entire feature keyboard-only (Tab, Shift+Tab, Enter, Space, Escape, Arrow keys)
- [ ] Run axe DevTools in browser: 0 violations
- [ ] Run Lighthouse accessibility audit: score ≥ 90
- [ ] Test with VoiceOver (Mac): Cmd+F5 to enable
- [ ] Test with NVDA (Windows): download from nvaccess.org
- [ ] Test at 200% zoom: no content clipped or overlapping
- [ ] Test at 320px viewport: single column, no horizontal scroll

**Screen reader test script** (for each major interactive flow):
1. Enable screen reader
2. Navigate to [component/feature]
3. Expected announcement: "[what should be read]"
4. Perform [action]
5. Expected result: "[what screen reader announces next]"

**Automated test setup**:
```js
// jest-axe example (add to existing component tests)
import { axe, toHaveNoViolations } from 'jest-axe';
expect.extend(toHaveNoViolations);

it('has no accessibility violations', async () => {
  const { container } = render(<YourComponent />);
  expect(await axe(container)).toHaveNoViolations();
});
```
```
Tools: Read, Write

---

## Accessibility Audit Summary Report

After all stages complete, print:

```
════════════════════════════════════════════════════════
  Accessibility Audit — {{TARGET}}
════════════════════════════════════════════════════════
  [✓] Stage 1 — INVENTORY    Interactive: N, Images: N, Forms: N, Modals: N
  [✓] Stage 2 — WCAG AUDIT   Criteria checked: 20 — Pass: N, Fail: N, Manual: N
  [✓] Stage 3 — REMEDIATION  P0: N, P1: N — Fixes + test scripts documented
════════════════════════════════════════════════════════

Critical violations: [list criterion + file]
WCAG passing: N / 20 criteria

Tickets to create in {{TICKET_SYSTEM}}:
  P0: [list]
  P1: [list]
```

---

## Variables

- `{{TARGET}}` = argument passed to this command
- `{{INVENTORY_OUTPUT}}` = Stage 1 output (first 3000 chars)
- `{{AUDIT_OUTPUT}}` = Stage 2 output (first 3000 chars)
- `{{FRAMEWORK}}`, `{{COMPONENT_LIB}}` = from frontend.config.md
- `{{TICKET_SYSTEM}}`, `{{DOCS_PLATFORM}}` = from workflow.config.md
