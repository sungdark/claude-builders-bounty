# SKILL: PR Review Agent

A Claude Code sub-agent that takes a PR URL or diff, analyzes it, and returns a structured Markdown review comment.

## Activation

```
/review-pr <pr-url>
```
or
```
bash pr-review.sh --pr https://github.com/owner/repo/pull/123
```

## How It Works

1. Fetches the PR diff and metadata from GitHub API
2. Analyzes code changes for risks, quality issues, and improvements
3. Returns a structured Markdown review

## Output Format

```markdown
## PR Review: <PR Title>

### Summary
<2-3 sentence description of what this PR does>

### Risks
- <list of identified risks>

### Improvement Suggestions
- <list of suggested improvements>

### Confidence Score
**Low | Medium | High**

### Files Changed
- <list of key files>
```

## Usage

### CLI
```bash
# Review a PR by URL
bash pr-review.sh --pr https://github.com/owner/repo/pull/123

# Review a local diff file
bash pr-review.sh --diff /path/to/diff.patch

# Save output to file
bash pr-review.sh --pr https://github.com/owner/repo/pull/123 --output review.md
```

### GitHub Action
See `.github/workflows/pr-review.yml` — paste it into your repo's `.github/workflows/`.

### Claude Code
```
/review-pr https://github.com/owner/repo/pull/123
```

## Implementation

The skill consists of:
- `pr-review.sh` — CLI tool using GitHub CLI (`gh`) or raw curl
- `.github/workflows/pr-review.yml` — GitHub Action that auto-reviews PRs
- `README.md` — setup instructions
