# CLAUDE.md — Next.js 15 + SQLite SaaS Project

## Stack & Versions

- **Node.js**: 20+ (use `node --version` to verify)
- **Next.js**: 15.x with App Router (NOT Pages Router)
- **Database**: SQLite via `better-sqlite3` (local) or `@libsql/client` (Turso remote)
- **Runtime**: Use `async`/`await` everywhere — no callbacks
- **Package Manager**: npm (not yarn/pnpm unless team convention)

## Folder Structure

```
/
├── app/                    # Next.js App Router pages
│   ├── layout.tsx          # Root layout (auth providers here)
│   ├── page.tsx            # Landing/marketing page
│   ├── (auth)/             # Auth route group
│   │   ├── login/page.tsx
│   │   └── register/page.tsx
│   ├── (dashboard)/        # Authenticated app routes
│   │   ├── layout.tsx      # Dashboard layout (sidebar, header)
│   │   ├── page.tsx        # Dashboard home
│   │   └── [slug]/         # Dynamic routes
│   ├── api/                # API Route Handlers (NOT route.ts files outside api/)
│   │   ├── auth/[...nextauth]/route.ts
│   │   └── v1/             # Versioned API
│   └── globals.css
├── components/
│   ├── ui/                 # Primitive UI (Button, Input, Card — shadcn/ui)
│   ├── forms/              # Form components with react-hook-form
│   └── features/           # Feature-specific components
├── lib/
│   ├── db.ts               # SQLite client singleton
│   ├── migrations/         # SQL migration files
│   │   └── 001_initial.sql
│   ├── auth.ts             # Auth configuration
│   └── utils.ts            # General utilities (cn(), formatDate(), etc.)
├── hooks/                   # Custom React hooks
├── types/                   # Shared TypeScript types
└── drizzle.config.ts       # Drizzle ORM config (optional)
```

**Why this structure?**
- `(auth)` and `(dashboard)` are route groups — they share layouts but have no URL segment
- `components/ui/` stays pure and reusable — no business logic
- `components/features/` holds complex feature components
- All DB code in `lib/` — never in `app/` directly

## SQL / Migration Conventions

### Rules
1. **Every schema change = a new migration file** — never mutate existing migrations
2. **Migration files are numbered**: `001_initial.sql`, `002_add_users.sql`
3. **Always include rollback** in the same file as comments
4. **No ORM-generated migrations for production** — write raw SQL you understand

### Migration Template
```sql
-- Migration: 003_add_subscriptions.sql
-- Description: Adds subscriptions table
-- Created: 2026-03-20

-- Up
CREATE TABLE IF NOT EXISTS subscriptions (
  id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
  user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan TEXT NOT NULL CHECK (plan IN ('free', 'pro', 'enterprise')),
  status TEXT NOT NULL DEFAULT 'active',
  created_at INTEGER NOT NULL DEFAULT (unixepoch()),
  updated_at INTEGER NOT NULL DEFAULT (unixepoch())
);

CREATE INDEX idx_subscriptions_user_id ON subscriptions(user_id);

-- Down
-- DROP TABLE IF EXISTS subscriptions;
```

### Writing Queries
```typescript
// lib/db.ts
import Database from 'better-sqlite3';
import { drizzle } from 'drizzle-orm/better-sqlite3';

const sqlite = new Database(process.env.DATABASE_PATH || './data.db');
export const db = drizzle(sqlite);

// Querying — always use drizzle-orm, never raw SQL strings with template literals
// unless absolutely necessary (and then validate with parameterized queries)
import { eq, and, desc } from 'drizzle-orm';
import { users } from '@/types/schema';

const activeUsers = await db.select().from(users).where(eq(users.status, 'active'));
```

## Component Patterns

### Server vs Client Components
- **Default to Server Components** — they are faster and reduce client JS
- Add `'use client'` ONLY when you need: `useState`, `useEffect`, browser APIs, event handlers
- Keep `'use client'` components as leaves in the tree — avoid wrapping large subtrees

```typescript
// ❌ Bad: wrapping everything in client boundary
'use client'
export default function Dashboard({ children }) {
  const [user] = useSession();
  return <div>{children}</div>; // children don't need client
}

// ✅ Good: client boundary only at the leaf
'use client'
export function UserAvatar() {
  const [user] = useSession();
  return <img src={user.image} alt={user.name} />;
}
```

### File Naming
| Type | Convention | Example |
|------|-----------|---------|
| Pages | `page.tsx` | `app/dashboard/page.tsx` |
| Layouts | `layout.tsx` | `app/dashboard/layout.tsx` |
| Components | `PascalCase.tsx` | `UserProfile.tsx` |
| Utilities | `camelCase.ts` | `formatDate.ts` |
| Hooks | `camelCase.ts` | `useDebounce.ts` |
| API handlers | `route.ts` | `app/api/users/route.ts` |

### Form Handling
Use `react-hook-form` + `zod` for all forms:

```typescript
import { z } from 'zod';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';

const schema = z.object({
  email: z.string().email('Invalid email address'),
  password: z.string().min(8, 'Password must be at least 8 characters'),
});

type FormData = z.infer<typeof schema>;

export function LoginForm() {
  const form = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: { email: '', password: '' },
  });

  async function onSubmit(data: FormData) {
    // handle submission
  }

  return (
    <form onSubmit={form.handleSubmit(onSubmit)}>
      {/* form fields */}
    </form>
  );
}
```

## What We DON'T Do (And Why)

### ❌ Don't Use `useEffect` for data fetching
- Use React Server Components or a data-fetching library (SWR, TanStack Query)
- `useEffect` causes waterfalls and loading spinners; server components eliminate them

### ❌ Don't Put Business Logic in Components
- Components render UI; logic goes in `lib/` or `hooks/`
- If your component has >3 `useState` calls, split it up

### ❌ Don't Use `any` Type
- Use `unknown` and narrow it, or write a proper type
- `any` defeats TypeScript's purpose and causes runtime errors

### ❌ Don't Use CSS-in-JS (styled-components, emotion)
- Use CSS Modules (`.module.css`) or Tailwind classes
- CSS-in-JS causes hydration issues and performance problems in Next.js

### ❌ Don't Make DB Calls in Server Components Without Caching
- Every DB call costs. Use `unstable_cache` or `fetch` with cache options
- Profile with `EXPLAIN QUERY PLAN` for slow queries

### ❌ Don't Use `new Date()` in SQL
- Use `unixepoch()` for SQLite timestamps — it's UTC and portable
- `new Date()` in JS is local-timezone dependent

### ❌ Don't Skip TypeScript strict mode
- Enable `"strict": true` in `tsconfig.json`
- It's the only way to catch bugs before runtime

## Dev Commands

```bash
npm run dev      # Start development server
npm run build   # Production build
npm run lint    # ESLint check
npm run type-check  # tsc --noEmit
npm run db:migrate # Run pending migrations
npm run db:studio # Open Drizzle Studio (if using Drizzle)
```

## API Conventions

### Response Shape
Always return consistent JSON:
```typescript
// Success
{ "data": { ... } }

// Error
{ "error": { "code": "VALIDATION_ERROR", "message": "..." } }
```

### Status Codes
- `200` — Success
- `201` — Created
- `400` — Bad request (validation error)
- `401` — Unauthorized
- `403` — Forbidden
- `404` — Not found
- `500` — Internal server error (never leak stack traces)
