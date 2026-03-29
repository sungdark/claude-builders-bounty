#!/bin/bash
# pr-review.sh — Analyze a PR and generate a structured review comment
# Usage: bash pr-review.sh --pr <url> [--output <file>]

set -e

PR_URL=""
DIFF_FILE=""
OUTPUT_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --pr)
      PR_URL="$2"
      shift 2
      ;;
    --diff)
      DIFF_FILE="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [ -z "$PR_URL" ] && [ -z "$DIFF_FILE" ]; then
  echo "Error: --pr or --diff required"
  echo "Usage: bash pr-review.sh --pr <url> [--output <file>]"
  echo "       bash pr-review.sh --diff <file> [--output <file>]"
  exit 1
fi

# Extract repo and PR number from URL
extract_pr_info() {
  local url="$1"
  # Handle both github.com and GH enterprise
  if [[ "$url" =~ github\.com/([^/]+)/([^/]+)/pull/([0-9]+) ]]; then
    echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}|${BASH_REMATCH[3]}"
  else
    echo ""
  fi
}

# Fetch PR metadata
fetch_pr_info() {
  local pr_info="$1"  # format: owner/repo|pr_number
  local owner_repo=$(echo "$pr_info" | cut -d'|' -f1)
  local pr_num=$(echo "$pr_info" | cut -d'|' -f2)
  
  gh api "repos/${owner_repo}/pulls/${pr_num}" --jq '{title, body, state, user, additions, deletions, changed_files, head}' 2>/dev/null
}

# Fetch PR diff
fetch_pr_diff() {
  local pr_info="$1"
  local owner_repo=$(echo "$pr_info" | cut -d'|' -f1)
  local pr_num=$(echo "$pr_info" | cut -d'|' -f2)
  
  gh api "repos/${owner_repo}/pulls/${pr_num}" --jq '.diff // empty' 2>/dev/null
}

# Analyze diff content (basic heuristics)
analyze_diff() {
  local diff="$1"
  local output=""
  
  # Count lines changed
  additions=$(echo "$diff" | grep -c '^+' || echo 0)
  deletions=$(echo "$diff" | grep -c '^-' || echo 0)
  
  # Detect potential issues
  risks=""
  suggestions=""
  
  # Check for TODO/FIXME in diff (shouldn't be introduced)
  new_todos=$(echo "$diff" | grep '^+' | grep -cE '(TODO|FIXME|HACK|XXX):' || echo 0)
  if [ "$new_todos" -gt 0 ]; then
    risks="${risks}\n- Contains $new_todos new TODO/FIXME comment(s) — consider resolving before merge"
  fi
  
  # Check for large files added
  large_adds=$(echo "$diff" | grep '^+' | awk '{if(length > 500) count++} END {print count+0}')
  
  # Check for potential security issues
  if echo "$diff" | grep -qE 'password|secret|api_key|token' | grep -v '^Binary'; then
    risks="${risks}\n- Potential secret/token in diff — ensure no credentials are exposed"
  fi
  
  # Check for missing tests (if source files changed but no test files)
  source_files=$(echo "$diff" | grep '^+' | grep -E '\.(ts|js|tsx|jsx)$' | grep -v node_modules | grep -v '\.test\.' | grep -v '\.spec\.' | wc -l)
  test_files=$(echo "$diff" | grep '^+' | grep -E '\.(test|spec)\.(ts|js|tsx|jsx)$' | wc -l)
  if [ "$source_files" -gt 0 ] && [ "$test_files" -eq 0 ]; then
    suggestions="${suggestions}\n- No test files changed — consider adding tests for new functionality"
  fi
  
  # Check for SQL injection risks
  if echo "$diff" | grep -qE 'execute|query|raw\s*\(|\.query\(' | grep -v parameterized; then
    suggestions="${suggestions}\n- Database query detected — ensure parameterized queries are used (no SQL injection risks)"
  fi
  
  # Check for missing error handling
  if echo "$diff" | grep -qE 'fetch\(|axios\.|http\.' | grep -v try; then
    suggestions="${suggestions}\n- HTTP calls detected without obvious error handling wrapper"
  fi
  
  echo -e "ADDITIONS:${additions}\nDELETIONS:${deletions}\nRISKS:${risks}\nSUGGESTIONS:${suggestions}"
}

# Generate review markdown
generate_review() {
  local pr_info="$1"
  local diff="$2"
  local analysis="$3"
  
  local owner_repo=$(echo "$pr_info" | cut -d'|' -f1)
  local pr_num=$(echo "$pr_info" | cut -d'|' -f2)
  
  local pr_data=$(fetch_pr_info "$pr_info")
  local title=$(echo "$pr_data" | jq -r '.title')
  local body=$(echo "$pr_data" | jq -r '.body // empty')
  local user=$(echo "$pr_data" | jq -r '.user.login')
  local additions=$(echo "$pr_data" | jq -r '.additions')
  local deletions=$(echo "$pr_data" | jq -r '.deletions')
  local changed_files=$(echo "$pr_data" | jq -r '.changed_files')
  local head_branch=$(echo "$pr_data" | jq -r '.head.ref')
  
  local diff_lines=$(echo "$diff" | wc -l)
  
  # Determine confidence based on diff size
  local confidence="High"
  if [ "$diff_lines" -gt 2000 ]; then
    confidence="Low"
  elif [ "$diff_lines" -gt 500 ]; then
    confidence="Medium"
  fi
  
  # Extract risks and suggestions from analysis
  local risks=$(echo "$analysis" | grep "^RISKS:" | sed 's/^RISKS://')
  local suggestions=$(echo "$analysis" | grep "^SUGGESTIONS:" | sed 's/^SUGGESTIONS://')
  
  if [ -z "$risks" ]; then
    risks="\n- No major risks identified"
  fi
  if [ -z "$suggestions" ]; then
    suggestions="\n- PR looks reasonable overall"
  fi
  
  cat << REVIEW
## PR Review: $title

**PR [#${pr_num}](https://github.com/${owner_repo}/pull/${pr_num})** by @${user}  
Branch: \`${head_branch}\` | +${additions} -${deletions} | ${changed_files} files

---

### Summary
$(echo "$body" | head -3 | sed 's/^/> /')

This PR modifies **${changed_files} files** with **+${additions} additions / -${deletions} deletions**.

---

### Risks
$(echo "$risks" | sed '/^$/d')

---

### Improvement Suggestions
$(echo "$suggestions" | sed '/^$/d')

---

### Confidence Score
**${confidence}**

*Note: This is an automated review. A thorough human review is still recommended.*

---

*Reviewed by PR Review Agent — [Source](https://github.com/claude-builders-bounty/claude-builders-bounty)*
REVIEW
}

# Main execution
if [ -n "$PR_URL" ]; then
  pr_info=$(extract_pr_info "$PR_URL")
  if [ -z "$pr_info" ]; then
    echo "Error: Could not parse PR URL: $PR_URL"
    exit 1
  fi
  
  echo "Fetching PR from $PR_URL..."
  diff=$(fetch_pr_diff "$pr_info")
  if [ -z "$diff" ]; then
    echo "Error: Could not fetch PR diff"
    exit 1
  fi
  
  analysis=$(analyze_diff "$diff")
  review=$(generate_review "$pr_info" "$diff" "$analysis")
else
  # Use local diff file
  echo "Reading diff from $DIFF_FILE..."
  diff=$(cat "$DIFF_FILE")
  analysis=$(analyze_diff "$diff")
  
  cat << REVIEW
## PR Review: Local Diff Review

**Source:** ${DIFF_FILE}
**Lines changed:** $(echo "$diff" | wc -l)

---

### Summary
Automated review of local diff file.

---

### Risks
$(echo "$analysis" | grep "^RISKS:" | sed 's/^RISKS://')

---

### Improvement Suggestions
$(echo "$analysis" | grep "^SUGGESTIONS:" | sed 's/^SUGGESTIONS://')

---

### Confidence Score
**Medium**

*Note: This is a local diff review. For full context, provide the PR URL.*

---

*Reviewed by PR Review Agent*
REVIEW
  exit 0
fi

# Output
if [ -n "$OUTPUT_FILE" ]; then
  echo "$review" > "$OUTPUT_FILE"
  echo "✅ Review saved to: $OUTPUT_FILE"
else
  echo "$review"
fi
