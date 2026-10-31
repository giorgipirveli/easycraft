extends GutTest
## M2 Task 8 (spec §12.6): monsters and defenses, with real bodies. Monsters never open or pass a closed
## door (they never climb onto one or hop over it), and never change it; an open door lets them in.
## Monsters of level 2 or less keep 6 blocks from a lantern (stopping short, or walking away when one is
## closer); level 3 and up ignore lanterns. Solo play: this game is the host.

const FLOOR := 10
const DT := 1.0 / 60.0
const DOOR := Vector3i(5, FLOOR, 0)
const LANTERN := Vector3i(10, FLOOR, 0)

var _cells := {}
var _n := 0
var _mode_before: StringName


## Stands in for the world and counts every change anybody makes to it.
class WatchedWorld:
	extends WorldService
	var cells := {}
	var edits := 0

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.GRASS if pos.y < 10 else BlockIds.AIR)

	func set_block(_pos: Vector3i, _id: int) -> void:
		edits += 1

	func is_editable(_pos: Vector3i) -> bool:
		return true


func before_each() -> void:
	_cells = {}
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR


func after_each() -> void:
	Game.mode = _mode_before


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _block(p: Vector3i) -> int:
	if _cells.has(p):
		return _cells[p]
	return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


## The ground, and a box for every solid cell in _cells (the terrain's collision).
func _build() -> void:
	var body := StaticBody3D.new()
	var ground := CollisionShape3D.new()
	var slab := BoxShape3D.new()
	slab.size = Vector3(80, 1, 80)
	ground.shape = slab
	ground.position = Vector3(0, FLOOR - 0.5, 0)
	body.add_child(ground)
	for p: Vector3i in _cells:
		if BlockIds.is_solid(_cells[p]):
			var shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3.ONE
			shape.shape = box
			shape.position = Vector3(p) + Vector3(0.5, 0.5, 0.5)
			body.add_child(shape)
	add_child_autofree(body)


## A 2-high house from x 5 to 12 and z -4 to 4 with a doorway at DOOR in its west wall (bottom and top).
func _house(bottom: int, top: int) -> void:
	for y in [FLOOR, FLOOR + 1]:
		for z in range(-4, 5):
			_cells[Vector3i(5, y, z)] = BlockIds.PLANKS
			_cells[Vector3i(12, y, z)] = BlockIds.PLANKS
		for x in range(5, 13):
			_cells[Vector3i(x, y, -4)] = BlockIds.PLANKS
			_cells[Vector3i(x, y, 4)] = BlockIds.PLANKS
	_cells[DOOR] = bottom
	_cells[DOOR + Vector3i.UP] = top


func _monster(kind: StringName, level: int, pos: Vector3, block_at: Callable = _block) -> Monster:
	_n += 1
	var m := Monster.new()
	m.setup({"kind": kind, "level": level, "id": "md%d" % _n, "pos": pos, "yaw": 0.0, "wild": true, "universe": 1})
	m.block_at = block_at
	add_child_autofree(m)
	m.set_physics_process(false)          # the test steps it
	return m


func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


## Keeps a monster after the player, whether it sees them or not (a hiding player is still hunted).
func _chase(m: Monster, p: Player) -> void:
	m._target = p
	m.awareness.see(p.global_position)   # the stealth awareness (M2 Task 5): it knows where the player stands


## Steps every monster for `seconds`, each chasing `p` (when given); calls `watch` after every step.
func _run(list: Array[Monster], seconds: float, p: Player = null, watch: Callable = Callable()) -> void:
	for i in int(seconds / DT):
		for m in list:
			if not is_instance_valid(m):
				continue
			if p:
				_chase(m, p)
			m._physics_process(DT)
			if watch.is_valid():
				watch.call(m)


## Every walking kind (M3 Task 3: an ice bat flies over a wall without a roof; a roof keeps it out, tested in
## test_frost_monsters.gd).
func _every_monster(at_x: float) -> Array[Monster]:
	var list: Array[Monster] = []
	for kind in MonsterRules.KINDS:
		if MonsterRules.behaviour(kind) == MonsterRules.FLYER:
			continue
		for level in range(1, 6):
			list.append(_monster(kind, level, Vector3(at_x, FLOOR, 0.5 + (level - 3) * 0.3)))
	return list


# --- Doors ------------------------------------------------------------------------------------------

func test_no_monster_passes_a_closed_doorway_of_two_doors() -> void:
	_house(BlockIds.DOOR, BlockIds.DOOR)
	_build()
	var p := _player(Vector3(8.5, FLOOR, 0.5))
	var list := _every_monster(1.5)
	await get_tree().physics_frame
	var deepest := [0.0]
	_run(list, 12.0, p, func(m: Monster) -> void:   # in the house's span (between its side walls' outer faces, z -4 to 5)
		if m.global_position.z > -4.0 and m.global_position.z < 5.0:
			deepest[0] = maxf(deepest[0], m.global_position.x))
	assert_lte(deepest[0], 5.0, "nobody got into the doorway (a monster walking round the house's outside is no entry)")


## A single closed door with nothing above it in a 2-high wall: a small goblin (under a block tall)
## could hop onto it and through the gap, and a slime could land on it. They never do.
## Every walking kind on its own (all five levels): none climbs or hops onto or over a single closed door. (The Glow
## Caves added two kinds, 2026-10-18: the old all-at-once crowd grew to 55, far past anything the game lets live at once,
## MonsterRules.MAX_TOTAL; a pile of 55 could shove one over. Each kind alone is the stricter guard for every new kind.)
func test_no_monster_climbs_or_hops_over_a_single_closed_door() -> void:
	for kind in MonsterRules.KINDS:
		if MonsterRules.behaviour(kind) == MonsterRules.FLYER:
			continue
		_house(BlockIds.DOOR, BlockIds.AIR)
		_build()
		var p := _player(Vector3(8.5, FLOOR, 0.5))
		var list: Array[Monster] = []
		for level in range(1, 6):
			list.append(_monster(kind, level, Vector3(1.5, FLOOR, 0.5 + (level - 3) * 0.3)))
		await get_tree().physics_frame
		var deepest := [0.0]
		_run(list, 12.0, p, func(m: Monster) -> void: deepest[0] = maxf(deepest[0], m.global_position.x))
		assert_lte(deepest[0], 5.0, "%s: nobody got onto the door (x 5 to 6) or past it" % kind)
		for m in list:
			if is_instance_valid(m):
				m.queue_free()
		p.queue_free()
		await get_tree().process_frame


## The most monsters the game ever has at once (MonsterRules.MAX_TOTAL), the weakest and strongest of every walking kind,
## pressing one single closed door together: none gets past it.
func test_a_crowd_at_the_games_cap_does_not_get_over_a_single_closed_door() -> void:
	_house(BlockIds.DOOR, BlockIds.AIR)
	_build()
	var p := _player(Vector3(8.5, FLOOR, 0.5))
	var list: Array[Monster] = []
	for kind in MonsterRules.KINDS:
		if MonsterRules.behaviour(kind) != MonsterRules.FLYER:
			for level in [1, 5]:
				if list.size() < MonsterRules.MAX_TOTAL:
					list.append(_monster(kind, level, Vector3(1.5, FLOOR, 0.5 + (list.size() % 5 - 2) * 0.3)))
	await get_tree().physics_frame
	var deepest := [0.0]
	_run(list, 12.0, p, func(m: Monster) -> void: deepest[0] = maxf(deepest[0], m.global_position.x))
	assert_lte(deepest[0], 5.0, "%d monsters: nobody got onto the door or past it" % list.size())


## The same crowd with other random choices (other ids), and without the spore puffs: a big yeti, a goblin and a crawler
## got over too through the same gap in the door checks (2026-10-18: the spore puff was the first, not the only one).
func test_crowds_with_other_random_choices_never_get_over_a_single_closed_door() -> void:
	for run: Array in [[75, true], [100, true], [125, true], [250, true], [50, false], [150, false]]:
		_n = int(run[0])
		_cells = {}
		_house(BlockIds.DOOR, BlockIds.AIR)
		_build()
		var p := _player(Vector3(8.5, FLOOR, 0.5))
		var list: Array[Monster] = []
		for kind in MonsterRules.KINDS:
			if MonsterRules.behaviour(kind) == MonsterRules.FLYER or (not run[1] and kind == MonsterRules.SPORE_PUFF):
				continue
			for level in [1, 5]:
				if list.size() < MonsterRules.MAX_TOTAL:
					list.append(_monster(kind, level, Vector3(1.5, FLOOR, 0.5 + (list.size() % 5 - 2) * 0.3)))
		await get_tree().physics_frame
		var deepest := [0.0, ""]
		_run(list, 12.0, p, func(m: Monster) -> void:
			if m.global_position.x > deepest[0]:
				deepest[0] = m.global_position.x
				deepest[1] = "%s L%d" % [m.kind, m.level])
		assert_lte(deepest[0], 5.0, "crowd %s: nobody got over the door (%s)" % [run, deepest[1]])
		for m in list:
			if is_instance_valid(m):
				m.queue_free()
		p.queue_free()
		await get_tree().process_frame


func test_an_open_door_lets_them_in() -> void:
	_house(BlockIds.DOOR_OPEN, BlockIds.DOOR_OPEN)
	_build()
	var p := _player(Vector3(8.5, FLOOR, 0.5))
	var goblin := _monster(MonsterRules.GOBLIN, 3, Vector3(1.5, FLOOR, 0.5))
	await get_tree().physics_frame
	_run([goblin] as Array[Monster], 8.0, p)
	assert_gt(goblin.global_position.x, 6.0, "inside the house")


func test_a_monster_never_changes_a_door() -> void:
	_house(BlockIds.DOOR, BlockIds.AIR)
	_build()
	var w := WatchedWorld.new()
	w.cells = _cells
	autofree(w)
	var before := Session.world
	Session.register_world(w)
	var p := _player(Vector3(8.5, FLOOR, 0.5))
	var list: Array[Monster] = []
	for kind in MonsterRules.KINDS:
		list.append(_monster(kind, 1, Vector3(3.5, FLOOR, 0.5), w.get_block))
	await get_tree().physics_frame
	_run(list, 6.0, p)
	Session.register_world(before)
	assert_eq(w.edits, 0, "no monster ever edits a block")
	assert_eq(w.get_block(DOOR), BlockIds.DOOR, "still closed")
	for path in ["res://entities/monsters/monster.gd", "res://world/monster_director.gd", "res://world/defense_director.gd"]:
		var src := FileAccess.get_file_as_string(path)
		for call in ["request_door", "host_door", "set_block", "request_set_block"]:
			assert_false(src.contains(call), "%s never calls %s" % [path.get_file(), call])


# --- Lanterns -----------------------------------------------------------------------------------------

func _lantern_distance(m: Monster) -> float:
	return (Vector3(LANTERN) + Vector3(0.5, 0.5, 0.5)).distance_to(m.global_position)


func test_weak_monsters_keep_6_blocks_from_a_lantern() -> void:
	_cells[LANTERN] = BlockIds.LANTERN
	_build()
	var p := _player(Vector3(10.5, FLOOR, 1.5))                # right next to the lantern
	var list: Array[Monster] = []
	for i in 2:
		for kind in MonsterRules.KINDS:
			# within sight of the player, whatever the number of kinds (M3 Tasks 3 and 4: two columns of 8, all within 32 of the player)
			list.append(_monster(kind, 1 + i, Vector3(0.5 - 2.0 * (list.size() / 8), FLOOR, 1.5 + 2.5 * ((list.size() % 8) - 3.5))))
	for m in list:
		m.lanterns.assign([LANTERN])
	await get_tree().physics_frame
	var closest := [INF]
	_run(list, 12.0, p, func(m: Monster) -> void: closest[0] = minf(closest[0], _lantern_distance(m)))
	assert_gte(closest[0], DefenseRules.LANTERN_KEEP_AWAY - 0.25, "level 1 and 2 stay about 6 blocks away")
	for m in list:
		if m.kind != MonsterRules.ARCHER:   # M3 Task 14b: an archer keeps 10-20 blocks from a child anyway
			assert_lt(_lantern_distance(m), 9.0, "... but they did come close")


func test_a_weak_monster_near_a_new_lantern_walks_away() -> void:
	_cells[LANTERN] = BlockIds.LANTERN
	_build()
	_player(Vector3(30.5, FLOOR, 20.5))                       # within 32 blocks, so it moves (and out of sight)
	var slime := _monster(MonsterRules.SLIME, 1, Vector3(13.5, FLOOR, 0.5))   # 3 blocks away
	slime.lanterns.assign([LANTERN])
	await get_tree().physics_frame
	_run([slime] as Array[Monster], 8.0)
	assert_gte(_lantern_distance(slime), DefenseRules.LANTERN_KEEP_AWAY)


func test_level_3_and_up_ignore_lanterns() -> void:
	_cells[LANTERN] = BlockIds.LANTERN
	_build()
	var p := _player(Vector3(10.5, FLOOR, 1.5))
	var goblin := _monster(MonsterRules.GOBLIN, 3, Vector3(-3.5, FLOOR, 1.5))
	goblin.lanterns.assign([LANTERN])
	await get_tree().physics_frame
	_run([goblin] as Array[Monster], 10.0, p)
	assert_lt(goblin.global_position.distance_to(p.global_position), 2.0, "right up to the player")


# --- Night spawns stay 8 blocks from lanterns ------------------------------------------------------

## The sandbox's lights_near: one bulk copy of the box round a spot and a byte search (a buffer here).
func _lights_in(cells: Dictionary, pos: Vector3) -> Array[Vector3i]:
	var r := int(MonsterRules.LIGHT_CLEAR)
	var origin := Vector3i(pos.floor()) - Vector3i(r, r, r)
	var buf := VoxelBuffer.new()
	buf.create(2 * r + 1, 2 * r + 1, 2 * r + 1)
	for c: Vector3i in cells:
		var l := c - origin
		if l.x >= 0 and l.y >= 0 and l.z >= 0 and l.x <= 2 * r and l.y <= 2 * r and l.z <= 2 * r:
			buf.set_voxel(cells[c], l.x, l.y, l.z, VoxelBuffer.CHANNEL_TYPE)
	return MonsterDirector.find_blocks(buf, origin, MonsterRules.LIGHT_BLOCKS)


func test_night_monsters_never_appear_within_8_blocks_of_a_lantern() -> void:
	var lanterns := {Vector3i(25, FLOOR, 0): BlockIds.LANTERN, Vector3i(-20, FLOOR, 15): BlockIds.LANTERN}
	var d := MonsterDirector.new()
	d.name = "Monsters"
	d.player_positions = func() -> Array[Vector3]: return [Vector3(0.5, FLOOR, 0.5)] as Array[Vector3]
	d.is_ready = func(_p: Vector3) -> bool: return true
	d.stand_spot = func(x: int, z: int) -> Vector3: return Vector3(x + 0.5, FLOOR, z + 0.5)
	d.lights_near = func(p: Vector3) -> Array[Vector3i]: return _lights_in(lanterns, p)
	d.home_beds = func() -> Array[Vector3i]: return [] as Array[Vector3i]
	d.time_of_day = func() -> float: return DayCycle.MIDNIGHT
	d.enabled = func() -> bool: return true
	d.block_at = _block
	d.rng.seed = 20260926
	add_child_autofree(d)
	var spots: Array[Vector3] = []
	for round in 40:
		d.tick()
		for m in d.monsters():
			spots.append(m.global_position)
			m.free()
	assert_gt(spots.size(), 40, "monsters still come elsewhere")
	for s in spots:
		for l: Vector3i in lanterns:
			assert_gt((Vector3(l) + Vector3(0.5, 0.5, 0.5)).distance_to(s), MonsterRules.LIGHT_CLEAR, "%s near the lantern at %s" % [s, l])
