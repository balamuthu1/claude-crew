#!/usr/bin/env bash
# Claude Crew — PreToolUse Hook
# Runs before any Bash tool execution.
# Receives tool input as JSON on stdin (when invoked by Claude Code hooks).
# Exits non-zero to block the tool call and surface a message to Claude.

set -euo pipefail

# Read the tool input JSON (provided by Claude Code on stdin for hooks)
INPUT=$(cat)

# Extract the command being run (if available)
COMMAND=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('command',''))" 2>/dev/null || echo "")

if [ -z "$COMMAND" ]; then
  exit 0  # No command to inspect, allow
fi

# ── Destructive git operations guard ─────────────────────────────────────────
if echo "$COMMAND" | grep -qE "git (push --force|push -f|reset --hard|clean -f|branch -D)"; then
  echo "BLOCKED: Destructive git operation detected: '$COMMAND'" >&2
  echo "These operations require explicit user confirmation. Ask the user before proceeding." >&2
  exit 1
fi

# ── Keystore / provisioning profile protection ────────────────────────────────
if echo "$COMMAND" | grep -qE "rm.*(\.jks|\.keystore|\.p12|\.mobileprovision|\.provisionprofile)"; then
  echo "BLOCKED: Attempted deletion of signing artifact: '$COMMAND'" >&2
  echo "Keystores and provisioning profiles cannot be deleted without explicit user approval." >&2
  exit 1
fi

# ── Migration file protection ─────────────────────────────────────────────────
if echo "$COMMAND" | grep -qE "rm.*(migrations?/|Migration[0-9])"; then
  echo "BLOCKED: Attempted deletion of database migration file: '$COMMAND'" >&2
  echo "Migration files must never be deleted. Discuss with the team before proceeding." >&2
  exit 1
fi

# ── Secrets leak prevention ───────────────────────────────────────────────────
# Block committing files that commonly contain secrets
if echo "$COMMAND" | grep -qE "git (add|commit).*\.(env|pem|p8|secret)"; then
  echo "BLOCKED: Possible secrets file in git operation: '$COMMAND'" >&2
  echo "Verify this file does not contain credentials before committing." >&2
  exit 1
fi

# ── rm -rf guard ──────────────────────────────────────────────────────────────
if echo "$COMMAND" | grep -qP "rm\s+-[a-zA-Z]*r[a-zA-Z]*f|rm\s+-[a-zA-Z]*f[a-zA-Z]*r"; then
  echo "WARNING: 'rm -rf' detected in command: '$COMMAND'" >&2
  echo "Ensure this is intentional. Claude Code will proceed but please verify the target." >&2
  # Allow but warn (exit 0) — user can configure to exit 1 to fully block
fi

exit 0
