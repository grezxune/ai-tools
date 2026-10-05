---
name: new-project
description: Set up a new project repo, or align an existing repo with my standards.
---

# New projects

Every project carries its own copy of my rules, so a contributor or a cloud session without my setup follows the same engineering practices. My skills stay the source of truth. The project copy is a snapshot the project owns from then on, and project-specific rules get added to it as the project grows.

Paths that start with `../` are relative to this skill's folder.

## Files

- `AGENTS.md`: the condensed rules. Codex, Cursor, and most other agents read this file.
- `CLAUDE.md`: the single line `@AGENTS.md`, so Claude Code loads the same rules.
- `prds/README.md`: the body of `../prd/SKILL.md`, so contributors have the PRD template.
- `DESIGN.md` and `design/`, when the project has UI. Follow `../design-plan/SKILL.md`.
- `docs/convex.md`: the body of `../convex/SKILL.md`, when the project uses Convex.
- `CHANGELOG.md` with an empty `## Unreleased` section.

Copies drop the frontmatter, get the same edits as `AGENTS.md` (condensing rules below), and lose anything that doesn't fit the project: helpers, roles, and examples it doesn't have.

## Writing AGENTS.md

Condense `../standards/SKILL.md` and the Git section of my global rules into this structure:

```markdown
# {Project name}

{One or two sentences: what the product does and who uses it.}

## Stack
{The stack this project uses, one line each. Only what is installed or decided.}

## Project notes
{Facts a contributor can't get from reading the code: domain terms, non-obvious architecture, gotchas. Omit for a new project.}

## Code
## UI
## Security
## Git

## Docs
- PRDs: before building a feature, read its PRD in `prds/`. The template is in `prds/README.md`.
- Design: read `DESIGN.md` before changing UI.
- Convex: read `docs/convex.md` before changing schema, queries, mutations, or auth.
- Writing: plain prose in docs, PR descriptions, and UI copy. No em dashes, no puffery, no filler. Say what a thing does.
```

Condensing rules:

- One imperative line per rule. Keep a reason only when it changes how someone applies the rule.
- Write for any contributor. Every path points inside the repo, and the file says "we" or addresses the reader, never "me".
- Leave out sections and lines that don't apply: no UI section for a project without UI, no Stripe line without payments, no Convex line without Convex.
- Keep it under 80 lines.

## Existing projects

Read the project's current `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, `README.md`, and `DESIGN.md` or `UxStyle.md` first, then:

- Move `CLAUDE.md` content into `AGENTS.md` with `git mv`, and leave `CLAUDE.md` as `@AGENTS.md`.
- Move `UxStyle.md` to `DESIGN.md` the way `../design-plan/SKILL.md` describes.
- Where the project's docs already cover a topic in their own terms, such as a contributing guide or a Convex section with the project's helper names, add the missing rules to the matching section there. Skip copying a skill body that would contradict them.
- Create the files that are still missing.
- When a project rule conflicts with one of my rules, ask me which one wins. If a rewording lets both hold, use it and tell me.
- Next.js 16 `next dev` keeps a managed block at the end of `AGENTS.md`. Leave it there.
- Follow the project's own change process (branch, gate, changelog) for this change too.

## Done when

- Every rule in `../standards/SKILL.md` and the Git section of my global rules has a line in the project's `AGENTS.md`, or does not apply to this project.
- Nothing in the project's agent files points outside the repo or says "me".
- For an existing project, every project-specific rule from the old files still has a home.
