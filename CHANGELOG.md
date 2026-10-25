# Changelog

## Unreleased

- `standards` recommends Better Auth instead of Auth.js, which gets only security fixes since September 2025. `setup-hosting` says which Better Auth variables go in Convex and which in Vercel, and the Google callback address.
- `convex` sets up auth through the `@convex-dev/better-auth` component. Better Auth's tables live in the component, a trigger links each Better Auth user to a row in the app's `users` table by `authId`, and `getAuthUser()` checks the session itself, not only its token. The `getGoals` example now checks who is asking.
- Every app's UI is built from its own component library. Styles live only in `src/components/ui/`, lint keeps them out of screens, and `/dev/ui` shows every component. The global rules say so in one line, `standards` has the full setup, `new-project` creates it, and `design-plan` points at the gallery.
- First public version: the global rules file, eleven skills, and the install and update scripts.
