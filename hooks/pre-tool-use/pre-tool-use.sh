#!/bin/bash
# Claude Code Pre-Tool-Use Safety Hook
# Intercepts dangerous commands before execution
# Part of: https://github.com/claude-builders-bounty/claude-builders-bounty

set -uo pipefail

# Configuration
LOG_FILE="${HOME}/.claude/hooks/blocked.log"
HOOK_DEBUG="${HOOK_DEBUG:-0}"

# Enable debug mode
debug() {
    if [[ "$HOOK_DEBUG" == "1" ]]; then
        echo "[DEBUG] $*" >&2
    fi
}

# Log blocked command
log_blocked() {
    local cmd="$1"
    local reason="$2"
    local project="${PWD:-unknown}"
    local user="${USER:-$(whoami 2>/dev/null || echo 'unknown')}"
    local timestamp="$(date -u +'%Y-%m-%d %H:%M:%S UTC')"
    
    mkdir -p "$(dirname "$LOG_FILE")"
    touch "$LOG_FILE" 2>/dev/null || true
    
    {
        echo "[$timestamp] BLOCKED: $cmd"
        echo "  User: $user"
        echo "  Project: $project"
        echo "  Reason: $reason"
        echo "  Tool: bash"
        echo ""
    } >> "$LOG_FILE"
}

# Print warning to Claude
print_warning() {
    local cmd="$1"
    local reason="$2"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "🛑 DANGEROUS COMMAND BLOCKED" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
    echo "" >&2
    echo "Command: $cmd" >&2
    echo "Reason: $reason" >&2
    echo "" >&2
    echo "If you need to run this command:" >&2
    echo "  1. Remove the safety hook temporarily:" >&2
    echo "     rm ~/.claude/hooks/pre-tool-use.sh" >&2
    echo "  2. Run your command" >&2
    echo "  3. Re-enable: ln -s /path/to/pre-tool-use.sh ~/.claude/hooks/" >&2
    echo "" >&2
    echo "This incident has been logged to:" >&2
    echo "  $LOG_FILE" >&2
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >&2
}

# Check if command is dangerous
check_dangerous() {
    local cmd="$1"
    local reason=""
    
    # Normalize command (lowercase, remove extra spaces)
    local normalized_cmd=$(echo "$cmd" | tr -s ' ' | tr '[:upper:]' '[:lower:]')
    
    debug "Checking command: $cmd"
    
    # Check: rm -rf on root or home directories
    if [[ "$cmd" =~ rm[[:space:]]+-rf[[:space:]]+[/~$] ]]; then
        reason="rm -rf on system root or home directory"
        echo "BLOCKED:$reason"
        return 0
    fi
    
    # Check: rm -rf on large scope paths
    if [[ "$cmd" =~ rm[[:space:]]+-rf[[:space:]]+\.(github|node_modules|__pycache__|vendor|bundle) ]]; then
        reason="rm -rf removing large dependency directory"
        echo "BLOCKED:$reason"
        return 0
    fi
    
    # Check: git push --force
    if [[ "$normalized_cmd" =~ git[[:space:]]+push[[:space:]]+.*--force ]]; then
        reason="git push --force overwrites remote history irreversibly"
        echo "BLOCKED:$reason"
        return 0
    fi
    
    # Check: DROP TABLE without backup confirmation
    if [[ "$normalized_cmd" =~ drop[[:space:]]+table ]]; then
        reason="DROP TABLE permanently removes database table"
        echo "BLOCKED:$reason"
        return 0
    fi
    
    # Check: DROP DATABASE
    if [[ "$normalized_cmd" =~ drop[[:space:]]+database ]]; then
        reason="DROP DATABASE permanently removes entire database"
        echo "BLOCKED:$reason"
        return 0
    fi
    
    # Check: TRUNCATE
    if [[ "$normalized_cmd" =~ truncate[[:space:]] ]]; then
        reason="TRUNCATE empties table without individual row deletion logging"
        echo "BLOCKED:$reason"
        return 0
    fi
    
    # Check: DELETE FROM without WHERE clause
    if [[ "$normalized_cmd" =~ delete[[:space:]]+from[[:space:]] ]] && [[ ! "$normalized_cmd" =~ where ]]; then
        reason="DELETE FROM without WHERE clause deletes ALL rows"
        echo "BLOCKED:$reason"
        return 0
    fi
    
    # Check: Fork bomb
    if [[ "$normalized_cmd" =~ :\(\)\{:\|:&在地\};:\$ ]]; then
        reason="Fork bomb - will crash the system"
        echo "BLOCKED:$reason"
        return 0
    fi
    
    # Check: Shred (secure delete - makes recovery impossible)
    if [[ "$normalized_cmd" =~ shred[[:space:]] ]]; then
        reason="shred securely deletes files making recovery impossible"
        echo "BLOCKED:$reason"
        return 0
    fi
    
    # Check: dd with dangerous targets
    if [[ "$normalized_cmd" =~ dd[[:space:]]+.*of=/dev/(sd|hd|nvme) ]] || [[ "$normalized_cmd" =~ dd[[:space:]]+.*of=/dev/zero ]] && [[ "$normalized_cmd" =~ of=/dev/sd ]]; then
        reason="dd to raw disk device - high risk of data loss"
        echo "BLOCKED:$reason"
        return 0
    fi
    
    # Check: > /dev/sdX style redirects
    if [[ "$cmd" =~ >[[:space:]]*/dev/(sd|hd|nvme|fd) ]] || [[ "$cmd" =~ 1>[[:space:]]*/dev/(sd|hd|nvme|fd) ]] || [[ "$cmd" =~ 2>[[:space:]]*/dev/(sd|hd|nvme|fd) ]]; then
        reason="Direct write to raw device - extreme data loss risk"
        echo "BLOCKED:$reason"
        return 0
    fi
    
    # Check: mkfs (format disk)
    if [[ "$normalized_cmd" =~ mkfs ]]; then
        reason="mkfs formats and destroys all data on a filesystem"
        echo "BLOCKED:$reason"
        return 0
    fi
    
    # Command is safe
    echo "SAFE"
    return 1
}

# Main hook logic
main() {
    # Get the command from Claude (passed as argument or via stdin)
    local cmd="${1:-$(cat /dev/stdin 2>/dev/null | tr -d '\n')}"
    
    if [[ -z "$cmd" ]]; then
        debug "No command provided, allowing through"
        exit 0
    fi
    
    debug "Hook received command: $cmd"
    
    # Check for dangerous commands
    local result
    result=$(check_dangerous "$cmd")
    
    if [[ "$result" == SAFE ]]; then
        debug "Command is safe, allowing through"
        exit 0
    fi
    
    # Extract reason (everything after "BLOCKED:")
    local reason="${result#BLOCKED:}"
    
    # Log the blocked attempt
    log_blocked "$cmd" "$reason"
    
    # Print warning
    print_warning "$cmd" "$reason"
    
    # Block the command by exiting with error
    exit 1
}

# Run
main "$@"
