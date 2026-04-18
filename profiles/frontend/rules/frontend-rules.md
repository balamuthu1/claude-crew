---
paths:
  - "**/*.ts"
  - "**/*.tsx"
  - "**/*.js"
  - "**/*.jsx"
  - "**/*.vue"
  - "**/*.svelte"
  - "**/*.css"
  - "**/*.scss"
  - "**/*.html"
---

# Frontend Rules

## Security

- NEVER use `dangerouslySetInnerHTML` without DOMPurify sanitisation.
- NEVER store auth tokens in `localStorage` — use `httpOnly` cookies.
- NEVER embed API keys in frontend code — env vars are public in the browser bundle.
- NEVER use `eval()`, `new Function()`, `setTimeout(string)` — XSS vectors.
- NEVER widen Content-Security-Policy without reviewing the root cause first.

## TypeScript

- NEVER use `any` type — use `unknown` with a type guard for truly dynamic data.
- Enable strict mode: `strict`, `noUncheckedIndexedAccess`, `noImplicitReturns`.
- No silent error swallowing (`catch (_) {}`) — at minimum log the error.

## Accessibility (WCAG 2.1 AA)

- All interactive elements must be keyboard accessible.
- All images need descriptive `alt` text; all form inputs need visible labels.
- Colour contrast: 4.5:1 for normal text, 3:1 for large text and UI components.
- Never `outline: none` without an alternative focus indicator.
- Use semantic HTML elements; add ARIA only when native semantics are insufficient.

## CSS / Design Tokens

- Never use `!important` — fix specificity by restructuring selectors.
- All spacing, colours, and typography must come from design tokens, not magic values.
- No hardcoded pixel values for spacing — use the token scale.

## Dependencies

- Run `npm audit` / `yarn audit` in CI; fail on High or Critical vulnerabilities.
- Lock file must be committed and kept up to date.
