#!/bin/bash
# changelog.sh — Generate a structured CHANGELOG.md from git history
# Usage: bash changelog.sh [--from <tag|commit>] [--output <file>]

set -e

FROM_REF=""
OUTPUT_FILE="CHANGELOG.md"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --from)
      FROM_REF="$2"
      shift 2
      ;;
    --output)
      OUTPUT_FILE="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: bash changelog.sh [--from <tag|commit>] [--output <file>]"
      exit 1
      ;;
  esac
done

# Detect last tag if --from not specified
LAST_TAG=""
RANGE=""
if [ -z "$FROM_REF" ]; then
  LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
  if [ -n "$LAST_TAG" ]; then
    echo "Detected last tag: $LAST_TAG"
    FROM_REF="$LAST_TAG"
    RANGE="${LAST_TAG}..HEAD"
  else
    echo "No tags found, using all commits"
    RANGE="--all"
  fi
else
  RANGE="${FROM_REF}..HEAD"
fi

# Arrays for categorized commits
added=""
fixed=""
changed=""
removed=""
other=""

# Fetch commits
if [ -z "$LAST_TAG" ]; then
  COMMITS=$(git log --pretty=format:"%h|%s|%an" --no-merges 2>/dev/null)
else
  COMMITS=$(git log "$RANGE" --pretty=format:"%h|%s|%an" --no-merges 2>/dev/null)
fi

while IFS= read -r line; do
  [ -z "$line" ] && continue
  
  sha=$(echo "$line" | cut -d'|' -f1)
  subject=$(echo "$line" | cut -d'|' -f2)
  author=$(echo "$line" | cut -d'|' -f3)
  
  # Categorize by conventional commit prefix
  lower_subject=$(echo "$subject" | tr '[:upper:]' '[:lower:]')
  
  entry="- ${subject} ([\`${sha}\`](#), @${author})"
  
  if echo "$lower_subject" | grep -qE "^(feat|feature|add|new)[:\s]"; then
    added="${added}${entry}\n"
  elif echo "$lower_subject" | grep -qE "^(fix|bugfix|hotfix|patch)[:\s]"; then
    fixed="${fixed}${entry}\n"
  elif echo "$lower_subject" | grep -qE "^(remove|delete|deprecate|drop)[:\s]"; then
    removed="${removed}${entry}\n"
  elif echo "$lower_subject" | grep -qE "^(chore|refactor|style|docs|test|build|ci|perf|revert|breaking)[:\s]"; then
    changed="${changed}${entry}\n"
  else
    other="${other}${entry}\n"
  fi
done <<< "$COMMITS"

# Build CHANGELOG
TODAY=$(date +"%Y-%m-%d")

# Helper to build a section
build_section() {
  local title="$1"
  local content="$2"
  if [ -n "$content" ]; then
    echo "### ${title}"
    echo -e "$content"
  fi
}

{
  echo "# Changelog"
  echo ""
  echo "All notable changes to this project will be documented in this file."
  echo ""
  echo "This changelog follows the [Conventional Commits](https://www.conventionalcommits.org/) specification."
  echo ""
  echo "## [Unreleased] - ${TODAY}"
  echo ""
  build_section "Added" "$added"
  build_section "Fixed" "$fixed"
  build_section "Changed" "$changed"
  build_section "Removed" "$removed"
  build_section "Other" "$other"
} > "$OUTPUT_FILE"

echo "✅ CHANGELOG.md generated: $OUTPUT_FILE"

# Show preview
echo ""
echo "=== Preview ==="
head -30 "$OUTPUT_FILE"
