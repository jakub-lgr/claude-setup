# claude-setup

My personal Claude Code setup as a **plugin marketplace**: skill bundles that I switch on per project instead of loading everything into every session. A web project gets the design bundles, an iOS app gets the Swift bundle, a video project gets its own tools, and only a small core is on everywhere.

> **Version 2.0.** Version 1 (global agents, hooks and an `install.sh` that linked everything into `~/.claude/`) lives on the `main` branch history. v2 drops custom agents: current models work well on their own when given good playbooks, so this repo now ships skills only.

## Idea

- **Bundles, not one big global install.** Every plugin is a bundle of skills for one kind of work. A disabled plugin is not loaded at all, so its skills cannot trigger by mistake in the wrong project.
- **Only `core` is global.** `core` is installed once per machine and is on everywhere. Every other bundle is installed per project, so it exists only in the projects that need it and nowhere else.
- **One copy of every skill.** Skills live here, not copied into each project, so an update reaches every project at once.
- **Third-party work is reused only under its license.** Skills from other authors are copied unchanged with their `LICENSE`; plugins that have their own repository are referenced, not copied.

## Catalog

### `core` – on everywhere (3 skills)

| Skill | What it does | Source |
|---|---|---|
| `commit-message` | Drafts a commit message in the repository's own style, learned from `git log`. Suggests splitting mixed diffs. | own |
| `pre-publish-check` | Before a repo goes public: scans files and git history for secrets, personal data, internal hosts, domains and local paths. Read-only PASS / WARN / FAIL report. | own |
| `skill-inspector` | Checks a skill before you install it: over-permissioned, exfiltrating or malicious instructions and scripts. Full scans need the `skillspector` CLI (`scripts/install-skillspector.sh`). | [NVIDIA/skillspector](https://github.com/NVIDIA/skillspector), Apache-2.0 |

### `emil-design` – web and React Native projects (19 skills)

All from [emilkowalski/skills](https://github.com/emilkowalski/skills) (MIT).

| Skill | What it does |
|---|---|
| **Design** | |
| `emil-design-eng` | UI polish, component design and the invisible details that make software feel great. |
| `apple-design` | Apple's approach to interface design and fluid, physical motion, translated for the web. |
| `mobile-native` | Small CSS and meta-tag fixes that make a web app feel native on a phone. |
| `learn-taste` | Turns a session's design corrections into rules in `DESIGN.md`, a project skill or a lint check. |
| `pick-ui-library` | Picks a library for a frontend task from a curated list (primitives, toasts, drawers, charts, drag and drop…). |
| `prototype` | Builds several genuinely different versions of a UI piece behind a live picker. |
| `break-ui` | Feeds UI worst-case data (long names, empty lists, huge numbers, emoji…) and reports what broke. |
| **Animation** | |
| `animate` | Builds an animation from scratch: should it animate, which properties, curve, duration, interruption, exit. |
| `animate-expo` | The same for React Native and Expo (Reanimated, Gesture Handler, haptics). |
| `animation-vocabulary` | "What is it called when…": turns a vague description of a motion effect into its exact name. |
| `animation-performance` | Keeps animations inside the frame budget and finds why one drops frames. |
| `choreograph` | Coordinates several elements that animate together (staggers, hero entrances, view swaps). |
| `gestures` | Drag, swipe and sheet interactions that track the finger 1:1 and stay interruptible. |
| `review-animations` | Strict review of animation code against a high craft bar. |
| `improve-animations` | Audits a whole codebase's motion and writes a prioritized plan. Read-only. |
| `find-animation-opportunities` | Finds places that should animate and rejects those that should not. Read-only. |
| `remove-animations` | Removes motion the interface does not need. Only subtracts. |
| **Helpers** | |
| `ask-emil` | Router: tells you which of these skills fits your situation. |
| `ask-sonner` | Guide to Sonner, the React toast library. Triggers only when you work with Sonner. |

### `ui-ux-pro-max` – web projects (7 skills)

From [nextlevelbuilder/ui-ux-pro-max-skill](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) (MIT). Listed in this marketplace, but installed straight from its own repository, not copied here. Needs **Python 3** for its search scripts.

| Skill | What it does |
|---|---|
| `ui-ux-pro-max` | Design intelligence with a searchable local database: 80 styles, 192 palettes, 74 font pairings, 25 chart types, 22 stacks. |
| `ui-styling` | shadcn/ui + Tailwind interfaces. |
| `design-system` | Design tokens (primitive → semantic → component) and component specs. |
| `design` | Brand identity, logos, icons, corporate identity. Parts call external image AI services. |
| `brand` | Brand voice, visual identity, style guides. |
| `banner-design` | Banners for social media, ads, website heroes and print. |
| `slides` | HTML presentations with Chart.js. |

### `ios` – Swift / Xcode projects (1 skill)

| Skill | What it does | Source |
|---|---|---|
| `write-swift` | Modern Swift: value types, Swift 6 concurrency, protocols and generics, API design, Swift Testing, macros. | [emilkowalski/skills](https://github.com/emilkowalski/skills), MIT |

Tip: in an iOS project enable `emil-design` too if you want `apple-design` and `gestures`.

### Video – Tesseract (not in this repo)

[Tesseract by Mirage](https://mirage.app/tesseract) ([mirage-hq/Tesseract](https://github.com/mirage-hq/Tesseract)) is a local video editor, motion graphics and 3D renderer driven by the agent. It is **not part of this marketplace**: it ships under Mirage's own terms, not an open-source license, and needs a downloaded CLI. Install it **per video project**.

Its skills: `tesseract-video` (edit footage into a finished video), `tesseract-motion` (motion graphics, titles, overlays), `tesseract-design` (static designs as PNG), `tesseract-3d` (3D scenes), `tesseract-editor` (custom browser editor for `.tsrct` files).

Install, inside the video project, by pasting this into a new Claude Code session there:

```text
Set up Tesseract by Mirage so you can create editable designs and 3D scenes, edit videos,
and make motion graphics in this agent's environment. Read https://github.com/mirage-hq/Tesseract
and check the requirements for this local or hosted environment. If it is supported, follow the
official plugin or skills installation guide, use its required runtime version, verify the
download checksum, and confirm a short preview renders correctly. Then ask what I want to make
and which brand references or source assets I have. Keep the editable project and source assets
with the finished render.
```

Or from a terminal (needs Node.js): `npx skills add mirage-hq/Tesseract`. The skills do not update themselves; run the same again for a new version. Project-specific video playbooks (for example a cutting style for one channel) belong in that project's own `.claude/skills/`.

## Install

Once per machine, install only `core`. It is the only bundle meant to be on everywhere.

In Claude Code:

```text
/plugin marketplace add jakub-lgr/claude-setup
/plugin install core@claude-setup
```

Or from a terminal:

```bash
claude plugin marketplace add jakub-lgr/claude-setup
claude plugin install core@claude-setup
```

Do **not** install the other bundles globally. They are installed per project, see below.

Optional, for full `skill-inspector` scans: `scripts/install-skillspector.sh` (Git Bash on Windows). Without it the skill still reviews the source.

Update later with `/plugin marketplace update claude-setup`. New or updated plugins are loaded when a new session starts.

## Per project

Install the bundles a project needs from inside the project folder, with project scope:

```bash
claude plugin install emil-design@claude-setup --scope project
claude plugin install ui-ux-pro-max@claude-setup --scope project
```

This enables the bundle in the project's `.claude/settings.json` only; other projects do not see it. Commit that file. To make the project work on a machine that has not added this marketplace yet, add the marketplace to the same file, then Claude Code offers to install what the project needs:

```json
{
  "extraKnownMarketplaces": {
    "claude-setup": {
      "source": { "source": "github", "repo": "jakub-lgr/claude-setup" }
    }
  },
  "enabledPlugins": {
    "emil-design@claude-setup": true,
    "ui-ux-pro-max@claude-setup": true
  }
}
```

Typical setups:

| Project | Bundles |
|---|---|
| Website / web app | `emil-design`, `ui-ux-pro-max` |
| React Native / Expo app | `emil-design` |
| iOS app in Xcode | `ios` (+ `emil-design` for `apple-design`, `gestures`) |
| Discord bot, server, API | nothing extra, `core` is enough |
| Video | Tesseract installed in the project (see above), no bundle from here |

Remove a bundle from a project with `claude plugin uninstall <plugin>@claude-setup --scope project`.

**Cloud sessions** (Claude Code on the web) start from a fresh clone of the project, without this machine's global `core`. Whether they install plugins listed in the project's `.claude/settings.json` is not verified yet. Skills committed directly in the project's `.claude/skills/` always work there; a script that copies chosen bundles into a project is planned (see TODO).

## Layout

```
.claude-plugin/marketplace.json   the marketplace: lists every plugin
plugins/<plugin>/                 one bundle per folder
  .claude-plugin/plugin.json
  skills/<skill>/SKILL.md
scripts/
  update-third-party-skills.sh    copies third-party skills into their plugin (+ .conf, .lock)
  install-skillspector.sh         CLI for full skill-inspector scans
UPSTREAM.md                       everything taken or inspired from elsewhere
THIRD_PARTY_NOTICES.md            licenses of those sources
```

## Maintaining

- **Update third-party skills:** `scripts/update-third-party-skills.sh` (all, or name the skills), review `git diff`, commit, then bump the plugin's `version` in its `plugin.json` so installed copies update.
- **Add a third-party skill:** add a line to `scripts/third-party-skills.conf` (`repo ref folder plugin name`), run the script, list it in this README and `THIRD_PARTY_NOTICES.md`.
- **Add a plugin:** new folder under `plugins/` with `.claude-plugin/plugin.json`, add it to `.claude-plugin/marketplace.json`. An external plugin is only an entry with a `github` source.
- **Check before pushing:** `claude plugin validate .` and `claude plugin validate plugins/<plugin>`.

## TODO

- [ ] `scripts/sync-to-project.sh`: copy chosen bundles into a project's `.claude/skills/` and update only those bundles on rerun, so they work in cloud sessions too.

## License

MIT for this repo's own files, see `LICENSE`. Third-party skills under `plugins/*/skills/` keep their own licenses, included in each skill's folder. See `UPSTREAM.md` and `THIRD_PARTY_NOTICES.md`.
