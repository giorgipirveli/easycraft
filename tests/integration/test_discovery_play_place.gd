extends GutTest
## Owner #132 (W1) on Play G0's foundation (owner #133, #134). DISCOVER's School over the world knows G0's play place:
## while a child plays from inside the world, Android Back and the pause key belong to the place, closing DISCOVER stops it
## calmly, and the world's HUD layer hides under it. A discovery crystal opens G0's short round (PlayHost, a few
## challenges that play without reading) on the child's own unit (a review due, else the next unit), else on a unit of
## the grade that plays (the unit the child was on kept as play debt); its end records through SkillShown as the School
## does; STOP FOR NOW ends it quietly. Only where nothing in the grade plays does the crystal fall back to its own number
## play in the world. The Academy's subject doors open a whole round of the subject's playable unit, else "coming soon".

class Meadow:
	func block(p: Vector3i) -> int:
		return BlockIds.GRASS if p.y < 70 else BlockIds.AIR


const DAY := 20380

var layer: CanvasLayer
var ui: Control
var world: Node3D
var meadow := Meadow.new()
var profile: ProfileData
var feet := Vector3(0.5, 70.0, 0.5)
var held: Array = []
var safe := 0
var saves := 0
var log: DiscoveryLog


func before_each() -> void:
	Profile.data.settings.reduce_motion = true
	layer = CanvasLayer.new()
	add_child_autofree(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)
	world = Node3D.new()
	add_child_autofree(world)
	profile = ProfileData.new()
	profile.school.grade = 4
	profile.survivor_gold = 0
	feet = Vector3(0.5, 70.0, 0.5)
	held = []
	safe = 0
	saves = 0
	log = DiscoveryLog.new("")
	log.state = DiscoveryRules.after_hoot({}, "sandbox_1:7", DAY)


func after_each() -> void:
	for h in get_tree().get_nodes_in_group(PlayHost.GROUP):
		if h is PlayHost and not (h as PlayHost).closed:
			(h as PlayHost).close()
	Profile.data.settings.reduce_motion = false
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _director() -> DiscoveryDirector:
	var d := DiscoveryDirector.new()
	d.profile = profile
	d.save_profile = func() -> void: saves += 1
	d.today = func() -> int: return DAY
	d.player_ready = func() -> bool: return true
	d.overlay_open = func() -> bool: return false
	d.take_over = func(on: bool) -> void: held.append(on)
	d.keep_safe = func() -> void: safe += 1
	d.in_vr = func() -> bool: return false
	d.log = log
	d.world_parent = world
	d.block_at = meadow.block
	d.player_feet = func() -> Vector3: return feet
	d.player_yaw = func() -> float: return 0.0
	d.busy = func() -> bool: return false
	d.next_seed = func() -> int: return 5
	add_child_autofree(d)
	d.setup(ui, "sandbox_1:7", true)
	return d


func _with_crystal(d: DiscoveryDirector) -> void:
	var t := 0.0
	while t < DiscoveryCrystalRules.FIRST_SECONDS + 2.0:
		d.step(0.5)
		t += 0.5


func _touch(d: DiscoveryDirector) -> void:
	feet = d.crystal.global_position + Vector3(0.5, 0, 0)
	d.step(0.1)


# --- DISCOVER's School and G0's play place --------------------------------------------------------------------------

func test_back_and_the_pause_key_belong_to_the_play_place() -> void:
	var d := _director()
	d.open_discover("maths")   # the School over the world (DISCOVER with no subject starts Hoot's pick: owner #133)
	var school := d.panel.screen as SchoolScreen
	school.show_play("g4.maths.big_numbers")
	await wait_process_frames(2)
	assert_not_null(school.play_host, "the child plays from inside the world")
	assert_true(d.panel.room_open(), "the place has the screen")
	assert_true(d.close_if_open(), "Back belongs to the place ...")
	assert_true(d.panel.is_open(), "... and DISCOVER stays under it")
	assert_false(layer.visible, "the world's HUD layer hides under the place")


func test_closing_discover_stops_the_play_calmly() -> void:
	var d := _director()
	d.open_discover("maths")
	var school := d.panel.screen as SchoolScreen
	school.show_play("g4.maths.big_numbers")
	await wait_process_frames(2)
	var place := school.play_host
	d.panel.close()
	assert_true(place.closed, "stopped for now: nothing recorded")
	assert_true(layer.visible, "the world's HUD comes back")


# --- A crystal on G0's short round ----------------------------------------------------------------------------------

func test_a_crystal_opens_gos_short_round_on_the_childs_unit() -> void:
	var d := _director()
	_with_crystal(d)
	_touch(d)
	await wait_process_frames(2)
	assert_not_null(d.place, "G0's play place")
	assert_eq(d.place.unit_id, "g4.maths.big_numbers", "the child's next unit (it plays without reading)")
	assert_eq(d.place.loop.challenges.size(), DiscoveryDirector.CRYSTAL_ROUND, "a short round")
	assert_true(d.playing())
	assert_false(layer.visible, "the world's HUD hides under the place")
	d.step(0.1)
	assert_true(held.has(true), "the avatar is held while the child plays")


func test_stop_for_now_ends_the_crystal_quietly() -> void:
	var d := _director()
	_with_crystal(d)
	_touch(d)
	await wait_process_frames(2)
	d.place.stop_for_now()
	assert_false(d.playing())
	assert_null(d.crystal)
	assert_true(layer.visible)
	d.step(0.1)
	assert_eq(held.back(), false, "the avatar is free again")


func test_its_end_records_like_the_school() -> void:
	var unit := "g4.maths.big_numbers"
	profile.school.set_progress(unit, {"s": 2, "d": DAY - 1, "m": DAY - 9, "r": 3})   # a review due
	var d := _director()
	_with_crystal(d)
	_touch(d)
	await wait_process_frames(2)
	assert_eq(d.place.unit_id, unit, "the review comes first")
	var shown := SkillShown.begin()
	for i in DiscoveryDirector.CRYSTAL_ROUND:
		shown.add(unit, SkillShown.SOLVED)
	watch_signals(d)
	d.place.finished.emit({"right_first": DiscoveryDirector.CRYSTAL_ROUND, "total": DiscoveryDirector.CRYSTAL_ROUND,
		"world_task": "", "shown": shown})
	assert_signal_emitted(d, "crystal_finished")
	assert_eq(int(profile.school.progress(unit).get("r", 0)), 4, "a review counted (SkillShown, MasteryRules)")
	assert_gt(saves, 0, "saved")
	assert_eq(int(log.state.crystals.played), 1)
	assert_null(d.crystal, "the crystal went")


func test_a_unit_that_does_not_play_gives_way_to_one_of_the_grade_that_does() -> void:
	var d := _director()
	d.unit_plays = func(id: String) -> bool: return id != "g4.maths.big_numbers" and PlayHost.plays(Curriculum.content(id))
	_with_crystal(d)
	_touch(d)
	await wait_process_frames(2)
	assert_not_null(d.place)
	assert_ne(d.place.unit_id, "g4.maths.big_numbers")
	assert_true(d.place.unit_id.begins_with("g4."), "a unit of the child's grade")
	assert_eq(int((log.state.crystals.debt as Dictionary).get("g4.maths.big_numbers", 0)), 1, "the play debt kept")


func test_only_where_nothing_plays_the_crystal_plays_its_own_numbers() -> void:
	var d := _director()
	d.unit_plays = func(_id: String) -> bool: return false
	_with_crystal(d)
	_touch(d)
	assert_null(d.place)
	assert_not_null(d.challenge, "the crystal's own number play in the world")


# --- The Academy's doors ----------------------------------------------------------------------------------------------

func _academy(d: DiscoveryDirector) -> void:
	var p := AcademyPlacer.new()
	p.search_later = false
	world.add_child(p)
	p.setup(null, {"pos": Vector3i(0, 70, -40), "facing": 0}, func(_x: int, _z: int) -> int: return 70)
	d.academy = p


func test_a_subject_door_opens_a_whole_round_of_its_playable_unit() -> void:
	var d := _director()
	_academy(d)
	feet = d.academy.door_position("maths")
	d.step(0.2)
	await wait_process_frames(2)
	assert_not_null(d.place, "the Maths Workshop: real play")
	assert_true(d.place.unit_id.begins_with("g4.maths."))
	assert_eq(d.place.loop.challenges.size(), MasteryRules.ROUND_SIZE, "a whole round: it can count like the School's")


func test_a_subject_with_nothing_to_play_says_coming_soon() -> void:
	var d := _director()
	_academy(d)
	d.unit_plays = func(id: String) -> bool: return not id.contains(".history.")
	feet = d.academy.door_position("history")
	d.step(0.2)
	assert_null(d.place)
	assert_true(d.academy_card.visible, "a calm coming soon, never a list of lessons")
