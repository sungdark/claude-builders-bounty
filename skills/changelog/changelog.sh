#!/bin/bash
# Generate CHANGELOG.md from git history
# Usage: ./changelog.sh [--since YYYY-MM-DD] [--version VERSION] [--output FILE] [--repo URL]

set -euo pipefail

VERSION=""
OUTPUT_FILE="CHANGELOG.md"
SINCE_TAG=""
INCLUDE_UNRELEASED=0
REPO_URL=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --since)
            SINCE_TAG="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --include-unreleased)
            INCLUDE_UNRELEASED=1
            shift
            ;;
        --repo)
            REPO_URL="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if in git repo (unless --repo specified)
if [[ -z "$REPO_URL" ]] && [[ ! -d .git ]]; then
    echo "Error: Not in a git repository. Use --repo to specify a remote repo."
    exit 1
fi

# Find last tag
LAST_TAG=""
if [[ -z "$SINCE_TAG" ]]; then
    LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
fi

# Build git log range
RANGE="$LAST_TAG..HEAD"
if [[ -n "$SINCE_TAG" ]]; then
    RANGE="${SINCE_TAG}..HEAD"
fi
if [[ -z "$LAST_TAG" ]] && [[ -z "$SINCE_TAG" ]]; then
    RANGE="--all"
fi

# Categorize commits
categorize_commit() {
    local msg="$1"
    local lower_msg=$(echo "$msg" | tr '[:upper:]' '[:lower:]')
    
    if [[ "$lower_msg" =~ ^\s*(feat|feature|add)[\s:] ]] || [[ "$lower_msg" =~ \+:$ ]]; then
        echo "Added"
    elif [[ "$lower_msg" =~ ^\s*(fix|bugfix|hotfix|patch)[\s:] ]]; then
        echo "Fixed"
    elif [[ "$lower_msg" =~ breaking[\s-]change ]] || [[ "$msg" =~ BREAKING ]]; then
        echo "BREAKING"
    elif [[ "$lower_msg" =~ ^\s*(refactor|chore|perf|style)[\s:] ]]; then
        echo "Changed"
    elif [[ "$lower_msg" =~ ^\s*docs[\s:] ]]; then
        echo "Changed"
    elif [[ "$lower_msg" =~ ^\s*(remove|delete|deprecate)[\s:] ]]; then
        echo "Removed"
    elif [[ "$lower_msg" =~ ^\s*test[\s:] ]]; then
        echo "Changed"
    else
        echo "Changed"  # Default
    fi
}

# Fetch commits
declare -A categories
categories[Added]=""
categories[Fixed]=""
categories[Changed]=""
categories[Removed]=""
categories[BREAKING]=""

if [[ -n "$REPO_URL" ]]; then
    # Clone shallow for analysis
    TEMP_DIR=$(mktemp -d)
    git clone --depth=100 "$REPO_URL" "$TEMP_DIR" 2>/dev/null
    cd "$TEMP_DIR"
fi

# Get commit count
COMMIT_COUNT=$(git log $RANGE --oneline 2>/dev/null | wc -l | tr -d ' ')

echo "📊 Analyzing git history..."
echo "   Commits found: $COMMIT_COUNT"

if [[ "$COMMIT_COUNT" -eq 0 ]]; then
    echo "No commits found in range."
    exit 0
fi

# Process each commit
while IFS= read -r line; do
    hash=$(echo "$line" | cut -d' ' -f1)
    msg=$(echo "$line" | sed 's/^[^ ]* //')
    
    category=$(categorize_commit "$msg")
    
    # Clean up message for display
    clean_msg=$(echo "$msg" | sed 's/^[^:]*: //' | head -c 100)
    
    entry="- $clean_msg"
    
    case $category in
        Added)
            categories[Added]="${categories[Added]}\n${entry}"
            ;;
        Fixed)
            categories[Fixed]="${categories[Fixed]}\n${entry}"
            ;;
        Changed)
            categories[Changed]="${categories[Changed]}\n${entry}"
            ;;
        Removed)
            categories[Removed]="${categories[Removed]}\n${entry}"
            ;;
        BREAKING)
            categories[BREAKING]="${categories[BREAKING]}\n${entry}"
            ;;
    esac
done < <(git log $RANGE --format="%h %s" 2>/dev/null)

# Generate version string
if [[ -z "$VERSION" ]]; then
    if [[ -n "$LAST_TAG" ]]; then
        # Bump patch version
        major=$(echo "$LAST_TAG" | cut -d. -f1 | tr -d 'v')
        minor=$(echo "$LAST_TAG" | cut -d. -f2)
        patch=$(echo "$LAST_TAG" | cut -d. -f3)
        patch=$((patch + 1))
        VERSION="${major}.${minor}.${patch}"
    else
        VERSION="0.1.0 (unreleased)"
    fi
fi

DATE=$(date -u +'%Y-%m-%d')

# Build CHANGELOG content
CHANGELOG="# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [${VERSION}] - ${DATE}
"

# Add sections (only if they have content)
if [[ -n "${categories[Added]}" ]]; then
    CHANGELOG="${CHANGELOG}
### Added
$(echo -e "${categories[Added]}")"
fi

if [[ -n "${categories[Fixed]}" ]]; then
    CHANGELOG="${CHANGELOG}
### Fixed
$(echo -e "${categories[Fixed]}")"
fi

if [[ -n "${categories[Changed]}" ]]; then
    CHANGELOG="${CHANGELOG}
### Changed
$(echo -e "${categories[Changed]}")"
fi

if [[ -n "${categories[Removed]}" ]]; then
    CHANGELOG="${CHANGELOG}
### Removed
$(echo -e "${categories[Removed]}")"
fi

if [[ -n "${categories[BREAKING]}" ]]; then
    CHANGELOG="${CHANGELOG}
### BREAKING
$(echo -e "${categories[BREAKING]}")"
fi

# Write output
echo -e "$CHANGELOG" > "$OUTPUT_FILE"

echo ""
echo "✅ Generated $OUTPUT_FILE"
echo "   Version: $VERSION"
echo "   Commits: $COMMIT_COUNT"
echo ""
echo "Categories:"
[[ -n "${categories[Added]}" ]] && echo "   Added:   $(echo -e "${categories[Added]}" | wc -l | tr -d ' ') entries"
[[ -n "${categories[Fixed]}" ]] && echo "   Fixed:   $(echo -e "${categories[Fixed]}" | wc -l | tr -d ' ') entries"
[[ -n "${categories[Changed]}" ]] && echo "   Changed: $(echo -e "${categories[Changed]}" | wc -l | tr -d ' ') entries"
[[ -n "${categories[Removed]}" ]] && echo "   Removed: $(echo -e "${categories[Removed]}" | wc -l | tr -d ' ') entries"
[[ -n "${categories[BREAKING]}" ]] && echo "   BREAKING: $(echo -e "${categories[BREAKING]}" | wc -l | tr -d ' ') entries"

# Cleanup temp dir
if [[ -n "$REPO_URL" ]]; then
    rm -rf "$TEMP_DIR"
fi
