# Claude Code Bounty Solutions

Solutions submitted for the [claude-builders-bounty](https://github.com/claude-builders-bounty/claude-builders-bounty) bounty board.

## Bounties Claimed

| # | Bounty | Amount | Status |
|---|--------|--------|--------|
| 1 | SKILL: Generate CHANGELOG from git history | $50 | ✅ Submitted |
| 3 | HOOK: Block destructive bash commands | $100 | ✅ Submitted |
| 4 | AGENT: PR reviewer with structured output | $150 | ✅ Submitted |

## Skills

### 1. CHANGELOG Generator — `$50`
**Path:** `skills/changelog/`

Generates a structured CHANGELOG.md from git commit history since the last tag.

```bash
./scripts/changelog.sh
```

Features:
- Auto-categorizes: Added / Fixed / Changed / Removed
- Works with git tags
- 3-step setup

### 3. Safe Hook — `$100`
**Path:** `skills/safe-hook/`

Pre-tool-use hook that blocks destructive bash commands.

```bash
# Install
mkdir -p ~/.claude/hooks
cp pre-tool-use ~/.claude/hooks/
chmod +x ~/.claude/hooks/pre-tool-use
```

Blocks: `rm -rf`, `DROP TABLE`, `TRUNCATE`, `git push --force`, `DELETE FROM` without WHERE, and more.

### 4. PR Reviewer Agent — `$150`
**Path:** `skills/pr-reviewer/`

Structured PR review via CLI or GitHub Action.

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
./scripts/claude-review --pr https://github.com/owner/repo/pull/123
```

Output includes: Summary, Risks, Suggestions, Security Notes, Confidence Score.

## Payment Address
BTC (Lightning compatible): `eB51DWp1uECrLZRLsE2cnyZUzfRWvzUzaJzkatTpQV9`
