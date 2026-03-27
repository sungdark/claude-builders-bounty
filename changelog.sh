#!/bin/bash
# changelog.sh - Generate a structured CHANGELOG.md from git history
# Usage: bash changelog.sh [repo_path] [output_file]
# Defaults: current directory, CHANGELOG.md

REPO_PATH="${1:-.}"
OUTPUT_FILE="${2:-CHANGELOG.md}"

cd "$REPO_PATH" || { echo "Error: Cannot access $REPO_PATH"; exit 1; }

# Check if it's a git repo
if [ ! -d .git ]; then
    echo "Error: Not a git repository: $REPO_PATH"
    exit 1
fi

# Get the last git tag (or start from beginning if no tags)
LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null)
if [ -z "$LAST_TAG" ]; then
    echo "No tags found. Using all commits."
    COMMIT_RANGE=""
else
    COMMIT_RANGE="$LAST_TAG..HEAD"
fi

# Category keywords for auto-categorization
declare -A CATEGORIES=(
    ["Added"]="add new feat introduce implement initial"
    ["Fixed"]="fix bug patch repair resolve correct"
    ["Changed"]="change update modify refactor improve"
    ["Removed"]="remove delete drop deprecate"
)

# Initialize changelog sections
declare -A sections=(
    ["Added"]=""
    ["Fixed"]=""
    ["Changed"]=""
    ["Removed"]=""
)

# Parse commits
while IFS= read -r line; do
    # Extract commit hash (7 chars) and message
    hash=$(echo "$line" | cut -d'|' -f1)
    msg=$(echo "$line" | cut -d'|' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | tr '[:upper:]' '[:lower:]')
    
    if [ -z "$msg" ]; then continue; fi
    
    # Categorize
    categorized=false
    for cat in Added Fixed Changed Removed; do
        keywords="${CATEGORIES[$cat]}"
        for kw in $keywords; do
            if echo "$msg" | grep -q "$kw"; then
                if [ -z "${sections[$cat]}" ]; then
                    sections[$cat]="### $cat\n"
                fi
                sections[$cat]+="- $(echo "$line" | cut -d'|' -f2- | sed 's/^[[:space:]]*//')\n"
                categorized=true
                break 2
            fi
        done
    done
    
    # If no category matched, put in Changed
    if [ "$categorized" = false ]; then
        if [ -z "${sections[Changed]}" ]; then
            sections[Changed]="### Changed\n"
        fi
        sections[Changed]+="- $(echo "$line" | cut -d'|' -f2- | sed 's/^[[:space:]]*//')\n"
    fi
done < <(git log $COMMIT_RANGE --pretty=format:"%h|%s" 2>/dev/null)

# Generate CHANGELOG content
{
    echo "# Changelog"
    echo ""
    echo "All notable changes to this project will be documented in this file."
    echo ""
    echo "This changelog follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format."
    echo ""
    if [ -n "$LAST_TAG" ]; then
        echo "## [$LAST_TAG] - $(git log -1 --format=%ci $LAST_TAG 2>/dev/null | cut -d' ' -f1)"
    else
        echo "## [Unreleased]"
    fi
    echo ""
    echo "$(date +%Y-%m-%d)"
    echo ""
    
    for cat in Added Fixed Changed Removed; do
        if [ -n "${sections[$cat]}" ]; then
            echo -e "${sections[$cat]}"
            echo ""
        fi
    done
} > "$OUTPUT_FILE"

echo "CHANGELOG.md generated successfully at $OUTPUT_FILE"
echo ""
echo "Generated on: $(date)"
echo "Commits analyzed: $(git log $COMMIT_RANGE --pretty=format:"%h" 2>/dev/null | wc -l | tr -d ' ')"
echo "Tag used: ${LAST_TAG:-none (all commits)}"
