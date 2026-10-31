extends GutTest
## Owner #89 (spec §5.12, §14.12): which channel list the Theater plays. The server keeps the owner's list (module
## 0.2.17, theater_channels); a game that is online reads it and keeps the last one on the device; before that, and
## on a device that never goes online, the list bundled with the game. The server's kill-switch is kept too.

const CACHE := "user://test_theater_feed_cache.json"


## Stands in for OnlineService: its status and a backend that answers theater_channels.
class FakeService:
	extends RefCounted
	var status: StringName = OnlineService.ONLINE
	var backend := FakeBackend.new()


class FakeBackend:
	extends RefCounted
	var reply: Dictionary = {"ok": true, "list": null}
	var calls: Array[String] = []

	func call_rpc(id: String, _payload: Dictionary = {}) -> Dictionary:
		calls.append(id)
		return reply


func before_each() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CACHE))


func after_all() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CACHE))


func _server_list(enabled: bool = true, title: String = "Server picks") -> Dictionary:
	return {"version": 1, "enabled": enabled, "source": "server", "updated_ms": 1790000000000, "channels": [
		{"id": "easycraft_tv", "title": title, "platform": "youtube", "icon": "tv",
			"videos": [{"id": "fYa-hmNzlAQ", "title": "Who is Paxi?", "made_for_kids": true}]}]}


func _write_cache(text: String) -> void:
	var f := FileAccess.open(CACHE, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func test_without_a_kept_list_the_bundled_one_plays() -> void:
	var list := TheaterFeed.load_best(CACHE)
	assert_eq(list.source, TheaterChannels.SOURCE_BUNDLED)
	assert_true(list.enabled)
	assert_eq(list.channels[0].id, TheaterChannels.EASYCRAFT_TV)


func test_the_servers_list_is_kept_and_played() -> void:
	var used := TheaterFeed.keep({"ok": true, "list": _server_list()}, CACHE)
	assert_eq(used.source, TheaterChannels.SOURCE_SERVER)
	assert_eq(used.channels[0].title, "Server picks")
	assert_true(FileAccess.file_exists(CACHE), "kept on the device")
	var again := TheaterFeed.load_best(CACHE)
	assert_eq(again.source, TheaterChannels.SOURCE_SERVER, "the next start plays the kept list")
	assert_eq(again.channels[0].title, "Server picks")


func test_the_servers_kill_switch_is_kept_too() -> void:
	var used := TheaterFeed.keep({"ok": true, "list": _server_list(false)}, CACHE)
	assert_false(used.enabled)
	assert_false(TheaterFeed.load_best(CACHE).enabled, "no Theater until the server says otherwise")


func test_no_list_on_the_server_means_the_bundled_one() -> void:
	TheaterFeed.keep({"ok": true, "list": _server_list()}, CACHE)
	var used := TheaterFeed.keep({"ok": true, "list": null}, CACHE)
	assert_eq(used.source, TheaterChannels.SOURCE_BUNDLED, "the owner cleared the server's list")
	assert_false(FileAccess.file_exists(CACHE), "the kept copy goes")
	assert_eq(TheaterFeed.load_best(CACHE).source, TheaterChannels.SOURCE_BUNDLED)


func test_a_failed_answer_changes_nothing() -> void:
	TheaterFeed.keep({"ok": true, "list": _server_list()}, CACHE)
	for reply: Dictionary in [{"ok": false, "error": "network"}, {"ok": true}, {"ok": true, "list": "junk"},
			{"ok": true, "list": {"enabled": true, "source": "sample", "channels": []}}]:
		assert_eq(TheaterFeed.keep(reply, CACHE), {}, "nothing new: %s" % reply)
		assert_eq(TheaterFeed.load_best(CACHE).channels[0].title, "Server picks", "the kept list stays: %s" % reply)


func test_a_broken_or_foreign_kept_file_is_ignored() -> void:
	for text: String in ["{", "[]", JSON.stringify({"enabled": true, "source": "sample", "channels": []}),
			JSON.stringify({"enabled": false, "source": "bundled", "channels": []})]:
		_write_cache(text)
		var list := TheaterFeed.load_best(CACHE)
		assert_eq(list.source, TheaterChannels.SOURCE_BUNDLED, "only a server's list replaces the bundled one: %s" % text)
		assert_true(list.enabled)


func test_an_online_game_asks_the_server() -> void:
	var s := FakeService.new()
	s.backend.reply = {"ok": true, "list": _server_list(true, "Fresh")}
	var used: Dictionary = await TheaterFeed.fetch(s, CACHE)
	assert_eq(s.backend.calls, [TheaterFeed.RPC])
	assert_eq(used.channels[0].title, "Fresh")
	assert_eq(TheaterFeed.load_best(CACHE).channels[0].title, "Fresh")


func test_an_offline_game_does_not_ask() -> void:
	var s := FakeService.new()
	s.status = OnlineService.OFFLINE
	assert_eq(await TheaterFeed.fetch(s, CACHE), {})
	assert_eq(s.backend.calls, [])
	assert_eq(await TheaterFeed.fetch(null, CACHE), {}, "no online service at all")
