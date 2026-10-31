extends GutTest
## Owner #132 (W1), stage 3: the Discovery Academy in a world. The placer stands a saved site at once; on the host a
## found site is checked (a child's build moves it), its trees cleared and the buildings stood, and the save keeps it; a
## world with no room gets the island over the spawn. Walking up to a door says its name (owner #133) and opens it: the
## Maths Workshop a crystal's real play right there (#134), Life the School's Life tab over the world, every other door a
## calm "coming soon" card (Hoot, the door's picture, a spoken line, no words) that walking away closes. The HUD's
## compass points to the Academy until the child has been to a door; MY MAP marks it.

class RecordingVoice:
	extends ReadAloud.Voice
	var said: Array[String] = []

	func has_voice(_language: String) -> bool:
		return true

	func speak(text: String, _language: String) -> void:
		said.append(text)


## A flat world: grass under GROUND, what was written, air above.
class FlatWorld:
	extends Node
	const GROUND := 70
	var cells := {}

	func get_block(p: Vector3i) -> int:
		if cells.has(p):
			return int(cells[p])
		return BlockIds.GRASS if p.y < GROUND else BlockIds.AIR

	func box_reader(_origin: Vector3i, _size: Vector3i) -> Callable:
		return get_block

	func is_editable(_p: Vector3i) -> bool:
		return true

	func set_blocks(changes: Array) -> Array:
		for c: Array in changes:
			cells[c[0]] = int(c[1])
		return []


const DAY := 20380
const SITE := {"pos": Vector3i(0, 70, -40), "facing": 0}

var voice: RecordingVoice
var _old_voice: ReadAloud.Voice
var ui: Control
var world: FlatWorld
var holder: Node3D
var profile: ProfileData
var feet := Vector3.INF
var log: DiscoveryLog


func before_each() -> void:
	_old_voice = ReadAloud.voice
	voice = RecordingVoice.new()
	ReadAloud.voice = voice
	ReadAloud.queue.clear()
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child_autofree(ui)
	world = FlatWorld.new()
	add_child_autofree(world)
	holder = Node3D.new()
	add_child_autofree(holder)
	profile = ProfileData.new()
	profile.school.grade = 4
	feet = Vector3(0.5, 70.0, 0.5)
	log = DiscoveryLog.new("")
	log.state = DiscoveryRules.after_hoot({}, "sandbox_1:7", DAY)


func after_each() -> void:
	ReadAloud.voice = _old_voice
	ReadAloud.queue.clear()
	await wait_process_frames(2)


func after_all() -> void:
	Audio.stop_all()


func _flat(_x: int, _z: int) -> int:
	return FlatWorld.GROUND


func _placer(saved: Dictionary, host := true) -> AcademyPlacer:
	var p := AcademyPlacer.new()
	p.search_later = false
	p.world = world
	p.host = host
	holder.add_child(p)
	p.setup(null, saved, _flat)
	return p


func _director(placer: AcademyPlacer) -> DiscoveryDirector:
	var d := DiscoveryDirector.new()
	d.profile = profile
	d.save_profile = func() -> void: pass
	d.today = func() -> int: return DAY
	d.player_ready = func() -> bool: return true
	d.overlay_open = func() -> bool: return false
	d.take_over = func(_on: bool) -> void: pass
	d.keep_safe = func() -> void: pass
	d.in_vr = func() -> bool: return false
	d.log = log
	d.world_parent = holder
	d.block_at = world.get_block
	d.player_feet = func() -> Vector3: return feet
	d.player_yaw = func() -> float: return 0.0
	d.busy = func() -> bool: return false
	d.next_seed = func() -> int: return 3
	add_child_autofree(d)
	d.setup(ui, "sandbox_1:7", true)
	d.academy = placer
	return d


func _walk_to(d: DiscoveryDirector, door: String) -> void:
	feet = AcademyPlaza.door_position(SITE, door, _flat)
	d.step(0.2)


# --- Placing it ----------------------------------------------------------------------------------------------------

func test_a_saved_academy_stands_at_once() -> void:
	var p := _placer(SITE)
	assert_true(p.stood)
	assert_not_null(p.buildings)
	assert_eq(p.buildings.get_parent(), p)


func test_the_host_checks_clears_stands_and_saves_a_found_site() -> void:
	var p := _placer({})
	watch_signals(p)
	world.cells[Vector3i(0, 70, -40 + 7)] = BlockIds.LOG   # a tree trunk at the Maths gate
	p.place(SITE)
	for i in 5:
		await wait_process_frames(1)
	assert_true(p.stood)
	assert_signal_emitted(p, "placed")
	assert_eq(world.get_block(Vector3i(0, 70, -33)), BlockIds.AIR, "the tree in the gate's way was cleared")


func test_a_childs_build_moves_it() -> void:
	var p := _placer({})
	world.cells[Vector3i(1, 71, -40)] = BlockIds.BRICK   # a child built where the tower would stand
	p.place(SITE)
	for i in 5:
		await wait_process_frames(1)
	assert_false(p.stood, "never on a child's build")
	assert_true(p.rejected.has(Vector2i(0, -40)))


func test_a_guest_stands_it_at_once() -> void:
	var p := _placer({}, false)
	p.place(SITE)
	assert_true(p.stood, "the host checks and clears; a guest stands it from the seed")


func test_the_island_stands_over_the_spawn() -> void:
	var p := _placer(AcademyPlaza.island(Vector2i(3, 4), 70))
	assert_true(p.stood)
	assert_true(p.buildings.island)
	assert_eq(p.buildings.position.y, float(70 + AcademyPlaza.ISLAND_UP))


func test_the_academy_draws_little() -> void:
	var p := _placer(SITE)
	var meshes := p.buildings.find_children("*", "MeshInstance3D", true, false)
	assert_lte(meshes.size(), 4, "merged per material: the stone, the glow, Hoot")
	assert_eq(p.buildings.find_children("*", "Label3D", true, false).size(), 0, "no words: pictures (owner #133)")
	assert_eq(p.buildings.find_children("*", "OmniLight3D", true, false).size(), 0, "it glows without a light")


# --- Its doors -----------------------------------------------------------------------------------------------------

func test_walking_up_to_a_door_says_its_name() -> void:
	var d := _director(_placer(SITE))
	for door: String in ["science", "maths", "life"]:
		voice.said.clear()
		feet = Vector3(0.5, 70.0, 0.5)
		d.step(0.2)   # away first: a door opens again only after walking away
		_walk_to(d, door)
		var door_name := str(AcademyPlaza.SPOTS[door].name)
		assert_true(voice.said.any(func(l: String) -> bool: return l.begins_with(door_name)), "%s: its name is said" % door)
		d.panel.close()
		if d.place_open():
			d.place.stop_for_now()


func test_a_door_with_no_game_yet_shows_a_calm_coming_soon() -> void:
	var d := _director(_placer(SITE))
	d.unit_plays = func(id: String) -> bool: return not id.contains(".history.")   # nothing of history plays yet
	_walk_to(d, "history")
	assert_true(d.academy_card.visible)
	assert_eq(d.academy_card.door, "history")
	assert_lte(DiscoveryRules.word_count(ReadAloud.words_of(d.academy_card)), DiscoveryRules.MAX_SCREEN_WORDS)
	assert_true(voice.said.has(d.academy_card.line()), "and spoken")
	feet = Vector3(0.5, 70.0, 0.5)
	d.step(0.2)
	assert_false(d.academy_card.visible, "walking away closes it")


func test_the_maths_door_starts_its_real_play() -> void:
	var d := _director(_placer(SITE))
	_walk_to(d, "maths")
	assert_true(d.place_open(), "a whole round of the child's maths in Play G0's place")
	assert_true(d.place.unit_id.begins_with("g4.maths."))
	d.place.stop_for_now()


func test_the_life_door_opens_life() -> void:
	var d := _director(_placer(SITE))
	_walk_to(d, "life")
	assert_true(d.panel.is_open())
	assert_eq(d.panel.subject, DiscoverPanel.LIFE)


func test_the_compass_points_to_it_until_the_child_has_been_in() -> void:
	var d := _director(_placer(SITE))
	var t := d.compass_target(feet)
	assert_false(t.is_empty(), "the HUD's compass points to the Academy")
	_walk_to(d, "music")
	assert_true(d.compass_target(feet).is_empty(), "been in: the compass is the world's again")
	var again := _director(_placer(SITE))
	assert_true(again.compass_target(feet).is_empty(), "remembered on the device for this world")


func test_the_island_has_no_doors_to_walk_up_to() -> void:
	var p := _placer(AcademyPlaza.island(Vector2i(0, 0), 70))
	var d := _director(p)
	feet = Vector3(0.5, 70.0, 0.5)
	d.step(0.2)
	assert_false(d.academy_card.visible)
	assert_true(d.compass_target(feet).is_empty(), "nothing to walk to")
