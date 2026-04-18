#!/usr/bin/env bash
# ============================================================
# Claude Crew — UserPromptSubmit Hook  (v1)
#
# Fires every time the user submits a prompt.
# Analyzes the prompt for vagueness signals and injects a
# [PROMPT_UNCLEAR] block into context when gaps are detected.
# Claude sees the block and asks targeted questions before
# starting any implementation or spawning any agent.
#
# Output to stdout is injected into Claude's context.
# Exit 0 always — blocking is not the goal, questioning is.
# ============================================================

set -uo pipefail

INPUT=$(cat)

PROMPT=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    print(d.get('prompt', d.get('message', d.get('content', ''))))
except:
    print('')
" 2>/dev/null || echo "")

[[ -z "$PROMPT" ]] && exit 0

# ── Skip non-task inputs ──────────────────────────────────────────────────────
# Questions, status checks, and workflow management commands need no clarification.
SKIP_COMMANDS="(profile|memory-review|learn|evolve|standup|retro|sprint-health|sprint-start|report|teach-mode|commit-push-pr|detect-arch|detect-gitflow|detect-jira|detect-workflow|android-review|ios-review|security-scan|mobile-release|mobile-test)"
if echo "$PROMPT" | grep -qE "^/$SKIP_COMMANDS(\s|$)"; then
  exit 0
fi

# Also skip pure questions and very short lookups
if echo "$PROMPT" | grep -qiE "^\s*(what|where|when|how|why|who|which|can you|could you|does|is |are |show me|list|explain|tell me|describe)\b"; then
  exit 0
fi

# ── Signal detection ──────────────────────────────────────────────────────────
python3 - "$PROMPT" <<'PYEOF'
import sys, re

prompt = sys.argv[1]
words  = prompt.split()
wc     = len(words)
p      = prompt.lower()

flags = []
gaps  = []

# ── 1. Short action with no subject ──────────────────────────────────────────
# "Build login", "Fix the bug", "Add feature" — action verb but missing what/where/why
ACTION_VERBS = r"^(build|create|add|fix|implement|write|make|update|refactor|design|review|test|debug|deploy|integrate|migrate|optimize|improve|change|modify|remove|delete|move|rename|convert|generate|set up|setup|configure)"
if wc <= 10 and re.match(ACTION_VERBS, p):
    flags.append("short-task")
    gaps.append("what specifically / in which component / acceptance criteria")

# ── 2. Slash command that needs a description ─────────────────────────────────
# /sdlc, /android-feature, /ios-feature submitted with no or minimal description
NEEDS_ARGS = r"^/(sdlc|android-feature|ios-feature|mobile-feature|api-feature|frontend-feature)\s*$"
if re.match(NEEDS_ARGS, prompt.strip()):
    flags.append("command-no-description")
    gaps.append("what feature to build (name, user story, or acceptance criteria)")

# ── 3. Vague scope language ───────────────────────────────────────────────────
VAGUE_WORDS = r"\b(something|somehow|a bit|kinda|sorta|some stuff|make it better|clean it up|improve (it|things)|fix (it|things)|update (it|things)|the (thing|stuff)|look into it|handle it|deal with it|sort (it|this) out)\b"
if re.search(VAGUE_WORDS, p):
    flags.append("vague-scope")
    gaps.append("concrete goal — what does 'done' look like?")

# ── 4. Ambiguous pronoun without referent ─────────────────────────────────────
# Short prompt where "it/this/that" is the subject with no clear prior context
AMBIGUOUS_REF = r"\b(fix it|update it|change it|move it|delete it|refactor it|it should|it needs|it must|this should|that should|this needs|that needs)\b"
if wc <= 15 and re.search(AMBIGUOUS_REF, p):
    flags.append("missing-referent")
    gaps.append("which specific file, component, or feature 'it/this/that' refers to")

# ── 5. Feature request without acceptance criteria ───────────────────────────
# Mentions a feature/screen/flow but has no should/must/when/so-that
FEATURE_WORDS  = r"\b(feature|screen|page|flow|module|widget|component|form|dialog|view|controller|service|api endpoint)\b"
CRITERIA_WORDS = r"\b(should|must|when|so that|given|accept|criteria|requirement|expect|behaviour|behavior|in order to|as a user|allow|prevent|validate|ensure)\b"
if wc <= 25 and re.search(FEATURE_WORDS, p) and not re.search(CRITERIA_WORDS, p):
    if "feature-no-criteria" not in [f for f in flags]:  # don't double-flag
        flags.append("feature-no-criteria")
        gaps.append("acceptance criteria — what must it do, what should it NOT do?")

# ── Emit signal only when gaps found ─────────────────────────────────────────
if not flags:
    sys.exit(0)

print("")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("[PROMPT_UNCLEAR]")
print(f"Signals:  {', '.join(flags)}")
print(f"Gaps:     {' | '.join(gaps)}")
print("")
print("STOP — do not start implementation or spawn any agent yet.")
print("Ask the user 2–3 short, numbered questions — one per gap.")
print("Wait for answers before proceeding.")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
print("")
PYEOF

exit 0
