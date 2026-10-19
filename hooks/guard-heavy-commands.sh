#!/usr/bin/env bash
# PreToolUse hook for Bash: blocks heavy commands that do not run through the
# project's wrapper. Configured per project in .claude/heavy-commands.conf:
#
#   wrapper=my-heavy-wrapper
#   \bpnpm (build|test|check)\b
#   \bvitest\b
#
# First "wrapper=" line names the wrapper, every other non-empty, non-comment
# line is an extended regex. No config file = hook does nothing.
set -euo pipefail

conf="${CLAUDE_PROJECT_DIR:-.}/.claude/heavy-commands.conf"
[[ -f "$conf" ]] || exit 0

cmd="$(jq -r '.tool_input.command // empty')"
[[ -n "$cmd" ]] || exit 0

wrapper="$(sed -n 's/^wrapper=//p' "$conf" | head -n1)"
[[ -n "$wrapper" ]] || exit 0

# Already wrapped: allow.
if grep -qE "(^|[;&|[:space:]])${wrapper}([[:space:]]|$)" <<<"$cmd"; then
  exit 0
fi

while IFS= read -r pattern; do
  [[ -z "$pattern" || "$pattern" == \#* || "$pattern" == wrapper=* ]] && continue
  if grep -qE -- "$pattern" <<<"$cmd"; then
    echo "Blocked: heavy command must run through '${wrapper}' (see ${conf}). Example: ${wrapper} <dir> <command>" >&2
    exit 2
  fi
done <"$conf"

exit 0
