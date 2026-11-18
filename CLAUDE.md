# claude-setup

The owner's personal Claude Code setup, published as a public repo: a plugin marketplace of skill bundles that are switched on per project. This file holds the rules for working on this repo itself.

## Principles

These are settled. Do not change them without the owner's explicit approval.

1. **Skills only, no custom agents.** Current models work well on their own with good playbooks. Do not add subagents or hooks that exist only to serve agents.
2. **Bundles per kind of work.** Each plugin under `plugins/` is one bundle (core, web design, iOS…). Only `core` is installed globally; every other bundle goes into the projects that need it, mainly copied into `<project>/.claude/skills/` by `scripts/sync-to-project.sh` so it also works in cloud sessions. Keep `core` small, because it loads in every session.
3. **This repo is the only source.** A skill lives in exactly one plugin here. Projects get copies only through `sync-to-project.sh`, which records them in the project's `.claude/claude-setup.lock` and updates them from here. Project-specific playbooks stay in that project's own `.claude/skills/`, not here.
4. **Public work is reused only under its license, with attribution.** Skills from public projects under an open license (MIT, Apache-2.0 and similar) may be:
   - **copied unchanged** as third-party skills, through `scripts/update-third-party-skills.sh` (see Notes);
   - **adapted** into this repo's own skills, with a note at the top naming the source path and commit, listed in `UPSTREAM.md`;
   - **used as an idea** only, listed in `UPSTREAM.md` for transparency.

   Every source's license text goes into `THIRD_PARTY_NOTICES.md`. Check folder-level licenses too, some repos mix licenses. Tools under non-open terms (for example Tesseract) are documented in the README with install steps, never copied or listed in the marketplace.

## Rules for this repo

- **Public repo.** Everything is in English and generic. No names, private projects, servers, domains, local paths or secrets, not even in examples.
- **No pushing or creating anything on GitHub** without the owner's explicit instruction.
- **Validate after changing a manifest:** `claude plugin validate .` and `claude plugin validate plugins/<plugin>`. Test scripts with `bash -n` and a dry run.
- **Bump `version`** in a plugin's `plugin.json` when its skills change, otherwise installed copies do not update.
- Shell scripts must use LF line endings and work in bash on Linux, macOS and Git Bash on Windows.
- Keep `README.md` (catalog, install, per-project table) in sync with every change.

## Layout

```
.claude-plugin/marketplace.json   lists every plugin (local folders and external github sources)
plugins/<plugin>/                 .claude-plugin/plugin.json + skills/<skill>/SKILL.md
scripts/                          sync-to-project.sh (+ external-bundles.conf), update-third-party-skills.sh (+ .conf, .lock), install-skillspector.sh
UPSTREAM.md                       every file copied, adapted or inspired from elsewhere
THIRD_PARTY_NOTICES.md            license texts of those sources
```

## Notes

- Third-party skills are added only when their license allows it: list them in `scripts/third-party-skills.conf` with the target plugin, run `scripts/update-third-party-skills.sh` (it copies each skill with its LICENSE and writes the lock), and add them to `THIRD_PARTY_NOTICES.md` and the README. Never edit their files by hand, changes would be lost on the next update.
- Plugins that have their own repository are never copied into this repo. Add them to `.claude-plugin/marketplace.json` with a `github` source, to `scripts/external-bundles.conf` (keep the two in sync) and to the README.
- `sync-to-project.sh` must never overwrite a project's own skills, and must keep working in bash 3.2 (macOS): no `mapfile`, no associative arrays. Test it in a temporary project folder, never in a real project without asking.
- Own skills are `plugins/core/skills/commit-message` and `plugins/core/skills/pre-publish-check`; edit them freely.
