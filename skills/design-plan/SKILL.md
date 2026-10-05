---
name: design-plan
description: Per-project design plan, `DESIGN.md` plus the `design/` folder. Use when setting or changing a design direction, or before UI work in a repo with no `DESIGN.md` or `UxStyle.md`.
---

# Design plan

Every project with UI keeps one design plan. It sets the direction for the life of the project, and a change to it takes effect immediately.

## Layout

```
DESIGN.md              the plan. Read before UI work. 80 lines at most.
design/
├── assets/            logo, wordmark, favicon source, illustrations
├── references/        screenshots and inspiration
├── mockups/           approved mockup per screen
└── decisions.md       dated decisions, one line each. Read when asked why.
src/app/globals.css    token values for both themes
```

Create a `design/` subfolder when its first file arrives.

## Single source

- Token values live in `globals.css`. `DESIGN.md` names each token and says when to use it.
- Component specs live in the component code. `DESIGN.md` lists each shared component with its path.
- Every file under `design/` gets one line in the Artifacts section saying what to take from it. Open an artifact only when the task needs it.

## Writing DESIGN.md

Start from the direction I give, and ask for one if I haven't given it. When the `frontend-design` skill produces a design plan, the approved plan becomes this file.

Keep these sections in this order, which is the DESIGN.md format other tools read. Leave out a section that would be empty.

```markdown
# {Project} design

## Overview
{Who it is for, the feel, and what it must never look like. Five to eight lines.}

## Colors
{Each color token by name and role, for both themes.}

## Typography
{The faces, their roles, and the scale names. The faces are a do-not-swap set.}

## Layout
{Breakpoints, spacing rhythm, page anatomy.}

## Components
{Each shared component: name, path, when to use it.}

## Do's and Don'ts
{The quality bar lines that apply, plus this project's own rules.}

## Artifacts
- `design/assets/logo.svg`: primary mark.
```

## Type

Choose faces with a point of view and pair them on purpose. These faces read as generated, so pick others: Inter, Manrope, Space Grotesk, Plus Jakarta Sans, DM Sans, DM Mono, JetBrains Mono, Instrument Serif, Instrument Sans, Fraunces, Playfair Display, Geist.

## Quality bar

Contributors only have the repo, so the lines that apply go into the project's Do's and Don'ts.

- Use the design tokens for color, type scale, spacing, radius, shadow, and motion. No ad hoc values.
- Present a distinct visual direction tied to the brand, not a default SaaS template.
- Build every interaction state for key flows: loading, empty, error, success, disabled, hover, focus, active.
- Motion is intentional and performant, and respects reduced-motion preferences.
- Meet WCAG 2.1 AA for contrast, keyboard navigation, and semantic structure.
- Design mobile, tablet, and desktop breakpoints deliberately.
- Show screenshots or equivalent visual proof for major UI changes before sign-off.
- When a UI pattern repeats, extract a component and move existing inline usage onto it.
- Keep the brand mark visible in primary navigation at every breakpoint.
- On small screens, an accessible menu toggle opens a right-side overlay with keyboard support.
- One shared branded modal replaces `alert()`, `confirm()`, and `prompt()`. It supports both themes and manages focus, keyboard navigation, and ARIA attributes.

## Moving an older repo

For a repo with `UxStyle.md`:

1. `git mv UxStyle.md DESIGN.md`, then reorder it into the sections above.
2. Cut every value and spec that restates the code.
3. Move loose design files into `design/` and index them under Artifacts.
4. Point the repo's `AGENTS.md` at `DESIGN.md`.

Done when `DESIGN.md` is 80 lines or fewer and every project-specific rule from the old file still has a home.
