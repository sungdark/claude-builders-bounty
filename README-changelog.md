# Generate Changelog from Git History

A simple bash script + Claude Code skill to automatically generate a `CHANGELOG.md` from your git commit history.

## Features
- Auto-categorizes commits into: Added, Fixed, Changed, Removed
- Uses git tags to scope commits (or all commits if no tags exist)
- Follows [Keep a Changelog](https://keepachangelog.com/) format
- Works with any git repo

## Setup (3 Steps)

### Step 1: Copy the script to your project
```bash
curl -O https://raw.githubusercontent.com/sungdark/claude-builders-bounty/main/changelog.sh
chmod +x changelog.sh
```

### Step 2: Run to generate CHANGELOG.md
```bash
bash changelog.sh
```

### Step 3: Commit the CHANGELOG
```bash
git add CHANGELOG.md
git commit -m "docs: update changelog"
```

## Usage

```bash
# Default: current directory, outputs CHANGELOG.md
bash changelog.sh

# Specify a different repo
bash changelog.sh /path/to/repo

# Custom output path
bash changelog.sh . /path/to/CHANGELOG.md
```

## Auto-Categorization

Commits are categorized by keywords in the subject line:

| Category | Keywords |
|----------|----------|
| Added | add, new, feat, introduce, implement, initial |
| Fixed | fix, bug, patch, repair, resolve, correct |
| Changed | change, update, modify, refactor, improve |
| Removed | remove, delete, drop, deprecate |

Commits that don't match any keyword go into **Changed**.

## Sample Output

```markdown
# Changelog

All notable changes to this project will be documented in this file.

This changelog follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format.

## [1.0.0] - 2026-03-20

### Added
- New authentication module

### Fixed
- Bug in payment processing
- Memory leak in background worker

### Changed
- Updated dependencies
- Refactored database layer
```

## Claude Code Skill

You can also trigger this via Claude Code's skill system. See `SKILL.md` for details.

## License
MIT
