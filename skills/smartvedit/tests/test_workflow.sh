#!/usr/bin/env bash
# test_workflow.sh — bash-runner tests for the smartvedit skill.
#
# Iterates every function whose name starts with `test_`, prints
# PASS/FAIL per test, exits non-zero if any failed.

set -u

SKILL_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILL_MD="$SKILL_ROOT/SKILL.md"
WORKFLOW_MD="$SKILL_ROOT/workflow.md"
VERBS_MD="$SKILL_ROOT/references/verbs.md"
CHECK_SH="$SKILL_ROOT/scripts/check-prereqs.sh"
EXEC_SH="$SKILL_ROOT/scripts/exec.sh"

# ---- helpers ---------------------------------------------------------------

# fail <message> — record an assertion failure for the current test.
fail() {
  CURRENT_TEST_FAILED=1
  echo "  ✗ $*" >&2
}

# assert_grep <pattern> <file> <description>
assert_grep() {
  local pattern="$1" file="$2" desc="$3"
  if ! grep -q -- "$pattern" "$file" 2>/dev/null; then
    fail "$desc — expected pattern '$pattern' in $file"
  fi
}

# ---- tests -----------------------------------------------------------------

test_skill_md_frontmatter() {
  [[ -f "$SKILL_MD" ]] || { fail "SKILL.md missing at $SKILL_MD"; return; }
  # First non-empty line must be the frontmatter opener.
  local first
  first="$(awk 'NF{print; exit}' "$SKILL_MD")"
  [[ "$first" == "---" ]] || fail "SKILL.md does not start with '---' frontmatter (got: '$first')"
  # name + description fields inside the frontmatter block.
  awk '/^---$/{c++; next} c==1{print}' "$SKILL_MD" | grep -qE '^name:[[:space:]]*smartvedit[[:space:]]*$' \
    || fail "SKILL.md frontmatter missing 'name: smartvedit'"
  awk '/^---$/{c++; next} c==1{print}' "$SKILL_MD" | grep -qE '^description:' \
    || fail "SKILL.md frontmatter missing 'description:' field"
}

test_workflow_md_lists_every_create_kind() {
  [[ -f "$WORKFLOW_MD" ]] || { fail "workflow.md missing at $WORKFLOW_MD"; return; }
  local kind
  for kind in trim_pauses captions level remaster highlights pipeline; do
    assert_grep "$kind" "$WORKFLOW_MD" "workflow.md must mention catalog kind '$kind'"
  done
}

test_verbs_md_covers_every_trigger_category() {
  [[ -f "$VERBS_MD" ]] || { fail "references/verbs.md missing at $VERBS_MD"; return; }
  # Map each required category to a string that must appear in the table.
  # The right-hand string is matched as a fixed (grep -F) substring.
  local checks=(
    "login|login"
    "list|get jobs"
    "describe|describe job"
    "watch|watch job"
    "delete|delete job"
    "trim_pauses|create trim-pauses"
    "captions|create captions"
    "level|create level"
    "remaster|create remaster"
    "highlights|create highlights"
    "pipeline|create pipeline"
  )
  local pair name needle
  for pair in "${checks[@]}"; do
    name="${pair%%|*}"
    needle="${pair#*|}"
    if ! grep -qF -- "$needle" "$VERBS_MD"; then
      fail "verbs.md missing row for category '$name' (needle: '$needle')"
    fi
  done
}

test_check_prereqs_no_smartvedit() {
  [[ -x "$CHECK_SH" || -f "$CHECK_SH" ]] || { fail "check-prereqs.sh missing"; return; }
  # Strip every PATH entry that contains a `smartvedit` binary so the
  # script's `command -v smartvedit` lookup fails deterministically.
  local stripped_path
  stripped_path="$(_path_without_smartvedit)"
  local rc=0 out
  # Also point XDG_CONFIG_HOME at an empty dir so the default
  # invocation (`smartvedit`) is what gets probed.
  local tmpdir
  tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t smartvedit-test)"
  out="$(env -i PATH="$stripped_path" HOME="$HOME" XDG_CONFIG_HOME="$tmpdir" \
    bash "$CHECK_SH" 2>&1)" && rc=$? || rc=$?
  rm -rf "$tmpdir"
  if [[ "$rc" -eq 0 ]]; then
    fail "check-prereqs.sh returned 0 with no smartvedit on PATH (expected non-zero)"
  fi
  # Remediation must mention installing or npx-falling-back.
  if ! echo "$out" | grep -q "npm i -g smartvedit-cli"; then
    fail "check-prereqs.sh remediation did not mention 'npm i -g smartvedit-cli'"
  fi
  if ! echo "$out" | grep -q "npx smartvedit-cli"; then
    fail "check-prereqs.sh remediation did not mention 'npx smartvedit-cli'"
  fi
  if ! echo "$out" | grep -qi "not on PATH"; then
    fail "check-prereqs.sh remediation did not mention the binary is not on PATH"
  fi
}

# Build a PATH string with all directories that contain a `smartvedit`
# binary removed. Pure shell; portable to macOS bash 3.2.
_path_without_smartvedit() {
  local IFS=:
  local out="" dir
  for dir in $PATH; do
    [[ -z "$dir" ]] && continue
    if [[ -e "$dir/smartvedit" ]]; then
      continue
    fi
    if [[ -z "$out" ]]; then out="$dir"; else out="$out:$dir"; fi
  done
  echo "$out"
}

test_exec_sh_invokes_default_smartvedit() {
  [[ -f "$EXEC_SH" ]] || { fail "exec.sh missing"; return; }
  # Stub `smartvedit` in a temp PATH dir so we can capture the exact
  # args the wrapper forwarded.
  local bindir tmpdir argfile
  bindir="$(mktemp -d 2>/dev/null || mktemp -d -t smartvedit-bin)"
  tmpdir="$(mktemp -d 2>/dev/null || mktemp -d -t smartvedit-cfg)"
  argfile="$tmpdir/args"

  cat > "$bindir/smartvedit" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$ARGFILE"
STUB
  chmod +x "$bindir/smartvedit"

  # Run exec.sh with an EMPTY config dir → must default to bare smartvedit.
  ARGFILE="$argfile" PATH="$bindir:$PATH" XDG_CONFIG_HOME="$tmpdir" \
    bash "$EXEC_SH" whoami --json >/dev/null 2>&1 || true

  if [[ ! -f "$argfile" ]]; then
    fail "exec.sh did not invoke the stub smartvedit (no args captured)"
  else
    local got
    got="$(tr '\n' ' ' < "$argfile" | sed 's/[[:space:]]*$//')"
    if [[ "$got" != "whoami --json" ]]; then
      fail "exec.sh forwarded wrong args (got: '$got', want: 'whoami --json')"
    fi
  fi

  rm -rf "$bindir" "$tmpdir"
}

# ---- runner ----------------------------------------------------------------

main() {
  local failed=0 total=0 tests
  # Discover every function named test_*.
  tests=$(declare -F | awk '$3 ~ /^test_/{print $3}')
  for t in $tests; do
    total=$((total + 1))
    CURRENT_TEST_FAILED=0
    echo "▶ $t"
    "$t"
    if [[ "$CURRENT_TEST_FAILED" -eq 0 ]]; then
      echo "  PASS"
    else
      echo "  FAIL"
      failed=$((failed + 1))
    fi
  done
  echo ""
  echo "$((total - failed))/$total passed"
  [[ "$failed" -eq 0 ]] || exit 1
}

main "$@"
