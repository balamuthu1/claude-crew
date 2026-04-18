#!/usr/bin/env bash
# ============================================================
# Claude Crew — SessionStart Hook
#
# Fires at the start of every Claude Code session.
# 1. Injects the active rules digest (profile-filtered) so
#    rules are always fresh in context, not buried in CLAUDE.md.
# 2. Reads .claude/memory/MEMORY.md and injects accumulated
#    project knowledge from previous sessions.
#
# Output to stdout is injected into Claude's context.
# ============================================================

set -uo pipefail

# ── Resolve plugin root (parent of shared/scripts/) ──────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# ── Find project dir ──────────────────────────────────────────────────────────
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# ── Inject rules digest ───────────────────────────────────────────────────────
DIGEST_FILE="$PLUGIN_ROOT/shared/rules/RULES_DIGEST.md"

# Fallback: check if running from inside the repo itself
if [[ ! -f "$DIGEST_FILE" ]]; then
  DIGEST_FILE="$PROJECT_DIR/shared/rules/RULES_DIGEST.md"
fi

if [[ -f "$DIGEST_FILE" ]]; then

  # Read active profiles (one per line, lowercase)
  PROFILES_FILE="$PROJECT_DIR/.claude/ACTIVE_PROFILES"
  ACTIVE_PROFILES=""
  if [[ -f "$PROFILES_FILE" ]]; then
    ACTIVE_PROFILES=$(tr '[:upper:]' '[:lower:]' < "$PROFILES_FILE" | tr '\n' ' ')
  fi

  # Extract SHARED section (always inject — everything between ## SHARED and next ##)
  SHARED_RULES=$(awk '/^## SHARED/{ found=1; next } found && /^## [A-Z]/{exit} found{ print }' "$DIGEST_FILE" || true)

  # Extract sections for active profiles only
  PROFILE_RULES=""
  for profile in mobile backend qa frontend product; do
    if echo "$ACTIVE_PROFILES" | grep -qw "$profile"; then
      SECTION=$(awk "/^## ${profile^^} PROFILE/{ found=1; next } found && /^## [A-Z]/{ exit } found{ print }" "$DIGEST_FILE" || true)
      [[ -n "$SECTION" ]] && PROFILE_RULES="${PROFILE_RULES}
${SECTION}"
    fi
  done

  # ── Print rules digest as the FIRST content in session context ────────────
  cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Claude Crew — Active Rules Digest
 Profiles: ${ACTIVE_PROFILES:-none declared — shared rules only}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Apply every rule below to every action in this session.
Full rules: profiles/<profile>/rules/ | shared/rules/
EOF

  [[ -n "$SHARED_RULES" ]] && echo "$SHARED_RULES"
  [[ -n "$PROFILE_RULES" ]] && echo "$PROFILE_RULES"

  echo ""
  echo "[rules-digest] Injected: shared + ${ACTIVE_PROFILES:-none}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""

fi

# ── Find project memory file ──────────────────────────────────────────────────
MEMORY_FILE="$PROJECT_DIR/.claude/memory/MEMORY.md"

# Also check parent directories (monorepo support)
if [[ ! -f "$MEMORY_FILE" ]]; then
  dir="$PROJECT_DIR"
  for _ in 1 2 3; do
    dir="$(dirname "$dir")"
    if [[ -f "$dir/.claude/memory/MEMORY.md" ]]; then
      MEMORY_FILE="$dir/.claude/memory/MEMORY.md"
      break
    fi
  done
fi

if [[ ! -f "$MEMORY_FILE" ]]; then
  exit 0  # No memory file yet — silent exit, don't inject anything
fi

# ── Count entries ─────────────────────────────────────────────────────────────
TOTAL=$(grep -c '^\[20' "$MEMORY_FILE" 2>/dev/null || echo "0")

if [[ "$TOTAL" -eq 0 ]]; then
  exit 0  # File exists but has no entries yet
fi

# ── Extract only high and medium confidence entries ───────────────────────────
HIGH=$(grep -A1 'confidence:high' "$MEMORY_FILE" 2>/dev/null | grep -v '^--$' | grep -v 'confidence:' | grep -v '^$' | head -40 || true)
MEDIUM=$(grep -A1 'confidence:medium' "$MEMORY_FILE" 2>/dev/null | grep -v '^--$' | grep -v 'confidence:' | grep -v '^$' | head -20 || true)
LOW_COUNT=$(grep -c 'confidence:low' "$MEMORY_FILE" 2>/dev/null || echo "0")

# ── Inject memory brief into Claude's context ─────────────────────────────────
cat <<EOF

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 Claude Crew — Project Memory  ($TOTAL entries)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This project has accumulated knowledge from previous sessions.
Apply these learnings to every response in this session.

EOF

if [[ -n "$HIGH" ]]; then
  echo "### Confirmed rules (confidence:high — treat as hard rules)"
  echo "$HIGH" | sed 's/^/  /' | grep -v '^\s*$' || true
  echo ""
fi

if [[ -n "$MEDIUM" ]]; then
  echo "### Observed patterns (confidence:medium — use as strong suggestions)"
  echo "$MEDIUM" | sed 's/^/  /' | grep -v '^\s*$' || true
  echo ""
fi

if [[ "$LOW_COUNT" -gt 0 ]]; then
  echo "### $LOW_COUNT unvalidated entries (confidence:low) — run /memory-review to promote or discard"
  echo ""
fi

cat <<EOF
Full memory: $MEMORY_FILE
Run /memory-review to curate. Run /learn to add an explicit learning.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF

# ── Subconscious: initialise session event log ────────────────────────────────
SC_DIR="$PROJECT_DIR/.claude/subconscious"
mkdir -p "$SC_DIR" 2>/dev/null || true
# Clear the previous session's event log so this session starts clean
: > "$SC_DIR/session.jsonl" 2>/dev/null || true
echo "0" > "$SC_DIR/event_count" 2>/dev/null || true
echo "0" > "$SC_DIR/whisper_event_count" 2>/dev/null || true
