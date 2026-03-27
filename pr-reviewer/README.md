# 🤖 Claude PR Review Agent

A CLI tool and GitHub Action that provides AI-powered code review for GitHub Pull Requests.

## Features

- **CLI Interface**: Review any PR with a single command
- **GitHub Action**: Automatically review PRs on open/sync
- **Structured Output**: Summary, risks, suggestions, and confidence score
- **No API Key Required**: Uses GitHub's public API (rate-limited)
- **With GitHub Token**: Higher rate limits and full access to private repos

## Installation

### CLI

```bash
# Download the script
curl -O https://raw.githubusercontent.com/claude-builders-bounty/claude-builders-bounty/main/pr-reviewer/claude-review.sh
chmod +x claude-review.sh

# Optional: add to PATH
sudo mv claude-review.sh /usr/local/bin/claude-review
```

### GitHub Action

Copy the workflow file to your repo:

```bash
mkdir -p .github/workflows
curl -O https://raw.githubusercontent.com/claude-builders-bounty/claude-builders-bounty/main/pr-reviewer/.github/workflows/pr-review.yml
```

## Usage

### CLI

```bash
# Basic usage
claude-review --pr https://github.com/owner/repo/pull/123

# With GitHub token (higher rate limits)
GITHUB_TOKEN=ghp_xxx ./claude-review.sh --pr https://github.com/owner/repo/pull/123

# Save to file
claude-review --pr https://github.com/owner/repo/pull/123 --output review.md

# Shorthand format
claude-review --pr owner/repo#123
```

### GitHub Action

The action automatically runs on:
- New pull requests (`opened`, `synchronize`, `reopened`)
- Posts review comment automatically

```yaml
name: Auto PR Review
on: [pull_request]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Review
        run: |
          chmod +x ./claude-review.sh
          ./claude-review.sh --pr ${{ github.event.pull_request.html_url }}
```

## Output Format

The review includes:

### 📋 Summary
- PR title, author, state
- Branch info (base ← head)
- File and line change statistics

### ⚠️ Identified Risks
- Secret/credential exposure detection
- Dangerous operations (rm -rf, DROP TABLE, etc.)
- Missing test coverage
- Large PR warnings

### 💡 Improvement Suggestions
- Documentation needs
- Error handling
- Type safety
- Review checklist

### 📊 Confidence Score
- **Low**: Limited visibility, large changes
- **Medium**: Standard review, good diff visibility
- **High**: Small, well-contained changes

## Examples

### Sample Review

```
# 🤖 Claude PR Review

## 📋 Summary

**Pull Request:** #42 — Add user authentication

| Property | Value |
|----------|-------|
| Author | @developer |
| State | open |
| Base | `main` ← Head | `feat/auth` |
| Files Changed | 12 |
| Lines | +245 / -32 |

---

## ⚠️ Identified Risks

1. 🟡 No test files detected — Consider adding tests
2. 🟢 No obvious secrets in the diff
3. 🟢 No destructive operations

## 💡 Improvement Suggestions

1. Add tests for authentication functions
2. Document the new API endpoints
3. Add error handling for failed login attempts

## 📊 Confidence Score: Medium
```

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `GITHUB_TOKEN` | GitHub personal access token | No (improves rate limit) |

## Rate Limits

- **Without token**: 60 requests/hour (unauthenticated)
- **With token**: 5,000 requests/hour

## Requirements

- bash 4+
- curl
- jq
- GitHub account (for token, optional)

## License

MIT — See [claude-builders-bounty](https://github.com/claude-builders-bounty/claude-builders-bounty)
