# Claude Code PR Reviewer Agent

A Claude Code agent that reviews GitHub Pull Requests and posts structured Markdown review comments.

## Quick Start

```bash
chmod +x scripts/claude-review
export ANTHROPIC_API_KEY="sk-ant-..."
./scripts/claude-review --pr https://github.com/owner/repo/pull/123
```

## CLI Options

| Flag | Description |
|------|-------------|
| `--pr <URL>` | GitHub PR URL (required) |
| `--model <name>` | Claude model (default: claude-sonnet-4-20250514) |
| `--output <file>` | Save output to file |
| `--help` | Show help |

## GitHub Action

See [`.github/workflows/pr-review.yml`](.github/workflows/pr-review.yml) for the GitHub Action setup.

## Sample Output

See [SKILL.md](SKILL.md) for full sample output format.

## Requirements

- `gh` CLI authenticated (`gh auth login`)
- `ANTHROPIC_API_KEY` environment variable set
