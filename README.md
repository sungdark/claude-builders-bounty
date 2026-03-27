# Claude Review — PR Review Agent

A Claude Code sub-agent that takes a PR diff as input, analyzes it with Claude AI, and returns a structured Markdown review comment.

## Features

- **CLI Tool**: `claude-review --pr <url>`
- **GitHub Action**: Automatic PR review on every PR
- **Structured Output**: Summary, Risks, Suggestions, Confidence Score
- **Multi-format**: Markdown, JSON, console output

## Installation

```bash
npm install -g claude-review
```

Or use without installation:

```bash
npx claude-review --pr https://github.com/owner/repo/pull/123
```

## Usage

### CLI

```bash
# Basic usage
claude-review --pr https://github.com/owner/repo/pull/123

# With output file
claude-review --pr https://github.com/owner/repo/pull/123 --output review.md

# With explicit tokens
claude-review --pr https://github.com/owner/repo/pull/123 \
  --gh-token ghp_xxx \
  --anthropic-key sk-ant-xxx
```

### Environment Variables

```bash
export GITHUB_TOKEN=ghp_xxx
export ANTHROPIC_API_KEY=sk-ant-xxx
```

### GitHub Action

Add to your workflow file (`.github/workflows/claude-review.yml`):

```yaml
name: Claude PR Review
on: [pull_request]
jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
      - run: npm install @anthropic-ai/sdk @octokit/rest commander dotenv typescript @types/node
      - run: npx ts-node cli.ts --pr "${{ github.event.pull_request.html_url }}"
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
```

## Output Format

```markdown
## 🤖 Claude Code Review

### 📋 Summary
This PR [description of changes]

### ⚠️ Identified Risks
- Risk 1
- Risk 2

### 💡 Improvement Suggestions
- Suggestion 1
- Suggestion 2

### ✅ Confidence: High
[Explanation]
```

## Development

```bash
npm install
npm run build
npm start -- --pr https://github.com/owner/repo/pull/123
```
