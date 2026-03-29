# CLAUDE.md — Next.js 15 App Router + SQLite SaaS Project

> Opinionated project guide for Claude Code. Paste this into your Next.js + SQLite project root.

## Stack & Versions

- **Next.js**: 15.x (App Router)
- **Database**: SQLite via `better-sqlite3` or `@libsql/client` (Turso)
- **ORM**: Drizzle ORM (type-safe, lightweight)
- **Styling**: Tailwind CSS v4
- **Auth**: NextAuth.js v5 or custom JWT
- **Deployment**: Vercel / Railway / Fly.io
- **Language**: TypeScript (strict mode)

---

## Project Structure

```
/
├── app/                    # Next.js App Router pages
│   ├── (auth)/            # Auth routes (login, register)
│   ├── (dashboard)/       # Protected dashboard routes
│   ├── api/               # API route handlers
│   ├── layout.tsx         # Root layout
│   └── page.tsx           # Landing / home
├── components/            # Reusable UI components
│   ├── ui/               # Headless / base components
│   └── forms/            # Form components
├── db/                    # Database layer
│   ├── schema.ts         # Drizzle schema definitions
│   ├── client.ts         # DB client singleton
│   └── migrations/       # SQL migration files
├── lib/                   # Utilities & helpers
│   ├── auth.ts           # Auth helpers
│   └── utils.ts          # General utilities (cn, etc.)
├── public/               # Static assets
└── drizzle/              # Drizzle config (drizzle.config.ts)
```

---

## Naming Conventions

### Files
- **Components**: `PascalCase.tsx` (e.g., `UserProfile.tsx`)
- **Pages/Routes**: `kebab-case/page.tsx` (e.g., `app/api/users/route.ts`)
- **Utilities**: `camelCase.ts` (e.g., `formatDate.ts`)
- **Database schema**: `singular noun` (e.g., `user.ts`, `post.ts`)

### Database Tables (Drizzle)
- Table names: `snake_case` plural (e.g., `users`, `posts`)
- Columns: `snake_case`
- Primary key: `id` (integer auto-increment or UUID)
- Timestamps: `created_at`, `updated_at` (UTC, NOT NULL DEFAULT now())

### API Routes
- RESTful: `GET /api/users`, `POST /api/users`, `GET /api/users/[id]`
- Use Next.js `route.ts` files (not `pages/api/`)

---

## SQL / Migration Rules

### Drizzle Schema Pattern
```typescript
import { sqliteTable, text, integer } from 'drizzle-orm/sqlite-core';

export const users = sqliteTable('users', {
  id: integer('id').primaryKey({ autoIncrement: true }),
  email: text('email').notNull().unique(),
  passwordHash: text('password_hash').notNull(),
  createdAt: text('created_at').notNull().default('CURRENT_TIMESTAMP'),
});
```

### Migration Workflow
```bash
# 1. Edit db/schema.ts
# 2. Generate migration
npx drizzle-kit generate
# 3. Apply migration (dev)
npx drizzle-kit push
# 4. Apply migration (prod) — run SQL manually via drizzle-kit studio or CLI
```

### NEVER
- ❌ Do NOT use `SELECT *` in application code — always specify columns
- ❌ Do NOT concatenate user input into SQL strings — use parameterized queries
- ❌ Do NOT run raw SQL migrations without reviewing them first
- ❌ Do NOT use `Date.now()` or `new Date()` for DB timestamps — use UTC strings

---

## Component Patterns

### Server vs. Client Components
- Default to **Server Components** (`async` function, no 'use client')
- Add `'use client'` ONLY when you need hooks, event handlers, or browser APIs
- Pass data from server to client via `async` props or `fetch()`

### Form Actions (App Router)
```typescript
// app/(dashboard)/posts/new/page.tsx
export default async function NewPostPage() {
  async function createPost(formData: FormData) {
    'use server'
    const title = formData.get('title') as string
    // ... validate and insert
    revalidatePath('/posts')
  }
  return <PostForm action={createPost} />
}
```

### Database Queries in Server Components
```typescript
// Always use drizzle DB client
import { db } from '@/db/client'
import { users } from '@/db/schema'

const allUsers = await db.select().from(users).all()
```

---

## What We DON'T Do

### No Prisma
We use Drizzle ORM. Prisma is too heavy for SQLite-first SaaS.

### No REST overfetching
Never `fetch('/api/users')` from client — import and call DB directly in server components.

### No client-side state for server data
If data lives in DB, fetch it server-side. Only use `useState`/`useEffect` for genuinely client-side state (UI toggles, form inputs).

### No inline styles
Use Tailwind utility classes only. No `style={{}}` except for dynamic values.

### No `any`
Use `unknown` + type guards, or explicit interfaces. Strict TypeScript.

### No `console.log` in production code
Use a structured logger (or `console.error` for errors). Remove debug logs before committing.

---

## Dev Commands

```bash
# Install dependencies
npm install

# Database
npx drizzle-kit studio       # Visual DB editor (dev only)
npx drizzle-kit generate      # Generate migrations
npx drizzle-kit push          # Push schema (dev)
npm run db:migrate            # Run migrations (prod)

# Development
npm run dev                   # Start dev server
npm run build                 # Production build
npm run lint                  # ESLint
npm run typecheck            # TypeScript check

# Testing
npm run test                  # Unit tests (Vitest)
npm run test:e2e             # E2E tests (Playwright)
```

---

## Patterns to Follow

### Error Handling
```typescript
// Always wrap DB operations in try/catch and re-throw typed errors
try {
  const result = await db.insert(users).values({ email, passwordHash }).returning()
  return result[0]
} catch (err) {
  if (isDuplicateError(err)) throw new ConflictError('Email already registered')
  throw err
}
```

### Input Validation
Use `zod` for all external input (API bodies, form data, query params).

```typescript
import { z } from 'zod'
const UserSchema = z.object({ email: z.string().email(), password: z.string().min(8) })
```

### Environment Variables
All secrets in `.env.local` (never committed). `.env.example` for documentation.

---

## Anti-Patterns to Avoid

1. **Not validating form input** → Use Zod on every input
2. **Fetching in client components when server would do** → Move to server components
3. **Using `new Date()` for UTC timestamps** → Use `new Date().toISOString()` or DB `now()`
4. **Skipping error boundaries** → Wrap pages with error.tsx
5. **Not using `revalidatePath` after mutations** → Always revalidate after DB writes
6. **Hardcoded IDs** → Use params and searchParams instead
