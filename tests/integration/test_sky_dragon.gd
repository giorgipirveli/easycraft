extends GutTest
## Owner feedback #39 (spec §14.2a): the Sky Dragon as an entity, on a floor (the arena's flat ground is y 32), and
## through the BossDirector. It is a StoneGolem to the director (fight, bar, honest help, gold, win and loss); it
## flies: arrives, circles high over the arena, then picks a child, climbs and glows while its dive line shows on the
## ground (every screen), and swoops along it: a child on the line is hit and pushed, one who stepped off is missed.
## After a dive it glides low (the window to hit it); after every second dive it lands and rests (double damage).
## Crystal towers rise round the arena at the start and at a third of its health, heal it every second until the
## team breaks them (weapons find them like monsters), and never hurt anyone. It never leaves the arena, never
## goes into the ground or cover, never changes a block; guests draw the line and the towers from synced state.
## Solo: this game is the host.

const FLOOR := 32
const DT := 1.0 / 60.0
const P := SkyDragonRules.Phase
const CENTER := Vector3(0.5, FLOOR, 0.5)
const TOTEM := Vector3(0.5, FLOOR, 0.5)

var _mode_before: StringName
var _universe_before := 1
var _unlocked_before := 1
var _gold_before := 0
var _dragon_before := {}          # owner 39: a win gives a baby dragon and a Dragon Crystal (the profile's)
var _gifts_before: Array[int] = []
var _hurts: Array = []
var _said: Array = []
var _cells := {}
var _n := 0


func before_each() -> void:
	_mode_before = Game.mode
	_universe_before = Game.universe
	_unlocked_before = Profile.data.universe_unlocked
	_gold_before = Profile.data.survivor_gold
	_dragon_before = Profile.data.baby_dragon.duplicate()
	_gifts_before = Profile.data.crystal_gifts.duplicate()
	Game.mode = ModeRules.SURVIVOR
	_hurts.clear()
	_said.clear()
	_cells = {}
	Session.player_hurt.connect(_on_hurt)
	Session.magic_feedback.connect(_on_said)
	var ground := StaticBody3D.new()             # the arena's ground (the terrain's collision)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(90, 1, 90)
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
	ground.global_position = Vector3(0, FLOOR - 0.5, 0)


func after_each() -> void:
	Session.player_hurt.disconnect(_on_hurt)
	Session.magic_feedback.disconnect(_on_said)
	Game.mode = _mode_before
	Game.universe = _universe_before
	Profile.data.universe_unlocked = _unlocked_before
	Profile.data.survivor_gold = _gold_before
	Profile.data.baby_dragon = _dragon_before
	Profile.data.crystal_gifts = _gifts_before
	Session.survivor_reset()
	Music.reset()
	UniverseRegistry.reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _on_hurt(peer: int, hp: int, from: Vector3) -> void:
	_hurts.append([peer, hp, from])


func _on_said(text: String) -> void:
	_said.append(text)


func _block(p: Vector3i) -> int:
	if _cells.has(p):
		return _cells[p]
	return BlockIds.STONE if p.y < FLOOR else BlockIds.AIR


## A dragon as the BossDirector makes it: it rises 7 blocks from the middle (BossRules.golem_spot), facing it.
func _dragon(max_hp: int = SkyDragonRules.BASE_HP, tired: bool = false, center: Vector3 = CENTER) -> SkyDragon:
	_n += 1
	var d := SkyDragon.new()
	d.setup({"id": "sd%d" % _n, "pos": BossRules.golem_spot(center), "yaw": 0.0, "max_hp": max_hp, "tired": tired,
		"center": center})
	d.block_at = _block
	add_child_autofree(d)
	d.set_physics_process(false)
	d.set_process(false)          # the test steps the looks by hand (the engine's own _process races them)
	return d


func _player(feet: Vector3, peer: int = 1) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _steps(d: SkyDragon, n: int) -> void:
	for i in n:
		if is_instance_valid(d):
			d._physics_process(DT)


func _steps_until(d: SkyDragon, done: Callable, limit: int = 2400) -> int:
	for i in limit:
		if done.call():
			return i
		_steps(d, 1)
	return limit


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _off_line(p: Vector3, a: Vector3, b: Vector3) -> float:
	var q := Vector2(p.x, p.z)
	return q.distance_to(Geometry2D.get_closest_point_to_segment(q, Vector2(a.x, a.z), Vector2(b.x, b.z)))


# --- A boss the director knows ----------------------------------------------------------------------------------

func test_it_is_a_boss_the_director_knows_with_shared_meshes() -> void:
	var a := _dragon()
	var b := _dragon()
	assert_true(a is StoneGolem, "the BossDirector's fights, bar and help work unchanged")
	assert_true(a.is_in_group(&"monsters"), "weapons and bot friends find it")
	assert_eq(a.boss_kind(), BossRules.SKY_DRAGON)
	var shapes := a.find_children("*", "CollisionShape3D", false, false)
	assert_eq(shapes.size(), 1)
	var box := (shapes[0] as CollisionShape3D).shape as BoxShape3D
	assert_lte(maxf(box.size.x, box.size.z), Buddy.MAX_FOOTPRINT, "a small footprint")
	var meshes_a := a.find_children("*", "MeshInstance3D", true, false).map(func(m: MeshInstance3D) -> Mesh: return m.mesh)
	var meshes_b := b.find_children("*", "MeshInstance3D", true, false).map(func(m: MeshInstance3D) -> Mesh: return m.mesh)
	assert_eq(meshes_a, meshes_b, "every dragon shares the same meshes")
	assert_same(SkyDragonModels.body_mesh().surface_get_material(0), BlockyAnimal.mesh_for(&"pig").surface_get_material(0),
		"the animals' material: no new shader")
	assert_same(SkyDragonModels.eyes_mesh().surface_get_material(0), GolemModels.glow_material(),
		"its glow is the Golem's shared glow material")
	assert_same(SkyDragonModels.line_mesh().surface_get_material(0), GolemModels.glow_material(), "the dive line's too")


func test_it_arrives_then_circles_high_over_the_arena() -> void:
	var d := _dragon()
	_player(Vector3(0.5, FLOOR, 6.5))
	await get_tree().physics_frame
	assert_eq(d.phase, P.RISE)
	d.take_hit(50, Vector3.ZERO, Vector3.ZERO)
	assert_eq(d.hp, SkyDragonRules.BASE_HP, "arriving: not yet")
	_steps_until(d, func() -> bool: return d.phase == P.CIRCLE)
	assert_eq(d.phase, P.CIRCLE)
	var low := INF
	var near := INF
	var far := 0.0
	for i in int(SkyDragonRules.phase_time(P.CIRCLE, false) / DT) - 2:
		_steps(d, 1)
		low = minf(low, d.global_position.y - FLOOR)
		near = minf(near, _flat(d.global_position, CENTER))
		far = maxf(far, _flat(d.global_position, CENTER))
	assert_gte(low, SkyDragonRules.FLY_HEIGHT - 0.5, "high over the ground: out of a sword's reach")
	assert_almost_eq(near, SkyDragonRules.CIRCLE_RADIUS, 1.5, "round the middle")
	assert_almost_eq(far, SkyDragonRules.CIRCLE_RADIUS, 1.5)
	d.take_hit(50, Vector3.ZERO, Vector3.ZERO)
	assert_eq(d.hp, SkyDragonRules.BASE_HP - 50, "an arrow reaches it up there")


# --- The dive ---------------------------------------------------------------------------------------------------

func test_a_dive_hits_a_child_on_the_line_after_the_line_showed() -> void:
	var d := _dragon()
	var p := _player(Vector3(0.5, FLOOR, 6.5))
	await get_tree().physics_frame
	_steps_until(d, func() -> bool: return d.phase == P.DIVE_WARN)
	assert_eq(d.phase, P.DIVE_WARN, "it picks a child")
	assert_true(d.dive_from.is_finite() and d.dive_to.is_finite(), "the line is set (synced)")
	assert_lt(_off_line(p.global_position, d.dive_from, d.dive_to), 0.3, "the line runs through the child")
	var high := d.global_position.y
	var frames := _steps_until(d, func() -> bool: return d.phase == P.DIVE)
	assert_almost_eq(frames * DT, SkyDragonRules.phase_time(P.DIVE_WARN, false), 3 * DT, "the line shows first")
	assert_gt(d.global_position.y, high, "it climbed while it glowed")
	assert_eq(_hurts.size(), 0, "nothing hurts during the warning")
	_steps_until(d, func() -> bool: return d.phase == P.GLIDE)
	assert_eq(_hurts.size(), 1, "hit once as it passed")
	assert_eq(p.health.hp, Health.MAX_HP - SkyDragonRules.DIVE_DAMAGE)


## Mirrored: a step off the line to either side during the warning dodges the dive.
func test_a_child_who_steps_off_the_line_is_missed() -> void:
	for side: float in [1.0, -1.0]:
		_hurts.clear()
		var d := _dragon()
		var p := _player(Vector3(0.5, FLOOR, 6.5))
		await get_tree().physics_frame
		_steps_until(d, func() -> bool: return d.phase == P.DIVE_WARN)
		var dir := (d.dive_to - d.dive_from).normalized()
		var across := Vector3(-dir.z, 0.0, dir.x) * side
		p.global_position += across * (SkyDragonRules.LINE_HALF_WIDTH + 1.0)   # a couple of steps aside
		_steps_until(d, func() -> bool: return d.phase == P.GLIDE)
		assert_eq(_hurts.size(), 0, "stepped off to the %s: missed" % ("left" if side < 0 else "right"))
		assert_eq(p.health.hp, Health.MAX_HP)
		d.free()
		p.free()
		await get_tree().physics_frame


## Over cover on its dive line it keeps above the blocks (it never goes through what it could hit): the child
## stands in a ring of 2-block cover, so every dive and every low glide back to the middle crosses it.
func test_it_never_flies_through_cover_or_ground() -> void:
	var child := Vector3(0.5, FLOOR, 8.5)
	var p := _player(child)
	for x in range(-5, 7):
		for z in range(3, 15):
			var r := Vector2(x + 0.5 - child.x, z + 0.5 - child.z).length()
			if r >= 2.5 and r <= 3.3:
				for y in range(FLOOR, FLOOR + 2):
					_cells[Vector3i(x, y, z)] = BlockIds.STONE
	var d := _dragon()
	await get_tree().physics_frame
	var worst := INF
	for i in int(45.0 / DT):
		_steps(d, 1)
		var at := d.global_position
		var ground := float(FLOOR)
		for o: Vector2 in [Vector2.ZERO, Vector2(0.9, 0), Vector2(-0.9, 0), Vector2(0, 0.9), Vector2(0, -0.9)]:
			if _cells.has(Vector3i(floori(at.x + o.x), FLOOR, floori(at.z + o.y))):
				ground = FLOOR + 2.0          # its feet or body over the cover
		worst = minf(worst, at.y - ground)
		assert_lte(_flat(at, CENTER), SkyDragonRules.ARENA_LIMIT + 0.01, "never out of the arena circle")
		if d.phase == P.DOWN:
			break
	assert_gte(worst, -0.01, "never into the ground or the cover (lowest %.2f over it)" % worst)
	assert_lt(p.health.hp, Health.MAX_HP, "its dives reached the child in the ring (it flew low there)")


## After a dive it glides low where a sword reaches it; after every second dive it lands and rests: double damage.
func test_after_a_dive_it_glides_low_and_every_second_dive_it_rests() -> void:
	var d := _dragon(2000)
	_player(Vector3(0.5, FLOOR, 8.5))
	await get_tree().physics_frame
	_steps_until(d, func() -> bool: return d.phase == P.GLIDE)
	_steps(d, int(0.8 / DT))
	assert_eq(d.phase, P.GLIDE)
	assert_lte(d.global_position.y - FLOOR, SkyDragonRules.GLIDE_HEIGHT + 0.3, "low")
	var chest := FLOOR + 1.4
	assert_lte(absf(d.hit_center().y - chest), WeaponRules.MAX_MELEE_RISE, "a sword's swing reaches it")
	_steps_until(d, func() -> bool: return d.phase != P.GLIDE)
	assert_eq(d.phase, P.CLIMB, "one dive: back up")
	_steps_until(d, func() -> bool: return d.phase == P.REST)
	assert_eq(d.phase, P.REST, "the second dive: it lands and rests")
	assert_almost_eq(d.global_position.y, float(FLOOR), 0.05, "on the ground")
	assert_true(d.is_dazed(), "the boss bar's x2 chip")
	var before := d.hp
	d.take_hit(10, Vector3.ZERO, Vector3.ZERO)
	assert_eq(d.hp, before - 20, "resting: double")
	_steps_until(d, func() -> bool: return d.phase != P.REST)
	assert_eq(d.phase, P.TAKE_OFF)
	_steps_until(d, func() -> bool: return d.phase == P.CIRCLE)
	assert_gte(d.global_position.y - FLOOR, SkyDragonRules.FLY_HEIGHT - 0.5, "back up high")


## Over a long fight every hurt comes from a dive, after its line showed: nothing hurts without a warning, and the
## towers never hurt anyone (a child stands right by one the whole time).
func test_nothing_hurts_without_a_warning() -> void:
	var d := _dragon(5000)
	var p := _player(Vector3(0.5, FLOOR, 6.5))
	await get_tree().physics_frame
	_steps_until(d, func() -> bool: return d.phase == P.CIRCLE)
	p.global_position = d.towers()[0].global_position + Vector3(0.8, 0, 0)   # right by a tower
	var warned := 0.0
	var phases: Array = []
	for i in int(40.0 / DT):
		var n := _hurts.size()
		_steps(d, 1)
		if d.phase == P.DIVE_WARN:
			warned += DT
		elif d.phase == P.CIRCLE:
			warned = 0.0
		if _hurts.size() > n:
			phases.append([d.phase, warned])
	assert_gt(phases.size(), 0, "the dives hit someone")
	for ph: Array in phases:
		assert_true(ph[0] == P.DIVE or ph[0] == P.GLIDE, "hurt only by a dive (phase %d)" % ph[0])
		assert_gte(ph[1], SkyDragonRules.phase_time(P.DIVE_WARN, false) - 2 * DT, "after its line showed")


# --- Crystal towers ---------------------------------------------------------------------------------------------

func test_crystal_towers_rise_heal_it_and_break() -> void:
	var d := _dragon()
	_player(Vector3(0.5, FLOOR, 6.5))
	await get_tree().physics_frame
	assert_eq(d.towers().size(), 0, "not while it arrives")
	_steps_until(d, func() -> bool: return d.phase == P.CIRCLE)
	assert_eq(d.towers().size(), 4, "four towers rise round the arena")
	assert_true(_said.has(SkyDragonRules.TOWER_LINE), "a line says what to do: %s" % [_said])
	var found := CombatDirector.monster_hittables(get_tree()).map(func(t: Dictionary) -> Node: return t.node)
	for t: SkyDragonTower in d.towers():
		assert_true(t.is_in_group(&"monsters"), "weapons, arrows, blasters and bot friends hit it")
		assert_true(found.has(t), "the combat director finds it")
		assert_almost_eq(_flat(t.global_position, CENTER), SkyDragonRules.TOWER_RING, 0.8)
		assert_almost_eq(t.global_position.y, float(FLOOR), 0.01, "standing on the ground")
	d.hp = 200
	d._heal_t = 0.0
	var heal4 := SkyDragonRules.heal_per_second(d.max_hp, 4)
	_steps(d, int(1.0 / DT) + 1)
	assert_eq(d.hp, 200 + heal4, "every tower heals it a little every second")
	var t0: SkyDragonTower = d.towers()[0]
	for i in SkyDragonRules.TOWER_HITS:
		assert_true(t0.is_in_group(&"monsters"))
		t0.take_hit(3, t0.global_position + Vector3(2, 1, 0), Vector3.ZERO)
	assert_false(t0.is_in_group(&"monsters"), "broken: nothing aims at it any more")
	assert_false(t0.standing())
	assert_eq(d.standing_towers(), 3)
	var before := d.hp
	d._heal_t = 0.0
	_steps(d, int(1.0 / DT) + 1)
	assert_eq(d.hp, before + SkyDragonRules.heal_per_second(d.max_hp, 3), "three heal less")
	t0.take_hit(3, Vector3.ZERO, Vector3.ZERO)
	_steps(d, int(5.0 / DT))
	assert_eq(d.standing_towers(), 3, "a broken tower stays broken")
	for t: SkyDragonTower in d.towers():
		for i in SkyDragonRules.TOWER_HITS:
			t.take_hit(3, Vector3.ZERO, Vector3.ZERO)
	assert_eq(d.standing_towers(), 0)
	before = d.hp
	_steps(d, int(2.0 / DT))
	assert_eq(d.hp, before, "no towers: no healing")


## At a third of its health the towers rise once more, in new places (not at two thirds, never a third time).
func test_towers_rise_again_at_a_third_of_its_health() -> void:
	var d := _dragon(300)
	_player(Vector3(0.5, FLOOR, 6.5))
	await get_tree().physics_frame
	_steps_until(d, func() -> bool: return d.phase == P.CIRCLE)
	var first: Array = d.towers().map(func(t: SkyDragonTower) -> Vector3: return t.global_position)
	for t: SkyDragonTower in d.towers():
		for i in SkyDragonRules.TOWER_HITS:
			t.take_hit(3, Vector3.ZERO, Vector3.ZERO)
	d.take_hit(95, Vector3.ZERO, Vector3.ZERO)             # 205: still over two thirds
	d.take_hit(10, Vector3.ZERO, Vector3.ZERO)             # 195: two thirds: nothing new
	assert_eq(d.standing_towers(), 0)
	d.take_hit(94, Vector3.ZERO, Vector3.ZERO)             # 101
	assert_eq(d.standing_towers(), 0)
	d.take_hit(1, Vector3.ZERO, Vector3.ZERO)              # 100: a third
	assert_eq(d.standing_towers(), 4, "the towers rise again")
	assert_true(_said.has(SkyDragonRules.TOWER_LINE_AGAIN), "and it says so: %s" % [_said])
	for t: SkyDragonTower in d.towers():
		for f: Vector3 in first:
			assert_gt(_flat(t.global_position, f), 2.0, "in new places")
	for t: SkyDragonTower in d.towers():
		for i in SkyDragonRules.TOWER_HITS:
			t.take_hit(3, Vector3.ZERO, Vector3.ZERO)
	d.take_hit(50, Vector3.ZERO, Vector3.ZERO)
	assert_eq(d.standing_towers(), 0, "never a third time")


func test_a_tired_dragon_raises_three_towers() -> void:
	var d := _dragon(SkyDragonRules.max_hp(1, true), true)
	_player(Vector3(0.5, FLOOR, 6.5))
	await get_tree().physics_frame
	_steps_until(d, func() -> bool: return d.phase == P.CIRCLE)
	assert_eq(d.towers().size(), 3)


# --- Every screen -----------------------------------------------------------------------------------------------

## A guest's copy is never stepped: it draws the dive line and the towers from the synced state alone.
func test_guests_see_the_dive_line_and_the_towers() -> void:
	var g := _dragon()
	var cfg := (g.get_node("Sync") as MultiplayerSynchronizer).replication_config
	for prop in [".:position", ".:rotation", ".:hp", ".:phase", ".:dive_from", ".:dive_to", ".:tower_spots", ".:tower_hits"]:
		assert_true(cfg.has_property(NodePath(prop)), "%s is synced" % prop)
	g._process(DT)
	assert_false(g.line_shown(), "no line while it circles")
	g.phase = P.DIVE_WARN
	g.dive_from = Vector3(12.5, FLOOR, 0.5)
	g.dive_to = Vector3(-8.5, FLOOR, 0.5)
	g._process(DT)
	assert_true(g.line_shown(), "the line on every screen")
	var line := g.line_node()
	assert_almost_eq(line.global_position.x, 2.0, 0.01, "between its ends")
	assert_almost_eq(line.global_position.y, float(FLOOR), 0.2, "on the ground")
	assert_almost_eq(line.global_basis.z.length(), 21.0, 0.01, "as long as the dive")
	assert_gte(line.global_basis.x.length(), 2.0 * SkyDragonRules.LINE_HALF_WIDTH - 0.001, "as wide as it hits, or more")
	g.phase = P.DIVE
	g._process(DT)
	assert_true(g.line_shown(), "still there while it swoops")
	g.phase = P.GLIDE
	g._process(DT)
	assert_false(g.line_shown(), "gone after the dive")
	g.tower_spots = PackedVector3Array([Vector3(10.5, FLOOR, 0.5), Vector3(0.5, FLOOR, 10.5), Vector3(-9.5, FLOOR, 0.5)])
	g.tower_hits = PackedByteArray([0, SkyDragonRules.TOWER_HITS, 1])
	g._process(DT)
	assert_eq(g.towers().size(), 3, "the towers stand where the host raised them")
	assert_almost_eq(g.towers()[0].global_position.x, 10.5, 0.01)
	assert_false(g.towers()[1].standing(), "a broken one shows broken")
	assert_false(g.towers()[1].is_in_group(&"monsters"))
	assert_true(g.towers()[2].standing())
	g.tower_hits = PackedByteArray([SkyDragonRules.TOWER_HITS, SkyDragonRules.TOWER_HITS, 1])
	g._process(DT)
	assert_false(g.towers()[0].standing(), "it breaks on every screen")
	g.towers()[2].take_hit(3, Vector3.ZERO, Vector3.ZERO)
	assert_eq(int(g.tower_hits[2]), 2, "the host decides the hits")


func test_the_boss_music_plays_while_it_is_here() -> void:
	Music.reset()
	var d := _dragon()
	Music.tick(0.1)
	assert_eq(Music.current(), MusicRules.BOSS)
	d.free()
	Music.tick(0.1)
	assert_ne(Music.current(), MusicRules.BOSS)


class WatchedWorld:
	extends WorldService
	var edits := 0

	func get_block(pos: Vector3i) -> int:
		return BlockIds.STONE if pos.y < 32 or (pos.z == 4 and pos.y < 34) else BlockIds.AIR

	func set_block(_pos: Vector3i, _id: int) -> void:
		edits += 1

	func is_editable(_pos: Vector3i) -> bool:
		return true


func test_it_never_changes_blocks() -> void:
	var w := WatchedWorld.new()
	autofree(w)
	var before := Session.world
	Session.register_world(w)
	var d := _dragon(5000)
	d.block_at = w.get_block
	var p := _player(Vector3(0.5, FLOOR, 7.5))
	await get_tree().physics_frame
	_steps(d, int(40.0 / DT))
	for t: SkyDragonTower in d.towers():
		for i in SkyDragonRules.TOWER_HITS:
			t.take_hit(3, p.global_position, Vector3.ZERO)
	d.take_hit(100000, p.global_position, Vector3.ZERO)
	Session.register_world(before)
	assert_eq(w.edits, 0, "the Sky Dragon never edits a block")
	for path in ["res://entities/monsters/sky_dragon.gd", "res://entities/monsters/sky_dragon_models.gd",
			"res://entities/monsters/sky_dragon_tower.gd", "res://core/rules/sky_dragon_rules.gd"]:
		var src := FileAccess.get_file_as_string(path)
		assert_gt(src.length(), 0, path)
		for call in ["set_block", "request_set_block", "set_voxel(", "do_box", "do_sphere"]:
			assert_false(src.contains(call), "%s never calls %s" % [path.get_file(), call])
	var tower_src := FileAccess.get_file_as_string("res://entities/monsters/sky_dragon_tower.gd")
	for call in ["hurt_player", "hurt(", "send_knockback"]:
		assert_false(tower_src.contains(call), "a tower never hurts anyone (%s)" % call)


func test_a_lost_fight_flies_it_away_with_its_towers() -> void:
	var d := _dragon()
	_player(Vector3(0.5, FLOOR, 6.5))
	await get_tree().physics_frame
	_steps_until(d, func() -> bool: return d.phase == P.CIRCLE)
	assert_eq(d.towers()[0].get_parent(), d, "its towers are its own: they go with it")
	d.go_to_sleep()
	assert_true(d.is_down())
	assert_eq(d.collision_layer, 0, "nothing aims at it any more")
	var y := d.global_position.y
	_steps(d, 10)
	assert_gt(d.global_position.y, y, "it flies off")
	_steps(d, int(3.0 / DT))
	assert_true(d.is_queued_for_deletion(), "and is gone")


# --- Through the BossDirector -----------------------------------------------------------------------------------

func _director(kind: StringName = BossRules.SKY_DRAGON) -> BossDirector:
	var bd := BossDirector.new()
	bd.name = "Boss"
	bd.block_at = _block
	bd.boss_kind = kind
	bd.pay_gold = func(_peer: int, _amount: int) -> void: pass
	bd.celebrate = func() -> void: pass
	var bar := BossBar.new()
	add_child_autofree(bar)
	bd.bar = bar
	add_child_autofree(bd)
	return bd


func _win(bd: BossDirector) -> void:
	var g := bd.golem()
	g.start_phase(P.CIRCLE)
	g.take_hit(100000, TOTEM, Vector3.ZERO)
	await get_tree().process_frame
	bd.tick(0.016)


## Universe 6, the Glow Caves, came after the realm: the Sky Dragon's win opens the portal there (the grand celebration
## waits for the last universe).
func test_the_dragon_realms_totem_brings_the_sky_dragon_and_a_win_opens_the_glow_caves() -> void:
	Game.universe = 5
	Profile.data.universe_unlocked = 5
	_player(TOTEM + Vector3(0, 0, 6))
	await get_tree().physics_frame
	var bd := _director()
	assert_eq(bd.start(TOTEM), "")
	var g := bd.golem()
	assert_true(g is SkyDragon, "the world's boss")
	assert_eq(g.max_hp, SkyDragonRules.max_hp(1))
	assert_almost_eq(_flat((g as SkyDragon).center, TOTEM), 0.0, 0.001, "it circles over the Totem")
	bd.tick(0.016)
	assert_eq(bd.bar.title(), SkyDragonRules.TITLE)
	assert_eq(bd.bar.face(), BossRules.SKY_DRAGON, "the bar shows the dragon's face")
	assert_eq(bd.start(TOTEM), "The Sky Dragon is already here!", "one at a time, by its name")
	await _win(bd)
	assert_eq(bd.bar.title(), SkyDragonRules.WIN_MESSAGE)
	assert_eq(bd.help.losses, 0, "the help resets after a win")
	assert_false(_said.has(CakeRules.GRAND_WIN), "not the last universe now: %s" % [_said])
	assert_eq(bd.portals().size(), 1)
	assert_eq(bd.portals()[0].target, 6, "its portal leads to the Glow Caves")


func test_a_tired_dragon_says_so() -> void:
	Game.universe = 5
	_player(TOTEM + Vector3(0, 0, 6))
	await get_tree().physics_frame
	var bd := _director()
	bd.help = {"losses": BossRules.TIRED_AFTER, "best": 40, "wins": 0}
	bd.start(TOTEM)
	var g := bd.golem()
	assert_true(g.tired)
	assert_eq(g.max_hp, SkyDragonRules.max_hp(1, true))
	assert_true(_said.has(SkyDragonRules.TIRED_MESSAGE), "honest help is announced: %s" % [_said])
	bd.tick(0.016)
	assert_eq(bd.bar.title(), SkyDragonRules.TIRED_TITLE)


## Monster Wave's raid boss opens no portal (a choice comes instead): its win says none.
func test_as_the_raid_boss_its_win_promises_no_portal() -> void:
	Game.mode = ModeRules.WAVE
	Game.universe = 5
	_player(TOTEM + Vector3(0, 0, 6))
	await get_tree().physics_frame
	var bd := _director()
	bd.opens_portal = false
	bd.start(TOTEM)
	await _win(bd)
	assert_eq(bd.portals().size(), 0)
	assert_eq(bd.bar.title(), SkyDragonRules.WIN_MESSAGE)
	assert_false(_said.has(BossDirector.GRAND_WIN_NO_PORTAL), "the Glow Caves come after it: %s" % [_said])
	for s: String in _said:
		assert_false(s.to_lower().contains("portal"), "no portal is promised: %s" % s)


## Monster Wave: the ArenaDirector starts the raid boss at wave 10 through the BossDirector: the Sky Dragon when the
## world's boss is the dragon (nothing in the ArenaDirector knows boss kinds).
func test_the_arena_starts_the_sky_dragon_at_wave_ten() -> void:
	Game.mode = ModeRules.WAVE
	Game.universe = 5
	var me := _player(Vector3(0.5, FLOOR, 6.5))
	await get_tree().physics_frame
	var md := MonsterDirector.new()
	md.name = "Monsters"
	md.block_at = _block
	md.player_positions = func() -> Array[Vector3]: return [me.global_position] as Array[Vector3]
	add_child_autofree(md)
	var waves := WaveDirector.new()
	waves.name = "Waves"
	waves.monsters = md
	waves.stand_spot = func(x: int, z: int) -> Vector3: return Vector3(x + 0.5, FLOOR, z + 0.5)
	waves.is_ready = func(_p: Vector3) -> bool: return true
	add_child_autofree(waves)
	waves.set_process(false)
	waves.place_totem(TOTEM, 0.0)
	var bd := _director()
	bd.opens_portal = false
	var now := [100.0]
	var a := ArenaDirector.new()
	a.name = "Arena"
	a.waves = waves
	a.boss = bd
	a.monsters = md
	a.universe = 5
	a.totem_pos = TOTEM
	a.now = func() -> float: return now[0]
	a.name_of = func(peer: int) -> String: return "P%d" % peer
	a.travel = func(_to: int) -> String: return ""
	a.next_open = func(_to: int) -> bool: return false
	add_child_autofree(a)
	a.set_process(false)
	a.start()
	a.cleared = ArenaRules.FINAL_WAVE - 1
	a.phase = ArenaDirector.Phase.BREATHER
	a.wait_left = 0.1
	for i in 4:
		now[0] += WaveDirector.TICK
		a.advance(WaveDirector.TICK)
		waves.advance(WaveDirector.TICK)
	assert_eq(a.phase, ArenaDirector.Phase.BOSS)
	assert_true(bd.golem() is SkyDragon, "the raid boss is the Sky Dragon")
	await _win(bd)
	assert_eq(a.phase, ArenaDirector.Phase.OVER, "beating it ends the run as a win")


## Owner 39: beating the Sky Dragon gives every player's own profile a baby dragon (once) and a Dragon Crystal.
func test_a_win_gives_a_baby_dragon_and_a_dragon_crystal() -> void:
	Game.mode = ModeRules.WAVE
	Game.universe = 5
	Profile.data.baby_dragon = {}
	Profile.data.crystal_gifts.clear()
	_player(TOTEM + Vector3(0, 0, 6))
	await get_tree().physics_frame
	var bd := _director()
	bd.opens_portal = false
	bd.start(TOTEM)
	await _win(bd)
	assert_false(Profile.data.baby_dragon.is_empty(), "a baby dragon")
	assert_eq(Profile.data.crystal_gifts, [5] as Array[int], "a Dragon Crystal to hand over")
	assert_true(_said.has(Session.DRAGON_GIFT_WORDS), "said: %s" % [_said])
