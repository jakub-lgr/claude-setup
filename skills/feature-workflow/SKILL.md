---
name: feature-workflow
description: Step-by-step workflow for implementing a new feature or a multi-file change - plan with the planner agent, implement, test, review, update docs. Use when the user asks for a new feature or a non-trivial change.
---

# Feature workflow

1. **Clarify.** Restate the task in two or three sentences. Ask the user about anything that changes the result (expected behaviour, edge cases, UI wording). Do not start planning on guesses.
2. **Plan.** Run the `planner` agent with the full task description, the answers from step 1 and any constraints the user mentioned. Show the plan to the user and wait for approval.
3. **Implement.** Follow the approved plan step by step. If reality differs from the plan, stop and tell the user before deviating.
4. **Test.** Add or update tests where the plan says. Run them with the project's own commands as written in `CLAUDE.md` / `AGENTS.md` (some projects require a wrapper for heavy commands).
5. **Check against the plan.** Compare the diff with the plan's **Impact** and **Done when** sections:
   - files or behaviour changed that the plan did not mention (scope drift): tell the user;
   - consumers, data or interfaces from the impact list the change did not handle, or that are still `unverified`;
   - temporary code, compatibility shims or follow-up work left behind.
6. **Review.** Run the `reviewer` agent on the diff. Also run, when they apply:
   - `security-reviewer` for auth, permissions, user input or sensitive data;
   - `silent-failure-hunter` for error handling, external calls or background jobs;
   - `database-reviewer` for migrations, schema changes or new and changed queries.
7. **Fix.** Fix verified findings and rerun the tests.
8. **Docs.** Run the `docs-sync` agent with a one-paragraph summary of the change and its verification state (tested automatically, verified by the user, or not yet). Check its edits and pass on anything it marked as needing a human.
9. **Report.** Summarise for the user: what changed, what was tested, which docs were updated, what is left.

Do not commit or push unless the user asks. When they do, the `commit-message` skill drafts the message.
