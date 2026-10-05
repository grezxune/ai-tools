---
name: convex
description: Convex patterns for schema, queries, mutations, and auth. Use before writing or reviewing Convex code in a repo with no `docs/convex.md`.
---

# Convex Patterns

Read this before writing or reviewing Convex schema, queries, mutations, actions, or auth.

## User IDs & Data Ownership

- Use `userId: v.id("users")` as the ownership field on every user-owned table.
- Never use email as a foreign key. Email lives only on the `users` table.
- Never join or filter across tables by email. Use `userId`.
- Every table with a `userId` field needs a `by_userId` index.
- Use compound indexes for common filters, e.g. `by_userId_status`.
- The `by_email` index on `users` exists only for Auth.js session lookup in `getAuthUser()`. After that, use `user._id`.

## Authorization (non-negotiable)

Never trust client-supplied `userId`, `email`, `role`, or `platformRole` for authorization.

Every public Convex query/mutation that accepts `userId` must:
1. Receive the canonical value derived from the authenticated NextAuth session.
2. Enforce ownership and role checks in Convex against stored records.
3. Use `ctx.auth.getUserIdentity()` as canonical actor identity and reject mismatches.

Deny by default: missing auth, missing ownership, or identity mismatch fails immediately. No deterministic or default secret/key fallbacks in production. Development-only auth providers must be disabled in production builds.

## Enforcement Pattern

- Do not use raw `query`/`mutation` for protected operations. Use shared wrappers: `authenticatedQuery`, `authenticatedMutation`, `superAdmin*`.
- Public functions accepting `userId` must call `requireAuthenticatedUserId(ctx, args.userId)`.
- Admin operations enforce role checks inside Convex, not only in Next.js pages or server actions.
- Prefer `internalQuery`/`internalMutation` for server-to-server work.

For custom JWT auth with Convex:
1. `convex/auth.config.ts` with issuer, JWKS, and audience.
2. Short-lived server-minted JWTs for server-side Convex clients.
3. A rotation-compatible JWKS endpoint.

## File Organization

```
convex/
├── lib/auth.ts               # Shared auth utilities
├── {domain}/
│   ├── queries.ts            # Public queries
│   ├── mutations.ts          # Public mutations
│   ├── internalQueries.ts    # Server-to-server only
│   ├── internalMutations.ts
│   ├── actions.ts            # External API calls
│   └── index.ts
├── schema.ts
└── _generated/
```

Reference internal functions as `internal.{domain}.internalQueries.fn`, not `.queries.`.

## Auth Utilities (`convex/lib/auth.ts`)

```typescript
export async function getAuthUser(ctx, requestedUserId?): Promise<Doc<"users"> | null>
export async function getAuthUserId(ctx, requestedUserId?): Promise<Id<"users"> | null>
export async function requireAuth(ctx, requestedUserId?): Promise<Doc<"users">>
export async function requireAuthUserId(ctx, requestedUserId?): Promise<Id<"users">>
export async function requireAuthenticatedUserId(ctx, requestedUserId?): Promise<Id<"users">>
export async function requireOwnership<T extends { userId: Id<"users"> }>(ctx, resource: T | null, name?): Promise<T>
export async function requirePremium(ctx): Promise<Doc<"users">>
export async function hasPremiumAccess(ctx): Promise<boolean>
```

## Frontend Hook (`src/hooks/use-auth-user.ts`)

```typescript
export function useAuthUser() {
  // { userId, user, isLoading, isAuthenticated, authArgs }
  // authArgs builds query args with userId, or returns "skip"
}
```

## Server-Side Filtering

Every list the UI shows comes from a query that already applied the view's filters. The component renders what it receives.

- Put each filter the view uses (status, date range, parent id, search text) in the query's `args` and apply it in the handler.
- Apply filters with `.withIndex()`. A `.collect()` followed by a JS `.filter()` still reads every row, even on the server.
- Run text search through a search index with `.withSearchIndex()`.
- Use `.paginate()` with `usePaginatedQuery` for any list that grows with usage. Keep `.collect()` for small, bounded sets.
- Map documents to the fields the view renders before returning. Other users' emails, internal flags, and tokens stay on the server.
- When a view needs a different subset, write a query for that subset rather than reusing a broader one.

## Query & Mutation Shape

```typescript
// Good: filter, paginate, and select fields inside the query
export const listGoalsByStatus = query({
  args: { userId: v.id("users"), status: goalStatus, paginationOpts: paginationOptsValidator },
  handler: async (ctx, args) => {
    const userId = await requireAuthenticatedUserId(ctx, args.userId);
    const result = await ctx.db
      .query("goals")
      .withIndex("by_userId_status", (q) => q.eq("userId", userId).eq("status", args.status))
      .paginate(args.paginationOpts);
    return { ...result, page: result.page.map(({ _id, title, status }) => ({ _id, title, status })) };
  },
});

// Good: filter by userId via index
export const getGoals = query({
  args: { userId: v.id("users") },
  handler: async (ctx, args) =>
    ctx.db.query("goals").withIndex("by_userId", (q) => q.eq("userId", args.userId)).collect(),
});

// Good: verify ownership before writing
export const updateGoal = mutation({
  args: { goalId: v.id("goals"), title: v.string() },
  handler: async (ctx, args) => {
    const goal = await ctx.db.get(args.goalId);
    await requireOwnership(ctx, goal, "Goal");
  },
});

// Bad: no userId filter, returns every row
export const getAllGoals = query({ handler: async (ctx) => ctx.db.query("goals").collect() });

// Bad: ships every goal to the client, which filters in the component
const goals = useQuery(api.goals.queries.getGoals, authArgs);
const active = goals?.filter((goal) => goal.status === "active");
```

## Required Security Tests

One negative authorization test per sensitive domain:
1. Mismatched `userId` is rejected.
2. Unauthenticated call is rejected.
3. Non-admin actor cannot reach admin-only paths.
