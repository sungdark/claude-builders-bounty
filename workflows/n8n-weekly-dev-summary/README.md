# n8n + Claude API — Weekly GitHub Dev Summary

**Issue:** [claude-builders-bounty#5](https://github.com/claude-builders-bounty/claude-builders-bounty/issues/5) | **Bounty: $200** | Powered by [Opire](https://opire.dev)

An n8n workflow that runs every Friday at 5pm, fetches GitHub activity for the past week (commits, closed issues, merged PRs), generates a narrative summary via Claude Sonnet, and delivers it to Discord.

## Setup in 5 Steps

### 1. Import the workflow

In n8n, click **Workflows → Import from File** and select `workflows/n8n-weekly-dev-summary/n8n-weekly-dev-summary.json`.

### 2. Configure variables

In n8n **Settings → Variables**, add these workflow variables:

| Variable | Value |
|----------|-------|
| `GITHUB_REPO` | `https://api.github.com/repos/YOUR_ORG/YOUR_REPO` |
| `ANTHROPIC_API_KEY` | Your Anthropic API key |
| `DISCORD_WEBHOOK_URL` | Your Discord channel webhook URL |
| `LANGUAGE` | `EN` or `FR` |
| `LAST_SUMMARIES_BRANCH` | `main` (or your release branch) |
| `LAST_WEEK_UNIX` | Unix timestamp of week start (auto-calculated in nodes) |

### 3. Add your GitHub token (optional, for private repos)

Add a GitHub Personal Access Token as a workflow credential named `github_auth`, then update the HTTP Request nodes to use it in the `Authorization: Bearer TOKEN` header.

### 4. Test manually

Click **Test Workflow** to verify it works. Check your Discord channel for the summary embed.

### 5. Activate

Toggle the workflow to **Active**. It will now run automatically every Friday at 5pm.

## Workflow Structure

```
[Schedule: Friday 5pm]
         │
         ▼
[GitHub API: Repo Info]  ← verifies repo exists
    │
    ├──────────────────┬──────────────────┐
    ▼                  ▼                  ▼
[Commits]         [Closed Issues]    [Merged PRs]
    │                  │                  │
    └──────────────────┼──────────────────┘
                       ▼
            [Format Prompt for Claude]
                       │
                       ▼
            [Claude Sonnet 4 API]
            Generate 3-4 paragraph narrative
                       │
                       ▼
            [Format Discord Embed]
                       │
                       ▼
            [Discord Webhook → Channel]
```

## Features

- **Trigger:** Weekly cron (Friday 5pm), configurable
- **GitHub API:** Fetches past week's commits, closed issues, merged PRs
- **Claude Sonnet 4:** Generates professional narrative summary
- **Discord delivery:** Rich embed with color, footer stats, timestamp
- **Configurable:** Repo, language (EN/FR), output channel all via variables
- **Slack alternative:** Replace the Discord webhook node with a Slack incoming webhook URL

## Discord Output Example

```
📋 Weekly Dev Summary — my-repo
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
This week was productive for my-repo with 12 commits merged
across 5 contributors. The team closed 3 issues including
a long-standing authentication bug (#42) and shipped the
new dashboard feature that had been in review since last
sprint. The most significant change was the refactoring of
the database layer...

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Week: 2026-03-21 → 2026-03-28 | 12 commits | 3 issues | 5 PRs merged
```

## Variables Reference

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `GITHUB_REPO` | Yes | — | GitHub API URL for your repo |
| `ANTHROPIC_API_KEY` | Yes | — | Anthropic API key (claude-sonnet-4-20250514) |
| `DISCORD_WEBHOOK_URL` | Yes | — | Discord webhook URL |
| `LANGUAGE` | No | `EN` | Summary language (EN/FR) |
| `LAST_SUMMARIES_BRANCH` | No | `main` | Branch to compare against |
| `LAST_WEEK_UNIX` | No | auto | Unix timestamp for issue filtering |

## Requirements

- n8n instance (self-hosted or cloud.n8n.io)
- Anthropic API account with API key
- Discord channel with webhook enabled

## Troubleshooting

**No summary posted to Discord:**
- Verify DISCORD_WEBHOOK_URL is correct
- Check n8n execution log for errors
- Test with "Test Workflow" button

**Claude API errors:**
- Verify ANTHROPIC_API_KEY is valid
- Check API key has sufficient quota
- Ensure model `claude-sonnet-4-20250514` is available

**GitHub API rate limiting:**
- Add a GitHub Personal Access Token to avoid rate limits
- For public repos, 60 requests/hour is usually sufficient

## Payment

BTC: `eB51DWp1uECrLZRLsE2cnyZUzfRWvzUzaJzkatTpQV9`
