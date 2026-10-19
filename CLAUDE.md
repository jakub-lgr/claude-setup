# claude-setup

A public, general-purpose Claude Code setup: a small set of agents, skills and hooks that work in any project. This file holds the rules for working on this repo itself.

## Principles

These are settled. Do not change them without the owner's explicit approval.

1. **Agents are generic, rules live in the project.** Every agent first reads the `CLAUDE.md` / `AGENTS.md` of the project it runs in and follows it. No agent hardcodes a stack, package manager, test framework or database.
2. **Two layers.**
   - **Global**: this repo, installed into `~/.claude/` and kept in sync across machines through git and `install.sh`.
   - **Project**: `.claude/` inside each project repo. A project agent with the same name overrides the global one.
3. **Few agents, used on purpose.** Every agent's description is loaded into every session, so each extra agent costs context. Add an agent only when it will really be used. Prefer explicit calls over "use proactively" descriptions.
4. **Cheap models for cheap work.** Opus plans (as a subagent, so the main session stays on Sonnet and never switches models), Sonnet implements and reviews, Haiku searches. Every agent sets both `model` and `effort`.
5. **Review agents are read-only.** They get only read tools. If they have Bash, it is limited to `git status`, `git diff` and `git log`.
6. **Reuse from ECC is allowed, with attribution.** [affaan-m/ecc](https://github.com/affaan-m/ecc) (MIT) is the main source of inspiration. Its files may be copied as they are, copied and adapted, or used only as an idea. Every copied or adapted file must:
   - be adapted to principles 1 to 5 (generic, reads project rules, explicit `model` and `effort`, no stack assumptions such as npm, eslint, jest or PostgreSQL, no "MUST BE USED" / "PROACTIVELY" descriptions unless intended);
   - keep a note at the top saying where it came from (ECC path and commit);
   - be listed in `UPSTREAM.md` (ECC path, commit, status: copied / adapted).

   ECC's license is reproduced in `THIRD_PARTY_NOTICES.md`. A few ECC subfolders carry their own license; check it before taking anything from them.

## Rules for this repo

- **Public repo.** Everything is in English and generic. No names, private projects, servers, domains, local paths or secrets, not even in examples.
- **No pushing or creating anything on GitHub** without the owner's explicit instruction.
- **Test after changing `install.sh` or a hook:** `bash -n` on the script, then a run with a sample config in a temporary folder (`CLAUDE_HOME=<tmp> ./install.sh`, `CLAUDE_PROJECT_DIR=<tmp>` for hooks). Never install into the real `~/.claude` without asking.
- Shell scripts must use LF line endings and work in bash on Linux, macOS and Git Bash on Windows.

## Layout

```
agents/      global subagents (Markdown + frontmatter)
skills/      global skills (one folder per skill, SKILL.md inside)
hooks/       hook scripts, enabled per project via settings.json
templates/   starting files for a new project (.claude/, CLAUDE.md)
install.sh   links agents/, skills/ and hooks/ into ~/.claude/
UPSTREAM.md            every file copied, adapted or inspired from elsewhere
THIRD_PARTY_NOTICES.md license texts of those sources
```

## Notes

- `skills/ecc-router/catalog.md` is generated. Do not edit it by hand: update the local ECC archive, run `python skills/ecc-router/build-catalog.py`, and update the commit in `UPSTREAM.md`.
- `ecc-router` is manual only (`disable-model-invocation: true`). It suggests ECC items, waits for the user's confirmation and uses them in the current session only. Keep it that way.
- Third-party skills or plugins are added only when their license allows it, with their license text in `THIRD_PARTY_NOTICES.md` and an entry in `UPSTREAM.md`.
- The repo is public and marked work in progress. Keep `README.md` (status, agents, skills, known issues) in sync with every change.
