#!/usr/bin/env python3
"""Serves a web export for testing (M7, spec §20.2), with the headers a threaded Godot web build needs.

  python3 tools/web_serve.py build/web            # http://localhost:8060/  (and http://10.0.2.2:8060/ from the emulator)
  python3 tools/web_serve.py build/web-spike 8061
  EC_SLOW_PCK=20 python3 tools/web_serve.py <folder> 8071   # owner #123: each .pck answer waits 20 s (a slow phone)

Threads need SharedArrayBuffer, which browsers only give a cross-origin-isolated page: every response carries
Cross-Origin-Opener-Policy: same-origin and Cross-Origin-Embedder-Policy: require-corp. localhost counts as a secure
context; from the Android emulator use `adb reverse tcp:8060 tcp:8060` and open http://localhost:8060/ there, because
10.0.2.2 is not a secure context and the browser would refuse the threads.
"""
import functools
import http.server
import os
import sys
import time


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".js": "application/javascript",
        ".pck": "application/octet-stream",
        ".webmanifest": "application/manifest+json",
    }

    def do_GET(self) -> None:
        slow = float(os.environ.get("EC_SLOW_PCK", "0") or 0)
        if slow > 0 and self.path.split("?")[0].endswith(".pck"):
            time.sleep(slow)
        super().do_GET()

    def end_headers(self) -> None:
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()


def main() -> None:
    root = sys.argv[1] if len(sys.argv) > 1 else "build/web"
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 8060
    handler = functools.partial(Handler, directory=root)
    with http.server.ThreadingHTTPServer(("0.0.0.0", port), handler) as httpd:
        print(f"WEB_SERVE {root} on http://localhost:{port}/", flush=True)
        httpd.serve_forever()


if __name__ == "__main__":
    main()
