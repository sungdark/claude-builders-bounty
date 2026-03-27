#!/usr/bin/env python3
"""
Claude PR Reviewer — CLI tool that analyzes PR diffs and returns structured review comments.
Usage: claude-review --pr <PR_URL>
"""

import argparse
import json
import os
import re
import sys
import urllib.request
import urllib.error
from urllib.parse import urlparse

ANTHROPIC_API_URL = "https://api.anthropic.com/v1/messages"
CLAUDE_MODEL = "claude-sonnet-4-20250514"

def get_api_key():
    key = os.environ.get("ANTHROPIC_API_KEY") or os.environ.get("CLAUDE_API_KEY")
    if not key:
        print("Error: Set ANTHROPIC_API_KEY or CLAUDE_API_KEY environment variable.", file=sys.stderr)
        sys.exit(1)
    return key

def parse_pr_url(url):
    """Extract owner, repo, PR number from GitHub PR URL."""
    parsed = urlparse(url)
    parts = [p for p in parsed.path.strip("/").split("/") if p]
    if len(parts) < 4 or parts[2] != "pull":
        raise ValueError(f"Invalid PR URL: {url}")
    return parts[0], parts[1], int(parts[3])

def get_pr_details(owner, repo, pr_num, token):
    """Fetch PR details and diff from GitHub API."""
    headers = {
        "Authorization": f"token {token}",
        "Accept": "application/vnd.github.v3.diff"
    }
    url = f"https://api.github.com/repos/{owner}/{repo}/pulls/{pr_num}"
    req = urllib.request.Request(url, headers=headers)
    try:
        with urllib.request.urlopen(req) as resp:
            diff = resp.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        print(f"GitHub API error: {e.code} {e.reason}", file=sys.stderr)
        sys.exit(1)
    
    # Get PR metadata
    meta_url = f"https://api.github.com/repos/{owner}/{repo}/pulls/{pr_num}"
    meta_req = urllib.request.Request(meta_url, headers={**headers, "Accept": "application/vnd.github.v3+json"})
    with urllib.request.urlopen(meta_req) as resp:
        meta = json.loads(resp.read().decode("utf-8"))
    
    return diff, meta

def call_claude(diff, pr_title, pr_body, api_key):
    """Send diff to Claude and get structured review."""
    system_prompt = """You are an expert code reviewer. Analyze the PR diff and return a structured Markdown review.
Your output MUST follow this exact format:

## Summary
[2-3 sentence summary of what this PR does]

## Identified Risks
- [risk 1]
- [risk 2]
- ...

## Improvement Suggestions
- [suggestion 1]
- [suggestion 2]
- ...

## Confidence Score
Low | Medium | High

Be concise and specific. Focus on substantive issues only."""

    body = {
        "model": CLAUDE_MODEL,
        "max_tokens": 1024,
        "system": system_prompt,
        "messages": [{
            "role": "user",
            "content": f"PR Title: {pr_title}\n\nPR Body:\n{pr_body or '(none)'}\n\n---DIFF---\n{diff[:15000]}"
        }]
    }
    
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(
        ANTHROPIC_API_URL,
        data=data,
        headers={
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01",
            "Content-Type": "application/json"
        },
        method="POST"
    )
    
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            result = json.loads(resp.read().decode("utf-8"))
            return result["content"][0]["text"]
    except urllib.error.HTTPError as e:
        body_err = e.read().decode("utf-8")
        print(f"Anthropic API error: {e.code} {e.reason}\n{body_err}", file=sys.stderr)
        sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description="Claude PR Reviewer — structured Markdown reviews for GitHub PRs")
    parser.add_argument("--pr", required=True, help="GitHub PR URL (e.g., https://github.com/owner/repo/pull/123)")
    args = parser.parse_args()
    
    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN", "")
    if not token:
        print("Error: Set GITHUB_TOKEN or GH_TOKEN environment variable.", file=sys.stderr)
        sys.exit(1)
    
    owner, repo, pr_num = parse_pr_url(args.pr)
    print(f"Fetching PR #{pr_num} from {owner}/{repo}...", file=sys.stderr)
    
    diff, meta = get_pr_details(owner, repo, pr_num, token)
    pr_title = meta.get("title", "")
    pr_body = meta.get("body", "")
    
    print(f"Analyzing diff ({len(diff)} bytes)...", file=sys.stderr)
    api_key = get_api_key()
    review = call_claude(diff, pr_title, pr_body, api_key)
    
    print("\n" + review)

if __name__ == "__main__":
    main()
