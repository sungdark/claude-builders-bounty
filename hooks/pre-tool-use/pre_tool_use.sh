#!/usr/bin/env bash
# Claude Code Pre-Tool-Use Hook: Block Destructive Commands (Bash version)
# Install to: ~/.claude/hooks/pre_tool_use.sh
#
# Claude Code passes JSON to hooks via stdin.
# Hook must output JSON to stdout.

BLOCKED_LOG="${HOME}/.claude/hooks/blocked.log"

log_blocked() {
    local cmd="$1"
    local reason="$2"
    local project
    project=$(git rev-parse --show-toplevel 2>/dev/null || echo "$(pwd)")
    mkdir -p "$(dirname "$BLOCKED_LOG")"
    echo "[$(date -Iseconds)] BLOCKED in $project: $cmd" >> "$BLOCKED_LOG"
    echo "  Reason: $reason" >> "$BLOCKED_LOG"
}

is_blocked() {
    local cmd="$1"
    # rm -rf /
    echo "$cmd" | grep -Eq 'rm\s+-rf\s+/\S*' && { echo "rm -rf / — root deletion"; return 0; }
    # DROP TABLE
    echo "$cmd" | grep -Eiq '\bDROP\s+TABLE\b' && { echo "DROP TABLE — deletes entire table"; return 0; }
    # TRUNCATE TABLE
    echo "$cmd" | grep -Eiq '\bTRUNCATE\s+TABLE\b' && { echo "TRUNCATE TABLE — removes all rows"; return 0; }
    # git push --force
    echo "$cmd" | grep -Eq 'git\s+push\s+.*--force' && { echo "git push --force — overwrites remote history"; return 0; }
    # git push -f
    echo "$cmd" | grep -Eq 'git\s+push\s+.*\s-f' && { echo "git push -f — overwrites remote history"; return 0; }
    # DELETE FROM without WHERE
    echo "$cmd" | grep -Eiq 'DELETE\s+FROM\s+\w+\s*(;|$)' && { echo "DELETE FROM without WHERE — deletes all rows"; return 0; }
    # dd to block device
    echo "$cmd" | grep -Eq '\bdd\b.*of=/dev/' && { echo "dd writing to block device"; return 0; }
    # mkfs
    echo "$cmd" | grep -Eq '\bmkfs\b' && { echo "mkfs — formats filesystem"; return 0; }
    # direct block device write
    echo "$cmd" | grep -Eq '>\s*/dev/(sd|hd|nvme)' && { echo "direct block device write"; return 0; }
    return 1
}

main() {
    # Read stdin (Claude Code JSON payload)
    local payload
    payload=$(cat)
    local tool
    tool=$(echo "$payload" | python3 -c "import json,sys; print(json.load(sys.stdin).get('tool',''))" 2>/dev/null)
    if [[ "$tool" != "Bash" ]]; then
        echo '{"allow": true}'
        return
    fi
    local cmd
    cmd=$(echo "$payload" | python3 -c "import json,sys; print(json.load(sys.stdin).get('params',{}).get('command_line',''))" 2>/dev/null)
    local blocked_msg
    if blocked_msg=$(is_blocked "$cmd"); then
        log_blocked "$cmd" "$blocked_msg"
        echo "{\"allow\": false, \"report\": \"🚫 BLOCKED: $blocked_msg\\n📋 Logged to: $BLOCKED_LOG\"}"
    else
        echo '{"allow": true}'
    fi
}

main
