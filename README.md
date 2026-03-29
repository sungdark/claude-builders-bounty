# Auto CHANGELOG Generator

**Bounty:** $50 — powered by [Opire](https://opire.dev)

## What It Does
Generates a structured `CHANGELOG.md` from your project's git history, automatically categorizing commits into **Added / Fixed / Changed / Removed** sections.

## Setup (3 Steps)

```bash
# 1. Save changelog.sh to your project root
curl -O https://raw.githubusercontent.com/claude-builders-bounty/claude-builders-bounty/main/changelog.sh

# 2. Make it executable
chmod +x changelog.sh

# 3. Run it
./changelog.sh
```

Output: `CHANGELOG.md` in your project root.

## Advanced Usage

```bash
# Generate from a specific tag
./changelog.sh --since-tag v1.0.0

# Output to a custom file
./changelog.sh --output HISTORY.md
```

## How It Works

1. Finds the last git tag (or uses `--since-tag` if specified)
2. Extracts all commits since that tag
3. Categorizes each commit by its prefix:
   - `feat`, `add`, `new` → **Added**
   - `fix`, `bug`, `patch` → **Fixed**
   - `remove`, `delete`, `deprecate` → **Removed**
   - everything else → **Changed**
4. Outputs a standard [Keep a Changelog](https://keepachangelog.com/) format

## Requirements
- Bash 4+
- Git with at least one tag

## Tested On
- Linux (Ubuntu, Debian, macOS)
- Git 2.20+
