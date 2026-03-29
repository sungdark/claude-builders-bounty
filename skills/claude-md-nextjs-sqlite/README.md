# SKILL: CLAUDE.md for Next.js + SQLite SaaS

An opinionated `CLAUDE.md` template for Next.js 15 App Router + SQLite (better-sqlite3 or Turso) SaaS projects.

## Setup (3 Steps)

### 1. Copy the file
```bash
cp skills/claude-md-nextjs-sqlite/CLAUDE.md /path/to/your/project/
```

### 2. Customize it
Edit the project-specific sections:
- Stack versions
- Project structure (if different)
- Dev commands
- Any project-specific rules

### 3. Test it
```bash
# Verify Claude Code picks it up
claude --print "What stack does this project use?" 
# Should respond with Next.js + SQLite info
```

## What's Included

- **Stack & Versions** — explicit tech stack declaration
- **Project Structure** — folder conventions for App Router
- **Naming Conventions** — files, tables, columns, API routes
- **SQL / Migration Rules** — Drizzle ORM patterns, what NOT to do
- **Component Patterns** — Server vs Client, form actions, DB queries
- **Anti-Patterns** — explicit list of things we avoid
- **Dev Commands** — standard npm scripts
- **Patterns to Follow** — error handling, validation, env vars

## Why This Exists

A greenfield Next.js + SQLite project needs clear rules or it becomes messy fast. This CLAUDE.md encodes:

1. **Conventions** — so Claude doesn't invent inconsistent naming
2. **Rules** — so Claude avoids common mistakes (Prisma, `any`, `SELECT *`, etc.)
3. **Patterns** — so Claude writes idiomatic code from the first line

## Customization Tips

- Update stack versions to match your actual dependencies
- Add custom rules specific to your project (e.g., "we use Clerk, not NextAuth")
- Extend the anti-patterns list as you discover new mistakes
- Keep it short — CLAUDE.md should be scannable, not exhaustive
