# CLAUDE.md — Next.js 15 App Router + SQLite SaaS

> Opinionated project context for Claude Code. Every rule has a reason.

## Stack

- **Next.js 15** (App Router, React 19)
- **SQLite** via `better-sqlite3` (local) or `@libsql/client` (Turso)
- **Drizzle ORM** — type-safe SQL, schema-first
- **Zod** — runtime validation for API inputs
- **TypeScript 5** (strict mode)

---

## Project Structure

```
app/                    # Next.js App Router pages & layouts
  (auth)/              # Auth routes (login, register, etc.)
  (dashboard)/         # Protected dashboard routes
  api/                 # API Route Handlers (app/api/)
components/             # React components (no business logic here)
  ui/                  # Headless/base components
  features/            # Feature-specific components
db/
  schema/              # Drizzle schema definitions (tables, relations)
  migrations/          # SQL migration files (Drizzle Kit generated)
  index.ts             # DB connection singleton
  seed.ts              # Dev seed data
lib/
  api/                 # Shared API utilities (error handling, response helpers)
  auth/                # Session management, password hashing
  validators/          # Zod schemas for forms and API inputs
  utils.ts             # General utilities (cn(), formatDate(), etc.)
types/                  # Shared TypeScript types (not generated from DB)
.env.local              # Environment variables (never commit secrets)
```

**Key conventions:**
- Pages live in `app/`. API routes in `app/api/`.
- Server Components by default; add `'use client'` only when needed.
- Database queries run server-side only. Never import DB in client components.
- Feature components (e.g., `components/features/billing/`) own their sub-components.

---

## Naming Conventions

### Database
- **Tables:** `snake_case`, plural nouns (`users`, `subscriptions`, `invoice_items`)
- **Columns:** `snake_case` (`created_at`, `user_id`, `is_active`)
- **Primary keys:** `id` (integer, auto-increment) or `uuid` (UUID v4)
- **Indexes:** `idx_<table>_<column>` (`idx_users_email`)

### API Routes
- Route files match the resource: `app/api/users/route.ts` for `/api/users`
- Use **Zod schemas** for request validation (body, query, params)
- Response shape: `{ data, error, meta }` — always return `{ data: ... }` on success

### Components
- **Files:** `PascalCase.tsx` (`UserProfile.tsx`, `InvoiceTable.tsx`)
- **Props:** `interface Props { ... }` with explicit types
- **State:** prefer `useState<T>()` over `any`

---

## Database Rules

### Migrations
1. Edit `db/schema/` to define or modify tables
2. Run `drizzle-kit generate` to create migration SQL
3. Run `drizzle-kit migrate` to apply (or `drizzle-kit push` for dev)
4. **Never edit migration files after they are applied.** Create a new migration for changes.

### Query Patterns
```ts
// ✅ CORRECT: parameterized query with Drizzle
const user = await db.select().from(users).where(eq(users.id, id)).get();

// ✅ CORRECT: insert with returning
const newUser = await db.insert(users).values(data).returning().get();

// ❌ WRONG: string interpolation (SQL injection risk)
await db.run(\`SELECT * FROM users WHERE id = \${id}\`);
```

### Transactions
Use transactions for multi-step writes:
```ts
await db.transaction(async (tx) => {
  const order = await tx.insert(orders).values({ userId, total }).returning().get();
  await tx.insert(orderItems).values(orderId, items);
  // auto-rollback on throw
});
```

### No Raw SQL in API Routes
All DB access goes through repository functions in `lib/db/` (if present) or direct Drizzle queries. API routes should be thin: validate input → query DB → return JSON.

---

## API Design

### Response Format
```ts
// Success
return Response.json({ data: result });

// Error
return Response.json({ error: { code: 'NOT_FOUND', message: 'User not found' } }, { status: 404 });
```

### Error Codes
| Code | HTTP | Meaning |
|------|------|---------|
| `VALIDATION_ERROR` | 400 | Invalid input (Zod failed) |
| `UNAUTHORIZED` | 401 | Not logged in |
| `FORBIDDEN` | 403 | Logged in but no permission |
| `NOT_FOUND` | 404 | Resource doesn't exist |
| `CONFLICT` | 409 | Duplicate (e.g., email already exists) |
| `INTERNAL_ERROR` | 500 | Unexpected server error |

### Validation
Every API route that accepts user input must validate with Zod before touching the DB:
```ts
const body = BodySchema.parse(req.body); // throws ZodError on invalid
```

---

## What We DON'T Do

| Anti-pattern | Why | Instead |
|---|---|---|
| Raw SQL strings (`\`<sql>\``) | SQL injection | Drizzle query builder |
| `any` types in API handlers | Silent failures | Explicit TypeScript types |
| `console.log` in production | Noise | Structured logging (use logger) |
| API routes that import client components | Build failure | Keep server/server-client boundaries clear |
| `new Date()` in DB inserts | Timezone issues | Use `Date.now()` + UTC |
| Auth via query params (`?token=`) | Leaky URLs | Use `Authorization:` header |

---

## Dev Commands

```bash
npm run dev          # Start dev server (http://localhost:3000)
npm run build        # Production build
npm run lint         # ESLint check
npm run typecheck    # TypeScript check (tsc --noEmit)

# Database
npm run db:generate  # Drizzle: generate migration from schema changes
npm run db:migrate   # Apply pending migrations
npm run db:push      # Push schema to DB (dev only, no migration file)
npm run db:studio    # Drizzle Studio (visual DB browser)

# Seeding
npm run db:seed      # Run seed script
```

---

## Common Tasks

### Add a new API endpoint
1. Create `app/api/<resource>/route.ts`
2. Add Zod input schema in `lib/validators/`
3. Write handler with validation → DB query → response pattern
4. Export named functions: `GET`, `POST`, etc.

### Add a new DB table
1. Add schema definition in `db/schema/`
2. Run `npm run db:generate`
3. Run `npm run db:migrate`
4. Update repository/API if needed

### Add a new page
1. Create `app/(dashboard)/<page>/page.tsx` (or `app/<page>/page.tsx`)
2. Use Server Components by default
3. Add `'use client'` only for interactivity (forms, useState, useEffect)

---

## Environment Variables

Required in `.env.local`:
```
DATABASE_URL=file:./dev.db          # SQLite file path
AUTH_SECRET=<32-byte-random>        # Session signing key (openssl rand -hex 32)
```

Optional:
```
TURSO_DATABASE_URL=...               # Turso remote DB (replaces DATABASE_URL)
TURSO_AUTH_TOKEN=...                # Turso auth token
```

---

## Testing Approach

- **Unit:** Test Zod validators and utility functions
- **API:** Test route handlers with mock DB (avoid real DB in tests)
- **Components:** Prefer integration tests over snapshot tests

Test file location: `<file>.test.ts` next to the source file.
