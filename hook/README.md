# Pre-Tool-Use Hook: Block Destructive Bash Commands

A Claude Code `pre-tool-use` hook that intercepts and blocks dangerous bash commands before execution.

## What It Blocks

| Pattern | Reason |
|---------|--------|
| `rm -rf /path` | Recursive force delete — destroys data permanently |
| `DROP TABLE` | SQL DROP TABLE — removes entire table |
| `TRUNCATE` | SQL TRUNCATE — removes all rows |
| `git push --force` / `-f` | Force push — overwrites remote history |
| `DELETE FROM table` (no WHERE) | Removes ALL rows from a table |
| `> /dev/sd*` | Direct block device writes |

## Installation (2 commands)

```bash
# 1. Copy the hook into Claude Code's hooks directory
cp pre-tool-use.py ~/.claude/hooks/pre-tool-use.py
chmod +x ~/.claude/hooks/pre-tool-use.py

# 2. That's it! Claude Code auto-discovers hooks in ~/.claude/hooks/
```

Or symlink for easy updates:
```bash
mkdir -p ~/.claude/hooks
ln -s /path/to/hook/pre-tool-use.py ~/.claude/hooks/pre-tool-use.py
```

## How It Works

When Claude Code attempts to run a bash command, this hook:
1. Intercepts the command before execution
2. Checks it against destructive patterns
3. If blocked: logs to `~/.claude/hooks/blocked.log` with timestamp + project path
4. Returns a clear error message to Claude explaining why it was blocked

## Log Format

```
[2026-03-27T12:00:00.000000] BLOCKED | project: /home/user/my-project | reason: Recursive force delete — destroys data permanently | cmd: rm -rf node_modules
```

## Unblocking (if needed)

If you need to bypass the hook for a specific task:

```bash
# Temporarily disable
mv ~/.claude/hooks/pre-tool-use.py ~/.claude/hooks/pre-tool-use.py.disabled

# Run your command, then re-enable:
mv ~/.claude/hooks/pre-tool-use.py.disabled ~/.claude/hooks/pre-tool-use.py
```

## Requirements

- Python 3.7+
- Claude Code (any recent version)
- No external dependencies
