# SKILL.md - Generate Changelog from Git History

## When to Use
When a user asks to generate, create, or update a CHANGELOG, or when they mention `/generate-changelog`.

## How It Works
Runs `changelog.sh` which:
1. Finds the most recent git tag (or uses all commits if none exist)
2. Parses commit messages since that tag
3. Auto-categorizes commits into: **Added**, **Fixed**, **Changed**, **Removed**
4. Outputs a `CHANGELOG.md` file following Keep a Changelog format

## Usage

```bash
# Default: generate CHANGELOG.md in current directory
bash changelog.sh

# Custom repo path
bash changelog.sh /path/to/repo

# Custom output file
bash changelog.sh . /path/to/CHANGELOG.md
```

## Categorization Logic
Commits are auto-categorized by keywords in the commit message:
- **Added**: add, new, feat, introduce, implement, initial
- **Fixed**: fix, bug, patch, repair, resolve, correct
- **Changed**: change, update, modify, refactor, improve
- **Removed**: remove, delete, drop, deprecate

Commits that don't match any category go into **Changed**.

## Output Format
Follows Keep a Changelog v1.0.0 format:
```markdown
# Changelog

## [1.2.0] - 2026-03-27

### Added
- New feature X

### Fixed
- Bug in Y
```
