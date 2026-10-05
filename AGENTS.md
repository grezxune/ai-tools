# ai-tools

The rules and skills our coding agents load, shared between Claude Code and Codex. `scripts/install.sh` links them into the home directory, so an edit here changes every later session on that machine.

## Project notes

- `rules/AGENTS.md` loads in every session. Each line costs context on every turn, so a rule goes there only when it applies in every repo.
- A skill's `description` also loads in every session. Write what the skill is, then the cases that should trigger it, and nothing else.
- A skill that only runs by hand sets `disable-model-invocation: true` in its frontmatter, and `policy.allow_implicit_invocation: false` in `agents/openai.yaml` for Codex.
- Skills listed in `skills/SOURCES` are vendored and match upstream byte for byte. Change them with `scripts/update-skills.sh`, never by hand. Local rules go in another skill.
- Skills point at each other by relative path, such as `../prd/SKILL.md`, because the folder is linked into more than one place.
- Before writing or editing a skill or a rules file, read `skills/writing-for-agents/SKILL.md`.

## Code

- Scripts are bash, start with `set -euo pipefail`, and are safe to re-run.
- After changing a script, run `bash -n` on it, then run it once.
- When a skill is added, removed, or changes how it loads, update the tables in `README.md`.

## Security

- This repo is public. Keep secrets, tokens, client names, and machine-specific paths out of every file.
- After `scripts/update-skills.sh`, read `git diff skills` before committing. A skill is instructions an agent will follow.

## Git

- Conventional Commits: `feat:`, `fix:`, `chore:`, `refactor:`.
- No AI-assistant attribution in commit messages, PR descriptions, or code comments.
- Branch as `feature/{name}`. Squash before merging.
- Update `CHANGELOG.md` for meaningful changes.

## Docs

- Writing: plain prose in docs, PR descriptions, and skill text. No em dashes, no puffery, no filler. Say what a thing does.
