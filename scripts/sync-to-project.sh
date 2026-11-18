#!/usr/bin/env bash
# Copies chosen bundles into a project's .claude/skills/, so the project carries
# its skills with it (cloud sessions, other machines, no global install needed).
# What was copied is recorded in <project>/.claude/claude-setup.lock, and a rerun
# without bundle names updates exactly the bundles listed there.
#
# Bundles come from plugins/<bundle>/skills in this repo (as checked out here, so
# git pull first) or, for bundles listed in external-bundles.conf, from their own
# repository. Skills the project has of its own are never touched.
#
# Works in bash on Linux, macOS and Git Bash on Windows. Needs git.
#
#   scripts/sync-to-project.sh <project> <bundle>...          add or update these bundles
#   scripts/sync-to-project.sh <project>                      update all bundles in the lock
#   scripts/sync-to-project.sh --remove <project> <bundle>... remove these bundles
#   scripts/sync-to-project.sh --list                         list available bundles
#   --dry-run                                                 only print what would happen
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ext_conf="$root/scripts/external-bundles.conf"

dry=0 remove=0 list=0
args=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry=1 ;;
    --remove) remove=1 ;;
    --list) list=1 ;;
    -h|--help) sed -n '2,19p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0 ;;
    -*) echo "unknown option: $arg" >&2; exit 2 ;;
    *) args+=("$arg") ;;
  esac
done

local_bundles() { for d in "$root"/plugins/*/skills; do [[ -d "$d" ]] && basename "$(dirname "$d")"; done; }
ext_line() { tr -d '\r' <"$ext_conf" | { grep -E "^$1 " || true; } | head -1; }
ext_bundles() { tr -d '\r' <"$ext_conf" | grep -vE '^\s*(#|$)' | awk '{print $1}'; }

if [[ $list == 1 ]]; then
  echo "In this repo:"; local_bundles | sed 's/^/  /'
  echo "External:"; ext_bundles | sed 's/^/  /'
  exit 0
fi

if [[ ${#args[@]} -lt 1 ]]; then
  echo "usage: sync-to-project.sh [--dry-run] [--remove] <project> [bundle...]   (--help for more)" >&2
  exit 2
fi
project="${args[0]}"
bundles=()
for a in "${args[@]:1}"; do bundles+=("$a"); done
if [[ ! -d "$project" ]]; then echo "error: $project is not a folder" >&2; exit 1; fi
project="$(cd "$project" && pwd)"
if [[ "$project" == "$root" ]]; then echo "error: the project is this repo itself" >&2; exit 1; fi

skills="$project/.claude/skills"
lock="$project/.claude/claude-setup.lock"

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Lock format, one line per bundle: <bundle> <source> <commit> <skill>...
old_lock="$tmp/old-lock"
if [[ -f "$lock" ]]; then tr -d '\r' <"$lock" | grep -vE '^\s*(#|$)' >"$old_lock" || true; else : >"$old_lock"; fi
lock_skills() { { grep -E "^$1 " "$old_lock" || true; } | head -1 | cut -d' ' -f4-; } # <bundle>
owner_of() { awk -v s="$2" -v b="$1" '$1 != b { for (i = 4; i <= NF; i++) if ($i == s) print $1 }' "$old_lock" | head -1; } # <bundle> <skill>

if [[ ${#bundles[@]} -eq 0 ]]; then
  # macOS ships bash 3.2: no mapfile, and empty arrays need care under set -u.
  if [[ $remove == 1 ]]; then echo "error: name the bundles to remove" >&2; exit 2; fi
  while read -r b _; do bundles+=("$b"); done <"$old_lock"
  if [[ ${#bundles[@]} -eq 0 ]]; then
    echo "Nothing to update: $project has no .claude/claude-setup.lock yet. Name the bundles to add." >&2
    exit 1
  fi
fi

run() { if [[ $dry == 1 ]]; then echo "+ $*"; else "$@"; fi; }
new_lines="$tmp/new-lines"
: >"$new_lines"
done_bundles=" "

for b in "${bundles[@]}"; do
  [[ "$done_bundles" == *" $b "* ]] && continue
  done_bundles+="$b "
  old_skills="$(lock_skills "$b")"

  if [[ $remove == 1 ]]; then
    if ! grep -qE "^$b " "$old_lock"; then echo "skip    $b is not in this project"; continue; fi
    for s in $old_skills; do run rm -rf "$skills/$s"; done
    echo "removed $b"
    continue
  fi

  # Resolve the bundle's source folder.
  rewrite=""
  if [[ -d "$root/plugins/$b/skills" ]]; then
    src="$root/plugins/$b/skills"
    source="local"
    commit="$(git -C "$root" rev-parse --short=12 HEAD 2>/dev/null || echo unknown)"
    license="$root/LICENSE"
    if [[ -n "$(git -C "$root" status --porcelain -- "plugins/$b" 2>/dev/null)" ]]; then
      echo "note    plugins/$b has uncommitted changes, copying them as they are"
    fi
  elif line="$(ext_line "$b")" && [[ -n "$line" ]]; then
    read -r _ repo ref path <<<"$line"
    dir="$tmp/src/$b"
    git clone --quiet --filter=blob:none --no-checkout "https://github.com/$repo.git" "$dir"
    git -C "$dir" -c advice.detachedHead=false checkout --quiet "$ref"
    src="$dir/$path"
    source="$repo"
    commit="$(git -C "$dir" rev-parse --short=12 HEAD)"
    license="$(ls "$dir"/LICENSE* "$dir"/LICENCE* 2>/dev/null | head -1 || true)"
    # Plugin skills address their files through ${CLAUDE_PLUGIN_ROOT}, which is not
    # set for project skills. Point those paths at the project's .claude/skills/.
    rewrite="\${CLAUDE_PLUGIN_ROOT}/${path%/}/"
  else
    echo "error: unknown bundle '$b' (see --list)" >&2
    exit 1
  fi

  new_skills=()
  for d in "$src"/*/; do [[ -f "$d/SKILL.md" ]] && new_skills+=("$(basename "$d")"); done
  if [[ ${#new_skills[@]} -eq 0 ]]; then echo "error: bundle $b has no skills in $src" >&2; exit 1; fi

  # Never overwrite a skill that belongs to the project or to another bundle.
  for s in "${new_skills[@]}"; do
    other="$(owner_of "$b" "$s")"
    if [[ -n "$other" ]]; then
      echo "error: skill $s from $b is already in this project from bundle $other" >&2; exit 1
    fi
    if [[ -e "$skills/$s" && " $old_skills " != *" $s "* ]]; then
      echo "error: .claude/skills/$s already exists and is not from bundle $b, refusing to overwrite" >&2; exit 1
    fi
  done

  for s in $old_skills; do [[ -e "$skills/$s" ]] && run rm -rf "$skills/$s"; done
  [[ $dry == 1 ]] || mkdir -p "$skills"
  for s in "${new_skills[@]}"; do
    run cp -R "$src/$s" "$skills/$s"
    [[ $dry == 1 ]] && continue
    if [[ ! -f "$skills/$s/LICENSE" && -n "$license" && -f "$license" ]]; then cp "$license" "$skills/$s/LICENSE"; fi
    if [[ -n "$rewrite" ]]; then
      while IFS= read -r -d '' f; do
        if grep -qF "$rewrite" "$f"; then
          sed "s#$(printf '%s' "$rewrite" | sed 's/[$.*/[\^]/\\&/g')#.claude/skills/#g" "$f" >"$f.tmp" && mv "$f.tmp" "$f"
        fi
      done < <(find "$skills/$s" -type f -name '*.md' -print0)
    fi
  done
  echo "$b $source $commit ${new_skills[*]}" >>"$new_lines"
  echo "synced  $b  (${#new_skills[@]} skills, $source@$commit)"
done

[[ $dry == 1 ]] && { echo "Dry run, nothing changed."; exit 0; }

# Write the lock: untouched bundles keep their line, synced ones get the new one.
{
  echo "# Generated by claude-setup scripts/sync-to-project.sh. Do not edit."
  echo "# Update: <claude-setup>/scripts/sync-to-project.sh <this project>"
  echo "# bundle source commit skills..."
  while read -r line; do
    b="${line%% *}"
    [[ "$done_bundles" == *" $b "* ]] || echo "$line"
  done <"$old_lock"
  cat "$new_lines"
} >"$tmp/lock"
if grep -qvE '^#' "$tmp/lock"; then
  mkdir -p "$project/.claude"
  mv "$tmp/lock" "$lock"
else
  rm -f "$lock"
fi
echo "Done. Start a new session in the project if the skills do not show up."
