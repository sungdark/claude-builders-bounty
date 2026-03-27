# Claude Code Pre-Tool-Use Destructive Command Blocker

A Claude Code hook that intercepts and blocks dangerous bash commands before execution.

## Installation (2 commands)

```bash
curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB_USER/claude-builders-bounty/main/pre-tool-use -o ~/.claude/hooks/pre-tool-use
chmod +x ~/.claude/hooks/pre-tool-use
```

## What It Blocks

| Pattern | Reason |
|---------|--------|
| `rm -rf` | Recursive force removal — often destructive |
| `DROP TABLE` | Database schema destruction |
| `TRUNCATE` | Table data destruction |
| `git push --force` | Rewrites remote history |
| `DELETE FROM` without `WHERE` | Mass data deletion |

## Blocked Log

Every blocked attempt is logged to `~/.claude/hooks/blocked.log` with:
- Timestamp
- Project path
- Attempted command
- Reason for block

## Requirements

- Python 3.6+
- Claude Code CLI

## Disable Temporarily

```bash
chmod -x ~/.claude/hooks/pre-tool-use
```
