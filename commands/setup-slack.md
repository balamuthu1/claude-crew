Set up the Slack integration for claude-crew. Guides the user through creating a Slack app, configuring tokens, and writing `slack.config.md`.

Run the following steps directly — do not spawn a sub-agent.

---

## Step 0 — Check prerequisites

```bash
# Check Python (needed for slack-bot.py)
python3 --version 2>/dev/null || echo "NOT_FOUND"

# Check if slack-bolt is installed
python3 -c "import slack_bolt; print('ok')" 2>/dev/null || echo "NOT_INSTALLED"

# Check if SLACK_BOT_TOKEN is already set
[[ -n "${SLACK_BOT_TOKEN:-}" ]] && echo "BOT_TOKEN_SET" || echo "BOT_TOKEN_MISSING"
[[ -n "${SLACK_APP_TOKEN:-}" ]] && echo "APP_TOKEN_SET" || echo "APP_TOKEN_MISSING"
```

If `slack-bolt` is not installed, tell the user:
```
slack-bolt is required for the Slack bot. Install it:
  pip install slack-bolt

Or with a virtual environment:
  python3 -m venv .venv && source .venv/bin/activate && pip install slack-bolt
```

---

## Step 1 — Slack app creation guide

Print:
```
## Slack App Setup

You need a Slack app with socket mode enabled. This takes about 5 minutes.

─── Step A: Create the app ───────────────────────────────────────────
1. Go to: https://api.slack.com/apps
2. Click "Create New App" → "From scratch"
3. App Name: "Claude Crew"   Workspace: your workspace
4. Click "Create App"

─── Step B: Enable Socket Mode ────────────────────────────────────────
1. In the left sidebar → "Socket Mode"
2. Toggle "Enable Socket Mode" ON
3. Click "Generate" under App-Level Token
   Name: "claude-crew-socket"   Scope: connections:write
4. COPY the token (starts with xapp-...) — you'll need it shortly

─── Step C: Bot token scopes ──────────────────────────────────────────
1. In the left sidebar → "OAuth & Permissions"
2. Under "Bot Token Scopes", add ALL of these:
     chat:write          (post messages)
     chat:write.public   (post to public channels without joining)
     channels:read       (list channels)
     channels:history    (read channel history)
     users:read          (look up users by ID)
     users:read.email    (match Slack users to Jira assignees)
     app_mentions:read   (receive @mentions)
3. Click "Install to Workspace" → "Allow"
4. COPY the "Bot User OAuth Token" (starts with xoxb-...)

─── Step D: Subscribe to events ───────────────────────────────────────
1. In the left sidebar → "Event Subscriptions"
2. Toggle "Enable Events" ON
3. Under "Subscribe to bot events", add:
     app_mention         (when someone @mentions the bot)
     message.channels    (messages in channels the bot is in)
4. Click "Save Changes"

─── Step E: Invite the bot to your channels ────────────────────────────
In each Slack channel you want the bot active in, type:
  /invite @Claude Crew

Done with the Slack app? Press Enter to continue with token setup.
```

Wait for the user to press Enter or confirm.

---

## Step 2 — Token setup

```
## Token Configuration

Tokens must NEVER be hardcoded or committed to git.
Add these to your shell profile (~/.zshrc, ~/.bashrc) or your CI secrets:

  export SLACK_BOT_TOKEN=xoxb-...   ← Bot User OAuth Token (from Step C)
  export SLACK_APP_TOKEN=xapp-...   ← App-Level Token (from Step B)

→ Have you added these to your shell profile? [Y/n]
```

If yes, verify:
```bash
[[ -n "${SLACK_BOT_TOKEN:-}" ]] && echo "✓ BOT_TOKEN" || echo "✗ SLACK_BOT_TOKEN not found in environment"
[[ -n "${SLACK_APP_TOKEN:-}" ]] && echo "✓ APP_TOKEN" || echo "✗ SLACK_APP_TOKEN not found in environment"
```

If tokens are missing, remind the user to `source ~/.zshrc` (or equivalent) and re-run `/setup-slack`.

---

## Step 3 — Interactive Q&A

Ask these questions one at a time, showing detected defaults where possible.

### Q1 — Workspace
```
→ What is your Slack workspace name? (e.g. "acme-mobile")
```

### Q2 — Channels

For each channel, show a detected default and ask for confirmation:

```
→ Which channel should agent notifications go to?
   (standup summaries, retro actions, sprint alerts)
   Default: #claude-crew
   (enter channel name or press Enter to accept)

→ Where do daily standups get posted?
   Default: #standup

→ Which channel for at-risk sprint alerts and blockers?
   Default: #dev-alerts

→ Which channel for release announcements?
   Default: #releases

→ Which channel for security scan findings?
   Default: #security

→ Is the bot commands channel the same as notifications? [Y/n]
   (if no: which channel should the bot listen for @mentions?)
```

### Q3 — Notification triggers

```
→ Auto-post standup summary to Slack after /standup? [Y/n]
→ Auto-post sprint alerts when health is "at risk"? [Y/n]
→ Auto-post retro action items after /retro? [Y/n]
→ Auto-post release notes after /mobile-release? [Y/n]
→ Auto-post P0/P1 security findings after /security-scan? [Y/n]
```

### Q4 — Socket mode bot

```
→ Enable the socket mode bot? (receives @mention commands from Slack) [Y/n]

   If enabled, team members can type in Slack:
     @Claude Crew standup
     @Claude Crew sprint-health
     @Claude Crew blockers
     @Claude Crew my-tickets PROJ-123
     @Claude Crew help
```

### Q5 — Message format

```
→ Use rich Slack Block Kit formatting? [Y/n]
   (Y = rich cards with sections and buttons; N = plain text, simpler)
```

---

## Step 4 — Confirm and write

Print a summary:
```
## Summary — slack.config.md

  workspace:             acme-mobile
  bot-name:              Claude Crew
  notifications-channel: #claude-crew
  standup-channel:       #standup
  alerts-channel:        #dev-alerts
  release-channel:       #releases
  security-channel:      #security
  socket-mode:           true
  post-standup:          true
  post-sprint-alerts:    true
  post-retro-actions:    true
  post-release-notes:    false
  post-security-findings: true
  use-block-kit:         true

Write slack.config.md? [Y/n]
```

If `slack.config.md` already exists: ask "Overwrite existing slack.config.md? [y/N]"

---

## Step 5 — Test the connection

After writing, test the bot token:

```bash
curl -s -X POST https://slack.com/api/auth.test \
  -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
  -H "Content-Type: application/json" | python3 -c "
import json,sys
d=json.load(sys.stdin)
if d.get('ok'):
    print(f'✓ Connected as: {d[\"user\"]} in workspace: {d[\"team\"]}')
else:
    print(f'✗ Auth failed: {d.get(\"error\", \"unknown\")}')
"
```

Test posting a message:
```bash
curl -s -X POST https://slack.com/api/chat.postMessage \
  -H "Authorization: Bearer ${SLACK_BOT_TOKEN}" \
  -H "Content-Type: application/json" \
  -d "{\"channel\": \"${NOTIFICATIONS_CHANNEL}\", \"text\": \"👋 Claude Crew is connected and ready!\"}"
```

---

## Step 6 — Start the socket mode bot (optional)

If socket mode is enabled:
```
## Starting the Socket Mode Bot

Run this in a terminal to start listening for Slack commands:

  python3 .claude/hooks/slack-bot.py

Or run it in the background:
  nohup python3 .claude/hooks/slack-bot.py > .claude/logs/slack-bot.log 2>&1 &

The bot will respond to @Claude Crew mentions in your channels.

To stop: kill the background process or Ctrl+C in the foreground terminal.
```

---

## Step 7 — Report

```
## Slack Integration Ready

slack.config.md written to project root.

Commit it (tokens are NOT in this file — they stay in env vars):
  git add slack.config.md && git commit -m "chore: add slack.config.md"

What agents can now do:
  ✓ Post standup summaries to #standup automatically
  ✓ Alert #dev-alerts when sprint is at risk
  ✓ Post retro action items to #claude-crew
  ✓ Notify #security of P0/P1 scan findings
  ✓ Respond to @Claude Crew commands in Slack (if bot running)

Bot commands (type in any invited channel):
  @Claude Crew standup       → sprint board + standup prompt
  @Claude Crew sprint-health → live health report
  @Claude Crew blockers      → BLOCKER tickets from Jira
  @Claude Crew my-tickets    → your assigned tickets
  @Claude Crew help          → full command list
```
