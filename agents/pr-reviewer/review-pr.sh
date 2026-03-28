#!/usr/bin/env bash
#===============================================================================
# Claude PR Review Agent
# Reviews a GitHub PR and posts a structured comment.
#
# Usage:
#   bash review-pr.sh --pr https://github.com/owner/repo/pull/123
#   bash review-pr.sh --pr owner/repo/123
#
# Environment:
#   ANTHROPIC_API_KEY  — Anthropic API key (required)
#   GITHUB_TOKEN       — GitHub token (optional, for private repos)
#===============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; RESET='\033[0m'

usage() {
  echo "Usage: $0 --pr <PR_URL_or_owner/repo/NUMBER> [--post]"
  echo "  --pr <url>    PR URL (https://github.com/owner/repo/pull/123) or owner/repo/123"
  echo "  --post        Post the review as a GitHub PR comment"
  echo ""
  echo "Required env: ANTHROPIC_API_KEY"
  echo "Optional env: GITHUB_TOKEN (for private repos)"
  exit 1
}

# Parse args
PR_URL=""
POST=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --pr) PR_URL="$2"; shift 2 ;;
    --post) POST=true; shift ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

if [[ -z "${PR_URL}" ]]; then usage; fi
if [[ -z "${ANTHROPIC_API_KEY}" ]]; then
  echo "Error: ANTHROPIC_API_KEY environment variable is required"
  exit 1
fi

# Normalize PR URL
if [[ "${PR_URL}" =~ ^([a-zA-Z0-9_-]+)/([a-zA-Z0-9_-]+)/([0-9]+)$ ]]; then
  OWNER="${BASH_REMATCH[1]}"; REPO="${BASH_REMATCH[2]}"; PR_NUM="${BASH_REMATCH[3]}"
  PR_URL="https://github.com/${OWNER}/${REPO}/pull/${PR_NUM}"
elif [[ "${PR_URL}" =~ ^https://github.com/([a-zA-Z0-9_-]+)/([a-zA-Z0-9_-]+)/pull/([0-9]+) ]]; then
  OWNER="${BASH_REMATCH[1]}"; REPO="${BASH_REMATCH[2]}"; PR_NUM="${BASH_REMATCH[3]}"
else
  echo "Error: Invalid PR URL format. Use https://github.com/owner/repo/pull/123 or owner/repo/123"
  exit 1
fi

echo -e "${CYAN}🔍 Fetching PR #${PR_NUM} from ${OWNER}/${REPO}...${RESET}"

# Fetch PR info
API_BASE="https://api.github.com/repos/${OWNER}/${REPO}"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN:-}"

PR_JSON=$(curl -sf -H "${AUTH_HEADER}" \
  -H "Accept: application/vnd.github.v3+json" \
  "${API_BASE}/pulls/${PR_NUM}")

if [[ -z "${PR_JSON}" ]]; then
  echo "Error: Failed to fetch PR info. Check the URL and your token."
  exit 1
fi

PR_TITLE=$(echo "${PR_JSON}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['title'])")
PR_STATE=$(echo "${PR_JSON}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['state'])")
PR_AUTHOR=$(echo "${PR_JSON}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['user']['login'])")
PR_BASE=$(echo "${PR_JSON}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['base']['ref'])")
PR_HEAD=$(echo "${PR_JSON}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['head']['ref'])")
PR_BODY=$(echo "${PR_JSON}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['body'] or '')" | head -c 500)
PR_DRAFT=$(echo "${PR_JSON}" | python3 -c "import sys,json; d=json.load(sys.stdin); print('yes' if d.get('draft') else 'no')")

echo -e "${GREEN}✓ PR: ${PR_TITLE}${RESET}"
echo "  Author: @${PR_AUTHOR} | Base: ${PR_BASE} ← Head: ${PR_HEAD}"
[[ "${PR_DRAFT}" == "yes" ]] && echo "  ⚠️  Draft PR"

# Fetch diff
echo -e "${CYAN}📥 Fetching diff...${RESET}"
DIFF=$(curl -sf -H "${AUTH_HEADER}" \
  -H "Accept: application/vnd.github.v3.diff" \
  "${API_BASE}/pulls/${PR_NUM}/files" 2>/dev/null || echo "")

if [[ -z "${DIFF}" ]]; then
  echo -e "${YELLOW}⚠️  Could not fetch diff (may be empty or private). Proceeding with PR metadata.${RESET}"
fi

# Truncate diff if too large (Claude API token limits)
DIFF_LEN=${#DIFF}
if [[ ${DIFF_LEN} -gt 50000 ]]; then
  echo -e "${YELLOW}⚠️  Diff truncated (${DIFF_LEN} chars → 50000)${RESET}"
  DIFF="${DIFF:0:50000}"
fi

# Build prompt for Claude
PROMPT="You are a senior code reviewer. Review the following GitHub Pull Request and provide a structured critique.

## PR Information
- **Title:** ${PR_TITLE}
- **Repository:** ${OWNER}/${REPO}
- **PR Number:** #${PR_NUM}
- **Author:** @${PR_AUTHOR}
- **Base branch:** ${PR_BASE}
- **Head branch:** ${PR_HEAD}
- **State:** ${PR_STATE}
- **Draft:** ${PR_DRAFT}
- **Description:** ${PR_BODY}

## Diff / Changed Files
\`\`\`diff
${DIFF}
\`\`\`

## Review Requirements

Provide your review in this EXACT Markdown format:

\`\`\`markdown
## PR Review: ${PR_TITLE}

**Repository:** ${OWNER}/${REPO} | **PR:** #${PR_NUM} | **Author:** @${PR_AUTHOR}
**Base:** ${PR_BASE} → **Head:** ${PR_HEAD}

---

### Summary
[2-3 sentence overview of what this PR does and whether it achieves its goal]

### Files Changed
[Quick list of the key files changed and what they do]

### Risk Assessment
- **[HIGH]** [Category]: [Specific risk and why it matters]
- **[MEDIUM]** [Category]: [Specific concern]
- **[LOW]** [Category]: [Minor observation]
(Or: *No significant risks identified.*)

### Suggestions
1. [Actionable recommendation with specific code example if applicable]
2. [Second suggestion]
3. [Third suggestion]
(Or: *No suggestions — PR looks good.*)

### Comment Quality
**[Good/Needs Work]** — [Brief assessment of PR description clarity and commit message quality]

### Confidence Score
**[High/Medium/Low]** — [Reason for your confidence level]
\`\`\`

Be critical but constructive. Focus on real bugs, security issues, and maintainability problems. Do not nitpick style choices that are purely subjective."
echo -e "${CYAN}🤖 Sending to Claude for review...${RESET}"

# Call Claude API
RESPONSE=$(curl -sf -X POST \
  -H "x-api-key: ${ANTHROPIC_API_KEY}" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "{
    \"model\": \"claude-sonnet-4-20250514\",
    \"max_tokens\": 1500,
    \"messages\": [{\"role\": \"user\", \"content\": $(echo "${PROMPT}" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))")}]
  }" 2>&1)

if [[ -z "${RESPONSE}" ]] || ! echo "${RESPONSE}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('content',[{}])[0].get('text',''))" > /dev/null 2>&1; then
  echo -e "${RED}✗ Claude API error. Response: ${RESPONSE:0:200}${RESET}"
  exit 1
fi

REVIEW=$(echo "${RESPONSE}" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d['content'][0]['text'])")

echo -e "${GREEN}✅ Review complete!${RESET}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "${REVIEW}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Post as PR comment if --post flag
if [[ "${POST}" == "true" ]]; then
  echo -e "${CYAN}💬 Posting review as PR comment...${RESET}"
  COMMENT_RESPONSE=$(curl -sf -X POST \
    -H "${AUTH_HEADER}" \
    -H "Accept: application/vnd.github.v3+json" \
    -H "content-type: application/vnd.github.v3+json" \
    "${API_BASE}/issues/${PR_NUM}/comments" \
    -d "{\"body\": \"## 🤖 Claude Code PR Review\n\n${REVIEW}\n\n---\n*Review generated by Claude Code. [Configure your own reviewer agent](https://github.com/claude-builders-bounty/claude-builders-bounty).*\"}")

  if [[ -n "${COMMENT_RESPONSE}" ]]; then
    echo -e "${GREEN}✓ Review posted as comment!${RESET}"
  else
    echo -e "${RED}✗ Failed to post comment.${RESET}"
  fi
fi
