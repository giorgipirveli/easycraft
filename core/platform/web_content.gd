class_name WebContent
extends Node
## M7 (owner 2026-09-28: "is it possible to make first download small, then after starting a game download continues
## in background to full game"): the web build's first download leaves the background music out (21 MB of 53: the
## classical pieces and the universes' loops); this node fetches it while the child plays. The export puts packs.json
## next to index.html:
##   {"version": 1, "packs": [{"name": "music", "file": "music.<hash>.pck", "size": <bytes>}]}
## (a new file name whenever the content changes). START_DELAY seconds after boot (the menu first; never while a
## world loads) it reads packs.json; then for each pack: a copy in user://packs/ with the right size is loaded at
## once; otherwise it is downloaded to <file>.part, renamed when it has the right size, older copies of the same
## pack are deleted and it is loaded (ProjectSettings.load_resource_pack: the main pack's files stay). pack_loaded(name)
## then tells the game (Music.on_pack_loaded). Offline (no packs.json) the copies already here are loaded. A failed
## try waits longer each time (RETRY_WAITS, at most MAX_TRIES a run); a download that moves no byte for STALL_SECONDS
## starts again. A hidden tab stops the main loop and with it this clock: nothing counts while the page is away.
## Only in a browser: begin() returns null elsewhere. The network, files and packs go through `io` (WebContentIo).
## A pack of pictures comes once per texture format: an entry with "gpu" ("s3tc": computers, index.pck; "etc2": phones,
## index.mobile.pck) is only for that GPU, the one the page chose (WebGlue.texture_format()); an entry without it is for
## every GPU (the owner 2026-09-28: the realistic style's pictures come after the start too).

## A pack is in: its files are part of res:// now.
signal pack_loaded(pack_name: String)

const MANIFEST := "packs.json"
const DIR := "user://packs/"
const PART := ".part"
## Seconds of running time after boot before anything is asked: the menu comes first.
const START_DELAY := 5.0
## Seconds to wait after the 1st, 2nd, … failed try; then the last one each time.
const RETRY_WAITS: Array[float] = [5.0, 15.0, 30.0, 60.0, 120.0]
## Tries of one step (packs.json, or one pack) in one run; the next start tries again.
const MAX_TRIES := 12
## A download that moves no byte for this long (running time) is cancelled and tried again.
const STALL_SECONDS := 60.0
## The most one frame adds to the clock: a tab shown again reports one very long frame.
const MAX_STEP := 0.25
## Seconds between looks at the packs `later` holds back.
const LATER_CHECK := 2.0
## The texture format of a page that did not say: its own default main pack, index.pck, is S3TC.
const DEFAULT_GPU := "s3tc"

enum Step { MANIFEST, PACKS, LATER, DONE }

var io: WebContentIo
## The page's folder, ending in "/" ("": nothing to fetch).
var base_url := ""
## () -> bool: nothing new starts while it says true (default: world_loading()).
var busy := Callable()
## The texture format this GPU reads (the page's choice): packs.json's entries for another "gpu" are left out.
var gpu := DEFAULT_GPU
## () -> String: the pack to fetch before the others ("": packs.json's order), asked before each pack starts (a download
## going on is never cut). scenes/main.gd: the realistic pictures first for a child who plays in that style.
var first := Callable()
## (pack_name) -> bool: true while that pack is not to be downloaded yet (a whole copy already here still loads); looked
## at again every LATER_CHECK seconds. scenes/main.gd: on an iPhone or iPad the realistic pictures wait for a child who
## plays in that style (memory, 2026-09-28).
var later := Callable()

var _step := Step.MANIFEST
var _wait := START_DELAY
var _tries := 0
var _in_flight := false
var _stall := 0.0
var _bytes := 0
var _packs: Array = []
var _index := 0
var _loaded := {}                 # pack name -> its file, loaded this run
var _looked_offline := false
var _later: Array = []          # packs `later` holds back, {name, file, size}


func _init(content_io: WebContentIo = null, page_folder: String = "") -> void:
	io = content_io if content_io else WebContentIo.new()
	base_url = page_folder
	io.request_done.connect(_on_request_done)
	if base_url == "":
		_step = Step.DONE


func _ready() -> void:
	if io.get_parent() == null:
		add_child(io)


## At boot (scenes/main.gd): in a browser, a WebContent under `root` that starts by itself; null elsewhere. `f`: the
## platform ({}: this device).
static func begin(root: Node, f: Dictionary = {}) -> WebContent:
	if not PlatformRules.fetches_packs(f if not f.is_empty() else PlatformRules.current()):
		return null
	var c := WebContent.new(null, base_of(WebGlue.page_url()))
	c.name = "WebContent"
	c.gpu = WebGlue.texture_format()
	root.add_child.call_deferred(c)
	return c


## The folder of the page at `href` ("https://host/play/index.html?x#y" -> "https://host/play/"); "" when it is not
## an http(s) address.
static func base_of(href: String) -> String:
	var url := href.get_slice("#", 0).get_slice("?", 0)
	if not (url.begins_with("http://") or url.begins_with("https://")):
		return ""
	var cut := url.rfind("/")
	if cut < url.find("//") + 2:
		return url + "/"
	return url.substr(0, cut + 1)


## packs.json's packs [{name, file, size}], or null when the text is not a version 1 packs.json. An entry whose file
## is not "<name>.<anything>.pck" (a plain file name) with a size is left out, and so is one for another `for_gpu`.
static func parse_manifest(text: String, for_gpu: String = DEFAULT_GPU) -> Variant:
	var json := JSON.new()
	if json.parse(text) != OK:
		return null
	var data: Variant = json.data
	if not data is Dictionary or not data.get("packs") is Array:
		return null
	var version: Variant = data.get("version")
	if not (version is float or version is int) or int(version) != 1:
		return null
	var out: Array = []
	for p: Variant in data.packs:
		if p is Dictionary and _safe_entry(p) and _for(p, for_gpu):
			out.append({"name": p.name, "file": p.file, "size": int(p.size)})
	return out


static func _safe_entry(p: Dictionary) -> bool:
	var pack_name: Variant = p.get("name")
	var file: Variant = p.get("file")
	var size: Variant = p.get("size")
	if not (pack_name is String and file is String and (size is float or size is int)):
		return false
	return pack_name != "" and not pack_name.contains(".") and pack_name.is_valid_filename() \
		and file.is_valid_filename() and not file.contains("..") and file.begins_with(pack_name + ".") \
		and file.ends_with(".pck") and int(size) > 0


## An entry without "gpu" is for every GPU; with one, only for that texture format.
static func _for(p: Dictionary, for_gpu: String) -> bool:
	return not p.has("gpu") or (p.gpu is String and p.gpu == for_gpu)


## Seconds to wait after the `tries`-th failed try in a row.
static func retry_wait(tries: int) -> float:
	return RETRY_WAITS[clampi(tries - 1, 0, RETRY_WAITS.size() - 1)]


## "music.a1b2.pck" and "music.a1b2.pck.part" belong to the pack "music".
static func pack_name_of(file: String) -> String:
	return file.get_slice(".", 0)


## Everything asked for this run is done (loaded, or given up until the next start).
func is_done() -> bool:
	return _step == Step.DONE


## A world is loading (its LoadingCard is up): nothing new starts then.
func world_loading() -> bool:
	return is_inside_tree() and get_tree().get_first_node_in_group(LoadingCard.GROUP) != null


func _process(delta: float) -> void:
	tick(delta)


func tick(delta: float) -> void:
	if _step == Step.DONE:
		set_process(false)
		return
	var dt := clampf(delta, 0.0, MAX_STEP)
	if _in_flight:
		_watch(dt)
		return
	if _wait > 0.0:
		_wait -= dt
		return
	if (busy.call() if busy.is_valid() else world_loading()):
		return
	if _step == Step.MANIFEST:
		_ask(base_url + MANIFEST, "")
	elif _step == Step.LATER:
		_look_later()
	else:
		_next_pack()


func _ask(url: String, to_file: String) -> void:
	_stall = 0.0
	_bytes = 0
	var err := io.request(url, to_file)
	if err != OK:
		print("EasyCraft: can't ask for %s (%s)" % [url, error_string(err)])
		_failed()
		return
	_in_flight = true


## No byte for STALL_SECONDS of running time: the request is cancelled and tried again.
func _watch(dt: float) -> void:
	var now := io.downloaded_bytes()
	if now != _bytes:
		_bytes = now
		_stall = 0.0
		return
	_stall += dt
	if _stall >= STALL_SECONDS:
		print("EasyCraft: a download stopped moving; trying again")
		io.cancel()
		_in_flight = false
		if _step == Step.PACKS:
			_download_failed()
		else:
			_failed()


func _on_request_done(result: int, code: int, body: PackedByteArray) -> void:
	if not _in_flight:
		return
	_in_flight = false
	var ok := result == HTTPRequest.RESULT_SUCCESS and code == 200
	if _step == Step.PACKS:
		_downloaded(ok, result, code)
		return
	var packs: Variant = parse_manifest(body.get_string_from_utf8(), gpu) if ok else null
	if packs == null:
		print("EasyCraft: no packs.json yet (result %d, HTTP %d)" % [result, code])
		_load_offline()
		_failed()
		return
	_packs = packs
	_index = 0
	_tries = 0
	_wait = 0.0
	_step = Step.PACKS


## The next pack: loaded at once when a whole copy is here, else downloaded. DONE after the last.
func _next_pack() -> void:
	_bring_first()
	while _index < _packs.size():
		var pack: Dictionary = _packs[_index]
		if _loaded.has(pack.name):
			_index += 1
			continue
		var path: String = DIR + pack.file
		if io.file_size(path) == pack.size:
			if not _use(pack):
				return
			continue
		if later.is_valid() and later.call(pack.name):
			_later.append(_packs.pop_at(_index))
			continue
		io.make_dir(DIR)
		io.remove(path + PART)
		print("EasyCraft: downloading the %s pack (%s, %d bytes)" % [pack.name, pack.file, pack.size])
		_ask(base_url + pack.file, path + PART)
		return
	if _later.is_empty():
		_step = Step.DONE
	else:
		_step = Step.LATER
		_wait = LATER_CHECK


## The packs `later` lets go now join the rest; else another look in LATER_CHECK seconds.
func _look_later() -> void:
	var go: Array = _later.filter(func(p: Dictionary) -> bool: return not later.call(p.name))
	if go.is_empty():
		_wait = LATER_CHECK
		return
	for p: Dictionary in go:
		_later.erase(p)
		_packs.append(p)
	_step = Step.PACKS


## The pack `first` names, when it is still to come, moves up to be the next.
func _bring_first() -> void:
	var wanted: String = str(first.call()) if first.is_valid() else ""
	if wanted == "":
		return
	for i in range(_index + 1, _packs.size()):
		if _packs[i].name == wanted:
			_packs.insert(_index, _packs.pop_at(i))
			return


func _downloaded(ok: bool, result: int, code: int) -> void:
	var pack: Dictionary = _packs[_index]
	var path: String = DIR + pack.file
	var size := io.file_size(path + PART)
	if ok and size == pack.size and io.rename(path + PART, path) == OK:
		io.sync_storage()
		if _use(pack):
			_wait = 0.0
		return
	print("EasyCraft: the %s pack's download failed (result %d, HTTP %d, %d of %d bytes; downloaded %d; in %s: %s)" % [
		pack.name, result, code, size, pack.size, io.downloaded_bytes(), DIR, ", ".join(io.list_files(DIR))])
	_download_failed()


func _download_failed() -> void:
	io.remove(DIR + String(_packs[_index].file) + PART)
	_failed()


## Deletes the pack's other copies, then loads it. False (the copy deleted, a try counted) when the engine refuses it.
func _use(pack: Dictionary) -> bool:
	var path: String = DIR + pack.file
	_clean(pack)
	if not io.load_pack(path):
		print("EasyCraft: %s did not load; it is downloaded again" % pack.file)
		io.remove(path)
		io.sync_storage()
		_failed()
		return false
	_loaded[pack.name] = pack.file
	_index += 1
	_tries = 0
	print("EasyCraft: the %s pack is in (%s)" % [pack.name, pack.file])
	pack_loaded.emit(pack.name)
	return true


## Older copies (and cut-off downloads) of `pack` go; other packs' files stay.
func _clean(pack: Dictionary) -> void:
	var removed := false
	for f: String in io.list_files(DIR):
		if f != pack.file and pack_name_of(f) == pack.name:
			io.remove(DIR + f)
			removed = true
	if removed:
		io.sync_storage()


## packs.json can't be had (offline, the server away): the whole copies already here are loaded, once a run. A
## .part file is a cut-off download and never loaded.
func _load_offline() -> void:
	if _looked_offline:
		return
	_looked_offline = true
	var files := io.list_files(DIR)
	files.sort()
	for f: String in files:
		var pack_name := pack_name_of(f)
		if not f.ends_with(".pck") or _loaded.has(pack_name):
			continue
		if io.load_pack(DIR + f):
			_loaded[pack_name] = f
			print("EasyCraft: offline: the %s pack on this device is in (%s)" % [pack_name, f])
			pack_loaded.emit(pack_name)


func _failed() -> void:
	_tries += 1
	if _tries >= MAX_TRIES:
		print("EasyCraft: packs: gave up for this run after %d tries" % _tries)
		_step = Step.DONE
		return
	_wait = retry_wait(_tries)
