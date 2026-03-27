#!/usr/bin/env node
import { Command } from 'commander';
import { Octokit } from '@octokit/rest';
import Anthropic from '@anthropic-ai/sdk';
import * as fs from 'fs';
import * as path from 'path';
import * as dotenv from 'dotenv';

dotenv.config();

const program = new Command();

interface PRInfo {
  owner: string;
  repo: string;
  prNumber: number;
  title: string;
  body: string;
  author: string;
  additions: number;
  deletions: number;
  changedFiles: number;
  diff: string;
}

async function parsePRUrl(url: string): Promise<{ owner: string; repo: string; prNumber: number }> {
  // Handle various GitHub PR URL formats
  const patterns = [
    /github\.com\/([^\/]+)\/([^\/]+)\/pull\/(\d+)/,
    /github\.com\/([^\/]+)\/([^\/]+)\/pull\/(\d+)\//,
  ];
  
  for (const pattern of patterns) {
    const match = url.match(pattern);
    if (match) {
      return { owner: match[1], repo: match[2], prNumber: parseInt(match[3], 10) };
    }
  }
  
  throw new Error(`Invalid PR URL: ${url}`);
}

async function fetchPRInfo(octokit: Octokit, owner: string, repo: string, prNumber: number): Promise<PRInfo> {
  const { data: pr } = await octokit.rest.pulls.get({ owner, repo, pull_number: prNumber });
  const { data: files } = await octokit.rest.pulls.listFiles({ owner, repo, pull_number: prNumber });
  
  const diffResponse = await octokit.rest.pulls.get({ owner, repo, pull_number: prNumber, mediaType: { format: 'diff' } });
  const diff = (diffResponse.data as unknown as { raw: string })?.raw || '';
  
  return {
    owner,
    repo,
    prNumber,
    title: pr.title,
    body: pr.body || '',
    author: pr.user?.login || 'unknown',
    additions: pr.additions || 0,
    deletions: pr.deletions || 0,
    changedFiles: files.length,
    diff,
  };
}

function buildReviewPrompt(prInfo: PRInfo): string {
  return `You are a senior code reviewer analyzing a GitHub Pull Request.

## PR Information
- **Title**: ${prInfo.title}
- **Author**: @${prInfo.author}
- **Files Changed**: ${prInfo.changedFiles}
- **Lines**: +${prInfo.additions} / -${prInfo.deletions}
- **Body**: ${prInfo.body || '(no description)'}

## Diff
\`\`\`diff
${prInfo.diff.slice(0, 50000)}  // Limit diff size
\`\`\`

## Your Task
Analyze this PR diff and provide a structured code review. Output ONLY valid Markdown in the following format (no other text):

## 🤖 Claude Code Review

### 📋 Summary
[2-3 sentence summary of what this PR does and its purpose]

### ⚠️ Identified Risks
- [Risk 1 - be specific and actionable]
- [Risk 2 - be specific and actionable]
- [Risk 3 - or "No significant risks identified"]

### 💡 Improvement Suggestions
- [Suggestion 1 - be specific and actionable]
- [Suggestion 2 - be specific and actionable]
- [Suggestion 3 - or "Code looks clean, no major suggestions"]

### ✅ Confidence: [Low / Medium / High]

[Explain in 1 sentence why you have this confidence level]`;
}

async function generateReview(prInfo: PRInfo): Promise<string> {
  const anthropic = new Anthropic();
  
  const msg = await anthropic.messages.create({
    model: 'claude-sonnet-4-20250514',
    max_tokens: 4096,
    messages: [{
      role: 'user',
      content: buildReviewPrompt(prInfo),
    }],
  });
  
  return msg.content[0].type === 'text' ? msg.content[0].text : '';
}

async function main() {
  program
    .name('claude-review')
    .description('Claude Code PR Review Agent - analyzes PRs and returns structured review comments')
    .requiredOption('-p, --pr <url>', 'GitHub PR URL (e.g., https://github.com/owner/repo/pull/123)')
    .option('-o, --output <file>', 'Output file path (default: stdout)')
    .option('-f, --format <type>', 'Output format: markdown, json, console', 'markdown')
    .option('--gh-token <token>', 'GitHub token (or set GITHUB_TOKEN env var)')
    .option('--anthropic-key <key>', 'Anthropic API key (or set ANTHROPIC_API_KEY env var)');

  await program.parseAsync(process.argv);
  const opts = program.opts();

  const githubToken = opts.ghToken || process.env.GITHUB_TOKEN;
  const anthropicKey = opts.anthropicKey || process.env.ANTHROPIC_API_KEY;

  if (!githubToken) {
    console.error('Error: GitHub token required. Set GITHUB_TOKEN env var or use --gh-token');
    process.exit(1);
  }
  if (!anthropicKey) {
    console.error('Error: Anthropic API key required. Set ANTHROPIC_API_KEY env var or use --anthropic-key');
    process.exit(1);
  }

  process.env.ANTHROPIC_API_KEY = anthropicKey;

  const octokit = new Octokit({ auth: githubToken });
  
  try {
    const { owner, repo, prNumber } = await parsePRUrl(opts.pr);
    console.error(`Fetching PR #${prNumber} from ${owner}/${repo}...`);
    
    const prInfo = await fetchPRInfo(octokit, owner, repo, prNumber);
    console.error(`Analyzing ${prInfo.changedFiles} files (+${prInfo.additions}/-${prInfo.deletions})...`);
    
    const review = await generateReview(prInfo);
    
    if (opts.output) {
      fs.writeFileSync(opts.output, review, 'utf-8');
      console.error(`Review written to ${opts.output}`);
    } else {
      console.log(review);
    }
  } catch (error) {
    console.error('Error:', error instanceof Error ? error.message : String(error));
    process.exit(1);
  }
}

main().catch(console.error);
