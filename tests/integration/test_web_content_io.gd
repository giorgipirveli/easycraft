extends GutTest
## M7: WebContentIo, WebContent's hands, on real files: sizes, listing, renaming and deleting under a private folder,
## a real resource pack (made here with PCKPacker) loaded into res://, and the HTTPRequest it downloads with (no
## second gunzip in a browser). The download itself is checked in a browser (docs/devlog/parts/m7-web-packs.md).

var DIR := "user://test_web_content_io_%d/" % OS.get_process_id()
var io: WebContentIo


func before_each() -> void:
	io = WebContentIo.new()
	add_child_autofree(io)
	DirAccess.make_dir_recursive_absolute(DIR)


func after_each() -> void:
	PlatformRules.simulated = {}
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR + f)
	DirAccess.remove_absolute(DIR)


func _write(path: String, bytes: int) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_buffer(_bytes(bytes))
	f.close()


func _bytes(n: int) -> PackedByteArray:
	var b := PackedByteArray()
	b.resize(n)
	return b


func test_files_sizes_renames_and_deletes() -> void:
	assert_eq(io.file_size(DIR + "none.pck"), -1, "no file")
	_write(DIR + "music.a.pck.part", 1234)
	assert_eq(io.file_size(DIR + "music.a.pck.part"), 1234)
	assert_eq(io.list_files(DIR), PackedStringArray(["music.a.pck.part"]))
	assert_eq(io.rename(DIR + "music.a.pck.part", DIR + "music.a.pck"), OK)
	assert_eq(io.list_files(DIR), PackedStringArray(["music.a.pck"]))
	io.remove(DIR + "music.a.pck")
	io.remove(DIR + "music.a.pck")   # twice: no error
	assert_eq(io.list_files(DIR), PackedStringArray())


func test_a_folder_not_made_yet_lists_nothing() -> void:
	assert_eq(io.list_files(DIR + "later/"), PackedStringArray())
	io.make_dir(DIR + "later/")
	assert_true(DirAccess.dir_exists_absolute(DIR + "later/"))
	DirAccess.remove_absolute(DIR + "later/")


func test_a_real_pack_adds_its_files_to_res() -> void:
	var inside := "res://web_content_test_%d/hello.txt" % OS.get_process_id()
	var source := DIR + "hello.txt"
	var f := FileAccess.open(source, FileAccess.WRITE)
	f.store_string("more music")
	f.close()
	var pck := DIR + "music.t1.pck"
	var packer := PCKPacker.new()
	assert_eq(packer.pck_start(pck), OK)
	assert_eq(packer.add_file(inside, source), OK)
	assert_eq(packer.flush(), OK)
	assert_false(FileAccess.file_exists(inside), "not in the game before")
	assert_true(io.load_pack(pck))
	assert_true(FileAccess.file_exists(inside), "in res:// once the pack is loaded")
	assert_eq(FileAccess.get_file_as_string(inside), "more music")


func test_the_download_never_gunzips_twice_in_a_browser() -> void:
	PlatformRules.simulated = {PlatformRules.WEB: true}
	var http := io.http_request()
	assert_false(http.accept_gzip, "the browser's fetch() has un-gzipped it already")
	assert_eq(http.download_chunk_size, WebContentIo.CHUNK)
	assert_eq(io.http_request(), http, "one HTTPRequest, made once")


## Owner 2026-09-28 ("while playing download full data needed for full game run in background"): a browser's fetch()
## gives no length for the body, and Godot's HTTPRequest deletes its download_file when a body without one ends
## (http_request.cpp 4.7.2: download_complete is only set when a length matched or a chunked body ended): the music
## pack vanished after every byte had come. On this PC a body without a length ends in a connection error instead, so
## the test pins the cure: HTTPRequest never gets the file; WebContentIo writes what came itself.
func test_the_download_is_written_by_us_not_by_http_request() -> void:
	var server := TCPServer.new()
	var port := 0
	for p in range(47810, 47830):
		if server.listen(p, "127.0.0.1") == OK:
			port = p
			break
	assert_ne(port, 0, "a free port")
	var body := PackedByteArray()
	for i in 100000:
		body.append(i % 251)
	var got: Array = []
	io.request_done.connect(func(r: int, c: int, b: PackedByteArray) -> void: got.append([r, c, b.size()]))
	var part := DIR + "music.t.pck.part"
	assert_eq(io.request("http://127.0.0.1:%d/music.t.pck" % port, part), OK)
	assert_eq(io.http_request().download_file, "", "HTTPRequest would delete it in a browser")
	var reply := ("HTTP/1.1 200 OK\r\nContent-Length: %d\r\nConnection: close\r\n\r\n" % body.size()).to_utf8_buffer() + body
	var peer: StreamPeerTCP = null
	var asked := ""
	var sent := 0
	for frame in 600:
		if not got.is_empty():
			break
		if peer == null and server.is_connection_available():
			peer = server.take_connection()
		if peer:
			peer.poll()
			if not asked.contains("\r\n\r\n") and peer.get_available_bytes() > 0:
				asked += peer.get_utf8_string(peer.get_available_bytes())
			elif asked.contains("\r\n\r\n") and sent < reply.size():
				var r: Array = peer.put_partial_data(reply.slice(sent, mini(sent + 16384, reply.size())))
				sent += int(r[1])
		await get_tree().process_frame
	server.stop()
	assert_eq(got, [[HTTPRequest.RESULT_SUCCESS, 200, 0]], "done, the body in the file")
	assert_eq(io.file_size(part), body.size(), "the file is there, whole")
	assert_eq(FileAccess.get_file_as_bytes(part), body)


func test_off_the_web_the_download_may_be_gzipped() -> void:
	PlatformRules.simulated = {PlatformRules.WEB: false}
	assert_true(io.http_request().accept_gzip)
