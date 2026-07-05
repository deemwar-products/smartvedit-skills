---
name: smartvedit
description: >
  Drive the smartvedit Node.js CLI for the video-ai backend from natural
  language. Translates requests like "smartvedit X", "run smartvedit X",
  "trim pauses on this video", "trim pauses on the latest job", "trim
  pauses on job X", "auto-caption this", "burn captions on X", "generate
  captions", "normalize loudness", "level the audio", "fix levels on X",
  "remaster the latest", "remaster HD on X", "upscale this video", "find
  reels", "pick the best moments", "make a reel from X", "find quotes",
  "pull quotes", "find quotable moments", "run a pipeline of A then B
  then C on this video", "list my smartvedit jobs", "show my jobs",
  "what jobs do I have", "describe job X", "show me job X", "watch job
  X", "wait for job X", "cancel job X", "delete job X", and "log into
  smartvedit" into the right `smartvedit` invocation (verb + kind +
  flags). Confirms the literal command before running. Requires the
  `smartvedit` CLI on PATH (`npm i -g smartvedit-cli`) or falls back to
  `npx smartvedit-cli`.
---

# smartvedit

Use this skill when the user wants to drive the video-ai backend from
the shell — submit fixers (trim pauses, captions, level, remaster,
highlights), chain them in a pipeline, inspect / watch / cancel jobs,
or log in.

The skill turns natural-language requests into the right `smartvedit`
CLI invocation. It does not call the HTTP API directly — the Node CLI
(npm package `smartvedit-cli`, bin `smartvedit`) is the single source
of truth for the verb / kind / flag grammar.

## Core rules

- The skill REQUIRES the `smartvedit` CLI from npm:
  `npm i -g smartvedit-cli`. If the binary isn't on PATH, fall back to
  `npx smartvedit-cli` (no install).
- Auth lives in `${XDG_CONFIG_HOME:-~/.config}/smartvedit/token`. If
  `whoami` errors with "not logged in", run `smartvedit login`
  (interactive Firebase browser flow), or `smartvedit login-password`
  for the username/password fallback.
- Default every `create` to `--wait` so the skill streams progress and
  surfaces the final `output_url`. Pipelines wait between steps by
  default; pass `--no-wait-final` only when the user explicitly asks
  for fire-and-forget.
- For ambiguous job references ("the latest", "this video", "my last
  job"), use `--latest` (no status), or `--latest ok` when the user
  said "finished" / "completed" / "done".
- ALWAYS print the literal `smartvedit ...` invocation and confirm
  before running. Do not guess silently.

Follow the procedure in `./workflow.md`. The natural-language → CLI
translation table is in `./references/verbs.md`.
