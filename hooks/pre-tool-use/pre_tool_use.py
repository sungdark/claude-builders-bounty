#!/usr/bin/env python3
"""
Claude Code Pre-Tool-Use Hook: Blocks destructive bash commands
Install to: ~/.claude/hooks/pre_tool_use.py

Usage in settings.json:
{
  "hooks": {
    "pre_tool_use": "python3 ~/.claude/hooks/pre_tool_use.py"
  }
}

Blocks: rm -rf, DROP TABLE, TRUNCATE, git push --force, DELETE without WHERE
Logs all blocked attempts to ~/.claude/hooks/blocked.log
"""

import os
import re
import subprocess
import sys
from datetime import datetime
from pathlib import Path

BLOCKED_PATTERNS = [
    (r'rm\s+-rf\s+/(?:\S*)', "rm -rf / (root deletion)"),
    (r'\bDROP\s+TABLE\b', "DROP TABLE (deletes entire table)"),
    (r'\bTRUNCATE\s+TABLE\b', "TRUNCATE TABLE (removes all rows)"),
    (r'git\s+push\s+.*--force\b', "git push --force (overwrites remote history)"),
    (r'git\s+push\s+.*-f\b', "git push -f (overwrites remote history)"),
    (r'DELETE\s+FROM\s+\w+\s*(?:;|\s*$)', "DELETE FROM without WHERE clause"),
    (r'\bdd\b.*of=/dev/', "dd writing to block device"),
    (r'\bmkfs\b', "mkfs (formats filesystem)"),
    (r'>\s*/dev/(?:sd|hd|nvme)', "direct block device write"),
]

BLOCKED_LOG = Path.home() / ".claude" / "hooks" / "blocked.log"


def get_project_path() -> str:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, timeout=5
        )
        if result.returncode == 0:
            return result.stdout.strip()
    except Exception:
        pass
    return os.getcwd()


def log_blocked(command: str, project: str):
    BLOCKED_LOG.parent.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now().isoformat()
    with open(BLOCKED_LOG, "a") as f:
        f.write(f"[{timestamp}] BLOCKED in {project}: {command}\n")


def check_command(command: str) -> tuple[bool, str]:
    for pattern, name in BLOCKED_PATTERNS:
        if re.search(pattern, command, re.IGNORECASE):
            msg = f"🚫 BLOCKED: {name}"
            return True, msg
    return False, ""


def main():
    # argv[0] = script path
    # argv[1] = tool name (e.g., "Bash")
    # argv[2:] = tool arguments (for Bash, argv[2] is the command string)
    if len(sys.argv) < 2:
        sys.exit(0)

    tool = sys.argv[1]
    if tool != "Bash":
        sys.exit(0)

    # The full command string is in argv[2] for Bash tool
    command = sys.argv[2] if len(sys.argv) > 2 else ""

    blocked, msg = check_command(command)

    if blocked:
        project = get_project_path()
        log_blocked(command, project)
        print(msg, file=sys.stderr)
        print(f"📋 Logged to: {BLOCKED_LOG}", file=sys.stderr)
        sys.exit(1)  # non-zero = block

    sys.exit(0)  # zero = allow


if __name__ == "__main__":
    main()
