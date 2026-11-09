# Changelog

## Unreleased

- `standards` keeps sticky sidebars and headers in place: the window scrolls the page, `body` clips with `overflow-x: clip` instead of `hidden`, and every other rule in `globals.css` sits in a Tailwind layer. `new-project` checks that `/dev/ui` keeps its sidebar and header when scrolled.
- The global rules offer to move a new domain's nameservers to Vercel, so its DNS is managed through the Vercel API. It is an offer, never a requirement. `setup-hosting` makes the same offer before falling back to A and CNAME records.
- `standards` recommends Better Auth instead of Auth.js, which gets only security fixes since September 2025. `setup-hosting` says which Better Auth variables go in Convex and which in Vercel, and the Google callback address.
- `convex` sets up auth through the `@convex-dev/better-auth` component. Better Auth's tables live in the component, a trigger links each Better Auth user to a row in the app's `users` table by `authId`, and `getAuthUser()` checks the session itself, not only its token. The `getGoals` example now checks who is asking.
- Every app's UI is built from its own component library. Styles live only in `src/components/ui/`, lint keeps them out of screens, and `/dev/ui` shows every component. The global rules say so in one line, `standards` has the full setup, `new-project` creates it, and `design-plan` points at the gallery.
- First public version: the global rules file, eleven skills, and the install and update scripts.
