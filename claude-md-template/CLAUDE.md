# CLAUDE.md — Next.js 15 + SQLite SaaS

> Opinionated project guide for a production-ready SaaS built with Next.js 15 App Router and SQLite.

## Stack & Versions

- **Next.js**: 15.x (App Router, React Server Components)
- **React**: 19.x (concurrent features)
- **TypeScript**: 5.x (strict mode — no exceptions)
- **Database**: SQLite via `better-sqlite3` (sync, zero-config) or `@libsql/client` + Turso (edge-ready)
- **ORM**: Drizzle ORM (preferred)
- **Styling**: Tailwind CSS 4.x + CSS Variables (no runtime CSS-in-JS)
- **Auth**: NextAuth.js v5 (Auth.js) with SQLite adapter
- **Forms**: react-hook-form + Zod
- **Deployment**: Vercel (recommended) or Docker + Fly.io

---

## Project Structure

```
/
├── app/                    # Next.js App Router — all routes
│   ├── (auth)/            # Auth group: /login, /register, /reset-password
│   ├── (dashboard)/       # Protected routes: requireAuth() enforced
│   │   ├── layout.tsx     # Dashboard shell with sidebar/nav
│   │   └── page.tsx       # Dashboard home
│   ├── api/               # Route Handlers
│   │   └── webhooks/      # Raw-body webhook handlers (skip CSRF)
│   ├── layout.tsx         # Root layout: providers, fonts, metadata
│   └── globals.css
├── components/
│   ├── ui/                # Primitive UI only (Button, Input, Card — zero business logic)
│   ├── forms/             # react-hook-form + zod form components
│   │   └── *.client.tsx   # MUST have .client.tsx suffix
│   └── dashboard/         # Feature-specific dashboard components
├── lib/
│   ├── db/
│   │   ├── index.ts       # DB client singleton
│   │   ├── schema.ts      # Drizzle table definitions
│   │   └── migrations/   # Versioned SQL migration files
│   ├── auth.ts            # NextAuth config + session helpers
│   ├── validators.ts      # Zod schemas for all API/route inputs
│   └── utils.ts           # Pure utility functions (NO side effects, NO React imports)
├── scripts/
│   └── migrate.ts         # Migration runner
└── drizzle.config.ts
```

**Core rules:**
- `components/` = presentational only. No `async` components here.
- `lib/` = pure logic. No React imports, no `useEffect`, no hooks.
- Business logic NEVER goes in Route Handlers — delegate to `lib/` functions.
- `app/` = route definitions + server-side data orchestration only.

---

## Naming Conventions

### Files

| Thing | Pattern | Example |
|---|---|---|
| Server component | `name.tsx` | `app/dashboard/page.tsx` |
| Client component | `name.client.tsx` | `components/forms/login-form.client.tsx` |
| Route Handler | `route.ts` | `app/api/users/route.ts` |
| DB migration | `YYYYMMDDHHMM_description.sql` | `202603280000_add_users.sql` |
| Utility | `kebab-case.ts` | `lib/format-currency.ts` |
| Schema | `schema.ts` | `lib/db/schema.ts` |

### Variables

- **camelCase** — variables and functions
- **PascalCase** — React components and TypeScript classes
- **SCREAMING_SNAKE_CASE** — env vars and true constants
- **Prefix booleans** with `is`, `has`, `can`, `should` (`isLoading`, `hasError`)

### Database

- Table names: **snake_case, plural** (`users`, `audit_logs`, `subscription_plans`)
- Column names: **snake_case** (`created_at`, `stripe_customer_id`)
- Primary keys: `id TEXT PRIMARY KEY` — use `crypto.randomUUID()`, NEVER auto-increment integers
- Every table MUST have `created_at` and `updated_at`

---

## Database Migrations

### Rules

1. **Every schema change = a new migration file** — never mutate existing files
2. **Migrations are sacred** — backward-compatible or include a compat step
3. **Never run raw SQL in Route Handlers** — use Drizzle ORM
4. **Wrap multi-table writes in transactions** with `db.transaction()`
5. **Never use `DROP COLUMN`** — SQLite doesn't support it (use compat migration)

### SQLite-Specific Gotchas

- SQLite has no native `BOOLEAN` — use `INTEGER` (0/1)
- `DEFAULT CURRENT_TIMESTAMP` stores server local time — convert to UTC in app code
- Foreign key enforcement must be enabled: `PRAGMA foreign_keys = ON`
- WAL mode recommended for concurrent reads: `PRAGMA journal_mode = WAL`
- Pattern matching with `LIKE` can't use indexes efficiently — use full-text search for large datasets

### Workflow

```bash
# 1. Edit schema
# lib/db/schema.ts — add/edit tables

# 2. Generate migration
npx drizzle-kit generate

# 3. Review the SQL in lib/db/migrations/
# 4. Apply
npx tsx scripts/migrate.ts

# 5. Verify
npx tsx scripts/migrate.ts --status
```

### Connection Pattern

```ts
// lib/db/index.ts — singleton pattern
import Database from 'better-sqlite3';
import { drizzle } from 'drizzle-orm/better-sqlite3';
import * as schema from './schema';

const sqlite = new Database(process.env.DATABASE_URL || './data/app.db');
sqlite.pragma('journal_mode = WAL');
sqlite.pragma('foreign_keys = ON');

export const db = drizzle(sqlite, { schema });
```

---

## Component Patterns

### Server vs Client Boundary

**Server Components** (`.tsx` in `app/`):
- Fetch data directly (no API overhead)
- Can be `async`
- Can import and use `lib/db` directly
- CANNOT use `useState`, `useEffect`, `onClick`, browser APIs

**Client Components** (`*.client.tsx`):
- Add `'use client'` at top of file — first line
- Use for: forms, interactive UI, state, event handlers
- Receive data from Server Components via **props** — NOT context for initial data
- Keep client components as **leaf nodes** — avoid deep prop drilling

**Rule of thumb**: Default to Server Component. Add `'use client'` only when you need interactivity.

### Form Handling

```tsx
// components/forms/signup-form.client.tsx
'use client';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { signupSchema } from '@/lib/validators';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';

export function SignupForm() {
  const form = useForm<z.infer<typeof signupSchema>>({
    resolver: zodResolver(signupSchema),
    defaultValues: { email: '', password: '' },
  });

  async function onSubmit(data: z.infer<typeof signupSchema>) {
    const res = await fetch('/api/auth/signup', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    });
    if (!res.ok) {
      const { error } = await res.json();
      form.setError('root', { message: error });
    }
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
      <Input {...form.register('email')} type="email" />
      <Input {...form.register('password')} type="password" />
      <Button type="submit" disabled={form.formState.isSubmitting}>
        {form.formState.isSubmitting ? 'Signing up...' : 'Sign Up'}
      </Button>
    </form>
  );
}
```

---

## Patterns to Follow

### Route Handler Pattern

```ts
// app/api/features/route.ts
import { NextRequest } from 'next/server';
import { z } from 'zod';
import { listFeatures, createFeature } from '@/lib/features';
import { featureSchema } from '@/lib/validators';

export async function GET(_req: NextRequest) {
  const features = await listFeatures();
  return Response.json({ features });
}

export async function POST(req: NextRequest) {
  const body = await req.json();
  const parsed = featureSchema.safeParse(body);
  if (!parsed.success) {
    return Response.json(
      { error: 'VALIDATION_ERROR', issues: parsed.error.issues },
      { status: 400 }
    );
  }
  const feature = await createFeature(parsed.data);
  return Response.json({ feature }, { status: 201 });
}
```

### Auth Check Pattern (Server Component)

```tsx
// app/(dashboard)/layout.tsx
import { redirect } from 'next/navigation';
import { getServerSession } from '@/lib/auth';

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const session = await getServerSession();
  if (!session) redirect('/login');
  return (
    <div className="flex h-screen">
      <aside>...</aside>
      <main>{children}</main>
    </div>
  );
}
```

### Data Fetching Pattern

```tsx
// app/dashboard/page.tsx
import { getServerSession } from '@/lib/auth';
import { getUserUsage } from '@/lib/usage';
import { UsageCard } from '@/components/dashboard/usage-card';

export default async function DashboardPage() {
  const session = await getServerSession();
  const usage = await getUserUsage(session.user.id);
  return <UsageCard usage={usage} />;
}
```

### Env Validation Pattern

```ts
// lib/env.ts
import { z } from 'zod';

const schema = z.object({
  DATABASE_URL: z.string(),
  NEXTAUTH_SECRET: z.string().min(32),
  NEXTAUTH_URL: z.string().url().default('http://localhost:3000'),
});

export const env = schema.parse(process.env);
```

**Always validate env vars at startup** — not per-request at runtime.

---

## Anti-Patterns

| ❌ Don't Do This | Why | ✅ Do This Instead |
|---|---|---|
| Auto-increment PKs | Predictable, enumerable attack surface | `crypto.randomUUID()` |
| `async` client components for initial data | Double-fetch waterfalls, hydration issues | Pass data as props from Server Component |
| `useEffect` for data fetching | Runs after render, causes loading states | Fetch in Server Components |
| `new Date()` without timezone | UTC mismatch across timezones | Store/retrieve as UTC, format at display layer |
| `NEXT_PUBLIC_` for secrets | Embedded in client bundle, public | Server-only vars stay unprefixed |
| Business logic in Route Handlers | Hard to test, mixed concerns | Delegate to `lib/` functions |
| Raw SQL with string interpolation | SQL injection risk | ORM with typed parameters |
| Default exports for UI components | Hinders tree-shaking and refactoring | Named exports only |
| `try/catch` swallowing errors | Silent failures are undebuggable | Re-throw or return structured `{ error }` |
| CSS-in-JS runtime | Performance cost per render | Tailwind + CSS Variables |
| `.env` committed to git | Secret exposure | `.env.local` (gitignored) + Vercel env vars |
| `console.log` in production | Leaks data, no structure | `pino` logger or `console.error` with shape |
| Mutating shared singletons | Race conditions across requests | Read-only patterns, per-request instances |

---

## What We Don't Do (And Why)

| We Don't Do | Reason |
|---|---|
| Auto-increment integer PKs | Predictable enumeration attacks |
| Client-side initial data fetching | Double-fetch, loading spinners, hydration mismatch |
| `console.log` in production code | Data leakage, no structured output |
| Global CSS classes | Unpredictable cascade conflicts |
| Business logic in Route Handlers | Untestable, mixed HTTP + domain concerns |
| Raw SQL in handlers | Injection vulnerability surface |
| `.env` committed to git | Secrets in history = game over |
| Mixing client/server in one file | Bundle bloat, boundary confusion |
| `try/catch` swallowing errors silently | Invisible bugs, impossible to debug |
| Default exports for UI components | Refactoring harder, tree-shaking unreliable |
| CSS-in-JS runtime | Performance tax on every render |
| Direct DOM manipulation | Breaks React reconciliation |

---

## Dev Commands

```bash
# Setup
npm install
cp .env.example .env.local    # fill in DATABASE_URL, NEXTAUTH_SECRET
npx tsx scripts/migrate.ts     # run initial migration

# Development
npm run dev                    # http://localhost:3000
npm run build                  # production build
npm run lint                   # ESLint
npm run type-check             # tsc --noEmit

# Database
npx drizzle-kit generate       # generate migration from schema
npx tsx scripts/migrate.ts    # apply pending migrations
npm run db:studio             # Drizzle Studio (browser DB GUI)

# Testing
npm test                       # Vitest unit tests
npm run test:e2e               # Playwright E2E tests
```

---

## Environment Variables

```bash
# Required
DATABASE_URL=file:./data/app.db          # Local SQLite (better-sqlite3)
# or for Turso edge:
TURSO_DATABASE_URL=libsql://your-db.turso.io
TURSO_AUTH_TOKEN=your-token

# Auth (required)
NEXTAUTH_SECRET=min-32-char-random-string
NEXTAUTH_URL=http://localhost:3000

# Optional
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=your@email.com
SMTP_PASS=your-password
```

---

## Deployment

- **Recommended**: Vercel (Edge Runtime compatible)
- **Self-hosted**: Docker on Fly.io or Railway
- **SQLite on server**: `better-sqlite3` + PM2; DB file in persistent volume
- **SQLite on edge**: Turso (`@libsql/client`) — native edge support, globally distributed
- **Docker**: Use multi-stage build; mount volume for `data/` directory persistence

---

## Security Rules

1. **Validate all inputs** — Zod schema at every API boundary
2. **Auth before logic** — session check in every protected Route Handler
3. **No secrets in client bundle** — never prefix with `NEXT_PUBLIC_`
4. **CSRF protection** — built into NextAuth; don't disable it
5. **Passwords hashed** — bcrypt (cost factor 12) or argon2
6. **Rate limiting** — `@upstash/ratelimit` on all public API routes
7. **Secrets in logs** — never log tokens, passwords, or PII
