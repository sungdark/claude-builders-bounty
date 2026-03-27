# Claude Code PR Reviewer — Bounty #4

A Claude Code agent (CLI + GitHub Action) that takes a PR diff as input, analyzes it with Claude Sonnet 4, and returns a structured Markdown review.

## Features

- **CLI**: `claude-review --pr <URL>` — works standalone
- **GitHub Action**: Automated reviews on PR open/sync
- **Structured output**: Summary / Risks / Suggestions / Confidence Score
- **Comment trigger**: Also responds to `/review` comments

## Setup (5 Steps)

### 1. CLI Installation

```bash
pip install requests  # or: pip install -r requirements.txt
chmod +x solutions/issue-4/claude-review.py
sudo mv solutions/issue-4/claude-review.py /usr/local/bin/claude-review
```

### 2. Set Environment Variables

```bash
export GITHUB_TOKEN=ghp_xxx     # GitHub personal access token
export ANTHROPIC_API_KEY=sk-ant-xxx  # Anthropic API key
```

### 3. Run a Review

```bash
claude-review --pr https://github.com/owner/repo/pull/123
```

### 4. GitHub Action Setup (optional)

Copy `.github/workflows/review.yml` to your repo and add to `.github/workflows/review.yml`.
Add `ANTHROPIC_API_KEY` to your repo's Secrets.

### 5. Automate on PR

The GitHub Action runs automatically on:
- PR opened
- New commits pushed to PR
- `/review` comment posted

## Output Format

````markdown
## Summary
[2-3 sentence summary of what this PR does]

## Identified Risks
- [risk 1]
- [risk 2]

## Improvement Suggestions
- [suggestion 1]
- [suggestion 2]

## Confidence Score
Low | Medium | High
````

## Tested On

| PR | Result |
|----|--------|
| cli/cli#13046 | High confidence — targeted bug fix |
| cli/cli#13048 | High confidence — drop-in dep replacement |

See `sample-reviews/` for full outputs.
