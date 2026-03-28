#!/usr/bin/env python3
"""
Claude Code Pre-Tool-Use Hook: Blocks destructive bash commands.
Install to: ~/.claude/hooks/pre_tool_use.py

Claude Code passes JSON to hooks via stdin:
  {"tool": "Bash", "params": {"command_line": "ls -la"}, "context": {...}}

Hook must output JSON to stdout:
  {"allow": true}   — allow the command
  {"allow": false, "report": "reason"}  — block the command
"""

import json
import os
import re
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

# Patterns that are always dangerous, regardless of path
BLOCKED_PATTERNS = [
    (re.compile(r'rm\s+-rf\s+/\S*'),              "rm -rf / — root deletion"),
    (re.compile(r'\bDROP\s+TABLE\b', re.IGNORECASE), "DROP TABLE — deletes entire table"),
    (re.compile(r'\bTRUNCATE\s+TABLE\b', re.IGNORECASE), "TRUNCATE TABLE — removes all rows"),
    (re.compile(r'git\s+push\s+.*--force\b'),      "git push --force — overwrites remote history"),
    (re.compile(r'git\s+push\s+.*\s-f\b'),           "git push -f — overwrites remote history"),
    (re.compile(r'DELETE\s+FROM\s+\w+\s*(?:;|\s*$)', re.IGNORECASE), "DELETE FROM without WHERE — deletes all rows"),
    (re.compile(r'\bdd\b.*of=/dev/'),               "dd writing to block device"),
    (re.compile(r'\bmkfs\b'),                        "mkfs — formats a filesystem"),
    (re.compile(r'>\s*/dev/(?:sd|hd|nvme)'),        "direct block device write"),
    (re.compile(r':\s*>\s*/dev/(?:sd|hd|nvme)'),   "redirect output to block device"),
]

BLOCKED_LOG = Path.home() / ".claude" / "hooks" / "blocked.log"


def get_project_path() -> str:
    """Get the git project root for the current directory."""
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


def log_blocked(command: str, project: str, reason: str):
    """Append a blocked attempt to the blocked.log file."""
    BLOCKED_LOG.parent.mkdir(parents=True, exist_ok=True)
    timestamp = datetime.now(timezone.utc).isoformat()
    with open(BLOCKED_LOG, "a") as f:
        f.write(f"[{timestamp}] BLOCKED in {project}: {command}\n  Reason: {reason}\n")


def check_command(command: str) -> tuple[bool, str]:
    """Check if a command matches any blocked pattern. Returns (blocked, reason)."""
    for pattern, reason in BLOCKED_PATTERNS:
        if pattern.search(command):
            return True, reason
    return False, ""


def main():
    # Read Claude Code's JSON payload from stdin
    try:
        payload = json.loads(sys.stdin.read())
    except (json.JSONDecodeError, OSError):
        # If we can't read stdin, allow by default (pass through)
        print(json.dumps({"allow": True}))
        return

    tool = payload.get("tool", "")
    if tool != "Bash":
        # Only intercept Bash commands
        print(json.dumps({"allow": True}))
        return

    params = payload.get("params", {})
    command_line = params.get("command_line", "")

    blocked, reason = check_command(command_line)

    if blocked:
        project = get_project_path()
        log_blocked(command_line, project, reason)
        report = f"🚫 BLOCKED: {reason}\n📋 Logged to: {BLOCKED_LOG}"
        print(json.dumps({"allow": False, "report": report}))
    else:
        print(json.dumps({"allow": True}))


if __name__ == "__main__":
    main()
