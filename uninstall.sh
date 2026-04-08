#!/usr/bin/env bash
# ============================================================
#  Claude Crew — Uninstaller
#
#  Usage:
#    ./uninstall.sh              # remove from current project
#    ./uninstall.sh --global     # remove global install
# ============================================================

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "  → $*"; }
success() { echo -e "${GREEN}  ✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}  ⚠${RESET} $*"; }

GLOBAL=false
PROJECT_DIR="$(pwd)"

while [[ $# -gt 0 ]]; do
  case $1 in
    --global)   GLOBAL=true; shift ;;
    --project)  PROJECT_DIR="$2"; shift 2 ;;
    *) echo "Unknown: $1"; exit 1 ;;
  esac
done

if $GLOBAL; then
  TARGET_CLAUDE="$HOME/.claude"
  CLAUDE_MD="$HOME/.claude/CLAUDE.md"
else
  TARGET_CLAUDE="$PROJECT_DIR/.claude"
  CLAUDE_MD="$PROJECT_DIR/CLAUDE.md"
fi

echo ""
echo -e "${BOLD}  Claude Crew — Uninstaller${RESET}"
echo ""

# Remove agents
if [[ -d "$TARGET_CLAUDE/agents" ]]; then
  # Only remove claude-crew agents, not any custom ones
  CREW_AGENTS=(
    android-developer.md ios-developer.md
    android-reviewer.md ios-reviewer.md mobile-architect.md
    mobile-performance.md mobile-security.md mobile-test-planner.md
    release-manager.md ui-accessibility.md
    git-flow-advisor.md
  )
  for agent in "${CREW_AGENTS[@]}"; do
    [[ -f "$TARGET_CLAUDE/agents/$agent" ]] && rm "$TARGET_CLAUDE/agents/$agent" && info "Removed agent: $agent"
  done
  # Remove agents dir if now empty
  [[ -z "$(ls -A "$TARGET_CLAUDE/agents" 2>/dev/null)" ]] && rmdir "$TARGET_CLAUDE/agents" && success "Removed .claude/agents/"
fi

# Remove commands
CREW_COMMANDS=(sdlc.md android-review.md ios-review.md mobile-test.md mobile-release.md detect-arch.md detect-gitflow.md sprint-start.md)
for cmd in "${CREW_COMMANDS[@]}"; do
  [[ -f "$TARGET_CLAUDE/commands/$cmd" ]] && rm "$TARGET_CLAUDE/commands/$cmd" && info "Removed command: $cmd"
done
[[ -d "$TARGET_CLAUDE/commands" && -z "$(ls -A "$TARGET_CLAUDE/commands" 2>/dev/null)" ]] && rmdir "$TARGET_CLAUDE/commands"

# Remove hooks
[[ -f "$TARGET_CLAUDE/hooks/pre-tool-use.sh" ]]  && rm "$TARGET_CLAUDE/hooks/pre-tool-use.sh"
[[ -f "$TARGET_CLAUDE/hooks/post-tool-use.sh" ]] && rm "$TARGET_CLAUDE/hooks/post-tool-use.sh"
[[ -d "$TARGET_CLAUDE/hooks" && -z "$(ls -A "$TARGET_CLAUDE/hooks" 2>/dev/null)" ]] && rmdir "$TARGET_CLAUDE/hooks"
success "Removed hooks"

# Strip claude-crew block from CLAUDE.md
if [[ -f "$CLAUDE_MD" ]] && grep -q "claude-crew: begin" "$CLAUDE_MD"; then
  # Remove the block between <!-- claude-crew: begin --> and <!-- claude-crew: end -->
  python3 -c "
import re, sys
path = sys.argv[1]
with open(path) as f: content = f.read()
cleaned = re.sub(r'\n?---\n<!-- claude-crew: begin -->.*?<!-- claude-crew: end -->\n?', '', content, flags=re.DOTALL)
with open(path, 'w') as f: f.write(cleaned.strip() + '\n')
" "$CLAUDE_MD"
  success "Removed Claude Crew section from CLAUDE.md"
fi

# Remove skills from .claude/skills/
CREW_SKILLS=(android-feature ios-feature mobile-test mobile-release mobile-code-review accessibility-audit performance-profile git-flow)
for skill in "${CREW_SKILLS[@]}"; do
  [[ -d "$TARGET_CLAUDE/skills/$skill" ]] && rm -rf "$TARGET_CLAUDE/skills/$skill" && info "Removed skill: $skill"
done
[[ -d "$TARGET_CLAUDE/skills" && -z "$(ls -A "$TARGET_CLAUDE/skills" 2>/dev/null)" ]] && rmdir "$TARGET_CLAUDE/skills"

# Remove rules/ if it was installed by claude-crew
if [[ -d "$PROJECT_DIR/rules" ]]; then
  read -r -p "  Remove $PROJECT_DIR/rules? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] && rm -rf "$PROJECT_DIR/rules" && success "Removed rules/"
fi

echo ""
success "Claude Crew uninstalled."
echo ""
