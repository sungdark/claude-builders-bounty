# Pre-tool-use Hook: Block Destructive Commands

A Claude Code `pre-tool-use` hook that intercepts dangerous bash and SQL commands **before** they are executed.

## Blocked Patterns

| Pattern | Reason |
|---------|--------|
| `rm -rf /`, `rm -rf ~`, `rm -rf .`, `rm -rf ..` | Recursive force delete — permanently destroys data |
| `DROP DATABASE`, `DROP TABLE`, `DROP SCHEMA` | Permanently removes database objects |
| `TRUNCATE TABLE` | Deletes all rows from a table |
| `DELETE FROM <table>;` (no WHERE/LIMIT) | Deletes all rows without filter |
| `git push --force`, `git push -f` | Rewrites remote history — dangerous in shared repos |
| Fork bombs `():{:|:&};:` | Saturates system processes |
| `mkfs.*`, `dd of=/dev/*` | Direct block device or filesystem format |

## Installation

### Step 1: Install the hook script

```bash
mkdir -p ~/.claude/hooks
curl -fsSL https://raw.githubusercontent.com/sungdark/claude-builders-bounty/sungdark-issue3-hook/hooks/pre-tool-use/block-destructive.sh \
  -o ~/.claude/hooks/block-destructive.sh
chmod +x ~/.claude/hooks/block-destructive.sh
```

### Step 2: Register it in `hooks.json`

Add to `~/.claude/hooks.json`:

```json
{
  "hooks": {
    "pre-tool-use": [
      {
        "name": "block-destructive",
        "path": "~/.claude/hooks/block-destructive.sh"
      }
    ]
  }
}
```

If you don't have a `hooks.json` file yet:

```bash
cat > ~/.claude/hooks.json << 'EOF'
{
  "hooks": {
    "pre-tool-use": [
      {
        "name": "block-destructive",
        "path": "~/.claude/hooks/block-destructive.sh"
      }
    ]
  }
}
EOF
```

That's it — 2 commands total. Claude Code will now run this hook on every `Bash` tool invocation.

## Audit Log

Every blocked attempt is logged to:

```
~/.claude/hooks/blocked.log
```

Format:
```
[2026-03-28 08:30:00] BLOCKED | Project: /path/to/project | Reason: Recursive force delete | Command: rm -rf /
[2026-03-28 08:30:01] BLOCKED | Project: /path/to/project | Reason: DROP TABLE without safety | Command: DROP TABLE users
```

## How It Works

The hook receives Claude Code's `pre-tool-use` payload (tool name + input) on stdin. It extracts the bash command and checks it against known-destructive patterns using shell glob matching and grep. If a match is found, it:

1. Logs the blocked attempt to `~/.claude/hooks/blocked.log` with timestamp, project path, and reason
2. Prints a human-readable block message to stderr
3. Exits with code `1` to tell Claude Code to abort this tool call

Commands that pass the filter exit with code `0` and are allowed to proceed.

## Supported Hook Format

This hook uses the **classic pre-tool-use hook** format (single-script, stdin/stdout). It is compatible with Claude Code's standard hooks interface.

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Allow the tool call to proceed |
| `1` | Block the tool call — command is dangerous |
| non-zero (other) | Block and report error |

## Requirements

- Bash 4.0+
- Python 3 (for JSON parsing of tool input)
- Standard Unix tools: `sed`, `grep`, `head`, `date`

## Acknowledgements

Built for [claude-builders-bounty Issue #3](https://github.com/claude-builders-bounty/claude-builders-bounty/issues/3) — bounty sponsored by Opire.
