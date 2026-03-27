# CLAUDE.md — Next.js 15 + SQLite SaaS Project

## Stack

- **Next.js**: 15.x (App Router, React Server Components)
- **React**: 19.x (concurrent features enabled)
- **TypeScript**: 5.x (strict mode)
- **Database**: SQLite via `better-sqlite3` (sync, zero-config) or `@libsql/client` + Turso (edge-ready)
- **Styling**: Tailwind CSS 4.x + CSS Variables (no runtime CSS-in-JS)
- **Auth**: NextAuth.js v5 (Auth.js) with SQLite adapter
- **Deployment**: Vercel (recommended) or Docker

---

## Project Structure

```
/
├── app/                    # Next.js App Router — all routes here
│   ├── (auth)/            # Auth group: /login, /register, /reset-password
│   ├── (dashboard)/       # Protected group: requireAuth() check
│   │   ├── layout.tsx     # Dashboard layout with sidebar
│   │   └── page.tsx       # Dashboard home
│   ├── api/               # Route Handlers (NOT pages/api/)
│   │   └── webhooks/      # Webhook handlers (raw body, skip CSRF)
│   ├── layout.tsx         # Root layout (providers, fonts)
│   └── globals.css
├── components/
│   ├── ui/                # Primitive UI (Button, Input, Card — no business logic)
│   │   └── button.tsx
│   │   └── input.tsx
│   │   └── card.tsx
│   ├── forms/             # Form components (react-hook-form + zod)
│   │   └── login-form.tsx
│   │   └── settings-form.tsx
│   └── dashboard/         # Feature-specific dashboard components
├── lib/
│   ├── db/                # Database layer ONLY
│   │   ├── index.ts       # DB client singleton (better-sqlite3 or Turso client)
│   │   ├── schema.ts      # Drizzle table definitions
│   │   └── migrations/   # SQL migration files (versioned)
│   ├── auth.ts            # NextAuth config + helpers (HAS sideload risk → use adapter)
│   ├── validators.ts      # Zod schemas for API/route inputs
│   └── utils.ts           # Pure utility functions (NO side effects)
├── public/                # Static assets
├── scripts/               # One-off dev scripts (seeds, migrations, audits)
│   └── migrate.ts
└── drizzle.config.ts      # Drizzle ORM config
```

**Rules:**
- `components/` = presentational only. Zero `async` components here (except in `app/`).
- `lib/` = pure logic, no React imports, no `useEffect`, no hooks.
- NEVER put business logic in Route Handlers — delegate to `lib/` functions.
- `app/` = route definitions + server-side data orchestration only.

---

## Naming Conventions

### Files
| Thing | Pattern | Example |
|-------|---------|---------|
| Server component | `name.tsx` | `app/dashboard/page.tsx` |
| Client component | `name.client.tsx` | `components/forms/login-form.client.tsx` |
| Utility | `kebab-case.ts` | `lib/format-currency.ts` |
| Route Handler | `route.ts` | `app/api/users/route.ts` |
| DB migration | `YYYYMMDDHHMM_description.sql` | `202603271200_add_users.sql` |

### Variables & Functions
- Use **camelCase** for variables and functions
- Use **PascalCase** for React components and TypeScript classes
- Use **SCREAMING_SNAKE_CASE** for env vars and constants that never change
- Prefix boolean variables with `is`, `has`, `can`, or `should`

### Database
- Table names: **snake_case, plural** (`users`, `audit_logs`, `subscription_plans`)
- Column names: **snake_case** (`created_at`, `stripe_customer_id`)
- Primary keys: `id TEXT PRIMARY KEY` (use `crypto.randomUUID()`, NOT auto-increment integers)
- Always `created_at` and `updated_at` on every table

---

## Database Migrations

### Rules
1. **Every schema change = a new migration file** — never mutate existing files.
2. **Migrations are sacred** — they must be backward-compatible or include a compatibility step.
3. **Never run raw SQL in Route Handlers** — use Drizzle ORM or the query builder.
4. **Use transactions** for multi-table writes.

### Workflow
```bash
# 1. Edit lib/db/schema.ts (define tables)
# 2. Generate migration
npx drizzle-kit generate

# 3. Review the generated SQL in lib/db/migrations/
# 4. Apply migration
npx tsx scripts/migrate.ts

# 5. Verify
npx tsx scripts/migrate.ts --status
```

### SQLite-specific patterns
- No `ALTER TABLE DROP COLUMN` (SQLite doesn't support it) — use migration compat layers.
- Use `INTEGER` for booleans (SQLite has no native BOOLEAN).
- `DEFAULT CURRENT_TIMESTAMP` works but is UTC-adjusted in app code.
- Use `LIKE` with caution — SQLite doesn't have real indexes for pattern matching.

---

## Component Patterns

### Server vs Client Boundary

**Server Components** (`.tsx` in `app/`):
- Fetch data directly (no API call overhead)
- Can be `async` functions
- Can use `lib/db` directly
- CANNOT use `useState`, `useEffect`, `onClick`, or any browser API

**Client Components** (`*.client.tsx`):
- Add `'use client'` at top
- Use for: forms, interactive UI, state, event handlers
- Pass data from server components via **props** — not context
- Keep client components as LEAF nodes — avoid prop drilling

**Rule of thumb**: Start with a Server Component. Only add `'use client'` when you need interactivity.

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
      body: JSON.stringify(data),
    });
    if (!res.ok) { /* handle error */ }
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      <Input {...form.register('email')} type="email" />
      <Input {...form.register('password')} type="password" />
      <Button type="submit">Sign Up</Button>
    </form>
  );
}
```

### Error Handling
- Route Handlers return `Response` with appropriate status codes
- Never `console.log` sensitive data (tokens, passwords, user PII)
- Use structured error objects: `{ error: 'INVALID_INPUT', message: '...' }`
- Wrap DB operations in try/catch and convert to `Response` errors

---

## Patterns to Follow

### 1. Route Handler Pattern
```ts
// app/api/feature/route.ts
import { NextRequest } from 'next/server';
import { createFeature, getFeatures } from '@/lib/features';
import { featureSchema } from '@/lib/validators';
import { z } from 'zod';

export async function GET(req: NextRequest) {
  const features = await getFeatures();
  return Response.json({ features });
}

export async function POST(req: NextRequest) {
  const body = await req.json();
  const parsed = featureSchema.safeParse(body);
  if (!parsed.success) {
    return Response.json({ error: 'INVALID_INPUT', issues: parsed.error.issues }, { status: 400 });
  }
  const feature = await createFeature(parsed.data);
  return Response.json({ feature }, { status: 201 });
}
```

### 2. Auth Check Pattern (Server Component)
```tsx
// app/(dashboard)/layout.tsx
import { redirect } from 'next/navigation';
import { getServerSession } from '@/lib/auth';

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  const session = await getServerSession();
  if (!session) redirect('/login');
  return <>{children}</>;
}
```

### 3. Data Fetching Pattern
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

### 4. Env Validation Pattern
```ts
// lib/env.ts
import { z } from 'zod';

const schema = z.object({
  DATABASE_URL: z.string().url(),
  NEXTAUTH_SECRET: z.string().min(32),
  STRIPE_SECRET_KEY: z.string().startsWith('sk_'),
  STRIPE_PUBLISHABLE_KEY: z.string().startsWith('pk_'),
});

export const env = schema.parse(process.env);
```
**Always validate env vars at startup — not at runtime per-request.**

---

## Anti-Patterns (And Why We Avoid Them)

### ❌ `async` in client components for initial data
**Why**: Client components run on the server for SSR AND on the client. Async client components cause waterfalls and are hard to debug.
**Do instead**: Pass data as props from parent server component.

### ❌ Mutating shared singleton objects (DB connections, caches)
**Why**: In Next.js, server code runs across multiple requests simultaneously. Mutation causes race conditions.
**Do instead**: Use read-only patterns. Create new instances per request if stateful.

### ❌ Storing secrets in `NEXT_PUBLIC_` prefixed vars
**Why**: `NEXT_PUBLIC_` vars are embedded in client-side JS bundles. Anyone can read them.
**Do instead**: Server-side only vars stay unprefixed. Access them only in Server Components or Route Handlers.

### ❌ Using `useEffect` for data fetching
**Why**: `useEffect` runs after render — causes double-fetching and loading spinners.
**Do instead**: Fetch data in Server Components. Use `useTransition` for client-side mutations that need pending UI.

### ❌ Putting business logic in Route Handlers
**Why**: Route Handlers become hard to test and reuse. Mixing HTTP concerns with business logic violates separation of concerns.
**Do instead**: Route Handler delegates to `lib/` functions. Handler only handles parsing and response formatting.

### ❌ Using auto-increment integers as primary keys
**Why**: Predictable IDs expose enumeration attacks. Sequential IDs in URLs (`/users/123`) are guessable.
**Do instead**: Use `crypto.randomUUID()` for all primary keys.

### ❌ Default `export default` for React components in `components/ui/`
**Why**: Named exports force explicit imports, making tree-shaking and refactoring easier.
**Do instead**: Use named exports only.

### ❌ Using `new Date()` without timezone awareness
**Why**: SQLite stores timestamps in local time unless handled carefully. Users in different timezones see incorrect timestamps.
**Do instead**: Always store and retrieve as UTC. Format to local time only at the presentation layer.

---

## Dev Commands

```bash
# Install & setup
npm install
cp .env.example .env.local   # fill in real values
npx tsx scripts/migrate.ts    # run initial migration

# Development
npm run dev          # Next.js dev server (http://localhost:3000)
npm run build        # Production build
npm run lint         # ESLint
npm run type-check   # tsc --noEmit

# Database
npx drizzle-kit generate   # generate migration from schema.ts
npx tsx scripts/migrate.ts # apply migrations
npm run db:studio          # Drizzle Studio (browser DB GUI)

# Testing
npm test             # Vitest unit tests
npm run test:e2e      # Playwright E2E tests
```

---

## What We Don't Do (And Why)

| Anti-pattern | Why | Alternative |
|---|---|---|
| Auto-increment PKs | Predictable, enumerable | `crypto.randomUUID()` |
| Client-side data fetching | Double-fetch, loading states | Server Components with props |
| `console.log` in production | Leaks data, no structured logging | Use a logger (pino, winston) |
| Global CSS classes | Unpredictable cascade | Tailwind utility classes only |
| `useEffect` for initial data | Hydration mismatch risk | Server Components |
| Raw SQL in handlers | SQL injection risk | ORM/query builder with typed params |
| `.env` committed to git | Secrets exposure | `.env.local` (gitignored), use Vercel env vars |
| Mixing client/server in one file | Bundle bloat, confusion | Separate files with clear `.client.tsx` suffix |
| `try/catch` swallowing errors | Silent failures, undebuggable | Always re-throw or return structured errors |
| Default exports for UI components | Hinders refactoring | Named exports only |
| CSS-in-JS runtime | Performance cost | Tailwind + CSS Variables |
| Direct DOM manipulation | Breaks React reconciliation | Use refs sparingly, prefer React patterns |
