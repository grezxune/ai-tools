#!/usr/bin/env bash
# Re-pull every vendored skill in skills/SOURCES at its upstream HEAD.
# Replaces those skill folders in the working tree and updates the pinned commits.
# Nothing is committed: review `git diff skills`, then commit.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS="$REPO/skills"
SOURCES="$SKILLS/SOURCES"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

rows=""
while read -r name repo path _; do
  case "$name" in "" | \#*) continue ;; esac

  if [[ ! "$name" =~ ^[a-z0-9-]+$ ]]; then
    echo "bad skill name in SOURCES: $name" >&2
    exit 1
  fi

  clone="$WORK/${repo//\//__}"
  if [ ! -d "$clone" ]; then
    git clone --quiet --depth 1 --filter=blob:none --sparse "https://github.com/$repo.git" "$clone"
  fi
  git -C "$clone" sparse-checkout add "$path"

  if [ ! -f "$clone/$path/SKILL.md" ]; then
    echo "$name: $repo has no $path/SKILL.md" >&2
    exit 1
  fi

  rm -rf "${SKILLS:?}/$name"
  cp -R "$clone/$path" "$SKILLS/$name"

  commit="$(git -C "$clone" rev-parse --short HEAD)"
  rows+="$(printf '%-20s %-36s %-50s %s' "$name" "$repo" "$path" "$commit")"$'\n'
  echo "pulled  $name @ $commit"
done < "$SOURCES"

{
  grep '^#' "$SOURCES"
  printf '%s' "$rows"
} > "$SOURCES.tmp"
mv "$SOURCES.tmp" "$SOURCES"

echo
git -C "$REPO" status --short skills
