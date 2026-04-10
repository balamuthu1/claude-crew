# Frontend Security Guardrails

These rules apply to all frontend development.

## Non-bypassable rules

1. **Never use `dangerouslySetInnerHTML` without sanitisation** — all user-generated HTML must be sanitised with DOMPurify or equivalent.
2. **Never store sensitive tokens in `localStorage`** — use `httpOnly` cookies for auth tokens; `sessionStorage` is acceptable for short-lived non-sensitive state.
3. **Never embed API keys in frontend code** — environment variables are still public in the browser bundle; treat them accordingly.
4. **Never trust client-side validation alone** — validate on the server. Client validation is for UX, not security.
5. **Never widen Content-Security-Policy** — if a CSP directive needs to be relaxed, review the root cause first.

## XSS prevention

### React/Vue (framework-level protection)
- JSX/template auto-escaping protects against most XSS — don't bypass it
- `dangerouslySetInnerHTML` bypasses escaping — requires explicit sanitisation
- `eval()`, `new Function()`, `setTimeout(string)` are XSS vectors — never use
- DOM properties that accept HTML: `innerHTML`, `outerHTML`, `document.write` — never set from user input

### Sanitisation when HTML is required
```typescript
import DOMPurify from 'dompurify';

// Only when rendering user-provided HTML is genuinely needed
function SafeHtml({ html }: { html: string }) {
  return (
    <div
      dangerouslySetInnerHTML={{
        __html: DOMPurify.sanitize(html, { ALLOWED_TAGS: ['b', 'i', 'em', 'strong'] })
      }}
    />
  );
}
```

## Sensitive file patterns (never commit)

```
.env.local
.env.development
.env.production
.env.staging
*.pem
*.key
```

Use `.env.example` (no real values) committed for documentation.

## Content Security Policy

Every production deployment must have a CSP header. Minimum viable CSP:
```
Content-Security-Policy:
  default-src 'self';
  script-src 'self';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
  connect-src 'self' https://api.yourdomain.com;
  frame-ancestors 'none'
```

Never use:
- `script-src 'unsafe-inline'` — use nonces instead
- `script-src 'unsafe-eval'` — blocks eval-based XSS
- `default-src *` — defeats the purpose

## Auth token storage

| Storage | XSS risk | CSRF risk | Recommendation |
|---------|----------|-----------|----------------|
| `localStorage` | High (readable by JS) | None | ❌ Avoid for auth tokens |
| `sessionStorage` | High (readable by JS) | None | ⚠️ Only for non-sensitive short session state |
| `httpOnly` cookie | None | Exists | ✅ Use for auth tokens; add CSRF token for mutations |
| In-memory (JS var) | Low (lost on reload) | None | ✅ Acceptable for SPAs with session persistence via refresh |

## Dependency security

- Run `npm audit` / `yarn audit` in CI — fail on High or Critical
- Review new dependencies before adding (size, activity, security history)
- Lock file must be committed and up to date
- Avoid dependencies with known unpatched vulnerabilities
