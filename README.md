# smartvedit-skills

The agent skill for [smartvedit](https://smartvedit.com) — turns natural-
language requests ("trim pauses on the latest video", "find quotes in job
X", "run a pipeline of trim_pauses then captions on this") into the right
`smartvedit` CLI invocation: login, submit whole-video fixers (trim
pauses, captions, level, remaster, highlights), watch/describe/delete
jobs, and chain steps into a pipeline. Confirms the literal command
before running it — see `skills/smartvedit/workflow.md`.

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
        ├── SKILL.md           # frontmatter + triggers
        ├── workflow.md        # step-by-step procedure
        ├── references/
        │   └── verbs.md       # full natural-language → CLI translation table
        ├── scripts/
        │   ├── check-prereqs.sh
        │   └── exec.sh
        └── tests/
            └── test_workflow.sh
```

Tracked source of truth for the copy baked into `smartvedit-cli` at build
time (submoduled into `apps/cli/` of the
[video-ai](https://github.com/deemwar-products/video-ai) monorepo, and
symlinked at `.claude/skills/smartvedit` there for local auto-discovery
while working on that repo).

Run the skill's own tests:

```sh
bash skills/smartvedit/tests/test_workflow.sh
```

---

Made by [deemwar](https://deemwar.com)
