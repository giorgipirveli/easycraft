#!/usr/bin/env bash
# M4 ghost races over a real Nakama server with two headless games (tools/ghost_net_test.gd): Hopper puts his
# showcase up with his race on a course; Mia says yes to his friend request, visits the showcase, races his
# ghost in the real visit scene, leaves a sticker and finds it kept for offline races; both delete their test
# accounts. The server must run module 0.2.6 or later. Each game gets a private user folder (XDG_DATA_HOME).
#   tools/ghost_net_test.sh [--server=<host:port>] [--keep]
# Prints both games' GHOSTNET lines and exits 0 when both passed.
set -uo pipefail
builtin cd "$(dirname "$0")/.."
server="127.0.0.1:7350"
keep=0
for a in "$@"; do
	case "$a" in
		--server=*) server="${a#--server=}" ;;
		--keep) keep=1 ;;
		*) echo "unknown argument: $a" >&2; exit 2 ;;
	esac
done
tag="$(tr -dc 'a-z0-9' < /dev/urandom | head -c 5)"
hopper="GhH${tag}"
mia="GhM${tag}"
work="$(mktemp -d "${TMPDIR:-/tmp}/easycraft-ghost-net.XXXXXX")"
for who in hopper mia; do
	dir="$work/$who/godot/app_userdata/EasyCraft"
	mkdir -p "$dir"
	name="$hopper"
	[[ $who == mia ]] && name="$mia"
	printf '{"version":1,"username":"%s","age_band":"13_plus"}\n' "$name" > "$dir/profile.json"
done
args=(--server="$server" --hopper="$hopper" --mia="$mia")
XDG_DATA_HOME="$work/hopper" timeout 240 godot --headless --max-fps 60 --path . --script res://tools/ghost_net_test.gd -- --role=hopper "${args[@]}" > "$work/hopper.log" 2>&1 &
hopper_pid=$!
XDG_DATA_HOME="$work/mia" timeout 240 godot --headless --max-fps 60 --path . --script res://tools/ghost_net_test.gd -- --role=mia "${args[@]}" > "$work/mia.log" 2>&1 &
mia_pid=$!
wait "$hopper_pid"
hopper_status=$?
wait "$mia_pid"
mia_status=$?
grep -h -E 'GHOSTNET|SCRIPT ERROR' "$work/hopper.log" "$work/mia.log"
if [[ $hopper_status -eq 0 && $mia_status -eq 0 ]]; then
	echo "GHOSTNET PASS"
	[[ $keep -eq 1 ]] && echo "logs: $work" || rm -rf "$work"
	exit 0
fi
echo "GHOSTNET FAIL (hopper $hopper_status, mia $mia_status); logs: $work"
exit 1
