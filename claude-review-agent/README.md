# Claude PR Review Agent

**Bounty:** $150 — powered by [Opire](https://opire.dev)

An AI-powered PR review agent that analyzes GitHub pull request diffs and posts structured Markdown review comments.

## Features

- 🔍 **Automated Code Review** — Analyzes PR diffs for risks and improvement opportunities
- 📊 **Structured Output** — Summary, Risks, Suggestions, Confidence Score
- ⚡ **Fast** — Runs in seconds, no LLM API required for basic analysis
- 🔒 **Security-Focused** — Detects potential SQL injection, exposed secrets, unsafe patterns
- 📝 **GitHub Action** — Fully automated reviews on every PR
- 💬 **Interactive** — Comment `/review <pr-number>` on any PR to trigger a review

## Installation

### CLI

```bash
npm install -g claude-review-agent
```

Or use directly with `npx`:

```bash
npx claude-review-agent --pr https://github.com/owner/repo/pull/123
```

### GitHub Action

Add to your repository at `.github/workflows/pr-review.yml`:

```yaml
name: Claude PR Review
on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
      - run: npm install -g claude-review-agent
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - run: |
          claude-review --pr ${{ github.repository }}/${{ github.event.pull_request.number }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      - run: |
          gh pr comment ${{ github.event.pull_request.number }} \
            --body "$(cat review.md)" \
            --repo ${{ github.repository }}
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

## Usage

### CLI

```bash
# Review a PR by full URL
claude-review --pr https://github.com/owner/repo/pull/123

# Review a PR by short form
claude-review --pr owner/repo/123

# Output to file instead of stdout
claude-review --pr owner/repo/123 --output review.md

# Verbose mode
claude-review --pr owner/repo/123 --verbose
```

### GitHub Comment

On any PR, leave a comment:

```
/review 123
```

The bot will analyze PR #123 and post a structured review comment.

## Output Format

The review output includes:

### Summary
- PR title, description, author
- Branch comparison
- Commit count, files changed, lines added/removed

### Identified Risks
- SQL injection patterns
- Secret/config file exposure
- Large changes that should be split
- Security-sensitive TODOs

### Improvement Suggestions
- `console.log` statements to remove
- TODO/FIXME comments
- Code quality concerns

### Confidence Score
- 🟢 **High** — No obvious issues detected
- 🟡 **Medium** — Some concerns that should be reviewed
- 🔴 **Low** — Security or critical issues detected

### Files Changed
A table of all changed files with line addition/deletion counts.

## Sample Output

```markdown
# 🔍 PR Review: #123 — Add user authentication

> **Reviewed:** 2026-03-29
> **Author:** @developer
> **Branch:** `feature/auth` → `main`
> **Commits:** 3 | **Files changed:** 5 | **+142 -23**

---

## 📝 Summary
Adds JWT-based authentication to the API.

---

## 🚨 Identified Risks
- No critical risks identified. ✅

---

## 💡 Improvement Suggestions
- `src/auth/login.ts`: Contains `console.log` statements that should be removed.
- `src/utils/format.ts`: Contains TODO/FIXME comments that should be addressed.

---

## 🎯 Confidence Score
🟢 High — No obvious issues detected
```

## Requirements

- Node.js 18+
- `gh` CLI authenticated (for GitHub API access)
- GitHub token (automatic when using GitHub Actions)
