class_name UpdateFetch
extends Node
## Owner #123: the updater's downloads (UpdateFlow.check). From our server: HTTPS only, only the update folders
## (UpdateRules.is_our_url), through HTTPRequest on its own thread with gzip (Caddy sends the `.gz` the deploy puts beside
## each pack, and HTTPRequest writes the un-compressed pack: the spike). From a local folder laid out as the server's
## play/ folder (`source`): a developer's run on a computer and the tests; the URLs are still our server's and checked.
## Also whether the network is metered (the Wi-Fi rule). Part of the updater's own set (tests/unit/test_updater.gd).

const Rules := preload("res://core/platform/update_rules.gd")
## A manifest is a few KB.
const TEXT_LIMIT := 1 << 20
const TEXT_TIMEOUT := 30.0
## A slow phone network (1 Mbit/s) takes 32 MB in about 4.5 minutes.
const FILE_TIMEOUT := 1800.0

## "" = our server; else a folder with android/ and quest/ in it.
var source := ""
## A local folder's network for the Wi-Fi rule (the tests).
var metered_here := false


## {"ok": true, "text"} or {"ok": false, "why"}.
func get_text(url: String) -> Dictionary:
	if not Rules.is_our_url(url):
		return {"ok": false, "why": "not our server"}
	if source != "":
		var path := _local(url)
		if not FileAccess.file_exists(path):
			return {"ok": false, "why": "no such file"}
		return {"ok": true, "text": FileAccess.get_file_as_string(path)}
	var req := _request(TEXT_TIMEOUT, TEXT_LIMIT)
	if req.request(url) != OK:
		req.queue_free()
		return {"ok": false, "why": "no request"}
	var r: Array = await req.request_completed
	req.queue_free()
	if r[0] != HTTPRequest.RESULT_SUCCESS or r[1] != 200:
		return {"ok": false, "why": "result %d, HTTP %d" % [r[0], r[1]]}
	return {"ok": true, "text": (r[3] as PackedByteArray).get_string_from_utf8()}


## Downloads `url` to `path` ({"ok": true} or {"ok": false, "why"}); the caller checks its size and SHA-256.
func get_file(url: String, path: String, size: int) -> Dictionary:
	if not Rules.is_our_url(url):
		return {"ok": false, "why": "not our server"}
	if source != "":
		var from := _local(url)
		if not FileAccess.file_exists(from):
			return {"ok": false, "why": "no such file"}
		return {"ok": DirAccess.copy_absolute(from, path) == OK}
	var req := _request(FILE_TIMEOUT, size + TEXT_LIMIT)
	req.download_file = path
	if req.request(url) != OK:
		req.queue_free()
		return {"ok": false, "why": "no request"}
	var r: Array = await req.request_completed
	req.queue_free()
	if r[0] != HTTPRequest.RESULT_SUCCESS or r[1] != 200:
		return {"ok": false, "why": "result %d, HTTP %d" % [r[0], r[1]]}
	return {"ok": true}


## Ruling 4: whether the network costs by the megabyte (mobile data). Android's ConnectivityManager says (it needs the
## ACCESS_NETWORK_STATE permission every Android preset has); when it cannot be asked, metered (only small patches).
func metered() -> bool:
	if source != "":
		return metered_here
	if not Engine.has_singleton("AndroidRuntime"):
		return true
	var runtime: Object = Engine.get_singleton("AndroidRuntime")
	var context: Variant = runtime.call("getApplicationContext")
	if not context is Object:
		return true
	var connectivity: Variant = (context as Object).call("getSystemService", "connectivity")
	if not connectivity is Object:
		return true
	var answer: Variant = (connectivity as Object).call("isActiveNetworkMetered")
	return answer if answer is bool else true


func _request(timeout: float, limit: int) -> HTTPRequest:
	var req := HTTPRequest.new()
	req.use_threads = true
	req.accept_gzip = true
	req.timeout = timeout
	req.body_size_limit = limit
	add_child(req)
	return req


## Our server's address of a file → the same file in the local folder.
func _local(url: String) -> String:
	return source.path_join(url.trim_prefix(Rules.SERVER + "/play/"))
