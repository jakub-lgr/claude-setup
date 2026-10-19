#!/usr/bin/env bash
# Installs the Claude Code plugins this setup uses, plus the command-line tools
# two of them need:
#
#   frontend-design  (Anthropic)            plugin
#   ui-ux-pro-max    (nextlevelbuilder)     plugin, needs Python 3
#   codex            (OpenAI)               plugin, needs the Codex CLI and a login
#   skillspector     (NVIDIA)               CLI for the skill-inspector skill
#
# Safe to rerun: anything already installed is left as it is.
# Works in bash on Linux, macOS and Git Bash on Windows.
#
#   scripts/install-plugins.sh             install everything
#   scripts/install-plugins.sh --dry-run   only print what would run
#   --skip-codex, --skip-skillspector      leave those parts out
set -uo pipefail

dry=0 codex=1 spector=1
for arg in "$@"; do
  case "$arg" in
    --dry-run) dry=1 ;;
    --skip-codex) codex=0 ;;
    --skip-skillspector) spector=0 ;;
    *) echo "unknown option: $arg" >&2; exit 2 ;;
  esac
done

failed=0
run() {
  echo "+ $*"
  [[ $dry == 1 ]] && return 0
  "$@" || { echo "  failed: $*" >&2; failed=1; return 1; }
}
has() { command -v "$1" >/dev/null 2>&1; }
windows() { case "$(uname -s)" in MINGW*|MSYS*|CYGWIN*) return 0 ;; *) return 1 ;; esac; }

if ! has claude; then
  echo "error: the claude command is not on PATH. Install Claude Code first." >&2
  exit 1
fi

# --- Plugins -------------------------------------------------------------------
marketplaces="$(claude plugin marketplace list 2>/dev/null || true)"
add_marketplace() { # <name> <github repo>
  if grep -q "$1" <<<"$marketplaces"; then echo "ok     marketplace $1"; else run claude plugin marketplace add "$2"; fi
}
installed="$(claude plugin list 2>/dev/null || true)"
install_plugin() { # <plugin@marketplace>
  if grep -q "${1%@*}" <<<"$installed"; then echo "ok     plugin $1"; else run claude plugin install "$1"; fi
}

add_marketplace claude-plugins-official anthropics/claude-plugins-official
install_plugin frontend-design@claude-plugins-official

add_marketplace ui-ux-pro-max-skill nextlevelbuilder/ui-ux-pro-max-skill
install_plugin ui-ux-pro-max@ui-ux-pro-max-skill
has python3 || has python || echo "note   ui-ux-pro-max needs Python 3 for its search scripts."

if [[ $codex == 1 ]]; then
  add_marketplace openai-codex openai/codex-plugin-cc
  install_plugin codex@openai-codex

  # The plugin calls the Codex CLI, which needs its own login.
  if has codex; then
    echo "ok     codex CLI $(codex --version 2>/dev/null)"
  elif has npm; then
    run npm install -g @openai/codex
  else
    echo "note   install Node.js, then run: npm install -g @openai/codex" >&2
  fi
  echo "note   if you have not logged in to Codex yet, run once: codex login"
fi

# --- skillspector CLI for the skill-inspector skill ----------------------------
if [[ $spector == 1 ]]; then
  if has skillspector; then
    echo "ok     $(skillspector --version 2>/dev/null)"
  else
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
  fi
fi

echo
if [[ $failed == 1 ]]; then
  echo "Finished with errors, see above." >&2
  exit 1
fi
echo "Done. Start a new Claude Code session so the plugins are loaded."
