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
{
  "hooks": {
    "pre_tool_use": "python3 ~/.claude/hooks/pre_tool_use.py"
  }
}
```

Or for the Bash version (no Python required):

```bash
mkdir -p ~/.claude/hooks
cp pre_tool_use.sh ~/.claude/hooks/pre_tool_use.sh
chmod +x ~/.claude/hooks/pre_tool_use.sh
# Then update settings.json to:
#   "pre_tool_use": "bash ~/.claude/hooks/pre_tool_use.sh"
```

## How It Works

Claude Code sends a JSON payload via stdin to the hook:

```json
{
  "tool": "Bash",
  "params": {
    "command_line": "rm -rf /tmp/test"
  }
}
```

The hook outputs `{"allow": true}` to allow or `{"allow": false, "report": "reason"}` to block.

## What It Blocks

| Pattern | Why |
|---------|-----|
| `rm -rf /` or `rm -rf /path` | Recursive force delete — irreversible |
| `DROP TABLE` | Drops entire database table |
| `TRUNCATE TABLE` | Removes all rows from table |
| `git push --force` / `git push -f` | Overwrites remote history |
| `DELETE FROM` without `WHERE` | Deletes ALL rows in table |
| `dd ... of=/dev/*` | Risk of full disk wipe |
| `mkfs.*` | Formats a filesystem |
| `> /dev/sdX` | Direct block device write |

## Block Log

Every blocked attempt is logged to `~/.claude/hooks/blocked.log`:

```
[2026-03-27T12:00:00+00:00] BLOCKED in /home/user/project: rm -rf /tmp/test
  Reason: rm -rf / — root deletion
```

## Testing

```bash
# Test blocked command (exit code 1 = blocked)
echo '{"tool": "Bash", "params": {"command_line": "rm -rf /tmp/test"}}' \
  | python3 pre_tool_use.py
# Output: {"allow": false, "report": "🚫 BLOCKED: rm -rf / — root deletion..."}

# Test allowed command (exit code 0 = allowed)
echo '{"tool": "Bash", "params": {"command_line": "ls -la"}}' \
  | python3 pre_tool_use.py
# Output: {"allow": true}
```

## Exit Codes

- `0` with `{"allow": true}` — Command allowed
- `0` with `{"allow": false, ...}` — Command blocked (Claude shows the report)

## Requirements

- Python 3.6+ (or Bash for the shell version)
- Claude Code

## License

Apache 2.0
