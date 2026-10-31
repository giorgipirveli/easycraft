#!/usr/bin/env bash
# EasyCraft server kit: every command the owner's server needs (docs/hosting.md).
#   ./kit.sh keys [domain]     make .env from .env.example with new random secrets (once)
#   ./kit.sh up                check .env, build the server, start everything, wait until healthy
#   ./kit.sh status            what runs and its health, and the newest backups
#   ./kit.sh check [url]       try the server from outside, like the game (HTTPS, sign-in, wss, relay)
#   ./kit.sh logs [service]    follow the logs (nakama, caddy, postgres or backup); Ctrl+C stops following
#   ./kit.sh access [lines]    the access log's files and its newest lines (addresses, 14 days at most)
#   ./kit.sh backup            make a backup now (into backups/)
#   ./kit.sh restore <file>    put a backup from backups/ back (asks first, backs up the present first)
#   ./kit.sh update            back up, fetch newer base images, rebuild and restart
#   ./kit.sh down              stop everything (the database, backups and certificates are kept)
#   ./kit.sh console           how to open Nakama's developer console through an SSH tunnel
#   ./kit.sh pack              (on the development PC) pack the kit and the server module for copying
# Trying the kit on a development PC without touching anything else: local-try.yml.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
env_file="${KIT_ENV_FILE:-$here/.env}"
compose=(docker compose --project-directory "$here" --env-file "$env_file" -f "$here/docker-compose.yml")
if [[ -n "${KIT_OVERRIDE:-}" ]]; then compose+=(-f "$here/$KIT_OVERRIDE"); fi
if [[ -n "${KIT_PROJECT:-}" ]]; then compose+=(-p "$KIT_PROJECT"); fi
# The backup service runs as whoever runs this kit, so the backups belong to them.
BACKUP_UID="$(id -u)"
BACKUP_GID="$(id -g)"
export BACKUP_UID BACKUP_GID
node_image=node:24-alpine          # the Dockerfile's NODE_VERSION: already here after the first build
secret_keys=(POSTGRES_PASSWORD NAKAMA_SESSION_ENCRYPTION_KEY NAKAMA_SESSION_REFRESH_ENCRYPTION_KEY
	NAKAMA_CONSOLE_PASSWORD NAKAMA_CONSOLE_SIGNING_KEY NAKAMA_RUNTIME_HTTP_KEY)

die() {
	echo "kit: $*" >&2
	exit 1
}

# The value of KEY in .env (last one wins, surrounding quotes removed), or "".
env_value() {
	[[ -f "$env_file" ]] || return 0
	grep -E "^$1=" "$env_file" | tail -n 1 | cut -d= -f2- | sed -e 's/^"\(.*\)"$/\1/' -e "s/^'\(.*\)'\$/\1/" || true
}

backup_dir() {
	local dir
	dir="$(env_value BACKUP_DIR)"
	dir="${dir:-./backups}"
	[[ "$dir" == /* ]] || dir="$here/${dir#./}"
	echo "$dir"
}

# Hex from the kernel's random source: `random 24` is 48 characters.
random() {
	od -An -N"$1" -tx1 /dev/urandom | tr -d ' \n'
}

check_env() {
	[[ -f "$env_file" ]] || die "no .env yet: run ./kit.sh keys first (docs/hosting.md step 5)"
	chmod 600 "$env_file"
	local domain
	domain="$(env_value EASYCRAFT_DOMAIN)"
	if [[ -z "$domain" || "$domain" == "play.example.com" ]]; then
		die "set EASYCRAFT_DOMAIN in .env to your server's name (docs/hosting.md step 3)"
	fi
	local k
	for k in NAKAMA_SERVER_KEY NAKAMA_CONSOLE_USERNAME "${secret_keys[@]}"; do
		[[ -n "$(env_value "$k")" ]] || die "$k is empty in .env: fill it in (./kit.sh keys makes a new .env)"
	done
}

cmd_keys() {
	[[ ! -e "$env_file" ]] || die "$env_file already exists. Keep it: the database only opens with its POSTGRES_PASSWORD."
	local domain="${1:-}" line key
	umask 077
	while IFS= read -r line || [[ -n "$line" ]]; do
		key="${line%%=*}"
		if [[ "$line" == "$key=" ]]; then
			case "$key" in
				NAKAMA_CONSOLE_PASSWORD) line="$key=$(random 16)" ;;
				POSTGRES_PASSWORD | NAKAMA_SESSION_* | NAKAMA_CONSOLE_SIGNING_KEY | NAKAMA_RUNTIME_HTTP_KEY)
					line="$key=$(random 24)" ;;
			esac
		fi
		if [[ -n "$domain" && "$key" == "EASYCRAFT_DOMAIN" && "$line" == EASYCRAFT_DOMAIN=* ]]; then
			line="EASYCRAFT_DOMAIN=$domain"
		fi
		printf '%s\n' "$line"
	done < "$here/.env.example" > "$env_file"
	echo "kit: wrote $env_file with new secrets (only you can read it)."
	if [[ -z "$domain" ]]; then
		echo "kit: now put your server's name into EASYCRAFT_DOMAIN in it: nano $env_file"
	fi
	echo "kit: keep a copy in a password manager (it has the console password); never send it to anyone."
}

cmd_up() {
	check_env
	mkdir -p "$(backup_dir)"
	chmod 700 "$(backup_dir)"
	"${compose[@]}" up -d --build --wait --wait-timeout 600
	echo "kit: running. Now try it from outside: ./kit.sh check"
}

cmd_status() {
	"${compose[@]}" ps
	echo
	echo "Newest backups in $(backup_dir):"
	# shellcheck disable=SC2010  # our own file names, no spaces
	ls -lt "$(backup_dir)" 2>/dev/null | grep '\.dump$' | head -n 8 || echo "  (none yet)"
}

cmd_check() {
	check_env
	local domain key url
	domain="$(env_value EASYCRAFT_DOMAIN)"
	key="$(env_value NAKAMA_SERVER_KEY)"
	url="${1:-https://$domain}"
	local run=(docker run --rm -v "$here/check:/check:ro")
	if [[ "$domain" == "localhost" ]]; then
		# A local try: trust Caddy's own local certificate, and reach the port published on this PC.
		local caddy
		caddy="$("${compose[@]}" ps -q caddy)"
		[[ -n "$caddy" ]] || die "Caddy is not running"
		run+=(--network host --volumes-from "$caddy:ro" -e NODE_EXTRA_CA_CERTS=/data/caddy/pki/authorities/local/root.crt)
	fi
	"${run[@]}" "$node_image" node /check/smoke.mjs "$url" "$key"
}

cmd_logs() {
	"${compose[@]}" logs -f --tail=200 "$@"
}

cmd_backup() {
	"${compose[@]}" exec -T backup /bin/sh /backup.sh now "${1:-manual}"
}

cmd_restore() {
	local file="${1:-}" yes="${2:-}"
	[[ -n "$file" ]] || die "which backup? ./kit.sh restore <file> (./kit.sh status lists them)"
	local name
	name="$(basename "$file")"
	[[ -f "$(backup_dir)/$name" ]] || die "no $name in $(backup_dir): copy the backup there first"
	if [[ "$yes" != "--yes" ]]; then
		echo "This replaces the whole database with $name."
		echo "Accounts, friends and reports made after that backup are lost."
		local answer
		read -r -p "Type RESTORE to go on: " answer
		[[ "$answer" == "RESTORE" ]] || die "nothing was changed"
	fi
	cmd_backup before-restore
	"${compose[@]}" stop nakama caddy
	if ! "${compose[@]}" exec -T backup /bin/sh /backup.sh restore "$name"; then
		echo "kit: the restore failed. What was there before is in $(backup_dir)/before-restore-*.dump:" >&2
		echo "kit: ./kit.sh restore <that file> puts it back, then ./kit.sh up" >&2
		exit 1
	fi
	"${compose[@]}" up -d --wait --wait-timeout 600
	echo "kit: restored $name; the server is running again"
}

cmd_update() {
	check_env
	[[ -z "${KIT_OVERRIDE:-}" ]] || die "not on a development PC: update pulls image tags other projects may share"
	cmd_backup before-update || echo "kit: no backup made (is the server running?); going on"
	"${compose[@]}" pull postgres caddy backup
	"${compose[@]}" build --pull nakama
	cmd_up
}

cmd_console() {
	local host
	host="$(hostname -I 2>/dev/null | awk '{print $1}')"
	cat <<EOF
Nakama's console listens on this server's 127.0.0.1:7351 only. From your own computer:

  ssh -N -L 7351:127.0.0.1:7351 $(id -un)@${host:-<server address>}

then open http://127.0.0.1:7351 in the browser there (Ctrl+C in the ssh window closes it).
Log in with NAKAMA_CONSOLE_USERNAME and NAKAMA_CONSOLE_PASSWORD from $env_file:
EOF
	grep -E '^NAKAMA_CONSOLE_(USERNAME|PASSWORD)=' "$env_file" | sed 's/^/  /'
}

cmd_pack() {
	local repo out_dir out
	repo="$(git -C "$here" rev-parse --show-toplevel 2>/dev/null)" || die "pack runs in the game's git folder on the development PC"
	out_dir="$repo/build/server"
	out="$out_dir/easycraft-server-$(date +%Y%m%d-%H%M).tar.gz"
	mkdir -p "$out_dir"
	# Only files git knows: never .env, backups, node_modules or build output.
	git -C "$repo" ls-files server/modules server/deploy | tar -C "$repo" -czf "$out" -T -
	echo "kit: packed $out"
	echo "kit: copy it to the server:  scp $out <user>@<server>:"
	echo "kit: and there:              mkdir -p ~/easycraft && tar -xzf $(basename "$out") -C ~/easycraft"
}

case "${1:-}" in
	keys) shift; cmd_keys "$@" ;;
	up) cmd_up ;;
	status) cmd_status ;;
	check) shift; cmd_check "$@" ;;
	logs) shift; cmd_logs "$@" ;;
	access) shift; "${compose[@]}" exec caddy sh -c 'ls -l /var/log/caddy && tail -n "$1" /var/log/caddy/access.log' sh "${1:-20}" ;;
	backup) cmd_backup ;;
	restore) shift; cmd_restore "$@" ;;
	update) cmd_update ;;
	down) "${compose[@]}" down ;;
	console) cmd_console ;;
	pack) cmd_pack ;;
	*) sed -n '2,15p' "$0"; exit 2 ;;
esac
