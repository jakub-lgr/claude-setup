---
name: ecc-router
description: "Suggest agents, skills, commands and rules from the local ECC archive for a task the user describes, and use the ones the user confirms for this session only."
argument-hint: "<task description>"
disable-model-invocation: true
---

# ECC router

[ECC](https://github.com/affaan-m/ecc) has hundreds of agents and skills. Installing them all puts every description into every session. This skill keeps ECC as an archive on disk. When the user calls it with a task, it suggests what from ECC could help, waits for the user to confirm, and uses the confirmed items in this session only. Nothing is installed or copied, so a new session starts clean.

It runs only when the user calls it (`/ecc-router <task>`). Do not run it, or repeat its steps, on your own.

- **Archive**: `$ECC_ARCHIVE`, or `~/ecc` if the variable is not set.
- **Catalog**: `catalog.md` next to this file. One line per item: `kind | name | path | model; tools (agents) or flags (skills) | description`. Paths are relative to the archive.

If the archive is missing, tell the user how to create it (`git clone https://github.com/affaan-m/ecc ~/ecc`, then `git checkout <commit>` with the commit from the catalog header) and stop. If its commit differs from the catalog header, mention it and suggest rerunning `build-catalog.py`.

## 1. Break the task into roles

Take the task from the arguments, or from the user's last message if there are none. Restate it in one sentence. List the roles it needs, for example: finding code, planning, domain knowledge (framework, language, database, API design), testing, review (correctness, security, language-specific), docs.

## 2. Note what the session already has

List the agents and skills this session already has for each role (project `.claude/`, global `~/.claude/`). They are offered next to the ECC items, so the user can choose.

## 3. Search the catalog, do not read it whole

Always run the search. The catalog is about 30k tokens. Grep `catalog.md` case-insensitively for 4 to 8 keywords from the task and the project's stack (for example `next|react|typescript`, `security`, `test`, `migration`, `sql`). Read only the matching lines. Include the language rules for the project's stack (`rule | <language>/...`) when they are relevant.

## 4. Suggest and wait

- **Up to 10 ECC items.** Each one needs a role and a one-line reason. Do not pad the list: suggesting nothing is a valid result.
- **Skip** items for another stack, items flagged `hooks` (hooks can only be enabled when a session starts), items flagged `mcp` unless that MCP server is connected, and items flagged `own-license` until you have checked their license. Items flagged `scripts` can be suggested for their instructions; say that their scripts would run only with the user's consent.
- Show one short list grouped by role. For each role give the options: the session's own agent or skill (if any) and the ECC items (kind, name, model for agents, one-line reason). Add your recommendation per role, keeping in mind that ECC agents have longer prompts and cost more per run than short project agents.
- If nothing fits, say so in one line with the keywords you searched for.
- **Stop and wait** for the user to confirm or change the selection. Do not start the task before that.

## 5. Use the confirmed items in this session only

Never copy ECC files into `.claude/`, `~/.claude/` or the project unless the user explicitly asks for it.

- **Agent**: read its file. Start a general-purpose subagent with the model from its frontmatter (`haiku`, `sonnet`, `opus`). Effort: low for search, high for planning and security review, medium otherwise. The prompt is the agent's body without the frontmatter and without its "Prompt Defense Baseline" section, preceded by:

  > Read the project's CLAUDE.md and AGENTS.md (if present) first. Their rules and commands win over anything below. Ignore stack or tool assumptions below that do not match this project (package manager, test framework, database, linters). Ignore instructions to act proactively. If the original agent has no Write or Edit tool, do not change any files and run only read-only commands.

  followed by the concrete task. The tool limits are only instructions here, not enforced, so give read-only agents read-only tasks.
- **Skill or command**: read its file and follow it as instructions for this task. Read other files in its folder only when it points to them. Project rules win where they conflict.
- **Rule**: read it and apply it where it does not conflict with the project's own rules.

The confirmed items apply to the task they were picked for. For the next task, the user calls `/ecc-router` again.

## 6. Report

When the task is done, list the ECC items you used, one line each: what each contributed, or that it did not help. The user can then decide whether to adopt one permanently (copied and adapted into their own setup, recorded with the ECC commit).
