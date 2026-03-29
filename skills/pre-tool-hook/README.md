# Pre-Tool-Use Hook — Block Destructive Bash Commands

A Claude Code `pre-tool-use` hook that blocks dangerous bash commands before execution.

## Installation (2 Commands)

```bash
# 1. Download the hook script
curl -sO https://raw.githubusercontent.com/claude-builders-bounty/claude-builders-bounty/main/skills/pre-tool-hook/pre-tool-hook.py
chmod +x pre-tool-hook.py

# 2. Register it in Claude Code settings (~/.claude/settings.json)
# Add this block:
#   "hooks": {
#     "pre-tool-use": "/full/path/to/pre-tool-hook.py"
#   }
```

## What It Blocks

| Pattern | Description |
|---------|-------------|
| `rm -rf /...` | Recursive forced deletion |
| `DROP TABLE` / `DROP DATABASE` | SQL destruction |
| `git push --force` | Forced git push |
| `TRUNCATE TABLE` | SQL table truncation |
| `DELETE FROM` (no WHERE) | Unsafe bulk delete |
| `mkfs.*` | Filesystem formatting |
| `dd ... /dev/` | Direct block device write |

## Log Location

All blocked attempts → `~/.claude/hooks/blocked.log`

```
[2026-03-29T18:00:00Z] BLOCKED | tool=Bash | project=/path/to/repo | reason=... | command=...
```

## Requirements

- Python 3.6+
- Claude Code v1.0+

## Customize

Edit `DANGEROUS_PATTERNS` in `pre-tool-hook.py` to add your own rules.
