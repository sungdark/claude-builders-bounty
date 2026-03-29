# Claude Code Pre-Tool-Use Safety Hook

**Bounty:** $100 | **Author:** claude-builders-bounty

## Overview

A `pre-tool-use` hook that intercepts dangerous bash commands before they are executed, preventing accidental data loss. Logs all blocked attempts and explains why each command was blocked.

## Features

- 🛡️ **Blocks destructive commands** — `rm -rf`, `DROP TABLE`, `git push --force`, `TRUNCATE`, dangerous `DELETE FROM`
- 📝 **Detailed logging** — Every blocked attempt logged with timestamp, command, and project path
- 💬 **Clear user feedback** — Explains exactly why the command was blocked
- 🔒 **Non-intrusive** — Normal bash commands pass through unaffected
- ⚡ **Easy install** — 2 commands to set up

## Installation (2 Commands)

```bash
# 1. Clone/download the hook
git clone https://github.com/claude-builders-bounty/claude-builders-bounty.git ~/claude-hooks
cd ~/claude-hooks/hooks/pre-tool-use

# 2. Symlink to Claude hooks directory
mkdir -p ~/.claude/hooks
ln -s "$(pwd)/pre-tool-use.sh" ~/.claude/hooks/pre-tool-use.sh

# 3. Make executable
chmod +x ~/.claude/hooks/pre-tool-use.sh
```

That's it! Claude Code will now run this hook before every bash command.

## How It Works

When you run a potentially dangerous command, the hook:

1. Checks the command against dangerous patterns
2. If dangerous: logs to `~/.claude/hooks/blocked.log`, prints a warning, exits with error
3. If safe: passes through to normal execution

## Dangerous Patterns Blocked

| Pattern | Why |
|---------|-----|
| `rm -rf /` | Deletes entire filesystem |
| `rm -rf ~` | Deletes home directory |
| `DROP TABLE` | Permanently removes database table |
| `DROP DATABASE` | Removes entire database |
| `TRUNCATE` | Empties table without logging |
| `git push --force` | Overwrites remote history |
| `DELETE FROM` (no WHERE) | Deletes all rows in a table |
| `shred` | Securely deletes files |
| `:(){:|:&};:` | Fork bomb |

## Log Format

```
[2026-03-29 07:15:32 UTC] BLOCKED: rm -rf /tmp/test
  User: ubuntu
  Project: /home/ubuntu/project
  Reason: rm -rf on root-level path
  Tool: bash

[2026-03-29 07:16:45 UTC] BLOCKED: DROP TABLE users;
  User: postgres
  Project: /home/ubuntu/project
  Reason: DROP TABLE without DROP TABLE confirmation
  Tool: bash
```

## Configuration

Edit `config.sh` to customize:

```bash
# Add custom blocked patterns
CUSTOM_PATTERNS=(
    "mycompany-secret-command"
    "production-delete"
)

# Enable/disable specific blocks
BLOCK_RM_RF=1
BLOCK_GIT_FORCE=1
BLOCK_SQL_DANGEROUS=1

# Log file location
LOG_FILE="$HOME/.claude/hooks/blocked.log"
```

## Testing

```bash
# Test blocked commands (should be intercepted)
./pre-tool-use.sh "rm -rf /tmp/test"
./pre-tool-use.sh "DROP TABLE users;"
./pre-tool-use.sh "git push --force origin main"

# Test safe commands (should pass through)
./pre-tool-use.sh "ls -la"
./pre-tool-use.sh "git status"
./pre-tool-use.sh "echo 'hello world'"
```

## Requirements

- bash 4.0+
- Claude Code (any recent version)

## Troubleshooting

**Hook not firing?**
- Verify symlink: `ls -la ~/.claude/hooks/pre-tool-use.sh`
- Check Claude Code version: `claude --version` (update if outdated)
- Enable hook debugging: `export HOOK_DEBUG=1` in `pre-tool-use.sh`

**Hook firing on safe commands?**
- Check the log: `cat ~/.claude/hooks/blocked.log`
- Adjust patterns in `config.sh`

## Files

```
hooks/pre-tool-use/
├── pre-tool-use.sh      # Main hook script
├── config.sh            # Configuration
├── README.md            # This file
└── blocked.log.example  # Example log format
```

## License

MIT
