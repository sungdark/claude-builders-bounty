# pre-tool-use: Security Hook for Claude Code

A Claude Code `pre-tool-use` hook that intercepts and blocks dangerous bash commands before they execute.

## Security Patterns Blocked

| Pattern | Risk |
|---------|------|
| `rm -rf /path` | Permanent recursive deletion |
| `DROP TABLE` | Permanent database table deletion |
| `TRUNCATE` | Permanent table content deletion |
| `git push --force` | Rewrites remote git history |
| `DELETE FROM` without WHERE | Permanent data deletion |

## Installation (2 Commands)

```bash
# 1. Link the hook into your Claude Code hooks directory
ln -sf $(pwd)/pre-tool-use ~/.claude/hooks/pre-tool-use

# 2. Make it executable
chmod +x ~/.claude/hooks/pre-tool-use
```

That's it! Claude Code will automatically invoke this hook before every bash command.

## Usage

The hook runs automatically. When a dangerous command is detected:

```
⛔ HOOK BLOCKED: rm -rf detected: permanent recursive deletion
Command: rm -rf /tmp/test
This command has been blocked by the pre-tool-use security hook.
Log: ~/.claude/hooks/blocked.log
```

## Blocked Command Log

All blocked attempts are logged to:
```
~/.claude/hooks/blocked.log
```

Each entry includes:
- Timestamp
- Full command that was blocked
- Project directory
- Reason for blocking

## How It Works

Claude Code hooks use a simple protocol:
- The hook script is called before each tool execution
- It receives the command via stdin
- If it exits with code 0 → command proceeds
- If it exits with non-zero → command is blocked

## Caveats

- This hook only intercepts bash commands executed by Claude Code
- It does not prevent direct terminal usage
- Always review the log periodically for blocked attempts
- The `git push --force` detection requires `--force` to be on the command line (not an alias)

## Uninstall

```bash
rm ~/.claude/hooks/pre-tool-use
```

## License
MIT
