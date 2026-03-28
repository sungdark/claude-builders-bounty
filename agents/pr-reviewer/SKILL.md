# SKILL: PR Reviewer Agent

Review GitHub pull requests using Claude Code.

## Trigger

Use this skill when asked to review a PR or when a new PR is opened.

## How to Use

### From CLI
```bash
export ANTHROPIC_API_KEY=your-key
export GITHUB_TOKEN=your-github-token  # optional for private repos
bash agents/pr-reviewer/review-pr.sh --pr https://github.com/owner/repo/pull/123
```

### From Claude Code
Simply share the PR URL and say: "Review this PR"

Claude will use this skill to:
1. Fetch PR metadata and diff
2. Analyze code changes
3. Generate a structured review comment
4. Optionally post it to the PR

## Output Format

```
## PR Review: [Title]

**Repository:** owner/repo | **PR:** #123 | **Author:** @username
**Base:** main → **Head:** feature-branch

---

### Summary
[2-3 sentence overview]

### Files Changed
[Key files and their purpose]

### Risk Assessment
- **[HIGH]** Security: [specific risk]
- **[MEDIUM]** Performance: [concern]
- **[LOW]** [observation]

### Suggestions
1. [Actionable recommendation]
2. [Second suggestion]

### Confidence Score
**[High/Medium/Low]** — [reason]
```

## What It Checks

- **Security:** Injection risks, auth bypasses, exposed secrets, unsafe SQL
- **Correctness:** Logic errors, edge cases, missing null checks, off-by-ones
- **Performance:** N+1 queries, missing indexes, large data in memory
- **Maintainability:** Code duplication, missing tests, unclear naming
- **Best practices:** Error handling, type safety, resource cleanup

## Requirements

- `ANTHROPIC_API_KEY` environment variable
- `GITHUB_TOKEN` (for private repos)
- `curl`, `python3`, `jq` available in PATH

## Installation

```bash
# Download the script
curl -fsSL https://raw.githubusercontent.com/sungdark/claude-builders-bounty/sungdark-issue4-pr-reviewer/agents/pr-reviewer/review-pr.sh \
  -o review-pr.sh && chmod +x review-pr.sh

# Add to PATH (optional)
mv review-pr.sh /usr/local/bin/pr-review

# Set environment
export ANTHROPIC_API_KEY=sk-ant-...
```

For GitHub Action, copy `.github/workflows/pr-reviewer.yml` to your repo and add `ANTHROPIC_API_KEY` as a secret.
