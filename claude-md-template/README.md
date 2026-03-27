# CLAUDE.md Template for Next.js 15 + SQLite SaaS

Production-ready `CLAUDE.md` for SaaS projects built with Next.js 15 App Router and SQLite.

## Usage

1. Create a new Next.js 15 project:
   ```bash
   npx create-next-app@latest my-saas --typescript --tailwind --eslint --app --src-dir=false
   cd my-saas
   npm install better-sqlite3 drizzle-orm @auth/drizzle-adapter next-auth react-hook-form @hookform/resolvers zod
   npm install -D drizzle-kit @types/better-sqlite3
   ```

2. Copy `CLAUDE.md` into the project root

3. Run the dev server — CLAUDE.md is automatically read by Claude Code on each session

## What's Included

- **Stack & Versions** — exact tech versions with reasoning
- **Project Structure** — clear folder conventions with rules
- **Naming Conventions** — files, variables, database naming rules
- **Database Migrations** — Drizzle ORM workflow, SQLite gotchas
- **Component Patterns** — Server vs Client boundary, form handling with code examples
- **5 Essential Patterns** — Route Handler, Auth Check, Data Fetching, Env Validation, Data Mutation
- **12 Anti-Patterns** — what NOT to do with reasons
- **What We Don't Do Table** — quick reference
- **Dev Commands** — full reference
- **Security Rules** — 7 must-follow rules

## Quick Setup

```bash
# 1. Install dependencies
npm install

# 2. Configure env
cp .env.example .env.local
# Edit .env.local with your DATABASE_URL and NEXTAUTH_SECRET

# 3. Run migrations
npx tsx scripts/migrate.ts

# 4. Start dev server
npm run dev
```

## Testing the Template

To confirm CLAUDE.md works without modification on a greenfield project:

1. Create a fresh Next.js 15 project
2. Paste `CLAUDE.md` into the root
3. Ask Claude Code: "What conventions should I follow for this project?"
4. Confirm it describes the project structure, DB patterns, and component rules correctly

## Bounty

Powered by [Opire](https://opire.dev) — bounty #2 ($75)
收款地址：eB51DWp1uECrLZRLsE2cnyZUzfRWvzUzaJzkatTpQV9
