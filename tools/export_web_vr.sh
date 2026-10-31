#!/usr/bin/env bash
# Owner #101 (VR on the Meta Quest), the WebXR route (docs/superpowers/plans/2026-10-15-vr-quest.md ruling 1): the game
# for a headset's browser, exported into build/web_vr/ and served at https://178-104-20-64.sslip.io/vr/ beside /play/
# (server/deploy/caddy/Caddyfile):
#
#   tools/export_web_vr.sh     the "Web VR" preset (feature tag webxr: the menu's ENTER VR, the multiview shaders
#                              xr/shaders/enabled.webxr) and the same content packs as /play/, in build/web_vr/
#   tools/deploy_web_vr.sh     then: compress it and copy it to the server's vr/ folder (served at /vr/)
#   python3 tools/web_serve.py build/web_vr 8061     or try it on this PC (a headset's browser needs HTTPS: the server)
#
# It is tools/export_web.sh (the flat web build, which stays exactly as it is) run with these differences, each checked
# to still apply (the script stops and says so when export_web.sh changed under it):
#   - build/web_vr and build/web_vr-* in place of build/web and build/web-*;
#   - one main pack, "Web VR", holding both texture formats (S3TC for a PC's browser, ETC2 for the Quest's), copied as
#     index.mobile.pck too: the page picks by the GPU as on /play/ (ruling: the Quest downloads both formats' textures,
#     docs/devlog/parts/vr-ui.md has the sizes);
#   - its own caches in the browser ("EasyCraft-vr-files", "vr-" before Godot's): /play/ and /vr/ share one origin, so
#     one Cache Storage, and each worker deletes the caches it does not know; with their own names neither deletes the
#     other's downloads;
#   - the page's way home (a browser that cannot run threads goes to the server's copy) is /vr/, not /play/.
# Godot reads export presets 0, 1, 2… up to the first missing number: before the lead merges VR-RIG's Quest presets (14,
# 15), "Web VR" (16) is exported from a copy of export_presets.cfg numbered without the gap (the file is put back).
set -euo pipefail

GAME="$(cd "$(dirname "$0")/.." && pwd)"
cd "$GAME"
mkdir -p build
body=build/export_web_vr_body.sh

python3 - tools/export_web.sh "$body" <<'PY'
import sys
src, dst = sys.argv[1], sys.argv[2]
s = open(src).read()


def swap(old, new, every=False):
    global s
    assert old in s, "tools/export_web.sh changed: %r is gone (update tools/export_web_vr.sh)" % old
    s = s.replace(old, new) if every else s.replace(old, new, 1)


swap('run --export-release "Web Mobile" build/web-mobile/index.html\n', '')
swap('run --export-release "Web" "$OUT/index.html"', 'run --export-release "Web VR" "$OUT/index.html"')
swap('cp build/web-mobile/index.pck "$OUT/index.mobile.pck"',
     'cp "$OUT/index.pck" "$OUT/index.mobile.pck"   # owner #101: one pack, both texture formats')
swap('\nOUT=build/web\n', '\nOUT=build/web_vr\n')
swap('build/web-', 'build/web_vr-', every=True)
swap("const EC_FILES_CACHE = 'EasyCraft-files';", "const EC_FILES_CACHE = 'EasyCraft-vr-files';")
swap('sw = open(sw_path).read()\n',
     'sw = open(sw_path).read()\n'
     'assert "const CACHE_PREFIX = \'" in sw\n'
     'sw = sw.replace("const CACHE_PREFIX = \'", "const CACHE_PREFIX = \'vr-", 1)   # owner #101: /vr/\'s own caches\n')
swap("assert \"'@EC_ASSETS@'\" in html\n",
     "assert \"'@EC_ASSETS@'\" in html\n"
     "assert 'https://178-104-20-64.sslip.io/play/' in html\n"
     "html = html.replace('https://178-104-20-64.sslip.io/play/', 'https://178-104-20-64.sslip.io/vr/')   # owner #101\n")
open(dst, "w").write("# Made by tools/export_web_vr.sh from tools/export_web.sh: do not edit.\n" + s)
PY

# "Web VR"'s number, and the first number missing before it (empty: none).
read -r vr_index gap < <(python3 - <<'PY'
import re
s = open("export_presets.cfg").read()
m = re.search(r'^\[preset\.(\d+)\]\n\nname="Web VR"$', s, flags=re.M)
assert m, 'export_presets.cfg has no "Web VR" preset'
vr = int(m.group(1))
have = {int(n) for n in re.findall(r'^\[preset\.(\d+)\]$', s, flags=re.M)}
gap = next((i for i in range(vr + 1) if i not in have), vr + 1)   # none: every number up to "Web VR" is there
print(vr, gap if gap < vr else "")
PY
)
if [[ -n "${gap:-}" ]]; then
	cp export_presets.cfg build/export_presets.cfg.vr.bak
	trap 'mv -f build/export_presets.cfg.vr.bak export_presets.cfg' EXIT
	python3 - "$vr_index" "$gap" <<'PY'
import sys
vr, gap = sys.argv[1], sys.argv[2]
s = open("export_presets.cfg").read()
for suffix in ("]", ".options]"):
    old, new = "[preset.%s%s\n" % (vr, suffix), "[preset.%s%s\n" % (gap, suffix)
    assert s.count(old) == 1, old
    s = s.replace(old, new)
open("export_presets.cfg", "w").write(s)
PY
	echo "WEB_VR_EXPORT: \"Web VR\" exported as preset.$gap (presets $gap..$((vr_index - 1)) are not in this branch yet)"
fi

bash "$body"
rm -f "$body"
echo "WEB_VR_EXPORT done: build/web_vr (serve at /vr/: tools/deploy_web_vr.sh)"
