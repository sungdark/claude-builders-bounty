#!/usr/bin/env python3
"""
pre-tool-hook.py — Claude Code pre-tool-use hook that blocks destructive commands.
Blocks: rm -rf, DROP TABLE, git push --force, TRUNCATE, DELETE without WHERE, etc.
Logs all blocked attempts to ~/.claude/hooks/blocked.log with timestamp + project.
"""

import sys
import json
import os
import re
from datetime import datetime, timezone

LOG_FILE = os.path.expanduser("~/.claude/hooks/blocked.log")

DANGEROUS_PATTERNS = [
    (r'rm\s+-rf\s+[/a-zA-Z0-9_\-\.]+', "Recursive forced deletion"),
    (r'rm\s+-[rf]+\s+/\s', "Deletion at root level"),
    (r'DROP\s+TABLE', "SQL DROP TABLE statement"),
    (r'DROP\s+DATABASE', "SQL DROP DATABASE statement"),
    (r'git\s+push\s+--force', "Forced git push"),
    (r'git\s+push\s+-f', "Forced git push (-f flag)"),
    (r'TRUNCATE\s+TABLE', "SQL TRUNCATE TABLE statement"),
    (r'DELETE\s+FROM\s+\w+\s*;?\s*$', "SQL DELETE without WHERE clause"),
    (r'DELETE\s+FROM\s+\w+\s+WHERE\s+1\s*=\s*1', "SQL DELETE with always-true WHERE"),
    (r';\s*rm\s+', "Command injection via rm"),
    (r'eval\s+\$', "Eval of shell variable — potential injection"),
    (r'>\s*/dev/sd', "Direct write to block device"),
    (r'mkfs\.', "Filesystem format command"),
    (r'dd\s+if=.*of=/dev/', "Direct dd to block device"),
]


def log_blocked(tool_name: str, command: str, reason: str, project: str):
    """Append blocked attempt to ~/.claude/hooks/blocked.log."""
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    with open(LOG_FILE, "a") as f:
        f.write(
            f"[{timestamp}] BLOCKED | tool={tool_name} | "
            f"project={project} | reason={reason} | command={command}\n"
        )


def check_command(command: str):
    """Check if command matches any dangerous pattern. Returns (blocked, reason)."""
    if not command:
        return False, ""
    for pattern, description in DANGEROUS_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            return True, description
    return False, ""


def build_block_response(tool_name: str, reason: str) -> str:
    return json.dumps({
        "allow": False,
        "reason": reason,
        "message": (
            f"⛔ Tool '{tool_name}' was blocked by pre-tool-use hook.\n"
            f"Reason: {reason}\n\n"
            f"This incident has been logged to: {LOG_FILE}\n\n"
            f"If you need to proceed, consider:\n"
            f"  1. Using safer alternatives (e.g., 'rm -i' instead of 'rm -rf')\n"
            f"  2. Breaking the operation into smaller, safer steps\n"
            f"  3. Consulting your team before bypassing this safeguard"
        ),
    })


def main():
    try:
        data = json.load(sys.stdin)
    except (json.JSONDecodeError, EOFError):
        print(json.dumps({"allow": True}))
        return

    tool_name = data.get("tool_name", "")
    tool_args = data.get("tool_args", {})
    project = data.get("project", os.getcwd())

    # Only intercept Bash tool
    if tool_name != "Bash":
        print(json.dumps({"allow": True}))
        return

    command = tool_args.get("command", "") or tool_args.get("description", "")
    is_blocked, reason = check_command(command)

    if is_blocked:
        log_blocked(tool_name, command, reason, project)
        print(build_block_response(tool_name, reason))
    else:
        print(json.dumps({"allow": True}))


if __name__ == "__main__":
    main()
