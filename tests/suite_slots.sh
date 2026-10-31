#!/usr/bin/env bash
# Runs a command while holding one of the PC-wide suite slots (EASYCRAFT_SUITE_SLOTS, default 3).
# Many agents' full suites at once overloaded the shared PC (load 63 on 24 cores, 2026-09-24 22:14), and
# another app with its own emulator is built on this PC too. A run waits for a free slot; the lock goes
# with the process, so a killed run frees its slot.
#   tests/suite_slots.sh tests/run_tests.sh
set -uo pipefail
slots="${EASYCRAFT_SUITE_SLOTS:-3}"
dir="${TMPDIR:-/tmp}/easycraft-suite-slots"
mkdir -p "$dir"
waited=0
while true; do
	for i in $(seq 1 "$slots"); do
		exec {fd}>"$dir/slot$i"
		if flock -n "$fd"; then
			[[ $waited -gt 0 ]] && echo "suite_slots: got slot $i after ${waited} s" >&2
			EASYCRAFT_SLOT_HELD=1 "$@"
			exit $?
		fi
		exec {fd}>&-
	done
	sleep 5
	waited=$((waited + 5))
done
