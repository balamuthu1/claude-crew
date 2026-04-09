#!/usr/bin/env bash
# ============================================================
#  Claude Crew — Mobile Agent Harness Installer
#  https://github.com/balamuthu1/claude-crew
#
#  Usage:
#    Global install (available in ALL projects):
#      ./install.sh --global
#
#    Project install (current directory):
#      ./install.sh
#      ./install.sh --project /path/to/your/mobile-app
#
#    Dry run (see what would be installed):
#      ./install.sh --dry-run
#      ./install.sh --global --dry-run
#
#  One-line remote install (clones repo, then runs):
#    git clone https://github.com/balamuthu1/claude-crew.git && bash claude-crew/install.sh --global
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

# ── Defaults ──────────────────────────────────────────────────────────────────
GLOBAL=false
PROJECT_DIR="$(pwd)"
DRY_RUN=false
REPO_URL="https://github.com/balamuthu1/claude-crew"
REPO_BRANCH="main"

# Source dir: where this script lives (works both locally and in tmp from curl)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" &>/dev/null && pwd)"
# If running via curl, SCRIPT_DIR is a temp dir — detect by checking for agents/
LOCAL_INSTALL=false
if [[ -d "$SCRIPT_DIR/.claude/agents" || -d "$SCRIPT_DIR/agents" ]]; then
  LOCAL_INSTALL=true
fi

# ── Argument parsing ──────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case $1 in
    --global)     GLOBAL=true; shift ;;
    --project)    PROJECT_DIR="$2"; shift 2 ;;
    --dry-run)    DRY_RUN=true; shift ;;
    --help|-h)
      echo "Usage: install.sh [--global] [--project <dir>] [--dry-run]"
      echo ""
      echo "  --global          Install to ~/.claude/ (available in all projects)"
      echo "  --project <dir>   Install to <dir>/.claude/ (default: current dir)"
      echo "  --dry-run         Show what would happen without changing anything"
      exit 0 ;;
    *) error "Unknown argument: $1"; exit 1 ;;
  esac
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
echo -e "${BOLD}║      Claude Crew — Mobile Agent Harness Installer        ║${RESET}"
echo -e "${BOLD}║      Android & iOS specialist agents for Claude Code     ║${RESET}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  Install mode : ${BOLD}$(if $GLOBAL; then echo 'GLOBAL'; else echo 'PROJECT'; fi)${RESET}"
echo -e "  Target       : ${BOLD}$TARGET_DESC${RESET}"
if $DRY_RUN; then
  echo -e "  Mode         : ${YELLOW}DRY RUN — no files will be changed${RESET}"
fi
echo ""

# ── Preflight checks ──────────────────────────────────────────────────────────
header "Preflight checks"

# Claude Code installed?
if command -v claude &>/dev/null; then
  CLAUDE_VERSION=$(claude --version 2>/dev/null | head -1 || echo "unknown")
  success "Claude Code found: $CLAUDE_VERSION"
else
  warn "Claude Code CLI not found. Install from https://claude.ai/code"
  warn "Continuing install — files will be ready when Claude Code is installed."
fi

# Project dir exists?
if ! $GLOBAL && [[ ! -d "$PROJECT_DIR" ]]; then
  error "Project directory not found: $PROJECT_DIR"
  exit 1
fi

# Fetch source files: either local or from GitHub
if $LOCAL_INSTALL; then
  SRC_AGENTS="$SCRIPT_DIR/agents"
  SRC_COMMANDS="$SCRIPT_DIR/commands"
  SRC_HOOKS="$SCRIPT_DIR/scripts"
  SRC_SKILLS="$SCRIPT_DIR/skills"
  SRC_RULES="$SCRIPT_DIR/rules"
  SRC_CLAUDE_MD="$SCRIPT_DIR/CLAUDE.md"
  SRC_SETTINGS="$SCRIPT_DIR/settings.json"
  SRC_CONFIG_MD="$SCRIPT_DIR/claude-crew.config.md"
  SRC_GITFLOW_MD="$SCRIPT_DIR/git-flow.config.md"
  SRC_JIRA_MD="$SCRIPT_DIR/jira.config.md"
  SRC_MEMORY_MD="$SCRIPT_DIR/memory/MEMORY.md"
  success "Using local source: $SCRIPT_DIR"
else
  # Remote install — download to temp dir
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  info "Downloading claude-crew from GitHub (branch: $REPO_BRANCH)..."
  if command -v git &>/dev/null; then
    git clone --depth 1 --branch "$REPO_BRANCH" --quiet "$REPO_URL.git" "$TMP_DIR/claude-crew" 2>/dev/null \
      || { error "Failed to clone $REPO_URL (branch: $REPO_BRANCH). Check your internet connection and that the branch exists."; exit 1; }
    SRC_BASE="$TMP_DIR/claude-crew"
  else
    error "git is required for remote install. Install git and retry."
    exit 1
  fi
  SRC_AGENTS="$SRC_BASE/agents"
  SRC_COMMANDS="$SRC_BASE/commands"
  SRC_HOOKS="$SRC_BASE/scripts"
  SRC_SKILLS="$SRC_BASE/skills"
  SRC_RULES="$SRC_BASE/rules"
  SRC_CLAUDE_MD="$SRC_BASE/CLAUDE.md"
  SRC_SETTINGS="$SRC_BASE/settings.json"
  SRC_CONFIG_MD="$SRC_BASE/claude-crew.config.md"
  SRC_GITFLOW_MD="$SRC_BASE/git-flow.config.md"
  SRC_JIRA_MD="$SRC_BASE/jira.config.md"
  SRC_MEMORY_MD="$SRC_BASE/memory/MEMORY.md"
  success "Downloaded claude-crew source"
fi

# ── Helper: copy directory ─────────────────────────────────────────────────────
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

# ── Helper: merge settings.json ───────────────────────────────────────────────
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
    # Merge: add permissions block if missing, preserve existing hooks
    python3 - "$src" "$dst" <<'PYEOF'
import json, sys

src_path, dst_path = sys.argv[1], sys.argv[2]
with open(src_path) as f: src = json.load(f)
with open(dst_path) as f: dst = json.load(f)

# Merge hooks: append claude-crew hooks without removing existing ones
for event, matchers in src.get("hooks", {}).items():
    dst.setdefault("hooks", {}).setdefault(event, [])
    existing_cmds = {
        h.get("command","")
        for entry in dst["hooks"][event]
        for h in entry.get("hooks", [])
    }
    for matcher_block in matchers:
        new_hooks = [
            h for h in matcher_block.get("hooks", [])
            if h.get("command","") not in existing_cmds
        ]
        if new_hooks:
            dst["hooks"][event].append({**matcher_block, "hooks": new_hooks})

# Merge permissions: union allow, union deny
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

# ── Helper: append CLAUDE.md ──────────────────────────────────────────────────
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
    # Check if already installed
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

# ── Install ───────────────────────────────────────────────────────────────────
header "Installing Claude Crew"

# Agents → .claude/agents/
copy_dir "$SRC_AGENTS" "$TARGET_CLAUDE/agents" "specialist agents (14)"

# Commands → .claude/commands/
copy_dir "$SRC_COMMANDS" "$TARGET_CLAUDE/commands" "slash commands"

# Skills → .claude/skills/   (each skill lives in its own subfolder with SKILL.md)
copy_dir "$SRC_SKILLS" "$TARGET_CLAUDE/skills" "workflow skills"

# Hooks → .claude/hooks/
copy_dir "$SRC_HOOKS" "$TARGET_CLAUDE/hooks" "lifecycle hooks"

# Make hooks executable
if ! $DRY_RUN && [[ -d "$TARGET_CLAUDE/hooks" ]]; then
  chmod +x "$TARGET_CLAUDE/hooks"/*.sh 2>/dev/null || true
  success "Hooks marked executable"
fi

# settings.json — merge carefully
merge_settings "$SRC_SETTINGS" "$TARGET_CLAUDE/settings.json"

# CLAUDE.md + project-only files
if $GLOBAL; then
  install_claude_md "$SRC_CLAUDE_MD" "$HOME/.claude/CLAUDE.md"
else
  install_claude_md "$SRC_CLAUDE_MD" "$PROJECT_DIR/CLAUDE.md"

  # rules/ — reference docs for agents
  copy_dir "$SRC_RULES" "$PROJECT_DIR/rules" "coding rules (Kotlin, Swift, Arch)"

  # claude-crew.config.md template (only if not already present)
  DST_CONFIG="$PROJECT_DIR/claude-crew.config.md"
  if $DRY_RUN; then
    info "[dry-run] Would install claude-crew.config.md → $DST_CONFIG"
  elif [[ -f "$DST_CONFIG" ]]; then
    warn "claude-crew.config.md already exists — skipping (edit it manually or run /detect-arch)"
  elif [[ -f "$SRC_CONFIG_MD" ]]; then
    cp "$SRC_CONFIG_MD" "$DST_CONFIG"
    success "Installed claude-crew.config.md → $DST_CONFIG"
    info "Run /detect-arch to auto-fill it, or edit manually to match your project"
  fi

  # git-flow.config.md template (only if not already present)
  DST_GITFLOW="$PROJECT_DIR/git-flow.config.md"
  if $DRY_RUN; then
    info "[dry-run] Would install git-flow.config.md → $DST_GITFLOW"
  elif [[ -f "$DST_GITFLOW" ]]; then
    warn "git-flow.config.md already exists — skipping (edit it manually or run /detect-gitflow)"
  elif [[ -f "$SRC_GITFLOW_MD" ]]; then
    cp "$SRC_GITFLOW_MD" "$DST_GITFLOW"
    success "Installed git-flow.config.md → $DST_GITFLOW"
    info "Run /detect-gitflow to auto-fill it, or edit manually to match your team conventions"
  fi

  # jira.config.md template (only if not already present)
  DST_JIRA="$PROJECT_DIR/jira.config.md"
  if $DRY_RUN; then
    info "[dry-run] Would install jira.config.md → $DST_JIRA"
  elif [[ -f "$DST_JIRA" ]]; then
    warn "jira.config.md already exists — skipping (edit it manually or run /detect-jira)"
  elif [[ -f "$SRC_JIRA_MD" ]]; then
    cp "$SRC_JIRA_MD" "$DST_JIRA"
    success "Installed jira.config.md → $DST_JIRA"
    info "Run /detect-jira to configure your Jira project (requires Jira CLI)"
  fi

  # .claude/memory/MEMORY.md — project learning store (only if not already present)
  DST_MEMORY_DIR="$TARGET_CLAUDE/memory"
  DST_MEMORY="$DST_MEMORY_DIR/MEMORY.md"
  if $DRY_RUN; then
    info "[dry-run] Would install .claude/memory/MEMORY.md → $DST_MEMORY"
  elif [[ -f "$DST_MEMORY" ]]; then
    warn ".claude/memory/MEMORY.md already exists — skipping (existing learnings preserved)"
  elif [[ -f "$SRC_MEMORY_MD" ]]; then
    mkdir -p "$DST_MEMORY_DIR"
    cp "$SRC_MEMORY_MD" "$DST_MEMORY"
    success "Installed .claude/memory/MEMORY.md → $DST_MEMORY"
    info "Claude will automatically write learnings here after each session"
    info "Run /learn \"<fact>\" to teach Claude something explicitly"
    info "Run /memory-review to curate accumulated entries"
  fi
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
echo -e "  ${BOLD}Slash commands:${RESET}"
echo "    /sdlc <feature>           Full SDLC: plan→build→review→security→a11y→release"
echo "    /android-review           Review Android/Kotlin code"
echo "    /ios-review               Review Swift/iOS code"
echo "    /mobile-test              Generate test suite"
echo "    /mobile-release           Release preparation checklist"
echo "    /detect-arch              Auto-detect project architecture
    /detect-gitflow           Auto-detect git branching conventions
    /sprint-start [N]         Kick off a new sprint
    /detect-jira              Interactive Jira project setup (requires Jira CLI)
    /standup                  Facilitate today's daily standup
    /retro [format]           Run a sprint retrospective
    /sprint-health            Check sprint burndown and surface risks
    /security-scan            Full OWASP Mobile Top 10 + secrets audit
    /learn \"<fact>\"           Teach Claude something about this project
    /memory-review            Curate accumulated project memory"
echo ""
echo -e "  ${BOLD}Skills (workflows):${RESET}"
echo "    android-feature           mobile-code-review    performance-profile"
echo "    ios-feature               mobile-release        accessibility-audit"
echo "    mobile-test               git-flow              jira-flow"
echo "    scrum"
echo ""
echo -e "  ${BOLD}Agents (specialist reviewers):${RESET}"
echo "    android-reviewer          mobile-architect      mobile-security"
echo "    ios-reviewer              mobile-performance    mobile-test-planner"
echo "    ui-accessibility          release-manager       git-flow-advisor"
echo "    jira-advisor              scrum-master          learning-agent"
echo ""
if $GLOBAL; then
  echo -e "  ${BOLD}Global install:${RESET} agents + commands active in every Claude Code project."
  echo ""
  echo -e "  ${BOLD}Next step:${RESET} In each project, run /detect-arch to create claude-crew.config.md"
  echo -e "  so agents review against YOUR architecture."
else
  echo -e "  ${BOLD}Project install:${RESET} agents + commands active in ${PROJECT_DIR}"
  echo ""
  echo -e "  ${BOLD}Next steps:${RESET}"
  echo -e "    1. Run ${BLUE}/detect-arch${RESET} to auto-detect your project architecture"
  echo -e "       (or edit claude-crew.config.md manually)"
  echo -e "    2. Try: ${BLUE}/sdlc Build a user profile screen for Android${RESET}"
fi
echo ""
echo -e "  Docs: ${BLUE}${REPO_URL}${RESET}"
echo ""
