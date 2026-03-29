# SKILL: Generate CHANGELOG from Git History

Generates a structured `CHANGELOG.md` from a project's git commit history, auto-categorizing changes.

## Setup (3 Steps)

### 1. Copy the skill files
```bash
# From the repo root:
cp -r skills/generate-changelog/ /path/to/your/project/
```

### 2. Make the script executable
```bash
chmod +x skills/generate-changelog/changelog.sh
```

### 3. Run it
```bash
cd /path/to/your/project
bash skills/generate-changelog/changelog.sh
```

## Options

```bash
# From a specific tag
bash changelog.sh --from v1.0.0

# To a custom output file
bash changelog.sh --output CHANGELOG.md
```

## Auto-Categorization

Commits are categorized by their prefix:

| Prefix | Category |
|--------|----------|
| `feat:`, `feature:`, `add:`, `new:` | **Added** |
| `fix:`, `bugfix:`, `hotfix:`, `patch:` | **Fixed** |
| `remove:`, `delete:`, `deprecate:` | **Removed** |
| `chore:`, `refactor:`, `style:`, `docs:`, `test:`, `build:`, `ci:`, `perf:`, `revert:` | **Changed** |
| (no prefix or other) | **Other** |

## Output Format

Follows [Conventional Commits](https://www.conventionalcommits.org/) and [Keep a Changelog](https://keepachangelog.com/) standards.

## Dependencies

- `git`
- `bash`
- Standard Unix tools: `cut`, `tr`, `grep`, `head`
