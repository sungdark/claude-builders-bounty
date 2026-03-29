# SKILL.md — Safe Hook: Block Destructive Bash Commands

## What This Does
A Claude Code pre-tool-use hook that intercepts and blocks dangerous bash commands before they execute. Logs all blocked attempts for review.

## Hook File: pre-tool-use
```bash
#!/bin/bash
# Claude Code pre-tool-use hook — blocks destructive commands
# Place at: ~/.claude/hooks/pre-tool-use

HOOK_LOG="${HOME}/.claude/hooks/blocked.log"
BLOCKED_COMMANDS=(
  "rm -rf"
  "DROP TABLE"
  "TRUNCATE"
  "git push --force"
  "git push -f"
  "--force-with-lease"
  "chmod -R 777"
  ":(){:|:&};"  # Fork bomb
  "> /dev/sda"
  "dd if="
  "mkfs"
  "shred -u"
)

BLOCKED=false
INPUT_DATA="$1"  # Claude Code passes tool input as first arg

for pattern in "${BLOCKED_COMMANDS[@]}"; do
  if echo "$INPUT_DATA" | grep -qi "$pattern"; then
    BLOCKED=true
    BLOCKED_PATTERN="$pattern"
    break
  fi
done

# Also check for DELETE FROM without WHERE
if echo "$INPUT_DATA" | grep -Pqi "delete\s+from\s+(?!.*where).*\;?\s*$"; then
  BLOCKED=true
  BLOCKED_PATTERN="DELETE FROM without WHERE clause"
fi

if [ "$BLOCKED" = true ]; then
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
  PROJECT=$(git rev-parse --show-toplevel 2>/dev/null | xargs basename 2>/dev/null || echo "unknown")
  COMMAND=$(echo "$INPUT_DATA" | tr '\n' ' ' | cut -c1-200)

  mkdir -p "$(dirname "$HOOK_LOG")"
  echo "[$TIMESTAMP] BLOCKED: $BLOCKED_PATTERN | Project: $PROJECT | Command: $COMMAND" >> "$HOOK_LOG"

  echo "🚫 HOOK BLOCKED: $BLOCKED_PATTERN"
  echo ""
  echo "This command was blocked by the Claude Code Safe Hook."
  echo "Dangerous patterns detected: $BLOCKED_PATTERN"
  echo ""
  echo "If you need to run this command, you can:"
  echo "  1. Modify the command to be safer (e.g., add --dry-run)"
  echo "  2. Disable the hook temporarily: mv ~/.claude/hooks/pre-tool-use ~/.claude/hooks/pre-tool-use.disabled"
  echo "  3. Add a comment in your prompt explaining why this is necessary"
  echo ""
  echo "This incident has been logged to: $HOOK_LOG"
  exit 1
fi

exit 0
```

## Installation (2 Commands)
```bash
# 1. Install the hook
mkdir -p ~/.claude/hooks
curl -fsSL https://raw.githubusercontent.com/sungdark/claude-builders-bounty/main/skills/safe-hook/pre-tool-use -o ~/.claude/hooks/pre-tool-use
chmod +x ~/.claude/hooks/pre-tool-use

# 2. Verify it's active
ls -la ~/.claude/hooks/pre-tool-use
```

## What Gets Blocked
| Pattern | Risk |
|---------|------|
| `rm -rf` | Accidental mass deletion |
| `DROP TABLE` | Database destruction |
| `TRUNCATE` | Table data destruction |
| `git push --force` | History overwriting |
| `DELETE FROM` without WHERE | Data deletion |
| Fork bombs, disk wipes | System compromise |

## Log Format
```
[2026-03-29 11:00:00] BLOCKED: DROP TABLE | Project: mydb | Command: mysql -e "DROP TABLE users"
[2026-03-29 11:05:00] BLOCKED: rm -rf | Project: project | Command: rm -rf node_modules/
```

## Edge Cases
- Commands with `--force` flags are checked contextually
- `rm -rf` with safe targets (like `rm -rf /tmp/cache/*`) can be allowed by removing specific patterns
- Database `DELETE FROM` with subqueries are flagged for review
