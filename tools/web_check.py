#!/usr/bin/env python3
# The browser build's first visit and refresh, in headless Chrome over the DevTools protocol (M7):
#   ~/src/cdpenv/bin/python tools/web_check.py http://localhost:8060/ [seconds]
#   ~/src/cdpenv/bin/python tools/web_check.py https://178-104-20-64.sslip.io/play/ 60
# A fresh profile opens the page, waits for PLAY, presses it, prints the game's console for `seconds` (MENU ready, the
# music pack: "downloading", "is in"), then reloads, presses PLAY again and prints what the refresh fetched over the
# network (it should be 0.00 MB: the service worker and user:// keep everything). Chrome gets a free DevTools port
# of its own each run. Needs Chrome and the python package
# websocket-client (~/src/cdpenv). The page stays visible to Chrome (headless tabs run requestAnimationFrame).
import json, os, subprocess, time, urllib.request, websocket, sys, shutil, tempfile
url = sys.argv[1]; secs = float(sys.argv[2]) if len(sys.argv) > 2 else 45
prof = tempfile.mkdtemp(prefix="ec-chrome-")
chrome = subprocess.Popen(["nice", "google-chrome", "--headless=new", "--remote-debugging-port=0", "--user-data-dir=" + prof,
                           "--no-first-run", "--window-size=1280,720", "about:blank"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
try:
    for _ in range(40):
        try:
            # Port 0: Chrome picks a free port and writes it to DevToolsActivePort in its own profile, so two runs (or an
            # agent's) never attach to each other's browser (2026-09-28: a fixed 9333 drove another run's tab).
            port = open(os.path.join(prof, "DevToolsActivePort")).read().split()[0]
            tabs = json.load(urllib.request.urlopen("http://localhost:%s/json" % port)); break
        except Exception: time.sleep(0.5)
    page = next(t for t in tabs if t["type"] == "page")
    ws = websocket.create_connection(page["webSocketDebuggerUrl"], timeout=5, suppress_origin=True)
    n = [0]; logs = []; net = [0]
    def pump(until):
        while time.time() < until:
            try: m = json.loads(ws.recv())
            except websocket.WebSocketTimeoutException: continue
            if m.get("method") == "Runtime.consoleAPICalled":
                logs.append(" ".join(str(a.get("value", a.get("description", ""))) for a in m["params"]["args"])[:160])
            if m.get("method") == "Network.loadingFinished":
                net[0] += m["params"].get("encodedDataLength", 0)
            if m.get("method") == "Network.responseReceived":
                r = m["params"]["response"]
                if r.get("encodedDataLength", 0) > 100000 or r["url"].endswith(".pck"):
                    logs.append("NET %s sw=%s disk=%s" % (r["url"].split("/")[-1], r.get("fromServiceWorker"), r.get("fromDiskCache")))
            if m.get("method") == "Runtime.exceptionThrown":
                logs.append("EXCEPTION " + str(m["params"]["exceptionDetails"].get("text"))[:160])
    def call(meth, p=None):
        n[0] += 1; ws.send(json.dumps({"id": n[0], "method": meth, "params": p or {}}))
        while True:
            try: m = json.loads(ws.recv())
            except websocket.WebSocketTimeoutException: continue
            if m.get("id") == n[0]: return m
            if m.get("method") == "Runtime.consoleAPICalled":
                logs.append(" ".join(str(a.get("value", a.get("description", ""))) for a in m["params"]["args"])[:160])
    call("Runtime.enable"); call("Page.enable"); call("Network.enable")
    call("Page.navigate", {"url": url})
    t0 = time.time()
    while time.time() - t0 < 60:
        pump(time.time() + 1)
        r = call("Runtime.evaluate", {"expression": "!!(document.getElementById('status') && document.getElementById('status').classList.contains('ready'))", "returnByValue": True})
        if r.get("result", {}).get("result", {}).get("value"): break
    print("READY after %.1fs" % (time.time() - t0))
    call("Runtime.evaluate", {"expression": "document.getElementById('play').click()"})
    pump(time.time() + secs)
    for l in logs: print(l)
    print("=== first visit: %.1f MB over the network ===" % (net[0] / 1048576))
    logs.clear(); net[0] = 0
    call("Page.reload")
    t0 = time.time()
    while time.time() - t0 < 60:
        pump(time.time() + 1)
        r = call("Runtime.evaluate", {"expression": "!!(document.getElementById('status') && document.getElementById('status').classList.contains('ready'))", "returnByValue": True})
        if r.get("result", {}).get("result", {}).get("value"): break
    print("RELOAD READY after %.1fs" % (time.time() - t0))
    call("Runtime.evaluate", {"expression": "document.getElementById('play').click()"})
    pump(time.time() + 25)
    for l in logs: print(l)
    print("=== after the refresh: %.2f MB over the network ===" % (net[0] / 1048576))
finally:
    chrome.terminate(); time.sleep(1); chrome.kill(); shutil.rmtree(prof, ignore_errors=True)
