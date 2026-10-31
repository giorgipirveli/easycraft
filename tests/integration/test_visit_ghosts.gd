extends GutTest
## M4 ghost races in a showcase visit (spec §17.5, research T2): the friend's courses in their showcase work
## there (START, CHECKPOINT, FINISH as in M3 Task 7, timed by the visitor's own game: a visit is its own world)
## and the friend's best run on each waits as a see-through ghost in the friend's look; the race clock shows
## the medal against the ghost's time, under the visit's bar. A visit from this device's copy works offline.

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const VISIT := preload("res://world/visit/visit.tscn")
const AREA_START := Vector3i(1, 0, 1)
const AREA_FINISH := Vector3i(5, 0, 1)

var DIR := "user://test_visit_ghosts_%d/" % OS.get_process_id()
var server: RefCounted
var service: OnlineService
var owner_id := ""
var clock := [0]


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()
	owner_id = server.make_account("dev-mia", "Mia_2")
	server.make_account("dev-me", "Hopper")
	server.befriend(owner_id, server.id_of("Hopper"))
	service = OnlineService.new()
	service.backend = FakeBackend.new(server)
	service.device_id = "dev-me"
	service.profile = ProfileData.new()
	service.profile.username = "Hopper"
	service.profile.age_band = AgeBand.TEEN_PLUS
	service.save_profile = func() -> void: pass
	service.prefs_path = DIR + "me.json"
	service.gift_book = GiftStampBook.new()
	service.gift_book_path = DIR + "gifts.json"
	service.ghost_book = GhostBook.new()
	service.ghost_book_path = DIR + "ghosts.json"
	add_child_autofree(service)
	service.prefs.safe_card_seen = int(Time.get_unix_time_from_system())
	assert_eq(await service.sign_in(), "")
	clock[0] = 0


func after_each() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)
	Audio.stop_all()


## Mia's 8 x 3 x 3 showcase: a stone floor with a course, START at (1, 0, 1), FINISH at (5, 0, 1).
func _area() -> String:
	var b := {}
	for x in 8:
		for z in 3:
			b[Vector3i(x, 0, z)] = BlockIds.STONE
	b[AREA_START] = BlockIds.START
	b[AREA_FINISH] = BlockIds.FINISH
	return BuildCodec.encode(b, Vector3i(8, 3, 3))


## Mia's 4 s run on it, in her look (a crown).
func _mia_ghost() -> RaceGhost:
	var g := RaceGhost.new()
	g.start = AREA_START
	g.finish = AREA_FINISH
	g.ms = 4000
	for i in RaceGhost.sample_count(4000):
		g.points.append((Vector3(4, 0, 0) * i / 20.0 * 10.0).round() / 10.0)
	var look := AvatarLook.new()
	look.hat = &"crown"
	g.look = look.to_code()
	return g


## Mia put her showcase up with her ghost; Hopper visits it (the friends page's VISIT).
func _published() -> Dictionary:
	server.showcases[owner_id] = {"build": _area(), "size": [8, 3, 3], "count": 24, "updated_ms": 1}
	var w := _mia_ghost().to_wire()
	w.ghost_id = "h1_000000000001"
	w.updated_ms = 1
	server.showcase_ghosts[owner_id] = [w]
	var r := await service.showcase_of(owner_id)
	assert_eq(r.text, "")
	return r.showcase


func _visit(showcase: Dictionary) -> VisitWorld:
	var v: VisitWorld = VISIT.instantiate()
	v.showcase = showcase
	v.service = service
	v.leave_to = func() -> void: pass
	add_child_autofree(v)
	await wait_until(func() -> bool: return v.player.is_spawned(), 20.0)
	await wait_physics_frames(2)
	v.courses.now_ms = func() -> int: return clock[0]
	v.courses.set_physics_process(false)   # the test says what the feet touch
	return v


func _touch(v: VisitWorld, t: int, id: int, area_cell: Vector3i, left: bool = false) -> void:
	clock[0] = t
	v.courses.touch_sink.call(id, v.generator.origin + area_cell, left)


func test_the_friends_ghost_waits_on_their_course_in_their_look() -> void:
	var v := await _visit(await _published())
	var start := v.generator.origin + AREA_START
	assert_eq(v.generator.block_at(start), BlockIds.START, "the course stands in the showcase")
	v.races.look_around()
	var r := v.races.runner_at(start)
	assert_not_null(r, "Mia's ghost waits on her START")
	assert_eq(r.global_position, CourseRules.top_of(start))
	assert_eq(r.avatar.look().hat, &"crown")
	assert_eq(r.tag.text, "Mia_2's ghost", "a 13+ visitor sees the name")
	assert_eq(r.find_children("*", "CollisionObject3D", true, false).size(), 0)


func test_racing_the_ghost_in_the_visit_gives_a_medal_against_its_time() -> void:
	var v := await _visit(await _published())
	var r := v.races.runner_at(v.generator.origin + AREA_START)
	_touch(v, 0, BlockIds.START, AREA_START)
	assert_true(v.hud.race_clock.visible, "the race clock: 0:00.0 on START")
	_touch(v, 500, BlockIds.START, AREA_START, true)
	assert_true(r.running, "the ghost goes with the visitor")
	_touch(v, 4000, BlockIds.FINISH, AREA_FINISH)             # 3.5 s against Mia's 4 s
	assert_eq(v.hud.race_clock.medal, CourseRules.GOLD)
	assert_true(v.hud.race_clock.picture.best, "the ghost is beaten: sparkles")
	assert_eq(v.hud._toast_label.text, "You beat Mia_2's ghost!  GOLD!")
	assert_eq(int(service.ghost_book.entry(GhostBook.showcase_key("h1_000000000001")).best), 3500, "kept on the device")


func test_a_touch_counts_only_where_the_block_really_is() -> void:
	var v := await _visit(await _published())
	_touch(v, 0, BlockIds.START, AREA_START + Vector3i(2, 0, 0))
	assert_false(v.courses.is_racing(), "stone, not START")
	_touch(v, 0, BlockIds.START, AREA_START)
	assert_true(v.courses.is_racing())


func test_the_race_clock_and_the_toasts_sit_under_the_visits_bar() -> void:
	var v := await _visit(await _published())
	_touch(v, 0, BlockIds.START, AREA_START)
	await wait_process_frames(2)
	var bar := v.panel.blockers()[0].get_global_rect()
	var clock_rect := v.hud.race_clock.get_global_rect()
	assert_gt(clock_rect.position.y, bar.end.y, "the race clock never covers STICKER, REPORT or LEAVE")
	assert_gt(v.hud._toast_panel.offset_top, clock_rect.end.y - 1.0, "the toasts under the clock")


func test_a_visit_from_this_devices_copy_races_offline() -> void:
	await _published()
	server.down = true
	service.sign_out()
	var kept := service.kept_showcase(owner_id)
	assert_true(kept.offline)
	var v := await _visit(kept)
	var r := v.races.runner_at(v.generator.origin + AREA_START)
	assert_not_null(r, "no server needed")
	_touch(v, 0, BlockIds.START, AREA_START)
	_touch(v, 500, BlockIds.START, AREA_START, true)
	_touch(v, 7000, BlockIds.FINISH, AREA_FINISH)             # 6.5 s against 4 / 5.2 / 6.4
	assert_eq(v.hud.race_clock.medal, CourseRules.NO_MEDAL, "6.5 s: finished, a star")
	assert_eq(v.hud._toast_label.text, "Mia_2's ghost got there first. Race again!")
