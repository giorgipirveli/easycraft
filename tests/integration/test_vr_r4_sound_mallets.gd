extends GutTest
## Owner #110 (VR round 4, idea 7) with fake hands (Vr.simulate): in VR, near a music block two mallets float over it,
## VrGrabbables of kind &"tool" (VR-HANDS' grabber takes them; until it lands the test sets `holder` and emits the
## signals the grabber will). A held mallet's tip coming down into a bar plays that bar's note, louder the faster it
## came, with a short buzz in that hand at the note's own frequency; a mallet laid on it plays nothing; it must lift off
## before it strikes again; the trigger plays the bar under the tip (no big arm motion needed). Let go, a mallet floats
## back; far from every music block, or out of VR, they go.

const XYLO := Vector3i(2, 10, 0)
const DRUM := Vector3i(4, 10, 0)
const FRAME := 1.0 / 72.0

var world: EditWorld
var music: MusicDirector
var stand: Node3D
var feet := Vector3(3.0, 10.0, 1.6)


class EditWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.GRASS if pos.y < 10 else BlockIds.AIR)


func before_each() -> void:
	feet = Vector3(3.0, 10.0, 1.6)
	world = EditWorld.new()
	add_child_autofree(world)
	world.cells[XYLO] = BlockIds.XYLOPHONE
	world.cells[DRUM] = BlockIds.DRUM
	stand = Node3D.new()
	add_child_autofree(stand)
	stand.global_position = feet
	Vr.simulate(true)
	Vr.anchor(stand, &"feet")
	music = MusicDirector.new()
	music.name = "Music"
	music.world = world
	music.local_feet = func() -> Vector3: return feet
	add_child_autofree(music)
	music.set_process(false)
	music.step(MusicDirector.SCAN_EVERY)


func after_each() -> void:
	Vr.simulate(false)
	Vr.anchor(null)


## Takes mallet `i` in `side` (what VR-HANDS' grabber will do: `holder`, then `grabbed`).
func _take(i: int, side: StringName) -> MusicDirector.Mallet:
	var m := music.mallets[i]
	m.grabbable.holder = side
	m.grabbable.grabbed.emit(side)
	return m


## Moves `side`'s fake hand so the mallet it holds has its tip at `tip` (world space), then a frame.
func _tip_to(m: MusicDirector.Mallet, side: StringName, tip: Vector3, frame: float = FRAME) -> void:
	var grip_to_tip: Vector3 = m.grabbable.hold_offset * MusicDirector.Mallet.TIP
	var hand := Transform3D(Basis(), tip - grip_to_tip)
	Vr.sim_hand(side, Vr.rig.global_transform.affine_inverse() * hand)
	music.step(frame)


## A point over the top of `cell` at (x, z), `up` metres above it.
func _over(cell: Vector3i, x: float, up: float, z: float = 0.5) -> Vector3:
	return Vector3(cell) + Vector3(x, 1.0 + up, z)


func test_near_a_music_block_two_mallets_float_over_it_in_vr() -> void:
	assert_eq(music.mallets.size(), 2)
	for m in music.mallets:
		var g := m.get_node("Grabbable") as VrGrabbable
		assert_eq(g, m.grabbable)
		assert_eq(g.kind, &"tool", "a tool: held and used")
		assert_false(g.throwable, "a mallet is never thrown")
		assert_true(g.far_pull, "the laser pulls it to the hand")
		assert_eq(g.held_by(), &"")
		var top := Vector3(music.near_cell) + Vector3(0.5, 1.0, 0.5)
		assert_lt(m.global_position.distance_to(top), 0.8, "over the music block")
		assert_gt(m.global_position.y, top.y, "above its top")
		assert_lt(m.tip().distance_to(top), m.global_position.distance_to(top), "its head over it, the grip nearer the child")


func test_a_mallet_hits_a_bar_and_the_right_note_plays_with_a_buzz_at_its_frequency() -> void:
	var m := _take(0, &"right")
	var buzzes := Vr.haptics
	_tip_to(m, &"right", _over(XYLO, 4.5 / 8.0, 0.1))
	assert_eq(music.played, 0, "over it: nothing yet")
	_tip_to(m, &"right", _over(XYLO, 4.5 / 8.0, -0.01))
	assert_eq(music.played, 1, "the tip came down into the bar")
	assert_eq(music.last_voice, 4, "G")
	assert_eq(music.last_cell, XYLO)
	assert_eq(Vr.haptics, buzzes + 1, "a buzz in the hand")
	assert_almost_eq(float(music.last_haptic[2]), MusicBlockRules.frequency(4) / 4.0, 0.01, "at G's own frequency")
	assert_eq(music.letter.text, "G")


func test_a_harder_hit_is_louder_and_a_mallet_laid_on_it_plays_nothing() -> void:
	var m := _take(0, &"right")
	var x := 1.5 / 8.0
	var y := 0.06
	while y > -0.02:   # 2 mm a frame: 0.14 m/s, a mallet laid down from 6 cm over it
		_tip_to(m, &"right", _over(XYLO, x, y))
		y -= 0.002
	assert_eq(music.played, 0, "laid on it: no note")
	_tip_to(m, &"right", _over(XYLO, x, 0.2))
	music.step(0.2)
	_tip_to(m, &"right", _over(XYLO, x, 0.02))
	_tip_to(m, &"right", _over(XYLO, x, -0.005))   # 2.5 cm in a frame: 1.8 m/s
	assert_eq(music.played, 1)
	var soft := music.last_db
	_tip_to(m, &"right", _over(XYLO, x, 0.25))
	music.step(0.2)
	_tip_to(m, &"right", _over(XYLO, x, 0.06))
	_tip_to(m, &"right", _over(XYLO, x, -0.005))   # 6.5 cm in a frame: 4.7 m/s
	assert_eq(music.played, 2)
	assert_gt(music.last_db, soft, "harder is louder")
	assert_eq(music.last_voice, 1, "D both times")


func test_a_mallet_lifts_off_before_it_strikes_again() -> void:
	var m := _take(1, &"right")
	_tip_to(m, &"right", _over(XYLO, 0.1, 0.1))
	_tip_to(m, &"right", _over(XYLO, 0.1, -0.01))
	assert_eq(music.played, 1)
	_tip_to(m, &"right", _over(XYLO, 0.1, 0.03))   # bounced up a little, still close
	_tip_to(m, &"right", _over(XYLO, 0.1, -0.01))
	assert_eq(music.played, 1, "a bounce on the bar is one note")
	_tip_to(m, &"right", _over(XYLO, 0.1, 0.12))
	music.step(0.1)
	_tip_to(m, &"right", _over(XYLO, 0.1, -0.01))
	assert_eq(music.played, 2, "lifted off: it strikes again")


func test_the_left_mallet_on_the_bongos() -> void:
	var m := _take(1, &"left")
	_tip_to(m, &"left", _over(DRUM, 0.25, 0.1))
	_tip_to(m, &"left", _over(DRUM, 0.25, -0.01))
	assert_eq(music.last_voice, MusicBlockRules.BONGO_LOW, "the big skin")
	_tip_to(m, &"left", _over(DRUM, 0.8, 0.12))
	music.step(0.1)
	_tip_to(m, &"left", _over(DRUM, 0.8, -0.01))
	assert_eq(music.last_voice, MusicBlockRules.BONGO_HIGH, "the small skin")
	assert_lt(float(MusicBlockRules.haptic(MusicBlockRules.BONGO_LOW, 1.0)[2]), float(music.last_haptic[2]))


func test_the_trigger_plays_the_bar_under_the_tip() -> void:
	var m := _take(0, &"right")
	_tip_to(m, &"right", _over(XYLO, 2.5 / 8.0, 0.05))
	m.grabbable.used.emit(&"right", 1.0)
	assert_eq(music.played, 1)
	assert_eq(music.last_voice, 2, "E, under the tip")
	m.grabbable.used.emit(&"right", 1.0)
	assert_eq(music.played, 1, "held down: once")
	m.grabbable.used.emit(&"right", 0.0)
	m.grabbable.used.emit(&"right", 0.8)
	assert_eq(music.played, 2, "squeezed again: again")
	_tip_to(m, &"right", _over(XYLO, 2.5 / 8.0, 0.5))
	m.grabbable.used.emit(&"right", 0.0)
	m.grabbable.used.emit(&"right", 1.0)
	assert_eq(music.played, 2, "too high over it: nothing")


func test_let_go_a_mallet_floats_back_to_its_rest() -> void:
	var m := _take(0, &"right")
	_tip_to(m, &"right", _over(XYLO, 0.5, 0.4))
	assert_gt(m.global_transform.origin.distance_to(m.rest.origin), 0.05, "in the hand")
	m.grabbable.holder = &""
	m.grabbable.released.emit(&"right", Vector3.ZERO)
	music.step(FRAME)
	assert_almost_eq(m.global_transform.origin.distance_to(m.rest.origin), 0.0, 0.001, "back at its rest")


func test_far_from_every_music_block_or_out_of_vr_they_go() -> void:
	feet = Vector3(3.0, 10.0, 1.6 + MusicDirector.MALLETS_GO + 2.0)
	music.step(MusicDirector.SCAN_EVERY)
	assert_eq(music.mallets.size(), 0, "walked off")
	feet = Vector3(3.0, 10.0, 1.6)
	music.step(MusicDirector.SCAN_EVERY)
	assert_eq(music.mallets.size(), 2, "back again")
	Vr.simulate(false)
	assert_eq(music.mallets.size(), 0, "out of VR")
