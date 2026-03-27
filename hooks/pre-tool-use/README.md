# Claude Code Pre-Tool-Use Hook: Block Destructive Commands

A security hook for [Claude Code](https://docs.anthropic.com/claude-code) that intercepts and blocks dangerous bash commands before execution.

## Installation (2 commands)

```bash
# 1. Copy the hook to your Claude hooks directory
mkdir -p ~/.claude/hooks
cp pre_tool_use.py ~/.claude/hooks/pre_tool_use.py
chmod +x ~/.claude/hooks/pre_tool_use.py

# 2. Register the hook in ~/.claude/settings.json
# Add this to your settings:
# {
#   "hooks": {
#     "pre_tool_use": "python3 ~/.claude/hooks/pre_tool_use.py"
#   }
# }
```

Or if you prefer bash:

```bash
mkdir -p ~/.claude/hooks
cp pre_tool_use.sh ~/.claude/hooks/pre_tool_use.sh
chmod +x ~/.claude/hooks/pre_tool_use.sh
# Then update settings.json to point to the .sh file
```

## What It Blocks

| Pattern | Why Blocked |
|---------|-------------|
| `rm -rf /` or `rm -rf /path` | Recursive force delete — irreversible |
| `DROP TABLE` | Drops entire database table |
| `TRUNCATE TABLE` | Removes all rows from table |
| `git push --force` / `git push -f` | Overwrites remote history |
| `DELETE FROM` without `WHERE` | Deletes ALL rows in table |
| `dd ... of=/dev/sdX` | Risk of full disk wipe |
| `mkfs.*` | Formats a filesystem |
| `> /dev/sdX` | Direct block device write |

## Block Log

Every blocked attempt is logged to:
```
~/.claude/hooks/blocked.log
```

Format:
```
[2026-03-27T12:00:00] BLOCKED in /home/user/project: rm -rf /tmp/test
```

## Exit Codes

- `0` — Command allowed to proceed
- `1` — Command blocked

## Testing

```bash
# Should be blocked:
echo "rm -rf /tmp/test" | python3 pre_tool_use.py Bash rm -rf /tmp/test
# Should be allowed:
echo "ls -la" | python3 pre_tool_use.py Bash ls -la
```

## Requirements

- Python 3.6+
- Claude Code

## License

Apache 2.0
