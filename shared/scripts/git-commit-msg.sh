#!/usr/bin/env bash
# ============================================================
# Claude Crew — Git commit-msg hook
#
# Auto-appends "Claude-Session: true" to any commit made
# while Claude Code is running. Claude Code always sets
# CLAUDE_PROJECT_DIR in its subprocess environment, so this
# fires for every git commit Claude executes — regardless of
# whether the developer uses /commit-push-pr or a direct
# git commit call.
#
# Installed to .git/hooks/commit-msg by install.sh.
# Safe to chain: only appends if the trailer is absent.
# ============================================================

if [[ -n "${CLAUDE_PROJECT_DIR:-}" ]]; then
  if ! grep -qE "^Claude-Session:" "$1" 2>/dev/null; then
    printf "\nClaude-Session: true\n" >> "$1"
  fi
fi
