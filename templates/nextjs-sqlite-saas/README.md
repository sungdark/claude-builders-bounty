# CLAUDE.md — Next.js 15 + SQLite SaaS Template

**Issue:** [claude-builders-bounty#2](https://github.com/claude-builders-bounty/claude-builders-bounty/issues/2) | **Bounty: $75** | Powered by [Opire](https://opire.dev)

An opinionated CLAUDE.md template for a Next.js 15 App Router + SQLite (better-sqlite3 or Turso) SaaS application. Every rule has a reason.

## Usage

1. Start a new Next.js + SQLite project:
   ```bash
   npx create-next-app@latest my-saas --typescript --app --no-tailwind
   cd my-saas
   npm install better-sqlite3 drizzle-orm zod
   npm install -D drizzle-kit @types/better-sqlite3
   ```

2. Copy this file to your project root:
   ```bash
   curl -fsSL <RAW_URL> -o CLAUDE.md
   ```

3. Claude Code will read it automatically and follow these conventions.

## What's Covered

- **Project structure** — App Router conventions, where things go
- **Database rules** — SQLite query patterns, Drizzle ORM, migration workflow, transactions
- **Naming conventions** — tables, columns, variables, components, API routes
- **API design** — response format, Zod validation, error codes
- **Anti-patterns** — specific things to avoid (SQL injection, raw error exposure)
- **Dev commands** — db:generate, db:migrate, db:studio, etc.
- **Environment variables** — required and optional .env.local vars
- **Common tasks** — how to add API routes, DB tables, and pages

## Acceptance Criteria

- [x] Covers project structure, naming conventions, DB migration rules
- [x] Includes dev commands, patterns to follow, anti-patterns to avoid
- [x] Opinionated — every rule has a reason, not generic advice
- [x] Usable without modification on a greenfield Next.js + SQLite project
- [x] Targets Next.js 15 App Router specifically

## Payment

BTC: `eB51DWp1uECrLZRLsE2cnyZUzfRWvzUzaJzkatTpQV9`
