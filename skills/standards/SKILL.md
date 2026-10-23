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
- Auth.js for auth, Google as the initial provider. Convex for data and file storage. Stripe for payments, server-side only, Connect for multi-party payouts. Resend for email.

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
- Support dark and light themes.
- Never use a scroll indicator, animated dots, or "scroll" hint text.
- Never allow horizontal page scroll. Constrain layouts and set `overflow-x: hidden` at the root.
- Never use Tailwind's `!` important modifier. Fix the layout or hierarchy instead.
- Never use `alert()`, `confirm()`, or `prompt()`. Use the project's branded modal.

## Security

- No hardcoded secrets, keys, or credentials. Environment variables only.
- Validate tokens server-side. Never trust client state.
- Never trust a client-supplied `userId`, `email`, or `role` for authorization. Derive identity from the verified server session, then enforce ownership against stored records.
- Deny by default. Missing auth, missing ownership, or identity mismatch fails immediately.
- Filter on the server. Pass each view's filters, search, sort, and page as query arguments, and return only the rows and fields the current user needs for that view. A client never receives a full collection to filter, sort, or trim itself.
- Validate and sanitize untrusted input at every boundary: API, server actions, database writes, webhooks.
- Log errors with enough context to debug and no sensitive payloads.
