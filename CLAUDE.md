# CLAUDE.md — Next.js 15 App Router + SQLite SaaS Project

**Bounty:** $75 — powered by [Opire](https://opire.dev)

> Opinionated, production-ready context file for Claude Code. Every rule has a reason.

## Stack & Versions

- **Next.js:** 15.x (App Router, React Server Components)
- **Runtime:** Node.js 20+ / Vercel
- **Database:** SQLite via `better-sqlite3` (sync) or `@libsql/client` (Turso)
- **ORM:** Drizzle ORM (type-safe, lightweight)
- **Styling:** Tailwind CSS 4.x
- **Auth:** NextAuth.js v5 (Auth.js) or custom JWT
- **Deployment:** Vercel (serverless) or self-hosted

## Project Structure

```
app/                    # Next.js App Router pages
  (auth)/              # Auth routes (login, register, etc.)
  (dashboard)/        # Protected dashboard routes
  api/                # API Route Handlers
    /trpc/            # tRPC router entry
components/
  ui/                 # Reusable shadcn/ui components
  forms/              # Form components (react-hook-form + zod)
lib/
  db/                 # Drizzle schema + db client
    schema/           # Table definitions
    index.ts         # DB client singleton
  utils.ts            # cn() and other utilities
  validations.ts      # Zod schemas
```

**Key rules:**
- All DB access goes through `/lib/db/` — never query directly in components
- API routes live in `app/api/` — prefer tRPC for type-safe calls
- Server Components are the default — add `'use client'` only when needed

## SQL / Migration Conventions

```bash
# Generate a migration
npx drizzle-kit generate

# Apply migrations (dev)
npx drizzle-kit push

# Apply migrations (prod)
npx drizzle-kit migrate
```

**Rules:**
- Always use Drizzle schema types — never raw SQL strings in application code
- Migrations are sacred: never modify a migration file after it's been applied
- Add `NOT NULL` by default; nullable columns need explicit justification
- Index any column used in a `WHERE`, `ORDER BY`, or `JOIN` clause
- Avoid `ALTER TABLE` in migrations — use additive changes only

## Component Patterns

### Server vs Client Components

```
✅ DO: Make it a Server Component
- Pages, layouts, data-fetching components
- Components that don't need interactivity

❌ DON'T: Make it a Client Component ('use client')
- Event handlers (onClick, onChange, etc.)
- useState, useEffect, useRef
- Browser-only APIs
```

### File Naming

| Type | Convention | Example |
|------|-----------|---------|
| Server Component | `PascalCase.tsx` | `UserProfile.tsx` |
| Client Component | `PascalCase.client.tsx` | `LoginForm.client.tsx` |
| Utility | `kebab-case.ts` | `format-date.ts` |
| API Route | `route.ts` | `app/api/users/route.ts` |

### Import Order

1. React / Next.js imports
2. Third-party libraries
3. Internal components / hooks
4. Types / utils
5. Styles (last resort)

## What We Don't Do (And Why)

| Anti-pattern | Why | Instead |
|---|---|---|
| `any` types | Type safety hole | Zod + Drizzle inferred types |
| `useEffect` for data fetching | RACE conditions | Server Components / tRPC |
| SQL template literals | Injection risk | Drizzle ORM |
| `npm i` (legacy) | Lockfile issues | `pnpm` or `bun` |
| CSS Modules + Tailwind | Conflict | Tailwind only |
| `try/catch` swallowing errors | Silent failures | Let errors propagate + Sentry |

## Dev Commands

```bash
pnpm dev          # Start dev server
pnpm build        # Production build
pnpm db:push      # Push schema (dev)
pnpm db:migrate   # Run migrations
pnpm db:studio    # Open Drizzle Studio
pnpm typecheck    # tsc --noEmit
pnpm lint         # ESLint
pnpm test         # Vitest
```

## Anti-Patterns to Avoid

1. **No `useEffect` for data fetching** — Server Components + tRPC query functions
2. **No `useState` for server data** — Data flows down from Server Components
3. **No direct SQL** — Always through Drizzle schema
4. **No `@ts-ignore`** — Fix the type error properly
5. **No barrel imports (`@/components`)** — Import from specific files to enable tree-shaking
