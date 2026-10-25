---
name: convex
description: Convex patterns for schema, queries, mutations, and auth. Use before writing or reviewing Convex code in a repo with no `docs/convex.md`.
---

# Convex Patterns

Read this before writing or reviewing Convex schema, queries, mutations, actions, or auth.

## Auth Setup

Better Auth runs inside Convex through the `@convex-dev/better-auth` component. Follow the component's Next.js guide (https://labs.convex.dev/better-auth/framework-guides/next) for the files, with these rules on top:

- Pin `better-auth` to the range in the component's `peerDependencies`. Component 0.12 needs `better-auth` 1.6.x, and its guide pins `~1.6.15`.
- The auth instance runs in Convex, so `BETTER_AUTH_SECRET`, `SITE_URL`, and OAuth credentials such as `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` are Convex environment variables, set with `npx convex env set` or the dashboard. `.env.local` holds only `CONVEX_DEPLOYMENT`, `NEXT_PUBLIC_CONVEX_URL`, `NEXT_PUBLIC_CONVEX_SITE_URL` (the `.convex.site` address), and `NEXT_PUBLIC_SITE_URL`.
- Google's authorized redirect URI is `<SITE_URL>/api/auth/callback/google`. Next.js serves `/api/auth/*` and forwards it to Convex.
- Better Auth's tables (`user`, `session`, `account`) live in the component, outside the app schema. The app keeps its own `users` table, linked by `authId` (next section).

## User IDs & Data Ownership

- Every person has a row in the app's `users` table with `authId: v.string()`, the Better Auth user's `_id`, and a `by_authId` index. A `user.onCreate` trigger creates the row in the same transaction as the Better Auth user. `onUpdate` copies a changed email or name, and `onDelete` removes the row, or marks it deleted while other tables still point at it.
- Use `userId: v.id("users")` as the ownership field on every user-owned table.
- Never use email as a foreign key. Email lives only on the `users` table, copied there by the trigger.
- Never join or filter across tables by email. Use `userId`.
- Every table with a `userId` field needs a `by_userId` index.
- Use compound indexes for common filters, e.g. `by_userId_status`.
- The `by_authId` index exists only for `getAuthUser()`, which turns the session into the app user. After that, use `user._id`.

```typescript
// convex/auth.ts
import { createClient, type AuthFunctions } from "@convex-dev/better-auth";
import { components, internal } from "./_generated/api";
import type { DataModel } from "./_generated/dataModel";

const authFunctions: AuthFunctions = internal.auth;

export const authComponent = createClient<DataModel>(components.betterAuth, {
  authFunctions,
  triggers: {
    user: {
      onCreate: async (ctx, authUser) => {
        await ctx.db.insert("users", { authId: authUser._id, email: authUser.email, name: authUser.name });
      },
    },
  },
});

export const { onCreate, onUpdate, onDelete } = authComponent.triggersApi();
```

## Authorization (non-negotiable)

Never trust client-supplied `userId`, `email`, `role`, or `platformRole` for authorization.

Identity comes from the session, checked inside Convex:
- `authComponent.safeGetAuthUser(ctx)` returns the Better Auth user when the session exists and has not expired, and `undefined` otherwise. `authComponent.getAuthUser(ctx)` throws `ConvexError("Unauthenticated")` instead.
- `ctx.auth.getUserIdentity()` reads the JWT only. A signed-out or revoked session keeps a valid JWT until it expires, so reach identity through the helpers in `convex/lib/auth.ts`, which go through `safeGetAuthUser`.

Every public Convex query/mutation that accepts `userId` must:
1. Resolve the actor with `requireAuthenticatedUserId(ctx, args.userId)`, which maps the session to the app user and rejects a mismatch.
2. Enforce ownership and role checks in Convex against stored records.

Deny by default: missing auth, missing ownership, or identity mismatch fails immediately. No deterministic or default secret/key fallbacks in production. Development-only auth providers must be disabled in production builds.

## Enforcement Pattern

- Do not use raw `query`/`mutation` for protected operations. Use shared wrappers: `authenticatedQuery`, `authenticatedMutation`, `superAdmin*`.
- Admin operations enforce role checks inside Convex, not only in Next.js pages or server actions.
- Server components and server actions call Convex through `fetchAuthQuery`, `fetchAuthMutation`, `fetchAuthAction`, and `preloadAuthQuery` from `src/lib/auth-server.ts`, which carry the session's token. The Convex function still runs its own checks.
- Prefer `internalQuery`/`internalMutation` for server-to-server work.

## File Organization

```
convex/
├── convex.config.ts          # app.use(betterAuth)
├── auth.config.ts            # providers: [getAuthConfigProvider()]
├── auth.ts                   # authComponent, createAuth, triggers
├── http.ts                   # authComponent.registerRoutes(http, createAuth)
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
src/lib/
├── auth-server.ts            # convexBetterAuthNextJs(): handler, getToken, fetchAuth*
└── auth-client.ts            # createAuthClient({ plugins: [convexClient()] })
src/app/api/auth/[...all]/route.ts   # export const { GET, POST } = handler
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

Every helper builds on `getAuthUser()`, the one place a session becomes an app user:

```typescript
export async function getAuthUser(ctx: QueryCtx | MutationCtx, requestedUserId?: Id<"users">): Promise<Doc<"users"> | null> {
  const authUser = await authComponent.safeGetAuthUser(ctx);
  if (!authUser) return null;
  const user = await ctx.db.query("users").withIndex("by_authId", (q) => q.eq("authId", authUser._id)).unique();
  if (!user || (requestedUserId !== undefined && requestedUserId !== user._id)) return null;
  return user;
}
```

## Frontend Hook (`src/hooks/use-auth-user.ts`)

```typescript
export function useAuthUser() {
  // { userId, user, isLoading, isAuthenticated, authArgs }
  // authArgs builds query args with userId, or returns "skip"
}
```

Gate on Convex's auth state: `<Authenticated>`, `<Unauthenticated>`, `<AuthLoading>`, or `useConvexAuth()`. Better Auth's `useSession()` can report a signed-in user before Convex has the token, and an authenticated query run then throws.

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

// Good: authenticate, then filter by userId via index
export const getGoals = query({
  args: { userId: v.id("users") },
  handler: async (ctx, args) => {
    const userId = await requireAuthenticatedUserId(ctx, args.userId);
    return ctx.db.query("goals").withIndex("by_userId", (q) => q.eq("userId", userId)).collect();
  },
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
4. An identity whose session was signed out or expired is rejected.
