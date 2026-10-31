#!/usr/bin/env python3
"""A child's first minute in the browser version, measured on the Android emulator's Chrome (M7; the shader warm-up's
measurement, 2026-09-29). One visit of http://localhost:8060/ (serve a build with `python3 tools/web_serve.py build/web
8060`; `adb reverse tcp:8060 tcp:8060`; `adb forward tcp:9223 localabstract:chrome_devtools_remote`; the emulator turned
sideways: `adb shell settings put system user_rotation 1`):

  ~/src/cdpenv/bin/python tools/web_emu_flow.py <label> <seconds idle on the menu> [seconds after] [--keep]

A fresh visitor (no worker, caches, storage or HTTP cache) presses the page's PLAY; the game's menu is timed (MENU
ready); after the idle time the child's taps go into the first world: PLAY, RANDOM, OK, BOY, SIMPLE, SANDBOX (a new
player) or, with --keep (the saved game, worker and packs stay: a returning child), PLAY, SANDBOX, CONTINUE. Prints
every frame over 400 ms after the last tap with the game's console lines near it, and the warm-up's own lines. The
taps are the Pixel 8 AVD's screen in landscape (2400 x 1080); a changed menu layout moves them."""
import json, sys, time, urllib.request
import websocket

label = sys.argv[1]
survivor = "--survivor" in sys.argv
rest = [a for a in sys.argv[2:] if not a.startswith("--")]
idle = float(rest[0]) if rest else 0
secs = float(rest[1]) if len(rest) > 1 else 45
import subprocess, os
ADB = dict(os.environ, ANDROID_ADB_SERVER_PORT="5038", ANDROID_SERIAL="emulator-5554")


def tap(x, y):
    subprocess.run(["adb", "shell", "input", "tap", str(x), str(y)], env=ADB, check=False)
URL = "http://localhost:8060/"

tabs = [t for t in json.load(urllib.request.urlopen("http://localhost:9223/json")) if t["type"] == "page"]
tab = next((t for t in tabs if "localhost:8060" in t["url"]), None)
if tab is None:
    req = urllib.request.Request("http://localhost:9223/json/new?about:blank", method="PUT")
    tab = json.load(urllib.request.urlopen(req))
urllib.request.urlopen("http://localhost:9223/json/activate/" + tab["id"])   # a hidden tab is paused
time.sleep(1)
ws = websocket.create_connection(tab["webSocketDebuggerUrl"], timeout=2, suppress_origin=True)
n = [0]
logs = []
seen = {"menu": None, "world": None}
t_origin = [None]


def handle(m):
    if m.get("method") == "Runtime.consoleAPICalled":
        text = " ".join(str(a.get("value", a.get("description", ""))) for a in m["params"]["args"])
        ts = m["params"]["timestamp"]
        logs.append((ts, text[:150]))
        if text.startswith("MENU ready") and seen["menu"] is None:
            seen["menu"] = time.time()
        if text.startswith(("WORLD ready", "SANDBOX spawned", "SURVIVOR spawned")) and seen["world"] is None:
            seen["world"] = time.time()


def call(method, params=None, wait=30):
    n[0] += 1
    ws.send(json.dumps({"id": n[0], "method": method, "params": params or {}}))
    end = time.time() + wait
    while time.time() < end:
        try:
            m = json.loads(ws.recv())
        except websocket.WebSocketTimeoutException:
            continue
        if m.get("id") == n[0]:
            return m
        handle(m)
    return {}


def pump(until):
    while time.time() < until:
        try:
            handle(json.loads(ws.recv()))
        except websocket.WebSocketTimeoutException:
            pass


def value(expr, promise=False):
    r = call("Runtime.evaluate", {"expression": expr, "returnByValue": True, "awaitPromise": promise})
    return r.get("result", {}).get("result", {}).get("value")


call("Runtime.enable")
call("Page.enable")
call("Page.navigate", {"url": URL})
pump(time.time() + 4)
keep = "--keep" in sys.argv   # a returning child: the saved game, the worker and its packs stay
# A fresh visitor: no worker, no caches, no saved game.
if not keep:
  value("""(async () => { for (const r of await navigator.serviceWorker.getRegistrations()) await r.unregister();
  for (const k of await caches.keys()) await caches.delete(k);
  for (const d of (indexedDB.databases ? await indexedDB.databases() : [])) indexedDB.deleteDatabase(d.name);
  localStorage.clear(); sessionStorage.clear(); return 1; })()""", True)
call("Network.enable")
if not keep:
    call("Network.clearBrowserCache")
    call("Network.setCacheDisabled", {"cacheDisabled": True})
call("Page.addScriptToEvaluateOnNewDocument", {"source": """window.__lf = []; (function () { let last = performance.now();
  function f(t) { if (t - last > 60) window.__lf.push([Math.round(performance.timeOrigin + last), Math.round(t - last)]);
  last = t; requestAnimationFrame(f); } requestAnimationFrame(f); })();"""})
if survivor:
    call("Page.addScriptToEvaluateOnNewDocument", {"source": """(() => { const c = Array.prototype.concat;
        Array.prototype.concat = function (...a) { const r = c.apply(this, a);
            if (this.length === 2 && this[0] === '--main-pack') { Array.prototype.concat = c;
                return c.call(r, ['--', '--survivor']); } return r; }; })();"""})
call("Page.navigate", {"url": URL})
seen["menu"] = None
seen["world"] = None
t0 = time.time()
ready = False
while time.time() - t0 < 300:
    pump(time.time() + 1)
    if value("!!(document.getElementById('status') && document.getElementById('status').classList.contains('ready'))"):
        ready = True
        break
print("[%s] page ready=%s after %.1f s" % (label, ready, time.time() - t0))
print("[%s] build %s" % (label, value("(document.documentElement.innerHTML.match(/EC_BUILD = '([^']+)'/) || [])[1]")))
t_play = time.time()
play_ms = value("performance.timeOrigin + performance.now()")
value("document.getElementById('play').click()")
want = "world" if survivor else "menu"
while time.time() - t_play < 240 and seen[want] is None:
    pump(time.time() + 1)
if seen["menu"]:
    print("[%s] MENU ready %.1f s after PLAY" % (label, seen["menu"] - t_play))
if seen["world"]:
    print("[%s] WORLD %.1f s after PLAY" % (label, seen["world"] - t_play))
pump(time.time() + idle)
taps = [(1267, 693, 4), (1072, 819, 1.5), (1456, 819, 3), (853, 667, 3), (987, 573, 3), (592, 627, 0)]
if keep:
    taps = [(1267, 693, 3), (592, 627, 3), (1265, 531, 0)]
for x, y, wait in taps:
    tap(x, y)
    pump(time.time() + wait)
enter_ms = value("performance.timeOrigin + performance.now()")
seen["world"] = None
t_enter = time.time()
pump(time.time() + secs)
lf = json.loads(value("JSON.stringify(window.__lf || [])") or "[]")
after = [(s0, d) for s0, d in lf if s0 >= enter_ms - 200]
print("[%s] idle %.0f s on the menu; into the world: frames over 60 ms: %d; over 500 ms: %d; worst %d ms; total %.1f s" % (label, idle,
      len(after), len([1 for _, d in after if d > 500]), max([d for _, d in after], default=0), sum(d for _, d in after) / 1000))
for s0, d in after:
    if d > 400:
        near = [t for ts, t in logs if s0 - 1500 <= ts <= s0 + d + 300 and not t.startswith("[")]
        print("  +%5.1f s  %5d ms  %s" % ((s0 - enter_ms) / 1000, d, " | ".join(near)[:220]))
warm = [t for ts, t in logs if t.startswith("WARMUP")]
print("[%s] warm-up lines: %s" % (label, " || ".join(warm)[:600]))
