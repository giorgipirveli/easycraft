#!/usr/bin/env bash
# Exports the browser version (M7, spec §20) small-first (owner 2026-09-28: "make first download small, then after
# starting a game download continues in background"):
#   build/web/index.pck          the game's code and data with computer textures (S3TC), without its media
#   build/web/index.mobile.pck   the same with phone textures (ETC2); web/shell.html picks one by the GPU
#   build/web/assets.<hash>.pck         the game's media (sounds, the core music loops, the characters) for computers
#   build/web/assets.mobile.<hash>.pck  (S3TC) and phones (ETC2); the page downloads its GPU's one next to index.pck
#                                before the start (autoloads/assets_pack.gd loads it first): kept by its content, so an
#                                update that changes only code downloads only index.pck
#   build/web/music.<hash>.pck   the background music (classical library, universe tracks), fetched after the start
#   build/web/reels.<hash>.pck   the Reel Studio's rendered videos (assets/reels/*.ogv, owner #96), fetched after the
#                                music; until it is in, a video reel shows its still and "coming…" (ReelPack)
#   build/web/realistic.<hash>.pck         the REALISTIC style's pictures (every block page's realistic twin and the
#   build/web/realistic.mobile.<hash>.pck  HDRI sky) for computers (S3TC) and phones (ETC2), fetched after the music
#                                (first for a child who plays REALISTIC); the game takes its GPU's one
#   build/web/packs.json         what the game fetches in the background (core/platform/web_content.gd)
#
#   tools/export_web.sh          then: python3 tools/web_serve.py build/web 8060   or   tools/deploy_web.sh
set -euo pipefail

GAME="$(cd "$(dirname "$0")/.." && pwd)"
cd "$GAME"
OUT=build/web
PACKS=(build/web-mobile build/web-music build/web-reels build/web-realistic build/web-realistic-mobile build/web-assets
	build/web-assets-mobile)
rm -rf "$OUT" "${PACKS[@]}"
mkdir -p "$OUT" "${PACKS[@]}"

run() { timeout 900 nice godot --headless --path . "$@" > /dev/null 2>&1; }
/usr/bin/python3 tools/write_build_info.py   # owner #123: the build's commit, date and online fingerprint (BuildInfo)
# INCLUDE_MUSIC=1 / INCLUDE_REALISTIC=1 / INCLUDE_ASSETS=1 / INCLUDE_REELS=1: keep the background music / the realistic
# pictures / the media / the reels' videos in the main packs too (a build for a game that cannot fetch them yet). The
# packs are still made and listed (loading them then changes nothing: a file the main pack has wins).
if [[ "${INCLUDE_MUSIC:-}" == "1" || "${INCLUDE_REALISTIC:-}" == "1" || "${INCLUDE_ASSETS:-}" == "1" \
		|| "${INCLUDE_REELS:-}" == "1" ]]; then
	cp export_presets.cfg build/export_presets.cfg.bak
	trap 'mv -f build/export_presets.cfg.bak export_presets.cfg' EXIT
	python3 - "${INCLUDE_MUSIC:-}" "${INCLUDE_REALISTIC:-}" "${INCLUDE_ASSETS:-}" "${INCLUDE_REELS:-}" <<'PY'
import re, sys
music, realistic, media, reels = [a == "1" for a in sys.argv[1:5]]
keep = (("assets/music/",) if music else ()) + (("data/blocks/", "assets/sky/") if realistic else ()) + \
    (("assets/audio/", "assets/characters/", "assets/music/day.", "assets/music/night.", "assets/music/boss.") if media else ()) + \
    (("assets/reels/",) if reels else ())
p = "export_presets.cfg"; s = open(p).read()
def strip(m):
    kept = [f.strip() for f in m.group(2).split(",") if not f.strip().startswith(keep)]
    return m.group(1) + ", ".join(kept) + '"'
s = re.sub(r'^(exclude_filter=")(spikes/\*[^"]*)"', strip, s, flags=re.M)
open(p, "w").write(s)
PY
fi
run --export-release "Web" "$OUT/index.html"
run --export-release "Web Mobile" build/web-mobile/index.html
run --export-pack "Web Music" build/web-music/music.pck
run --export-pack "Web Reels" build/web-reels/reels.pck
run --export-pack "Web Realistic" build/web-realistic/realistic.pck
run --export-pack "Web Realistic Mobile" build/web-realistic-mobile/realistic.pck
run --export-pack "Web Assets" build/web-assets/assets.pck
run --export-pack "Web Assets Mobile" build/web-assets-mobile/assets.pck

cp build/web-mobile/index.pck "$OUT/index.mobile.pck"
# The exporter adds the autoload scripts, project.binary, the caches, the icon and the splash to every pack: a content
# pack keeps only its own files (tools/pck_tool.py), so a code change never renames it (the main pack's copies win).
strip() { python3 tools/pck_tool.py strip "$1" "$1.stripped" --preset "$2" && mv -f "$1.stripped" "$1"; }
strip build/web-music/music.pck "Web Music"
strip build/web-reels/reels.pck "Web Reels"
strip build/web-realistic/realistic.pck "Web Realistic"
strip build/web-realistic-mobile/realistic.pck "Web Realistic Mobile"
strip build/web-assets/assets.pck "Web Assets"
strip build/web-assets-mobile/assets.pck "Web Assets Mobile"
# Each pack is named by its content (a new name whenever it changes: the game keeps the one it has otherwise).
hashed() { echo "$2.$(sha256sum "$1" | cut -c1-10).pck"; }
music="$(hashed build/web-music/music.pck music)"
reels="$(hashed build/web-reels/reels.pck reels)"
realistic="$(hashed build/web-realistic/realistic.pck realistic)"
realistic_mobile="$(hashed build/web-realistic-mobile/realistic.pck realistic.mobile)"
assets="$(hashed build/web-assets/assets.pck assets)"
assets_mobile="$(hashed build/web-assets-mobile/assets.pck assets.mobile)"
cp build/web-music/music.pck "$OUT/$music"
cp build/web-reels/reels.pck "$OUT/$reels"
cp build/web-realistic/realistic.pck "$OUT/$realistic"
cp build/web-realistic-mobile/realistic.pck "$OUT/$realistic_mobile"
cp build/web-assets/assets.pck "$OUT/$assets"
cp build/web-assets-mobile/assets.pck "$OUT/$assets_mobile"

python3 - "$OUT" "$music" "$realistic" "$realistic_mobile" "$assets" "$assets_mobile" "$reels" <<'EOF'
import json, os, re, sys
out, music, realistic, realistic_mobile, assets, assets_mobile, reels = sys.argv[1:8]
size = lambda f: os.path.getsize(os.path.join(out, f))
# The music first, then the reels' videos (owner #96), then the realistic pictures (the game asks for them first when the
# child plays REALISTIC). A "gpu" entry is only for the GPU that reads that texture format (the page's choice:
# index.pck S3TC, index.mobile.pck ETC2).
json.dump({"version": 1, "packs": [
    {"name": "music", "file": music, "size": size(music)},
    {"name": "reels", "file": reels, "size": size(reels)},
    {"name": "realistic", "file": realistic, "size": size(realistic), "gpu": "s3tc"},
    {"name": "realistic", "file": realistic_mobile, "size": size(realistic_mobile), "gpu": "etc2"},
]}, open(os.path.join(out, "packs.json"), "w"))
# The page preloads one main pack and the assets pack of its GPU; tell it their sizes (the progress bar) and names.
html_path = os.path.join(out, "index.html")
html = open(html_path).read()
m = re.search(r'"fileSizes":\{([^}]*)\}', html)
html = html[:m.end(1)] + ',"index.mobile.pck":%d,"%s":%d,"%s":%d' % (
    size("index.mobile.pck"), assets, size(assets), assets_mobile, size(assets_mobile)) + html[m.end(1):]
assert "'@EC_ASSETS@'" in html
html = html.replace("'@EC_ASSETS@'", json.dumps({"s3tc": assets, "etc2": assets_mobile}), 1)
open(html_path, "w").write(html)
sw_path = os.path.join(out, "index.service.worker.js")
sw = open(sw_path).read()
def swap(old, new):
    global sw
    assert old in sw, old
    sw = sw.replace(old, new, 1)
swap('const CACHEABLE_FILES = ["index.wasm","index.pck",', 'const CACHEABLE_FILES = ["index.wasm","index.pck","index.mobile.pck",')
# Owner 2026-09-28: "once downloaded we should not have to download it again". Godot's worker only starts when the
# game starts, and never takes over the open page, so a first visit's downloads were not kept. EasyCraft's page
# (web/shell.html) registers it first and waits for it; the worker takes over at once:
# A new version's worker fetched every file of its list again, index.js (3 MB) too, although the content cache below
# keeps that one by its content: those it gets from there (or once from the network, which also keeps it offline).
# Owner #95 ("get upgraded after getting online"): a new version's worker downloads every file this device's game
# needs (its GPU's main pack and media pack, the engine, the code) before it takes over, so the new version plays
# offline too; if the download fails (offline again) the install fails and the old version stays, whole.
swap("event.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(CACHED_FILES)));",
     "self.skipWaiting(); // EasyCraft: take over the page at once (tools/export_web.sh)\n"
     "\tevent.waitUntil(caches.open(CACHE_NAME).then((cache) => cache.addAll(CACHED_FILES.filter((name) => !(name in EC_HASHES))))\n"
     "\t\t.then(() => ecKeep(CACHED_FILES.filter((name) => name in EC_HASHES)))\n"
     "\t\t.then(() => ecKeepUpdate()));")
swap("return ('navigationPreload' in self.registration) ? self.registration.navigationPreload.enable() : Promise.resolve();",
     "return ('navigationPreload' in self.registration) ? self.registration.navigationPreload.enable() : Promise.resolve();\n"
     "\t}).then(function () {\n\t\treturn self.clients.claim(); // EasyCraft: control the first visit's downloads too")
# Each device keeps only the main pack its GPU uses (index.pck or index.mobile.pck): only the rest must be there to
# count as offline-ready.
swap("const fullCache = await Promise.all(FULL_CACHE.map((name) => cache.match(name)));",
     "const fullCache = await Promise.all(FULL_CACHE.filter((name) => !(name in EC_HASHES) && (!name.startsWith('index.') || !name.endsWith('.pck'))).map((name) => cache.match(name)));")
# Owner #93 (2026-09-30): "play alone without an internet". The page is opened as /play/ (not index.html), which
# Godot's worker never finds in its cache, so an offline visit failed (net::ERR_FAILED). The page now comes from the
# network whenever it can (an update still reaches it at once); offline, this worker's own copy of index.html (the
# same build as its files) when every file of the game is kept here, else Godot's offline page.
swap("""				if (isNavigate) {
					// Check if we have full cache during HTML page request.""",
     """				if (isNavigate) {
					try {
						return await fetchAndCache(event, cache, false);   // EasyCraft: online, the newest page
					} catch (e) {
						const page = await ecOfflinePage(cache);   // EasyCraft: offline, this build's page (owner #93)
						if (page != null) {
							return ENSURE_CROSSORIGIN_ISOLATION_HEADERS ? ensureCrossOriginIsolationHeaders(page) : page;
						}
						return caches.match(OFFLINE_URL);
					}
					// Check if we have full cache during HTML page request.""")
# Owner 2026-09-28 01:29: "make sure it is saved in iphone and in android browser so after refresh i dont need to
# redownload". Godot's worker keeps files in a cache named after the export and deletes it on every new version, so each
# update downloaded everything again. The big files are kept instead in a cache of their own, keyed by their content
# (sha-256): an update downloads only the files whose content changed; stale ones are removed.
import hashlib
big = ["index.pck", "index.mobile.pck", "index.side.wasm", "index.wasm", "index.js", assets, assets_mobile] + \
    sorted(f for f in os.listdir(out) if f.startswith("lib") and f.endswith(".wasm"))
hashes = {f: hashlib.sha256(open(os.path.join(out, f), "rb").read()).hexdigest()[:16] for f in big}
EC_BLOCK = r'''// EasyCraft (tools/export_web.sh): the big files kept by their content across versions.
const EC_FILES_CACHE = 'EasyCraft-files';
const EC_HASHES = HASHES_JSON;
function ecKey(name) { return name + '?h=' + EC_HASHES[name]; }
async function ecKeep(names) {
	const cache = await caches.open(EC_FILES_CACHE);
	for (const name of names) {
		const key = new URL(ecKey(name), self.location).href;
		if (await cache.match(key) == null) {
			const response = await fetch(name);
			if (response.ok) {
				await cache.put(key, response);
			}
		}
	}
}
// Owner #95: an update's whole game for this device (the kind of main pack it kept before: a phone's or a computer's),
// downloaded before this worker takes over; nothing on a first visit (the page downloads what it needs then).
async function ecKeepUpdate() {
	const kept = await caches.open(EC_FILES_CACHE);
	const names = (await kept.keys()).map((request) => new URL(request.url).pathname.split('/').pop());
	if (!names.some((name) => name.endsWith('.pck'))) {
		return;
	}
	const phone = names.includes('index.mobile.pck');
	const wanted = Object.keys(EC_HASHES).filter((name) => !name.endsWith('.pck')
		|| (name === 'index.mobile.pck' || name.includes('.mobile.')) === phone);
	// Owner #123: the page waits for an update while it downloads and shows how far it is (files done of files new).
	const missing = [];
	for (const name of wanted) {
		if (await kept.match(new URL(ecKey(name), self.location).href) == null) {
			missing.push(name);
		}
	}
	await ecTell([0, missing.length]);
	for (let i = 0; i < missing.length; i++) {
		await ecKeep([missing[i]]);
		await ecTell([i + 1, missing.length]);
	}
}
// Owner #123: the update's progress to the open pages ({ecUpdate: [done, total]}).
async function ecTell(progress) {
	try {
		const pages = await self.clients.matchAll({ includeUncontrolled: true, type: 'window' });
		for (const page of pages) {
			page.postMessage({ ecUpdate: progress });
		}
	} catch (e) {}
}
// Owner #93: the page to open without the internet: this build's index.html when every file the game needs is kept
// here (the main pack and the media pack of one GPU kind), else null.
async function ecOfflinePage(cache) {
	const kept = await caches.open(EC_FILES_CACHE);
	const has = async (name) => name in EC_HASHES && (await kept.match(new URL(ecKey(name), self.location).href)) != null;
	const names = Object.keys(EC_HASHES);
	for (const name of names) {
		if (!name.endsWith('.pck') && !(await has(name))) {
			return null;
		}
	}
	for (const name of CACHED_FILES) {
		if (!(name in EC_HASHES) && (await cache.match(name)) == null) {
			return null;
		}
	}
	const assets = (mobile) => names.find((name) => name.startsWith('assets.') && name.includes('.mobile.') === mobile);
	const computer = (await has('index.pck')) && (await has(assets(false)));
	const phone = (await has('index.mobile.pck')) && (await has(assets(true)));
	return (computer || phone) ? await cache.match('index.html') : null;
}
self.addEventListener('fetch', (event) => {
	if (event.request.method !== 'GET') {
		return;
	}
	const url = new URL(event.request.url);
	const name = url.pathname.split('/').pop();
	if (!(name in EC_HASHES)) {
		return;
	}
	event.respondWith((async () => {
		const cache = await caches.open(EC_FILES_CACHE);
		const key = new URL(ecKey(name), url).href;
		let response = await cache.match(key);
		if (response == null) {
			response = await fetch(event.request);
			if (response.ok) {
				// Store the copy while the page reads the same bytes: awaiting the whole file first froze the progress
				// bar at 2 % until 64 MB had arrived (owner 2026-09-28 01:42).
				event.waitUntil(cache.put(key, response.clone()));
			}
		}
		return ENSURE_CROSSORIGIN_ISOLATION_HEADERS ? ensureCrossOriginIsolationHeaders(response) : response;
	})());
});
self.addEventListener('activate', (event) => {
	event.waitUntil(caches.open(EC_FILES_CACHE).then(async (cache) => {
		const keep = new Set(Object.keys(EC_HASHES).map(ecKey));
		for (const request of await cache.keys()) {
			const url = new URL(request.url);
			if (!keep.has(url.pathname.split('/').pop() + url.search)) {
				await cache.delete(request);
			}
		}
	}));
});

'''
marker = "self.addEventListener('install'"
assert marker in sw
sw = sw.replace(marker, EC_BLOCK.replace("HASHES_JSON", json.dumps(hashes)) + marker, 1)
# One build id in the worker and the page (web/shell.html, EC_BUILD): Godot's cache name, new at every export. A
# returning page asks its worker for it and makes both the same version (2026-09-28: new page, old worker, old pack).
build_id = re.search(r"const CACHE_PREFIX = '([^']+)';", sw).group(1) + re.search(r"const CACHE_VERSION = '([^']+)';", sw).group(1)
sw = sw.replace(marker, '''self.addEventListener('message', (event) => {
	if (event.data === 'ec-build' && event.ports && event.ports[0]) {
		event.ports[0].postMessage({ ecBuild: CACHE_NAME });   // EasyCraft: the page checks it is of this build
	}
});

''' + marker, 1)
open(sw_path, "w").write(sw)
html = open(html_path).read()
assert "'@EC_BUILD@'" in html
open(html_path, "w").write(html.replace("'@EC_BUILD@'", "'" + build_id + "'", 1))
print("WEB_EXPORT " + " ".join("%s=%.1f MB" % (f, size(f) / 1048576) for f in [
    "index.pck", "index.mobile.pck", assets, assets_mobile, music, reels, realistic, realistic_mobile]))
EOF
python3 tools/web_finish.py "$OUT"
/usr/bin/python3 tools/write_build_info.py --clean   # owner #123: the editor shows the version alone again
