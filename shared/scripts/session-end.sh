#!/usr/bin/env bash
# ============================================================
# Claude Crew — Stop Hook (Session-End Learning Extractor)
#
# Fires at the end of every Claude Code session.
# Reads the session transcript (via transcript_path) and extracts
# learnings into memory/MEMORY.md automatically.
#
# Also captures recent git diff to understand what was built.
#
# No user action required — this runs silently after every session.
# ============================================================

set -uo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
MEMORY_FILE="$PROJECT_DIR/.claude/memory/MEMORY.md"
TODAY=$(date +"%Y-%m-%d" 2>/dev/null || echo "unknown")

# ── Parse hook input ──────────────────────────────────────────────────────────
INPUT=$(cat)

TRANSCRIPT_PATH=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('transcript_path', ''))
except:
    print('')
" 2>/dev/null || echo "")

STOP_REASON=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('stop_reason', ''))
except:
    print('')
" 2>/dev/null || echo "")

# Only extract learnings on natural session end (not interruptions)
if [[ "$STOP_REASON" == "error" || "$STOP_REASON" == "cancelled" ]]; then
  exit 0
fi

# ── Ensure memory file exists ─────────────────────────────────────────────────
if [[ ! -f "$MEMORY_FILE" ]]; then
  exit 0  # No memory system set up — skip silently
fi

# ── Helper: append a learning entry ──────────────────────────────────────────
append_learning() {
  local section="$1"
  local confidence="$2"
  local source="$3"
  local content="$4"

  # Auto-promotion: if this content already exists, promote its confidence level
  # rather than adding a duplicate. low→medium on 2nd occurrence, medium→high on 3rd.
  if grep -qF "$content" "$MEMORY_FILE" 2>/dev/null; then
    python3 - "$MEMORY_FILE" "$content" "$TODAY" "$source" <<'PYEOF'
import sys, re
path, content, date, src = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(path) as f:
    lines = f.readlines()

promoted = False
for i, line in enumerate(lines):
    if content[:60] in line:
        # Look back up to 3 lines for the confidence tag
        for j in range(max(0, i - 3), i + 1):
            if 'confidence:low' in lines[j]:
                lines[j] = lines[j].replace('confidence:low', 'confidence:medium')
                promoted = True
                break
            elif 'confidence:medium' in lines[j]:
                lines[j] = lines[j].replace('confidence:medium', 'confidence:high')
                promoted = True
                break
        if promoted:
            break

with open(path, 'w') as f:
    f.writelines(lines)
PYEOF
    return
  fi

  # New entry — find the section and append after it
  local marker="## $section"
  if grep -q "^$marker" "$MEMORY_FILE" 2>/dev/null; then
    python3 - "$MEMORY_FILE" "$marker" "$TODAY" "$confidence" "$source" "$content" <<'PYEOF'
import sys
path, marker, date, conf, src, content = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6]
with open(path) as f:
    text = f.read()
entry = f"\n[{date} | confidence:{conf} | source:{src}]\n  {content}\n"
text = text.replace(marker + "\n", marker + "\n" + entry, 1)
with open(path, "w") as f:
    f.write(text)
PYEOF
  fi
}

# ── Queue transcript for learning-agent extraction at next session start ──────
# Instead of regex-parsing the transcript here (fragile), we write a pending
# marker that session-start.sh injects into Claude's context. Claude then
# spawns the learning-agent (an LLM) which understands natural language and
# applies proper deduplication and confidence logic.
if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
  PENDING_FILE="$PROJECT_DIR/.claude/subconscious/pending-learning.json"
  python3 - "$PENDING_FILE" "$TRANSCRIPT_PATH" "$TODAY" <<'PYEOF' 2>/dev/null || true
import json, sys, os
pending_file, transcript_path, date = sys.argv[1], sys.argv[2], sys.argv[3]
os.makedirs(os.path.dirname(pending_file), exist_ok=True)
with open(pending_file, "w") as f:
    json.dump({"transcript_path": transcript_path, "session_date": date}, f)
PYEOF
fi

# ── Subconscious: promote high-signal whispers into MEMORY.md ─────────────────
# [PATTERN] and [WARN] lines from the whisper are worth recording at confidence:low.
# [MEMORY] is skipped — already in MEMORY.md. [OBJECTIVE]/[ZONE] are session-specific.
SC_DIR="$PROJECT_DIR/.claude/subconscious"
WHISPER_FILE="$SC_DIR/WHISPER.md"

if [[ -f "$WHISPER_FILE" && -f "$MEMORY_FILE" ]]; then
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if echo "$line" | grep -qE '^\[PATTERN\]'; then
      content=$(echo "$line" | sed 's/^\[PATTERN\] //' | cut -c1-200)
      append_learning "Patterns & Best Practices" "low" "subconscious" "$content"
    fi
    if echo "$line" | grep -qE '^\[WARN\]'; then
      content=$(echo "$line" | sed 's/^\[WARN\] //' | cut -c1-200)
      append_learning "Antipatterns & Known Issues" "low" "subconscious" "$content"
    fi
  done < "$WHISPER_FILE"
fi

# ── KPI: log session_end and memory_snapshot events ──────────────────────────
KPI_FILE="$PROJECT_DIR/.claude/kpi/events.jsonl"
mkdir -p "$(dirname "$KPI_FILE")" 2>/dev/null || true
KPI_TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ" 2>/dev/null || echo "unknown")

# Files written this session (from subconscious event counter)
KPI_FILES=$(cat "$PROJECT_DIR/.claude/subconscious/event_count" 2>/dev/null || echo "0")

# Commands run: count cmd-type events in session.jsonl
KPI_CMDS=$(grep -c '"type":"cmd"' "$PROJECT_DIR/.claude/subconscious/session.jsonl" 2>/dev/null || echo "0")

KPI_REASON="${STOP_REASON:-natural}"
[[ -z "$KPI_REASON" ]] && KPI_REASON="natural"

echo "{\"ts\":\"$KPI_TS\",\"type\":\"session_end\",\"stop_reason\":\"$KPI_REASON\",\"files_written\":$KPI_FILES,\"cmds_run\":$KPI_CMDS}" \
  >> "$KPI_FILE" 2>/dev/null || true

# Memory snapshot — counts by confidence level
if [[ -f "$MEMORY_FILE" ]]; then
  python3 - "$MEMORY_FILE" "$KPI_FILE" "$KPI_TS" <<'PYEOF' 2>/dev/null || true
import json, sys, re
mem_path, kpi_path, ts = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(mem_path).read()
high   = len(re.findall(r'confidence:high',   text))
medium = len(re.findall(r'confidence:medium', text))
low    = len(re.findall(r'confidence:low',    text))
event  = {"ts": ts, "type": "memory_snapshot", "high": high, "medium": medium, "low": low}
with open(kpi_path, "a") as f:
    f.write(json.dumps(event) + "\n")
PYEOF
fi

exit 0
