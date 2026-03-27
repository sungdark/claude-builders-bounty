#!/usr/bin/env bash
#
# Claude Code Pre-Tool-Use Hook: Blocks destructive bash commands
# Install to: ~/.claude/hooks/pre_tool_use.sh
#

BLOCKED_LOG="${HOME}/.claude/hooks/blocked.log"
COMMAND="$*"

block_and_exit() {
    local msg="$1"
    local project
    project=$(git rev-parse --show-toplevel 2>/dev/null || echo "$(pwd)")
    
    mkdir -p "$(dirname "$BLOCKED_LOG")"
    echo "[$(date -Iseconds)] BLOCKED in $project: $COMMAND" >> "$BLOCKED_LOG"
    
    echo "$msg" >&2
    echo "" >&2
    echo "📋 Logged to: $BLOCKED_LOG" >&2
    exit 1
}

# Only check bash commands
if [[ "$1" != "Bash" ]]; then
    exit 0
fi

# Check for destructive patterns
case "$COMMAND" in
    *'rm -rf /'*|*'rm -rf /'*|*'rm -rf .'*)
        block_and_exit "🚫 BLOCKED: 'rm -rf' — Recursive force delete is dangerous"
        ;;
esac

if echo "$COMMAND" | grep -iqP 'DROP\s+TABLE'; then
    block_and_exit "🚫 BLOCKED: 'DROP TABLE' — Drops an entire database table"
fi

if echo "$COMMAND" | grep -iqP 'TRUNCATE\s+TABLE'; then
    block_and_exit "🚫 BLOCKED: 'TRUNCATE TABLE' — Removes all rows from a table"
fi

if echo "$COMMAND" | grep -iqP 'git\s+push\s+.*-f\b'; then
    block_and_exit "🚫 BLOCKED: 'git push --force' — Overwrites remote history"
fi

if echo "$COMMAND" | grep -iqP 'git\s+push\s+.*--force\b'; then
    block_and_exit "🚫 BLOCKED: 'git push --force' — Overwrites remote history"
fi

if echo "$COMMAND" | grep -iqP 'DELETE\s+FROM\s+(?!\S*\s+WHERE)'; then
    block_and_exit "🚫 BLOCKED: 'DELETE FROM' without WHERE — Will delete ALL rows"
fi

if echo "$COMMAND" | grep -iqP '^dd\s+.*of=/dev/'; then
    block_and_exit "🚫 BLOCKED: 'dd' writing to device — Risk of full disk wipe"
fi

if echo "$COMMAND" | grep -iqP 'mkfs'; then
    block_and_exit "🚫 BLOCKED: 'mkfs' — Formats a filesystem"
fi

if echo "$COMMAND" | grep -qP '>\s*/dev/sd'; then
    block_and_exit "🚫 BLOCKED: Direct block device write"
fi

exit 0
