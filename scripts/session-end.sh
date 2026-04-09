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
MEMORY_FILE="$PROJECT_DIR/memory/MEMORY.md"
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

  # Deduplicate: skip if a very similar entry already exists
  if grep -qF "$content" "$MEMORY_FILE" 2>/dev/null; then
    return
  fi

  # Find the section and append after it
  local marker="## $section"
  if grep -q "^$marker" "$MEMORY_FILE" 2>/dev/null; then
    # Insert after the section header using python for reliability
    python3 - "$MEMORY_FILE" "$marker" "$TODAY" "$confidence" "$source" "$content" <<'PYEOF'
import sys, re
path, marker, date, conf, src, content = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5], sys.argv[6]
with open(path) as f:
    text = f.read()
entry = f"\n[{date} | confidence:{conf} | source:{src}]\n  {content}\n"
# Insert after the section header line
text = text.replace(marker + "\n", marker + "\n" + entry, 1)
with open(path, "w") as f:
    f.write(text)
PYEOF
  fi
}

# ── Extract learnings from transcript ─────────────────────────────────────────
if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then

  # Read transcript — handle both JSONL and plain text formats
  TRANSCRIPT_TEXT=$(python3 - "$TRANSCRIPT_PATH" <<'PYEOF' 2>/dev/null || cat "$TRANSCRIPT_PATH" 2>/dev/null || echo "")
import json, sys
path = sys.argv[1]
lines = []
try:
    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                obj = json.loads(line)
                # Extract text content from various message formats
                role = obj.get("role", obj.get("type", ""))
                content = obj.get("content", obj.get("message", obj.get("text", "")))
                if isinstance(content, list):
                    for block in content:
                        if isinstance(block, dict) and block.get("type") == "text":
                            lines.append(f"{role}: {block['text']}")
                elif isinstance(content, str) and content:
                    lines.append(f"{role}: {content}")
            except json.JSONDecodeError:
                lines.append(line)
except Exception as e:
    pass
print("\n".join(lines[:2000]))  # cap at ~2000 lines
PYEOF

  if [[ -n "$TRANSCRIPT_TEXT" ]]; then

    # ── Pattern: explicit corrections ("actually", "we use X not Y") ──────────
    CORRECTIONS=$(echo "$TRANSCRIPT_TEXT" | grep -iE \
      "(actually[,.]|no[,.]? we (use|do|don'?t)|that'?s (wrong|not right|incorrect)|we prefer|we always|we never|don'?t use|stop using|use .+ not |instead of .+ use)" \
      2>/dev/null | head -5 || true)

    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      # Strip the role prefix and clean up
      clean=$(echo "$line" | sed 's/^[^:]*: //' | sed 's/[[:space:]]\+/ /g' | cut -c1-200)
      [[ -z "$clean" ]] && continue
      append_learning "Team Preferences & Corrections" "low" "session-end" "$clean"
    done <<< "$CORRECTIONS"

    # ── Pattern: explicit architecture decisions ───────────────────────────────
    ARCH=$(echo "$TRANSCRIPT_TEXT" | grep -iE \
      "(we use .+ for (di|dependency|networking|database|state|navigation)|our architecture (is|uses)|we'?ve (chosen|decided|migrated to))" \
      2>/dev/null | head -3 || true)

    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      clean=$(echo "$line" | sed 's/^[^:]*: //' | sed 's/[[:space:]]\+/ /g' | cut -c1-200)
      [[ -z "$clean" ]] && continue
      append_learning "Architecture & Stack" "low" "session-end" "$clean"
    done <<< "$ARCH"

    # ── Pattern: antipatterns discovered ──────────────────────────────────────
    ANTIPATTERNS=$(echo "$TRANSCRIPT_TEXT" | grep -iE \
      "(caused (an )?anr|memory leak|crash(ed)? (in|on) (prod|production)|never (use|do|call)|don'?t (use|do|call).+(in production|in viewmodel|on main thread))" \
      2>/dev/null | head -3 || true)

    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      clean=$(echo "$line" | sed 's/^[^:]*: //' | sed 's/[[:space:]]\+/ /g' | cut -c1-200)
      [[ -z "$clean" ]] && continue
      append_learning "Antipatterns & Known Issues" "low" "session-end" "$clean"
    done <<< "$ANTIPATTERNS"

    # ── Pattern: build/test commands discovered ───────────────────────────────
    BUILD_CMDS=$(echo "$TRANSCRIPT_TEXT" | grep -iE \
      "(gradlew |xcodebuild |fastlane |swift (build|test))" \
      2>/dev/null | grep -v "^#" | head -3 || true)

    while IFS= read -r line; do
      [[ -z "$line" ]] && continue
      clean=$(echo "$line" | sed 's/^[^:]*: //' | sed 's/[[:space:]]\+/ /g' | cut -c1-200)
      [[ -z "$clean" ]] && continue
      append_learning "Build & CI" "low" "session-end" "$clean"
    done <<< "$BUILD_CMDS"

  fi
fi

# ── Extract learnings from git diff (what was actually built) ─────────────────
if command -v git &>/dev/null && git -C "$PROJECT_DIR" rev-parse --git-dir &>/dev/null; then

  # Check if any files were committed this session
  RECENT_COMMITS=$(git -C "$PROJECT_DIR" log --oneline --since="30 minutes ago" 2>/dev/null | head -5 || true)

  if [[ -n "$RECENT_COMMITS" ]]; then
    # Detect patterns from committed files
    CHANGED_FILES=$(git -C "$PROJECT_DIR" diff --name-only HEAD~1 HEAD 2>/dev/null | head -20 || true)

    # Build command detection from gradle/xcode files
    if echo "$CHANGED_FILES" | grep -q "\.gradle"; then
      GRADLE_CMD=$(grep -r "applicationId\|versionName\|versionCode" \
        "$PROJECT_DIR/app/build.gradle.kts" "$PROJECT_DIR/app/build.gradle" 2>/dev/null \
        | head -1 || true)
      if [[ -n "$GRADLE_CMD" ]]; then
        append_learning "Build & CI" "medium" "session-end" \
          "Android app module: app/build.gradle.kts (or .gradle)"
      fi
    fi
  fi
fi

exit 0
