class_name WebContentIo
extends Node
## WebContent's hands (M7, the web build's later packs): one HTTPRequest at a time, the files under user://packs/ and
## the engine's resource packs. Kept apart so the loader's decisions are tested with a fake
## (tests/fakes/fake_web_content_io.gd); these few calls are tested on real files (tests/integration/test_web_content_io.gd)
## and in a browser (docs/devlog/parts/m7-web-packs.md).

## request() finished: an HTTPRequest.Result, the HTTP status, and the body (empty when it went to a file).
signal request_done(result: int, code: int, body: PackedByteArray)

## HTTPRequest reads at most one chunk a frame; a browser's fetch hands over bigger pieces than the 64 KiB default.
const CHUNK := 262144

var _http: HTTPRequest
## Where the request in flight goes ("": its body comes with request_done).
var _to_file := ""


## GET `url` into the file `to_file` ("": the body comes with request_done). The body comes into memory and is written
## here: HTTPRequest's own download_file is deleted when a body without a length ends, which is every download in a
## browser (fetch() gives no length; the music pack vanished after every byte had come, 2026-09-28).
func request(url: String, to_file: String) -> Error:
	var http := http_request()
	http.download_file = ""
	_to_file = to_file
	return http.request(url)


## The HTTPRequest, made on first use. In a browser fetch() has already un-gzipped the body: a second pass would fail
## (as the Nakama adapter found, tests/unit/test_web_http_gzip.gd).
func http_request() -> HTTPRequest:
	if _http == null:
		_http = HTTPRequest.new()
		_http.name = "Http"
		_http.accept_gzip = not PlatformRules.is_web(PlatformRules.current())
		_http.download_chunk_size = CHUNK
		_http.request_completed.connect(_on_completed)
		add_child(_http)
	return _http


func _on_completed(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var to_file := _to_file
	_to_file = ""
	if to_file != "" and result == HTTPRequest.RESULT_SUCCESS:
		var f := FileAccess.open(to_file, FileAccess.WRITE)
		if f == null or not f.store_buffer(body):
			result = HTTPRequest.RESULT_DOWNLOAD_FILE_WRITE_ERROR
		body = PackedByteArray()
	request_done.emit(result, code, body)


## Stops the request in flight (request_done does not come).
func cancel() -> void:
	_to_file = ""
	if _http:
		_http.cancel_request()


func downloaded_bytes() -> int:
	return _http.get_downloaded_bytes() if _http else 0


## The file's size in bytes, -1 when there is none.
func file_size(path: String) -> int:
	var f := FileAccess.open(path, FileAccess.READ)
	return f.get_length() if f else -1


## The file names in `dir` (none when it doesn't exist).
func list_files(dir: String) -> PackedStringArray:
	return DirAccess.get_files_at(dir) if DirAccess.dir_exists_absolute(dir) else PackedStringArray()


func make_dir(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)


func remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)


func rename(from: String, to: String) -> Error:
	return DirAccess.rename_absolute(from, to)


## Adds the pack's files to res://; files the game already has stay as they are.
func load_pack(path: String) -> bool:
	return ProjectSettings.load_resource_pack(path, false)


## A browser keeps user:// in its storage only after a write: deletions and renames need the stamp (WebStorage).
func sync_storage() -> void:
	WebStorage.sync()
