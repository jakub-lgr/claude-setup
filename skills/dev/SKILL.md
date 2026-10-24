---
name: dev
description: "One entry point for development work: classify the task (new feature, change, fix, refactor) and its size, then run the matching gated workflow with this setup's agents - plan, approve, test first, implement, review, docs, approve commit."
argument-hint: "<what you want done>"
disable-model-invocation: true
# Idea from ECC skills/orch-pipeline, orch-* and ecc-recipes @ 90606c8 (MIT): one entry point,
# size classifier, a workflow per task type, two human gates.
---

# Dev

The user describes what they want. You pick the workflow, so they do not need to know any other command. It runs only when the user calls it (`/dev <task>`).

Take the task from the arguments, or from the user's last message if there are none. Read the project's `CLAUDE.md` / `AGENTS.md` first; their rules win over this file wherever they differ (test commands, wrappers for heavy commands, commit rules).

Write every message to the user, including the plan and the report, in the language the user wrote the task in.

## 1. Classify

Decide the **type**:

| Type | When |
|---|---|
| `feature` | Behaviour that does not exist yet ("add", "build", "support"). |
| `change` | Existing behaviour should work differently. |
| `fix` | Existing behaviour is wrong: a bug, an error, a regression. |
| `refactor` | Structure improves, behaviour stays exactly the same. |

Decide the **size**. Take the highest size any signal reaches:

| Size | Files | New dependency, schema, API or permission | Open design choices |
|---|---|---|---|
| `trivial` | 1, a few lines | no | none |
| `small` | 1 file or 1 function | no | clear after reading the code |
| `standard` | 2 to 5 | maybe an internal module | one real choice |
| `large` | many, cross-cutting | yes | several |

Anything touching authentication, permissions, user input, money, a migration or a public interface is at least `standard`.

Tell the user the result in one line, with one reason, and continue unless they correct you. This line is the first thing you write, for every size including `trivial`, before running any agent, asking questions or showing a plan:

> Type: fix, size: small (one function in the export service). Correct me if not.

If the task mixes types (a fix plus a new feature), say so and suggest doing them one after another.

## 2. Clarify

Restate the task in two or three sentences. Ask about anything that changes the result: expected behaviour, edge cases, failure handling, who may do it, UI wording. Do not plan on guesses. For `trivial` and `small`, skip this when nothing is unclear.

## 3. Plan and Gate 1

| Size | Plan |
|---|---|
| `trivial`, `small` | No `planner`. State the intended change and the test in a few lines. |
| `standard`, `large` | Run the `planner` agent. Do not write the plan yourself. |

Give `planner` the full task, the answers from step 2, the type and what it should stress:

- `feature`: reuse an existing feature built the same way, list every place that lists siblings of anything new (permissions, routes, menus).
- `change`: who depends on the current behaviour (callers, stored data, other apps), what existing tests assert it, how to roll back.
- `fix`: the suspected root cause with evidence, and how to reproduce it.
- `refactor`: which tests prove behaviour stays the same, and where coverage is missing.

Show the plan. **Gate 1: wait for the user's approval.** Do not change any file before it. Apply what the user changes in the plan.

## 4. Implement, test first

Follow the approved plan. If reality differs from it, stop and tell the user before deviating.

The first move depends on the type:

- `feature`: write new tests for the new behaviour, see them fail, then implement until they pass.
- `change`: update the existing tests to the new behaviour first, see them fail, then change the code.
- `fix`: write a test that reproduces the bug, see it fail for the right reason, then fix the root cause, not the symptom. If the bug cannot be reproduced in a test, say so and describe how you reproduced it instead.
- `refactor`: run the tests before touching anything. If they do not cover the code, add tests for the current behaviour first. Change no behaviour. Tests must pass before and after, unchanged.

Run tests with the project's own commands. If the project has no tests for this area, say so instead of skipping silently.

Where tests or checks fail for reasons outside this task (other uncommitted work, a broken base), say so and keep them apart from this task's failures.

## 5. Check against the plan

For `standard` and `large`, compare the diff with the plan's **Impact** and **Done when**:

- files or behaviour the plan did not mention (scope drift): tell the user;
- consumers, data or interfaces from the impact list that the change did not handle, or that are still `unverified`;
- temporary code, shims or follow-up work left behind.

## 6. Review

Run the `reviewer` agent on the diff, for every size except `trivial`. Add, when they apply:

- `security-reviewer`: authentication, permissions, user input, secrets, sensitive data, calls to external services;
- `silent-failure-hunter`: error handling, external calls, background jobs, retries;
- `database-reviewer`: migrations, schema changes, new or changed queries.

Run only the ones that apply. Fix verified findings and rerun the tests. Findings that need the user's decision go into the report, not into the code.

## 7. Docs

Run the `docs-sync` agent with a one-paragraph summary of the change and its verification state (tested automatically, verified by the user, or not yet). Check its edits. Skip for `trivial` when the project's rules require no doc change.

## 8. Report and Gate 2

Report:

1. **Result**: the type and size from step 1, then what changed and why, in a few lines.
2. **Agents**: a table of every agent this workflow called for (`planner`, `reviewer`, the conditional reviewers, `docs-sync`), each marked `ran` or `skipped`, with the reason for each skip. An agent the workflow required that did not run is a defect of this run: say so plainly.
3. **Verified**: tests and checks run, with results. **Not verified**: what was not run (build, browser, live services) and why.
4. **Open decisions**: findings or questions left for the user.
5. **Proposed commit**: the exact files, listed by path, and a message from the `commit-message` skill.

**Gate 2: wait for the user's approval before committing.**

- Commit only the files of this task, added by path. Never `git add -A` or `git add .`. If a file mixes this task's changes with other uncommitted work, tell the user and let them decide.
- Never push, open a pull request or deploy unless the user says so in this conversation.
