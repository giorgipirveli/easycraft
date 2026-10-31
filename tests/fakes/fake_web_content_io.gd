extends WebContentIo
## WebContent's network, files and packs, all in memory (tests/unit/test_web_content.gd): `files` is path -> size; a
## request waits in `requests` until the test calls finish(); load_pack() records the path.

var files := {}
var requests: Array[Dictionary] = []      # {url, to_file}, every request in order
var loaded_packs: Array[String] = []
var syncs := 0
var cancels := 0
var bytes := 0                            # what downloaded_bytes() says (the stall watch)
var start_error := OK                     # what request() returns
var pack_loads := true                    # what load_pack() returns
var in_flight := false


func request(url: String, to_file: String) -> Error:
	if start_error != OK:
		return start_error
	requests.append({"url": url, "to_file": to_file})
	in_flight = true
	bytes = 0
	return OK


## The request in flight ends: `size` bytes were written to its file (downloads), `body` is the answer (packs.json).
func finish(result: int = HTTPRequest.RESULT_SUCCESS, code: int = 200, size: int = -1,
		body := PackedByteArray()) -> void:
	assert(in_flight, "no request in flight")
	in_flight = false
	var to_file: String = requests.back().to_file
	if to_file != "" and size >= 0:
		files[to_file] = size
	request_done.emit(result, code, body)


func finish_text(text: String, code: int = 200) -> void:
	finish(HTTPRequest.RESULT_SUCCESS, code, -1, text.to_utf8_buffer())


func cancel() -> void:
	cancels += 1
	in_flight = false


func downloaded_bytes() -> int:
	return bytes


func file_size(path: String) -> int:
	return int(files.get(path, -1))


func list_files(dir: String) -> PackedStringArray:
	var out := PackedStringArray()
	for path: String in files:
		if path.get_base_dir() + "/" == dir:
			out.append(path.get_file())
	return out


func make_dir(_dir: String) -> void:
	pass


func remove(path: String) -> void:
	files.erase(path)


func rename(from: String, to: String) -> Error:
	if not files.has(from):
		return ERR_FILE_NOT_FOUND
	files[to] = files[from]
	files.erase(from)
	return OK


func load_pack(path: String) -> bool:
	loaded_packs.append(path)
	return pack_loads


func sync_storage() -> void:
	syncs += 1
