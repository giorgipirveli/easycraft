#!/usr/bin/env python3
# A returning visitor after an update, in headless Chrome over the DevTools protocol (M7, docs/devlog/parts/m7-assets-pack.md):
#   ~/src/cdpenv/bin/python tools/web_update_check.py <build A> <build B> [port] [first visit seconds] [--etc2]
# Serves build A (a copy of an export's build/web) at http://localhost:<port>/ (8077), visits it in a Chrome profile that
# is kept between visits (PLAY, the menu, `first visit seconds` (150) for the music and realistic packs), then serves
# build B at the same address and visits again (the update), refreshes, and opens the Survivor world (the page's engine
# gets the user args -- --survivor). For each visit it prints the game's console lines and what the SERVER sent: the
# real network bytes, the service worker's own downloads included (a page's own count misses those). Raw bytes: this
# server sends no brotli (tools/deploy_web.sh's .br sizes say what a phone downloads). --etc2 hides S3TC from WebGL
# (a phone's GPU: the page takes the .mobile packs). Needs Chrome and websocket-client (~/src/cdpenv).
import http.server, json, os, shutil, subprocess, sys, tempfile, threading, time, urllib.request
import websocket

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from web_serve import Handler  # noqa: E402  (COOP/COEP, no-cache)

args = [a for a in sys.argv[1:] if not a.startswith("--")]
build_a, build_b = args[0], args[1]
port = int(args[2]) if len(args) > 2 else 8077
first_secs = float(args[3]) if len(args) > 3 else 150
etc2 = "--etc2" in sys.argv
state = {"root": build_a}
sent = []   # (time, status, bytes, path)
lock = threading.Lock()


class Counting(Handler):
    def copyfile(self, source, outputfile):
        n = 0
        while True:
            b = source.read(1 << 16)
            if not b:
                break
            outputfile.write(b)
            n += len(b)
        with lock:
            sent.append((time.time(), 200, n, self.path.split("?")[0]))

    def send_response(self, code, message=None):
        super().send_response(code, message)
        if code != 200:
            with lock:
                sent.append((time.time(), code, 0, self.path.split("?")[0]))

    def log_message(self, *a):
        pass


server = http.server.ThreadingHTTPServer(("127.0.0.1", port), lambda *a: Counting(*a, directory=state["root"]))
threading.Thread(target=server.serve_forever, daemon=True).start()
url = "http://localhost:%d/" % port
prof = tempfile.mkdtemp(prefix="ec-update-")

HIDE_S3TC = """(() => { for (const C of [WebGLRenderingContext, WebGL2RenderingContext]) {
    const g = C.prototype.getExtension; C.prototype.getExtension = function (n) { return /s3tc/i.test(n) ? null : g.call(this, n); };
    const s = C.prototype.getSupportedExtensions;
    C.prototype.getSupportedExtensions = function () { return (s.call(this) || []).filter((n) => !/s3tc/i.test(n)); }; } })();"""
# The page builds its engine args once: ['--main-pack', pack].concat(GODOT_CONFIG.args). The user args go there.
SURVIVOR = """(() => { const c = Array.prototype.concat; Array.prototype.concat = function (...a) { const r = c.apply(this, a);
    if (this.length === 2 && this[0] === '--main-pack') { Array.prototype.concat = c; return c.call(r, ['--', '--survivor']); }
    return r; }; })();"""


def visit(label, secs, survivor=False):
    try:
        os.remove(os.path.join(prof, "DevToolsActivePort"))
    except FileNotFoundError:
        pass
    with lock:
        start = len(sent)
    chrome = subprocess.Popen(["nice", "google-chrome", "--headless=new", "--remote-debugging-port=0", "--user-data-dir=" + prof,
                               "--no-first-run", "--no-default-browser-check", "--window-size=1280,720", "about:blank"],
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    t0 = time.time()
    logs = []
    seen = {"menu": False, "world": False}
    try:
        for _ in range(60):
            try:
                dport = open(os.path.join(prof, "DevToolsActivePort")).read().split()[0]
                tabs = json.load(urllib.request.urlopen("http://localhost:%s/json" % dport))
                break
            except Exception:
                time.sleep(0.5)
        ws = websocket.create_connection(next(t for t in tabs if t["type"] == "page")["webSocketDebuggerUrl"],
                                         timeout=5, suppress_origin=True)
        n = [0]

        def handle(m):
            meth = m.get("method")
            if meth == "Runtime.consoleAPICalled":
                text = " ".join(str(a.get("value", a.get("description", ""))) for a in m["params"]["args"])
                kind = m["params"].get("type")
                seen["menu"] |= text.startswith("MENU ready")
                seen["world"] |= text.startswith(("WORLD ready", "SANDBOX spawned"))
                if kind in ("error", "warning") or text.startswith(("EasyCraft", "MENU", "WORLD", "SANDBOX", "SCRIPT")):
                    logs.append("%6.1f %s%s" % (time.time() - t0, "[%s] " % kind if kind in ("error", "warning") else "", text[:200]))
            elif meth == "Runtime.exceptionThrown":
                logs.append("%6.1f EXCEPTION %s" % (time.time() - t0, str(m["params"]["exceptionDetails"].get("text"))[:200]))

        def pump(until):
            while time.time() < until:
                try:
                    handle(json.loads(ws.recv()))
                except websocket.WebSocketTimeoutException:
                    pass

        def call(meth, p=None):
            n[0] += 1
            ws.send(json.dumps({"id": n[0], "method": meth, "params": p or {}}))
            while True:
                try:
                    m = json.loads(ws.recv())
                except websocket.WebSocketTimeoutException:
                    continue
                if m.get("id") == n[0]:
                    return m.get("result", {}).get("result", {}).get("value")
                handle(m)

        call("Runtime.enable")
        call("Page.enable")
        for source in ([HIDE_S3TC] if etc2 else []) + ([SURVIVOR] if survivor else []):
            call("Page.addScriptToEvaluateOnNewDocument", {"source": source})
        call("Page.navigate", {"url": url})
        ready = "document.getElementById('status') && document.getElementById('status').classList.contains('ready')"
        while time.time() - t0 < 120 and not call("Runtime.evaluate", {"expression": "!!(%s)" % ready, "returnByValue": True}):
            pump(time.time() + 1)
        logs.append("%6.1f READY; page %s" % (time.time() - t0, call("Runtime.evaluate", {"expression":
            "JSON.stringify({gpu: window.easycraftGpu, build: (document.documentElement.innerHTML.match(/EC_BUILD = '([^']+)'/) || [])[1]})",
            "returnByValue": True})))
        call("Runtime.evaluate", {"expression": "document.getElementById('play').click()"})
        want = "world" if survivor else "menu"
        t1 = time.time()
        while time.time() - t1 < 180 and not seen[want]:
            pump(time.time() + 1)
        logs.append("%6.1f %s=%s" % (time.time() - t0, want.upper(), seen[want]))
        pump(time.time() + secs)
        # A graceful close writes the caches and IndexedDB to the profile.
        ver = json.load(urllib.request.urlopen("http://localhost:%s/json/version" % dport))
        websocket.create_connection(ver["webSocketDebuggerUrl"], timeout=5, suppress_origin=True).send(
            json.dumps({"id": 1, "method": "Browser.close"}))
        chrome.wait(20)
    finally:
        if chrome.poll() is None:
            chrome.terminate()
            time.sleep(1)
            chrome.kill()
    print("##### %s" % label)
    for line in logs:
        print(line)
    with lock:
        mine = sent[start:]
    per = {}
    for _, code, b, path in mine:
        per[(code, path)] = per.get((code, path), 0) + b
    print("=== %s: the server sent %.2f MB ===" % (label, sum(b for _, _, b, _ in mine) / 1048576))
    for (code, path), b in sorted(per.items(), key=lambda kv: -kv[1]):
        if code == 200:
            print("   %10d  %s" % (b, path))


try:
    visit("first visit of A (%s)" % build_a, first_secs)
    state["root"] = build_b
    visit("the update: B (%s) at the same address" % build_b, 40)
    visit("a refresh of B", 30)
    visit("B again, into the Survivor world", 20, survivor=True)
finally:
    server.shutdown()
    shutil.rmtree(prof, ignore_errors=True)
