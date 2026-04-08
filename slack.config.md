# Claude Crew — Slack Integration Configuration
#
# Run /setup-slack to configure this interactively.
# Requires a Slack app with socket mode enabled.
#
# Setup guide:
#   1. Go to https://api.slack.com/apps → Create New App → From scratch
#   2. Under "Socket Mode": enable it, generate an App-Level Token (scope: connections:write)
#      → copy to SLACK_APP_TOKEN env var (starts with xapp-)
#   3. Under "OAuth & Permissions" → Bot Token Scopes, add:
#        chat:write, channels:read, channels:history, users:read, app_mentions:read
#   4. Install app to workspace → copy Bot User OAuth Token
#      → copy to SLACK_BOT_TOKEN env var (starts with xoxb-)
#   5. Under "Event Subscriptions" → Subscribe to bot events: app_mention, message.channels
#   6. Invite the bot to each channel: /invite @claude-crew
#
# Environment variables required (never hardcode these):
#   export SLACK_BOT_TOKEN=xoxb-...
#   export SLACK_APP_TOKEN=xapp-...
#
# Add to your shell profile or CI secrets — never commit these values.

---

## Connection

# Slack workspace name (for display purposes only)
workspace: your-org

# Bot display name in Slack
bot-name: Claude Crew

# Bot emoji (used as icon in messages)
bot-emoji: ":robot_face:"

# Socket mode enabled (true = bot can receive messages; false = send-only)
socket-mode: true

---

## Channel Mapping

# Channel for agent notifications (standup summaries, sprint health, retro actions)
notifications-channel: "#claude-crew"

# Channel where daily standups are posted
standup-channel: "#standup"

# Channel for sprint health alerts and at-risk warnings
alerts-channel: "#dev-alerts"

# Channel for release announcements
release-channel: "#releases"

# Channel for security scan findings
security-channel: "#security"

# Channel where the bot listens for @mentions and slash commands
# (the bot must be invited to this channel)
commands-channel: "#claude-crew"

---

## Notification Triggers

# Post standup summary to standup-channel after /standup completes
post-standup: true

# Post sprint health report to alerts-channel when status is "at risk"
post-sprint-alerts: true

# Post retro action items to notifications-channel after /retro completes
post-retro-actions: true

# Post release summary to release-channel after /mobile-release completes
post-release-notes: true

# Post P0/P1 security findings to security-channel after /security-scan
post-security-findings: true

# Post blocker alerts to alerts-channel when a blocker is raised in standup
post-blockers: true

---

## Bot Commands (socket mode only)

# When someone @mentions the bot in Slack, it handles these commands:
# @claude-crew standup          → posts standup prompt or last summary
# @claude-crew sprint-health    → posts live sprint health report
# @claude-crew blockers         → lists current BLOCKER tickets from Jira
# @claude-crew my-tickets       → lists the mentioner's assigned tickets
# @claude-crew help             → shows command list

# Enable/disable bot command handling
bot-commands-enabled: true

# Require bot to be @mentioned (true) or respond to all messages in commands-channel (false)
require-mention: true

---

## Message Format

# Use Slack Block Kit formatting (rich messages with sections, buttons, etc.)
# false = plain text (simpler, more compatible)
use-block-kit: true

# Include Jira ticket links in messages
linkify-tickets: true

# Jira base URL for ticket links (copied from jira.config.md if present)
# jira-url: https://yourorg.atlassian.net

---

## Notes

# Any team-specific Slack conventions or channel naming notes.
# notes:
