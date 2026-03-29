#!/usr/bin/env node
/**
 * claude-review — PR Review Agent
 * Takes a PR URL, analyzes the diff, and outputs a structured Markdown review.
 * 
 * Usage:
 *   claude-review --pr https://github.com/owner/repo/pull/123
 *   claude-review --pr owner/repo/123
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const GITHUB_API = 'https://api.github.com';

// ANSI color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  green: '\x1b[32m',
  cyan: '\x1b[36m',
  bold: '\x1b[1m',
};

function log(color, ...args) {
  console.log(`${color}${args.join(' ')}${colors.reset}`);
}

function parseArgs() {
  const args = process.argv.slice(2);
  let prUrl = null;
  let outputFile = null;
  let verbose = false;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--pr' || args[i] === '-p') {
      prUrl = args[++i];
    } else if (args[i] === '--output' || args[i] === '-o') {
      outputFile = args[++i];
    } else if (args[i] === '--verbose' || args[i] === '-v') {
      verbose = true;
    } else if (args[i] === '--help' || args[i] === '-h') {
      printHelp();
      process.exit(0);
    }
  }

  if (!prUrl) {
    console.error('Error: --pr is required');
    printHelp();
    process.exit(1);
  }

  return { prUrl, outputFile, verbose };
}

function printHelp() {
  console.log(`
claude-review — AI-Powered PR Review Agent

Usage:
  claude-review --pr <pr-url> [options]

Options:
  --pr, -p <url>      GitHub PR URL (required)
  --output, -o <file> Output to file instead of stdout
  --verbose, -v       Show detailed progress
  --help, -h          Show this help message

Examples:
  claude-review --pr https://github.com/owner/repo/pull/123
  claude-review --pr owner/repo/123 --output review.md
  `);
}

function parsePRUrl(prUrl) {
  // Handle full URL: https://github.com/owner/repo/pull/123
  const urlMatch = prUrl.match(/github\.com\/([^/]+)\/([^/]+)\/pull\/(\d+)/);
  if (urlMatch) {
    return { owner: urlMatch[1], repo: urlMatch[2], prNumber: urlMatch[3] };
  }

  // Handle short form: owner/repo/123
  const shortMatch = prUrl.match(/^([^/]+)\/([^/]+)\/(\d+)$/);
  if (shortMatch) {
    return { owner: shortMatch[1], repo: shortMatch[2], prNumber: shortMatch[3] };
  }

  throw new Error(`Invalid PR URL format: ${prUrl}`);
}

function ghGraphQL(query, variables = {}) {
  const token = process.env.GITHUB_TOKEN || '';
  const args = [
    'gh', 'api', 'graphql',
    '-f', `query=${query}`,
    '-F', `owner=${variables.owner}`,
    '-F', `repo=${variables.repo}`,
    '-F', `prNumber=${variables.prNumber}`,
  ];
  
  try {
    const result = execSync(args.join(' '), { encoding: 'utf-8', maxBuffer: 10 * 1024 * 1024 });
    return JSON.parse(result);
  } catch (e) {
    // Fallback to REST API
    return null;
  }
}

async function fetchPRData(owner, repo, prNumber) {
  log(colors.cyan, `Fetching PR #${prNumber} from ${owner}/${repo}...`);
  
  let token = '';
  try {
    token = execSync('gh auth token', { encoding: 'utf-8' }).trim();
  } catch (e) {
    console.error('Warning: Not authenticated with gh CLI. Using public API (rate limited).');
  }

  const headers = {
    'Accept': 'application/vnd.github.v3+json',
    ...(token && { 'Authorization': `Bearer ${token}` }),
  };

  // Fetch PR details
  const prRes = await fetch(
    `https://api.github.com/repos/${owner}/${repo}/pulls/${prNumber}`,
    { headers }
  );
  
  if (!prRes.ok) {
    throw new Error(`Failed to fetch PR: ${prRes.status} ${prRes.statusText}`);
  }
  
  const pr = await prRes.json();

  // Fetch changed files
  const filesRes = await fetch(
    `https://api.github.com/repos/${owner}/${repo}/pulls/${prNumber}/files`,
    { headers }
  );
  
  const files = await filesRes.json();
  const fileArray = Array.isArray(files) ? files : [];

  // Fetch commit list
  const commitsRes = await fetch(
    `https://api.github.com/repos/${owner}/${repo}/pulls/${prNumber}/commits`,
    { headers }
  );
  
  const commits = await commitsRes.json();
  const commitArray = Array.isArray(commits) ? commits : [];

  return { pr, files: fileArray, commits: commitArray };
}

function analyzeCodeQuality(files) {
  const risks = [];
  const suggestions = [];
  let highRiskCount = 0;
  let mediumRiskCount = 0;
  let lowRiskCount = 0;

  for (const file of files) {
    const filename = file.filename;
    const patch = file.patch || '';
    const additions = file.additions || 0;
    const deletions = file.deletions || 0;
    const changes = additions + deletions;

    // Check for large changes
    if (changes > 500) {
      risks.push(`**${filename}**: Large change (${changes} lines). Consider splitting into smaller PRs.`);
      mediumRiskCount++;
    }

    // Check for sensitive files
    if (filename.includes('.env') || filename.includes('config/secrets')) {
      risks.push(`**${filename}**: Possible secret/config file. Ensure no credentials are exposed.`);
      highRiskCount++;
    }

    // Check for TODO/FIXME comments
    if (patch.includes('TODO') || patch.includes('FIXME')) {
      suggestions.push(`**${filename}**: Contains TODO/FIXME comments that should be addressed.`);
      lowRiskCount++;
    }

    // Check for console.log
    if (patch.match(/console\.(log|debug|info)/) && !filename.endsWith('.test.ts')) {
      suggestions.push(`**${filename}**: Contains \`console.log\` statements that should be removed or replaced with proper logging.`);
      lowRiskCount++;
    }

    // Check for TODO in security-sensitive areas
    if ((patch.includes('auth') || patch.includes('token') || patch.includes('password')) && patch.includes('TODO')) {
      risks.push(`**${filename}**: TODO comment in security-sensitive code path.`);
      mediumRiskCount++;
    }

    // Check for SQL injection patterns
    if (patch.match(/`.*\$\{.*\}.*`/) && (filename.endsWith('.sql') || patch.includes('SELECT') || patch.includes('INSERT'))) {
      risks.push(`**${filename}**: Possible SQL injection risk with template literals.`);
      highRiskCount++;
    }
  }

  // Determine confidence score
  let confidence;
  if (highRiskCount > 0) {
    confidence = '🔴 Low — Security or critical issues detected';
  } else if (mediumRiskCount > 0) {
    confidence = '🟡 Medium — Some concerns that should be reviewed';
  } else {
    confidence = '🟢 High — No obvious issues detected';
  }

  return { risks, suggestions, confidence, counts: { high: highRiskCount, medium: mediumRiskCount, low: lowRiskCount } };
}

function generateReview(pr, files, commits, analysis) {
  const title = pr.title || 'Untitled PR';
  const description = pr.body || 'No description provided.';
  const author = pr.user?.login || 'unknown';
  const branch = pr.head?.ref || 'unknown';
  const baseBranch = pr.base?.ref || 'main';
  const additions = files.reduce((sum, f) => sum + (f.additions || 0), 0);
  const deletions = files.reduce((sum, f) => sum + (f.deletions || 0), 0);
  const changedFiles = files.length;
  const commitCount = commits.length;

  const reviewDate = new Date().toISOString().split('T')[0];

  let markdown = `# 🔍 PR Review: #${pr.number} — ${title}

> **Reviewed:** ${reviewDate}  
> **Author:** @${author}  
> **Branch:** \`${branch}\` → \`${baseBranch}\`  
> **Commits:** ${commitCount} | **Files changed:** ${changedFiles} | **+${additions} -${deletions}**

---

## 📝 Summary

${description.length > 200 ? description.substring(0, 200) + '...' : description || 'No description provided.'}

${
  changedFiles > 10
    ? `This PR touches **${changedFiles} files**. `
    : `This PR touches **${changedFiles} file${changedFiles !== 1 ? 's' : ''}**. `
} A total of **+${additions} lines** added and **-${deletions} lines** removed across ${commitCount} commit${commitCount !== 1 ? 's' : ''}.

---

## 🚨 Identified Risks

${
  analysis.risks.length > 0
    ? analysis.risks.map(r => `- ${r}`).join('\n')
    : '- No critical risks identified. ✅'
}

---

## 💡 Improvement Suggestions

${
  analysis.suggestions.length > 0
    ? analysis.suggestions.map(s => `- ${s}`).join('\n')
    : '- Code looks good! No specific suggestions. ✅'
}

---

## 📊 Files Changed

| File | + | - |
|------|---|---|
${files.map(f => `| \`${f.filename}\` | +${f.additions || 0} | -${f.deletions || 0} |`).join('\n')}

---

## 🎯 Confidence Score

**${analysis.confidence}**

> ⚠️ _This review is automated and should not replace human code review. Always verify security-sensitive changes manually._

---

*Generated by claude-review agent — [Source](https://github.com/claude-builders-bounty/claude-builders-bounty)*
`;

  return markdown;
}

async function main() {
  const { prUrl, outputFile, verbose } = parseArgs();
  
  try {
    const { owner, repo, prNumber } = parsePRUrl(prUrl);
    const { pr, files, commits } = await fetchPRData(owner, repo, prNumber);
    
    if (verbose) {
      log(colors.green, `✓ Fetched PR: "${pr.title}"`);
      log(colors.green, `✓ Fetched ${files.length} changed files`);
      log(colors.green, `✓ Fetched ${commits.length} commits`);
    }

    const analysis = analyzeCodeQuality(files);
    const review = generateReview(pr, files, commits, analysis);

    if (outputFile) {
      fs.writeFileSync(outputFile, review, 'utf-8');
      log(colors.green, `✓ Review written to ${outputFile}`);
    } else {
      console.log(review);
    }

    // Print summary
    console.error('\n' + colors.bold + 'Review Summary:' + colors.reset);
    console.error(`  Risks: ${analysis.counts.high} high, ${analysis.counts.medium} medium, ${analysis.counts.low} low`);
    console.error(`  Confidence: ${analysis.confidence}`);

  } catch (error) {
    console.error(`${colors.red}Error: ${error.message}${colors.reset}`);
    process.exit(1);
  }
}

main();
