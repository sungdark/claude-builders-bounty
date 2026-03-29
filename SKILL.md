# SKILL.md - Auto CHANGELOG Generator

## What This Does
Generates a structured CHANGELOG.md from a project's git history, categorizing commits since the last git tag into: **Added**, **Fixed**, **Changed**, **Removed**.

## How to Use
```bash
./changelog.sh [options]
```

## Options
- `--since-tag <tag>` — Generate changelog from a specific tag (default: last annotated tag)
- `--output <file>`   — Output file path (default: CHANGELOG.md)
- `--help`            — Show this help message

## Output Format
```markdown
# Changelog

## [Unreleased]

### Added
- commit message 1
- commit message 2

### Fixed
- commit message 3

### Changed
- commit message 4

### Removed
- commit message 5
```

## Installation
1. Save `changelog.sh` to your project root
2. Run `chmod +x changelog.sh`
3. Run `./changelog.sh`
