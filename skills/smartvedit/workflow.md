---
name: smartvedit-workflow
---

# smartvedit workflow

Translate a natural-language request into the right `smartvedit`
invocation, confirm it, run it, and surface the result.

## Variables

- `{project-root}` — the user's active project folder (where the skill
  was triggered). All commands run from here.
- `{skill-root}` — `.claude/skills/smartvedit/` inside this repo.
- `{config-dir}` — `~/.config/muthuishere-agent-skills/smartvedit/`
  (where the invocation preference is cached).
- `{invocation}` — either `smartvedit` (when installed globally) or
  `npx smartvedit-cli` (no-install fallback). Resolved in step 1.

## Core rules

- Show the literal `{invocation} ...` command BEFORE running it. Wait
  for the user's confirmation. Wrong flags can deduct credits or cancel
  the wrong job.
- Never guess silently between two plausible parses (e.g. "the latest"
  vs. a specific id). If both fit, ask one specific question.
- Default every `create` to `--wait`. The skill streams progress and
  surfaces the final `output_url`. Pipelines wait between steps by
  default; only pass `--no-wait-final` when the user explicitly says
  "fire-and-forget" / "don't wait".
- Use `--latest` (no status) for "the latest", "this video", "my last
  job". Use `--latest ok` when the user said "finished" / "completed" /
  "done". Use the explicit id only when the user gave one.
- Pipe stderr verbatim. Do not paraphrase CLI errors.

## Process

### 1. Pre-flight: CLI present?

Run:

    bash {skill-root}/scripts/check-prereqs.sh

If exit is non-zero, the `smartvedit` binary isn't on PATH. Propose the
two options to the user:

- **Install globally**: `npm i -g smartvedit-cli`
- **No install (every call prefixed)**: use `npx smartvedit-cli`

Ask which they prefer. Save the choice as JSON in
`{config-dir}/config.json`:

    mkdir -p {config-dir}
    printf '{"invocation": "smartvedit"}\n'         > {config-dir}/config.json   # global
    printf '{"invocation": "npx smartvedit-cli"}\n' > {config-dir}/config.json   # npx

From this point on, every `smartvedit ...` you'd run goes through:

    bash {skill-root}/scripts/exec.sh <verb> <kind> [flags...]

which reads `config.json` and prepends the right prefix. If
`config.json` is missing, `exec.sh` defaults to bare `smartvedit`.

### 2. Auth check

Run quietly:

    bash {skill-root}/scripts/exec.sh whoami

If it errors with "not logged in":

- Default: `bash {skill-root}/scripts/exec.sh login` (interactive
  Firebase browser sign-in).
- Fallback for headless / password-only accounts:
  `bash {skill-root}/scripts/exec.sh login-password`.

If the user just said "log into smartvedit", run the appropriate one
and stop.

### 3. Parse the request → verb + kind + flags

Use the translation table in `./references/verbs.md`. Every
natural-language category maps to one CLI shape:

- `login`, `login-password`, `logout`, `whoami`
- `get jobs`, `get job <id|--latest>`, `get videos`
- `describe job <id|--latest>`
- `watch job <id|--latest>`
- `create trim-pauses --source <id|--latest> [--min-pause N] --wait`
- `create captions --source <id|--latest> [--font-size N] [--position top|bottom] --wait`
- `create level --source <id|--latest> [--target-lufs N] --wait`
- `create cut --source <id|--latest> [--start <time>] [--end <time>] --wait` — explicit in/out range, stream-copy (see `references/verbs.md` "Cut")
- `create remaster --source <id|--latest> --wait` (see the caution note in "Catalog vocabulary" below)
- `create highlights --source <id|--latest> [--preset reel|quotes] --wait` (same caution)
- `create pipeline --source <id|--latest> --steps trim_pauses,captions,level,remaster,highlights[,...] [--no-wait-final]`
- `delete job <id|--latest>`

### 4. Resolving the source

The CLI maps `--source --latest` to "most recent job", and
`--source --latest ok` to "most recent job in status=ok". If the user
said "the latest" / "this video" / "my last analyzed video", pick
`--source --latest ok` (you want a completed source so the action
actually starts). For "the latest job" with no status hint, use
`--source --latest`.

If the user gave an explicit job id (UUID or shortened prefix the CLI
accepts), pass it verbatim: `--source <id>`.

### 5. Confirm the literal invocation

Print the full command, then ASK the user to confirm. Example:

    > I'm about to run:
    >
    >     {invocation} create captions --source --latest ok --font-size 36 --position bottom --wait
    >
    > OK to run? (y/N)

Do not skip this step even for innocuous reads like `get jobs`. It is
how the user catches a wrong job reference before credits are spent.

### 6. Execute

After confirmation:

    bash {skill-root}/scripts/exec.sh <verb> <kind> [flags...]

`exec.sh` forwards every arg verbatim and pipes stderr through
unfiltered. With `--wait`, the CLI streams status transitions; surface
them line by line.

### 7. Report

On success, summarise in one line:

- action / source job / credits used (parsed from the CLI's JSON
  output)
- the playable `output_url` (always present after a successful `create
  ... --wait`; for `create pipeline`, the URL of the final step)

On failure, surface stderr verbatim and suggest:

    {invocation} describe job <id>

so the user can inspect the worker error.

## Pipelines

The `create pipeline` kind chains fixers in order, threading each
step's output as the next step's source. Example:

    {invocation} create pipeline --source --latest ok \
      --steps trim_pauses,captions,level

Defaults:

- Each intermediate step waits to terminal before the next is
  submitted.
- The final step also waits unless `--no-wait-final` is passed.
- Step names match the catalog: `trim_pauses`, `captions`, `level`,
  `remaster`, `highlights`. Pipeline-only aliases for the two
  highlights presets: `highlights_reel`, `highlights_quotes` (the
  CLI maps them to `highlights --preset reel|quotes`).

If the user says "first A then B then C", expand to `--steps A,B,C`
in that order. If two phrasings are equally valid (e.g. "captions
then level" vs. "level then captions"), confirm the intended order
before submitting.

## Job references — quick reference

| User says | Pass to the CLI |
|---|---|
| "the latest video", "my last analyzed video", "this video" | `--source --latest ok` |
| "the latest job" (status unspecified) | `--source --latest` |
| "the latest failed job" | `--source --latest error` |
| "<UUID>" or "job abc123…" | `--source <id>` |

## Catalog vocabulary (live actions)

These are the `create` kinds the skill supports today; each maps to a
catalog entry in `specs/09-auto-editing.md` and a wizard tile in
`specs/10-wizard-action-picker.md`:

- **trim_pauses** — cut dead air & filler words
- **captions** — transcribe + burn subtitles
- **level** — loudness normalise to -14 LUFS
- **cut** — trim to an explicit in/out range (stream-copy, near-instant)
- **remaster** — upscale + face restore (GPU)
- **highlights** — pick & assemble the best moments (`--preset reel`
  or `--preset quotes`)
- **pipeline** — chain any of the above in order

**Caution — remaster/highlights (2026-07-05):** these two are GPU-lane
actions delegated to a serverless RunPod endpoint. As of this date that
lane is unreliable in production (endpoint churn / dispatch failures),
and the smartvedit web app hides both tiles for exactly this reason. The
CLI verbs still exist and will accept a job, but expect a real chance of
failure after credits are already charged. If the user asks for either,
say so plainly before running it and let them decide — don't submit
silently assuming it'll work.

Coming-soon fixers from the same catalog (stabilize, denoise, gaze,
mouth) are NOT in the CLI yet — if the user asks for one, say so and
offer the closest live alternative. Several *live* web-app fixers also
aren't in the CLI yet either: `vertical`, `looks`, `voice_swap`,
`split_images`, `quotes`, `people` (person detection + composition) all
work via the smartvedit.com web app today but have no CLI verb — say so
if asked, don't invent flags for them.
