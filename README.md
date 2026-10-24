# claude-setup

My personal Claude Code setup: my own agents, skills and hooks, plus selected public skills and plugins under open licenses. Everything is generic and works in any project.

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
| `database-reviewer` | sonnet | high | Migrations, schema changes and queries, any database engine (MySQL/MariaDB, PostgreSQL, SQLite…), against the project's own rules. Read-only. |
| `docs-sync` | haiku | medium | After a change: updates the docs the project's rules say must change with it. Edits Markdown only. |
| `explainer` | sonnet | medium | How does this flow work end to end? Traces code through layers. |
| `planner` | opus | high | Plan a feature or refactor before writing code, including its impact (consumers, data, docs, release and rollback). Read-only. |
| `reviewer` | sonnet | high | Review the current diff against the project's own rules. Read-only. |
| `security-reviewer` | sonnet | high | Access control, injection, secrets, unsafe input in changed code. Read-only. |
| `silent-failure-hunter` | sonnet | medium | Swallowed errors, bad fallbacks, unknown treated as known. |

For plain code search use Claude Code's built-in `Explore` agent.

Ask for them explicitly, it is more reliable than waiting for automatic use:

> Run the `planner` agent: add CSV export to the orders page.

## Recommended workflow

Describe the task to `/dev` and it picks the workflow for you:

> /dev add CSV export to the orders page

It classifies the task as a new feature, a change, a fix or a refactor, estimates its size (trivial, small, standard, large), tells you in one line, then runs the matching steps with two gates where it waits for you: plan approval and commit approval. Small tasks skip the planner and the docs step. Its report lists every agent it ran or skipped, so a skipped `planner` or reviewer is visible.

The steps for a standard feature:

1. Main session on **Sonnet**. Clarify the task with it first.
2. **`planner`** (Opus) writes the plan. Read it, adjust it, approve it (gate 1).
3. Main session writes the tests first, then implements the plan. A fix starts with a test that reproduces the bug, a refactor keeps the existing tests passing unchanged.
4. Tests, using the project's own commands.
5. Compare the diff with the plan's impact section.
6. **`reviewer`** checks the diff. Add **`security-reviewer`** for auth, permissions or user input, **`silent-failure-hunter`** for error-heavy code, and **`database-reviewer`** for migrations and queries.
7. Fix findings, then **`docs-sync`** updates the docs.
8. Approve the commit (gate 2): only this task's files, with a message from the `commit-message` skill. No push unless you say so.

Rules of thumb:

- One session = one task. Start a new session for unrelated work.
- Do not switch the main model for a single message, each switch rereads the whole context without cache.
- Raise effort (`/effort xhigh`) for risky areas: auth, permissions, migrations, money, data loss.

## Requirements

- Claude Code
- bash (Linux, macOS, or Git Bash on Windows) and git
- `jq` for the hooks (without it, `readonly-git.sh` blocks every Bash call of the read-only agents and `guard-heavy-commands.sh` blocks heavy-looking commands)
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

### My skills

| Skill | What it does |
|---|---|
| `dev` | Manual only (`/dev <task>`). One entry point for development work: classifies the task (feature, change, fix, refactor) and its size, then runs the matching workflow: clarify, plan with `planner`, gate 1, tests first, implement, check against the plan, review with the agents that apply, `docs-sync`, report with the agents that ran or were skipped, gate 2 (commit only this task's files, never push without asking). |
| `commit-message` | Draft a commit message in the repo's own style, learned from `git log`. Suggests splitting mixed diffs. |
| `pre-publish-check` | Before making a repo public: scan files and git history for secrets, personal data, internal hosts, domains and local paths. Read-only report. |
| `ecc-router` | Manual only (`/ecc-router <task>`). Keeps [ECC](https://github.com/affaan-m/ecc) as a local archive (`~/ecc` or `$ECC_ARCHIVE`), suggests up to 10 matching agents, skills, commands or rules next to your own agents, waits for your confirmation, and uses the confirmed ones in the current session only. Nothing is installed. Rebuild its catalog after updating the archive: `python skills/ecc-router/build-catalog.py`. |

### Third-party skills

Public skills under open licenses, copied unchanged from their authors' repositories, each with its license in its folder. The exact commits are in `scripts/third-party-skills.lock`. Update them with `scripts/update-third-party-skills.sh` (all, or name the skills to update), then review the diff.

| Source | Skills | License |
|---|---|---|
| [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) | `high-end-visual-design`, `minimalist-ui`, `industrial-brutalist-ui`, `full-output-enforcement` | MIT |
| [emilkowalski/skills](https://github.com/emilkowalski/skills) | `animate`, `animate-expo`, `animation-vocabulary`, `apple-design`, `emil-design-eng`, `find-animation-opportunities`, `improve-animations`, `mobile-native`, `review-animations` | MIT |
| [vercel-labs/skills](https://github.com/vercel-labs/skills) | `find-skills` | MIT |
| [NVIDIA/skillspector](https://github.com/NVIDIA/skillspector) | `skill-inspector` (full scans need the `skillspector` CLI, installed by `install-plugins.sh`) | Apache-2.0 |

## Plugins

Plugins are not copied into this repo. `scripts/install-plugins.sh` installs them from their own marketplaces, so they update the usual way.

| Plugin | Source | License | Needs |
|---|---|---|---|
| `frontend-design` | [anthropics/claude-plugins-official](https://github.com/anthropics/claude-plugins-official) | Apache-2.0 | – |
| `ui-ux-pro-max` | [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | MIT | Python 3 |
| `codex` | [openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc) | Apache-2.0 | Codex CLI (installed by the script) and a one-time `codex login` |

Optional plugins, not for coding. Installed only with `scripts/install-plugins.sh --personal`. Each adds 11 skills that can trigger on their own, so turn them off with `/plugin` in coding projects.

| Plugin | Source | License | What it is for | Needs |
|---|---|---|---|---|
| `trader-skill` | [Jakeschincariol/trader-skill](https://github.com/Jakeschincariol/trader-skill) | MIT | Investing: copy a portfolio from 13F filings, news and Congress trade alerts, budget and risk checks, taxes, rebalancing. Orders only after an explicit yes, paper trading by default. | Python 3 |
| `founder-skill` | [Jakeschincariol/founder-skill](https://github.com/Jakeschincariol/founder-skill) | MIT | Testing a business idea: board review, competitors, simulated buyer panel, pricing, unit economics, launch plan. Simulated buyers are a brainstorm, not market research. | Python 3 |

## Hooks

| Hook | What it does |
|---|---|
| `guard-heavy-commands.sh` | Blocks heavy commands (build, test suites…) unless they run through the project's wrapper, e.g. a memory-limiting script. Each part of a chained command must start with the wrapper itself. Does nothing in projects without `.claude/heavy-commands.conf`. Needs `jq`. |
| `readonly-git.sh` | Used by the read-only agents through their frontmatter, nothing to enable. Allows only `git status`, `git diff` and `git log` in Bash, blocks everything else. |

## Known issues

- `install.sh` on Windows: Git Bash's `ln -s` copies files instead of linking them unless symlinks are enabled (Developer Mode and `MSYS=winsymlinks:nativestrict`). Copies are not updated by `git pull`.
- `readonly-git.sh` is found through `~/.claude/hooks/`. If `install.sh` has not been run, the hook is missing and the read-only agents fall back to the instruction alone.
- `guard-heavy-commands.sh` splits chained commands on `;`, `&&`, `|` and similar without understanding quotes, so a separator inside a quoted string can split a command in the wrong place. It errs on the side of blocking.

## TODO

- [ ] Keep tuning agent prompts on real tasks. First round done (all new agents, reviewer, silent-failure-hunter); `docs-sync` stays on haiku.
- [ ] `release-checklist` and `new-project` skills (see `skills/README.md`).
- [ ] Later: project-level parity reviewer template (compare a ported page with its legacy original).

## Credits

Some agents are adapted from or inspired by [ECC](https://github.com/affaan-m/ecc) (MIT), and the `ecc-router` catalog lists ECC's items with their descriptions. Third-party skills keep their own licenses. See `UPSTREAM.md` and `THIRD_PARTY_NOTICES.md`.

## License

MIT for this repo's own files, see `LICENSE`. Third-party skills in `skills/` are under their own licenses, included in each skill's folder.
