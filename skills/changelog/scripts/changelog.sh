#!/bin/bash
# changelog.sh — Generate a structured CHANGELOG.md from git history
# Part of: https://github.com/sungdark/claude-builders-bounty (Bounty #1)

set -euo pipefail

CHANGELOG_FILE="CHANGELOG.md"

# Detect last git tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")

if [ -n "$LAST_TAG" ]; then
  echo "📦 Last tag: $LAST_TAG"
  COMMITS=$(git log "$LAST_TAG"..HEAD --oneline --format="%s|%h|%an" 2>/dev/null || echo "")
else
  echo "📦 No tags found, using all commits (last 500)"
  COMMITS=$(git log --oneline --format="%s|%h|%an" -n 500 2>/dev/null || echo "")
fi

# Categorize commits
declare -A categories
categories[Added]=""
categories[Fixed]=""
categories[Changed]=""
categories[Removed]=""

while IFS='|' read -r msg hash author; do
  [ -z "$msg" ] && continue

  entry="- ${msg} ([\`${hash}\`](#-${hash}))\n"

  case "$msg" in
    feat*|"+ "*|add*|"New "*)
      categories[Added]+="$entry"
      ;;
    fix*|bug*|"patch "*|"Hotfix "*|"bugfix "*)
      categories[Fixed]+="$entry"
      ;;
    refactor*|chore*|docs*|style*|perf*|test*|build*|ci*|config*)
      categories[Changed]+="$entry"
      ;;
    remove*|delete*|deprecate*)
      categories[Removed]+="$entry"
      ;;
    *)
      categories[Changed]+="$entry"
      ;;
  esac
done <<< "$COMMITS"

# Defaults for empty categories
for key in Added Fixed Changed Removed; do
  if [ -z "${categories[$key]}" ]; then
    categories[$key]="_(none)_\n"
  fi
done

TODAY=$(date +%Y-%m-%d)
VERSION=${1:-$(date +%Y.%m.%d)}

CHANGELOG_CONTENT="# Changelog

## [${VERSION}] - ${TODAY}

### Added
${categories[Added]}

### Fixed
${categories[Fixed]}

### Changed
${categories[Changed]}

### Removed
${categories[Removed]}
"

# Prepend to existing CHANGELOG (skip header line if it exists)
if [ -f "$CHANGELOG_FILE" ]; then
  # Skip the first line (# Changelog) and append
  REST=$(tail -n +2 "$CHANGELOG_FILE")
  CHANGELOG_CONTENT+="
$REST"
fi

echo -e "$CHANGELOG_CONTENT" > "$CHANGELOG_FILE"

ADDED_COUNT=$(echo -e "${categories[Added]}" | grep -c "^-" || true)
FIXED_COUNT=$(echo -e "${categories[Fixed]}" | grep -c "^-" || true)
CHANGED_COUNT=$(echo -e "${categories[Changed]}" | grep -c "^-" || true)
REMOVED_COUNT=$(echo -e "${categories[Removed]}" | grep -c "^-" || true)

echo "✅ CHANGELOG.md updated: +${ADDED_COUNT} added, ~${CHANGED_COUNT} changed, ✓${FIXED_COUNT} fixed, -${REMOVED_COUNT} removed"
