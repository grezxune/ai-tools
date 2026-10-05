#!/usr/bin/env bash
# Link the rules and skills in this repo into $HOME for Claude Code and Codex.
# Safe to re-run. A real file or directory at a destination is moved to
# <dest>.bak.<timestamp> before the link is made.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# source (relative to repo) : destination
LINKS=(
  "rules/AGENTS.md:$HOME/.claude/CLAUDE.md"
  "rules/AGENTS.md:$HOME/.codex/AGENTS.md"
  "skills:$HOME/.claude/skills"
  "skills:$HOME/.agents/skills"
)

link() {
  local source="$REPO/$1" dest="$2"

  if [ ! -e "$source" ]; then
    echo "skip    $1 (missing in repo)"
    return
  fi

  # Compare the link itself, not where it resolves, so a link that reaches
  # the source through another link gets replaced with a direct one.
  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$source" ]; then
    echo "ok      $dest"
    return
  fi

  mkdir -p "$(dirname "$dest")"
  if [ -L "$dest" ]; then
    rm "$dest"
  elif [ -e "$dest" ]; then
    local backup
    backup="$dest.bak.$(date +%Y%m%d%H%M%S)"
    mv "$dest" "$backup"
    echo "backup  $dest -> $backup"
  fi

  ln -s "$source" "$dest"
  echo "linked  $dest -> $source"
}

for entry in "${LINKS[@]}"; do
  link "${entry%%:*}" "${entry#*:}"
done
