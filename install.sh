#!/usr/bin/env bash
# Links agents, skills and hooks from this repo into ~/.claude/.
# Safe to rerun: existing links into this repo are refreshed, anything else is
# left alone and reported.
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${CLAUDE_HOME:-$HOME/.claude}"

link() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    case "$(readlink "$dst")" in
      "$repo"/*) ln -sfn "$src" "$dst"; echo "updated  $dst" ;;
      *) echo "skipped  $dst (link to somewhere else)" ;;
    esac
  elif [[ -e "$dst" ]]; then
    echo "skipped  $dst (already exists)"
  else
    ln -s "$src" "$dst"; echo "linked   $dst"
  fi
}

mkdir -p "$target/agents" "$target/skills" "$target/hooks"

for f in "$repo"/agents/*.md; do link "$f" "$target/agents/$(basename "$f")"; done
for d in "$repo"/skills/*/; do d="${d%/}"; link "$d" "$target/skills/$(basename "$d")"; done
for f in "$repo"/hooks/*.sh; do chmod +x "$f"; link "$f" "$target/hooks/$(basename "$f")"; done

echo "Done. Project templates are in $repo/templates/project/ (copy them manually)."
