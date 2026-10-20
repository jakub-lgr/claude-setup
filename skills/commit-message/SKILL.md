---
name: commit-message
description: Draft a commit message for the staged (or current) changes in the style the repository already uses - format, language, scope and length learned from git log. Flags diffs that should be split. Use when the user asks for a commit message or asks you to commit.
# Idea from ECC agents/commit-reviewer.md @ 6f1881a (MIT): learn the norms from history, suggest splits.
---

# Commit message

Draft the message; do not commit unless the user asked you to commit.

1. **Rules first.** Read the project's `CLAUDE.md` / `AGENTS.md` (and `CONTRIBUTING.md` if present) for commit rules: format, language, scopes, issue references, trailers. They win over what the history shows.
2. **Read the change.** `git diff --staged`; if nothing is staged, `git diff` and `git status` (and say the message is for unstaged changes). If there are no changes, say so and stop.
3. **Learn the style.** `git log --no-merges --format=%s -30`, plus `git log --no-merges --format=%B -10` to see whether bodies are used. Note:
   - format: Conventional Commits (`type(scope): subject`), a plain sentence, a ticket prefix, or something else;
   - language and grammatical mood (imperative, past tense, noun phrase);
   - scope names actually used, and how they map to directories or modules;
   - typical subject length, capitalisation, trailing period;
   - whether bodies and trailers are used, and for what.
   Follow the dominant style. If the history is mixed or too short, use the project rules, then a short imperative sentence.
4. **Split check.** If the diff mixes unrelated changes (a feature plus an unrelated fix, a refactor plus behaviour change, formatting of untouched files), say so and propose one message per part and which files go where. Do not hide a second change in the body.
5. **Write it.**
   - Subject: within the typical length you measured; what changes for the user or the codebase, not how ("Fix totals for an empty cart", not "Add null check").
   - Body only when the reason or a consequence is not obvious from the diff: why, what it affects, migration or deploy notes. Wrap like the history does.
   - Breaking changes and migrations are stated explicitly in the repo's own way (`!` and `BREAKING CHANGE:` in Conventional Commits).
   - Trailers (co-author, sign-off, session links, issue refs): only the ones the project rules or the current session's instructions require, with the values given there. Do not copy trailers from old commits, they name other people, models or sessions. Never invent issue numbers.
   - No secrets, personal data or internal hostnames in the message.
6. **Show it** in a code block, followed by one line on the style you matched (for example: "Czech imperative sentence, no scope, ~60 characters, like the last 30 commits"). If the user asked you to commit, commit with exactly that message.
