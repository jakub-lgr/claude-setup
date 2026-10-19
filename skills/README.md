# Skills

One folder per skill, each with a `SKILL.md`:

```
skills/
  feature-workflow/
    SKILL.md
```

Third-party skills in this folder come from `scripts/update-third-party-skills.sh`. Do not edit them by hand. See the main README.

A skill is a reusable set of instructions Claude loads when the task matches its `description` (or when you call it as `/skill-name`). Use skills for repeatable procedures; use agents for isolated subtasks that should run in their own context.

## Ideas

- [x] `feature-workflow`: plan with Opus, implement, test, review.
- [x] `ecc-router`: on request, suggest ECC agents and skills for a task and use the confirmed ones in this session only.
- [ ] `release-checklist`: steps before pushing or deploying.
- [ ] `new-project`: set up `CLAUDE.md` and `.claude/` from `templates/project/`.
- [ ] `commit-message`: draft a commit message that matches the repo's history style (idea: ECC `commit-reviewer`).
- [ ] `pre-publish-check`: scan a repo for secrets, personal data and internal references before making it public (idea: ECC `opensource-sanitizer`).
