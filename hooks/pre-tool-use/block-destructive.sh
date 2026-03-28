#!/usr/bin/env bash
#===============================================================================
# pre-tool-use hook: Block Destructive Commands
# Claude Code pre-tool-use hook that intercepts dangerous bash/SQL commands
# before they are executed.
#
# Installation (2 commands):
#   mkdir -p ~/.claude/hooks
#   curl -fsSL <RAW_URL> -o ~/.claude/hooks/block-destructive.sh && chmod +x ~/.claude/hooks/block-destructive.sh
#
# Add to ~/.claude/hooks.json:
#   { "hooks": { "pre-tool-use": [{ "name": "block-destructive", "path": "~/.claude/hooks/block-destructive.sh" }] } }
#===============================================================================

set -euo pipefail

LOG_FILE="${HOME}/.claude/hooks/blocked.log"
HOOKS_DIR="${HOME}/.claude/hooks"

#-------------------------------------------------------------------------------
# Log a blocked attempt
#-------------------------------------------------------------------------------
log_blocked() {
  local cmd="$1"
  local reason="$2"
  local project="${3:-unknown}"
  local timestamp
  timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
  echo "[${timestamp}] BLOCKED | Project: ${project} | Reason: ${reason} | Command: ${cmd}" >> "${LOG_FILE}"
}

#-------------------------------------------------------------------------------
# Block pattern match
# Returns 0 (block) if pattern found, 1 (allow) otherwise
#-------------------------------------------------------------------------------
should_block() {
  local cmd="$1"
  local reason="$2"

  # Primary dangerous patterns
  case "${cmd}" in
    # Recursive force delete — almost always catastrophic
    *'rm -rf /'*|*'rm -rf ~/'*|*'rm -rf $HOME/'*|*'rm -rf /'*|'rm -rf .'*|'rm -rf ..'*)
      reason="Recursive force delete (rm -rf) — permanently destroys data"
      return 0
      ;;

    # Direct device/formatted writes
    *'mkfs'*|*'dd if='*'of=/dev/'*|*'> /dev/'*)
      reason="Direct block device or filesystem format operation"
      return 0
      ;;

    # Database destructive SQL — no WHERE clause = wipe entire table/db
    *'DROP DATABASE'*|*'DROP SCHEMA'*|*'DROP TABLE'*|*'TRUNCATE TABLE'*|*'DELETE FROM'*)
      # Allow if has WHERE or LIMIT
      if echo "${cmd}" | grep -qiE '(DROP|TRUNCATE)' || \
         ! echo "${cmd}" | grep -qiE 'WHERE|LIMIT|ORDER BY'; then
        reason="Destructive SQL without safety clause — drops entire table/database"
        return 0
      fi
      ;;

    # Git history rewrite on remote
    *'git push --force'*|*'git push -f'*|*'git push +'*|*'git push --delete --force'*|*'git push origin --force'*)
      reason="Force-push rewrites remote history — dangerous in shared repositories"
      return 0
      ;;

    # Fork bomb — anonymous function recursion
    *':(){:|:&};:'*|*'fork(){'*|*'() { :| : & } ;'*)
      reason="Fork bomb — will crash or saturate the system"
      return 0
      ;;
  esac

  # Secondary: DELETE FROM with table but no WHERE
  if echo "${cmd}" | grep -qiE 'DELETE FROM\s+[a-zA-Z_][a-zA-Z0-9_]*\s*;?\s*$' && \
     ! echo "${cmd}" | grep -qiE 'WHERE|LIMIT'; then
    reason="DELETE FROM without WHERE clause — deletes all rows from table"
    return 0
  fi

  # Secondary: DROP TABLE/CASCADE
  if echo "${cmd}" | grep -qiE 'DROP TABLE'; then
    reason="DROP TABLE permanently removes a database table"
    return 0
  fi

  return 1
}

#-------------------------------------------------------------------------------
# Main: read hook input (tool name + tool input from Claude Code)
# Claude Code passes: <tool_name>\n<tool_input_json>
#-------------------------------------------------------------------------------
main() {
  local tool_name tool_input cmd reason project

  # Claude Code pre-tool-use hook receives input on stdin
  tool_name="$(sed -n '1p' /dev/stdin)"
  tool_input="$(sed -n '2p' /dev/stdin)"

  # Only intercept bash tool calls
  if [[ "${tool_name}" != "Bash" ]]; then
    exit 0
  fi

  # Extract the command from tool_input (it's a JSON object)
  # Handle both {"command":"..."} and {"commands":["..."]}
  cmd=""
  if echo "${tool_input}" | grep -q '"command"'; then
    cmd="$(echo "${tool_input}" | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("command",""))' 2>/dev/null || echo "")"
  elif echo "${tool_input}" | grep -q '"commands"'; then
    cmd="$(echo "${tool_input}" | python3 -c 'import sys,json; d=json.load(sys.stdin); cmds=d.get("commands",[]); print("; ".join(cmds))' 2>/dev/null || echo "")"
  fi

  # Get project path from env or default
  project="${CLAUDE_PROJECT_PATH:-${PWD:-unknown}}"

  # Normalize: expand aliases and take first line of multi-command
  cmd="$(echo "${cmd}" | head -n1)"

  if [[ -z "${cmd}" ]]; then
    exit 0
  fi

  # Check if this command should be blocked
  if should_block "${cmd}" ""; then
    reason="Destructive command blocked by pre-tool-use hook"

    # Log it
    mkdir -p "$(dirname "${LOG_FILE}")" 2>/dev/null || true
    log_blocked "${cmd}" "${reason}" "${project}"

    # Print reason for Claude Code to display
    echo "⛔ HOOK BLOCKED: ${cmd}" >&2
    echo "" >&2
    echo "This command was blocked by your pre-tool-use safety hook." >&2
    echo "Reason: ${reason}" >&2
    echo "" >&2
    echo "If you need to proceed, consider:" >&2
    echo "  1. Using a safer variant (e.g., 'rm -i' instead of 'rm -rf')" >&2
    echo "  2. Adding a WHERE clause to SQL commands" >&2
    echo "  3. Using 'git push' without --force" >&2
    echo "" >&2
    echo "Log entry saved to: ${LOG_FILE}" >&2

    # Exit with non-zero to block the tool
    exit 1
  fi

  exit 0
}

main "$@"
