#!/usr/bin/env python3
# Counts and times the WebGL shader programs the browser build links, per phase of play (M7: the browser freezes are
# the first sight of each material compiling its shader on the main thread; docs/devlog/parts/m7-shader-warmup.md).
#   tools/export_web.sh
#   ~/src/cdpenv/bin/python tools/web_shader_probe.py [build/web] [--phases new,play,moon,realistic] [--continue]
#                                                     [--no-warmup] [--style realistic] [--json out.json] [--timeout 900]
# It serves the build itself (a free port, the thread headers), opens it in headless Chrome (a fresh profile, a free
# DevTools port of its own), and before the page's own scripts wraps WebGL2's compileShader / linkProgram /
# getProgramParameter / getShaderParameter / getParameter and requestAnimationFrame. The game gets the developer arg
# --shader-probe=<phases> (tools/shader_probe_steps.gd, added by scenes/main.gd): it plays the phases and prints
# `PROBE phase=<name>` at each start and `PROBE done` at the end; the page's phase before is `boot` until `MENU ready`,
# then `menu`. --continue then reloads the page (same profile: the saved world) and plays `continue` (CONTINUE).
# Per phase it prints the programs linked, the time the page waited for them (compile + link), the frames, the long
# frames (over 100 ms) and how much of those frames was shader waiting; then each phase's programs by signature
# (the kind of Godot shader, a hash of its source without the #define lines, the material's uniforms, the defines).
# Headless Chrome draws with SwiftShader (software GL): absolute times are not a phone's; the COUNT of links per
# phase, and their share of the long frames, are what to compare before and after a change. --no-warmup gives the game
# --no-shader-warmup: the same build without its warm-up (ShaderWarmup), for a before and after of one export;
# --style realistic starts as a REALISTIC child (its saved style), whose warm-up does both styles.
import argparse, functools, http.server, json, os, shutil, socket, subprocess, sys, tempfile, threading, time
import urllib.request

import websocket

WRAPPER = r"""
(() => {
  if (window.__probe) return;
  const now = () => performance.now();
  const probe = window.__probe = {phase: 'boot', phases: {}, links: [], sources: {}, marks: [], longFrames: [],
    getParam: {}, frameShader: 0, frameGP: 0, frameWarm: false, menuReadyAt: 0, done: false, lines: []};
  window.__probeArgs = __ARGS__;
  function ph() {
    let p = probe.phases[probe.phase];
    if (!p) {
      p = probe.phases[probe.phase] = {links: 0, linkMs: 0, compiles: 0, compileMs: 0, gp: 0, gpMs: 0, frames: 0,
        frameMs: 0, long: 0, longMs: 0, longShaderMs: 0, maxFrame: 0, start: now(), sight: 0, warm: 0, warmFrames: 0,
        maxSightFrame: 0, maxWarmFrame: 0};
      probe.marks.push([probe.phase, Math.round(now())]);
    }
    return p;
  }
  ph();
  function fnv(s) {
    let h = 0x811c9dc5;
    for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 0x01000193) >>> 0; }
    return ('0000000' + h.toString(16)).slice(-8);
  }
  const srcOf = new WeakMap(), shadersOf = new WeakMap(), recOf = new WeakMap();
  function signature(prog) {
    const srcs = (shadersOf.get(prog) || []).map(s => srcOf.get(s) || '');
    const all = srcs.join('\n//----\n');
    const defs = [];
    for (const m of all.matchAll(/^\s*#define\s+([A-Z_][A-Z_0-9]*)\s*$/gm)) {
      if (!defs.includes(m[1])) defs.push(m[1]);
    }
    const body = all.replace(/^\s*#define.*$/gm, '');
    const hash = fnv(body);
    let kind = 'other';
    if (/SceneData|scene_data_block/.test(all)) kind = 'scene';
    else if (/CanvasData|canvas_data|draw_data/i.test(all)) kind = 'canvas';
    else if (/SkyData|sky_/.test(all)) kind = 'sky';
    let mat = '';
    const mu = /uniform\s+MaterialUniforms[^{]*{([^}]*)}/.exec(all);
    if (mu) mat = mu[1].replace(/\s+/g, ' ').trim().slice(0, 160);
    const tex = [];
    for (const m of all.matchAll(/uniform\s+(?:highp\s+|mediump\s+|lowp\s+)?sampler\w*\s+(\w+)/g)) {
      if (!tex.includes(m[1])) tex.push(m[1]);
    }
    if (!probe.sources[hash]) probe.sources[hash] = all.slice(0, 200000);
    return {kind: kind, hash: hash, defines: defs.join(' '), mat: mat, tex: tex.join(' ').slice(0, 200)};
  }
  for (const C of [window.WebGL2RenderingContext, window.WebGLRenderingContext]) {
    if (!C) continue;
    const P = C.prototype;
    const wrap = (name, fn) => {
      const o = P[name];
      if (!o || o.__probed) return;
      const w = function () { return fn.call(this, o, arguments); };
      w.__probed = true;
      P[name] = w;
    };
    wrap('shaderSource', function (o, a) { srcOf.set(a[0], a[1]); return o.apply(this, a); });
    wrap('attachShader', function (o, a) {
      const l = shadersOf.get(a[0]) || []; l.push(a[1]); shadersOf.set(a[0], l); return o.apply(this, a);
    });
    wrap('compileShader', function (o, a) {
      const t = now(); const r = o.apply(this, a); const d = now() - t;
      const p = ph(); p.compiles++; p.compileMs += d; probe.frameShader += d; return r;
    });
    wrap('getShaderParameter', function (o, a) {
      const t = now(); const r = o.apply(this, a); const d = now() - t;
      const p = ph(); p.compileMs += d; probe.frameShader += d; return r;
    });
    wrap('linkProgram', function (o, a) {
      const t = now(); const r = o.apply(this, a); const d = now() - t;
      const p = ph(); p.links++; p.linkMs += d; probe.frameShader += d;
      const rec = Object.assign({phase: probe.phase, at: Math.round(now()), ms: d, warm: probe.frameWarm}, signature(a[0]));
      if (probe.frameWarm) p.warm++; else p.sight++;
      probe.links.push(rec); recOf.set(a[0], rec); return r;
    });
    wrap('getProgramParameter', function (o, a) {
      const t = now(); const r = o.apply(this, a); const d = now() - t;
      const p = ph(); p.linkMs += d; probe.frameShader += d;
      const rec = recOf.get(a[0]); if (rec) rec.ms += d; return r;
    });
    wrap('getParameter', function (o, a) {
      const t = now(); const r = o.apply(this, a); const d = now() - t;
      const p = ph(); p.gp++; p.gpMs += d; probe.frameGP += d;
      const k = String(a[0]); const g = probe.getParam[k] || (probe.getParam[k] = {n: 0, ms: 0}); g.n++; g.ms += d;
      return r;
    });
  }
  const raf = window.requestAnimationFrame.bind(window);
  window.requestAnimationFrame = function (cb) {
    return raf(function (ts) {
      probe.frameShader = 0; probe.frameGP = 0; probe.frameWarm = false;
      const t = now();
      try { cb(ts); } finally {
        const d = now() - t; const p = ph();
        p.frames++; p.frameMs += d; if (d > p.maxFrame) p.maxFrame = d;
        // A frame the warm-up drew in (the game prints WARMUP draw with --shader-warmup-log): its programs are the
        // warm-up's own; the others are first sights, what the child meets.
        if (probe.frameWarm) { p.warmFrames++; if (d > p.maxWarmFrame) p.maxWarmFrame = d; }
        else if (d > p.maxSightFrame) p.maxSightFrame = d;
        if (d > 100) {
          p.long++; p.longMs += d; p.longShaderMs += probe.frameShader;
          probe.longFrames.push({phase: probe.phase, at: Math.round(t), ms: Math.round(d),
            shader: Math.round(probe.frameShader), gp: Math.round(probe.frameGP), warm: probe.frameWarm});
        }
      }
    });
  };
  const log = console.log;
  console.log = function () {
    const text = Array.prototype.join.call(arguments, ' ');
    if (text.startsWith('WARMUP draw ')) { probe.frameWarm = true; return log.apply(this, arguments); }
    if (text.startsWith('PROBE phase=')) { probe.phase = text.slice(12).trim(); ph(); }
    else if (text.startsWith('PROBE done')) { probe.done = true; }
    else if (text.startsWith('MENU ready') && !probe.menuReadyAt) {
      probe.menuReadyAt = now(); probe.menuLine = text; if (probe.phase === 'boot') { probe.phase = 'menu'; ph(); }
    }
    if (/^(PROBE|MENU|SANDBOX|EasyCraft|WARMUP)/.test(text)) probe.lines.push(Math.round(now()) + ' ' + text.slice(0, 200));
    return log.apply(this, arguments);
  };
  // What the loading page says (its label and bar), each change with its time: the warm-up's progress.
  document.addEventListener('DOMContentLoaded', () => {
    const label = document.getElementById('label'), fill = document.getElementById('fill');
    if (!label) return;
    new MutationObserver(() => {
      probe.lines.push(Math.round(now()) + ' PAGE ' + label.textContent + ' | ' + (fill ? fill.style.width : ''));
    }).observe(label, {childList: true, characterData: true, subtree: true});
  });
})();
"""


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map, ".wasm": "application/wasm",
                      ".js": "application/javascript", ".pck": "application/octet-stream"}

    def log_message(self, *a):
        pass

    def end_headers(self):
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def do_GET(self):
        path = self.path.split("?")[0]
        if path in ("/", "/index.html"):
            # The probe's args: the page adds window.__probeArgs (set by the wrapper) to the engine's args.
            body = open(os.path.join(self.directory, "index.html"), encoding="utf-8").read()
            body = body.replace("concat(GODOT_CONFIG['args'] || [])",
                                "concat(GODOT_CONFIG['args'] || [], window.__probeArgs || [])")
            data = body.encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/html")
            self.send_header("Content-Length", str(len(data)))
            self.end_headers()
            self.wfile.write(data)
            return
        super().do_GET()


def free_port():
    s = socket.socket(); s.bind(("127.0.0.1", 0)); p = s.getsockname()[1]; s.close(); return p


class Tab:
    def __init__(self, ws_url):
        self.ws = websocket.create_connection(ws_url, timeout=5, suppress_origin=True)
        self.n = 0

    def call(self, meth, params=None, timeout=120):
        self.n += 1
        self.ws.send(json.dumps({"id": self.n, "method": meth, "params": params or {}}))
        until = time.time() + timeout
        while time.time() < until:
            try:
                m = json.loads(self.ws.recv())
            except websocket.WebSocketTimeoutException:
                continue
            if m.get("id") == self.n:
                return m
        raise TimeoutError(meth)

    def js(self, expr, timeout=120):
        r = self.call("Runtime.evaluate", {"expression": expr, "returnByValue": True}, timeout)
        return r.get("result", {}).get("result", {}).get("value")


def visit(tab, url, args, timeout):
    """Opens the page with `args` for the game, presses PLAY, waits for PROBE done; returns the probe's record."""
    src = WRAPPER.replace("__ARGS__", json.dumps(args))
    ident = tab.call("Page.addScriptToEvaluateOnNewDocument", {"source": src})["result"]["identifier"]
    tab.call("Page.navigate", {"url": url})
    t0 = time.time()
    while time.time() - t0 < 90:
        time.sleep(1)
        if tab.js("!!(document.getElementById('status') && document.getElementById('status').classList.contains('ready'))"):
            break
    tab.js("window.__probe.playAt = performance.now(); document.getElementById('play').click()")
    t0 = time.time()
    last = ""
    while time.time() - t0 < timeout:
        time.sleep(3)
        state = tab.js("JSON.stringify([window.__probe.phase, window.__probe.done, window.__probe.lines.length])")
        if state != last:
            last = state
            print("  %5.0fs %s" % (time.time() - t0, state), flush=True)
        if state and json.loads(state)[1]:
            break
    else:
        print("  TIMEOUT: no PROBE done after %d s" % timeout, flush=True)
    rec = json.loads(tab.js("JSON.stringify(window.__probe)", 300))
    tab.call("Page.removeScriptToEvaluateOnNewDocument", {"identifier": ident})
    return rec


def report(rec, top):
    play = rec.get("playAt", 0)
    menu = rec.get("menuReadyAt", 0)
    print("PLAY -> MENU ready: %.1f s   (%s)" % ((menu - play) / 1000.0 if menu else -1, rec.get("menuLine", "")))
    print("%-12s %6s %9s %8s %7s %6s %9s %9s %8s %6s %6s %9s %9s" % ("phase", "links", "wait ms", "compiles", "frames",
          "long", "long ms", "shader%", "max ms", "sight", "warm", "max sight", "max warm"))
    for name, _ in rec["marks"]:
        p = rec["phases"][name]
        share = 100.0 * p["longShaderMs"] / p["longMs"] if p["longMs"] else 0.0
        print("%-12s %6d %9.0f %8d %7d %6d %9.0f %8.0f%% %8.0f %6d %6d %9.0f %9.0f" % (name, p["links"],
              p["linkMs"] + p["compileMs"], p["compiles"], p["frames"], p["long"], p["longMs"], share, p["maxFrame"],
              p.get("sight", 0), p.get("warm", 0), p.get("maxSightFrame", 0), p.get("maxWarmFrame", 0)))
    for name, _ in rec["marks"]:
        links = [l for l in rec["links"] if l["phase"] == name]
        if not links:
            continue
        groups = {}
        for l in links:
            g = groups.setdefault((l["kind"], l["hash"]), {"n": 0, "ms": 0.0, "defs": set(), "mat": l["mat"], "tex": l["tex"]})
            g["n"] += 1; g["ms"] += l["ms"]; g["defs"].add(l["defines"])
        print("--- %s: %d programs, %d shaders" % (name, len(links), len(groups)))
        for (kind, h), g in sorted(groups.items(), key=lambda kv: -kv[1]["n"])[:top]:
            print("  %-6s %s x%-3d %7.0f ms  tex[%s] mat[%s]" % (kind, h, g["n"], g["ms"], g["tex"][:70], g["mat"][:70]))
    page = [l for l in rec["lines"] if " PAGE " in l]
    if page:
        print("the loading page after PLAY (ms, what it said): " + "; ".join(
            "%d %s" % (int(l.split(" ", 1)[0]) - play, l.split(" PAGE ", 1)[1]) for l in page
            if int(l.split(" ", 1)[0]) >= play)[:1500])
    for l in rec["lines"]:
        if l.split(" ", 1)[1].startswith("WARMUP") and " draw " not in l:
            print("  " + l)
    gp = sorted(rec["getParam"].items(), key=lambda kv: -kv[1]["ms"])[:6]
    print("getParameter by pname (top): " + ", ".join("%s x%d %.0f ms" % (k, v["n"], v["ms"]) for k, v in gp))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("build", nargs="?", default="build/web")
    ap.add_argument("--phases", default="new,play,moon,realistic")
    ap.add_argument("--continue", dest="cont", action="store_true", help="then reload and CONTINUE the saved world")
    ap.add_argument("--json", default="")
    ap.add_argument("--timeout", type=float, default=900)
    ap.add_argument("--top", type=int, default=12)
    ap.add_argument("--size", default="1280,720")
    ap.add_argument("--no-warmup", action="store_true", help="the same build without its shader warm-up (a before)")
    ap.add_argument("--style", default="", help="the saved style from the start (realistic: a REALISTIC child)")
    ap.add_argument("--warmup", action="store_true", help="the warm-up on where its rule is off (--shader-warmup)")
    # The game always gets --shader-warmup-log: it prints each warm-up draw, so the report tells the warm-up's own
    # programs and frames (warm) from first sights (sight), what the child meets.
    ap.add_argument("--menu-seconds", type=float, default=-1, help="seconds on the menu before the phases (12)")
    ns = ap.parse_args()

    port = free_port()
    httpd = http.server.ThreadingHTTPServer(("127.0.0.1", port), functools.partial(Handler, directory=ns.build))
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    url = "http://localhost:%d/" % port
    prof = tempfile.mkdtemp(prefix="ec-probe-")
    chrome = subprocess.Popen(["nice", "google-chrome", "--headless=new", "--remote-debugging-port=0",
                               "--user-data-dir=" + prof, "--no-first-run", "--window-size=" + ns.size,
                               "--autoplay-policy=no-user-gesture-required", "about:blank"],
                              stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    out = {}
    try:
        for _ in range(60):
            try:
                dport = open(os.path.join(prof, "DevToolsActivePort")).read().split()[0]
                tabs = json.load(urllib.request.urlopen("http://localhost:%s/json" % dport))
                break
            except Exception:
                time.sleep(0.5)
        page = next(t for t in tabs if t["type"] == "page")
        tab = Tab(page["webSocketDebuggerUrl"])
        tab.call("Page.enable"); tab.call("Runtime.enable")
        print("VISIT 1: %s  phases %s" % (url, ns.phases), flush=True)
        extra = (["--no-shader-warmup"] if ns.no_warmup else []) + (["--shader-probe-style=" + ns.style] if ns.style else []) \
            + (["--shader-warmup"] if ns.warmup else []) + ["--shader-warmup-log"] \
            + (["--shader-probe-menu=%g" % ns.menu_seconds] if ns.menu_seconds >= 0 else [])
        out["first"] = visit(tab, url, ["--", "--shader-probe=" + ns.phases] + extra, ns.timeout)
        report(out["first"], ns.top)
        if ns.cont:
            print("VISIT 2: reload, CONTINUE", flush=True)
            out["continue"] = visit(tab, url, ["--", "--shader-probe=continue"] + extra, ns.timeout)
            report(out["continue"], ns.top)
    finally:
        if ns.json:
            for v in out.values():
                v.pop("sources", None) if not ns.json.endswith(".full.json") else None
            json.dump(out, open(ns.json, "w"), indent=1)
        chrome.terminate(); time.sleep(1); chrome.kill(); shutil.rmtree(prof, ignore_errors=True)
        httpd.shutdown()


if __name__ == "__main__":
    main()
