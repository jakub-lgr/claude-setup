# Skills

One folder per skill, each with a `SKILL.md`. Two kinds live here:

- **My skills** (`dev`, `ecc-router`, `commit-message`, `pre-publish-check`): written for this repo, edit them freely.
- **Third-party skills**: public skills under open licenses, copied unchanged by `scripts/update-third-party-skills.sh`, each with its `LICENSE`. Do not edit them by hand, the next update would overwrite the changes. The list is in the main README.

A skill is a reusable set of instructions Claude loads when the task matches its `description` (or when you call it as `/skill-name`). Use skills for repeatable procedures; use agents for isolated subtasks that should run in their own context.

## Planned

- [x] `dev`: one entry point that classifies the task (feature, change, fix, refactor) and its size and runs the matching gated workflow. Replaces `feature-workflow`.
- [x] `ecc-router`: on request, suggest ECC agents and skills for a task and use the confirmed ones in this session only.
- [x] `commit-message`: draft a commit message that matches the repo's history style.
- [x] `pre-publish-check`: scan a repo for secrets, personal data and internal references before making it public.
- [ ] `release-checklist`: steps before pushing or deploying.
- [ ] `new-project`: set up `CLAUDE.md` and `.claude/` from `templates/project/`.
