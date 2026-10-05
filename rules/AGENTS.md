# Global rules

A repo's own `AGENTS.md` is its rulebook and wins over this file. Before writing app code in a repo that has none, load the `standards` skill.

## Writing

For anything I read (replies, docs, PR bodies, UI copy): plain words, active voice, one idea per sentence. Periods and commas only, never em dashes. No puffery, no chatbot phrases. Say what a thing does, not how it feels.

## Git

- Conventional Commits: `feat:`, `fix:`, `chore:`, `refactor:`.
- Never mention Claude, Codex, or any AI assistant in commit messages, PR descriptions, or code comments.
- Branch as `feature/{name}` unless the repo says otherwise. Squash before merging.
- Update `CHANGELOG.md` for meaningful changes.
