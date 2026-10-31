extends GutTest
## Owner #110 (VR round 4, idea 7): LOOP. Near a music block LOOP shows over the hotbar (the cars' HORN spot); a press
## counts in a bar (4, 3, 2, 1, the metronome ticking), records four bars (REC 1/4 ... 4/4), then plays them again and
## again while the child plays over them; LOOP + adds a layer from the next bar, three at most; STOP clears it. A loop
## stops when its player walks off, and a note whose block was broken is silent.

const XYLO := Vector3i(2, 10, 0)
const DRUM := Vector3i(4, 10, 0)

var world: EditWorld
var music: MusicDirector
var feet := Vector3(3.0, 10.0, 2.0)
var heard: Array = []


class EditWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.GRASS if pos.y < 10 else BlockIds.AIR)

	func set_block(pos: Vector3i, id: int) -> void:
		cells[pos] = id

	func is_editable(_pos: Vector3i) -> bool:
		return true


func before_each() -> void:
	feet = Vector3(3.0, 10.0, 2.0)
	world = EditWorld.new()
	add_child_autofree(world)
	world.cells[XYLO] = BlockIds.XYLOPHONE
	world.cells[DRUM] = BlockIds.DRUM
	music = MusicDirector.new()
	music.name = "Music"
	music.world = world
	music.local_feet = func() -> Vector3: return feet
	add_child_autofree(music)
	music.set_process(false)   # the test steps it
	var ui := Control.new()
	ui.size = Vector2(1280, 720)
	add_child_autofree(ui)
	music.make_buttons(ui)
	heard = []
	music.note_played.connect(func(v: int, _c: Vector3i, _db: float, _from: int) -> void: heard.append(v))


## Steps the director `seconds` in 20 ms frames.
func _run(seconds: float) -> void:
	var t := 0.0
	while t < seconds - 0.0001:
		music.step(0.02)
		t += 0.02


## The time (on the director's clock) of beat `b` of the loop.
func _at(b: float) -> float:
	return music.loop.origin + b * MusicBlockRules.beat_seconds()


func _run_to(b: float) -> void:
	_run(maxf(_at(b) - music.time, 0.0))


func _hit(cell: Vector3i, x: float) -> int:
	return music.strike(cell, Vector3i.UP, Vector3(x, 1.0, 0.5), 1.5)


func test_loop_shows_near_a_music_block_and_stop_only_while_a_loop_runs() -> void:
	feet = Vector3(30.0, 10.0, 30.0)
	_run(0.5)
	assert_false(music.loop_button.visible, "far from every music block")
	feet = Vector3(3.0, 10.0, 2.0)
	_run(0.5)
	assert_true(music.loop_button.visible, "beside the xylophone")
	assert_eq(music.loop_button.text, "LOOP")
	assert_false(music.stop_button.visible)
	assert_eq(HudLayout.rect(&"horn", Vector2(1280, 720)), music.loop_button.get_rect(), "the cars' HORN spot")


func test_a_take_counts_in_records_four_bars_and_plays_them_back_again_and_again() -> void:
	_run(0.5)
	assert_true(music.press_loop())
	var counts: Array = []
	while music.loop.state == MusicBlockRules.Loop.COUNT_IN:
		if counts.is_empty() or counts.back() != music.loop_button.text:
			counts.append(music.loop_button.text)
		music.step(0.02)
	assert_eq(counts, ["4", "3", "2", "1"], "a bar's count-in on the button")
	assert_true(music.stop_button.visible)
	_hit(XYLO, 0.1)            # beat 0: C
	_run_to(2.0)
	_hit(XYLO, 0.6)            # beat 2: G
	_run_to(4.5)
	assert_eq(music.loop_button.text, "REC 2/4", "the second bar")
	assert_true(music.loop_button.selected, "lit while it records")
	_hit(DRUM, 0.3)            # beat 4.5: the low bongo
	_run_to(15.9)
	assert_eq(heard, [0, 4, MusicBlockRules.BONGO_LOW], "the take repeats nothing while it records")
	heard.clear()
	_run_to(31.9)
	assert_eq(heard, [0, 4, MusicBlockRules.BONGO_LOW], "the second time round: every note, in order")
	assert_eq(music.loop_button.text, "LOOP +", "room for another layer")
	heard.clear()
	_run_to(47.9)
	assert_eq(heard, [0, 4, MusicBlockRules.BONGO_LOW], "and again")


func test_the_metronome_ticks_through_the_count_in_and_the_take_only() -> void:
	_run(0.5)
	music.press_loop()
	_run_to(16.0 + 0.1)
	assert_eq(music.metronome_ticks, 20, "four counts and sixteen beats")
	_run_to(31.0)
	assert_eq(music.metronome_ticks, 20, "none while it plays")


func test_three_layers_at_most_and_stop_clears_them() -> void:
	_run(0.5)
	for layer in 3:
		assert_true(music.press_loop(), "layer %d" % (layer + 1))
		_run_to(music.loop.rec_from + 1.0)
		_hit(XYLO, 0.1 + layer * 0.3)
		_run_to(music.loop.rec_from + 16.1)
	assert_eq(music.loop.layers.size(), 3)
	assert_eq(music.loop_button.text, "3 LOOPS")
	assert_false(music.press_loop(), "no fourth")
	music.stop_button.pressed.emit()
	assert_eq(music.loop.state, MusicBlockRules.Loop.IDLE)
	assert_false(music.stop_button.visible)
	heard.clear()
	_run(MusicBlockRules.loop_seconds())
	assert_eq(heard, [], "quiet")


func test_a_loop_stops_when_its_player_walks_off() -> void:
	_run(0.5)
	music.press_loop()
	_run_to(1.0)
	_hit(XYLO, 0.5)
	_run_to(16.5)
	assert_eq(music.loop.state, MusicBlockRules.Loop.PLAYING)
	feet = Vector3(3.0, 10.0, 2.0 + MusicBlockRules.LOOP_RANGE + 5.0)
	_run(1.0)
	assert_eq(music.loop.state, MusicBlockRules.Loop.IDLE, "far away: it stops")


func test_a_note_whose_block_was_broken_is_silent() -> void:
	_run(0.5)
	music.press_loop()
	_run_to(1.0)
	_hit(XYLO, 0.1)
	_run_to(3.0)
	_hit(DRUM, 0.8)
	_run_to(16.5)
	world.cells.erase(DRUM)
	heard.clear()
	_run_to(32.5)
	assert_eq(heard, [0], "the xylophone's note plays, the broken drum's does not")
