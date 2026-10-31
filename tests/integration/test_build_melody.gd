extends GutTest
## M3 Task 21c: building sounds and melody in the game. The local player's placed blocks sing their note
## (BuildNotes) from a small pool of players that never grows, at the scale's exact pitch; a row climbs; the budget
## keeps the mix clear; a LINE or FILL of many blocks is one tool step and sings once, never once per cell; the
## "Block music" setting turns it off (the plain pop plays as before).

const ME_AT := Vector3(0.5, 10.0, 0.5)


## Stands in for the terrain: grass below y = 10, air above, plus `cells`.
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


var _sounds: Array[StringName] = []
var _settings_before: Dictionary
var _clock := [0]


func before_each() -> void:
	_settings_before = Profile.data.settings.duplicate()
	Profile.data.settings["build_notes"] = true
	Audio.stop_all()
	Audio.sound_played.connect(_on_sound)
	_sounds.clear()
	_clock[0] = 10000


func after_each() -> void:
	Audio.sound_played.disconnect(_on_sound)
	Profile.data.settings = _settings_before
	Audio.stop_all()


func after_all() -> void:
	Audio.stop_all()


func _on_sound(sound: StringName, _at: Vector3, _db: float) -> void:
	_sounds.append(sound)


func _melody() -> BuildMelody:
	var m := BuildMelody.new()
	m.now_ms = func() -> int: return _clock[0]
	add_child_autofree(m)
	return m


func _count(sound: StringName) -> int:
	return _sounds.count(sound)


func test_a_placed_block_sings_its_own_note_at_the_exact_pitch() -> void:
	var m := _melody()
	assert_true(m.place(Vector3(0.5, 10.5, 0.5), BlockIds.PLANKS))
	assert_almost_eq(m.last_pitch, BuildNotes.pitch(BuildNotes.base_degree(BlockIds.PLANKS)), 0.0001, "no wobble")
	assert_eq(m.last_voice, BuildNotes.WOOD)
	assert_eq(_count(BuildMelody.SOUND), 1, "reported like every other sound (owner #50's counting tools)")
	assert_eq(_count(&"place"), 0, "the note takes the plain pop's place")
	_clock[0] += 5000
	assert_true(m.place(Vector3(9.5, 10.5, 0.5), BlockIds.GLASS))
	assert_eq(m.last_voice, BuildNotes.BELL, "glass rings")
	assert_almost_eq(m.last_pitch, BuildNotes.pitch(BuildNotes.base_degree(BlockIds.GLASS)), 0.0001)


func test_blocks_in_a_row_play_a_rising_melody() -> void:
	var m := _melody()
	var pitches: Array[float] = []
	for i in 4:
		_clock[0] += 300
		m.place(Vector3(i + 0.5, 10.5, 0.5), BlockIds.STONE)
		pitches.append(m.last_pitch)
	for i in 3:
		assert_gt(pitches[i + 1], pitches[i], "note %d climbs" % (i + 1))


## The pool is made once: however many notes play, never more players, and never more playing than the pool.
func test_the_pool_never_grows() -> void:
	var m := _melody()
	assert_eq(m.player_count(), BuildMelody.POOL)
	for i in 60:
		_clock[0] += 150
		m.place(Vector3(i % 3 + 0.5, 10.5, 0.5), BlockIds.BRICK)
		assert_lte(m.playing_count(), BuildMelody.POOL)
	assert_eq(m.player_count(), BuildMelody.POOL)
	assert_eq(m.played, 60, "a child building fast is heard every time")


## However fast blocks come (a mirror, a stamp, a hold that repeats), at most BuildNotes.PER_SECOND notes a second.
func test_the_budget_keeps_the_mix_clear() -> void:
	var m := _melody()
	for i in 100:
		_clock[0] += 10
		m.place(Vector3(i % 2 + 0.5, 10.5, 0.5), BlockIds.RED)
	assert_lte(m.played, BuildNotes.PER_SECOND)
	assert_eq(m.played + m.skipped, 100)
	assert_lte(_count(BuildMelody.SOUND), BuildNotes.PER_SECOND)


func test_block_music_off_plays_the_plain_pop() -> void:
	Profile.data.settings["build_notes"] = false
	var m := _melody()
	assert_false(m.place(Vector3(0.5, 10.5, 0.5), BlockIds.PLANKS))
	assert_eq(_count(BuildMelody.SOUND), 0)
	assert_eq(_count(&"place"), 1, "as before the wonder pack")
	assert_false(BuildMelody.notes_on())
	Profile.data.settings.erase("build_notes")
	assert_true(BuildMelody.notes_on(), "on unless a grown-up or child turns it off")
	assert_true(ProfileData.DEFAULT_SETTINGS.get("build_notes", false), "on in a new profile")


## A LINE of many blocks is one tool step: one note (the host writes the cells a little every frame).
func test_a_line_sings_once_not_once_per_cell() -> void:
	var mode := Game.mode
	Game.mode = ModeRules.SANDBOX
	Session.tool_reset()
	var world := EditWorld.new()
	add_child_autofree(world)
	Session.register_world(world)
	var me: Player = load("res://entities/player/player.tscn").instantiate()
	me.name = str(multiplayer.get_unique_id())
	me.world = world
	add_child_autofree(me)
	me.set_physics_process(false)
	me.global_position = ME_AT
	me._spawned = true
	var interactor: BlockInteractor = me.get_node("BlockInteractor")
	interactor.set_slot_block(interactor.selected_slot, BlockIds.BRICK)
	interactor.set_slot_block(interactor.selected_slot, ItemIds.LINE_TOOL)
	interactor.tools.tap(ItemIds.LINE_TOOL, Vector3i(2, 10, -2))
	interactor.tools.tap(ItemIds.LINE_TOOL, Vector3i(12, 10, -2))
	for i in 10:
		await wait_physics_frames(1)
	var bricks := 0
	for c: Vector3i in world.cells:
		bricks += int(world.cells[c] == BlockIds.BRICK)
	assert_eq(bricks, 11, "the whole line is built")
	assert_eq(_count(BuildMelody.SOUND), 1, "one note for the tool step")
	assert_eq(_count(&"place"), 0)
	interactor.set_slot_block(interactor.selected_slot, ItemIds.PAINTS[5])
	var painted := interactor.tools.paint(Vector3i(2, 10, -2), interactor.selected_block())
	assert_true(painted)
	assert_eq(_count(BuildMelody.SOUND), 2, "a paint tap sings one note too")
	Session.register_world(null)
	Session.tool_reset()
	Game.mode = mode
