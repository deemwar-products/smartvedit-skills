#!/usr/bin/env bash
# check-prereqs.sh — verify the smartvedit CLI is reachable.
#
# Reads the saved invocation preference from
# ~/.config/muthuishere-agent-skills/smartvedit/config.json (jq); if
# absent, defaults to `smartvedit` on PATH. If the chosen invocation is
# `npx smartvedit-cli`, checks that `npx` is on PATH instead.
#
# Exit codes:
#   0 — CLI is reachable (or npx fallback is reachable)
#   1 — neither path works; diagnostics + remediation printed on stderr.
#
# Diagnostics + remediation go to stderr; stdout stays clean so callers
# can use the script as a quiet probe.

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

# The first whitespace-delimited word is the binary that needs to exist on PATH.
binary="${invocation%% *}"

if ! command -v "$binary" >/dev/null 2>&1; then
  {
    echo "smartvedit pre-flight: '$binary' is not on PATH."
    echo ""
    echo "Install the smartvedit CLI:"
    echo "  npm i -g smartvedit-cli"
    echo ""
    echo "Or use it without installing by prefixing every call:"
    echo "  npx smartvedit-cli <verb> <kind> [flags...]"
    echo ""
    echo "To pin the npx-fallback invocation for this skill, write:"
    echo "  mkdir -p $CONFIG_DIR"
    printf '  printf %s > %s\n' "'{\"invocation\": \"npx smartvedit-cli\"}\\n'" "$CONFIG_FILE"
  } >&2
  exit 1
fi

exit 0
