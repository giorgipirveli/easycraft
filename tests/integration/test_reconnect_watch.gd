extends GutTest
## Owner #95: the watch signs in again after the internet comes back (the fake server down, then up), waits longer
## after each failure, says "back online" once it did, and tries at once when the browser says it is online again.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")

var DIR := "user://test_reconnect_watch_%d/" % OS.get_process_id()
var server: RefCounted


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


func _service() -> OnlineService:
	server.make_account("dev-r", "Kid_9")
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = "dev-r"
	s.profile = ProfileData.new()
	s.profile.username = "Kid_9"
	s.profile.age_band = AgeBand.TEEN_PLUS
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + "dev-r.json"
	add_child_autofree(s)
	s.prefs.safe_card_seen = 1
	return s


func _watch(s: OnlineService) -> ReconnectWatch:
	var w := ReconnectWatch.new()
	w.service = s
	w.wanted = func() -> bool: return true
	w.auto_tick = false
	add_child_autofree(w)
	return w


func test_it_signs_in_again_when_the_internet_is_back_and_says_so() -> void:
	var s := _service()
	server.set("down", true)
	assert_ne(await s.sign_in(), "", "the first try fails: no internet")
	var w := _watch(s)
	var back := [0]
	w.back_online.connect(func() -> void: back[0] += 1)
	await w.tick(0.0)
	assert_eq(s.status, OnlineService.OFFLINE, "still down")
	assert_eq(w.tries, 1)
	await w.tick(10.0)
	assert_eq(w.tries, 1, "waits 20 s after the first failure")
	server.set("down", false)
	await w.tick(21.0)
	assert_eq(s.status, OnlineService.ONLINE, "signed in again by itself")
	assert_eq(back[0], 1, "said once: back online")
	assert_eq(w.tries, 0)


func test_the_waits_grow_and_the_browser_s_online_event_tries_at_once() -> void:
	var s := _service()
	server.set("down", true)
	await s.sign_in()
	var w := _watch(s)
	var online := [false]
	w.online_hint = func() -> bool: return online[0]
	await w.tick(0.0)
	assert_eq(w.tries, 0, "the browser says offline: no try")
	online[0] = true
	await w.tick(1.0)
	assert_eq(w.tries, 1)
	await w.tick(22.0)
	assert_eq(w.tries, 2)
	await w.tick(50.0)
	assert_eq(w.tries, 2, "40 s after the second")
	await w.tick(63.0)
	assert_eq(w.tries, 3)
	online[0] = false
	await w.tick(64.0)
	online[0] = true
	server.set("down", false)
	await w.tick(65.0)
	assert_eq(s.status, OnlineService.ONLINE, "back online in the browser: tried at once")


func test_a_device_never_online_before_never_tries() -> void:
	var s := _service()
	server.set("down", true)
	await s.sign_in()
	var w := _watch(s)
	w.wanted = func() -> bool: return false
	await w.tick(0.0)
	await w.tick(100.0)
	assert_eq(w.tries, 0)


## The menu's own sign-in failed (offline at the start); the watch's first try works: that was an offline spell too.
func test_offline_at_the_start_then_online_says_back_online() -> void:
	var s := _service()
	server.set("down", true)
	await s.sign_in()
	server.set("down", false)
	var w := _watch(s)
	var back := [0]
	w.back_online.connect(func() -> void: back[0] += 1)
	await w.tick(0.0)
	assert_eq(s.status, OnlineService.ONLINE)
	assert_eq(back[0], 1)
	await w.tick(100.0)
	assert_eq(back[0], 1, "once")
