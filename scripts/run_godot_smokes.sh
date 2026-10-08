#!/usr/bin/env bash
# scripts/run_godot_smokes.sh — run every headless Godot smoke under game/tests/.
#
# Discovers game/tests/*_smoke.gd automatically (new smokes need no edits here),
# does a one-off `--import` pass, then runs each smoke headless with a per-smoke
# timeout. A smoke fails if it exits non-zero OR its output contains known Godot
# failure text (SCRIPT ERROR / Parse Error / a printed FAIL) even with exit 0.
#
# Usage:
#   scripts/run_godot_smokes.sh [smoke ...]   # subset is optional; names may be
#                                             # given with or without _smoke / .gd
#
# Env overrides:
#   GODOT         Godot binary to use (default: godot from PATH)
#   SMOKE_TIMEOUT per-smoke timeout in seconds (default: 120)
#   SMOKE_LOG     combined log file (default: a fresh file under $TMPDIR)
#
# Exit codes: 0 = all passed (skips do not fail the run), 1 = at least one
# failed, 2 = usage error (e.g. an unknown smoke name was requested).
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GAME_DIR="game"
GODOT="${GODOT:-godot}"
SMOKE_TIMEOUT="${SMOKE_TIMEOUT:-120}"
SMOKE_LOG="${SMOKE_LOG:-$(mktemp "${TMPDIR:-/tmp}/godot-smokes-log.XXXXXX")}"

# ---------------------------------------------------------------------------
# Skip list — smokes that genuinely cannot run headless in CI.
# Every entry MUST carry a stated reason; add new entries as "name|reason".
# A skipped smoke prints as SKIP in the table and does not fail the run.
# (Currently empty: all game/tests/*_smoke.gd run headless.)
SKIP_LIST=(
  # "example_smoke|requires a GPU/display; see <issue or bus note>"
)
# ---------------------------------------------------------------------------

die() { printf 'ERROR: %s\n' "$*" >&2; exit 2; }

[[ -d "$REPO_ROOT/$GAME_DIR" ]] || die "run from the Mobile Fortress repo (missing $GAME_DIR/)"
cd "$REPO_ROOT"
command -v "$GODOT" >/dev/null 2>&1 || die "Godot binary not found: $GODOT (set GODOT=/path/to/godot)"
[[ -d "$GAME_DIR/tests" ]] || die "no smoke directory at $GAME_DIR/tests"

# Master log: everything below is teed to SMOKE_LOG (uploaded as a CI artifact
# on failure by .github/workflows/godot-game.yml).
: >"$SMOKE_LOG"
exec > >(tee -a "$SMOKE_LOG") 2>&1

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Build the skip lookup.
declare -A SKIP_REASON=()
for entry in "${SKIP_LIST[@]}"; do
  SKIP_REASON["${entry%%|*}"]="${entry#*|}"
done

# --- Discover smokes (sorted, basename without .gd) -------------------------
shopt -s nullglob
discovered=()
for path in "$GAME_DIR"/tests/*_smoke.gd; do
  discovered+=("$(basename "$path" .gd)")
done
((${#discovered[@]} > 0)) || die "no *_smoke.gd files found under $GAME_DIR/tests"
mapfile -t discovered < <(printf '%s\n' "${discovered[@]}" | sort)

# --- Resolve optional subset args -------------------------------------------
smokes=()
if (($# > 0)); then
  for arg in "$@"; do
    name="${arg%.gd}"
    match=""
    for candidate in "${discovered[@]}"; do
      if [[ "$candidate" == "$name" || "$candidate" == "${name}_smoke" ]]; then
        match="$candidate"
        break
      fi
    done
    [[ -n "$match" ]] || die "unknown smoke: $arg (available: ${discovered[*]})"
    smokes+=("$match")
  done
else
  smokes=("${discovered[@]}")
fi

# --- One-off import pass ------------------------------------------------------
# Godot's headless --import can exit non-zero *after* a successful import
# (e.g. the Android export plugin aborts when no adb daemon is reachable).
# The import itself is idempotent and breakage is caught by the smokes'
# parse-error scan below, so a non-zero import exit only warrants a warning.
echo "== Import pass: $GODOT --path $GAME_DIR --headless --import =="
import_rc=0
timeout "$SMOKE_TIMEOUT" "$GODOT" --path "$GAME_DIR" --headless --import \
  >"$TMP_DIR/import.log" 2>&1 || import_rc=$?
sed -e 's/\x1b\[[0-9;]*m//g' "$TMP_DIR/import.log"
if ((import_rc != 0)); then
  echo "WARN: --import exited $import_rc (continuing; smokes still validate the project)"
fi
echo ""

# --- Run smokes ---------------------------------------------------------------
godot_version="$("$GODOT" --version 2>/dev/null | head -n1 || true)"
name_width=4 # "NAME"
for smoke in "${smokes[@]}"; do
  ((${#smoke} > name_width)) && name_width=${#smoke}
done

echo "== Godot headless smokes: ${#smokes[@]} selected (${#discovered[@]} discovered), binary: ${GODOT} (${godot_version}) =="
printf '%-*s  %-6s  %s\n' "$name_width" "SMOKE" "RESULT" "DETAIL"

passed=0
failed=0
skipped=0
failed_names=()

for smoke in "${smokes[@]}"; do
  if [[ -v "SKIP_REASON[$smoke]" ]]; then
    printf '%-*s  %-6s  %s\n' "$name_width" "$smoke" "SKIP" "reason: ${SKIP_REASON[$smoke]}"
    ((skipped += 1))
    continue
  fi

  out="$TMP_DIR/$smoke.log"
  start=$SECONDS
  rc=0
  timeout "$SMOKE_TIMEOUT" "$GODOT" --path "$GAME_DIR" --headless \
    --script "res://tests/$smoke.gd" >"$out" 2>&1 || rc=$?
  elapsed=$((SECONDS - start))

  # Strip ANSI escapes, then scan for known failure text even when rc == 0.
  sed -e 's/\x1b\[[0-9;]*m//g' "$out" >"$out.clean"
  matched=()
  if grep -q 'SCRIPT ERROR' "$out.clean"; then matched+=("SCRIPT ERROR"); fi
  if grep -q 'Parse Error' "$out.clean"; then matched+=("Parse Error"); fi
  if grep -Eq '(^|[^[:alnum:]_])FAIL([^[:alnum:]_]|$)' "$out.clean"; then matched+=("FAIL output"); fi

  if ((rc == 124 || rc == 137 || rc == 143)); then
    result="FAIL"
    detail="timeout after ${SMOKE_TIMEOUT}s"
    ((failed += 1))
    failed_names+=("$smoke")
  elif ((rc != 0)); then
    result="FAIL"
    detail="exit=$rc"
    ((${#matched[@]} > 0)) && detail+="; matched: ${matched[*]}"
    ((failed += 1))
    failed_names+=("$smoke")
  elif ((${#matched[@]} > 0)); then
    result="FAIL"
    detail="exit=0 but matched: ${matched[*]}"
    ((failed += 1))
    failed_names+=("$smoke")
  else
    result="PASS"
    detail="${elapsed}s"
    ((passed += 1))
  fi

  printf '%-*s  %-6s  %s\n' "$name_width" "$smoke" "$result" "$detail"

  # Append the smoke's own output to the master log for artifact debugging.
  {
    echo ""
    echo "----- $smoke (rc=$rc, ${elapsed}s) -----"
    cat "$out.clean"
  } >>"$SMOKE_LOG"
done

echo ""
echo "== Summary: $passed passed, $failed failed, $skipped skipped (of ${#smokes[@]} selected) =="
echo "Log: $SMOKE_LOG"

if ((failed > 0)); then
  echo "Failed smokes: ${failed_names[*]}"
  exit 1
fi
exit 0
