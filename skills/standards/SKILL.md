---
name: standards
description: Default stack, code, UI, and security rules. Use before writing app code in a repo with no AGENTS.md.
---

# Standards

My defaults for web apps. A repo's own `AGENTS.md` replaces them.

## Stack

- Package manager is bun.
- Next.js App Router only. Never create a `pages/` directory.
- Server components by default. Client components only where interactivity requires it.
- Give each entity state its own route: `create/`, `[id]/`, `[id]/update/`, `[id]/manage/`. Do not multiplex those states inside one route.
- Convex for data and file storage. Better Auth for auth, Google as the initial provider, joined to Convex through the `@convex-dev/better-auth` component. It replaced Auth.js, which gets only security fixes since September 2025. Stripe for payments, server-side only, Connect for multi-party payouts. Resend for email.

## Code

- Never use `@ts-nocheck`. Fix the types.
- Target 200 lines per file. Exceed it when splitting would hurt cohesion, and say why.
- Import everything explicitly.
- After every change, run build, typecheck, and lint for what you touched, plus targeted tests for the changed behavior. Never merge with failing tests.

## UI

Every app is built from its own component library, so a change to one component reaches every screen.

- Primitives live in `src/components/ui/` and own every class and token: layout (stack, row, grid, split), text and headings, controls, feedback, tables, and the app shell.
- Screens and domain components compose primitives. Outside `src/components/ui/`, lint fails `className`, `style`, and CSS imports with `react/forbid-dom-props`, `react/forbid-component-props`, and `no-restricted-imports`.
- Primitive props take named options such as `tone="muted"`, `columns="fields"`, or `gap={4}`, never raw classes or values.
- A missing piece becomes a new primitive or a new variant of one. A pattern that shows up twice becomes a primitive, and both uses move onto it.
- `/dev/ui` demos every shared component in each of its states, the way screens use it, and is a 404 outside development. A test fails when a component has no demo. A component and its demo change in the same commit.
- Tokens for color, type, spacing, radius, shadow, and motion live in `globals.css`. The repo's `DESIGN.md`, or `UxStyle.md` in an older repo, sets the direction and names the tokens.
- Every other rule in `globals.css` sits in a Tailwind layer: `@layer base` for element selectors such as `body > *`, `@layer components` for helper classes. A primitive's utility classes then always win. Unlayered CSS beats every layer, whatever its specificity.
- Support dark and light themes.
- Never use a scroll indicator, animated dots, or "scroll" hint text.
- Never use Tailwind's `!` important modifier. Fix the layout or hierarchy instead.
- Never use `alert()`, `confirm()`, or `prompt()`. Use the project's branded modal.

### Shell and scrolling

- The window scrolls the page, so `sticky` elements stick to the window.
- A sidebar is `sticky top-0 h-dvh` beside the main column. It fills the window's height and stays in place as the page scrolls. Its nav scrolls inside it when it runs long, and its footer stays pinned to the bottom.
- A header is `sticky top-0`. A sidebar under a header sticks just below it and fills the rest of the window's height.
- The page stays inside the window's width: layouts constrain themselves, and a wide table scrolls inside its own frame. Set `overflow-x: hidden` on `html` and `overflow-x: clip` on `body`. `hidden` on `body` makes the body its own scroll container, and every sticky element scrolls away with the page.
- `/dev/ui` draws inside the app shell, so the gallery is itself a page taller than the window. After changing the shell or `globals.css`, scroll it and check that the sidebar and header stay in place.

## Security

- No hardcoded secrets, keys, or credentials. Environment variables only.
- Validate tokens server-side. Never trust client state.
- Never trust a client-supplied `userId`, `email`, or `role` for authorization. Derive identity from the verified server session, then enforce ownership against stored records.
- Deny by default. Missing auth, missing ownership, or identity mismatch fails immediately.
- Filter on the server. Pass each view's filters, search, sort, and page as query arguments, and return only the rows and fields the current user needs for that view. A client never receives a full collection to filter, sort, or trim itself.
- Validate and sanitize untrusted input at every boundary: API, server actions, database writes, webhooks.
- Log errors with enough context to debug and no sensitive payloads.
