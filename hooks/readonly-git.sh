#!/usr/bin/env bash
# PreToolUse hook for Bash, declared in the frontmatter of read-only agents.
# Allows only plain `git status`, `git diff` and `git log` (optionally with
# `--no-pager`), blocks everything else. Fails closed: without jq, or with
# unreadable input, every Bash call is blocked.
set -uo pipefail

block() {
  echo "Blocked: this agent may only run 'git status', 'git diff' or 'git log' (no pipes, redirects or chained commands). $1" >&2
  exit 2
}

command -v jq >/dev/null 2>&1 || block "jq is not installed, so the command cannot be checked."

cmd="$(jq -r '.tool_input.command // empty' 2>/dev/null)" || block "Could not read the hook input."
[[ -n "$cmd" ]] || block "Empty command."

# One line, no shell metacharacters: no chaining, pipes, redirects, substitution.
case "$cmd" in
  *$'\n'* | *$'\r'* | *';'* | *'&'* | *'|'* | *'<'* | *'>'* | *'`'* | *'$'* | *'('* | *')'*)
    block "Got: $cmd"
    ;;
esac

# Options that write files or run external programs.
if grep -qE -- '(^|[[:space:]])(--output|--ext-diff|--textconv|-c|--exec-path|--git-dir|--work-tree)([=[:space:]]|$)' <<<"$cmd"; then
  block "Option not allowed. Got: $cmd"
fi

if grep -qE '^[[:space:]]*git([[:space:]]+--no-pager)?[[:space:]]+(status|diff|log)([[:space:]]|$)' <<<"$cmd"; then
  exit 0
fi

block "Got: $cmd"
