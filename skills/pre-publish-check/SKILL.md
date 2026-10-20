---
name: pre-publish-check
description: Scan a repository - working tree and git history - for secrets, personal data, internal hostnames, domains, IP addresses and local paths before it is made public or before pushing to a public repo. Read-only, reports PASS / WARN / FAIL. Use when the user is about to publish a repo, open-source code, or push to a public repository.
# Idea from ECC agents/opensource-sanitizer.md @ 6f1881a (MIT): secret, PII, internal-reference
# and dangerous-file scans with a PASS / FAIL report, plus a git history audit.
---

# Pre-publish check

Find anything that must not become public. Never change files, rewrite history, rotate keys or push. Report and let the user decide.

Never print a full secret in the report: show the file, line and the first 4 characters followed by `…`.

## 0. Scope and rules

- Target: the repository root the user names, or the current one.
- Read its `CLAUDE.md` / `AGENTS.md` for publishing rules (for example "no names, domains or local paths, even in examples") and for anything already declared public on purpose (the project's own public domain, the author's public handle, third-party license notices).
- Ask the user, if not obvious, for names, domains, server names and usernames that are private to them. Those are the strongest search terms you have. Do not write them into any file.
- List the files that would be published: `git ls-files`, plus untracked files not ignored (`git status --porcelain`). Ignored files are out of scope, but report if `.env` or similar is **tracked**.

## 1. Secrets (any confirmed hit = FAIL)

Search tracked files with `git grep -nIE` (case-insensitive where it helps) for:

- private keys: `-----BEGIN [A-Z ]*PRIVATE KEY-----`;
- cloud and service keys: `AKIA[0-9A-Z]{16}`, `gh[pousr]_[A-Za-z0-9]{36,}`, `github_pat_[A-Za-z0-9_]{20,}`, `sk-[A-Za-z0-9_-]{20,}`, `sk-ant-[A-Za-z0-9_-]{20,}`, `xox[abposr]-[A-Za-z0-9-]{10,}`, `AIza[0-9A-Za-z_-]{35}`, `SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}`;
- Discord bot tokens: `[MN][A-Za-z0-9_-]{23,25}\.[A-Za-z0-9_-]{6}\.[A-Za-z0-9_-]{27,}`, and webhook URLs `discord(app)?\.com/api/webhooks/`;
- Slack and other webhooks: `hooks\.slack\.com/services/`;
- JWTs: `eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}`;
- connection strings with a password: `[a-z+]+://[^:/\s]+:[^@\s]+@`;
- assignments: `(password|passwd|secret|token|api[_-]?key|client[_-]?secret)\s*[:=]\s*['"]?[^\s'"]{8,}`.

Then judge each hit: placeholders (`changeme`, `<your-key>`, `xxx`, `example`), `.env.example` templates and obvious test values are not secrets. A real-looking value is FAIL even if it "might be old".

## 2. Personal and internal data (hit = FAIL or WARN)

- email addresses: `[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}`. Generic ones (`noreply@`, `example.com`, documented contact addresses) are fine;
- phone numbers, dates of birth, home addresses, real people's names in fixtures, seed data or examples;
- local paths with a user name: `/home/[^/\s]+/`, `/Users/[^/\s]+/`, `C:\\Users\\[^\\\s]+\\`;
- private IP ranges and hosts: `\b10\.\d+\.\d+\.\d+\b`, `\b192\.168\.\d+\.\d+\b`, `\b172\.(1[6-9]|2\d|3[01])\.\d+\.\d+\b`, `\b[a-z0-9-]+\.(local|lan|internal|corp)\b`, SSH strings `\b[a-z0-9_.-]+@[a-z0-9.-]+:[~/]`;
- every domain and hostname that appears (`git grep -noIE '[a-z0-9-]+(\.[a-z0-9-]+)+\.[a-z]{2,}'`, deduplicated). Separate well-known public ones (github.com, npm, docs sites) from the rest and list the rest for the user to confirm;
- the private terms the user gave you in step 0.

## 3. Dangerous files (tracked = FAIL)

`git ls-files` matched against: `.env`, `.env.*` (except `*.example`/`*.sample`), `*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa*`, `id_ed25519*`, `*.kdbx`, `credentials*.json`, `*.sqlite`, `*.db`, `*.sql` and `*.dump` with data, `*.bak`, `*.log`, `.npmrc` or `.pypirc` with tokens, editor and OS clutter with paths in it.

## 4. Git history

Everything ever committed becomes public with the repo, even if deleted since.

- `git log --all --format='%an <%ae>' | sort -u`: author names and emails that will be public. Report them as WARN so the user can confirm they are fine to publish (or use a noreply address).
- Rerun the secret patterns from step 1 over history: `git log --all -p -G '<pattern>' --format='%h %s'` for the strongest patterns, and `git log --all --diff-filter=D --name-only --format=` for deleted files that match step 3.
- Commit messages: `git log --all --format=%B` for names, hosts and links from step 2.

A secret found only in history is still FAIL: removing it needs a history rewrite and a key rotation, and the user decides how.

## 5. Report

```
Pre-publish check: <repo> @ <short sha>  →  PASS | PASS WITH WARNINGS | FAIL

FAIL
- <file:line or commit> · <what> · <why it matters> · <what to do>

WARN (confirm or fix)
- ...

Checked
- files scanned: N tracked, M untracked
- history: K commits, A authors
- domains found: <list>
```

For every FAIL say what to do: remove and rotate the key (rotation first, it is already exposed if pushed anywhere), move the value to the environment, replace the example with a placeholder, or rewrite history before publishing.
