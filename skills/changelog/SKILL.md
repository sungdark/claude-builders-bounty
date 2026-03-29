# SKILL: Generate CHANGELOG from Git History

**Trigger:** `/generate-changelog` or `generate changelog`

## How to Use

1. Run `/generate-changelog` in your Claude Code project
2. The skill will analyze your git history since the last tag
3. A structured `CHANGELOG.md` will be created/updated

## What It Does

1. Finds the most recent git tag to determine version boundary
2. Fetches all commits between the last tag and HEAD
3. Categorizes each commit into: **Added**, **Fixed**, **Changed**, **Removed**
4. Generates a properly formatted `CHANGELOG.md` in Keep a Changelog format

## Categorization Rules

| Commit Message Contains | CHANGELOG Section |
|--------------------------|-------------------|
| `feat:`, `feat:`, `+:` | **Added** |
| `fix:`, `bugfix:`, `hotfix:` | **Fixed** |
| `refactor:`, `chore:`, `perf:` | **Changed** |
| `remove:`, `delete:`, `deprecate:` | **Removed** |
| `docs:` | **Changed** |
| `BREAKING CHANGE` | **BREAKING** |

## Customization Options

- `--since "YYYY-MM-DD"` — Generate changelog since specific date
- `--version "1.2.3"` — Set a specific version number
- `--output file.md` — Write to a custom file path
- `--include-unreleased` — Include commits not in any tag

## Output Format

Follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) specification:

```markdown
# Changelog

## [Version] - YYYY-MM-DD

### Added
- New features

### Fixed
- Bug fixes

### Changed
- Changes to existing functionality

### Removed
- Removed features

### BREAKING
- Breaking changes
```

## Example

```
User: /generate-changelog
Assistant: I'll generate a CHANGELOG from your git history...

Found 47 commits since v2.0.0 (2026-02-15)

Categories:
  Added: 5
  Fixed: 3
  Changed: 8
  Removed: 1

Generated CHANGELOG.md with 47 entries across 4 categories.
```

## Error Handling

- **No git repo**: Error message asking to run in a git repository
- **No tags found**: Falls back to analyzing all commits
- **Empty history**: Informs user and skips generation
