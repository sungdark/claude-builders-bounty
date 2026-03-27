# CHANGELOG Generator Skill

Generate a structured CHANGELOG.md from git history, auto-categorizing commits.

## Usage

```
/generate-changelog
```

Or run directly:
```bash
bash changelog.sh
```

## What It Does

1. Fetches commits since the last git tag (or all commits if no tag)
2. Parses conventional commit messages (feat:, fix:, chore:, etc.)
3. Auto-categorizes into: **Added** / **Fixed** / **Changed** / **Removed** / **Other**
4. Outputs a properly formatted CHANGELOG.md

## Conventional Commit Mapping

| Prefix | Category |
|--------|----------|
| `feat:` | Added |
| `fix:` | Fixed |
| `perf:` | Changed |
| `refactor:` | Changed |
| `chore:` | Changed |
| `docs:` | Changed |
| `test:` | Changed |
| `BREAKING CHANGE` | Removed |
| `feat!:` / `fix!:` | Removed (breaking) |

## Sample Output

```markdown
# Changelog

## [1.2.0] - 2026-03-27

### Added
- User authentication with OAuth2
- New dashboard API endpoint

### Fixed
- Memory leak in background worker
- Rate limiting not applied to premium users

### Changed
- Upgraded to Node.js 22
- Improved error messages

### Removed
- Legacy v1 API endpoints (BREAKING)
```

## Requirements

- Git repository
- Standard unix tools: `git`, `grep`, `sed`, `awk`
