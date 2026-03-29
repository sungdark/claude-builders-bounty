#!/bin/bash
# Claude Code PR Reviewer Agent
# Usage: ./claude-review.sh --pr https://github.com/owner/repo/pull/123

set -e

ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-$ANTHROPIC_KEY}"
MODEL="${ANTHROPIC_MODEL:-claude-opus-4-5-20250514}"
OUTPUT_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --pr)
            PR_URL="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$PR_URL" ]; then
    echo "Usage: $0 --pr https://github.com/owner/repo/pull/123 [--output review.md] [--model claude-opus-4-5-20250514]"
    exit 1
fi

# Parse owner/repo/pr_number from URL
if [[ "$PR_URL" =~ github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
    OWNER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
    PR_NUM="${BASH_REMATCH[3]}"
else
    echo "Error: Invalid PR URL format"
    exit 1
fi

echo "🔍 Fetching PR #$PR_NUM from $OWNER/$REPO..."

# Fetch PR info
PR_INFO=$(gh pr view "$PR_NUM" --repo "$OWNER/$REPO" --json title,author,body,state,additions,deletions,changedFiles --jq '.')

PR_TITLE=$(echo "$PR_INFO" | jq -r '.title')
PR_AUTHOR=$(echo "$PR_INFO" | jq -r '.author.login')
PR_STATE=$(echo "$PR_INFO" | jq -r '.state')
PR_ADDITIONS=$(echo "$PR_INFO" | jq -r '.additions')
PR_DELETIONS=$(echo "$PR_INFO" | jq -r '.deletions')
PR_CHANGED_FILES=$(echo "$PR_INFO" | jq -r '.changedFiles')

# Fetch PR diff
echo "📥 Downloading diff..."
PR_DIFF=$(gh pr diff "$PR_NUM" --repo "$OWNER/$REPO")

# Truncate diff if too large (first 100KB)
if [ ${#PR_DIFF} -gt 102400 ]; then
    PR_DIFF=$(echo "$PR_DIFF" | head -c 102400)
    PR_DIFF="$PR_DIFF

[... Diff truncated, showing first 100KB ...]"
fi

# Build prompt for Claude
PROMPT="You are an expert code reviewer. Analyze the following GitHub Pull Request and provide a structured review.

## PR Details
- **Title:** $PR_TITLE
- **Author:** @$PR_AUTHOR
- **State:** $PR_STATE
- **Files Changed:** $PR_CHANGED_FILES files
- **Lines:** +$PR_ADDITIONS / -$PR_DELETIONS

## Diff (first 100KB)
\`\`\`diff
$PR_DIFF
\`\`\`

## Your Task
Provide a detailed Markdown review with these exact sections:

### 📝 Summary
2-3 sentences describing what this PR does.

### ⚠️ Risks
A table of potential risks with Severity (High/Medium/Low) and Description columns.

### 💡 Suggestions
Numbered list of improvement recommendations.

### 🎯 Confidence Score
LOW, MEDIUM, or HIGH — rate how confident you are this PR is ready to merge.

Format your entire response as clean Markdown. Do not include any preamble like 'Here is your review' — just the Markdown directly."

echo "🤖 Sending to Claude API (model: $MODEL)..."

# Call Claude API
RESPONSE=$(curl -s -X POST "https://api.anthropic.com/v1/messages" \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "{
        \"model\": \"$MODEL\",
        \"max_tokens\": 2048,
        \"system\": \"You are an expert code reviewer. Be thorough but constructive. Focus on security, correctness, performance, and maintainability.\",
        \"messages\": [{\"role\": \"user\", \"content\": $(echo "$PROMPT" | jq -Rs .)}]
    }")

# Extract text from response
REVIEW=$(echo "$RESPONSE" | jq -r '.content[0].text // empty')

if [ -z "$REVIEW" ]; then
    echo "❌ Error: Failed to get response from Claude API"
    echo "Response: $RESPONSE"
    exit 1
fi

# Format the review with header
FORMATTED_REVIEW="## 🤖 AI PR Review Summary

**Repo:** $OWNER/$REPO  
**PR:** #$PR_NUM — $PR_TITLE  
**Author:** @$PR_AUTHOR  
**Files Changed:** $PR_CHANGED_FILES files, +$PR_ADDITIONS lines, -$PR_DELETIONS lines

---

$REVIEW

---

*🤖 Reviewed by Claude Code PR Reviewer Agent — [Source](https://github.com/claude-builders-bounty/claude-builders-bounty)*"

# Output
if [ -n "$OUTPUT_FILE" ]; then
    echo "$FORMATTED_REVIEW" > "$OUTPUT_FILE"
    echo "✅ Review saved to $OUTPUT_FILE"
else
    echo "$FORMATTED_REVIEW"
fi

# Optionally post as GitHub comment
if [ -n "$POST_COMMENT" ]; then
    echo "$FORMATTED_REVIEW" | gh pr comment "$PR_NUM" --repo "$OWNER/$REPO" --body-file -
    echo "✅ Posted review as GitHub comment"
fi

echo "✅ Review complete!"
