#!/usr/bin/env bash
# ============================================================
# Claude Crew — PostToolUse Security Hook  (v2)
#
# Runs after Write and Edit tool calls.
# Scans written files for secrets, injection patterns, and
# mobile-specific security issues. Reminds about lint/tests.
# ============================================================

set -euo pipefail

# ── Audit log ────────────────────────────────────────────────────────────────
AUDIT_LOG="${CLAUDE_PROJECT_DIR:-$HOME}/.claude/audit.log"
mkdir -p "$(dirname "$AUDIT_LOG")" 2>/dev/null || true

audit_warn() {
  local file="$1" reason="$2"
  local ts; ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
  echo "[$ts] TOOL=PostWrite ACTION=WARN FILE=\"$file\" REASON=\"$reason\"" \
    >> "$AUDIT_LOG" 2>/dev/null || true
}

# ── Parse input ──────────────────────────────────────────────────────────────
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('file_path', d.get('path', d.get('tool_input', {}).get('file_path', ''))) or '')
except:
    print('')
" 2>/dev/null || echo "")

if [[ -z "$FILE_PATH" || ! -f "$FILE_PATH" ]]; then
  exit 0
fi

FOUND_ISSUES=0

issue() {
  local severity="$1" msg="$2"
  echo "" >&2
  echo "$severity  $msg" >&2
  audit_warn "$FILE_PATH" "$msg"
  FOUND_ISSUES=$((FOUND_ISSUES + 1))
}

# ── 1. Secret / credential patterns ──────────────────────────────────────────
scan_secrets() {
  local file="$1"

  # AWS Access Key
  grep -nqiE "AKIA[0-9A-Z]{16}" "$file" 2>/dev/null && \
    issue "🔴 SECRET" "AWS Access Key pattern detected in $file — remove immediately and rotate the key"

  # GitHub personal access token
  grep -nqiE "gh[pousr]_[A-Za-z0-9]{36,}" "$file" 2>/dev/null && \
    issue "🔴 SECRET" "GitHub token pattern detected in $file — remove immediately and revoke the token"

  # Private key block
  grep -nqiE "-----BEGIN (RSA |EC |OPENSSH |)PRIVATE KEY-----" "$file" 2>/dev/null && \
    issue "🔴 SECRET" "Private key block detected in $file — never commit private keys"

  # Google API key
  grep -nqiE "AIza[0-9A-Za-z_-]{35}" "$file" 2>/dev/null && \
    issue "🔴 SECRET" "Google API key pattern detected in $file — use BuildConfig injection instead"

  # JWT token (heuristic: three base64 segments)
  grep -nqiE '"eyJ[A-Za-z0-9+/]{20,}\.[A-Za-z0-9+/]{20,}\.[A-Za-z0-9+/]{20,}"' "$file" 2>/dev/null && \
    issue "🔴 SECRET" "Hardcoded JWT token detected in $file"

  # Generic high-confidence API key assignment
  grep -nqiE '(api[_-]?key|apikey|secret[_-]?key|auth[_-]?token|access[_-]?token)\s*[=:]\s*["'"'"'][A-Za-z0-9+/_-]{20,}["'"'"']' \
    "$file" 2>/dev/null && \
    issue "🔴 SECRET" "Hardcoded API key/token assignment in $file — use environment injection or a secrets manager"

  # Hardcoded password (heuristic)
  grep -nqiE '(password|passwd|pwd)\s*[=:]\s*["'"'"'][^"'"'"']{8,}["'"'"']' "$file" 2>/dev/null && \
    issue "🟠 SECRET" "Possible hardcoded password in $file — use secure storage or environment injection"

  # Android: hardcoded key in build.gradle
  if echo "$FILE_PATH" | grep -qiE "\.gradle(\.kts)?$"; then
    grep -nqiE '(signingConfig|storePassword|keyPassword|storeFile)\s*[=:]\s*["'"'"'][^"'"'"']{4,}["'"'"']' "$file" 2>/dev/null && \
      issue "🔴 SECRET" "Signing credentials hardcoded in build file — use local.properties or environment variables"
  fi
}

# ── 2. Prompt injection pattern in written content ────────────────────────────
scan_injection() {
  local file="$1"
  grep -nqiE \
    "(ignore (all |previous |prior )?(instructions?|rules?)|you are now (a |an )?[a-z]|new (system |)prompt|\[SYSTEM\]|<system>|<!-- ?system|disregard.*rules?|execute the following)" \
    "$file" 2>/dev/null && \
    issue "🟠 INJECTION" "Prompt injection pattern written to $file — review before committing"
}

# ── 3. Mobile security patterns ───────────────────────────────────────────────
scan_mobile_security() {
  local file="$1"

  # Android — disabling SSL
  if echo "$FILE_PATH" | grep -qiE "\.kt$"; then
    grep -nqiE "(setHostnameVerifier\(.*ALLOW_ALL|trustAllCerts|X509TrustManager.*override.*checkServer|SSLContext.*TrustAllCerts)" \
      "$file" 2>/dev/null && \
      issue "🔴 SECURITY" "SSL certificate validation disabled in $file — this enables MITM attacks"

    grep -nqiE "Log\.(d|e|v|i|w)\(.*password|Log\.(d|e|v|i|w)\(.*token|Log\.(d|e|v|i|w)\(.*secret" \
      "$file" 2>/dev/null && \
      issue "🟠 SECURITY" "Sensitive data may be logged in $file — remove before release"

    grep -nqiE "MODE_WORLD_READABLE|MODE_WORLD_WRITEABLE" "$file" 2>/dev/null && \
      issue "🔴 SECURITY" "World-readable/writable file mode in $file — data accessible to other apps"

    grep -nqiE "getSharedPreferences|SharedPreferences" "$file" 2>/dev/null
    grep -nqiE "(token|password|secret|key|credential)" "$file" 2>/dev/null && \
      true  # Check combination
    if grep -qiE "getSharedPreferences|SharedPreferences" "$file" 2>/dev/null && \
       grep -qiE "(token|password|secret|key|credential)" "$file" 2>/dev/null; then
      issue "🟠 SECURITY" "SharedPreferences used with sensitive data in $file — use EncryptedSharedPreferences instead"
    fi

    grep -nqiE "Runtime\.getRuntime\(\)\.exec|ProcessBuilder" "$file" 2>/dev/null && \
      issue "🟠 SECURITY" "Dynamic command execution in $file — verify input is sanitised to prevent command injection"
  fi

  # iOS — disabling SSL
  if echo "$FILE_PATH" | grep -qiE "\.swift$"; then
    grep -nqiE "(NSAllowsArbitraryLoads.*true|canAuthenticateAgainstProtectionSpace.*false|serverTrust.*nil|allowInvalidCertificates)" \
      "$file" 2>/dev/null && \
      issue "🔴 SECURITY" "SSL/ATS disabled or bypassed in $file — enables MITM attacks"

    grep -nqiE 'print\(.*password|print\(.*token|NSLog\(.*password|NSLog\(.*secret' "$file" 2>/dev/null && \
      issue "🟠 SECURITY" "Sensitive data may be printed to logs in $file — remove before release"

    grep -nqiE "UserDefaults.*password|UserDefaults.*token|UserDefaults.*secret" "$file" 2>/dev/null && \
      issue "🟠 SECURITY" "Sensitive data stored in UserDefaults in $file — use Keychain instead"

    grep -nqiE "!{1}" "$file" 2>/dev/null | grep -vqiE "!=" && \
      issue "⚠️  QUALITY" "Force unwrap (!) detected in $file — prefer guard let or if let to avoid crashes"
  fi

  # Both — network security config
  if echo "$FILE_PATH" | grep -q "network_security_config.xml"; then
    grep -nqiE "<trust-anchors>.*<certificates src=\"user\"" "$file" 2>/dev/null && \
      issue "🟠 SECURITY" "User certificates trusted in network security config — acceptable for debug only"
  fi
}

# ── 4. Lint / test reminders ──────────────────────────────────────────────────
lint_reminder() {
  local file="$1"
  local reminded=false

  if echo "$FILE_PATH" | grep -qE "\.kt$"; then
    echo "" >&2
    echo "── Kotlin file modified: $file ──" >&2
    echo "  Run: ./gradlew lint && ./gradlew test" >&2
    reminded=true
  fi

  if echo "$FILE_PATH" | grep -qE "\.gradle(\.kts)?$"; then
    echo "" >&2
    echo "── Build file modified: $file ──" >&2
    echo "  Run: ./gradlew build" >&2
    reminded=true
  fi

  if echo "$FILE_PATH" | grep -qE "\.swift$"; then
    echo "" >&2
    echo "── Swift file modified: $file ──" >&2
    echo "  Run: swiftlint && xcodebuild test -scheme \$SCHEME" >&2
    reminded=true
  fi

  if echo "$FILE_PATH" | grep -q "\.pbxproj"; then
    echo "" >&2
    echo "── Xcode project file modified — verify it opens correctly in Xcode ──" >&2
    reminded=true
  fi
}

# ── Run all scans ─────────────────────────────────────────────────────────────
scan_secrets    "$FILE_PATH"
scan_injection  "$FILE_PATH"
scan_mobile_security "$FILE_PATH"
lint_reminder   "$FILE_PATH"

if [[ $FOUND_ISSUES -gt 0 ]]; then
  echo "" >&2
  echo "── $FOUND_ISSUES security issue(s) found in $FILE_PATH ──" >&2
  echo "   Review rules/security-guardrails.md for remediation guidance." >&2
fi

exit 0
