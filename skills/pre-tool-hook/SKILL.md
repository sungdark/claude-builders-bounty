# SKILL: Pre-Tool-Use Hook — Block Destructive Bash Commands

## What It Does

A Claude Code `pre-tool-use` hook that intercepts dangerous bash/SQL commands before they execute, blocks them, and logs the attempt.

## How It Works

1. Claude Code calls a tool
2. The hook (placed in `~/.claude/hooks/`) receives the tool name and arguments
3. If the command matches a dangerous pattern → **blocked**, logged to `~/.claude/hooks/blocked.log`
4. If safe → passes through without interference

## Blocked Patterns

| Pattern | Danger |
|---------|--------|
| `rm -rf ...` | Recursive forced deletion |
| `DROP TABLE` / `DROP DATABASE` | SQL destruction |
| `git push --force` | Forced push to remote |
| `TRUNCATE TABLE` / `TRUNCATE DATABASE` | SQL table truncation |
| `DELETE FROM` without `WHERE` | Unconditional bulk delete |
| `mkfs.*` | Filesystem format |
| `dd ... /dev/` | Direct block device write |

## Log Format

```
[2026-03-29T18:00:00Z] BLOCKED | tool=Bash | project=/path/to/repo | reason=Recursive forced deletion | command=rm -rf /tmp/test
```

## Installation

See `README.md` for 2-command setup.
