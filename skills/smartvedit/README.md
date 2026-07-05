# smartvedit skill

A Claude Code project skill that turns natural-language requests in
this repo into `smartvedit` CLI invocations.

## What it does

Translates phrases like "trim pauses on the latest video", "remaster
this", "find quotes in job X", "run a pipeline of trim_pauses then
captions on the latest", or "log into smartvedit" into the right
`smartvedit` verb + kind + flags, prints the literal command, asks the
user to confirm, then runs it and surfaces the streamed progress + the
final `output_url`.

The skill never talks to the HTTP API directly — the Node CLI
(`smartvedit-cli` on npm, bin `smartvedit`) is the single source of
truth for the grammar.

## Installation / activation

This skill is shipped with the repo at `.claude/skills/smartvedit/`,
so it activates automatically in Claude Code when you type a trigger
phrase inside this repo — no manual install step.

Prerequisite: the `smartvedit` CLI. Install once:

    npm i -g smartvedit-cli

Or use it without installing — the skill's `scripts/exec.sh` honours
an `npx smartvedit-cli` invocation if you save it once:

    mkdir -p ~/.config/muthuishere-agent-skills/smartvedit
    printf '{"invocation": "npx smartvedit-cli"}\n' \
      > ~/.config/muthuishere-agent-skills/smartvedit/config.json

CLI source / docs: `apps/cli/` (the Node CLI being built in parallel).

## Example sessions

### 1. Trim pauses on the latest analyzed video

> **You:** trim pauses on the latest video
>
> **Skill:** I'm about to run:
>
>     smartvedit create trim-pauses --source --latest ok --wait
>
> OK to run? (y/N)
>
> **You:** y
>
> **Skill:** Streams `[12:04:01] queued` → `[12:04:05] running` →
> `[12:04:53] ok`, then prints:
>
>     ✓ trim_pauses on job a1b2…  cost 50 cr
>       https://s3…/jobs/c3d4…/output.mp4

### 2. Pipeline: trim pauses + level + captions

> **You:** first trim pauses, then level, then captions on the latest
>
> **Skill:** I'm about to run:
>
>     smartvedit create pipeline --source --latest ok --steps trim_pauses,level,captions
>
> OK to run? (y/N)
>
> **You:** y
>
> **Skill:** Streams each step's transitions; on completion prints the
> final-step `output_url`.

### 3. Login

> **You:** log into smartvedit
>
> **Skill:** I'm about to run:
>
>     smartvedit login
>
> OK to run? (y/N)
>
> **You:** y
>
> **Skill:** Opens the Firebase browser sign-in; on success prints
> `logged in as <email>`.

## Files

- `SKILL.md` — Claude Code skill manifest (frontmatter + triggers).
- `workflow.md` — step-by-step procedure the skill follows.
- `references/verbs.md` — full natural-language → CLI translation table.
- `scripts/check-prereqs.sh` — verifies the `smartvedit` binary is
  reachable; prints remediation if not.
- `scripts/exec.sh` — thin wrapper that reads the cached invocation
  and forwards every arg verbatim.
- `tests/test_workflow.sh` — bash-runner tests for the skill's own
  contract (frontmatter, trigger coverage, prereq check, exec default).
