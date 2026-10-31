#!/usr/bin/env bash
# Runs every GUT test under tests/unit headless; exits non-zero on any failure.
# GUT skips test scripts that fail to parse and still exits 0, so script errors are failures too.
set -uo pipefail
builtin cd "$(dirname "$0")/.."
# A tool's PATH shims (a Claude Code plugin's `python3` that refuses to run, 2026-10-16) never reach the tests: some
# tests run `python3 tools/...` (test_assets_pack_load.gd), and a shim made them fail outside the game.
PATH="$(printf '%s' "$PATH" | tr ':' '\n' | grep -v '/hooks/shims' | paste -sd: -)"
export PATH
# One of the PC-wide suite slots first (tests/suite_slots.sh): the PC is shared with another app.
if [[ -z "${EASYCRAFT_SLOT_HELD:-}" && "$*" != *-gtest=* ]]; then
	exec tests/suite_slots.sh tests/run_tests.sh "$@"
fi
out="$(mktemp)"
# -gtest=<files> runs only those files: GUT runs every -gdir too when both are given (owner 39 found every
# "single file" run was a whole ungated suite), so the directories are left out then.
dirs=(-gdir=res://tests/unit,res://tests/integration -ginclude_subdirs)
if [[ "$*" == *-gtest=* ]]; then
	dirs=()
fi
# tests/pre_run.gd: the age rules on for their own tests (the game ships with them off, AgeBand.restrictions).
nice -n 10 godot --headless --path . -s addons/gut/gut_cmdln.gd "${dirs[@]}" -gpre_run_script=res://tests/pre_run.gd -gexit "$@" 2>&1 | tee "$out"
status=${PIPESTATUS[0]}
if grep -qE 'SCRIPT ERROR|Parse Error' "$out"; then
	echo "run_tests: script errors found — failing the run" >&2
	status=1
fi
# A run that stops partway (killed, crashed, or GUT quitting early) can still exit 0: demand the
# summary, with a pass count, and no failing tests in it.
if ! grep -qE '^Passing Tests +[0-9]+' "$out"; then
	echo "run_tests: no test summary — the run stopped before the end; failing it" >&2
	status=1
elif grep -qE '^Failing Tests +[1-9]' "$out"; then
	status=1
fi
rm -f "$out"
exit "$status"
