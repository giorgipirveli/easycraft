#!/usr/bin/env bash
# Owner #101 (VR on the Meta Quest): puts the Web VR export on the server, served at https://178-104-20-64.sslip.io/vr/
#
#   tools/export_web_vr.sh        # the Web VR game and its packs in build/web_vr/
#   tools/deploy_web_vr.sh        # compress (brotli + gzip) and copy build/web_vr to the server's vr/ folder
#   tools/deploy_web_vr.sh --dry-run
#
# It is tools/deploy_web.sh with build/web_vr and the server's vr/ folder in place of build/web and play/ (each change
# checked to still apply). Caddy serves ~/easycraft/server/deploy/vr/ at /vr/ with the thread headers once the server has
# this commit's server/deploy/caddy/Caddyfile and docker-compose.yml (the ./vr mount): docs/devlog/parts/vr-ui.md says
# what the lead deploys.
set -euo pipefail

GAME="$(cd "$(dirname "$0")/.." && pwd)"
cd "$GAME"
mkdir -p build
body=build/deploy_web_vr_body.sh
python3 - tools/deploy_web.sh "$body" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
s = open(src).read()


def swap(old, new):
    global s
    assert old in s, "tools/deploy_web.sh changed: %r is gone (update tools/deploy_web_vr.sh)" % old
    s = s.replace(old, new, 1)


swap('SRC="$GAME/build/web"', 'SRC="$GAME/build/web_vr"')
swap('DEST="easycraft/server/deploy/play"', 'DEST="easycraft/server/deploy/vr"')
swap('(export the \\"Web\\" preset first)', '(run tools/export_web_vr.sh first)')
open(dst, "w").write("# Made by tools/deploy_web_vr.sh from tools/deploy_web.sh: do not edit.\n" + s)
PY
status=0
bash "$body" "$@" || status=$?
rm -f "$body"
exit "$status"
