extends GutTest
## Owner #110 (VR round 4, idea 7): the music blocks are for everyone. On a phone, the web and a PC a tap on a bar plays
## its note and a tap on a skin its drum (the laser's tap in VR is the same tap), whatever is in the hand, as a good
## medium hit; the bar's letter shows over it; a hold still breaks the block; other blocks are built on as before. Off VR
## no mallet is ever made.

const XYLO := Vector3i(2, 10, 0)
const DRUM := Vector3i(-2, 10, 0)
const ME_AT := Vector3(0.5, 10.0, 3.5)

var world: EditWorld
var me: Player
var interactor: BlockInteractor
var music: MusicDirector
var center: Vector2


## Stands in for the terrain: a dictionary of cells, all loaded (grass under y 10).
class EditWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.GRASS if pos.y < 10 else BlockIds.AIR)

	func set_block(pos: Vector3i, id: int) -> void:
		var old := get_block(pos)
		if old == id:
			return
		cells[pos] = id
		block_changed.emit(pos, old, id)

	func is_editable(_pos: Vector3i) -> bool:
		return true

	func surface_height(_x: int, _z: int) -> int:
		return 9


func before_each() -> void:
	Game.mode = ModeRules.SANDBOX
	world = EditWorld.new()
	add_child_autofree(world)
	world.cells[XYLO] = BlockIds.XYLOPHONE
	world.cells[DRUM] = BlockIds.DRUM
	Session.register_world(world)
	me = load("res://entities/player/player.tscn").instantiate()
	me.name = str(multiplayer.get_unique_id())
	me.world = world
	add_child_autofree(me)
	me.set_physics_process(false)
	me.global_position = ME_AT
	interactor = me.get_node("BlockInteractor")
	me.viewer.free()
	me.rig.process_mode = Node.PROCESS_MODE_DISABLED     # the test aims the camera
	center = interactor.get_viewport().get_visible_rect().size * 0.5
	music = MusicDirector.new()
	music.name = "Music"
	music.world = world
	add_child_autofree(music)
	music.setup_local(me, null)


func after_each() -> void:
	Session.register_world(null)
	Session.survivor_reset()


## Aims the camera from the eye at `point` (world space) and taps the screen's middle.
func _tap(point: Vector3) -> bool:
	me.camera().look_at_from_position(me.eye_position(), point)
	return interactor.place_at_screen(center)


func _top(cell: Vector3i, x: float, z: float = 0.5) -> Vector3:
	return Vector3(cell) + Vector3(x, 1.0, z)


func test_a_tap_on_a_bar_plays_its_note_as_a_medium_hit() -> void:
	watch_signals(Audio)
	assert_true(_tap(_top(XYLO, 4.5 / 8.0)), "the tap was the xylophone's")
	assert_eq(music.played, 1)
	assert_eq(music.last_voice, 4, "the fifth bar: G")
	assert_eq(music.last_cell, XYLO)
	assert_almost_eq(music.last_db, MusicBlockRules.volume_db(4, MusicBlockRules.TAP_SPEED), 0.001, "a medium hit")
	assert_signal_emitted_with_parameters(Audio, "sound_played", [MusicDirector.SOUND, Vector3(XYLO) +
		Vector3(0.5, 1.0, 0.5), music.last_db])
	assert_eq(world.cells.size(), 2, "nothing was built on it")


func test_the_west_end_is_low_c_and_the_east_end_high_c() -> void:
	_tap(_top(XYLO, 0.05))
	assert_eq(music.last_voice, 0, "low C")
	_tap(_top(XYLO, 0.95))
	assert_eq(music.last_voice, 7, "high C")
	_tap(_top(XYLO, 0.3, 0.05))
	assert_eq(music.last_voice, 2, "x alone picks the bar: E")


func test_the_bars_letter_shows_over_it() -> void:
	_tap(_top(XYLO, 4.5 / 8.0))
	assert_true(music.letter.visible)
	assert_eq(music.letter.text, "G")
	assert_gt(music.letter.global_position.y, float(XYLO.y) + 1.0, "over the bar")
	music.step(MusicDirector.LETTER_SECONDS + 0.1)
	assert_false(music.letter.visible, "then it goes")


func test_a_tap_on_the_drums_plays_the_skin_under_it_or_the_shell() -> void:
	_tap(_top(DRUM, 0.25))
	assert_eq(music.last_voice, MusicBlockRules.BONGO_LOW, "the big skin")
	_tap(_top(DRUM, 0.8))
	assert_eq(music.last_voice, MusicBlockRules.BONGO_HIGH, "the small skin")
	_tap(Vector3(DRUM) + Vector3(0.5, 0.4, 1.0))
	assert_eq(music.last_voice, MusicBlockRules.SHELL, "the side: the wooden shell")
	assert_eq(music.played, 3)


func test_whatever_is_in_the_hand_a_tap_plays_and_a_hold_still_breaks() -> void:
	for item: int in [BlockIds.PLANKS, ItemIds.SWORD, ItemIds.WAND, BlockIds.XYLOPHONE]:
		interactor.hotbar[0] = item
		interactor.select_slot(0)
		assert_true(_tap(_top(XYLO, 0.6)), ItemIds.display_name(item))
	assert_eq(music.played, 4)
	assert_eq(world.cells.size(), 2, "nothing was placed against it")
	me.camera().look_at_from_position(me.eye_position(), _top(XYLO, 0.6))
	assert_true(interactor.break_at_screen(center), "a hold breaks it")
	assert_eq(world.get_block(XYLO), BlockIds.AIR)


func test_other_blocks_are_built_on_as_before() -> void:
	interactor.hotbar[0] = BlockIds.PLANKS
	interactor.select_slot(0)
	assert_true(_tap(Vector3(0.5, 10.0, 1.5)), "the grass in front")
	assert_eq(music.played, 0, "no note")
	assert_eq(world.cells.values().count(BlockIds.PLANKS), 1, "a plank placed as always")


func test_off_vr_no_mallet_is_ever_made() -> void:
	me.global_position = Vector3(2.5, 10.0, 1.5)   # right by the xylophone
	music.step(1.0)
	assert_false(Vr.active())
	assert_eq(music.mallets.size(), 0, "a phone has no mallets")
	assert_eq(music.find_children("*", "VrGrabbable", true, false).size(), 0)


## The lead (VR-SOUND's ruling S1): the music's tap has its own hook in BlockInteractor, so the cars' director setting
## its tap after the music's (any order at the sandbox's start) never takes the music's taps away.
func test_a_car_tap_set_after_the_music_never_takes_the_music_taps_away() -> void:
	var car_taps := []
	interactor.vehicle_tap = func(_p: Vector2) -> bool:
		car_taps.append(1)
		return false
	assert_true(_tap(_top(XYLO, 4.5 / 8.0)), "the tap still plays the xylophone")
	assert_eq(music.played, 1)
	assert_eq(car_taps.size(), 0, "the music's tap comes first")
	assert_true(interactor.music_tap.is_valid(), "its own hook")
