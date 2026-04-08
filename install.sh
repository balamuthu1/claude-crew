#!/usr/bin/env bash
# ============================================================
#  Claude Crew — Mobile Agent Harness Installer
#  https://github.com/balamuthu1/claude-crew
#
#  Usage:
#    Global install (available in ALL projects):
#      ./install.sh --global
#      curl -sSL https://raw.githubusercontent.com/balamuthu1/claude-crew/main/install.sh | bash -s -- --global
#
#    Project install (current directory):
#      ./install.sh
#      ./install.sh --project /path/to/your/mobile-app
#
#    Dry run (see what would be installed):
#      ./install.sh --dry-run
#      ./install.sh --global --dry-run
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
REPO_RAW="https://raw.githubusercontent.com/balamuthu1/claude-crew/main"

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
  SRC_AGENTS="$SCRIPT_DIR/.claude/agents"
  SRC_COMMANDS="$SCRIPT_DIR/.claude/commands"
  SRC_HOOKS="$SCRIPT_DIR/.claude/hooks"
  SRC_RULES="$SCRIPT_DIR/rules"
  SRC_SKILLS="$SCRIPT_DIR/skills"
  SRC_CLAUDE_MD="$SCRIPT_DIR/CLAUDE.md"
  SRC_SETTINGS="$SCRIPT_DIR/.claude/settings.json"
  SRC_CONFIG_MD="$SCRIPT_DIR/claude-crew.config.md"
  success "Using local source: $SCRIPT_DIR"
else
  # Remote install — download to temp dir
  TMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$TMP_DIR"' EXIT
  info "Downloading claude-crew from GitHub..."
  if command -v git &>/dev/null; then
    git clone --depth 1 --quiet "$REPO_URL.git" "$TMP_DIR/claude-crew" 2>/dev/null
    SRC_BASE="$TMP_DIR/claude-crew"
  else
    error "git is required for remote install. Install git and retry."
    exit 1
  fi
  SRC_AGENTS="$SRC_BASE/.claude/agents"
  SRC_COMMANDS="$SRC_BASE/.claude/commands"
  SRC_HOOKS="$SRC_BASE/.claude/hooks"
  SRC_RULES="$SRC_BASE/rules"
  SRC_SKILLS="$SRC_BASE/skills"
  SRC_CLAUDE_MD="$SRC_BASE/CLAUDE.md"
  SRC_SETTINGS="$SRC_BASE/.claude/settings.json"
  SRC_CONFIG_MD="$SRC_BASE/claude-crew.config.md"
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
copy_dir "$SRC_AGENTS" "$TARGET_CLAUDE/agents" "specialist agents (8)"

# Commands → .claude/commands/
copy_dir "$SRC_COMMANDS" "$TARGET_CLAUDE/commands" "slash commands"

# Hooks → .claude/hooks/
copy_dir "$SRC_HOOKS" "$TARGET_CLAUDE/hooks" "lifecycle hooks"

# Make hooks executable
if ! $DRY_RUN && [[ -d "$TARGET_CLAUDE/hooks" ]]; then
  chmod +x "$TARGET_CLAUDE/hooks"/*.sh 2>/dev/null || true
  success "Hooks marked executable"
fi

# settings.json — merge carefully
merge_settings "$SRC_SETTINGS" "$TARGET_CLAUDE/settings.json"

# CLAUDE.md — project install only (global CLAUDE.md goes to ~/.claude/CLAUDE.md)
if $GLOBAL; then
  install_claude_md "$SRC_CLAUDE_MD" "$HOME/.claude/CLAUDE.md"
else
  install_claude_md "$SRC_CLAUDE_MD" "$PROJECT_DIR/CLAUDE.md"

  # Also install rules/ and skills/ into project for agent reference
  copy_dir "$SRC_RULES"  "$PROJECT_DIR/rules"  "coding rules (Kotlin, Swift, Arch)"
  copy_dir "$SRC_SKILLS" "$PROJECT_DIR/skills" "workflow skills"

  # Install claude-crew.config.md template (only if not already present)
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
echo -e "  ${BOLD}Available slash commands:${RESET}"
echo "    /sdlc <feature>       Full SDLC: plan→build→test→review→security→a11y→release"
echo "    /android-review       Review Android/Kotlin code"
echo "    /ios-review           Review Swift/iOS code"
echo "    /mobile-test          Generate test suite"
echo "    /mobile-release       Release preparation checklist"
echo ""
echo -e "  ${BOLD}Available agents (via Agent tool or @mention):${RESET}"
echo "    android-reviewer      mobile-architect      mobile-security"
echo "    ios-reviewer          mobile-performance    mobile-test-planner"
echo "    ui-accessibility      release-manager"
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
