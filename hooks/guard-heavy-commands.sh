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
#
# The command line is split on ; && || | & and newlines. A part is allowed when
# its first word (after env assignments) is the wrapper; any other part that
# matches a pattern is blocked. Mentioning the wrapper elsewhere does not count.
set -euo pipefail

conf="${CLAUDE_PROJECT_DIR:-.}/.claude/heavy-commands.conf"
[[ -f "$conf" ]] || exit 0

wrapper="$(sed -n 's/^wrapper=//p' "$conf" | head -n1)"
[[ -n "$wrapper" ]] || exit 0

patterns=()
while IFS= read -r pattern || [[ -n "$pattern" ]]; do
  pattern="${pattern%$'\r'}"
  [[ -z "$pattern" || "$pattern" == \#* || "$pattern" == wrapper=* ]] && continue
  patterns+=("$pattern")
done <"$conf"
[[ ${#patterns[@]} -gt 0 ]] || exit 0

matches_heavy() {
  local p
  for p in "${patterns[@]}"; do
    grep -qE -- "$p" <<<"$1" && return 0
  done
  return 1
}

input="$(cat)"

if ! command -v jq >/dev/null 2>&1; then
  # Cannot parse the command. Block only what looks heavy, and say why.
  if matches_heavy "$input"; then
    echo "Blocked: jq is not installed, so guard-heavy-commands.sh cannot check whether this heavy command runs through '${wrapper}'. Install jq, or ask the user." >&2
    exit 2
  fi
  exit 0
fi

cmd="$(jq -r '.tool_input.command // empty' <<<"$input")"
[[ -n "$cmd" ]] || exit 0

while IFS= read -r part; do
  # Drop leading whitespace, subshell/group openers and VAR=value assignments.
  part="$(sed -E 's/^[[:space:](){}]*//; s/^([A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*[[:space:]]+)*//' <<<"$part")"
  [[ -n "$part" ]] || continue
  first="${part%%[[:space:]]*}"
  [[ "$first" == "$wrapper" ]] && continue
  if matches_heavy "$part"; then
    echo "Blocked: heavy command must run through '${wrapper}' (see ${conf}). Example: ${wrapper} <dir> <command>" >&2
    exit 2
  fi
done < <(awk '{ gsub(/&&|\|\||;|\||&/, "\n"); print }' <<<"$cmd")

exit 0
