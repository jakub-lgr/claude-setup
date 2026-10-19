# claude-setup

A small, personal Claude Code setup: a handful of general-purpose agents, skills and hooks that work in any project.

> **Status: work in progress (WIP).** Usable, but agents and skills are still being tuned on real tasks. Expect changes. See [Known issues](#known-issues).

## Idea

- **Agents are generic, rules live in the project.** Every agent starts by reading the project's own `CLAUDE.md` / `AGENTS.md` and follows it. The same `reviewer` checks one project's conventions here and a different project's conventions there.
- **Two layers.**
  - **Global** (this repo, linked into `~/.claude/`): the same on every machine.
  - **Project** (`.claude/` inside each project repo): project rules, project-only agents, hook config. A project agent with the same name overrides the global one.
- **Cheap models for cheap work, expensive models only where judgment matters.** Opus plans, Sonnet implements and reviews, Haiku searches.
- **Few agents, used on purpose.** Each agent description is loaded into every session, so every extra agent costs context.

## Layout

```
agents/      global subagents (Markdown + frontmatter)
skills/      global skills (one folder per skill, SKILL.md inside)
hooks/       hook scripts, enabled per project via settings.json
templates/   starting files for a new project (.claude/, CLAUDE.md)
scripts/     third-party skill updates and plugin installation
install.sh   links agents/, skills/ and hooks/ into ~/.claude/
```

## Agents

| Agent | Model | Effort | Use it for |
|---|---|---|---|
| `explainer` | sonnet | medium | How does this flow work end to end? Traces code through layers. |
| `planner` | opus | high | Plan a feature or refactor before writing code. Read-only. |
| `reviewer` | sonnet | high | Review the current diff against the project's own rules. Read-only. |
| `security-reviewer` | sonnet | high | Access control, injection, secrets, unsafe input in changed code. Read-only. |
| `silent-failure-hunter` | sonnet | medium | Swallowed errors, bad fallbacks, unknown treated as known. |

For plain code search use Claude Code's built-in `Explore` agent.

Ask for them explicitly, it is more reliable than waiting for automatic use:

> Run the `planner` agent: add CSV export to the orders page.

## Recommended workflow for a feature

1. Main session on **Sonnet**. Clarify the task with it first.
2. **`planner`** (Opus) writes the plan. Read it, adjust it.
3. Main session implements the plan.
4. Tests, using the project's own commands.
5. **`reviewer`** checks the diff. Add **`security-reviewer`** for auth, permissions or user input, and **`silent-failure-hunter`** for error-heavy code.
6. Fix findings, commit.

Rules of thumb:

- One session = one task. Start a new session for unrelated work.
- Do not switch the main model for a single message, each switch rereads the whole context without cache.
- Raise effort (`/effort xhigh`) for risky areas: auth, permissions, migrations, money, data loss.

## Requirements

- Claude Code
- bash (Linux, macOS, or Git Bash on Windows) and git
- `jq` for the heavy command hook
- Python 3 for rebuilding the `ecc-router` catalog and for the `ui-ux-pro-max` plugin
- Node.js (`npm`) for the Codex CLI, only if you use the `codex` plugin

## Install

```bash
git clone https://github.com/jakub-lgr/claude-setup ~/claude-setup
~/claude-setup/install.sh
~/claude-setup/scripts/install-plugins.sh
```

`install-plugins.sh` installs the plugins listed under [Plugins](#plugins) and the CLI tools they need. It skips anything already installed. Use `--dry-run` to see what it would do.

**Windows:** run the scripts in Git Bash, which comes with Git for Windows (Claude Code needs it anyway). From PowerShell: `& "C:\Program Files\Git\bin\bash.exe" scripts/install-plugins.sh`.

`install.sh` creates symlinks in `~/.claude/agents`, `~/.claude/skills` and `~/.claude/hooks`. It never overwrites an existing file that is not already a link into this repo. Update everywhere with `git pull`.

## Per project

Copy what you need from `templates/project/` into the project:

- `CLAUDE.md`: the project rules the agents read.
- `.claude/settings.json`: enables hooks for this project.
- `.claude/heavy-commands.conf`: config for the heavy command guard (optional).

## Skills

| Skill | What it does |
|---|---|
| `feature-workflow` | Clarify, plan with `planner`, implement, test, review. |
| `ecc-router` | Manual only (`/ecc-router <task>`). Keeps [ECC](https://github.com/affaan-m/ecc) as a local archive (`~/ecc` or `$ECC_ARCHIVE`), suggests up to 10 matching agents, skills, commands or rules next to your own agents, waits for your confirmation, and uses the confirmed ones in the current session only. Nothing is installed. Rebuild its catalog after updating the archive: `python skills/ecc-router/build-catalog.py`. |

### Third-party skills

Copied unchanged from their authors' repositories, each with its license in its folder. The exact commits are in `scripts/third-party-skills.lock`. Update them with `scripts/update-third-party-skills.sh` (all, or name the skills to update), then review the diff.

| Source | Skills | License |
|---|---|---|
| [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) | `high-end-visual-design`, `minimalist-ui`, `industrial-brutalist-ui`, `full-output-enforcement` | MIT |
| [emilkowalski/skills](https://github.com/emilkowalski/skills) | `animate`, `animate-expo`, `animation-vocabulary`, `apple-design`, `emil-design-eng`, `find-animation-opportunities`, `improve-animations`, `mobile-native`, `review-animations` | MIT |
| [vercel-labs/skills](https://github.com/vercel-labs/skills) | `find-skills` | MIT |
| [NVIDIA/skillspector](https://github.com/NVIDIA/skillspector) | `skill-inspector` (full scans need the `skillspector` CLI, installed by `install-plugins.sh`) | Apache-2.0 |

`full-output-enforcement` was removed from taste-skill upstream and is pinned to the last commit that has it.

## Plugins

Plugins are not copied into this repo. `scripts/install-plugins.sh` installs them from their own marketplaces, so they update the usual way.

| Plugin | Source | License | Needs |
|---|---|---|---|
| `frontend-design` | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | Apache-2.0 | – |
| `ui-ux-pro-max` | [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | MIT | Python 3 |
| `codex` | [openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc) | Apache-2.0 | Codex CLI (installed by the script) and a one-time `codex login` |

## Hooks

| Hook | What it does |
|---|---|
| `guard-heavy-commands.sh` | Blocks heavy commands (build, test suites…) unless they run through the project's wrapper, e.g. a memory-limiting script. Does nothing in projects without `.claude/heavy-commands.conf`. Needs `jq`. |

## Why not install all of ECC?

We ran the same three tasks (a feature, a feature with planning and review, a bug fix) on the same small Next.js app with different setups. All of them produced working results.

| Setup | Relative load on usage limits | Time |
|---|---|---|
| This repo (5 agents) | 1.0× | ~5 min |
| This repo + `ecc-router` picking extra ECC agents | ~1.6× | ~10 min |
| Full ECC install (all agents, skills, hooks) | ~2.4× | ~20 min |

Full ECC wrote slightly more robust code, but at more than twice the cost. Hence: a small default set, and ECC on demand through `ecc-router` when a task needs knowledge the default set lacks. One run per setup on one small app, so treat the numbers as indicative.

## Known issues

- `install.sh` on Windows: Git Bash's `ln -s` copies files instead of linking them unless symlinks are enabled (Developer Mode and `MSYS=winsymlinks:nativestrict`). Copies are not updated by `git pull`.
- `guard-heavy-commands.sh` does nothing if `jq` is missing, without a warning. Its wrapper check can be bypassed by a command that mentions the wrapper later on the line.
- Review agents limit Bash to read-only git commands by instruction only, it is not enforced yet.

## TODO

- [ ] Tune agent prompts on real tasks.
- [ ] Decide which skills belong here (see `skills/README.md`).
- [ ] Optional database reviewer agents (MariaDB, PostgreSQL) as project-level or opt-in.
- [ ] Fix the known issues above.

## Credits

Some agents are adapted from or inspired by [ECC](https://github.com/affaan-m/ecc) (MIT), and the `ecc-router` catalog lists ECC's items with their descriptions. Third-party skills keep their own licenses. See `UPSTREAM.md` and `THIRD_PARTY_NOTICES.md`.

## License

MIT for this repo's own files, see `LICENSE`. Third-party skills in `skills/` are under their own licenses, included in each skill's folder.
