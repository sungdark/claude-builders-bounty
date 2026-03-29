# SKILL: Generate CHANGELOG from Git History

Generate a structured `CHANGELOG.md` from a project's git commit history, categorizing changes automatically.

## Activation
Trigger: `/generate-changelog`

## How It Works
1. Gets all commits since the last git tag (or from a specified start point)
2. Parses commit messages for conventional commit prefixes
3. Categorizes into: **Added** / **Fixed** / **Changed** / **Removed** / **Other**
4. Outputs a properly formatted `CHANGELOG.md`

## Usage

### Command
```
/generate-changelog [--from <tag|commit>] [--output <file>]
```

### Options
- `--from <ref>` — Start from a specific tag or commit (default: last tag)
- `--output <path>` — Output file path (default: `CHANGELOG.md`)

## Output Format

```markdown
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]
### Added
- ...
### Fixed
- ...
### Changed
- ...
### Removed
- ...

## [<version>] - <date>
### Added
- ...
```

## Implementation

The skill uses a bash script (`changelog.sh`) that:

1. **Detect last tag:**
   ```bash
   LAST_TAG=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
   ```

2. **Fetch commits:**
   ```bash
   if [ -z "$LAST_TAG" ]; then
     COMMITS=$(git log --pretty=format:"%h|%s|%an" --no-merges)
   else
     COMMITS=$(git log "$LAST_TAG..HEAD" --pretty=format:"%h|%s|%an" --no-merges)
   fi
   ```

3. **Categorize by prefix:**
   - `feat:` / `feature:` / `add:` → **Added**
   - `fix:` / `bugfix:` / `hotfix:` → **Fixed**
   - `chore:` / `refactor:` / `style:` → **Changed**
   - `remove:` / `delete:` / `deprecate:` → **Removed**
   - Conventional: `feat`, `fix`, `perf`, `docs`, `test`, `build`, `ci`, `chore`, `revert`

4. **Write CHANGELOG.md** with proper sections and dates.

## Example

```bash
cd /path/to/repo
bash changelog.sh
# Generates CHANGELOG.md with all commits since last tag
```

## Sample Output

See `SAMPLE-CHANGELOG.md` for a complete example.

## Notes

- Commits with no clear type prefix go under "Changed"
- Merge commits are excluded (`--no-merges`)
- Author names are included for attribution
- SHA hashes are available for reference
