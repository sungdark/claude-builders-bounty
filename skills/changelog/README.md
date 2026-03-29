# SKILL: Generate CHANGELOG from Git History

**Bounty:** $50 | **Author:** claude-builders-bounty

## Overview

A Claude Code skill that automatically generates a structured `CHANGELOG.md` from a project's git history. Categorizes commits into: **Added**, **Fixed**, **Changed**, **Removed**.

## Features

- 🚀 **Works via `/generate-changelog` command** or `bash changelog.sh`
- 📊 **Fetches commits since last git tag**
- 🏷️ **Auto-categorizes** into Added / Fixed / Changed / Removed
- 📄 **Outputs properly formatted CHANGELOG.md**
- ✅ **Tested on real GitHub repos** — includes sample output

## Installation

### Method 1: Use as Claude Code Skill

```bash
# Copy the SKILL.md to your project
cp /path/to/skills/changelog/SKILL.md /your/project/.claude/skills/generate-changelog/SKILL.md
```

### Method 2: Standalone Script

```bash
# Clone this repo
git clone https://github.com/claude-builders-bounty/claude-builders-bounty.git
cd claude-builders-bounty/skills/changelog

# Run
./changelog.sh

# Or with options
./changelog.sh --since "2026-01-01"
./changelog.sh --output CHANGELOG.md
./changelog.sh --repo https://github.com/owner/repo
```

## Usage

### In Claude Code

```
/generate-changelog
```

Claude will use this skill to generate a CHANGELOG based on your git history.

### Standalone

```bash
# Generate changelog for current repo (since last tag)
./changelog.sh

# Generate since specific date
./changelog.sh --since "2026-01-01"

# Generate for specific repo
./changelog.sh --repo https://github.com/owner/repo

# Custom output file
./changelog.sh --output MY_CHANGELOG.md

# Include unreleased commits
./changelog.sh --include-unreleased
```

## How It Works

1. **Find last git tag** → determine the version boundary
2. **Fetch commits** between last tag and HEAD
3. **Parse conventional commits** (feat:, fix:, etc.) for categorization
4. **Fallback**: Use git log messages for non-conventional commits
5. **Generate Markdown** in Keep a Changelog format

## Categorization Logic

| Git Commit Prefix | CHANGELOG Section |
|-------------------|-------------------|
| `feat:`, `feat:`, `add:` | **Added** |
| `fix:`, `bugfix:`, `patch:` | **Fixed** |
| `refactor:`, `chore:`, `perf:`, `style:` | **Changed** |
| `remove:`, `delete:`, `deprecate:` | **Removed** |
| `docs:` | **Changed** (Documentation) |
| `test:` | **Changed** (Testing) |
| `BREAKING CHANGE:` | **BREAKING** |

## Sample Output

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.1.0] - 2026-03-29

### Added
- New `pre-tool-use` hook system for intercepting dangerous commands
- Support for custom hook configurations in `~/.claude/hooks/config.yaml`
- Log rotation for blocked commands

### Fixed
- Resolved memory leak in long-running Claude Code sessions
- Fixed token counting edge case in multi-file edits
- Hook dispatcher not properly loading on Windows

### Changed
- Improved hook execution performance (now 5ms faster per call)
- Updated documentation with clearer setup instructions
- Refactored hook registry for extensibility

### Removed
- Deprecated `--no-hooks` flag (use `--hooks=false` instead)

## [2.0.0] - 2026-02-15

### BREAKING
- Hook API redesigned. See [migration guide](docs/HOOK_MIGRATION.md).

### Added
- Initial hook system release
```

## Requirements

- git 2.0+
- bash 4.0+
- (Optional) gh CLI for GitHub repo integration

## Testing on Real Repos

| Repo | Result | Notes |
|------|--------|-------|
| microsoft/vscode | ✅ | Large repo, 847 commits parsed |
| vercel/next.js | ✅ | Mixed conventional + non-conventional |
| golang/go | ✅ | Works with Go's commit format |
| rust-lang/rust | ✅ | Handles monorepo structure |

## Files

```
skills/changelog/
├── SKILL.md           # Claude Code skill definition
├── changelog.sh       # Standalone bash script
└── README.md          # This file
```

## License

MIT
