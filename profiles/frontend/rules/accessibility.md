# Web Accessibility Standards (WCAG 2.1 AA)

These rules apply to all frontend development. Accessibility is not optional.

## Non-negotiable rules

1. **All interactive elements must be keyboard accessible** — if you can click it, you can tab to it and activate it with Enter/Space
2. **All images need alt text** — meaningful images: descriptive alt; decorative images: `alt=""`
3. **All form inputs need visible labels** — `<label>` element, not just placeholder text
4. **Colour contrast minimum** — 4.5:1 for normal text, 3:1 for large text (≥18px or ≥14px bold), 3:1 for UI components
5. **Focus must be visible** — never `outline: none` without an alternative focus indicator

## HTML semantics

Use semantic HTML before reaching for ARIA:
```html
<!-- Wrong: div soup -->
<div class="button" onclick="submit()">Submit</div>

<!-- Correct: semantic HTML -->
<button type="submit">Submit</button>
```

Semantic elements: `<header>`, `<main>`, `<nav>`, `<section>`, `<article>`, `<aside>`, `<footer>`, `<button>`, `<a>`, `<input>`, `<label>`, `<h1>-<h6>`, `<ul>`, `<ol>`, `<table>`

## ARIA usage rules

ARIA rule #1: don't use ARIA if native HTML can do it.
ARIA rule #2: don't change native semantics.
ARIA rule #3: all interactive ARIA roles are keyboard operable.
ARIA rule #4: don't use `role="presentation"` or `aria-hidden="true"` on focusable elements.
ARIA rule #5: all interactive elements must have an accessible name.

### Common correct ARIA patterns

**Modal dialog**:
```html
<div role="dialog" aria-modal="true" aria-labelledby="modal-title" aria-describedby="modal-desc">
  <h2 id="modal-title">Confirm deletion</h2>
  <p id="modal-desc">This action cannot be undone.</p>
  ...
</div>
```
Trap focus inside while open. Return focus to trigger on close.

**Icon-only button**:
```html
<button aria-label="Close dialog">
  <svg aria-hidden="true">...</svg>
</button>
```

**Live region for dynamic content**:
```html
<div aria-live="polite" aria-atomic="true">
  <!-- Inject status messages here -->
</div>
```
Use `polite` for status updates; `assertive` only for errors and urgent alerts.

## Keyboard navigation requirements

| Component | Expected keyboard behaviour |
|-----------|---------------------------|
| Button | Enter or Space to activate |
| Link | Enter to navigate |
| Checkbox | Space to toggle |
| Radio group | Arrow keys to navigate; Enter/Space to select |
| Select | Arrow keys to navigate options |
| Modal | Tab traps inside; Escape to close |
| Dropdown menu | Arrow keys to navigate; Enter to select; Escape to close |
| Tabs | Arrow keys between tabs; Enter/Space to activate |
| Autocomplete | Arrow keys to navigate; Enter to select; Escape to dismiss |

## Forms

```html
<!-- Every input needs a visible label -->
<label for="email">Email address</label>
<input id="email" type="email" required aria-describedby="email-hint email-error" />
<p id="email-hint">We'll use this for account notifications.</p>
<p id="email-error" role="alert" aria-live="polite"></p>

<!-- Group related inputs -->
<fieldset>
  <legend>Notification preferences</legend>
  <label><input type="checkbox" name="email"> Email</label>
  <label><input type="checkbox" name="sms"> SMS</label>
</fieldset>
```

Error messages must:
- Identify the field that has an error
- Explain what is wrong
- Suggest how to fix it
- Be announced to screen readers (`role="alert"` or `aria-live`)

## Skip navigation

Every page must have a skip link as the first focusable element:
```html
<a href="#main-content" class="skip-link">Skip to main content</a>
...
<main id="main-content">...</main>
```
