# n8n + Claude Code — Weekly Dev Summary Workflow

**Bounty:** $200 | **Author:** claude-builders-bounty

## Overview

This n8n workflow automatically generates a weekly narrative summary of a GitHub repository's activity using the Claude API. Triggered every Friday at 5pm, it fetches commits, closed issues, and merged PRs, then uses Claude to generate a human-readable summary delivered via Discord or Email.

## Features

- ⏰ **Weekly Cron Trigger** — Runs every Friday at 17:00 UTC
- 📊 **Fetches GitHub Activity** — Commits, closed issues, merged PRs for the week
- 🤖 **Claude-Generated Summary** — Uses `claude-sonnet-4-20250514` for narrative summary
- 📬 **Multi-Channel Delivery** — Discord webhook or Email (your choice)
- 🌐 **Multi-Language** — Supports EN and FR

## Setup (5 Steps)

### Step 1: Import the Workflow

1. Open your n8n instance
2. Click **"Import from File"**
3. Select `n8n-weekly-summary.json`
4. Click **Save**

### Step 2: Configure GitHub Credentials

1. Create a GitHub Personal Access Token with `repo:read` scope
2. In n8n, go to **Credentials** → **New** → **GitHub API**
3. Paste your token
4. Name it `github-default`

### Step 3: Configure Claude API Credential

1. Get your API key from [Anthropic Console](https://console.anthropic.com/)
2. In n8n, go to **Credentials** → **New** → **HTTP Header Auth**
3. Add header: `x-api-key` with your Anthropic API key
4. OR use the **HTTP Request Node** with Bearer token

### Step 4: Configure Delivery Channel

**Option A — Discord Webhook:**
1. Create a Discord webhook URL for your channel
2. In the final **Discord Node**, paste your webhook URL

**Option B — Email:**
1. Configure SMTP credentials in n8n (Gmail, SendGrid, etc.)
2. In the final **Email Node**, configure recipient and subject

### Step 5: Update Workflow Variables

Open the workflow and set these **Variable Nodes**:
- `GITHUB_REPO` — e.g., `anthropic/claude-code`
- `WEBHOOK_URL` — your Discord webhook or SMTP settings
- `LANGUAGE` — `EN` or `FR`
- `DAY_OFFSET` — `7` for weekly (or `1` for daily)

## Testing

1. Click **"Test Workflow"** to run manually
2. Check your Discord/Email for the summary
3. Verify the output matches your expectations

## Sample Output

```
📊 Weekly Dev Summary — anthropic/claude-code
📅 Week of Mar 22–28, 2026

🛠️ Commits (15):
• feat: Add pre-tool-use hook support
• fix: Resolve token counting edge case
• docs: Update SKILL.md template

🐛 Closed Issues (3):
• #1234 - Hook not firing on Windows
• #1229 - Memory leak in long sessions

✅ Merged PRs (7):
• #456 - Add Claude Code agent template
• #455 - Fix CLI argument parsing

💡 Claude Summary:
"This week the team focused on hook infrastructure and documentation.
The most notable change is the new pre-tool-use hook system, which
provides better safety guarantees. Outstanding items include the
memory optimization work, expected to land next week."
```

## Architecture

```
[Cron Trigger] 
      ↓
[GitHub API - Commits] ─┐
[GitHub API - Issues]  ─┤
[GitHub API - PRs]     ─┤
      ↓                 │
[Merge Data Node]      │
      ↓                 │
[Claude API Node]      │
      ↓                 │
[Discord/Email Node]   │
```

## Troubleshooting

- **No data returned?** — Verify your PAT has correct permissions
- **Claude errors?** — Check your API key and account balance
- **Discord not working?** — Ensure webhook URL is valid and accessible

## License

MIT — Use freely, modify as needed.
