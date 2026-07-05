# smartvedit-skills

The agent skill for [smartvedit](https://smartvedit.com) — teaches an AI
agent (Claude Code, Codex, etc.) to drive the `smartvedit` CLI: login,
submit whole-video fixers (trim pauses, captions, level, remaster,
highlights), watch jobs, and chain steps into a pipeline.

## Install

The `smartvedit` CLI (`npm install -g smartvedit-cli`) embeds this skill
and installs it itself:

```sh
smartvedit install --skills
```

This drops `skills/smartvedit/` into `~/.claude/skills/smartvedit` (and
`~/.agents/skills/smartvedit` if `codex` is on PATH), matching the install
convention used across deemwar's other CLI-embedded skills (`messenger
install --skills`, `crypto-desk install --skills`).

Manual install (no CLI, or a different agent):

```sh
npx skills add deemwar-products/smartvedit-skills
```

## Layout

```
smartvedit-skills/
└── skills/
    └── smartvedit/
        └── SKILL.md
```

Tracked source of truth for the copy baked into `smartvedit-cli` at build
time (submoduled into `apps/cli/` of the
[video-ai](https://github.com/deemwar-products/video-ai) monorepo).

---

Made by [deemwar](https://deemwar.com)
