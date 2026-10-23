# Global rules

A repo's own `AGENTS.md` is its rulebook and wins over this file. Before writing app code in a repo that has none, load the `standards` skill.

## Writing

For anything I read (replies, docs, PR bodies, UI copy): plain words, active voice, one idea per sentence. Periods and commas only, never em dashes. No puffery, no chatbot phrases. Say what a thing does, not how it feels.

## UI

Build every app's UI from its own component library: styles live only in `src/components/ui/`, screens compose those components with no `className` or `style`, and `/dev/ui` shows every one. The `standards` skill has the full setup.

## Git

- Conventional Commits: `feat:`, `fix:`, `chore:`, `refactor:`.
- Branch as `feature/{name}` unless the repo says otherwise. Squash before merging.
- Update `CHANGELOG.md` for meaningful changes.
