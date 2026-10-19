---
name: feature-workflow
description: Step-by-step workflow for implementing a new feature or a multi-file change - plan with the planner agent, implement, test, review. Use when the user asks for a new feature or a non-trivial change.
---

# Feature workflow

1. **Clarify.** Restate the task in two or three sentences. Ask the user about anything that changes the result (expected behaviour, edge cases, UI wording). Do not start planning on guesses.
2. **Plan.** Run the `planner` agent with the full task description, the answers from step 1 and any constraints the user mentioned. Show the plan to the user and wait for approval.
3. **Implement.** Follow the approved plan step by step. If reality differs from the plan, stop and tell the user before deviating.
4. **Test.** Add or update tests where the plan says. Run them with the project's own commands as written in `CLAUDE.md` / `AGENTS.md` (some projects require a wrapper for heavy commands).
5. **Review.** Run the `reviewer` agent on the diff. Run `security-reviewer` too when the change touches auth, permissions, user input or sensitive data, and `silent-failure-hunter` when it handles errors, external calls or background jobs.
6. **Fix and report.** Fix verified findings, rerun tests, then summarise for the user: what changed, what was tested, what is left.

Do not commit or push unless the user asks.
