# SKILL: PR Review Agent

A Claude Code sub-agent that analyzes a GitHub PR and returns a structured Markdown review.

## Setup (3 Steps)

### Option A: CLI Tool
```bash
# 1. Copy the skill
cp -r skills/pr-review-agent/ /path/to/your/project/

# 2. Make executable
chmod +x skills/pr-review-agent/pr-review.sh

# 3. Run on a PR
bash pr-review.sh --pr https://github.com/owner/repo/pull/123
```

### Option B: GitHub Action (auto-review all PRs)
```bash
# Copy the workflow
mkdir -p .github/workflows
cp skills/pr-review-agent/.github/workflows/pr-review.yml .github/workflows/
```

## Usage

```bash
# Review a PR by URL
bash pr-review.sh --pr https://github.com/owner/repo/pull/123

# Review a local diff file
bash pr-review.sh --diff /path/to/diff.patch

# Save output to file
bash pr-review.sh --pr https://github.com/owner/repo/pull/123 --output review.md
```

## Output Format

```markdown
## PR Review: <Title>

### Summary
<2-3 sentence description>

### Risks
- <list of risks>

### Improvement Suggestions
- <list of suggestions>

### Confidence Score
**Low | Medium | High**
```

## What It Checks

- **TODOs/FIXMEs** added in the diff
- **Credentials/secrets** potentially exposed
- **Missing tests** when source files change
- **SQL injection** risks in database queries
- **Missing error handling** for HTTP calls
- **Large additions** that may need extra scrutiny

## Requirements

- `gh` CLI authenticated (`gh auth login`)
- `jq` for JSON parsing
- `bash` 4+
