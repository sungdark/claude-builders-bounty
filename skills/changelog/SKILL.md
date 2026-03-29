# SKILL.md — Generate CHANGELOG from Git History

## Triggers
- User says "generate changelog", "/generate-changelog", or "update CHANGELOG"
- User asks to document recent changes

## What This Does
Reads git commit history since the last tag, categorizes commits by type (Added/Fixed/Changed/Removed), and writes or updates CHANGELOG.md.

## How to Run
```bash
# Option 1: Run the skill directly
./scripts/changelog.sh

# Option 2: Via Claude Code
/generate-changelog
```

## Script: scripts/changelog.sh
```bash
#!/bin/bash
set -euo pipefail

# Detect last tag
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
CHANGELOG_FILE="CHANGELOG.md"

# Get commits since last tag (or all if no tag)
if [ -n "$LAST_TAG" ]; then
  COMMITS=$(git log "$LAST_TAG"..HEAD --oneline --format="%s|%h|%an" 2>/dev/null || echo "")
  DATE_FROM=$(git log -1 --format=%ci "$LAST_TAG" 2>/dev/null | cut -d' ' -f1 || echo "")
else
  COMMITS=$(git log --oneline --format="%s|%h|%an" -n 500 2>/dev/null || echo "")
  DATE_FROM="All commits"
fi

# Categorize commits
declare -A categories
categories[Added]=""
categories[Fixed]=""
categories[Changed]=""
categories[Removed]=""

while IFS='|' read -r msg hash author; do
  [ -z "$msg" ] && continue

  # Categorize by prefix
  case "$msg" in
    feat*|"+ "*|add*|"New "*)
      categories[Added]+="- ${msg} ([\`${hash}\`](#-${hash}))\n"
      ;;
    fix*|bug*|"patch "*|"Hotfix "*|"bugfix "*)
      categories[Fixed]+="- ${msg} ([\`${hash}\`](#-${hash}))\n"
      ;;
    refactor*|chore*|docs*|style*|perf*|test*|build*|ci*)
      categories[Changed]+="- ${msg} ([\`${hash}\`](#-${hash}))\n"
      ;;
    remove*|delete*|deprecate*)
      categories[Removed]+="- ${msg} ([\`${hash}\`](#-${hash}))\n"
      ;;
    *)
      categories[Changed]+="- ${msg} ([\`${hash}\`](#-${hash}))\n"
      ;;
  esac
done <<< "$COMMITS"

# Build output
TODAY=$(date +%Y-%m-%d)
VERSION=${1:-$(date +%Y.%m.%d)}

CHANGELOG_CONTENT="# Changelog

## [${VERSION}] - ${TODAY}

### Added
${categories[Added]:-_(none)_}

### Fixed
${categories[Fixed]:-_(none)_}

### Changed
${categories[Changed]:-_(none)_}

### Removed
${categories[Removed]:-_(none)_}
"

# Append to existing CHANGELOG or create new
if [ -f "$CHANGELOG_FILE" ]; then
  # Insert after the header line (## [Unreleased] or first heading)
  CHANGELOG_CONTENT+="
$(cat "$CHANGELOG_FILE")"
fi

echo -e "$CHANGELOG_CONTENT" > "$CHANGELOG_FILE"
echo "✅ CHANGELOG.md generated/updated with $(echo -e "$CHANGELOG_CONTENT" | wc -l) lines"
```

## Setup (3 Steps)
1. Copy `scripts/changelog.sh` to your project root
2. Run `chmod +x scripts/changelog.sh`
3. Run `./scripts/changelog.sh` or import the SKILL.md into Claude Code

## Sample Output
```
# Changelog

## [2026.03.29] - 2026-03-29

### Added
- Add user authentication ([\`a1b2c3d\`](#-a1b2c3d))
- Implement rate limiting middleware ([\`b2c3d4e\`](#-b2c3d4e))

### Fixed
- Fix memory leak in connection pool ([\`c3d4e5f\`](#-c3d4e5f))
- Resolve race condition in cache invalidation ([\`d4e5f6g\`](#-d4e5f6g))

### Changed
- Refactor database layer for better type safety ([\`e5f6g7h\`](#-e5f6g7h))
- Update dependencies to latest versions ([\`f6g7h8i\`](#-f6g7h8i))
```
