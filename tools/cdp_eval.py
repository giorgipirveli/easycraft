#!/usr/bin/env python3
"""Talks to a browser page over the Chrome DevTools Protocol (M7 browser tests on the Android emulator).

  adb forward tcp:9223 localabstract:chrome_devtools_remote     # (ANDROID_ADB_SERVER_PORT=5038 ANDROID_SERIAL=emulator-5554)
  ~/src/cdpenv/bin/python tools/cdp_eval.py fps 5               # frames per second over 5 s, and the worst frame
  ~/src/cdpenv/bin/python tools/cdp_eval.py eval "navigator.hardwareConcurrency"
  ~/src/cdpenv/bin/python tools/cdp_eval.py console 20          # the page's console lines for 20 s (the game's print())

Needs websocket-client (a venv: python3 -m venv ~/src/cdpenv && ~/src/cdpenv/bin/pip install websocket-client).
"""
import json
import os
import sys
import time
import urllib.request

import websocket

PORT = 9223
FPS_JS = """new Promise(res => { let n = 0, worst = 0; const t0 = performance.now(); let last = t0;
  function f(t) { n++; worst = Math.max(worst, t - last); last = t;
    if (t - t0 < %d) requestAnimationFrame(f); else res(JSON.stringify({fps: n * 1000 / (t - t0), worst_ms: worst})); }
  requestAnimationFrame(f); })"""


def page_socket() -> websocket.WebSocket:
    tabs = json.load(urllib.request.urlopen(f"http://localhost:{PORT}/json"))
    want = os.environ.get("CDP_URL", "")   # pick the page whose address contains this (several tabs open)
    page = next(t for t in tabs if t["type"] == "page" and want in t["url"])
    return websocket.create_connection(page["webSocketDebuggerUrl"], timeout=120, suppress_origin=True)


def call(ws: websocket.WebSocket, method: str, params: dict, ident: int) -> dict:
    ws.send(json.dumps({"id": ident, "method": method, "params": params}))
    while True:
        msg = json.loads(ws.recv())
        if msg.get("id") == ident:
            return msg


def evaluate(expr: str) -> str:
    ws = page_socket()
    out = call(ws, "Runtime.evaluate", {"expression": expr, "awaitPromise": True, "returnByValue": True}, 1)
    ws.close()
    return json.dumps(out.get("result", out).get("result", out))


def console(seconds: float) -> None:
    ws = page_socket()
    call(ws, "Runtime.enable", {}, 1)
    end = time.time() + seconds
    ws.settimeout(1)
    while time.time() < end:
        try:
            msg = json.loads(ws.recv())
        except websocket.WebSocketTimeoutException:
            continue
        if msg.get("method") == "Runtime.consoleAPICalled":
            args = msg["params"]["args"]
            print(" ".join(str(a.get("value", a.get("description", ""))) for a in args), flush=True)
    ws.close()


def main() -> None:
    cmd = sys.argv[1]
    if cmd == "fps":
        print(evaluate(FPS_JS % int(float(sys.argv[2]) * 1000)))
    elif cmd == "eval":
        print(evaluate(sys.argv[2]))
    elif cmd == "console":
        console(float(sys.argv[2]))


if __name__ == "__main__":
    main()
