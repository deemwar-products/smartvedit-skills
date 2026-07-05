---
name: smartvedit
description: Auto-edit a video from the command line — trim pauses, burn captions, normalize loudness, upscale, or pull highlight reels/quotes — by driving the `smartvedit` CLI. Use when the user wants to "clean up this video", "cut the dead air", "add captions", "fix the audio levels", "upscale this clip", "find the highlights/best quotes", or wants to chain several of those in one pass. Handles login, job submission, waiting for results, and chaining steps into a pipeline.
---

# smartvedit — auto-edit videos via the smartvedit CLI

`smartvedit` is deemwar's video auto-editing product. This skill drives its CLI
(`smartvedit-cli` on npm, bin `smartvedit`) so you (the agent) can submit jobs,
watch them, and chain fixers into a pipeline on the user's behalf.

## Prerequisite

The `smartvedit` CLI must be on PATH:

```sh
npm install -g smartvedit-cli
smartvedit --version
```

If it's missing, install it first — don't try to hit the HTTP API directly;
the CLI owns auth, job-ref resolution (`latest`, `latest:ok`), and polling.

## Login (once per machine)

```sh
smartvedit login             # Firebase Google sign-in, opens a browser
smartvedit whoami            # confirms {id, username, email, credits_balance}
```

Cached token lives on disk after this — no need to log in again per command.
If the user has no browser handy, `smartvedit login-password <user> <pass>`
is the fallback.

## The fixers

Every whole-video action is a `create <action>` verb. All take `--source <ref>`
(a job id, or the bare word `latest` / `latest:ok` for "whatever I just
uploaded/finished"), and `--wait` to block until done and print the result
instead of just a queued ack.

| Command | What it does |
|---|---|
| `smartvedit create trim-pauses --source <ref> --min-pause <s> --wait` | Cuts dead air / long pauses. |
| `smartvedit create captions --source <ref> --font-size <int> --position top\|bottom --wait` | Burns in captions. |
| `smartvedit create level --source <ref> --target-i <db> --wait` | Normalizes loudness (EBU R128-style). |
| `smartvedit create remaster --source <ref> --wait` | GPU upscale/remaster. |
| `smartvedit create highlights --source <ref> --preset reel\|quotes --wait` | Pulls a highlight reel or best-quotes cut. |

Without `--wait`, the command prints a queued job id and a copy-pasteable
next step (`smartvedit watch job <id>`) — use that instead of polling by hand.

## Chaining steps (pipeline)

```sh
smartvedit create pipeline --source <ref> --steps trim_pauses,level,captions --wait
```

Valid step names: `trim_pauses`, `captions`, `level`, `remaster`, `highlights`
(alias for `highlights:reel`), `highlights:reel`, `highlights:quotes`. Each
step's output becomes the next step's `--source`. If a step fails, the
pipeline halts there — don't retry blindly, surface the error to the user.

## Inspecting and cleaning up

```sh
smartvedit get jobs --status running          # or -o json for scripting
smartvedit get job latest                     # last job, any status
smartvedit describe job <ref>                 # full job + result JSON
smartvedit watch job latest                    # follow a job to completion
smartvedit delete job latest                   # cancel-then-delete
```

## Rules of engagement

- Always resolve what the user means by "that video" / "the last one" to
  `latest` (or `latest:ok` if they mean the last *successful* one) rather
  than asking them to hunt for a job id.
- Don't invent flags — if a fixer needs a parameter not listed above, run
  `smartvedit create <action> --help` and read the real flag names before
  guessing.
- Report credits used and the `output_url` back to the user after a job
  completes; don't just say "done".
- This skill only covers the CLI-scriptable whole-video fixers. Actions that
  need a person-picker or free-typed text (multi-person compose/focus, add-quote
  text) go through the smartvedit.com web app, not this skill.
