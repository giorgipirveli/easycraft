extends GutTest
## M7 (owner 2026-09-28: "is it possible to make first download small, then after starting a game download continues
## in background to full game"): the web build's first download leaves the background music out; WebContent fetches
## it a few seconds after the menu is up. Next to the page, packs.json:
##   {"version": 1, "packs": [{"name": "music", "file": "music.<hash>.pck", "size": <bytes>}]}
## A copy in user://packs/ with the right size is loaded at once; otherwise it is downloaded (to <file>.part, renamed
## when whole), older copies are deleted, the pack is loaded, pack_loaded(name) is told. Retries wait longer each time.
## Driven by hand (tick) with a fake network and file system (tests/fakes/fake_web_content_io.gd).

const FakeIo := preload("res://tests/fakes/fake_web_content_io.gd")
const BASE := "https://example.org/play/"
const FILE := "music.a1b2c3.pck"
const SIZE := 21000000
const PATH := WebContent.DIR + FILE

var io: FakeIo
var content: WebContent
var told: Array[String] = []


func before_each() -> void:
	told.clear()
	io = FakeIo.new()
	autofree(io)
	content = WebContent.new(io, BASE)
	autofree(content)
	content.pack_loaded.connect(func(pack_name: String) -> void: told.append(pack_name))


func after_each() -> void:
	PlatformRules.simulated = {}


func _manifest(packs: Array = [{"name": "music", "file": FILE, "size": SIZE}]) -> String:
	return JSON.stringify({"version": 1, "packs": packs})


## `seconds` of frames, 0.1 s each.
func _run(seconds: float) -> void:
	var t := 0.0
	while t < seconds - 0.0001:
		content.tick(0.1)
		t += 0.1


## Past the start delay, packs.json asked for and answered.
func _to_packs(manifest: String = _manifest()) -> void:
	_run(WebContent.START_DELAY + 0.2)
	assert_eq(io.requests.size(), 1, "packs.json asked for")
	io.finish_text(manifest)
	content.tick(0.1)


# --- the pure parts ------------------------------------------------------------------------------------------------

func test_the_page_folder_from_its_address() -> void:
	assert_eq(WebContent.base_of("https://h.example/play/index.html?x=1#top"), "https://h.example/play/")
	assert_eq(WebContent.base_of("https://h.example/play/"), "https://h.example/play/")
	assert_eq(WebContent.base_of("http://127.0.0.1:8060/index.html"), "http://127.0.0.1:8060/")
	assert_eq(WebContent.base_of("https://h.example/play/?v=2"), "https://h.example/play/")
	assert_eq(WebContent.base_of("https://h.example"), "https://h.example/", "the site's root")
	assert_eq(WebContent.base_of(""), "", "no page")
	assert_eq(WebContent.base_of("not an address"), "")


func test_packs_json_is_read() -> void:
	var packs: Variant = WebContent.parse_manifest(_manifest())
	assert_eq(packs, [{"name": "music", "file": FILE, "size": SIZE}])
	assert_true(WebContent.parse_manifest(_manifest([])) is Array, "no packs is a good answer")


func test_a_bad_packs_json_is_no_answer() -> void:
	for text: String in ["", "not json", "[1, 2]", "{\"version\": 2, \"packs\": []}", "{\"packs\": []}",
			"{\"version\": 1, \"packs\": {}}", "<html>404</html>"]:
		assert_null(WebContent.parse_manifest(text), text)


func test_a_pack_entry_that_is_not_safe_is_left_out() -> void:
	var bad := [
		{"name": "music", "file": "../evil.pck", "size": 5},
		{"name": "music", "file": "sub/music.x.pck", "size": 5},
		{"name": "music", "file": "music.x.zip", "size": 5},
		{"name": "music", "file": "other.x.pck", "size": 5},
		{"name": "music", "file": "music.x.pck", "size": 0},
		{"name": "music", "file": "music.x.pck"},
		{"name": "", "file": ".x.pck", "size": 5},
		{"name": "mu.sic", "file": "mu.sic.x.pck", "size": 5},
		"music.x.pck",
	]
	assert_eq(WebContent.parse_manifest(_manifest(bad)), [])


## M7 (owner 2026-09-28: the realistic style's pictures come later too): a pack of pictures exists once per texture
## format (the page picks index.pck or index.mobile.pck by the GPU); an entry with "gpu" is for that GPU only.
const BOTH_FORMATS := [
	{"name": "music", "file": "music.m1.pck", "size": 20},
	{"name": "realistic", "file": "realistic.d1.pck", "size": 30, "gpu": "s3tc"},
	{"name": "realistic", "file": "realistic.mobile.e1.pck", "size": 31, "gpu": "etc2"},
]


func test_a_pack_for_another_gpu_is_left_out() -> void:
	assert_eq(WebContent.parse_manifest(_manifest(BOTH_FORMATS), "s3tc"), [
		{"name": "music", "file": "music.m1.pck", "size": 20},
		{"name": "realistic", "file": "realistic.d1.pck", "size": 30}], "a computer")
	assert_eq(WebContent.parse_manifest(_manifest(BOTH_FORMATS), "etc2"), [
		{"name": "music", "file": "music.m1.pck", "size": 20},
		{"name": "realistic", "file": "realistic.mobile.e1.pck", "size": 31}], "a phone")


func test_without_a_known_gpu_the_computer_pictures_are_taken() -> void:
	assert_eq(WebContent.parse_manifest(_manifest(BOTH_FORMATS)), WebContent.parse_manifest(_manifest(BOTH_FORMATS),
		"s3tc"), "the page's own default (index.pck) is S3TC")
	assert_eq(WebContent.DEFAULT_GPU, "s3tc")


func test_a_gpu_that_is_not_a_word_leaves_the_entry_out() -> void:
	var odd := [{"name": "realistic", "file": "realistic.x.pck", "size": 5, "gpu": 1},
		{"name": "realistic", "file": "realistic.y.pck", "size": 5, "gpu": ["s3tc"]}]
	assert_eq(WebContent.parse_manifest(_manifest(odd), "s3tc"), [])


func test_a_phone_downloads_its_own_pictures() -> void:
	content.gpu = "etc2"
	_to_packs(_manifest(BOTH_FORMATS))
	assert_eq(io.requests.back().url, BASE + "music.m1.pck")
	io.finish(HTTPRequest.RESULT_SUCCESS, 200, 20)
	content.tick(0.1)
	assert_eq(io.requests.back().url, BASE + "realistic.mobile.e1.pck", "the ETC2 pictures")
	io.finish(HTTPRequest.RESULT_SUCCESS, 200, 31)
	content.tick(0.1)
	assert_eq(told, ["music", "realistic"] as Array[String])
	assert_eq(io.requests.size(), 3, "never the other format's pack")
	assert_true(content.is_done())


## M7: a child who plays in the realistic style gets its pictures before the music (they are what the child sees).
func test_the_pack_asked_for_first_comes_first() -> void:
	content.first = func() -> String: return "realistic"
	_to_packs(_manifest(BOTH_FORMATS))
	assert_eq(io.requests.back().url, BASE + "realistic.d1.pck", "before the music, though packs.json lists it second")
	io.finish(HTTPRequest.RESULT_SUCCESS, 200, 30)
	content.tick(0.1)
	assert_eq(io.requests.back().url, BASE + "music.m1.pck", "then the rest in packs.json's order")
	io.finish(HTTPRequest.RESULT_SUCCESS, 200, 20)
	assert_eq(told, ["realistic", "music"] as Array[String])


func test_without_a_first_pack_packs_json_decides_the_order() -> void:
	content.first = func() -> String: return ""
	_to_packs(_manifest(BOTH_FORMATS))
	assert_eq(io.requests.back().url, BASE + "music.m1.pck")


func test_a_pack_asked_for_while_another_downloads_is_next() -> void:
	var wanted := [""]
	content.first = func() -> String: return wanted[0]
	_to_packs(_manifest([{"name": "music", "file": "music.m1.pck", "size": 20}, {"name": "extra", "file": "extra.x.pck",
		"size": 5}, {"name": "realistic", "file": "realistic.d1.pck", "size": 30, "gpu": "s3tc"}]))
	assert_eq(io.requests.back().url, BASE + "music.m1.pck")
	wanted[0] = "realistic"   # the child picks REALISTIC while the music comes: the music is not cut
	_run(1.0)
	assert_eq(io.cancels, 0)
	io.finish(HTTPRequest.RESULT_SUCCESS, 200, 20)
	content.tick(0.1)
	assert_eq(io.requests.back().url, BASE + "realistic.d1.pck", "next, before the extra pack")
	io.finish(HTTPRequest.RESULT_SUCCESS, 200, 30)
	content.tick(0.1)
	io.finish(HTTPRequest.RESULT_SUCCESS, 200, 5)
	assert_eq(told, ["music", "realistic", "extra"] as Array[String])


func test_waits_grow_between_tries() -> void:
	assert_eq(WebContent.retry_wait(1), WebContent.RETRY_WAITS[0])
	assert_eq(WebContent.retry_wait(2), WebContent.RETRY_WAITS[1])
	assert_gt(WebContent.retry_wait(3), WebContent.retry_wait(2))
	assert_eq(WebContent.retry_wait(99), WebContent.RETRY_WAITS[-1], "then the longest wait")


func test_a_pack_file_names_its_pack() -> void:
	assert_eq(WebContent.pack_name_of("music.a1b2.pck"), "music")
	assert_eq(WebContent.pack_name_of("music.a1b2.pck.part"), "music")


# --- when it starts ------------------------------------------------------------------------------------------------

func test_nothing_is_asked_before_the_menu_has_been_up_a_few_seconds() -> void:
	_run(WebContent.START_DELAY - 0.5)
	assert_eq(io.requests.size(), 0)
	_run(0.7)
	assert_eq(io.requests.size(), 1)
	assert_eq(io.requests[0], {"url": BASE + "packs.json", "to_file": ""}, "packs.json next to the page, in memory")


func test_a_long_frame_counts_only_a_little() -> void:
	content.tick(3600.0)   # a hidden tab coming back reports one very long frame
	content.tick(0.1)
	assert_eq(io.requests.size(), 0, "the start delay is real playing time")


func test_nothing_starts_while_a_world_loads() -> void:
	var loading := [true]
	content.busy = func() -> bool: return loading[0]
	_run(WebContent.START_DELAY + 5.0)
	assert_eq(io.requests.size(), 0, "the world load goes first")
	loading[0] = false
	content.tick(0.1)
	assert_eq(io.requests.size(), 1)


func test_a_page_without_an_address_asks_for_nothing() -> void:
	var quiet := WebContent.new(io, "")
	autofree(quiet)
	for i in 200:
		quiet.tick(0.1)
	assert_eq(io.requests.size(), 0)
	assert_true(quiet.is_done())


# --- the packs -----------------------------------------------------------------------------------------------------

func test_a_pack_already_here_with_the_right_size_is_loaded_without_a_download() -> void:
	io.files[PATH] = SIZE
	_to_packs()
	assert_eq(io.requests.size(), 1, "only packs.json")
	assert_eq(io.loaded_packs, [PATH] as Array[String])
	assert_eq(told, ["music"] as Array[String])
	assert_true(content.is_done())


func test_a_pack_not_here_is_downloaded_next_to_its_name_then_loaded() -> void:
	_to_packs()
	assert_eq(io.requests.size(), 2)
	assert_eq(io.requests[1], {"url": BASE + FILE, "to_file": PATH + ".part"}, "into a .part file first")
	assert_eq(io.loaded_packs, [] as Array[String])
	io.finish(HTTPRequest.RESULT_SUCCESS, 200, SIZE)
	assert_eq(io.file_size(PATH), SIZE, "whole: renamed")
	assert_eq(io.file_size(PATH + ".part"), -1)
	assert_eq(io.loaded_packs, [PATH] as Array[String])
	assert_eq(told, ["music"] as Array[String])
	assert_gt(io.syncs, 0, "the browser's storage keeps it")
	_run(1.0)
	assert_true(content.is_done())
	assert_eq(io.requests.size(), 2)


func test_a_copy_with_the_wrong_size_is_downloaded_again() -> void:
	io.files[PATH] = SIZE - 10
	_to_packs()
	assert_eq(io.requests.size(), 2)
	assert_eq(io.requests[1].url, BASE + FILE)


func test_older_copies_of_the_pack_are_deleted_and_others_kept() -> void:
	io.files[WebContent.DIR + "music.0ld.pck"] = 900
	io.files[WebContent.DIR + "music.0ld2.pck.part"] = 10
	io.files[WebContent.DIR + "other.x.pck"] = 5
	io.files[WebContent.DIR + "musical.x.pck"] = 5
	_to_packs()
	io.finish(HTTPRequest.RESULT_SUCCESS, 200, SIZE)
	assert_eq(io.files.keys().size(), 3, str(io.files))
	assert_true(io.files.has(PATH))
	assert_true(io.files.has(WebContent.DIR + "other.x.pck"), "another pack's file")
	assert_true(io.files.has(WebContent.DIR + "musical.x.pck"), "another pack's file")


func test_a_failed_download_is_tried_again_after_growing_waits() -> void:
	_to_packs()
	io.finish(HTTPRequest.RESULT_CANT_CONNECT, 0, 1000)
	assert_eq(io.file_size(PATH + ".part"), -1, "a broken piece is not kept")
	assert_eq(told, [] as Array[String])
	_run(WebContent.RETRY_WAITS[0] - 0.3)
	assert_eq(io.requests.size(), 2, "waits first")
	_run(0.5)
	assert_eq(io.requests.size(), 3, "then tries again")
	io.finish(HTTPRequest.RESULT_SUCCESS, 404)
	_run(WebContent.RETRY_WAITS[0] + 0.5)
	assert_eq(io.requests.size(), 3, "a longer wait the second time")
	_run(WebContent.RETRY_WAITS[1] - WebContent.RETRY_WAITS[0])
	assert_eq(io.requests.size(), 4)
	io.finish(HTTPRequest.RESULT_SUCCESS, 200, SIZE)
	assert_eq(told, ["music"] as Array[String])


func test_a_short_download_is_not_kept() -> void:
	_to_packs()
	io.finish(HTTPRequest.RESULT_SUCCESS, 200, SIZE - 1)
	assert_eq(io.file_size(PATH + ".part"), -1)
	assert_eq(io.file_size(PATH), -1)
	assert_eq(io.loaded_packs, [] as Array[String])


func test_a_request_that_cannot_start_is_tried_again() -> void:
	_run(WebContent.START_DELAY + 0.2)
	io.finish_text(_manifest())
	io.start_error = ERR_CANT_CONNECT
	content.tick(0.1)
	io.start_error = OK
	assert_eq(io.requests.size(), 1)
	_run(WebContent.RETRY_WAITS[0] + 0.2)
	assert_eq(io.requests.size(), 2)


func test_a_download_that_stops_moving_starts_again() -> void:
	_to_packs()
	io.files[PATH + ".part"] = 1000   # what came so far
	io.bytes = 1000
	_run(WebContent.STALL_SECONDS - 1.0)
	io.bytes = 2000   # it moves: the watch starts over
	_run(WebContent.STALL_SECONDS - 1.0)
	assert_eq(io.cancels, 0)
	_run(1.5)
	assert_eq(io.cancels, 1, "no byte for STALL_SECONDS: cancelled")
	assert_eq(io.file_size(PATH + ".part"), -1)
	_run(WebContent.RETRY_WAITS[0] + 0.2)
	assert_eq(io.requests.size(), 3, "and tried again")


func test_a_pack_that_does_not_load_is_downloaded_again() -> void:
	io.files[PATH] = SIZE
	io.pack_loads = false
	_to_packs()
	assert_eq(io.file_size(PATH), -1, "a copy the engine refuses is deleted")
	assert_eq(told, [] as Array[String])
	io.pack_loads = true
	_run(WebContent.RETRY_WAITS[0] + 0.2)
	assert_eq(io.requests.back().url, BASE + FILE)


func test_two_packs_come_one_after_the_other() -> void:
	_to_packs(_manifest([{"name": "music", "file": FILE, "size": SIZE}, {"name": "extra", "file": "extra.9.pck",
		"size": 50}]))
	io.finish(HTTPRequest.RESULT_SUCCESS, 200, SIZE)
	content.tick(0.1)
	assert_eq(io.requests.back().url, BASE + "extra.9.pck")
	io.finish(HTTPRequest.RESULT_SUCCESS, 200, 50)
	assert_eq(told, ["music", "extra"] as Array[String])


func test_each_pack_has_its_own_tries() -> void:
	_to_packs(_manifest([{"name": "music", "file": FILE, "size": SIZE}, {"name": "extra", "file": "extra.9.pck",
		"size": 50}]))
	for i in WebContent.MAX_TRIES - 1:   # the music pack: every try but the last fails
		io.finish(HTTPRequest.RESULT_CANT_CONNECT, 0)
		_run(WebContent.retry_wait(i + 1) + 0.2)
	io.finish(HTTPRequest.RESULT_SUCCESS, 200, SIZE)
	content.tick(0.1)
	assert_eq(io.requests.back().url, BASE + "extra.9.pck")
	io.finish(HTTPRequest.RESULT_CANT_CONNECT, 0)
	assert_false(content.is_done(), "the extra pack's first failure is its first")
	_run(WebContent.RETRY_WAITS[0] + 0.2)
	io.finish(HTTPRequest.RESULT_SUCCESS, 200, 50)
	assert_eq(told, ["music", "extra"] as Array[String])


# --- packs.json missing, broken or out of reach ---------------------------------------------------------------------

func test_a_missing_or_broken_packs_json_is_asked_again_later() -> void:
	_run(WebContent.START_DELAY + 0.2)
	io.finish_text("<html>Not found</html>", 404)
	_run(WebContent.RETRY_WAITS[0] + 0.2)
	assert_eq(io.requests.size(), 2)
	io.finish_text("{ broken")
	_run(WebContent.RETRY_WAITS[1] + 0.2)
	assert_eq(io.requests.size(), 3)
	assert_eq(io.requests[2].url, BASE + "packs.json")
	io.finish_text(_manifest())
	content.tick(0.1)
	assert_eq(io.requests.back().url, BASE + FILE, "then the pack")


func test_offline_the_copy_already_here_is_loaded() -> void:
	io.files[PATH] = SIZE
	io.files[WebContent.DIR + "extra.1.pck.part"] = 3   # a download cut off: never loaded
	_run(WebContent.START_DELAY + 0.2)
	io.finish(HTTPRequest.RESULT_CANT_CONNECT, 0)
	assert_eq(io.loaded_packs, [PATH] as Array[String])
	assert_eq(told, ["music"] as Array[String])
	_run(WebContent.RETRY_WAITS[0] + 0.2)
	io.finish_text(_manifest())   # back online: the same pack
	_run(1.0)
	assert_eq(io.loaded_packs, [PATH] as Array[String], "not loaded twice")
	assert_eq(io.requests.size(), 2, "nothing to download")
	assert_true(content.is_done())


func test_it_stops_trying_for_this_run_after_max_tries() -> void:
	_run(WebContent.START_DELAY + 0.2)
	for i in WebContent.MAX_TRIES:
		assert_eq(io.requests.size(), i + 1)
		io.finish(HTTPRequest.RESULT_CANT_CONNECT, 0)
		_run(WebContent.retry_wait(i + 1) + 0.2)
	_run(WebContent.RETRY_WAITS[-1] + 0.2)
	assert_eq(io.requests.size(), WebContent.MAX_TRIES)
	assert_true(content.is_done(), "the next start tries again")


# --- only in a browser ---------------------------------------------------------------------------------------------

func test_off_the_web_nothing_starts() -> void:
	var root := Node.new()
	add_child_autofree(root)
	assert_null(WebContent.begin(root, {PlatformRules.WEB: false, PlatformRules.ANDROID: true}), "Android")
	assert_null(WebContent.begin(root, {PlatformRules.WEB: false}), "the desktop")
	assert_null(WebContent.begin(root), "this test run")
	await wait_process_frames(1)
	assert_eq(root.get_child_count(), 0)


func test_in_a_browser_it_is_started_once_at_boot() -> void:
	assert_true(PlatformRules.fetches_packs({PlatformRules.WEB: true}))
	assert_false(PlatformRules.fetches_packs({PlatformRules.WEB: false, PlatformRules.MOBILE: true}))
	var root := Node.new()
	add_child_autofree(root)
	var c := WebContent.begin(root, {PlatformRules.WEB: true})
	assert_not_null(c)
	await wait_process_frames(1)
	assert_eq(c.get_parent(), root)
	assert_eq(c.base_url, "", "this run has no page (WebGlue.page_url off the web)")
	assert_eq(WebGlue.page_url(), "")


func test_a_world_loading_holds_the_start() -> void:
	var tree_content := WebContent.new(io, BASE)
	add_child_autofree(tree_content)
	assert_false(tree_content.world_loading())
	var card := LoadingCard.new()
	card.setup(ModeRules.SANDBOX, 1)
	add_child_autofree(card)
	assert_true(tree_content.world_loading(), "a loading card is up")


func test_at_boot_the_game_starts_it_and_the_music_hears_it() -> void:
	var main: GDScript = load("res://scenes/main.gd")
	var root := Node.new()
	add_child_autofree(root)
	assert_null(main.call(&"start_packs", root, {PlatformRules.WEB: false}), "not off the web")
	var c: WebContent = main.call(&"start_packs", root, {PlatformRules.WEB: true})
	assert_not_null(c)
	assert_true(c.pack_loaded.is_connected(Music.on_pack_loaded), "Music.on_pack_loaded hears every pack")
	await wait_process_frames(1)
	assert_eq(c.get_parent(), root)


func test_at_boot_the_realistic_pictures_are_heard_and_come_first_for_a_realistic_child() -> void:
	var main: GDScript = load("res://scenes/main.gd")
	var root := Node.new()
	add_child_autofree(root)
	var c: WebContent = main.call(&"start_packs", root, {PlatformRules.WEB: true})
	assert_true(c.pack_loaded.is_connected(RealisticPack.on_pack_loaded), "the worlds turn realistic when it lands")
	assert_eq(c.gpu, WebGlue.texture_format(), "the pictures in the format of the page's main pack")
	var saved := str(Profile.data.settings.style)
	Profile.data.settings.style = "realistic"
	var realistic_first: String = c.first.call() if c.first.is_valid() else ""
	Profile.data.settings.style = "blocky"
	var blocky_first: String = c.first.call() if c.first.is_valid() else "?"
	Profile.data.settings.style = saved
	assert_eq(realistic_first, RealisticPack.PACK, "a child who plays REALISTIC sees these pictures first")
	assert_eq(blocky_first, "", "a BLOCKY child: packs.json's order (the music first)")


## 2026-09-28: a pack `later` holds back is not downloaded (on an iPhone the realistic pictures wait for a child who
## chooses that style); the packs after it come; it comes once `later` lets it, looked at every LATER_CHECK seconds.
func test_a_pack_held_back_comes_when_it_is_wanted() -> void:
	var wanted := [false]
	content.later = func(pack_name: String) -> bool: return pack_name == "extra" and not wanted[0]
	_to_packs(_manifest([{"name": "extra", "file": "extra.9.pck", "size": 50}, {"name": "music", "file": FILE,
		"size": SIZE}]))
	assert_eq(io.requests.back().url, BASE + FILE, "the held pack is passed over: the music comes")
	io.finish(HTTPRequest.RESULT_SUCCESS, 200, SIZE)
	_run(WebContent.LATER_CHECK * 3)
	assert_eq(io.requests.size(), 2, "nothing more while it is held")
	assert_false(content.is_done(), "it keeps looking")
	wanted[0] = true
	_run(WebContent.LATER_CHECK + 0.2)
	assert_eq(io.requests.back().url, BASE + "extra.9.pck", "wanted now: downloaded")
	io.finish(HTTPRequest.RESULT_SUCCESS, 200, 50)
	assert_eq(told, ["music", "extra"] as Array[String])
	content.tick(0.1)
	assert_true(content.is_done())


func test_a_held_pack_already_on_the_device_still_loads() -> void:
	content.later = func(_pack_name: String) -> bool: return true
	io.files[PATH] = SIZE
	_to_packs()
	assert_eq(told, ["music"] as Array[String], "a copy here is loaded, held or not")
	assert_eq(io.requests.size(), 1, "only packs.json: nothing downloaded")
	content.tick(0.1)
	assert_true(content.is_done(), "nothing is held back")


func test_at_boot_an_iphone_holds_the_realistic_pictures_for_a_blocky_child() -> void:
	var main: GDScript = load("res://scenes/main.gd")
	var root := Node.new()
	add_child_autofree(root)
	var iphone := {PlatformRules.WEB: true, PlatformRules.WEB_IOS: true, PlatformRules.TOUCH_SCREEN: true}
	var c: WebContent = main.call(&"start_packs", root, iphone)
	var saved := str(Profile.data.settings.style)
	Profile.data.settings.style = "blocky"
	var blocky: bool = c.later.call(RealisticPack.PACK) if c.later.is_valid() else false
	var music: bool = c.later.call(Music.PACK) if c.later.is_valid() else true
	Profile.data.settings.style = "realistic"
	var realistic: bool = c.later.call(RealisticPack.PACK) if c.later.is_valid() else true
	Profile.data.settings.style = saved
	assert_true(blocky, "a BLOCKY child on an iPhone: the realistic pictures wait")
	assert_false(realistic, "a REALISTIC child: they come")
	assert_false(music, "the music always comes")
	var pc: WebContent = main.call(&"start_packs", root, {PlatformRules.WEB: true, PlatformRules.WEB_WINDOWS: true})
	assert_false(pc.later.call(RealisticPack.PACK) if pc.later.is_valid() else false, "a PC fetches everything")
