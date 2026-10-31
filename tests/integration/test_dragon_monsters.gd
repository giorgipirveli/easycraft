extends GutTest
## Owner feedback #39 (spec §14.2a): the Dragon Realm's monsters in the world, with real Monster nodes.
## The shadow bat hovers over a child's side, flares its wings, brightens its eyes and squeaks (everyone sees and
## hears it), then swoops: a child who stands still is hit, a sidestep dodges it; then it flies up and away to rest
## before it comes back. The wisp spirit floats (it never walks), keeps its distance, brightens, chimes and grows a
## ring, then throws a slow spark: a still child is hit, one who moves dodges it, a wall stops it (one built while
## it flies too). Both only attack what they see (stealth), never change a block, keep to where the islands are,
## puff away below y 0 over nothing, come at night and in waves of universe 5, and /summon works in any world.

const FLOOR := 10
const DT := 1.0 / 60.0
const U := 2
const S := MonsterRules.SHADOW_BAT
const W := MonsterRules.WISP

var _mode_before: StringName
var _n := 0
var _players: Array[Vector3] = []
var _cells := {}
var _time := DayCycle.MIDNIGHT


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	_players = [Vector3(0.5, FLOOR, 0.5)]
	_cells = {}
	_time = DayCycle.MIDNIGHT


func after_each() -> void:
	Game.mode = _mode_before
	Session.survivor_reset()


func after_all() -> void:
	Audio.stop_all()


func _block(p: Vector3i) -> int:
	if _cells.has(p):
		return _cells[p]
	return BlockIds.STONE if p.y < FLOOR else BlockIds.AIR


## Yaw that makes a monster at `from` face `to` (models face -Z).
static func _yaw_to(from: Vector3, to: Vector3) -> float:
	return atan2(-(to.x - from.x), -(to.z - from.z))


func _monster(kind: StringName, level: int, pos: Vector3, facing: Vector3 = Vector3.INF, block_at: Callable = _block) -> Monster:
	_n += 1
	var m := Monster.new()
	m.setup({"kind": kind, "level": level, "id": "dm%d" % _n, "pos": pos, "wild": true, "universe": U,
		"yaw": _yaw_to(pos, facing) if facing.is_finite() else 0.0})
	m.block_at = block_at
	add_child_autofree(m)
	m.set_physics_process(false)
	return m


## The ground, and a box for every solid cell in _cells.
func _ground() -> void:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	shape.position = Vector3(0, FLOOR - 0.5, 0)
	body.add_child(shape)
	for p: Vector3i in _cells:
		if BlockIds.is_solid(_cells[p]):
			var s := CollisionShape3D.new()
			var b := BoxShape3D.new()
			b.size = Vector3.ONE
			s.shape = b
			s.position = Vector3(p) + Vector3(0.5, 0.5, 0.5)
			body.add_child(s)
	add_child_autofree(body)


func _player(feet: Vector3, peer: int = 1) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _steps(m: Monster, n: int) -> void:
	for i in n:
		if is_instance_valid(m):
			m._physics_process(DT)


func _steps_until(m: Monster, done: Callable, limit: int = 120) -> int:
	for i in limit:
		if done.call():
			return i
		_steps(m, 1)
	return limit


## Steps while it keeps seeing `p` (the tests that are not about sight).
func _chase_steps(m: Monster, p: Player, n: int, done: Callable = Callable()) -> int:
	for i in n:
		if done.is_valid() and done.call():
			return i
		if is_instance_valid(m):
			m._target = p
			m.awareness.see(p.global_position)
			m._physics_process(DT)
	return n


func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _director(kinds: Array[StringName], universe: int, gentle: bool = false, block_at: Callable = _block) -> MonsterDirector:
	var d := MonsterDirector.new()
	d.name = "Monsters"
	d.player_positions = func() -> Array[Vector3]: return _players
	d.is_ready = func(_p: Vector3) -> bool: return true
	d.stand_spot = func(x: int, z: int) -> Vector3: return Vector3(x + 0.5, FLOOR, z + 0.5)
	d.lights_near = func(_p: Vector3) -> Array[Vector3i]: return [] as Array[Vector3i]
	d.home_beds = func() -> Array[Vector3i]: return [] as Array[Vector3i]
	d.time_of_day = func() -> float: return _time
	d.enabled = func() -> bool: return true
	d.gentle = gentle
	d.block_at = block_at
	d.kinds = kinds
	d.universe = universe
	d.rng.seed = 39
	add_child_autofree(d)
	return d


func _bursts() -> int:
	return get_tree().root.find_children("*", "CPUParticles3D", false, false).size()


# --- The shadow bat ------------------------------------------------------------------------------------------

func _shadow_bat_near(p: Player) -> Monster:
	var at := Vector3(4.5, FLOOR + 3.5, 0.5)
	return _monster(S, 1, at, p.global_position)


func test_a_shadow_bat_signals_then_swoops_and_a_child_standing_still_is_hit() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var b := _shadow_bat_near(p)
	await get_tree().physics_frame
	_steps_until(b, func() -> bool: return b.state == Monster.State.WINDUP, 300)
	assert_eq(b.state, Monster.State.WINDUP, "it signals first")
	assert_true(b.winding, "everyone sees the wings flare and the eyes brighten")
	assert_eq(p.health.hp, Health.MAX_HP, "nothing before its signal")
	var start := b.global_position
	var waited := _steps_until(b, func() -> bool: return p.health.hp < Health.MAX_HP, 240)
	assert_eq(p.health.hp, Health.MAX_HP - MonsterRules.hit(S, 1, U), "the swoop lands")
	assert_gte(waited, int(MonsterRules.SHADOW_WINDUP / DT) - 1, "the whole signal before the swoop (%d steps)" % waited)
	assert_lt(start.distance_to(b.global_position), 5.0)


func test_it_hovers_in_place_while_it_signals() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var b := _shadow_bat_near(p)
	await get_tree().physics_frame
	_steps_until(b, func() -> bool: return b.state == Monster.State.WINDUP, 300)
	var start := b.global_position
	_steps(b, int(MonsterRules.SHADOW_WINDUP / DT) - 4)
	assert_lt(b.global_position.distance_to(start), 0.6, "hovering, not diving yet")
	assert_eq(p.health.hp, Health.MAX_HP)


func test_a_sidestep_dodges_the_shadow_bat() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var b := _shadow_bat_near(p)
	await get_tree().physics_frame
	_steps_until(b, func() -> bool: return b.state == Monster.State.WINDUP, 300)
	_steps_until(b, func() -> bool: return b.state != Monster.State.WINDUP, 120)
	p.global_position += Vector3(0, 0, 2.5)
	_steps(b, int(MonsterRules.BAT_DIVE_TIME / DT) + 10)
	assert_eq(p.health.hp, Health.MAX_HP, "dodged")


## "Then flies up and away to rest": after its swoop it climbs away on its side and waits there, then comes back
## for another signalled swoop.
func test_after_its_swoop_a_shadow_bat_flies_up_and_away_to_rest() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var b := _shadow_bat_near(p)
	await get_tree().physics_frame
	_chase_steps(b, p, 400, func() -> bool: return p.health.hp < Health.MAX_HP)
	var after := p.health.hp
	assert_lt(after, Health.MAX_HP, "the first swoop")
	var far := [0.0]
	var high := [0.0]
	var calm := int((MonsterRules.BAT_LOW_TIME + MonsterRules.SHADOW_REST) / DT)
	for i in calm:
		_chase_steps(b, p, 1)
		far[0] = maxf(far[0], _flat(b.global_position, p.global_position))
		high[0] = maxf(high[0], b.global_position.y)
	assert_gt(far[0], MonsterRules.SHADOW_AWAY - 1.5, "away from the child (%.1f)" % far[0])
	assert_gt(high[0], FLOOR + MonsterRules.SHADOW_AWAY_UP - 1.0, "and up (%.1f)" % high[0])
	assert_eq(p.health.hp, after, "no swoop while it rests")
	_chase_steps(b, p, 900, func() -> bool: return p.health.hp < after)
	assert_lt(p.health.hp, after, "then it comes back for another (signalled) swoop")


# --- The wisp spirit -------------------------------------------------------------------------------------------

func test_a_wisp_floats_over_the_ground_and_never_walks() -> void:
	_ground()
	var w := _monster(W, 1, Vector3(0.5, FLOOR, 0.5))
	_player(Vector3(20.5, FLOOR, 20.5))              # within 32 blocks, so it moves (and out of sight)
	await get_tree().physics_frame
	var low := [INF]
	var high := [-INF]
	for i in 360:
		_steps(w, 1)
		if i > 150:
			low[0] = minf(low[0], w.global_position.y)
			high[0] = maxf(high[0], w.global_position.y)
	assert_gt(low[0], FLOOR + MonsterRules.WISP_FLOAT - 0.8, "it floats above the ground (%.2f)" % low[0])
	assert_lt(high[0], FLOOR + MonsterRules.WISP_FLOAT + 0.8, "at its own height, not a bat's (%.2f)" % high[0])


func _wisp_at(p: Player, at: Vector3, level: int = 1) -> Monster:
	return _monster(W, level, at, p.global_position)


## It keeps its distance: from right next to a child it drifts back to about WISP_KEEP, above their head.
func test_a_wisp_keeps_its_distance() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var w := _wisp_at(p, Vector3(1.5, FLOOR + 2.0, 0.5))
	await get_tree().physics_frame
	_chase_steps(w, p, 420)
	var d := _flat(w.global_position, p.global_position)
	assert_between(d, MonsterRules.WISP_KEEP - 1.5, MonsterRules.WISP_KEEP + 1.0, "about %.0f blocks away (%.1f)" % [MonsterRules.WISP_KEEP, d])
	assert_gt(w.global_position.y, FLOOR + MonsterRules.WISP_HOVER - 1.0, "above the child's head")


func test_a_wisp_signals_then_throws_a_slow_spark_and_a_child_standing_still_is_hit() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var w := _wisp_at(p, Vector3(7.5, FLOOR + 3.0, 0.5))
	await get_tree().physics_frame
	_chase_steps(w, p, 300, func() -> bool: return w.state == Monster.State.WINDUP)
	assert_eq(w.state, Monster.State.WINDUP, "it signals first")
	assert_true(w.winding, "everyone sees it brighten and grow its ring")
	var waited := _chase_steps(w, p, 200, func() -> bool: return w.sparks_in_flight() > 0)
	assert_gte(waited, int(MonsterRules.WISP_WINDUP / DT) - 1, "the whole signal before the spark (%d steps)" % waited)
	assert_eq(w.sparks_in_flight(), 1, "then the spark flies")
	var from := w.hit_center()
	_chase_steps(w, p, 6)
	assert_eq(p.health.hp, Health.MAX_HP, "it is slow: nothing yet")
	var flew := _chase_steps(w, p, 240, func() -> bool: return w.sparks_in_flight() == 0)
	assert_eq(p.health.hp, Health.MAX_HP - MonsterRules.hit(W, 1, U), "the spark lands on them")
	var slow := MonsterRules.spark_time(from, MonsterRules.spark_aim(p.global_position)) - 0.25
	assert_gt((flew + 6) * DT, slow, "a slow spark (%.2f s)" % ((flew + 6) * DT))


func test_a_child_who_moves_dodges_the_spark() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var w := _wisp_at(p, Vector3(7.5, FLOOR + 3.0, 0.5))
	await get_tree().physics_frame
	_chase_steps(w, p, 400, func() -> bool: return w.sparks_in_flight() > 0)
	assert_eq(w.sparks_in_flight(), 1)
	p.global_position += Vector3(0, 0, 2.0)          # a couple of steps to the side
	_steps_until(w, func() -> bool: return w.sparks_in_flight() == 0, 240)
	assert_eq(p.health.hp, Health.MAX_HP, "dodged")


func _wall(x: int, height: int) -> void:
	for z in range(-4, 5):
		for y in range(FLOOR, FLOOR + height):
			_cells[Vector3i(x, y, z)] = BlockIds.PLANKS


## A wall between the wisp and the child: it never throws (children hide behind walls).
func test_a_wall_between_means_no_spark() -> void:
	_wall(3, 8)
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var w := _wisp_at(p, Vector3(7.5, FLOOR + 3.0, 0.5))
	await get_tree().physics_frame
	for i in 300:
		_chase_steps(w, p, 1)
		assert_eq(w.sparks_in_flight(), 0, "no spark through the wall")
		if w.sparks_in_flight() > 0:
			break
	assert_eq(p.health.hp, Health.MAX_HP)


## A wall built while the spark flies stops it there.
func test_a_wall_built_while_the_spark_flies_stops_it() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var w := _wisp_at(p, Vector3(7.5, FLOOR + 3.0, 0.5))
	await get_tree().physics_frame
	_chase_steps(w, p, 400, func() -> bool: return w.sparks_in_flight() > 0)
	assert_eq(w.sparks_in_flight(), 1)
	_wall(2, 6)
	_steps_until(w, func() -> bool: return w.sparks_in_flight() == 0, 240)
	assert_eq(p.health.hp, Health.MAX_HP, "the wall took it")
	assert_gt(w.last_spark_end.x, 2.0, "it ended at the wall (%s)" % w.last_spark_end)


# --- Both: stealth, blocks, the void ---------------------------------------------------------------------------

## They perceive like every monster (§12.5): an invisible child in front of them is never seen or attacked; the
## same child visible is (the mirrored setup, so luck can't pass both).
func test_they_only_attack_what_they_see() -> void:
	_ground()
	var far := 0.0
	for invisible in [true, false]:
		for kind: StringName in MonsterRules.DRAGON_KINDS:
			far += 70.0                               # each pair on its own, far from the others
			var p := _player(Vector3(far + 0.5, FLOOR, 0.5), 1 + int(far))
			if invisible:
				p.drink(ItemIds.POTION_INVIS)
			var m := _monster(kind, 1, Vector3(far + 6.5, FLOOR + 3.0, 0.5), p.global_position)
			await get_tree().physics_frame
			var wound := _steps_until(m, func() -> bool: return m.state == Monster.State.WINDUP, 360) < 360
			if invisible:
				assert_null(m.perceive(), "%s never sees an invisible child" % kind)
				assert_false(wound, "%s never winds up at them" % kind)
				assert_eq(p.health.hp, Health.MAX_HP)
			else:
				assert_eq(m.perceive(), p, "%s sees a visible child" % kind)
				assert_true(wound, "%s winds up at a child it sees" % kind)


## A Dragon Realm world never loses a block to them: summoned at levels 1, 3 and 5 by a child behind a wall,
## swooping, throwing sparks into the wall and defeated, nobody changes one.
class WatchedWorld:
	extends WorldService
	const GROUND := 10
	var edits := 0

	func get_block(pos: Vector3i) -> int:
		return BlockIds.STONE if pos.y < GROUND or (pos.z == -3 and pos.y < GROUND + 3) else BlockIds.AIR

	func set_block(_pos: Vector3i, _id: int) -> void:
		edits += 1

	func is_editable(_pos: Vector3i) -> bool:
		return true


func test_they_never_change_a_block() -> void:
	var w := WatchedWorld.new()
	autofree(w)
	var before := Session.world
	Session.register_world(w)
	_ground()
	var d := _director(MonsterRules.DRAGON_KINDS, 5, false, w.get_block)
	var p := _player(Vector3(0.5, FLOOR, -5.5))   # behind a wall of blocks
	await get_tree().physics_frame
	for kind in MonsterRules.DRAGON_KINDS:
		for level in [1, 3, 5]:
			assert_eq(d.summon(kind, level, p.global_position), "")
	for i in 300:
		for m in d.monsters():
			m._target = p
			m.awareness.see(p.global_position)
			m._physics_process(DT)
		p.health.hp = Health.MAX_HP
	for m in d.monsters():
		m.take_hit(1000, p.global_position, Vector3(0, 2, 3))
	for c in d.coins():
		c._physics_process(DT)
	Session.register_world(before)
	assert_eq(w.edits, 0, "no monster ever edits a block")
	for path in ["res://entities/monsters/monster.gd", "res://entities/monsters/spit_glob.gd",
			"res://entities/monsters/monster_models.gd", "res://core/rules/monster_rules.gd"]:
		var src := FileAccess.get_file_as_string(path)
		for call in ["set_block", "request_set_block", "set_voxel(", "do_box", "do_sphere"]:
			assert_false(src.contains(call), "%s never calls %s" % [path.get_file(), call])


func _island(p: Vector3i) -> int:
	return BlockIds.STONE if p.y >= 38 and p.y < 40 and absi(p.x) < 7 and absi(p.z) < 7 else BlockIds.AIR


## Floating islands over the void: wandering, they keep to the island instead of sinking into the void.
func test_over_the_void_they_keep_to_the_island() -> void:
	var p := _player(Vector3(0.5, 40, 20.5))         # within 32 blocks (they move) ...
	p.drink(ItemIds.POTION_INVIS)                    # ... and never seen: they only wander
	var list: Array[Monster] = []
	for kind: StringName in MonsterRules.DRAGON_KINDS:
		for i in 2:
			list.append(_monster(kind, 1, Vector3(-2.5 + i * 5.0, 40, 0.5), Vector3.INF, _island))
	await get_tree().physics_frame
	var low := [INF]
	var out := [0.0]
	var over := [0]
	for i in 1800:
		for m in list:
			_steps(m, 1)
			if i > 120:
				low[0] = minf(low[0], m.global_position.y)
			var edge := maxf(absf(m.global_position.x - 0.5), absf(m.global_position.z - 0.5))
			out[0] = maxf(out[0], edge)
			if edge > 6.5:
				over[0] += 1
	assert_gt(low[0], 40.0, "never down into the void (lowest %.1f)" % low[0])
	assert_lt(out[0], 7.0 + 2.0, "near the island (furthest %.1f)" % out[0])
	# Mutation-checked: without the turn at the edge they spent 767 of these steps over the void (the way home
	# still brought them back); with it 0.
	assert_lt(over[0], 150, "they turn round at the edge (%d steps over the void)" % over[0])


## One that ends up out over the void (a push, a chase) keeps its height there and flies back to the island.
func test_out_over_the_void_it_keeps_its_height_and_comes_back() -> void:
	var p := _player(Vector3(0.5, 40, 20.5))
	p.drink(ItemIds.POTION_INVIS)
	for kind: StringName in MonsterRules.DRAGON_KINDS:
		var m := _monster(kind, 1, Vector3(3.5, 40, 0.5), Vector3.INF, _island)
		await get_tree().physics_frame
		_steps(m, 60)                                # up over the island
		var height := m.global_position.y
		m.global_position = Vector3(12.5, height, 0.5)   # blown out over the void
		var low := [INF]
		for i in 360:
			_steps(m, 1)
			low[0] = minf(low[0], m.global_position.y)
		assert_gt(low[0], height - 1.0, "%s keeps its height over the void (%.1f from %.1f)" % [kind, low[0], height])
		assert_lt(absf(m.global_position.x), 9.0, "%s is back near the island (x %.1f)" % [kind, m.global_position.x])


## One that ever ends up below y 0 with nothing under it puffs away (no gold); one in a deep cave below y 0 stays.
func test_below_y_0_over_nothing_it_puffs_away() -> void:
	var d := _director(MonsterRules.DRAGON_KINDS, 5, false, func(_c: Vector3i) -> int: return BlockIds.AIR)
	_player(Vector3(0.5, 2, 0.5))
	await get_tree().physics_frame
	assert_eq(d.summon(W, 1, Vector3(0.5, 2, 0.5)), "")
	var m := d.monsters()[0]
	m.set_physics_process(false)
	m.global_position = Vector3(0.5, -3.0, 0.5)
	var bursts := _bursts()
	_steps(m, 30)
	assert_true(not is_instance_valid(m) or m.is_queued_for_deletion(), "it puffed away")
	assert_gt(_bursts(), bursts, "a little puff")
	assert_eq(d.coins().size(), 0, "no gold")
	var cave := func(c: Vector3i) -> int: return BlockIds.STONE if c.y < -10 else BlockIds.AIR
	var bat := _monster(S, 1, Vector3(0.5, -6.0, 0.5), Vector3.INF, cave)
	_steps(bat, 30)
	assert_true(is_instance_valid(bat) and not bat.is_queued_for_deletion(), "a bat in a cave below y 0 stays")


# --- /summon, defeats, nights and waves ----------------------------------------------------------------------------

## They work in any universe: /summon wisp and /summon shadowbat in a Sandbox world of Green Meadows.
func test_summon_them_in_a_meadows_sandbox_world() -> void:
	Game.mode = ModeRules.SANDBOX
	var cmd := ChatCommands.host_check("/summon wisp", true, ModeRules.SANDBOX)
	assert_eq(cmd.get("monster"), W)
	assert_eq(cmd.get("level"), 1)
	var bat := ChatCommands.parse("/summon shadowbat 3")
	assert_eq(bat.get("monster"), S)
	assert_eq(bat.get("level"), 3)
	assert_true(ChatCommands.suggestions("/summon sha").has("/summon shadowbat"))
	assert_true(ChatCommands.suggestions("/summon wi").has("/summon wisp"))
	var d := _director(MonsterRules.MEADOWS_KINDS, 1, true)
	_time = DayCycle.NOON
	assert_eq(d.summon(W, 2, _players[0]), "")
	assert_eq(d.summon(S, 3, _players[0]), "")
	var got := {}
	for m in d.monsters():
		got[m.kind] = m
		assert_eq(m.universe, 1)
		assert_eq(m.hp, MonsterRules.hp(m.kind, m.level, 1), "Green Meadows' numbers")
		assert_false(m.wild, "the sun leaves a summoned one alone")
	assert_true(got.has(W) and got.has(S))
	d.tick()
	assert_eq(d.monsters().size(), 2, "still there in the day")


func test_a_defeat_gives_coins_in_survivor_and_confetti_in_sandbox() -> void:
	var d := _director(MonsterRules.DRAGON_KINDS, 5)
	d.summon(S, 2, _players[0])
	var bursts := _bursts()
	d.monsters()[0].take_hit(1000, _players[0], Vector3.ZERO)
	assert_gt(_bursts(), bursts, "confetti")
	var total := 0
	for c in d.coins():
		total += c.value
	assert_eq(total, MonsterRules.gold(S, 2, 5), "its gold × 16 in universe 5, in coins")
	Game.mode = ModeRules.SANDBOX
	var gentle := _director(MonsterRules.DRAGON_KINDS, 5, true)
	gentle.summon(W, 2, _players[0])
	bursts = _bursts()
	gentle.monsters()[0].take_hit(1000, _players[0], Vector3.ZERO)
	assert_gt(_bursts(), bursts, "confetti")
	assert_eq(gentle.coins().size(), 0, "no coins in Sandbox")


func test_a_dragon_realm_night_brings_shadow_bats_and_wisps() -> void:
	var d := _director(MonsterRules.DRAGON_KINDS, 5)
	var seen := {}
	for i in 8:
		d.tick()
	for m in d.monsters():
		seen[m.kind] = true
		assert_eq(m.universe, 5)
	assert_true(seen.has(S) and seen.has(W), "%s" % [seen.keys()])


func test_monster_wave_waves_in_the_dragon_realm_bring_them() -> void:
	for wave in [1, 3, 6, 9]:
		var roster := ArcherRules.wave_roster(WaveRules.roster(wave, false, 2, MonsterRules.DRAGON_KINDS), wave)
		assert_eq(roster.size(), WaveRules.size(wave, false, 2))
		var kinds := {}
		for e: Dictionary in roster:
			kinds[e.kind] = true
			assert_true(MonsterRules.DRAGON_KINDS.has(e.kind), "wave %d: %s" % [wave, e.kind])
		if wave >= 3:
			assert_true(kinds.has(S) and kinds.has(W), "wave %d: %s" % [wave, kinds.keys()])


# --- Looks, sounds and minds ------------------------------------------------------------------------------------

func test_a_shadow_bat_is_dark_with_glowing_eyes_and_its_wings_flap_and_flare() -> void:
	var b := _monster(S, 2, Vector3(0.5, 40, 0.5))
	var wings := b.find_child("Arm", true, false) as Node3D
	assert_not_null(wings, "its wings")
	var mesh := wings.get_child(0) as MeshInstance3D
	var seen := {}
	for i in 30:
		b.global_position += Vector3(0.05, 0, 0)
		b._process(DT)
		seen[mesh.mesh] = true
	assert_gt(seen.size(), 1, "the wings go up and down")
	for m: Mesh in seen:
		assert_true(m == MonsterModels.arm_mesh_for(S, 2, 0, false, 0) or m == MonsterModels.arm_mesh_for(S, 2, 0, false, 1),
			"shared wing meshes")
	b.winding = true
	b._process(DT)
	assert_true(mesh.mesh == MonsterModels.arm_mesh_for(S, 2, 0, true, 0) or mesh.mesh == MonsterModels.arm_mesh_for(S, 2, 0, true, 1),
		"the signal: flared wings and bright eyes (a shared mesh)")
	assert_has(MonsterModels.colors_of(S, 3), MonsterRules.level_color(3), "it wears its level colour")
	var dark := 0
	for c in MonsterModels.colors_of(S, 1):
		if c.get_luminance() < 0.3:
			dark += 1
	assert_gt(dark, MonsterModels.colors_of(S, 1).size() / 2, "mostly dark violet: hard to see at night")
	assert_gt(MonsterModels.SHADOW_EYES.get_luminance(), 0.7, "but its eyes always glow")


func test_a_wisps_ring_grows_while_it_winds_up_on_every_screen() -> void:
	var w := _monster(W, 2, Vector3(0.5, 40, 0.5))
	w.set_process(false)
	var ring := w.find_child("Arm", true, false) as Node3D
	assert_not_null(ring, "its trail and ring")
	var mesh := ring.get_child(0) as MeshInstance3D
	var calm := mesh.mesh
	w.winding = true
	w._process(0.1)
	var first := ring.scale.x
	assert_same(mesh.mesh, MonsterModels.arm_mesh_for(W, 2, 0, true), "the ring shows (a shared mesh)")
	assert_lt(first, 0.7, "small at first")
	for i in int(MonsterRules.WISP_WINDUP / 0.1):
		w._process(0.1)
	assert_almost_eq(ring.scale.x, 1.0, 0.05, "full size as the spark leaves")
	assert_gt(MonsterModels.arm_mesh_for(W, 2, 0, true).get_aabb().size.y, calm.get_aabb().size.y, "a ring round the orb")
	w.winding = false
	w._process(0.1)
	assert_same(mesh.mesh, calm)


func test_their_voices_and_sounds_are_registered() -> void:
	var sounds: Dictionary = load("res://autoloads/audio.gd").SOUNDS
	for kind: StringName in MonsterRules.DRAGON_KINDS:
		for s: StringName in [MonsterRules.KIND[kind].sound, VoiceRules.monster_idle(kind), VoiceRules.monster_hurt(kind),
				MonsterRules.WINDUP_SOUND[kind]]:
			assert_true(sounds.has(s), "%s: %s" % [kind, s])
			assert_true(FileAccess.file_exists(str(sounds[s][0])), str(sounds[s][0]))
	assert_true(sounds.has(&"spark_pop"))
	assert_ne(VoiceRules.monster_hurt(S), &"hit", "their own cry")
	assert_ne(VoiceRules.monster_hurt(W), &"hit")


## Their minds pick only fair, signalled tactics that steer: a hurt wisp that backs off floats further away and
## throws nothing while it does; the tactics' hints are there for both.
func test_a_tactic_only_steers_where_they_fly() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var w := _wisp_at(p, Vector3(7.5, FLOOR + 3.0, 0.5))
	await get_tree().physics_frame
	w.hp = 1
	w.use_tactic(MonsterSpecies.BACK_OFF, p)
	var far := [0.0]
	var steps := 0
	while w.tactic == MonsterSpecies.BACK_OFF and steps < 300:
		_chase_steps(w, p, 1)
		steps += 1
		far[0] = maxf(far[0], _flat(w.global_position, p.global_position))
		if w.tactic == MonsterSpecies.BACK_OFF:
			assert_false(w.winding, "no signal while it backs off")
			if w.winding:
				break
	assert_gt(steps, 60, "it held the tactic a while (%d steps)" % steps)
	assert_gt(far[0], MonsterRules.WISP_KEEP + 1.0, "it backed off (%.1f)" % far[0])
	assert_eq(w.sparks_in_flight(), 0, "no spark while it backs off")
	assert_eq(p.health.hp, Health.MAX_HP)
	for kind: StringName in MonsterRules.DRAGON_KINDS:
		assert_eq(MonsterSpecies.table(kind).actions, MonsterSpecies.ACTIONS)
		for tactic in [MonsterSpecies.ZIGZAG, MonsterSpecies.GO_ROUND, MonsterSpecies.WAIT, MonsterSpecies.BACK_OFF, MonsterSpecies.CALL]:
			assert_true(MonsterSpecies.HINTS.has("%s:%s" % [kind, tactic]), "%s:%s" % [kind, tactic])


## A wisp that sees a child for a while lets its mind pick a tactic (fair ones only; it keeps throwing sparks).
func test_a_wisp_that_sees_a_child_thinks_about_how_to_come() -> void:
	_ground()
	var p := _player(Vector3(0.5, FLOOR, 0.5))
	var w := _wisp_at(p, Vector3(9.5, FLOOR + 3.0, 0.5))
	await get_tree().physics_frame
	_chase_steps(w, p, 30)
	assert_ne(w.tactic, &"", "its mind picked a tactic")
	assert_true(MonsterSpecies.ACTIONS.has(w.tactic))
