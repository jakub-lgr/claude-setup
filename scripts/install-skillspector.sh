#!/usr/bin/env bash
# Installs the skillspector CLI that the skill-inspector skill (core plugin) uses
# for full scans. Without it the skill still does its source-aware review.
#
# Safe to rerun: does nothing if skillspector is already on PATH.
# Works in bash on Linux, macOS and Git Bash on Windows.
#
#   scripts/install-skillspector.sh             install
#   scripts/install-skillspector.sh --dry-run   only print what would run
set -uo pipefail

dry=0
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry=1 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

run() {
  echo "+ $*"
  [[ $dry == 1 ]] && return 0
  "$@" || { echo "  failed: $*" >&2; exit 1; }
}
has() { command -v "$1" >/dev/null 2>&1; }
windows() { case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) return 0 ;; *) return 1 ;; esac; }

if has skillspector; then
  echo "ok     $(skillspector --version 2>/dev/null)"
  exit 0
fi

if ! has uv; then
  if windows; then
    run powershell -NoProfile -ExecutionPolicy Bypass -Command "irm https://astral.sh/uv/install.ps1 | iex"
  else
    run sh -c "curl -LsSf https://astral.sh/uv/install.sh | sh"
  fi
  export PATH="$HOME/.local/bin:$PATH"
fi

# Python 3.12: yara-python has no prebuilt wheel for newer versions on Windows.
# uv downloads Python 3.12 by itself if it is missing.
run uv tool install --python 3.12 git+https://github.com/NVIDIA/skillspector.git
echo "Done."
