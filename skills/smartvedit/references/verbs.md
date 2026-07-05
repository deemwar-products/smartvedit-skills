---
name: smartvedit-verbs
---

# Natural-language → smartvedit CLI

The canonical translation table. Every row is "When user says …" →
"Run …". `{invocation}` is either `smartvedit` (global install) or
`npx smartvedit-cli`, resolved by `scripts/exec.sh`.

For job references inside `--source`:

- "the latest video" / "my last analyzed video" / "this video" → `--source --latest ok`
- "the latest job" → `--source --latest`
- "the latest failed job" → `--source --latest error`
- explicit id given → `--source <id>`

Every `create` defaults to `--wait` so the skill streams progress and
surfaces the final `output_url`.

## Auth

| When user says… | Run |
|---|---|
| "log into smartvedit", "sign in to smartvedit", "smartvedit login" | `{invocation} login` |
| "log in with password", "username and password login", "headless login" | `{invocation} login-password` |
| "log out of smartvedit", "forget my smartvedit token" | `{invocation} logout` |
| "who am I in smartvedit", "smartvedit whoami", "show my smartvedit account" | `{invocation} whoami` |

## List / inspect

| When user says… | Run |
|---|---|
| "list my smartvedit jobs", "show my jobs", "what jobs do I have", "my smartvedit jobs" | `{invocation} get jobs` |
| "list my completed jobs", "show finished jobs" | `{invocation} get jobs --status ok` |
| "list my failed jobs", "show jobs that errored" | `{invocation} get jobs --status error` |
| "list my videos", "show my smartvedit videos", "my video library" | `{invocation} get videos` |
| "show job X", "what is job X", "details of job X" | `{invocation} get job <id>` |
| "show the latest job" | `{invocation} get job --latest` |
| "describe job X", "show me job X", "full details of job X" | `{invocation} describe job <id>` |
| "describe the latest job" | `{invocation} describe job --latest` |

## Watch

| When user says… | Run |
|---|---|
| "watch job X", "wait for job X", "follow job X" | `{invocation} watch job <id>` |
| "watch the latest job", "wait for the latest job" | `{invocation} watch job --latest` |

## Delete / cancel

| When user says… | Run |
|---|---|
| "delete job X", "remove job X" | `{invocation} delete job <id>` |
| "cancel job X", "stop job X", "kill job X" | `{invocation} delete job <id>` |
| "cancel the latest job", "stop the latest job" | `{invocation} delete job --latest` |

## Trim pauses

| When user says… | Run |
|---|---|
| "trim pauses on this video", "cut the dead air on the latest", "trim pauses" | `{invocation} create trim-pauses --source --latest ok --wait` |
| "trim pauses on job X" | `{invocation} create trim-pauses --source <id> --wait` |
| "trim pauses with a 0.6 second threshold on the latest" | `{invocation} create trim-pauses --source --latest ok --min-pause 0.6 --wait` |

## Captions

| When user says… | Run |
|---|---|
| "auto-caption this", "burn captions on the latest", "generate captions", "add captions to this video" | `{invocation} create captions --source --latest ok --wait` |
| "burn captions on job X" | `{invocation} create captions --source <id> --wait` |
| "captions with bottom position on the latest" | `{invocation} create captions --source --latest ok --position bottom --wait` |
| "big captions on the latest" | `{invocation} create captions --source --latest ok --font-size 48 --wait` |

## Level (loudness)

| When user says… | Run |
|---|---|
| "normalize loudness on this video", "level the audio", "fix levels on the latest" | `{invocation} create level --source --latest ok --wait` |
| "fix levels on job X" | `{invocation} create level --source <id> --wait` |
| "target -16 LUFS on the latest" | `{invocation} create level --source --latest ok --target-lufs -16 --wait` |

## Remaster

| When user says… | Run |
|---|---|
| "remaster the latest", "remaster HD on this video", "upscale this video", "remaster" | `{invocation} create remaster --source --latest ok --wait` |
| "remaster job X" | `{invocation} create remaster --source <id> --wait` |

## Highlights

| When user says… | Run |
|---|---|
| "find reels on the latest", "pick the best moments", "make a reel from the latest" | `{invocation} create highlights --source --latest ok --preset reel --wait` |
| "make a reel from job X" | `{invocation} create highlights --source <id> --preset reel --wait` |
| "find quotes on the latest", "pull quotes", "find quotable moments" | `{invocation} create highlights --source --latest ok --preset quotes --wait` |
| "find quotes in job X" | `{invocation} create highlights --source <id> --preset quotes --wait` |

## Pipeline (multi-step)

Step names match the catalog: `trim_pauses`, `captions`, `level`,
`remaster`, `highlights`. Pipeline-only aliases for the two highlights
presets: `highlights_reel`, `highlights_quotes`.

| When user says… | Run |
|---|---|
| "run a pipeline of trim pauses then captions on this video" | `{invocation} create pipeline --source --latest ok --steps trim_pauses,captions` |
| "first trim pauses, then level, then captions on the latest" | `{invocation} create pipeline --source --latest ok --steps trim_pauses,level,captions` |
| "trim pauses and then captions and then highlights reel on job X" | `{invocation} create pipeline --source <id> --steps trim_pauses,captions,highlights_reel` |
| "run a pipeline on the latest and don't wait" | `{invocation} create pipeline --source --latest ok --steps <steps> --no-wait-final` |
| "remaster then highlights reel on this video" | `{invocation} create pipeline --source --latest ok --steps remaster,highlights_reel` |
