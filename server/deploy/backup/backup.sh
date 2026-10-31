#!/bin/sh
# Database backups for the EasyCraft server. Runs inside the "backup" service (docker-compose.yml,
# a PostgreSQL image, so pg_dump and pg_restore match the database); the host side is ./kit.sh.
#   backup.sh daily           a backup at start when the newest is over 12 h old, then one every day
#                             at BACKUP_AT (UTC); keeps the newest BACKUP_KEEP daily backups
#   backup.sh now [label]     one backup now, named <label>-<time>.dump (default "manual"); keeps
#                             the newest BACKUP_KEEP of that label
#   backup.sh restore <file>  empties the database and loads <file> into it (Nakama must be stopped:
#                             ./kit.sh restore does all of it)
#   backup.sh health          exit 0 while the newest daily backup is under 26 h old
# Connection: PGHOST, PGUSER, PGPASSWORD, PGDATABASE from docker-compose.yml. Backups hold every
# child's account: they are only readable by their owner (umask 077).
set -eu
umask 077

dir=/backups
keep=${BACKUP_KEEP:-7}
at=${BACKUP_AT:-03:30}

log() {
	echo "backup $(date -u +%Y-%m-%dT%H:%M:%SZ): $*"
}

# backup_once LABEL: dump to a temporary name, check the dump reads back, then give it its name.
backup_once() {
	label=$1
	stamp=$(date -u +%Y%m%d-%H%M%S)
	part="$dir/.$label-$stamp.dump.part"
	out="$dir/$label-$stamp.dump"
	if ! pg_dump --format=custom --compress=6 --no-owner --file="$part"; then
		rm -f "$part"
		log "FAILED: pg_dump could not read the database"
		return 1
	fi
	if ! pg_restore --list "$part" > /dev/null; then
		rm -f "$part"
		log "FAILED: the new dump does not read back"
		return 1
	fi
	mv "$part" "$out"
	log "made $out ($(du -k "$out" | cut -f1) KiB)"
	rotate "$label"
}

# rotate LABEL: keep the newest $keep backups with that label (names sort by time).
# shellcheck disable=SC2010  # the names are our own: <label>-<yyyymmdd>-<hhmmss>.dump
rotate() {
	ls -1 "$dir" | grep -E "^$1-[0-9]{8}-[0-9]{6}\.dump$" | sort -r | tail -n +"$((keep + 1))" |
		while read -r old; do
			rm -f "$dir/$old"
			log "removed $old (keeping the newest $keep)"
		done
}

# newest_age LABEL: seconds since the newest backup with that label was made (a big number if none).
# shellcheck disable=SC2010  # the names are our own
newest_age() {
	newest=$(ls -1 "$dir" | grep -E "^$1-[0-9]{8}-[0-9]{6}\.dump$" | sort -r | head -n 1 || true)
	if [ -z "$newest" ]; then
		echo 999999999
		return
	fi
	echo $(($(date -u +%s) - $(date -u -r "$dir/$newest" +%s)))
}

# seconds_until HH:MM (UTC): how long until that time next comes round.
seconds_until() {
	now=$(date -u +%s)
	target=$(date -u -d "$(date -u +%Y-%m-%d) $1" +%s)
	if [ "$target" -le "$now" ]; then
		target=$((target + 86400))
	fi
	echo $((target - now))
}

case "${1:-}" in
	daily)
		date -u -d "2000-01-01 $at" +%s > /dev/null 2>&1 || { log "BACKUP_AT must be HH:MM, not '$at'"; exit 2; }
		log "daily backups at $at UTC into $dir, keeping $keep"
		if [ "$(newest_age daily)" -gt 43200 ]; then
			backup_once daily || true
		fi
		while :; do
			wait_s=$(seconds_until "$at")
			log "next backup in $((wait_s / 60)) min"
			sleep "$wait_s"
			until backup_once daily; do
				log "trying again in an hour"
				sleep 3600
			done
		done
		;;
	now)
		backup_once "${2:-manual}"
		;;
	restore)
		file="${2:?backup.sh restore <file in $dir>}"
		case "$file" in /*) ;; *) file="$dir/$file" ;; esac
		[ -f "$file" ] || { log "no such backup: $file"; exit 1; }
		pg_restore --list "$file" > /dev/null || { log "$file is not a readable backup"; exit 1; }
		db=$PGDATABASE
		log "emptying database $db"
		psql --quiet --set ON_ERROR_STOP=1 --dbname=postgres \
			--command="DROP DATABASE IF EXISTS \"$db\" WITH (FORCE);" \
			--command="CREATE DATABASE \"$db\";"
		log "loading $file"
		pg_restore --no-owner --exit-on-error --single-transaction --dbname="$db" "$file"
		log "restored $file"
		;;
	health)
		[ "$(newest_age daily)" -lt 93600 ]
		;;
	*)
		sed -n '2,13p' "$0"
		exit 2
		;;
esac
