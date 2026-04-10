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

# ── Remove agents (shared + all profile agents) ───────────────────────────────
if [[ -d "$TARGET_CLAUDE/agents" ]]; then
  CREW_AGENTS=(
    # shared agents
    git-flow-advisor.md jira-advisor.md scrum-master.md learning-agent.md
    # mobile agents
    android-developer.md ios-developer.md android-reviewer.md ios-reviewer.md
    mobile-architect.md mobile-performance.md mobile-security.md
    mobile-test-planner.md release-manager.md ui-accessibility.md
    # backend agents
    api-developer.md api-reviewer.md backend-architect.md
    database-specialist.md devops-advisor.md backend-security.md backend-test-planner.md
    # qa agents
    test-strategist.md automation-engineer.md performance-tester.md
    bug-triager.md qa-lead.md
    # product agents
    prd-author.md user-story-writer.md product-manager.md
    metrics-analyst.md stakeholder-advisor.md
    # data agents
    data-engineer.md ml-engineer.md analytics-engineer.md
    sql-specialist.md data-reviewer.md
    # frontend agents
    frontend-developer.md frontend-reviewer.md ui-engineer.md
    accessibility-auditor.md frontend-architect.md
  )
  for agent in "${CREW_AGENTS[@]}"; do
    [[ -f "$TARGET_CLAUDE/agents/$agent" ]] && rm "$TARGET_CLAUDE/agents/$agent" && info "Removed agent: $agent"
  done
  [[ -z "$(ls -A "$TARGET_CLAUDE/agents" 2>/dev/null)" ]] && rmdir "$TARGET_CLAUDE/agents" && success "Removed .claude/agents/"
fi

# ── Remove commands ───────────────────────────────────────────────────────────
CREW_COMMANDS=(
  # shared commands
  commit-push-pr.md detect-gitflow.md detect-jira.md learn.md memory-review.md
  standup.md retro.md sprint-start.md sprint-health.md teach-mode.md profile.md
  # mobile commands
  sdlc.md android-review.md ios-review.md mobile-test.md mobile-release.md
  detect-arch.md security-scan.md
  # backend commands
  api-sdlc.md api-review.md db-migration.md openapi-spec.md
  backend-security-scan.md detect-backend-stack.md
  # qa commands
  test-plan.md bug-report.md regression-suite.md performance-test.md qa-review.md
  # product commands
  prd.md user-story.md feature-brief.md acceptance-criteria.md metrics-review.md
  # data commands
  pipeline-review.md sql-review.md data-model.md ml-experiment.md dbt-review.md
  # frontend commands
  frontend-sdlc.md frontend-review.md accessibility-audit.md
  bundle-analysis.md detect-frontend-stack.md
)
for cmd in "${CREW_COMMANDS[@]}"; do
  [[ -f "$TARGET_CLAUDE/commands/$cmd" ]] && rm "$TARGET_CLAUDE/commands/$cmd" && info "Removed command: $cmd"
done
[[ -d "$TARGET_CLAUDE/commands" && -z "$(ls -A "$TARGET_CLAUDE/commands" 2>/dev/null)" ]] && rmdir "$TARGET_CLAUDE/commands"

# ── Remove hooks ──────────────────────────────────────────────────────────────
[[ -f "$TARGET_CLAUDE/hooks/pre-tool-use.sh" ]]    && rm "$TARGET_CLAUDE/hooks/pre-tool-use.sh"
[[ -f "$TARGET_CLAUDE/hooks/post-tool-use.sh" ]]   && rm "$TARGET_CLAUDE/hooks/post-tool-use.sh"
[[ -f "$TARGET_CLAUDE/hooks/session-start.sh" ]]   && rm "$TARGET_CLAUDE/hooks/session-start.sh"
[[ -f "$TARGET_CLAUDE/hooks/session-end.sh" ]]     && rm "$TARGET_CLAUDE/hooks/session-end.sh"
[[ -d "$TARGET_CLAUDE/hooks" && -z "$(ls -A "$TARGET_CLAUDE/hooks" 2>/dev/null)" ]] && rmdir "$TARGET_CLAUDE/hooks"
success "Removed hooks"

# ── Remove profile files ──────────────────────────────────────────────────────
[[ -f "$TARGET_CLAUDE/ACTIVE_PROFILES" ]]    && rm "$TARGET_CLAUDE/ACTIVE_PROFILES"    && info "Removed ACTIVE_PROFILES"
[[ -f "$TARGET_CLAUDE/INSTALLED_PROFILES" ]] && rm "$TARGET_CLAUDE/INSTALLED_PROFILES" && info "Removed INSTALLED_PROFILES"

# ── Remove skills ─────────────────────────────────────────────────────────────
CREW_SKILLS=(
  # shared skills
  git-flow jira-flow scrum
  # mobile skills
  android-feature ios-feature mobile-test mobile-release mobile-code-review
  accessibility-audit performance-profile
  # backend skills
  api-feature backend-code-review service-deployment
  # qa skills
  test-planning automation-framework bug-lifecycle
  # product skills
  product-discovery prd-writing story-mapping
  # data skills
  pipeline-development data-modeling ml-workflow
  # frontend skills
  component-development frontend-code-review performance-audit
)
for skill in "${CREW_SKILLS[@]}"; do
  [[ -d "$TARGET_CLAUDE/skills/$skill" ]] && rm -rf "$TARGET_CLAUDE/skills/$skill" && info "Removed skill: $skill"
done
[[ -d "$TARGET_CLAUDE/skills" && -z "$(ls -A "$TARGET_CLAUDE/skills" 2>/dev/null)" ]] && rmdir "$TARGET_CLAUDE/skills"

# ── Strip claude-crew block from CLAUDE.md ────────────────────────────────────
if [[ -f "$CLAUDE_MD" ]] && grep -q "claude-crew: begin" "$CLAUDE_MD"; then
  python3 -c "
import re, sys
path = sys.argv[1]
with open(path) as f: content = f.read()
cleaned = re.sub(r'\n?---\n<!-- claude-crew: begin -->.*?<!-- claude-crew: end -->\n?', '', content, flags=re.DOTALL)
with open(path, 'w') as f: f.write(cleaned.strip() + '\n')
" "$CLAUDE_MD"
  success "Removed Claude Crew section from CLAUDE.md"
fi

# ── Remove rules/ if installed by claude-crew ─────────────────────────────────
if [[ -d "$PROJECT_DIR/rules" ]]; then
  read -r -p "  Remove $PROJECT_DIR/rules? [y/N] " ans
  [[ "$ans" =~ ^[Yy]$ ]] && rm -rf "$PROJECT_DIR/rules" && success "Removed rules/"
fi

# ── Optionally remove memory ──────────────────────────────────────────────────
if [[ -f "$TARGET_CLAUDE/memory/MEMORY.md" ]]; then
  read -r -p "  Remove $TARGET_CLAUDE/memory/MEMORY.md (accumulated project learnings)? [y/N] " ans
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    rm -f "$TARGET_CLAUDE/memory/MEMORY.md"
    rmdir "$TARGET_CLAUDE/memory" 2>/dev/null || true
    success "Removed .claude/memory/MEMORY.md"
  else
    warn "Keeping .claude/memory/MEMORY.md — your project learnings are preserved"
  fi
fi

echo ""
success "Claude Crew uninstalled."
echo ""
