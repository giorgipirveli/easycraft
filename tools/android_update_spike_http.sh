#!/usr/bin/env bash
# Owner #123's spike, part 2 (docs/devlog/parts/same-version.md): does Godot's HTTPRequest download a pack the way our
# server sends it, and how long does checking it take?
#
#   tools/android_update_spike_http.sh <a .pck file> <empty work folder>
#
# A local server on 127.0.0.1 sends the pack as Caddy's `precompressed gzip` does for /play/ (the .gz beside the file,
# Content-Encoding: gzip when the request accepts it). Godot downloads it with HTTPRequest (use_threads, download_file,
# accept_gzip: as autoloads/updater.gd's downloader does), then hashes the file (SHA-256 in 1 MiB pieces). It prints
# what the server sent, what landed, both hashes and the times. Local only: never the live server.
set -euo pipefail

PACK="${1:?usage: tools/android_update_spike_http.sh <pack.pck> <work folder>}"
WORK="${2:?usage: tools/android_update_spike_http.sh <pack.pck> <work folder>}"
mkdir -p "$WORK/serve" "$WORK/xdg"
WORK="$(cd "$WORK" && pwd)"
cp "$PACK" "$WORK/serve/game.pck"
gzip -9 -k -f "$WORK/serve/game.pck"
PORT="${SPIKE_PORT:-8093}"

cat > "$WORK/server.py" <<'PY'
import http.server, os, sys
root, port = sys.argv[1], int(sys.argv[2])
class H(http.server.BaseHTTPRequestHandler):
    def do_GET(self):
        path = os.path.join(root, self.path.lstrip("/"))
        gz = path + ".gz"
        enc = self.headers.get("Accept-Encoding", "")
        send, extra = (gz, {"Content-Encoding": "gzip"}) if "gzip" in enc and os.path.exists(gz) else (path, {})
        if not os.path.exists(send):
            self.send_error(404)
            return
        data = open(send, "rb").read()
        self.send_response(200)
        self.send_header("Content-Type", "application/octet-stream")
        self.send_header("Content-Length", str(len(data)))
        for k, v in extra.items():
            self.send_header(k, v)
        self.end_headers()
        self.wfile.write(data)
        print("SPIKE_SERVER sent %s (%d bytes) Accept-Encoding=%r" % (os.path.basename(send), len(data), enc), flush=True)
    def log_message(self, *a):
        pass
http.server.HTTPServer(("127.0.0.1", port), H).serve_forever()
PY

cat > "$WORK/fetch.gd" <<'GD'
extends SceneTree


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var url := OS.get_environment("SPIKE_URL")
	var out := OS.get_environment("SPIKE_OUT")
	var req := HTTPRequest.new()
	req.use_threads = true
	req.accept_gzip = true
	req.download_file = out
	root.add_child(req)
	var t := Time.get_ticks_msec()
	var frames := Engine.get_process_frames()
	req.request(url)
	var r: Array = await req.request_completed
	var headers: PackedStringArray = r[2]
	print("SPIKE_HTTP result=%d code=%d in %d ms over %d frames, Content-Encoding=%s, get_body_size=%d, downloaded=%d" % [
		r[0], r[1], Time.get_ticks_msec() - t, Engine.get_process_frames() - frames,
		Array(headers).filter(func(h: String) -> bool: return h.to_lower().begins_with("content-encoding")),
		req.get_body_size(), req.get_downloaded_bytes()])
	t = Time.get_ticks_msec()
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	var f := FileAccess.open(out, FileAccess.READ)
	var size := f.get_length()
	while f.get_position() < size:
		ctx.update(f.get_buffer(1 << 20))
	print("SPIKE_HTTP landed %d bytes, sha256 %s, hashed in %d ms" % [size, ctx.finish().hex_encode(), Time.get_ticks_msec() - t])
	quit()
GD

/usr/bin/python3 "$WORK/server.py" "$WORK/serve" "$PORT" &
server=$!
trap 'kill $server 2>/dev/null || true' EXIT
sleep 1
echo "SPIKE_HTTP the file's own sha256 $(sha256sum "$WORK/serve/game.pck" | cut -d' ' -f1), $(stat -c %s "$WORK/serve/game.pck") bytes; gzip $(stat -c %s "$WORK/serve/game.pck.gz") bytes"
(cd "$WORK" && XDG_DATA_HOME="$WORK/xdg" SPIKE_URL="http://127.0.0.1:$PORT/game.pck" SPIKE_OUT="$WORK/landed.pck" \
	nice "${GODOT:-godot}" --headless -s "$WORK/fetch.gd" 2>&1 | grep -E "SPIKE|ERROR" || true)
