#!/bin/bash
# Generate CHANGELOG.md from git history
# Usage: bash changelog.sh [since_tag]

set -e

REPO_PATH="${1:-.}"
cd "$REPO_PATH"

# Get last tag or initial commit
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
if [[ -n "$LAST_TAG" ]]; then
    RANGE="$LAST_TAG..HEAD"
    TAG_NAME="$LAST_TAG"
else
    RANGE="--all"
    TAG_NAME="Unreleased"
fi

# Fetch commits
COMMITS=$(git log $RANGE --pretty=format:"%s%n%b---DELIM---" 2>/dev/null)

# Categorize
declare -A CATEGORIES=(
    ["Added"]=""
    ["Fixed"]=""
    ["Changed"]=""
    ["Removed"]=""
    ["Other"]=""
)

while IFS= read -r line; do
    if [[ -z "$line" || "$line" == "---DELIM---" ]]; then
        continue
    fi
    
    LOWER=$(echo "$line" | tr '[:upper:]' '[:lower:]')
    
    if   [[ "$LOWER" =~ ^feat(\([^)]*\))?:\  ]]; then
        CATEGORIES["Added"]+="- $line\n"
    elif [[ "$LOWER" =~ ^fix(\([^)]*\))?:\  ]]; then
        CATEGORIES["Fixed"]+="- $line\n"
    elif [[ "$LOWER" =~ ^perf(\([^)]*\))?:\  ]] || [[ "$LOWER" =~ ^refactor(\([^)]*\))?:\  ]] || [[ "$LOWER" =~ ^chore(\([^)]*\))?:\  ]] || [[ "$LOWER" =~ ^docs(\([^)]*\))?:\  ]] || [[ "$LOWER" =~ ^test(\([^)]*\))?:\  ]]; then
        CATEGORIES["Changed"]+="- $line\n"
    elif [[ "$LOWER" =~ breaking ]]; then
        CATEGORIES["Removed"]+="- $line (BREAKING)\n"
    else
        CATEGORIES["Other"]+="- $line\n"
    fi
done <<< "$COMMITS"

# Generate CHANGELOG
DATE=$(date '+%Y-%m-%d')
OUTPUT="# Changelog\n\n## [$TAG_NAME] - $DATE\n"

for cat in "Added" "Fixed" "Changed" "Removed" "Other"; do
    content="${CATEGORIES[$cat]}"
    if [[ -n "$content" ]]; then
        OUTPUT+="\n### $cat\n"
        OUTPUT+="$content"
    fi
done

# Write file
echo -e "$OUTPUT" > CHANGELOG.md
echo "✅ CHANGELOG.md generated successfully!"
cat CHANGELOG.md
