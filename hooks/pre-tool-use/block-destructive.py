#!/usr/bin/env python3
"""
Pre-tool-use hook: Block Destructive Commands
Claude Code pre-tool-use hook that intercepts dangerous bash/SQL commands.

Installation:
    curl -fsSL <RAW_URL> -o ~/.claude/hooks/block-destructive.py
    chmod +x ~/.claude/hooks/block-destructive.py

Add to ~/.claude/hooks.json:
    { "hooks": { "pre-tool-use": [{ "name": "block-destructive", "path": "~/.claude/hooks/block-destructive.py" }] } }
"""

import sys
import os
import re
import json
import datetime
from pathlib import Path

LOG_FILE = Path.home() / ".claude" / "hooks" / "blocked.log"

# Compiled regex patterns for speed
PATTERNS = [
    # Recursive rm -rf on dangerous paths
    (re.compile(r'rm\s+(-[rf]+\s+)*(/|~\/|/home|/root|\$HOME|\.)'), 
     "Recursive force delete — permanently destroys data"),
    
    # SQL DROP/DELETE/TRUNCATE
    (re.compile(r'\bDROP\s+DATABASE\b', re.IGNORECASE), 
     "DROP DATABASE permanently removes an entire database"),
    (re.compile(r'\bDROP\s+SCHEMA\b', re.IGNORECASE), 
     "DROP SCHEMA permanently removes a schema"),
    (re.compile(r'\bDROP\s+TABLE\b', re.IGNORECASE), 
     "DROP TABLE permanently removes a database table"),
    (re.compile(r'\bTRUNCATE\s+TABLE\b', re.IGNORECASE), 
     "TRUNCATE TABLE deletes all rows from a table"),
    (re.compile(r'\bDELETE\s+FROM\s+[a-zA-Z_][a-zA-Z0-9_]*\s*;?\s*$'), 
     "DELETE without WHERE — deletes all rows from table"),
    
    # Git force push
    (re.compile(r'git\s+push\s+(-f|--force)(\s+|$)', re.IGNORECASE), 
     "Force-push rewrites remote history — dangerous in shared repos"),
    (re.compile(r'git\s+push\s+\+[a-f0-9]+\.\.\.', re.IGNORECASE), 
     "Force-push rewrites remote history"),
    
    # Fork bomb
    (re.compile(r'\(\)\s*:\s*\{\s*:\s*\|\s*:\s*&\s*\}\s*;'), 
     "Fork bomb — will crash or saturate the system"),
    (re.compile(r':\(\)\s*\{\s*\|\s*&\s*\}\s*;'), 
     "Fork bomb variant"),
    
    # Dangerous device writes
    (re.compile(r'mkfs\.'), 
     "mkfs formats a block device — destructive"),
    (re.compile(r'dd\s+.*of=/dev/'), 
     "Direct block device write — can destroy disks"),
]


def log_blocked(cmd: str, reason: str, project: str) -> None:
    """Append a blocked attempt to the audit log."""
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    LOG_FILE.parent.mkdir(parents=True, exist_ok=True)
    with LOG_FILE.open("a") as f:
        f.write(f"[{timestamp}] BLOCKED | Project: {project} | Reason: {reason} | Command: {cmd}\n")


def extract_bash_command(tool_input: str) -> str:
    """Extract the bash command string from Claude Code tool input JSON."""
    try:
        data = json.loads(tool_input)
        if "command" in data:
            cmd = data["command"]
            if isinstance(cmd, list):
                return "; ".join(str(c) for c in cmd)
            return str(cmd)
        if "commands" in data:
            cmds = data["commands"]
            return "; ".join(str(c) for c in cmds)
    except (json.JSONDecodeError, TypeError):
        pass
    return ""


def should_block(cmd: str) -> tuple[bool, str]:
    """Check if a command matches any blocked pattern. Returns (blocked, reason)."""
    for pattern, reason in PATTERNS:
        if pattern.search(cmd):
            return True, reason
    return False, ""


def main():
    # Claude Code pre-tool-use hook: line 1 = tool name, line 2 = tool input JSON
    lines = sys.stdin.read().splitlines()
    if len(lines) < 2:
        sys.exit(0)  # Allow if we can't parse

    tool_name = lines[0].strip()
    tool_input = "\n".join(lines[1:])

    # Only intercept Bash tool calls
    if tool_name != "Bash":
        sys.exit(0)

    cmd = extract_bash_command(tool_input)
    if not cmd:
        sys.exit(0)

    # Take first line only for safety
    cmd = cmd.splitlines()[0]
    project = os.environ.get("CLAUDE_PROJECT_PATH", os.getcwd())

    blocked, reason = should_block(cmd)
    if blocked:
        log_blocked(cmd, reason, project)

        sys.stderr.write(f"⛔ HOOK BLOCKED: {cmd}\n\n")
        sys.stderr.write(f"This command was blocked by your pre-tool-use safety hook.\n")
        sys.stderr.write(f"Reason: {reason}\n\n")
        sys.stderr.write("If you need to proceed, consider:\n")
        sys.stderr.write("  1. Using a safer variant (e.g., 'rm -i' instead of 'rm -rf')\n")
        sys.stderr.write("  2. Adding a WHERE clause to SQL commands\n")
        sys.stderr.write("  3. Using 'git push' without --force\n\n")
        sys.stderr.write(f"Log entry saved to: {LOG_FILE}\n")

        sys.exit(1)  # Block the tool

    sys.exit(0)  # Allow


if __name__ == "__main__":
    main()
