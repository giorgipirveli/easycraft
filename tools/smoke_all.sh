#!/usr/bin/env bash
# Every headless smoke run (tools/*_smoke.gd) one after another: the M3 acceptance's end-to-end part (plan Task 18,
# the lead's ruling 2026-09-25: the feature smoke runs on the final tree, plus the emulator runs). Each run gets a
# fresh private folder whose path contains "smoke", with a copy of this PC's profile.json, a time limit and nice.
# One line per run (PASS / FAIL / TIMEOUT, its seconds and log), then "SMOKE_ALL passed=<n> failed=<m>"; exits 0
# when every run passed. Logs stay in $SMOKE_ALL_DIR (default /tmp/easycraft-smoke-all).
#   tools/smoke_all.sh              # all of them
#   tools/smoke_all.sh farm quest   # only these (names without _smoke.gd)
# Holds one PC-wide suite slot for the whole run (tests/suite_slots.sh): the PC is shared with another app.
set -uo pipefail
cd "$(dirname "$0")/.."
if [[ -z "${EASYCRAFT_SLOT_HELD:-}" ]]; then
	exec tests/suite_slots.sh tools/smoke_all.sh "$@"
fi
root="${SMOKE_ALL_DIR:-/tmp/easycraft-smoke-all}"
limit="${SMOKE_ALL_LIMIT:-600}"
profile="${XDG_DATA_HOME:-$HOME/.local/share}/godot/app_userdata/EasyCraft/profile.json"
rm -rf "$root"
mkdir -p "$root"
names=("$@")
if [[ ${#names[@]} -eq 0 ]]; then
	for f in tools/*_smoke.gd; do
		n="$(basename "$f" .gd)"
		names+=("${n%_smoke}")
	done
fi
passed=0
failed=0
for n in "${names[@]}"; do
	home="$root/$n-smoke"
	mkdir -p "$home/godot/app_userdata/EasyCraft"
	[[ -f "$profile" ]] && cp "$profile" "$home/godot/app_userdata/EasyCraft/profile.json"
	log="$root/$n.log"
	start=$(date +%s)
	XDG_DATA_HOME="$home" timeout "$limit" nice -n 10 godot --headless --path . --script "res://tools/${n}_smoke.gd" \
		> "$log" 2>&1
	code=$?
	took=$(( $(date +%s) - start ))
	if [[ $code -eq 0 ]] && ! grep -qE "SCRIPT ERROR|Parse Error" "$log"; then
		echo "SMOKE $n PASS ${took}s"
		passed=$((passed + 1))
	else
		what="FAIL"
		[[ $code -eq 124 ]] && what="TIMEOUT"
		grep -qE "SCRIPT ERROR|Parse Error" "$log" && what="$what (script error)"
		echo "SMOKE $n $what exit=$code ${took}s $log"
		failed=$((failed + 1))
	fi
done
echo "SMOKE_ALL passed=$passed failed=$failed"
[[ $failed -eq 0 ]]
