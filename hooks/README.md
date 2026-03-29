# Pre-Tool-Use Security Hook — Claude Code

**Bounty:** $100 — powered by [Opire](https://opire.dev)

A Claude Code `pre-tool-use` hook that intercepts and blocks dangerous bash commands before execution.

## What It Blocks

| Pattern | Reason |
|---------|--------|
| `rm -rf /`, `rm -rf ~`, `rm -rf $HOME` | Unrestricted destructive delete |
| `DROP TABLE ...` | SQL table destruction |
| `TRUNCATE ...` | SQL table truncation |
| `git push --force` | Remote history rewrite |
| `DELETE FROM ...` (no WHERE) | Unconditional row deletion |

## Installation (2 Commands)

```bash
# 1. Copy the hook to your Claude Code hooks directory
mkdir -p ~/.claude/hooks
curl -o ~/.claude/hooks/pre-tool-use https://raw.githubusercontent.com/claude-builders-bounty/claude-builders-bounty/main/hooks/pre-tool-use
chmod +x ~/.claude/hooks/pre-tool-use

# 2. Restart Claude Code — the hook loads automatically
```

## How It Works

1. Every time Claude Code runs a bash command, this hook fires **before** execution
2. It checks the command against dangerous patterns
3. If blocked: logs to `~/.claude/hooks/blocked.log` and shows Claude a warning message
4. If safe: passes through normally with zero latency

## Block Log Format

Each blocked attempt is logged with timestamp, command, reason, and project path:

```
[2026-03-29 10:30:15] BLOCKED: 'rm -rf / --no-preserve-root' | Reason: rm -rf on root, home, or HOME directory | Project: /home/user/project
```

## Bypassing (If Needed)

If you genuinely need to run a blocked command:

1. Ask the user to confirm explicitly
2. Run the command directly in their terminal outside Claude Code

## Requirements

- Claude Code (latest version)
- Bash 4+
- `jq` or standard Unix tools (`grep`, `sed`, `date`)
