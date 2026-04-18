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

# Carry the previous session's WHISPER.md forward BEFORE clearing the log,
# so returning sessions get the whisper injected into context automatically.
# This is the mechanical injection — no need for Claude to remember to read it.
WHISPER_FILE="$SC_DIR/WHISPER.md"
if [[ -f "$WHISPER_FILE" ]]; then
  WHISPER_CONTENT=$(head -c 500 "$WHISPER_FILE" 2>/dev/null || true)
  if [[ -n "$WHISPER_CONTENT" ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo " Subconscious context from last session (background priming — not hard rules)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "$WHISPER_CONTENT"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
  fi
fi

: > "$SC_DIR/session.jsonl" 2>/dev/null || true
echo "0" > "$SC_DIR/event_count" 2>/dev/null || true
echo "0" > "$SC_DIR/whisper_event_count" 2>/dev/null || true

# ── Teach mode: restore state across sessions ─────────────────────────────────
# Emit teach mode status to stdout so Claude Code injects it into context.
# Without this, teach mode silently expires on every session restart.
TEACH_MODE_FILE="$PROJECT_DIR/.claude/TEACH_MODE.md"
if [[ -f "$TEACH_MODE_FILE" ]] && grep -q "status: active" "$TEACH_MODE_FILE" 2>/dev/null; then
  ENABLED_AT=$(grep "enabled_at:" "$TEACH_MODE_FILE" 2>/dev/null | sed 's/enabled_at: //' || echo "unknown")
  echo ""
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo " TEACH MODE IS ACTIVE (enabled: $ENABLED_AT)"
  echo " After every code change: apply teach-mode-protocol.md"
  echo " Explain patterns used, quiz on the actual code, calibrate to level."
  echo " Never quiz on planning, PRDs, or workflow phases."
  echo " Turn off: /teach-mode off"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
fi

# ── KPI: log session_start event ─────────────────────────────────────────────
# Per-user files (events-<username>.jsonl) avoid git merge conflicts when the
# team commits .claude/kpi/ for shared reporting via /report --team.
KPI_TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")
KPI_USER_RAW=$(git -C "$PROJECT_DIR" config user.name 2>/dev/null \
  || git -C "$PROJECT_DIR" config user.email 2>/dev/null \
  || echo "user")
KPI_USER=$(echo "$KPI_USER_RAW" \
  | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_' | cut -c1-30)
[[ -z "$KPI_USER" ]] && KPI_USER="user"

KPI_DIR="$PROJECT_DIR/.claude/kpi"
KPI_FILE="$KPI_DIR/events-${KPI_USER}.jsonl"
mkdir -p "$KPI_DIR" 2>/dev/null || true
# Cache username so post-tool-use.sh and session-end.sh can reuse it without
# re-running git config on every file write.
echo "$KPI_USER" > "$KPI_DIR/.current-user" 2>/dev/null || true

KPI_PROFILES="[]"
PROFILES_FILE="$PROJECT_DIR/.claude/ACTIVE_PROFILES"
if [[ -f "$PROFILES_FILE" ]]; then
  KPI_PROFILES=$(python3 -c "
import sys
lines = open('$PROFILES_FILE').read().strip().splitlines()
profiles = [l.strip() for l in lines if l.strip()]
import json; print(json.dumps(profiles))
" 2>/dev/null || echo "[]")
fi
KPI_HAS_MEMORY="false"
[[ -f "$MEMORY_FILE" ]] && KPI_HAS_MEMORY="true"
KPI_TEACH="false"
[[ -f "$TEACH_MODE_FILE" ]] && grep -q "status: active" "$TEACH_MODE_FILE" 2>/dev/null && KPI_TEACH="true"

echo "{\"ts\":\"$KPI_TS\",\"type\":\"session_start\",\"user\":\"$KPI_USER\",\"profiles\":$KPI_PROFILES,\"has_memory\":$KPI_HAS_MEMORY,\"teach_mode\":$KPI_TEACH}" \
  >> "$KPI_FILE" 2>/dev/null || true

# ── Pending learning: queue LLM extraction of previous session transcript ─────
# session-end.sh writes this file instead of doing fragile regex extraction.
# We emit it here so Claude can spawn learning-agent (which has proper LLM
# comprehension) before starting the new session's work.
PENDING_LEARNING="$PROJECT_DIR/.claude/subconscious/pending-learning.json"
if [[ -f "$PENDING_LEARNING" ]]; then
  PREV_TRANSCRIPT=$(python3 -c "
import json, sys
try:
    d = json.load(open('$PENDING_LEARNING'))
    print(d.get('transcript_path', ''))
except:
    print('')
" 2>/dev/null || echo "")
  PREV_DATE=$(python3 -c "
import json, sys
try:
    d = json.load(open('$PENDING_LEARNING'))
    print(d.get('session_date', 'previous session'))
except:
    print('previous session')
" 2>/dev/null || echo "previous session")
  if [[ -n "$PREV_TRANSCRIPT" && -f "$PREV_TRANSCRIPT" ]]; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo " PENDING LEARNING EXTRACTION (from $PREV_DATE)"
    echo " Transcript: $PREV_TRANSCRIPT"
    echo " Spawn learning-agent now (background) with this transcript path."
    echo " Prompt: 'Extract project learnings from session transcript at"
    echo "   $PREV_TRANSCRIPT — update .claude/memory/MEMORY.md'"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
  fi
  rm -f "$PENDING_LEARNING" 2>/dev/null || true
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

