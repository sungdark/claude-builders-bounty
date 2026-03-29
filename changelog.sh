#!/usr/bin/env bash
set -euo pipefail

# changelog.sh — Generate a structured CHANGELOG.md from git history
# Usage: ./changelog.sh [--since-tag <tag>] [--output <file>]

OUTPUT="CHANGELOG.md"
SINCE_TAG=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --since-tag)
      SINCE_TAG="$2"
      shift 2
      ;;
    --output)
      OUTPUT="$2"
      shift 2
      ;;
    --help)
      echo "Usage: $0 [--since-tag <tag>] [--output <file>]"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Find the tag to start from
if [[ -z "$SINCE_TAG" ]]; then
  SINCE_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
fi

# Determine git log range
if [[ -n "$SINCE_TAG" ]]; then
  RANGE="${SINCE_TAG}..HEAD"
else
  RANGE="--all"
fi

# Temporary file for raw commits
TEMP=$(mktemp)

# Get commits with their messages
if [[ -n "$SINCE_TAG" ]]; then
  git log "$RANGE" --pretty=format:"%s" > "$TEMP" 2>/dev/null || true
else
  git log --pretty=format:"%s" | head -100 > "$TEMP" || true
fi

# Categorize commits
declare -A categories
categories[Added]=""
categories[Fixed]=""
categories[Changed]=""
categories[Removed]=""

while IFS= read -r msg || [[ -n "$msg" ]]; do
  # Skip merge commits and empty lines
  [[ -z "$msg" || "$msg" == "merge:"* || "$msg" == "Merge"* ]] && continue

  # Lowercase for matching (but preserve original for output)
  lower_msg=$(echo "$msg" | tr '[:upper:]' '[:lower:]')

  # Categorize by prefix (anchor at start of string)
  if echo "$lower_msg" | grep -qE "^(feat|feature|new|add|introduce)\b"; then
    categories[Added]="${categories[Added]}- ${msg}\n"
  elif echo "$lower_msg" | grep -qE "^(fix|bug|patch|hotfix|resolve|resolve)\b"; then
    categories[Fixed]="${categories[Fixed]}- ${msg}\n"
  elif echo "$lower_msg" | grep -qE "^(remove|delete|deprecate|drop)\b"; then
    categories[Removed]="${categories[Removed]}- ${msg}\n"
  else
    categories[Changed]="${categories[Changed]}- ${msg}\n"
  fi
done < "$TEMP"

# Build the changelog
{
  echo "# Changelog"
  echo ""
  if [[ -n "$SINCE_TAG" ]]; then
    echo "## [${SINCE_TAG}] → [Unreleased]"
  else
    echo "## [Unreleased]"
  fi
  echo ""

  if [[ -n "${categories[Added]}" ]]; then
    echo "### Added"
    echo -e "${categories[Added]}"
  fi
  if [[ -n "${categories[Fixed]}" ]]; then
    echo "### Fixed"
    echo -e "${categories[Fixed]}"
  fi
  if [[ -n "${categories[Changed]}" ]]; then
    echo "### Changed"
    echo -e "${categories[Changed]}"
  fi
  if [[ -n "${categories[Removed]}" ]]; then
    echo "### Removed"
    echo -e "${categories[Removed]}"
  fi
} > "$OUTPUT"

rm -f "$TEMP"
echo "✅ CHANGELOG.md generated → ${OUTPUT}"
