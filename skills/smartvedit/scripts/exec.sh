#!/usr/bin/env bash
# exec.sh — thin wrapper around the smartvedit CLI.
#
# Reads the invocation preference from
# ~/.config/muthuishere-agent-skills/smartvedit/config.json (jq); if
# absent or unreadable, defaults to bare `smartvedit`. Forwards every
# arg verbatim. Stderr is passed through unfiltered so CLI errors and
# `--wait` progress lines reach the caller untouched.
#
# Usage:
#   bash exec.sh whoami
#   bash exec.sh get jobs --status ok
#   bash exec.sh create captions --source --latest ok --wait

set -euo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/muthuishere-agent-skills/smartvedit"
CONFIG_FILE="$CONFIG_DIR/config.json"

invocation="smartvedit"
if [[ -f "$CONFIG_FILE" ]] && command -v jq >/dev/null 2>&1; then
  cached="$(jq -r '.invocation // "smartvedit"' < "$CONFIG_FILE" 2>/dev/null || echo "smartvedit")"
  if [[ -n "$cached" && "$cached" != "null" ]]; then
    invocation="$cached"
  fi
fi

# Split the cached invocation on whitespace so `npx smartvedit-cli`
# becomes ("npx" "smartvedit-cli") and `smartvedit` stays a single token.
# shellcheck disable=SC2206
parts=($invocation)

exec "${parts[@]}" "$@"
