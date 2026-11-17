# Upstream sources

Files in this repo that were copied from, adapted from, or inspired by other projects. License texts are in `THIRD_PARTY_NOTICES.md`.

Third-party skills (copied unchanged, one folder each under `plugins/<plugin>/skills/`) are listed with their exact commits in `scripts/third-party-skills.lock`.

Status:

- **copied**: taken as is.
- **adapted**: taken and changed to fit this repo's principles.
- **idea**: only the idea was used, the text is our own (listed for transparency, no license obligation).

## ECC

Source: https://github.com/affaan-m/ecc. Each row names the commit it was taken from: `6f1881a` = `6f1881aeafa3c48f7b603cc4be4b2e4e70daad59`.

| File here | ECC source | Commit | Status | Notes |
|---|---|---|---|---|
| `plugins/core/skills/commit-message/SKILL.md` | `agents/commit-reviewer.md` | `6f1881a` | idea | Learn the message style from `git log`, suggest splitting mixed diffs. |
| `plugins/core/skills/pre-publish-check/SKILL.md` | `agents/opensource-sanitizer.md` | `6f1881a` | idea | Secret, personal data, internal reference and dangerous file scans, git history audit, PASS/FAIL report. |
