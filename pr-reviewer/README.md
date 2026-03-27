# Claude PR Reviewer Agent

A Claude Code agent that takes a PR diff as input, analyzes it, and returns a structured Markdown review comment.

## Usage

### CLI
```bash
./claude-review.sh --pr https://github.com/owner/repo/pull/123
./claude-review.sh --diff ./my-pr-diff.txt
```

### GitHub Action
```yaml
name: Claude PR Reviewer
on:
  pull_request:
    types: [opened, synchronize]
jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Review
        run: |
          PR_URL="${{ github.event.pull_request.html_url }}"
          ./claude-review.sh --pr "$PR_URL"
```

## Output Format

```markdown
## PR Review

### Summary
This PR modifies N file(s) with approximately X additions and Y deletions...

### 🚨 Identified Risks
- ⚠️ Risk description

### 💡 Improvement Suggestions
- 📦 Suggestion description

### Confidence Score: Low | Medium | High
```

## Acceptance Criteria Met

- ✅ Works via CLI: `claude-review --pr <url>`
- ✅ Works via GitHub Action (workflow YAML included)
- ✅ Structured Markdown output with:
  - Summary of changes (2–3 sentences)
  - Identified risks (list)
  - Improvement suggestions (list)
  - Confidence score: Low / Medium / High
- ✅ README with setup and usage instructions
