#!/usr/bin/env python3
"""Test script to verify pre-tool-hook.py blocks the right commands."""

import json
import subprocess
import sys
import os

# Add the script path
SCRIPT = os.path.join(os.path.dirname(__file__), "pre-tool-hook.py")

def run_test(command: str, expect_block: bool) -> bool:
    """Run the hook with a given command and check if it was blocked correctly."""
    payload = json.dumps({
        "tool_name": "Bash",
        "tool_args": {"command": command},
        "project": "/test/project"
    })
    result = subprocess.run(
        [sys.executable, SCRIPT],
        input=payload.encode(),
        capture_output=True
    )
    try:
        response = json.loads(result.stdout.decode())
        allowed = response.get("allow", True)
        if expect_block and not allowed:
            print(f"  ✅ Correctly blocked: {command[:50]}")
            return True
        elif not expect_block and allowed:
            print(f"  ✅ Correctly allowed: {command[:50]}")
            return True
        else:
            print(f"  ❌ Unexpected: {command[:50]} (expected {'block' if expect_block else 'allow'})")
            return False
    except json.JSONDecodeError:
        print(f"  ❌ Invalid JSON output for: {command[:50]}")
        return False

print("Testing pre-tool-hook.py...")
print()

tests = [
    # (command, expect_block)
    ("echo hello", False),
    ("ls -la", False),
    ("git status", False),
    ("git commit -m 'fix bug'", False),
    ("rm -rf /tmp/test", True),
    ("rm -rf /var/log/*", True),
    ("DROP TABLE users", True),
    ("DROP DATABASE production", True),
    ("git push --force origin main", True),
    ("git push -f", True),
    ("TRUNCATE TABLE sessions", True),
    ("DELETE FROM users", True),
    ("DELETE FROM logs WHERE 1=1", True),
    ("mkfs.ext4 /dev/sda1", True),
    ("dd if=/dev/zero of=/dev/sdb", True),
    ("python script.py --flag", False),
    ("npm install", False),
]

passed = sum(run_test(cmd, expect) for cmd, expect in tests)
print()
print(f"Results: {passed}/{len(tests)} tests passed")
sys.exit(0 if passed == len(tests) else 1)
