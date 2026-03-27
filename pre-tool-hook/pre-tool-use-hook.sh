#!/usr/bin/env python3
"""
Claude Code pre-tool-use hook: blocks destructive bash commands.
Install: cp pre-tool-use-hook.sh ~/.claude/hooks/pre-tool-use
"""
import sys
import json
import os
import re
from datetime import datetime

HOOKS_DIR = os.path.expanduser("~/.claude/hooks")
BLOCKED_LOG = os.path.join(HOOKS_DIR, "blocked.log")

# Dangerous patterns to block
DANGEROUS_PATTERNS = [
    (r'rm\s+-rf\s+', "Recursive force delete — catastrophic if wrong path"),
    (r'DROP\s+TABLE', "SQL DROP TABLE — irreversibly deletes data"),
    (r'git\s+push\s+.*--force', "Force push — rewrites remote history"),
    (r'TRUNCATE', "SQL TRUNCATE — deletes all rows without backup"),
    (r'DELETE\s+FROM\s+(?!.*WHERE)', "SQL DELETE without WHERE clause"),
    (r'DELETE\s+FROM\s+\w+\s*$', "SQL DELETE without WHERE clause"),
    (r'\|\s*rm\s+', "Pipe to rm — dangerous pattern"),
    (r'>\s*/dev/sd', "Direct block device write"),
    (r'>\s*/dev/hd', "Direct block device write"),
    (r'mkfs\.', "Filesystem format — destroys data"),
    (r'dd\s+.*of=/dev/', "Direct block device write"),
]

def is_dangerous(command: str) -> tuple:
    for pattern, reason in DANGEROUS_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            return True, reason
    return False, ""

def log_blocked(timestamp, tool, command, reason, cwd):
    os.makedirs(HOOKS_DIR, exist_ok=True)
    entry = (
        f"[{timestamp}] BLOCKED\n"
        f"  Tool: {tool}\n"
        f"  Command: {command}\n"
        f"  Reason: {reason}\n"
        f"  CWD: {cwd}\n"
        f"---\n"
    )
    try:
        with open(BLOCKED_LOG, "a") as f:
            f.write(entry)
    except Exception:
        pass

def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    tool_name = payload.get("tool", "")
    tool_input = payload.get("input", {})
    
    if tool_name == "Bash":
        command = tool_input.get("command", "")
    else:
        command = ""

    blocked, reason = is_dangerous(command)

    if blocked:
        timestamp = datetime.now().isoformat()
        cwd = os.getcwd()
        log_blocked(timestamp, tool_name, command, reason, cwd)
        
        msg = (
            f"\n🛑 HOOK: Command blocked by pre-tool-use hook\n"
            f"   Reason: {reason}\n"
            f"   Command: {command}\n"
            f"   This command was blocked. Use a safer alternative or ask the user.\n"
            f"   Logged to: {BLOCKED_LOG}\n"
        )
        print(msg, file=sys.stderr)
        sys.exit(1)
    
    sys.exit(0)

if __name__ == "__main__":
    main()
