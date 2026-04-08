Run a comprehensive security audit of the mobile project. Delegates to the `mobile-security` agent.

Spawn the `mobile-security` agent with this task:

```
You are the mobile-security agent performing a full project security scan.
Read `rules/security-guardrails.md` before starting.

## Scope

Scan the entire project for the following categories. Work through each category
systematically. Use Grep and Glob to find files — do not execute or run code.

---

## Category 1 — Hardcoded Secrets & Credentials

Search for hardcoded secrets in all source files:

```bash
# AWS keys
grep -rn "AKIA[0-9A-Z]{16}" --include="*.kt" --include="*.swift" --include="*.gradle*" --include="*.xml" --include="*.plist" .

# Google API keys
grep -rn "AIza[0-9A-Za-z_-]{35}" --include="*.kt" --include="*.swift" --include="*.gradle*" --include="*.xml" --include="*.plist" .

# Private key headers
grep -rn "BEGIN PRIVATE KEY\|BEGIN RSA PRIVATE KEY\|BEGIN EC PRIVATE KEY" -r .

# Generic hardcoded tokens/passwords
grep -rniE '(api_?key|secret_?key|auth_?token|access_?token|password|passwd)\s*[=:]\s*["'"'"'][A-Za-z0-9+/_-]{8,}["'"'"']' \
  --include="*.kt" --include="*.swift" --include="*.java" .
```

Also check:
- `build.gradle` / `build.gradle.kts` for hardcoded `storePassword`, `keyPassword`
- `Info.plist` for hardcoded API keys in any key/string pair
- `strings.xml` for tokens or passwords
- `.github/workflows/*.yml` for hardcoded secrets (should use ${{ secrets.X }})

Rate each finding:
- 🔴 P0 — active credential that must be rotated immediately
- 🟠 P1 — pattern that looks like a credential, verify and remove
- 🟡 P2 — placeholder or test value that should be documented

---

## Category 2 — Network Security

**Android:**
- Check `res/xml/network_security_config.xml` for `<certificates src="user">` or `<trust-anchors>` outside debug config
- Search for `setHostnameVerifier(SSLSocketFactory.ALLOW_ALL_HOSTNAME_VERIFIER)` or `ALLOW_ALL`
- Search for custom `X509TrustManager` that overrides `checkServerTrusted` without validation
- Search for `HttpURLConnection` without timeout or SSL config
- Check if certificate pinning is implemented for all production API endpoints

**iOS:**
- Check `Info.plist` for `NSAllowsArbitraryLoads: true` outside a justification comment
- Search for `URLSession` configurations that set `allowInvalidCertificates` or trust all certificates
- Check for `canAuthenticateAgainstProtectionSpace` returning false without reason

---

## Category 3 — Sensitive Data Storage

**Android:**
- Search for `SharedPreferences` storing tokens, passwords, or PII — should use `EncryptedSharedPreferences`
- Search for `openFileOutput` with `MODE_WORLD_READABLE` or `MODE_WORLD_WRITEABLE`
- Check that SQLite databases with sensitive data use `SQLCipher` or are in internal storage
- Verify no sensitive data is stored in `external storage` (sdcard paths)

**iOS:**
- Search for `UserDefaults` storing passwords, tokens, or private keys — should use Keychain
- Check that Keychain items use `.secureEnclave` or `.afterFirstUnlock` accessibility
- Verify no PII is written to `NSDocumentDirectory` without encryption

---

## Category 4 — Logging & Debug Leaks

**Android:**
- Search for `Log.d/e/v/i/w` calls containing `password`, `token`, `secret`, `key`, `email`, `ssn`, `dob`
- Search for `println` with sensitive variable names
- Check that `BuildConfig.DEBUG` gates all sensitive logging

**iOS:**
- Search for `print(` or `NSLog(` with sensitive variable names
- Check that `#if DEBUG` gates sensitive logging
- Search for `dump(` calls on model objects containing PII

---

## Category 5 — Injection Vulnerabilities

**SQL Injection:**
- Search for raw SQL strings with string interpolation: `"SELECT * FROM users WHERE id = \${userId}"`
- All Room `@Query` annotations with user input must use `:parameter` binding
- iOS: CoreData predicates with user input must use `%@` or `NSPredicate` with substitutions

**Deep Link / Intent Injection:**
- Check all exported Activities (`android:exported="true"`) for intent data handled without validation
- Search for `getIntent().getStringExtra()` used directly in SQL, file paths, or URLs
- iOS: Check all URL scheme handlers for parameter validation before use

**WebView:**
- Search for `setJavaScriptEnabled(true)` — verify it is necessary and `addJavascriptInterface` is not exposed to untrusted content
- iOS: Check `WKWebView` for `allowsArbitraryLoads` and loaded URLs

---

## Category 6 — Authentication & Session

- Verify token storage uses Keychain (iOS) or EncryptedSharedPreferences / Keystore (Android)
- Check token refresh logic for race conditions
- Verify biometric authentication result is not bypassable by intercepting the callback
- Check for missing `FLAG_SECURE` on screens showing sensitive data (Android)
- Verify session invalidation on logout (tokens cleared, cookies cleared)

---

## Category 7 — OWASP Mobile Top 10 Checklist

| # | Risk | Status |
|---|---|---|
| M1 | Improper credential usage | check hardcoded secrets above |
| M2 | Inadequate supply chain security | check dependency versions |
| M3 | Insecure authentication/authorisation | check auth flows |
| M4 | Insufficient input/output validation | check deep links + WebView |
| M5 | Insecure communication | check SSL/TLS + pinning |
| M6 | Inadequate privacy controls | check logging + storage |
| M7 | Insufficient binary protections | check ProGuard/R8 config |
| M8 | Security misconfiguration | check manifest + Info.plist |
| M9 | Insecure data storage | check SharedPrefs/UserDefaults |
| M10 | Insufficient cryptography | check key storage + algorithms |

---

## Category 8 — Build & Configuration

**Android:**
- Verify `minifyEnabled true` and `shrinkResources true` in release build type
- Verify ProGuard/R8 rules do not expose sensitive classes
- Check `android:debuggable` is not `true` in release manifest
- Check `android:allowBackup` — should be `false` for apps handling sensitive data
- Verify no `android:exported="true"` for components that don't need to be

**iOS:**
- Verify `DEBUG` preprocessor macro is not set in release scheme
- Check entitlements file — no unnecessary capabilities enabled
- Verify bitcode / symbol upload configured for crash reporting
- Check `NSFaceIDUsageDescription` is present if biometrics used

---

## Report Format

Print a structured report:

```
## Security Scan Report — {project} — {date}

### Summary
  🔴 P0 Critical: {N} findings (require immediate action)
  🟠 P1 High:     {N} findings (fix before next release)
  🟡 P2 Medium:   {N} findings (fix within 2 sprints)
  🔵 P3 Low:      {N} findings (add to backlog)
  ✅ Passed:      {N} checks passed

### Findings

#### 🔴 P0 — [Category]: [Title]
  File: [path:line]
  Issue: [description]
  Fix: [specific remediation]

[repeat for each finding]

### Passed Checks
  ✅ No hardcoded AWS keys found
  ✅ SSL hostname verification not disabled
  [etc.]

### Recommendations
  1. [highest priority action]
  2. [second priority]
  ...
```

Create a Jira task for each P0 and P1 finding if `jira.config.md` exists and Jira CLI is available.
```
