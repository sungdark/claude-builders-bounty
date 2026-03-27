# Claude Code Pre-Tool-Use Hook: Destructive Command Blocker

A `pre-tool-use` hook for Claude Code that intercepts and blocks dangerous bash commands before they execute.

## What It Blocks

| Pattern | Reason |
|---------|--------|
| `rm -rf` | Recursive force delete |
| `DROP TABLE` | SQL drop — irreversible |
| `git push --force` | Rewrites remote history |
| `TRUNCATE` | Deletes all table rows |
| `DELETE FROM` without `WHERE` | Wipes entire table |
| `mkfs.*` | Destroys filesystem |
| `dd of=/dev/*` | Direct block device write |

## Installation

```bash
# 2 commands
curl -fsSL https://raw.githubusercontent.com/sungdark/claude-builders-bounty/pre-tool-hook/pre-tool-hook/pre-tool-use-hook.sh -o ~/.claude/hooks/pre-tool-use
chmod +x ~/.claude/hooks/pre-tool-use
```

## How It Works

1. Hook script lives at `~/.claude/hooks/pre-tool-use`
2. Receives tool payload via stdin as JSON
3. Checks bash command against dangerous regex patterns
4. If blocked: logs to `~/.claude/hooks/blocked.log` + tells Claude why
5. Exit code `1` = block, `0` = allow

## Log Format

Each blocked attempt is logged with timestamp, tool name, command, reason, and working directory.

## Requirements

- Python 3.6+
- Claude Code (latest version with hooks support)

## Claude Code Hooks Docs

https://docs.anthropic.com/claude-code/hooks
