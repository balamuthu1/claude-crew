#!/usr/bin/env bash
# Claude Crew — PostToolUse Hook
# Runs after Write or Edit tool calls.
# Reminds Claude to run lint/tests after modifying mobile source files.

set -euo pipefail

# Read the tool result JSON
INPUT=$(cat)

# Extract the file path that was written/edited
FILE_PATH=$(echo "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('file_path', d.get('path','')))" 2>/dev/null || echo "")

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# ── Android file changed ──────────────────────────────────────────────────────
if echo "$FILE_PATH" | grep -qE "\.(kt|gradle\.kts|gradle)$"; then
  echo ""
  echo "── Android file modified: $FILE_PATH ──"

  # Check if this is a Kotlin source file (not build file)
  if echo "$FILE_PATH" | grep -qE "\.kt$"; then
    echo "Reminder: after editing Kotlin files, run:"
    echo "  ./gradlew lint          # check for Android lint issues"
    echo "  ./gradlew test          # run unit tests"
    echo "  ./gradlew ktlintCheck   # check Kotlin code style (if ktlint is configured)"
  fi

  # Build file changed
  if echo "$FILE_PATH" | grep -qE "\.gradle(\.kts)?$"; then
    echo "Reminder: build file changed. Run './gradlew build' to validate configuration."
  fi
fi

# ── iOS file changed ──────────────────────────────────────────────────────────
if echo "$FILE_PATH" | grep -qE "\.(swift|m|h|pbxproj|xcconfig)$"; then
  echo ""
  echo "── iOS file modified: $FILE_PATH ──"

  if echo "$FILE_PATH" | grep -qE "\.swift$"; then
    echo "Reminder: after editing Swift files, run:"
    echo "  swiftlint               # check Swift code style"
    echo "  xcodebuild test -scheme \$SCHEME -destination 'platform=iOS Simulator,name=iPhone 16'"
  fi

  if echo "$FILE_PATH" | grep -q "\.pbxproj"; then
    echo "Reminder: Xcode project file changed. Verify it opens correctly in Xcode."
  fi
fi

# ── Secrets scan on any edited file ──────────────────────────────────────────
if [ -f "$FILE_PATH" ]; then
  # Simple pattern scan for common secret indicators
  if grep -qiE "(api_key|apikey|secret|password|token|private_key)\s*[=:]\s*['\"][a-zA-Z0-9+/]{20,}" "$FILE_PATH" 2>/dev/null; then
    echo ""
    echo "⚠  WARNING: Possible secret/credential detected in $FILE_PATH"
    echo "   Review the file to ensure no API keys or tokens are hardcoded."
  fi
fi

exit 0
