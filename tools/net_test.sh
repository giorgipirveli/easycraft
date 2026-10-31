#!/usr/bin/env bash
# Two headless game instances play together and check each other (tools/net_test.gd): over the
# Nakama relay (the default; start the server first: server/dev.sh up) or over LAN (--lan).
# Each instance gets a private user folder (XDG_DATA_HOME) with a profile, so nothing touches the
# shared one. Prints both instances' NETTEST lines and exits 0 when both passed.
#   tools/net_test.sh [--lan] [--server=<address>] [--fly] [--drop=close|dead|never] [--no-smooth] [--fps=60] [--keep]
#                     [--invite] [--remove] [--delete-accounts] [--big] [--freeze] [--crew] [--move] [--login]
#   --server: the Nakama address (OnlineConfig.parse_server), default 127.0.0.1:7350
#   --fly:    then the guest flies 150 m and the host reports what the world cost meanwhile
#   --no-smooth: remote bodies are not smoothed between syncs (to compare; the host reports how the
#             guest's body moved on its screen while the guest played)
#   --drop:   (online) the guest's link drops after the checks and it must rejoin within 30 s:
#             close = the socket closes; dead = it is abandoned open (the server still has it);
#             never = it can't get back in: it must give up after 30 s and reach the menu
#   --fps:    the games' frame rate cap (default 60)
#   --keep:   keep the logs and user folders (printed); otherwise they are deleted when both pass
#   --invite: (online) the two games claim names and become friends first (tools/net_test_friends.gd), and the host
#             invites the guest into its match before the guest joins: a real server lets only invited friends in
#             (a development server also lets an unclaimed developer in)
#   --remove: after playing, the host removes the guest (spec §17.3): the guest must reach the menu with the host's
#             words and never rejoin; the host lets its player go at once
#   --delete-accounts: (online) afterwards both test accounts are deleted through the game's data-rights path
#             (tools/delete_test_account.gd), so a run against the live server leaves none behind
#   --vr=host|guest: (owner #101, P4) that game plays in a simulated headset (--vr-preview --vr-wave: its head nods
#             and turns, its right hand waves); the other must see it (NETTEST ... vr body)
#   --old=host|guest: (owner #101, P4) that game has no VrPoseLink under its players (--vr-old-peer), standing in for
#             a build from before P4: the two must still play together (old peers and new ones mixed) and it never
#             hears a pose
#   --crew:   (spec §21d.6 phase 2) instead of the edit checks: the host builds a 2-seat rocket on its Launch Site's pad
#             and LAUNCHes, the guest takes its seat, both fly (the guest's flight follows the host's), both stand in
#             the host's Moon world, the guest's own mission counts, the host's HOME brings both home. With
#             --drop=close the guest's link drops mid-flight: back on board (or straight into the Moon world), no hang.
#             Works with --lan too.
#   --move:   (online; owner #99) instead of playing: the same name on a new device, with proof. The "old" game claims a
#             name and backs its profile up; the "new" one types that name (taken), asks to move the game there and
#             prints its 6-digit code; this script hands the code to the old game (a file), which types a wrong code,
#             then the right one; the new game signs in with its one-time key and plays as the account (its name and
#             progress); the old game stays signed in and hears "Your game is on a computer now too."
#             (tools/net_test_move.gd). With --delete-accounts the account is deleted afterwards. While the move by
#             code is off (DeviceMoveRules.enabled; the server's MoveRules.ENABLED, 0.2.20) it says SKIP and exits 0.
#   --login:  (online; owner #105) instead of playing: LOG IN with the name and the password, one device at a time. The
#             "a" game claims a name, is refused a weak password, makes a good one and backs its profile up; the "b"
#             game (its own first-launch name) types that name with a wrong password (refused), then the right one, and
#             plays as the account (its name and progress); the "a" game's link closes by itself and its next sign-in
#             says "You logged in on another device. LOG IN to play here." with no new account made
#             (tools/net_test_login.gd). With --delete-accounts the account is deleted afterwards (from "b", with the
#             password).
set -uo pipefail
builtin cd "$(dirname "$0")/.."
mode=online
server=""
keep=0
delete_accounts=0
invite=0
fps=60   # like a phone at best (headless games otherwise run as fast as they can, and every
         # MultiplayerSynchronizer sends once per frame: the bandwidth would grow with the frame rate)
test_args=(--net-test)
host_extra=()
guest_extra=()
game_timeout=240
for a in "$@"; do
	case "$a" in
		--lan) mode=lan ;;
		--server=*) server="${a#--server=}" ;;
		--keep) keep=1 ;;
		--delete-accounts) delete_accounts=1 ;;
		--invite) invite=1 ;;
		--remove) test_args+=(--net-test-remove) ;;
		--fps=*) fps="${a#--fps=}" ;;
		--fly) test_args+=(--net-test-fly) ;;
		--big) test_args+=(--net-test-big) ;;   # owner #92: the host builds a big world before the guest joins
		--crew) test_args+=(--net-test-crew); game_timeout=400 ;;   # spec §21d.6: a crew flight to the Moon and home
		--freeze) test_args+=(--net-test-freeze) ;;   # owner #92: the guest freezes 12 s after joining (a slow phone)
		--no-smooth) test_args+=(--net-test-no-smooth) ;;
		--drop=*) test_args+=("--net-test-drop=${a#--drop=}") ;;
		--vr=host) host_extra+=(--vr-preview --vr-wave); guest_extra+=(--net-test-see-vr) ;;
		--vr=guest) guest_extra+=(--vr-preview --vr-wave); host_extra+=(--net-test-see-vr) ;;
		--old=host) host_extra+=(--vr-old-peer) ;;
		--old=guest) guest_extra+=(--vr-old-peer) ;;
		--move) move=1 ;;   # owner #99
		--login) login=1 ;;   # owner #105
		# owner #123, the online version check (NetVersionCheck): the same fingerprint plays as always; different ones:
		# the guest (older) leaves with "newer" words and the host is told the guest was "older"
		--versions=same) host_extra+=(--net-version=aaaaaaaa1111); guest_extra+=(--net-version=aaaaaaaa1111) ;;
		--versions=differ) versions=differ; host_extra+=(--net-version=ffffffff9999); guest_extra+=(--net-version=0aaaaaaa0001) ;;
		*) echo "unknown argument: $a" >&2; exit 2 ;;
	esac
done
if [[ ${move:-0} -eq 1 ]]; then
	# Owner #99: the same name on a new device, with proof (tools/net_test_move.gd), then nothing else.
	if [[ $mode != online ]]; then
		echo "net_test: --move needs the online server" >&2
		exit 2
	fi
	work="$(mktemp -d "${TMPDIR:-/tmp}/easycraft-net-move.XXXXXX")"
	tag="$(tr -dc 'a-z0-9' < /dev/urandom | head -c 5)"
	name="NtM${tag}"
	for who in old new; do
		mkdir -p "$work/$who/godot/app_userdata/EasyCraft"
		printf '{"version":1,"username":"%s","age_band":"13_plus"}\n' "$name" > "$work/$who/godot/app_userdata/EasyCraft/profile.json"
	done
	code_file="$work/code.txt"
	XDG_DATA_HOME="$work/old" timeout 200 godot --headless --path . --script res://tools/net_test_move.gd -- \
		--role=old --me="$name" --server="$server" --code-file="$code_file" > "$work/old.log" 2>&1 &
	old_pid=$!
	for _ in $(seq 1 600); do
		grep -q 'NETMOVE old ready' "$work/old.log" && break
		kill -0 "$old_pid" 2>/dev/null || break
		sleep 0.1
	done
	XDG_DATA_HOME="$work/new" timeout 200 godot --headless --path . --script res://tools/net_test_move.gd -- \
		--role=new --me="$name" --server="$server" > "$work/new.log" 2>&1 &
	new_pid=$!
	for _ in $(seq 1 900); do   # a person reads the code on the new screen and types it on the old one
		code="$(grep -oP 'NETMOVE new code=\K[0-9]{6}' "$work/new.log" | head -1)"
		[[ -n "$code" ]] && { printf '%s' "$code" > "$code_file"; break; }
		kill -0 "$new_pid" 2>/dev/null || break
		sleep 0.1
	done
	wait "$new_pid"; new_status=$?
	wait "$old_pid"; old_status=$?
	grep -h '^NETMOVE' "$work/old.log" "$work/new.log"
	if [[ $old_status -eq 3 && $new_status -eq 3 ]]; then
		echo "net_test: SKIP (move: the move by code is off)"
		rm -rf "$work"
		exit 0
	fi
	errors=$(cat "$work/old.log" "$work/new.log" | grep -e 'SCRIPT ERROR' -e '^ERROR' | grep -c -v 'at exit')
	echo "net_test: move old exit=$old_status new exit=$new_status errors=$errors"
	deleted=0
	if [[ $delete_accounts -eq 1 ]]; then
		XDG_DATA_HOME="$work/old" timeout 180 godot --headless --path . --script res://tools/delete_test_account.gd \
			-- "--server=${server}" > "$work/old-delete.log" 2>&1 || deleted=1
		grep -h '^DELETE_ACCOUNT' "$work/old-delete.log" | sed "s/^/net_test: /"
	fi
	if [[ $old_status -eq 0 && $new_status -eq 0 && $errors -eq 0 && $deleted -eq 0 ]]; then
		echo "net_test: PASS (move)"
		if [[ $keep -eq 1 ]]; then echo "net_test: logs in $work"; else rm -rf "$work"; fi
		exit 0
	fi
	echo "net_test: FAIL (move), logs in $work"
	exit 1
fi
if [[ ${login:-0} -eq 1 ]]; then
	# Owner #105: LOG IN with the name and the password, one device at a time (tools/net_test_login.gd).
	if [[ $mode != online ]]; then
		echo "net_test: --login needs the online server" >&2
		exit 2
	fi
	work="$(mktemp -d "${TMPDIR:-/tmp}/easycraft-net-login.XXXXXX")"
	tag="$(tr -dc 'a-z' < /dev/urandom | head -c 4)"
	name="NtL${tag}"
	password="moon${tag}7tiger"
	for who in a b; do
		mkdir -p "$work/$who/godot/app_userdata/EasyCraft"
		first="$name"
		[[ $who == b ]] && first="NtB${tag}"   # the new device's own first-launch name
		printf '{"version":1,"username":"%s","age_band":"13_plus"}\n' "$first" > "$work/$who/godot/app_userdata/EasyCraft/profile.json"
	done
	XDG_DATA_HOME="$work/a" timeout 220 godot --headless --path . --script res://tools/net_test_login.gd -- \
		--role=a --me="$name" --password="$password" --server="$server" > "$work/a.log" 2>&1 &
	a_pid=$!
	for _ in $(seq 1 600); do
		grep -q 'NETLOGIN a ready' "$work/a.log" && break
		kill -0 "$a_pid" 2>/dev/null || break
		sleep 0.1
	done
	XDG_DATA_HOME="$work/b" timeout 220 godot --headless --path . --script res://tools/net_test_login.gd -- \
		--role=b --me="$name" --password="$password" --server="$server" > "$work/b.log" 2>&1 &
	b_pid=$!
	wait "$b_pid"; b_status=$?
	wait "$a_pid"; a_status=$?
	grep -h '^NETLOGIN' "$work/a.log" "$work/b.log"
	errors=$(cat "$work/a.log" "$work/b.log" | grep -e 'SCRIPT ERROR' -e '^ERROR' | grep -c -v 'at exit')
	echo "net_test: login a exit=$a_status b exit=$b_status errors=$errors"
	deleted=0
	if [[ $delete_accounts -eq 1 ]]; then
		XDG_DATA_HOME="$work/b" timeout 180 godot --headless --path . --script res://tools/delete_test_account.gd \
			-- "--server=${server}" "--password=${password}" > "$work/b-delete.log" 2>&1 || deleted=1
		grep -h '^DELETE_ACCOUNT' "$work/b-delete.log" | sed "s/^/net_test: /"
	fi
	if [[ $a_status -eq 0 && $b_status -eq 0 && $errors -eq 0 && $deleted -eq 0 ]]; then
		echo "net_test: PASS (login)"
		if [[ $keep -eq 1 ]]; then echo "net_test: logs in $work"; else rm -rf "$work"; fi
		exit 0
	fi
	echo "net_test: FAIL (login), logs in $work"
	exit 1
fi
work="$(mktemp -d "${TMPDIR:-/tmp}/easycraft-net-test.XXXXXX")"
for who in host guest; do
	dir="$work/$who/godot/app_userdata/EasyCraft"
	mkdir -p "$dir"
	name="Net${who^}"
	printf '{"version":1,"username":"%s","age_band":"13_plus"}\n' "$name" > "$dir/profile.json"
done
tag="$(tr -dc 'a-z0-9' < /dev/urandom | head -c 5)"
host_name="NtH${tag}"
guest_name="NtG${tag}"
server_args=()
[[ -n "$server" ]] && server_args=("--online-server=$server")
if [[ $invite -eq 1 && $mode == online ]]; then
	f_args=(--server="${server}")
	XDG_DATA_HOME="$work/host" timeout 150 godot --headless --path . --script res://tools/net_test_friends.gd -- \
		--role=host --me="$host_name" --other="$guest_name" "${f_args[@]}" > "$work/host-friends.log" 2>&1 &
	fh=$!
	XDG_DATA_HOME="$work/guest" timeout 150 godot --headless --path . --script res://tools/net_test_friends.gd -- \
		--role=guest --me="$guest_name" --other="$host_name" "${f_args[@]}" > "$work/guest-friends.log" 2>&1 &
	fg=$!
	wait "$fh"; fh_status=$?
	wait "$fg"; fg_status=$?
	grep -h '^NETFRIENDS' "$work/host-friends.log" "$work/guest-friends.log"
	if [[ $fh_status -ne 0 || $fg_status -ne 0 ]]; then
		echo "net_test: FAIL (the two test games could not become friends), logs in $work"
		exit 1
	fi
	test_args+=("--net-test-invite=$guest_name")
fi
if [[ $mode == online ]]; then
	host_args=(--online-host "${server_args[@]}" "${test_args[@]}" "${host_extra[@]}")
else
	host_args=(--auto-host "${test_args[@]}" "${host_extra[@]}")
fi

XDG_DATA_HOME="$work/host" timeout "$game_timeout" godot --headless --max-fps "$fps" --path . -- "${host_args[@]}" > "$work/host.log" 2>&1 &
host_pid=$!
ready=""
for _ in $(seq 1 600); do
	if [[ $mode == online ]]; then
		ready="$(grep -oP 'ONLINE host match_id=\K\S+' "$work/host.log" | head -1)"
		grep -q 'ONLINE error' "$work/host.log" && break
	else
		grep -q 'LAN host_lan err=OK' "$work/host.log" && ready=yes
	fi
	[[ -n "$ready" ]] && break
	kill -0 "$host_pid" 2>/dev/null || break
	sleep 0.1
done
if [[ -z "$ready" ]]; then
	echo "net_test: the host did not get ready (logs: $work)" >&2
	grep -h -e ONLINE -e 'LAN ' "$work/host.log" >&2
	kill "$host_pid" 2>/dev/null
	exit 1
fi
if [[ $invite -eq 1 && $mode == online ]]; then
	for _ in $(seq 1 600); do
		grep -q "NETTEST host .*invited $guest_name ok" "$work/host.log" && break
		grep -q "NETTEST host .*invite failed" "$work/host.log" && break
		kill -0 "$host_pid" 2>/dev/null || break
		sleep 0.1
	done
	grep -h "invited\|invite failed" "$work/host.log"
fi
if [[ $mode == online ]]; then
	echo "net_test: match $ready"
	guest_args=("--online-join=$ready" "${server_args[@]}" "${test_args[@]}" "${guest_extra[@]}")
else
	guest_args=(--auto-join=127.0.0.1 "${test_args[@]}" "${guest_extra[@]}")
fi
XDG_DATA_HOME="$work/guest" timeout "$game_timeout" godot --headless --max-fps "$fps" --path . -- "${guest_args[@]}" > "$work/guest.log" 2>&1 &
guest_pid=$!
wait "$guest_pid"; guest_status=$?
wait "$host_pid"; host_status=$?

for who in host guest; do
	grep -h -e '^NETTEST' -e '^ONLINE' -e '^LAN ' -e '^CREW ' -e 'SANDBOX spawned' "$work/$who.log"
	# (not Godot's leak reports when a headless game quits mid-world: "... at exit")
	errors=$(grep -e 'SCRIPT ERROR' -e '^ERROR' "$work/$who.log" | grep -c -v 'at exit')
	echo "net_test: $who exit=$(eval echo \$${who}_status) errors=$errors"
done
deleted=0
if [[ $delete_accounts -eq 1 && $mode == online ]]; then
	for who in host guest; do
		XDG_DATA_HOME="$work/$who" timeout 180 godot --headless --path . --script res://tools/delete_test_account.gd \
			-- "--server=${server}" > "$work/$who-delete.log" 2>&1 || deleted=1
		grep -h '^DELETE_ACCOUNT' "$work/$who-delete.log" | sed "s/^/net_test: $who /"
	done
fi
if [[ ${versions:-} == differ ]]; then
	grep -h '^ONLINE version' "$work/host.log" "$work/guest.log"
	if grep -q '^ONLINE version newer' "$work/guest.log" && grep -q '^ONLINE version older' "$work/host.log" \
			&& [[ $deleted -eq 0 ]]; then
		echo "net_test: PASS (versions differ: the guest left, the host was told)"
		if [[ $keep -eq 1 ]]; then echo "net_test: logs in $work"; else rm -rf "$work"; fi
		exit 0
	fi
	echo "net_test: FAIL (versions differ), logs in $work"
	exit 1
fi
if [[ $host_status -eq 0 && $guest_status -eq 0 && $deleted -eq 0 ]]; then
	echo "net_test: PASS ($mode)"
	if [[ $keep -eq 1 ]]; then echo "net_test: logs in $work"; else rm -rf "$work"; fi
	exit 0
fi
echo "net_test: FAIL ($mode), logs in $work"
exit 1
