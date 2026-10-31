extends GutTest
## Owner #133, #134 (the leaf's B2 brief; docs/devlog/parts/game-leaf-b.md B2.1): every caller opens a deep game's own
## host through the registry (PlaySignature): the School's PLAY, Hoot's pick, a discovery crystal and an Academy door.
## A unit naming none still opens G0's PlayHost; an unknown game falls back to it, never a crash. The game's end is
## recorded exactly as a PlayHost round's (MasteryRules, the unit's gold once, SkillShown), and an outcome's `then`
## opens the unit again with the game's next params (the leaf's "again" and its voyage board). Back stays the game's.

class Meadow:
	func block(p: Vector3i) -> int:
		return BlockIds.GRASS if p.y < 70 else BlockIds.AIR


const HOST := "res://tests/integration/play_signature_host.gd"
const UNIT := "g5.science.plants_air_water"
const DAY := 20380
## A unit naming the stand-in game (in memory: Curriculum.put_content), with challenges G0 could play too.
const CONTENT := {"id": UNIT, "lesson": [{"text": "Plants make food from air and water."},
		{"text": "Try it in the world: plant a seed by a window."}],
	"exercises": [
		{"type": "number", "prompt": "3 + 4 = ?", "answer": "7", "hint": "Count on.", "level": 1},
		{"type": "number", "prompt": "5 + 4 = ?", "answer": "9", "hint": "Count on.", "level": 1},
		{"type": "number", "prompt": "6 + 2 = ?", "answer": "8", "hint": "Count on.", "level": 2},
		{"type": "number", "prompt": "7 + 2 = ?", "answer": "9", "hint": "Count on.", "level": 2}],
	"play": {"game": "stand_in", "params": {"voyage": "5.T1"}}}

var _saved := {}
var profile: ProfileData
var saves := 0
var screen: SchoolScreen
var layer: CanvasLayer
var ui: Control
var world: Node3D
var meadow := Meadow.new()
var feet := Vector3(0.5, 70.0, 0.5)
var held: Array = []
var log: DiscoveryLog
var menu: Node


func before_each() -> void:
	_saved = PlayMechanics.data().duplicate(true)
	PlayMechanics.data().signature = {"stand_in": {"name": "Stand-in Game", "host": HOST}}
	Profile.data.settings.reduce_motion = true
	ParentGate.reset_tries()
	Curriculum.clear_cache()
	Curriculum.put_content(UNIT, CONTENT)
	profile = ProfileData.new()
	profile.school.grade = 5
	saves = 0
	held = []
	feet = Vector3(0.5, 70.0, 0.5)


func after_each() -> void:
	for h in get_tree().get_nodes_in_group(PlayHost.GROUP):
		if h is PlayHost and not (h as PlayHost).closed:
			(h as PlayHost).close()
	PlayMechanics._data = _saved
	Curriculum.clear_cache()
	Profile.data.settings.reduce_motion = false
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _school() -> SchoolScreen:
	layer = CanvasLayer.new()
	add_child_autofree(layer)
	screen = SchoolScreen.new()
	screen.profile = profile
	screen.save_profile = func() -> void: saves += 1
	screen.today = func() -> int: return DAY
	screen.next_seed = func() -> int: return 7
	screen.quests_path = "user://test_play_signature_quests_%d.json" % OS.get_process_id()
	layer.add_child(screen)
	await wait_process_frames(2)
	return screen


func _is_stand_in(h: Variant) -> bool:
	return h is PlayHost and is_instance_valid(h) and (h as PlayHost).get_script().resource_path == HOST


# --- The School's PLAY ------------------------------------------------------------------------------------------------

func test_play_on_the_school_page_opens_the_units_deep_game() -> void:
	await _school()
	screen.show_play(UNIT)
	await wait_process_frames(2)
	assert_true(_is_stand_in(screen.play_host), "the deep game's own host")
	assert_eq(screen.play_host.get("params").get("voyage"), "5.T1", "its params from the unit's play block")
	assert_false(layer.visible, "the game shows instead of the School")


func test_the_deep_games_end_counts_like_a_round_with_the_gold_once() -> void:
	var gold := profile.survivor_gold
	await _school()
	screen.show_play(UNIT)
	await wait_process_frames(2)
	screen.play_host.call("finish_now", 5, 6)
	await wait_process_frames(2)
	assert_eq(screen.page, SchoolScreen.ROUND_END)
	assert_eq(MasteryRules.stars(profile.school.progress(UNIT)), 2, "5 of 6 right first time: mastered")
	assert_eq(profile.survivor_gold, gold + MasteryRules.UNIT_GOLD, "the unit's gold")
	assert_gt(saves, 0)
	assert_true(layer.visible, "the School is back")


func test_then_opens_the_unit_again_with_the_games_next_params() -> void:
	await _school()
	screen.show_play(UNIT)
	await wait_process_frames(2)
	var first := screen.play_host
	first.call("finish_now", 6, 6, {"voyage": "5.1"})
	await wait_process_frames(3)
	assert_true(_is_stand_in(screen.play_host) and screen.play_host != first, "opened again")
	assert_eq(screen.play_host.get("params").get("voyage"), "5.1", "with the game's next params")
	assert_eq(MasteryRules.stars(profile.school.progress(UNIT)), 2, "the first one was recorded")


func test_a_unit_naming_no_deep_game_opens_playhost_as_today() -> void:
	var plain := CONTENT.duplicate(true)
	plain.erase("play")
	Curriculum.put_content(UNIT, plain)
	await _school()
	screen.show_play(UNIT)
	await wait_process_frames(2)
	assert_eq(screen.play_host.get_script(), PlayHost)


func test_an_unknown_game_falls_back_to_playhost_never_a_crash() -> void:
	var unknown := CONTENT.duplicate(true)
	unknown.play.game = "no_such_game"
	Curriculum.put_content(UNIT, unknown)
	await _school()
	screen.show_play(UNIT)
	await wait_process_frames(2)
	assert_eq(screen.play_host.get_script(), PlayHost, "G0's place plays what it can")


# --- DISCOVER in the world: Hoot's pick, a crystal, an Academy door ----------------------------------------------------

func _director() -> DiscoveryDirector:
	layer = CanvasLayer.new()
	add_child_autofree(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)
	world = Node3D.new()
	add_child_autofree(world)
	log = DiscoveryLog.new("")
	log.state = DiscoveryRules.after_hoot({}, "sandbox_1:7", DAY)
	var d := DiscoveryDirector.new()
	d.profile = profile
	d.save_profile = func() -> void: saves += 1
	d.today = func() -> int: return DAY
	d.player_ready = func() -> bool: return true
	d.overlay_open = func() -> bool: return false
	d.take_over = func(on: bool) -> void: held.append(on)
	d.keep_safe = func() -> void: pass
	d.in_vr = func() -> bool: return false
	d.log = log
	d.world_parent = world
	d.block_at = meadow.block
	d.player_feet = func() -> Vector3: return feet
	d.player_yaw = func() -> float: return 0.0
	d.busy = func() -> bool: return false
	d.next_seed = func() -> int: return 5
	d.unit_plays = func(id: String) -> bool: return id == UNIT   # the grade's one unit that plays: the deep game's
	add_child_autofree(d)
	d.setup(ui, "sandbox_1:7", true)
	return d


func test_hoots_pick_opens_the_deep_game() -> void:
	var d := _director()
	d.open_discover()
	await wait_process_frames(2)
	assert_true(_is_stand_in(d.place), "Hoot's pick: the deep game's own host")
	assert_eq(d.place.unit_id, UNIT)
	assert_true(d.place_open())
	d.step(0.1)
	assert_true(held.has(true), "the avatar is held while the child plays")
	assert_false(layer.visible, "the world's HUD hides under the game")


func test_a_crystal_opens_the_deep_game() -> void:
	var d := _director()
	var t := 0.0
	while t < DiscoveryCrystalRules.FIRST_SECONDS + 2.0:
		d.step(0.5)
		t += 0.5
	feet = d.crystal.global_position + Vector3(0.5, 0, 0)
	d.step(0.1)
	await wait_process_frames(2)
	assert_true(_is_stand_in(d.place), "a crystal's choice: the deep game's own host")
	assert_eq(d.place.get("counts"), [DiscoveryDirector.CRYSTAL_ROUND] as Array[int], "told it is a crystal's round")


func test_an_academy_door_opens_the_deep_game() -> void:
	var d := _director()
	var p := AcademyPlacer.new()
	p.search_later = false
	world.add_child(p)
	p.setup(null, {"pos": Vector3i(0, 70, -40), "facing": 0}, func(_x: int, _z: int) -> int: return 70)
	d.academy = p
	feet = d.academy.door_position("science")
	d.step(0.2)
	await wait_process_frames(2)
	assert_true(_is_stand_in(d.place), "the Science door: the deep game's own host")


func test_in_the_world_the_end_records_like_the_school_and_then_opens_again() -> void:
	var d := _director()
	d.open_discover()
	await wait_process_frames(2)
	var first := d.place
	first.call("finish_now", 6, 6, {"voyage": "5.1"})
	await wait_process_frames(3)
	assert_eq(MasteryRules.stars(profile.school.progress(UNIT)), 2, "recorded through SkillShown")
	assert_gt(saves, 0)
	assert_true(_is_stand_in(d.place) and d.place != first, "then: opened again")
	assert_eq(d.place.get("params").get("voyage"), "5.1")


# --- Back belongs to the game ----------------------------------------------------------------------------------------

func test_in_discover_back_and_the_pause_key_belong_to_the_deep_game() -> void:
	var d := _director()
	d.open_discover("science")   # the School over the world, on the subject's map
	var school := d.panel.screen as SchoolScreen
	school.show_play(UNIT)
	await wait_process_frames(2)
	assert_true(_is_stand_in(school.play_host), "the deep game, from inside the world")
	assert_true(d.panel.room_open(), "W1's room_open sees it (a PlayHost)")
	assert_true(d.close_if_open(), "Back belongs to the game ...")
	assert_true(d.panel.is_open(), "... and DISCOVER stays under it")
	assert_false(school.play_host.closed)

func test_back_in_the_menus_school_belongs_to_the_deep_game() -> void:
	menu = load("res://ui/menus/menu.tscn").instantiate()
	menu.set("quit_game", func() -> void: pass)
	add_child_autofree(menu)
	await wait_process_frames(3)
	menu.call("_show_school")
	await wait_process_frames(2)
	var school: SchoolScreen = menu.find_children("*", "SchoolScreen", true, false)[0]
	school.show_play(UNIT)
	await wait_process_frames(2)
	var host := school.play_host
	assert_true(_is_stand_in(host))
	assert_true(PlaySignature.any_open(get_tree()))
	get_tree().root.propagate_notification(NOTIFICATION_WM_GO_BACK_REQUEST)
	await wait_process_frames(2)
	assert_true(is_instance_valid(school) and school.is_inside_tree(), "the menu stayed: Back is the game's")
	assert_false(host.closed, "the game is still open")
