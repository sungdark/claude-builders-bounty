# Claude Code Context — Next.js 15 + SQLite SaaS Template

## Overview

This is an opinionated, production-ready `CLAUDE.md` template for a typical SaaS project built with **Next.js 15 App Router** and **SQLite** (better-sqlite3 or Turso).

> This template is designed to be copy-pasted into a new project without modifications. Every rule has a reason.

---

## 📦 Stack & Versions

| Technology | Version | Notes |
|------------|---------|-------|
| Next.js | 15.x | App Router, Server Components |
| React | 19.x | |
| TypeScript | 5.x | Strict mode enabled |
| SQLite | — | better-sqlite3 (local) or Turso (edge) |
| ORM | Drizzle ORM | Type-safe, SQL-like |
| Auth | NextAuth.js v5 | |
| Forms | react-hook-form + zod | |
| Styling | Tailwind CSS 4.x | |

---

## 📁 Project Structure

```
├── app/                    # Next.js App Router pages
│   ├── (auth)/            # Auth routes (login, register, etc.)
│   ├── (dashboard)/       # Protected dashboard routes
│   ├── api/              # Route Handlers (no Route Modules in v15)
│   └── layout.tsx         # Root layout
├── components/            # Shared components
│   ├── ui/               # Primitives (Button, Input, etc.)
│   ├── forms/            # Form components (wrapped with react-hook-form)
│   └── dashboard/        # Feature-specific components
├── lib/                  # Business logic
│   ├── db/               # Drizzle schema, migrations, client
│   ├── auth/             # Auth utilities
│   ├── validations/      # Zod schemas
│   └── utils/            # Helpers
├── public/               # Static assets
├── drizzle/             # SQL migrations (versioned!)
└── scripts/              # Dev utilities
```

### Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| Pages | `kebab-case` | `app/settings-billing/page.tsx` |
| Components | `PascalCase` | `UserProfileCard.tsx` |
| Utils/Hooks | `camelCase` | `useUserData.ts`, `formatCurrency.ts` |
| DB Tables | `snake_case` | `user_subscriptions` |
| DB Columns | `snake_case` | `created_at`, `stripe_customer_id` |
| Files in `lib/` | `camelCase` | `db/client.ts`, `auth/session.ts` |
| Route Handlers | `route.ts` | `app/api/webhooks/stripe/route.ts` |

---

## 🗄️ Database & Migrations

### Rules

1. **All migrations are versioned SQL files** — never modify a migration once merged
2. **Use Drizzle ORM** for all DB operations — never raw SQL strings
3. **Migrations go in `drizzle/migrations/`** — tracked in git
4. **Never use `DROP COLUMN` in a migration** — SQLite limitation
5. **Use `INTEGER` for booleans** — SQLite has no BOOLEAN type (0/1)
6. **Use `TEXT` for UUIDs** — SQLite doesn't have a native UUID type
7. **Primary keys are `TEXT` UUIDs** — never auto-increment integers for SaaS

### Why These Rules?

```sql
-- ❌ NEVER do this in SQLite
ALTER TABLE users DROP COLUMN phone_number;

-- ✅ Instead: mark column as deprecated and ignore it
-- Add a comment or migration note, then ignore the column in your app

-- ❌ NEVER use auto-increment for SaaS primary keys
-- Auto-increment PKs can be guessed, leaked, and cause ID collision issues
CREATE TABLE orders (
  id INTEGER PRIMARY KEY AUTOINCREMENT  -- ❌ BAD
);

-- ✅ Use UUIDs instead
CREATE TABLE orders (
  id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(4))) || '-' || ...)
);
```

### Migration Workflow

```bash
# Generate migration from schema changes
npx drizzle-kit generate

# Apply migrations locally
npx drizzle-kit migrate

# Apply migrations in production (run once per instance)
npx drizzle-kit push
```

---

## 🧩 Component Patterns

### Server vs Client Components

**Default to Server Components.** Only add `'use client'` when necessary.

| Use Client Component When | Use Server Component When |
|---------------------------|--------------------------|
| Using `useState`, `useEffect` | Fetching data from DB |
| Event listeners (onClick, onChange) | Accessing server resources |
| Browser-only APIs | Rendering markdown/HTML |
| Real-time subscriptions | SEO metadata |

### Form Handling

All forms must use `react-hook-form` + `zod`:

```typescript
// ✅ CORRECT pattern
import { useForm } from 'react-hook-form';
import { z } from 'zod';
import { zodResolver } from '@hookform/resolvers/zod';

const schema = z.object({
  email: z.string().email(),
  name: z.string().min(2),
});

type FormData = z.infer<typeof schema>;

// In component:
const form = useForm<FormData>({
  resolver: zodResolver(schema),
  defaultValues: { email: '', name: '' },
});
```

### Route Handlers (API Endpoints)

```typescript
// ✅ CORRECT pattern — validate input, return typed JSON
import { NextResponse } from 'next/server';
import { z } from 'zod';
import { db } from '@/lib/db/client';
import { verifyAuth } from '@/lib/auth/session';

const PostSchema = z.object({ title: z.string().min(1), body: z.string() });

export async function POST(req: Request) {
  const session = await verifyAuth(req);
  if (!session) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const body = await req.json();
  const parsed = PostSchema.safeParse(body);
  if (!parsed.success) {
    return NextResponse.json({ error: parsed.error.flatten() }, { status: 400 });
  }

  const post = await db.insert(posts).values({
    ...parsed.data,
    authorId: session.userId,
  }).returning();

  return NextResponse.json(post, { status: 201 });
}
```

---

## ⚠️ Anti-Patterns (And Why)

| Anti-Pattern | Problem | Correct Alternative |
|-------------|---------|---------------------|
| Auto-increment PKs | Predictable, guessable IDs | UUID primary keys |
| `useEffect` for data | Double-fetch, race conditions | Server Components or React Query |
| Raw SQL strings | SQL injection risk, no type safety | Drizzle ORM |
| CSS-in-JS at runtime | Performance overhead | Tailwind CSS |
| Client components everywhere | Large JS bundles | Server Components first |
| `any` types | No type safety | Explicit types + `z.infer<>` |
| `.env` for secrets | Committed to git | `.env.local` + docs |
| Synchronous DB calls in Route Handlers | Blocks request thread | Async/await |
| `npm install --legacy-peer-deps` | Hides peer dep conflicts | Fix the conflicts |

---

## 🧪 Dev Commands

```bash
# Install dependencies
npm install

# Run database migrations
npm run db:migrate

# Generate Drizzle types
npm run db:generate

# Start development server
npm run dev

# Run type checking
npm run typecheck

# Run linting
npm run lint

# Run tests
npm run test
```

---

## 🚫 What We DON'T Do

| Don't | Reason |
|-------|--------|
| Use auto-increment IDs for entities | UUIDs prevent enumeration attacks |
| Use `useEffect` for initial data fetch | Server Components + React Query |
| Put API keys in `.env` | Use `.env.local` and document required vars |
| Use default exports for components | Named exports are better for refactoring |
| Use `console.log` in production | Use structured logging (pino) |
| Fetch data directly in Client Components | Use Server Components as data boundary |
| Skip input validation | Always validate with Zod on client AND server |

---

## ✅ Quick Reference

- **New page?** → `app/[kebab-case]/page.tsx` (Server Component by default)
- **Need a form?** → `react-hook-form` + `zod` + Server Action
- **DB change?** → Modify `lib/db/schema.ts`, run `npm run db:generate && npm run db:migrate`
- **Need a client component?** → Wrap only what needs interactivity, not the parent
- **API endpoint?** → `app/api/[resource]/route.ts` with `verifyAuth()` and Zod validation
- **Environment variable?** → Add to `.env.example`, document the purpose

---

## 📄 License

MIT — This CLAUDE.md template is freely reusable.
