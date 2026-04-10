#!/usr/bin/env bash
# ============================================================
#  Claude Crew — Multi-Team Agent Harness Installer
#  https://github.com/balamuthu1/claude-crew
#
#  Usage:
#    ./install.sh                              # mobile profile (default, backward compat)
#    ./install.sh --profile mobile             # explicit mobile profile
#    ./install.sh --profile mobile,qa          # multiple profiles
#    ./install.sh --profile all                # every profile
#    ./install.sh --global                     # global install (~/.claude)
#    ./install.sh --project ~/MyApp            # specific project
#    ./install.sh --dry-run                    # preview without changes
#    ./install.sh --list-profiles              # list available profiles and exit
#    ./install.sh --upgrade                    # re-run on existing install
# ============================================================

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${BLUE}  →${RESET} $*"; }
success() { echo -e "${GREEN}  ✓${RESET} $*"; }
warn()    { echo -e "${YELLOW}  ⚠${RESET} $*"; }
error()   { echo -e "${RED}  ✗${RESET} $*" >&2; }
header()  { echo -e "\n${BOLD}$*${RESET}"; }

# ── Available profiles ────────────────────────────────────────────────────────
ALL_PROFILES=(mobile backend qa product data frontend)

# Profile display info (parallel arrays)
PROFILE_LABELS=(
  "Mobile Engineering  — Android & iOS developers, reviewers, architect, security, test, a11y"
  "Backend Engineering — API developer, architect, DB specialist, DevOps, security, test"
  "QA Engineering      — Test strategist, automation, performance, bug triage, QA lead"
  "Product Management  — PRD author, user story writer, product manager, metrics, stakeholder"
  "Data Engineering    — Data engineer, ML engineer, analytics, SQL specialist, reviewer"
  "Frontend Engineering— Frontend developer, reviewer, UI engineer, accessibility, architect"
)

# ── Defaults ──────────────────────────────────────────────────────────────────
GLOBAL=false
PROJECT_DIR="$(pwd)"
DRY_RUN=false
UPGRADE=false
LIST_PROFILES=false
SELECTED_PROFILES=("mobile")  # default: mobile (backward compat)
PROFILES_EXPLICITLY_SET=false
REPO_URL="https://github.com/balamuthu1/claude-crew"
REPO_BRANCH="main"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" &>/dev/null && pwd)"
LOCAL_INSTALL=false
if [[ -d "$SCRIPT_DIR/profiles" ]]; then
  LOCAL_INSTALL=true
fi

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --global)         GLOBAL=true; shift ;;
    --project)        PROJECT_DIR="$2"; shift 2 ;;
    --dry-run)        DRY_RUN=true; shift ;;
    --upgrade)        UPGRADE=true; shift ;;
    --list-profiles)  LIST_PROFILES=true; shift ;;
    --profile)
      PROFILES_EXPLICITLY_SET=true
      IFS=',' read -ra SELECTED_PROFILES <<< "$2"
      shift 2 ;;
    --help|-h)
      echo "Usage: install.sh [OPTIONS]"
      echo ""
      echo "  --profile <name(s)>   Profiles to install (comma-separated, or 'all')"
      echo "                        Available: mobile, backend, qa, product, data, frontend"
      echo "                        Default: mobile (backward compatible)"
      echo "  --global              Install to ~/.claude/ (available in all projects)"
      echo "  --project <dir>       Install to <dir>/.claude/ (default: current dir)"
      echo "  --dry-run             Show what would happen without changing anything"
      echo "  --upgrade             Re-run on existing install, merge new content"
      echo "  --list-profiles       List available profiles and exit"
      echo ""
      echo "Examples:"
      echo "  ./install.sh                          # mobile only (default)"
      echo "  ./install.sh --profile mobile,qa      # mobile + QA"
      echo "  ./install.sh --profile all --global   # everything, global"
      exit 0 ;;
    *) error "Unknown argument: $1"; exit 1 ;;
  esac
done

# ── List profiles mode ────────────────────────────────────────────────────────
if $LIST_PROFILES; then
  echo ""
  echo -e "${BOLD}Available Claude Crew profiles:${RESET}"
  echo ""
  for i in "${!ALL_PROFILES[@]}"; do
    echo -e "  ${BOLD}${ALL_PROFILES[$i]}${RESET}  —  ${PROFILE_LABELS[$i]}"
  done
  echo ""
  echo -e "Install a profile:  ./install.sh --profile ${ALL_PROFILES[0]}"
  echo -e "Install multiple:   ./install.sh --profile mobile,qa"
  echo -e "Install all:        ./install.sh --profile all"
  echo ""
  exit 0
fi

# ── Expand 'all' profile shorthand ───────────────────────────────────────────
if [[ "${SELECTED_PROFILES[*]}" == "all" ]]; then
  SELECTED_PROFILES=("${ALL_PROFILES[@]}")
fi

# ── Validate profile names ────────────────────────────────────────────────────
for p in "${SELECTED_PROFILES[@]}"; do
  valid=false
  for known in "${ALL_PROFILES[@]}"; do
    [[ "$p" == "$known" ]] && valid=true && break
  done
  if ! $valid; then
    error "Unknown profile: '$p'"
    echo "  Available: ${ALL_PROFILES[*]}"
    exit 1
  fi
done

# ── Target directory ──────────────────────────────────────────────────────────
if $GLOBAL; then
  TARGET_CLAUDE="$HOME/.claude"
  TARGET_DESC="global (~/.claude)"
else
  TARGET_CLAUDE="$PROJECT_DIR/.claude"
  TARGET_DESC="project ($PROJECT_DIR/.claude)"
fi

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════╗${RESET}"
echo -e "${BOLD}║          Claude Crew — Multi-Team Agent Harness          ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  Install mode  : ${BOLD}$(if $GLOBAL; then echo 'GLOBAL'; else echo 'PROJECT'; fi)${RESET}"
echo -e "  Target        : ${BOLD}$TARGET_DESC${RESET}"
echo -e "  Profiles      : ${BOLD}${SELECTED_PROFILES[*]}${RESET}"
if $DRY_RUN; then
  echo -e "  Mode          : ${YELLOW}DRY RUN — no files will be changed${RESET}"
fi
echo ""

# ── Preflight checks ──────────────────────────────────────────────────────────
header "Preflight checks"

if command -v claude &>/dev/null; then
  CLAUDE_VERSION=$(claude --version 2>/dev/null | head -1 || echo "unknown")
  success "Claude Code found: $CLAUDE_VERSION"
else
  warn "Claude Code CLI not found. Install from https://claude.ai/code"
  warn "Continuing install — files will be ready when Claude Code is installed."
fi

if ! $GLOBAL && [[ ! -d "$PROJECT_DIR" ]]; then
  error "Project directory not found: $PROJECT_DIR"
  exit 1
fi

# ── Resolve source base ───────────────────────────────────────────────────────
if $LOCAL_INSTALL; then
  SRC_BASE="$SCRIPT_DIR"
  success "Using local source: $SCRIPT_DIR"
else
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  info "Downloading claude-crew from GitHub (branch: $REPO_BRANCH)..."
  if command -v git &>/dev/null; then
    git clone --depth 1 --branch "$REPO_BRANCH" --quiet "$REPO_URL.git" "$TMP_DIR/claude-crew" 2>/dev/null \
      || { error "Failed to clone $REPO_URL. Check your internet connection."; exit 1; }
    SRC_BASE="$TMP_DIR/claude-crew"
  else
    error "git is required for remote install."
    exit 1
  fi
  success "Downloaded claude-crew source"
fi

# ── Helpers ───────────────────────────────────────────────────────────────────
copy_dir() {
  local src="$1" dst="$2" label="$3"
  if [[ ! -d "$src" ]]; then
    warn "Source not found, skipping: $src"
    return
  fi
  if $DRY_RUN; then
    info "[dry-run] Would copy $src → $dst"
    return
  fi
  mkdir -p "$dst"
  cp -r "$src"/. "$dst/"
  success "Installed $label → $dst"
}

copy_file() {
  local src="$1" dst="$2" label="$3"
  [[ ! -f "$src" ]] && return
  if $DRY_RUN; then
    info "[dry-run] Would copy $src → $dst"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  cp "$src" "$dst"
  success "Installed $label → $dst"
}

merge_settings() {
  local src="$1" dst="$2"
  if $DRY_RUN; then
    info "[dry-run] Would merge settings.json → $dst"
    return
  fi
  mkdir -p "$(dirname "$dst")"
  if [[ ! -f "$dst" ]]; then
    cp "$src" "$dst"
    success "Installed settings.json → $dst"
  else
    python3 - "$src" "$dst" <<'PYEOF'
import json, sys
src_path, dst_path = sys.argv[1], sys.argv[2]
with open(src_path) as f: src = json.load(f)
with open(dst_path) as f: dst = json.load(f)

for event, matchers in src.get("hooks", {}).items():
    dst.setdefault("hooks", {}).setdefault(event, [])
    existing_cmds = {
        h.get("command","")
        for entry in dst["hooks"][event]
        for h in entry.get("hooks", [])
    }
    for matcher_block in matchers:
        new_hooks = [h for h in matcher_block.get("hooks", []) if h.get("command","") not in existing_cmds]
        if new_hooks:
            dst["hooks"][event].append({**matcher_block, "hooks": new_hooks})

for key in ("allow", "deny"):
    existing = set(dst.get("permissions", {}).get(key, []))
    incoming = set(src.get("permissions", {}).get(key, []))
    if incoming - existing:
        dst.setdefault("permissions", {})[key] = sorted(existing | incoming)

with open(dst_path, "w") as f:
    json.dump(dst, f, indent=2)
    f.write("\n")
PYEOF
    success "Merged settings.json → $dst"
  fi
}

merge_profile_permissions() {
  local profile_json="$1" settings_dst="$2"
  [[ ! -f "$profile_json" ]] && return
  if $DRY_RUN; then
    info "[dry-run] Would merge $profile_json permissions → $settings_dst"
    return
  fi
  [[ ! -f "$settings_dst" ]] && return
  python3 - "$profile_json" "$settings_dst" <<'PYEOF'
import json, sys
profile_path, dst_path = sys.argv[1], sys.argv[2]
with open(profile_path) as f: profile = json.load(f)
with open(dst_path) as f: dst = json.load(f)

perms = profile.get("permissions", {})
for key in ("allow", "deny"):
    incoming = set(perms.get(key, []))
    existing = set(dst.get("permissions", {}).get(key, []))
    if incoming - existing:
        dst.setdefault("permissions", {})[key] = sorted(existing | incoming)

with open(dst_path, "w") as f:
    json.dump(dst, f, indent=2)
    f.write("\n")
PYEOF
}

install_claude_md() {
  local src="$1" dst="$2"
  if $DRY_RUN; then
    info "[dry-run] Would install/append CLAUDE.md → $dst"
    return
  fi
  if [[ ! -f "$dst" ]]; then
    cp "$src" "$dst"
    success "Installed CLAUDE.md → $dst"
  else
    if grep -q "Claude Crew" "$dst" 2>/dev/null; then
      warn "CLAUDE.md already contains Claude Crew content — skipping"
    else
      echo "" >> "$dst"
      echo "---" >> "$dst"
      echo "<!-- claude-crew: begin -->" >> "$dst"
      cat "$src" >> "$dst"
      echo "<!-- claude-crew: end -->" >> "$dst"
      success "Appended Claude Crew section to existing CLAUDE.md"
    fi
  fi
}

# ── Install shared layer (always) ─────────────────────────────────────────────
header "Installing shared layer"

copy_dir "$SRC_BASE/shared/agents"   "$TARGET_CLAUDE/agents"   "shared agents (git-flow-advisor, jira-advisor, scrum-master, learning-agent)"
copy_dir "$SRC_BASE/shared/commands" "$TARGET_CLAUDE/commands" "shared commands (commit-push-pr, detect-gitflow, learn, memory-review, standup, retro, ...)"
copy_dir "$SRC_BASE/shared/skills"   "$TARGET_CLAUDE/skills"   "shared skills (git-flow, jira-flow, scrum)"

# Hooks → .claude/hooks/
copy_dir "$SRC_BASE/shared/scripts"  "$TARGET_CLAUDE/hooks"    "lifecycle hooks"
if ! $DRY_RUN && [[ -d "$TARGET_CLAUDE/hooks" ]]; then
  chmod +x "$TARGET_CLAUDE/hooks"/*.sh 2>/dev/null || true
  success "Hooks marked executable"
fi

# settings.json
merge_settings "$SRC_BASE/settings.json" "$TARGET_CLAUDE/settings.json"

# CLAUDE.md
if $GLOBAL; then
  install_claude_md "$SRC_BASE/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
else
  install_claude_md "$SRC_BASE/CLAUDE.md" "$PROJECT_DIR/CLAUDE.md"
  # Shared rules
  copy_dir "$SRC_BASE/shared/rules" "$PROJECT_DIR/rules" "shared rules (security-guardrails, scrum)"
fi

# Memory file
if ! $GLOBAL; then
  DST_MEMORY="$TARGET_CLAUDE/memory/MEMORY.md"
  if $DRY_RUN; then
    info "[dry-run] Would install .claude/memory/MEMORY.md"
  elif [[ ! -f "$DST_MEMORY" ]]; then
    mkdir -p "$TARGET_CLAUDE/memory"
    cp "$SRC_BASE/memory/MEMORY.md" "$DST_MEMORY" 2>/dev/null || true
    [[ -f "$DST_MEMORY" ]] && success "Installed .claude/memory/MEMORY.md"
  else
    warn ".claude/memory/MEMORY.md already exists — preserving existing learnings"
  fi
fi

# ── Install each selected profile ────────────────────────────────────────────
for profile in "${SELECTED_PROFILES[@]}"; do
  header "Installing profile: $profile"

  SRC_PROFILE="$SRC_BASE/profiles/$profile"
  if [[ ! -d "$SRC_PROFILE" ]]; then
    error "Profile directory not found: $SRC_PROFILE"
    continue
  fi

  # Agents
  [[ -d "$SRC_PROFILE/agents" ]] && copy_dir "$SRC_PROFILE/agents" "$TARGET_CLAUDE/agents" "$profile agents"

  # Commands
  [[ -d "$SRC_PROFILE/commands" ]] && copy_dir "$SRC_PROFILE/commands" "$TARGET_CLAUDE/commands" "$profile commands"

  # Skills
  [[ -d "$SRC_PROFILE/skills" ]] && copy_dir "$SRC_PROFILE/skills" "$TARGET_CLAUDE/skills" "$profile skills"

  # Rules (project install only)
  if ! $GLOBAL && [[ -d "$SRC_PROFILE/rules" ]]; then
    copy_dir "$SRC_PROFILE/rules" "$PROJECT_DIR/rules" "$profile rules"
  fi

  # Merge profile permissions into settings.json
  merge_profile_permissions "$SRC_PROFILE/profile.json" "$TARGET_CLAUDE/settings.json"

  # Profile-specific config template
  if ! $GLOBAL; then
    PROFILE_JSON="$SRC_PROFILE/profile.json"
    if [[ -f "$PROFILE_JSON" ]]; then
      CONFIG_TEMPLATE=$(python3 -c "import json,sys; d=json.load(open(sys.argv[1])); print(d.get('configTemplate',''))" "$PROFILE_JSON" 2>/dev/null || echo "")
      if [[ -n "$CONFIG_TEMPLATE" && ! -f "$PROJECT_DIR/$CONFIG_TEMPLATE" && -f "$SRC_BASE/$CONFIG_TEMPLATE" ]]; then
        copy_file "$SRC_BASE/$CONFIG_TEMPLATE" "$PROJECT_DIR/$CONFIG_TEMPLATE" "$CONFIG_TEMPLATE template"
      fi
    fi
  fi

done

# ── Write ACTIVE_PROFILES and INSTALLED_PROFILES ──────────────────────────────
if ! $DRY_RUN; then
  printf '%s\n' "${SELECTED_PROFILES[@]}" > "$TARGET_CLAUDE/ACTIVE_PROFILES"
  success "Wrote .claude/ACTIVE_PROFILES: ${SELECTED_PROFILES[*]}"

  # INSTALLED_PROFILES: merge with existing (for upgrade support)
  INSTALLED_FILE="$TARGET_CLAUDE/INSTALLED_PROFILES"
  if [[ -f "$INSTALLED_FILE" ]]; then
    mapfile -t existing_installed < "$INSTALLED_FILE"
    combined=("${existing_installed[@]}" "${SELECTED_PROFILES[@]}")
    printf '%s\n' "${combined[@]}" | sort -u > "$INSTALLED_FILE"
  else
    printf '%s\n' "${SELECTED_PROFILES[@]}" > "$INSTALLED_FILE"
  fi
  success "Wrote .claude/INSTALLED_PROFILES"
fi

# ── Project-specific shared config templates ─────────────────────────────────
if ! $GLOBAL && ! $DRY_RUN; then
  for cfg in git-flow.config.md jira.config.md; do
    DST="$PROJECT_DIR/$cfg"
    SRC="$SRC_BASE/$cfg"
    if [[ ! -f "$DST" && -f "$SRC" ]]; then
      cp "$SRC" "$DST"
      success "Installed $cfg"
    fi
  done
fi

# ── Post-install summary ──────────────────────────────────────────────────────
header "Installation complete"

if $DRY_RUN; then
  warn "DRY RUN — nothing was changed. Remove --dry-run to install."
  exit 0
fi

echo ""
echo -e "${GREEN}${BOLD}  Claude Crew is installed!${RESET}"
echo ""
echo -e "  Active profiles: ${BOLD}${SELECTED_PROFILES[*]}${RESET}"
echo ""
echo -e "  ${BOLD}Shared commands (always available):${RESET}"
echo "    /profile [list|status|add|use|remove]   Manage active team profiles"
echo "    /commit-push-pr                          Stage, commit, push, open PR"
echo "    /detect-gitflow                          Auto-detect git conventions"
echo "    /detect-jira                             Configure Jira project"
echo "    /standup                                 Daily standup"
echo "    /retro [format]                          Sprint retrospective"
echo "    /sprint-start [N]                        Kick off a sprint"
echo "    /sprint-health                           Sprint burndown and risk"
echo "    /teach-mode [on|off|status]              Interactive teach mode"
echo "    /learn \"<fact>\"                          Teach Claude a project rule"
echo "    /memory-review                           Curate project memory"
echo ""

# Profile-specific command hints
for profile in "${SELECTED_PROFILES[@]}"; do
  case $profile in
    mobile)
      echo -e "  ${BOLD}Mobile commands:${RESET}"
      echo "    /sdlc <feature>    Full 7-stage SDLC pipeline"
      echo "    /android-review    Android/Kotlin code review"
      echo "    /ios-review        Swift/iOS code review"
      echo "    /security-scan     OWASP Mobile Top 10 audit"
      echo "    /detect-arch       Auto-detect mobile stack"
      echo "" ;;
    backend)
      echo -e "  ${BOLD}Backend commands:${RESET}"
      echo "    /api-sdlc <feature>          Full backend SDLC pipeline"
      echo "    /api-review                  API code review + security"
      echo "    /db-migration                Generate safe DB migration"
      echo "    /backend-security-scan       OWASP API Security Top 10"
      echo "    /detect-backend-stack        Auto-detect backend stack"
      echo "" ;;
    qa)
      echo -e "  ${BOLD}QA commands:${RESET}"
      echo "    /test-plan <feature>   Risk-based test plan"
      echo "    /bug-report            Triage and structured bug report"
      echo "    /regression-suite      Automated regression tests"
      echo "    /performance-test      Load test script + SLOs"
      echo "    /qa-review             Release sign-off checklist"
      echo "" ;;
    product)
      echo -e "  ${BOLD}Product commands:${RESET}"
      echo "    /prd <feature>           Write a PRD"
      echo "    /user-story <epic>       Break epic into stories"
      echo "    /feature-brief           Stakeholder feature brief"
      echo "    /acceptance-criteria     Given/When/Then AC"
      echo "    /metrics-review          Define KPIs and event schema"
      echo "" ;;
    data)
      echo -e "  ${BOLD}Data commands:${RESET}"
      echo "    /pipeline-review    Review data pipeline"
      echo "    /sql-review         Review SQL / dbt models"
      echo "    /data-model         Design data model"
      echo "    /ml-experiment      Set up ML experiment"
      echo "    /dbt-review         Review dbt models"
      echo "" ;;
    frontend)
      echo -e "  ${BOLD}Frontend commands:${RESET}"
      echo "    /frontend-sdlc <feature>   Full frontend SDLC pipeline"
      echo "    /frontend-review           Code review + accessibility"
      echo "    /accessibility-audit       WCAG 2.1 AA audit"
      echo "    /bundle-analysis           Bundle size optimisation"
      echo "    /detect-frontend-stack     Auto-detect frontend stack"
      echo "" ;;
  esac
done

echo -e "  ${BOLD}Manage profiles:${RESET}"
echo "    /profile list                  See all profiles"
echo "    /profile add qa                Add QA profile at runtime"
echo "    ./install.sh --profile all     Install all profiles"
echo ""
echo -e "  Docs: ${BLUE}${REPO_URL}${RESET}"
echo ""
