#!/usr/bin/env bash
# ============================================================
# Claude Crew — SessionStart Hook
#
# Fires at the start of every Claude Code session.
# Reads .claude/memory/MEMORY.md and injects accumulated
# project knowledge from previous sessions into context.
#
# Rule enforcement is handled natively by Claude Code via
# .claude/rules/ (path-scoped rules installed per profile).
#
# Output to stdout is injected into Claude's context.
# ============================================================

set -uo pipefail

# ── Find project memory file ──────────────────────────────────────────────────
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
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

# ── Subconscious: initialise session event log (always runs, even with no memory) ─
SC_DIR="$PROJECT_DIR/.claude/subconscious"
mkdir -p "$SC_DIR" 2>/dev/null || true
: > "$SC_DIR/session.jsonl" 2>/dev/null || true
echo "0" > "$SC_DIR/event_count" 2>/dev/null || true
echo "0" > "$SC_DIR/whisper_event_count" 2>/dev/null || true

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

