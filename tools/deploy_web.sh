#!/usr/bin/env bash
# Puts the web export on the server (M7, spec §20): https://178-104-20-64.sslip.io/play/
#
#   tools/export_web.sh                 # the game (computer + phone packs), the assets, music and realistic packs, packs.json
#   tools/deploy_web.sh                 # compress (brotli + gzip) and copy build/web to the server's play/ folder
#   tools/deploy_web.sh --dry-run       # only compress and print the sizes
#
# Caddy serves ~/easycraft/server/deploy/play/ at /play/ with the COOP/COEP headers and sends the .br or .gz file
# when the browser accepts it (server/deploy/caddy/Caddyfile). The folder is not in git. Needs brotli (apt).
set -euo pipefail

GAME="$(cd "$(dirname "$0")/.." && pwd)"
SRC="$GAME/build/web"
HOST="${EASYCRAFT_HOST:-easycraft@178.104.20.64}"
KEY="${EASYCRAFT_SSH_KEY:-$HOME/.ssh/easycraft_hetzner}"
DEST="easycraft/server/deploy/play"
DRY="${1:-}"

[[ -f "$SRC/index.html" && -f "$SRC/index.pck" ]] || { echo "no web export in $SRC (export the \"Web\" preset first)" >&2; exit 1; }
command -v brotli >/dev/null || { echo "brotli is missing: sudo apt install brotli" >&2; exit 1; }

stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
cp -a "$SRC/." "$stage/"
python3 "$GAME/tools/web_finish.py" "$stage"   # the install prompt needs a 192 px icon and a short name
# music.*.pck stays uncompressed (it is OGG); the realistic pictures (S3TC/ETC2) shrink to a quarter (35 -> 8 MB), the
# assets pack by a sixth (7.6 -> 6.4 MB: its WAV samples); the browser un-compresses before the game sees a byte
# (packs.json's and the page's sizes are the .pck's own). index*.pck, the code every update brings, gets brotli's best
# (-q 11: 15.9 -> 2.6 MB, about 50 s each; -q 9 gives 3.4 MB; -q 11 took 8 minutes for a 99 MB pack).
for f in "$stage"/*.wasm "$stage"/index*.pck "$stage"/realistic.*.pck "$stage"/assets.*.pck "$stage"/*.js "$stage"/*.html "$stage"/*.json; do
	[[ -e "$f" ]] || continue
	nice gzip -9 -k -f "$f"
	case "$(basename "$f")" in
		index*.pck) nice brotli -q 11 -k -f "$f" ;;
		*) nice brotli -q 9 -k -f "$f" ;;
	esac
done

raw=0; br=0
for f in "$stage"/*; do
	case "$f" in *.br | *.gz) continue ;; esac
	s=$(stat -c %s "$f"); raw=$((raw + s))
	if [[ -e "$f.br" ]]; then br=$((br + $(stat -c %s "$f.br"))); else br=$((br + s)); fi
done
echo "WEB_SIZE raw=$((raw / 1048576)) MB download(brotli)=$((br / 1048576)) MB"
ls -la "$stage" | grep -E "\.(wasm|pck)(\.br)?$" || true

if [[ "$DRY" == "--dry-run" ]]; then
	exit 0
fi
# Docker creates the bind-mounted folder as root when Caddy starts before the first deploy: hand it back.
ssh -i "$KEY" "$HOST" "mkdir -p $DEST && { test -w $DEST || docker run --rm -v \$HOME/$DEST:/p alpine chown -R \$(id -u):\$(id -g) /p; }"
# Owner #123: play/android/ and play/quest/ hold the Android apps' updates (tools/deploy_android_update.sh): kept.
rsync -az --delete --exclude=/android/ --exclude=/quest/ -e "ssh -i $KEY" "$stage/" "$HOST:$DEST/"
echo "WEB_DEPLOYED $(date -Is) to $HOST:$DEST"
