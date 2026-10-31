extends GutTest
## M3 Task 2: the desert's hazards in a world (DesertTraps, host). A cactus pushes a player who walks into
## it (their own game moves them) and never hurts; an arrow slit clicks when a child steps into its lane
## and shoots a moment later, hurting only whoever is still in the lane; a broken slit never shoots.

const FLOOR := 10
const SLIT := Vector3i(5, FLOOR + 1, 0)

var _mode_before: StringName
var _pushes: Array = []
var _cells := {}


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_pushes.clear()
	_cells = {SLIT: BlockIds.ARROW_SLIT}
	Session.knocked_back.connect(_on_push)


func after_each() -> void:
	Session.knocked_back.disconnect(_on_push)
	Game.mode = _mode_before
	Session.survivor_reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _on_push(impulse: Vector3) -> void:
	_pushes.append(impulse)


func _block(p: Vector3i) -> int:
	if _cells.has(p):
		return _cells[p]
	return BlockIds.SAND if p.y < FLOOR else BlockIds.AIR


func _traps() -> DesertTraps:
	var t := DesertTraps.new()
	t.name = "DesertTraps"
	t.block_at = _block
	t.traps_near = func(_pos: Vector3) -> Array: return [{"cell": SLIT, "dir": Vector3i(0, 0, 1)}]
	add_child_autofree(t)
	t.set_process(false)
	t.start_host()
	return t


func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func test_a_cactus_pushes_a_player_away_and_never_hurts() -> void:
	_cells[Vector3i(21, FLOOR, 0)] = BlockIds.CACTUS
	var t := _traps()
	var p := _player(Vector3(20.8, FLOOR, 0.5))
	await get_tree().physics_frame
	t.tick(0.1)
	assert_eq(_pushes.size(), 1)
	assert_lt((_pushes[0] as Vector3).x, 0.0, "away from the cactus")
	assert_eq(p.health.hp, Health.MAX_HP, "never hurt")
	t.tick(0.1)
	assert_eq(_pushes.size(), 1, "a moment before the next push")
	for i in 9:
		t.tick(0.1)
	assert_eq(_pushes.size(), 2, "still leaning on it: pushed again")


func test_an_arrow_slit_clicks_then_hits_a_child_who_stays_in_its_lane() -> void:
	var t := _traps()
	var p := _player(Vector3(5.5, FLOOR, 2.5))
	await get_tree().physics_frame
	t.tick(0.1)
	assert_eq(p.health.hp, Health.MAX_HP, "the click first")
	for i in int(DesertRules.DART_DELAY / 0.1) + 1:
		t.tick(0.1)
	assert_eq(p.health.hp, Health.MAX_HP - DesertRules.DART_DAMAGE, "then the dart")


func test_walking_on_after_the_click_dodges_the_dart() -> void:
	var t := _traps()
	var p := _player(Vector3(5.5, FLOOR, 2.5))
	await get_tree().physics_frame
	t.tick(0.1)
	p.global_position = Vector3(8.5, FLOOR, 2.5)
	await get_tree().physics_frame
	for i in int(DesertRules.DART_DELAY / 0.1) + 2:
		t.tick(0.1)
	assert_eq(p.health.hp, Health.MAX_HP, "past it")


func test_a_broken_slit_never_shoots() -> void:
	_cells.erase(SLIT)
	var t := _traps()
	var p := _player(Vector3(5.5, FLOOR, 2.5))
	await get_tree().physics_frame
	for i in 20:
		t.tick(0.1)
	assert_eq(p.health.hp, Health.MAX_HP)


func test_the_traps_never_change_blocks() -> void:
	var src := FileAccess.get_file_as_string("res://world/desert_traps.gd")
	for call in ["set_block", "request_set_block", "set_voxel("]:
		assert_false(src.contains(call), "desert_traps.gd never calls %s" % call)
