#!/usr/bin/env bash
# Owner #123: puts the Android apps' update (tools/export_android_update.sh's build/android/update/<kind>/) on the
# server, beside the web game: the phone's in play/android/, the Quest's in play/quest/, which Caddy already serves at
# https://178-104-20-64.sslip.io/play/android/ and /play/quest/ (the /play/ block: plain files, `precompressed gzip`; no
# Caddy or server change). tools/deploy_web.sh leaves those two folders alone.
#
#   tools/deploy_android_update.sh --dry-run            # check the manifests' signatures, gzip, print what would go up
#   tools/deploy_android_update.sh --to <folder>        # into a local folder laid out as the server's play/ (a test)
#   tools/deploy_android_update.sh                      # to the server (the lead, from the web deploy's commit)
#
# Order: the packs (with their .gz: Godot's HTTPRequest takes gzip, not brotli) first, update.json last, so an app never
# reads a manifest whose pack is not there yet; then files no manifest names any more go. EASYCRAFT_UPDATE_OUT
# (build/android/update), EASYCRAFT_HOST, EASYCRAFT_SSH_KEY as for tools/deploy_web.sh.
set -euo pipefail

GAME="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${EASYCRAFT_UPDATE_OUT:-$GAME/build/android/update}"
HOST="${EASYCRAFT_HOST:-easycraft@178.104.20.64}"
KEY="${EASYCRAFT_SSH_KEY:-$HOME/.ssh/easycraft_hetzner}"
DEST="easycraft/server/deploy/play"
PY=(/usr/bin/python3 -B "$GAME/tools/android_update.py")
# A test's own public key (the tests sign with a key of their own); else the game's (UpdateRules.PUBLIC_KEYS).
PUBLIC="${EASYCRAFT_UPDATE_PUBLIC:-}"

DRY=0
TO=""
while (( $# )); do
	case "$1" in
		--dry-run) DRY=1 ;;
		--to) TO="${2:?--to needs a folder}"; shift ;;
		*) echo "unknown argument: $1" >&2; exit 2 ;;
	esac
	shift
done

declare -A FOLDER=([phone]=android [quest]=quest)
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
kinds=()
for kind in phone quest; do
	src="$SRC/$kind"
	[[ -f "$src/update.json" ]] || { echo "ANDROID_DEPLOY $kind: no update.json in $src (tools/export_android_update.sh first): skipped"; continue; }
	"${PY[@]}" verify "$src/update.json" ${PUBLIC:+--public "$PUBLIC"}   # the game's key: an app refuses any other
	f="${FOLDER[$kind]}"
	mkdir -p "$stage/$f"
	cp "$src/update.json" "$stage/$f/"
	# Only the packs the manifest names (game.pck, the logs and a refused patch stay home).
	while read -r name; do
		[[ -n "$name" ]] || continue
		cp "$src/$name" "$stage/$f/"
		nice gzip -9 -k -f "$stage/$f/$name"
		echo "ANDROID_DEPLOY $kind: $name $(stat -c %s "$stage/$f/$name") bytes, gzip $(stat -c %s "$stage/$f/$name.gz") bytes"
	done < <(/usr/bin/python3 -c 'import json,sys; [print(e["file"]) for e in json.loads(json.load(open(sys.argv[1]))["signed"])["bases"].values()]' "$src/update.json")
	kinds+=("$f")
done
(( ${#kinds[@]} )) || { echo "nothing to deploy" >&2; exit 1; }

if (( DRY )); then
	echo "ANDROID_DEPLOY dry run: would put ${kinds[*]} into ${TO:-$HOST:$DEST}"
	exit 0
fi
if [[ -n "$TO" ]]; then
	for f in "${kinds[@]}"; do
		mkdir -p "$TO/$f"
		find "$stage/$f" -maxdepth 1 -type f ! -name update.json -exec cp {} "$TO/$f/" \;
		cp "$stage/$f/update.json" "$TO/$f/update.json.new" && mv "$TO/$f/update.json.new" "$TO/$f/update.json"
		for old in "$TO/$f"/*; do
			[[ -e "$stage/$f/$(basename "$old")" ]] || rm -f "$old"
		done
	done
	echo "ANDROID_DEPLOYED $(date -Is) to $TO (${kinds[*]})"
	exit 0
fi
ssh -i "$KEY" "$HOST" "mkdir -p $(printf "$DEST/%s " "${kinds[@]}")"
for f in "${kinds[@]}"; do
	rsync -az -e "ssh -i $KEY" --exclude=update.json "$stage/$f/" "$HOST:$DEST/$f/"
	rsync -az -e "ssh -i $KEY" "$stage/$f/update.json" "$HOST:$DEST/$f/update.json"
	rsync -az --delete -e "ssh -i $KEY" "$stage/$f/" "$HOST:$DEST/$f/"
done
echo "ANDROID_DEPLOYED $(date -Is) to $HOST:$DEST (${kinds[*]})"
