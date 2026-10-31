extends GutTest
## M2 Task 4: the host-side MonsterDirector with stubs (like the AnimalDirector tests): night spawns
## (distance, lights, home beds, caps, levels, a few per tick), Sandbox limits and its setting, the
## sunrise puff, far monsters leaving, defeats (confetti, coins, the slime split), coins given once to
## the nearest player, /summon, and the rule that monsters never change blocks.

const FLOOR := 10
const DT := 1.0 / 60.0

var _time := DayCycle.MIDNIGHT
var _on := true
var _lights: Array[Vector3i] = []
var _homes: Array[Vector3i] = []
var _players: Array[Vector3] = []
var _light_everywhere := false
var _mode_before: StringName
var _gold_before := 0


func before_each() -> void:
	_time = DayCycle.MIDNIGHT
	_on = true
	_lights = []
	_homes = []
	_players = [Vector3(0.5, FLOOR, 0.5)]
	_light_everywhere = false
	_mode_before = Game.mode
	_gold_before = Profile.data.survivor_gold
	Game.mode = ModeRules.SURVIVOR
	Profile.data.survivor_gold = 0


func after_each() -> void:
	Game.mode = _mode_before
	Profile.data.survivor_gold = _gold_before
	Session.survivor_reset()


func _flat(p: Vector3i) -> int:
	return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func _director(gentle: bool = false) -> MonsterDirector:
	var d := MonsterDirector.new()
	d.name = "Monsters"
	d.player_positions = func() -> Array[Vector3]: return _players
	d.is_ready = func(_p: Vector3) -> bool: return true
	d.stand_spot = func(x: int, z: int) -> Vector3: return Vector3(x + 0.5, FLOOR, z + 0.5)
	d.lights_near = func(p: Vector3) -> Array[Vector3i]:
		if _light_everywhere:
			var here: Array[Vector3i] = [Vector3i(p.floor())]
			return here
		return _lights
	d.home_beds = func() -> Array[Vector3i]: return _homes
	d.time_of_day = func() -> float: return _time
	d.enabled = func() -> bool: return _on
	d.gentle = gentle
	d.block_at = _flat
	d.rng.seed = 20260924
	add_child_autofree(d)
	return d


## A player standing still at `feet`.
func _player(feet: Vector3, peer: int = 1) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


# --- Night spawns ---

func test_at_night_monsters_come_18_to_40_blocks_from_the_player_a_few_at_a_time() -> void:
	var d := _director()
	d.tick()
	var list := d.monsters()
	assert_between(list.size(), 1, 3, "at most 3 a tick (the animals' lesson)")
	for m in list:
		var dist := Vector2(m.global_position.x - 0.5, m.global_position.z - 0.5).length()
		assert_between(dist, MonsterRules.SPAWN_MIN, MonsterRules.SPAWN_MAX)
		assert_true(m.wild)
		assert_true(m.is_in_group(&"monsters"))
		assert_eq(m.global_position.y, float(FLOOR), "standing on the surface")


func test_one_player_gets_at_most_10() -> void:
	var d := _director()
	var last := 0
	for i in 12:
		d.tick()
		var n := d.monsters().size()
		assert_lte(n - last, 3, "at most 3 per tick")
		last = n
	assert_eq(d.monsters().size(), MonsterRules.MAX_PER_PLAYER)


func test_never_more_than_20_in_the_world() -> void:
	_players = [Vector3(0, FLOOR, 0), Vector3(300, FLOOR, 0), Vector3(0, FLOOR, 300)]
	var d := _director()
	for i in 30:
		d.tick()
	assert_eq(d.monsters().size(), MonsterRules.MAX_TOTAL)


func test_no_monsters_come_by_day() -> void:
	_time = DayCycle.NOON
	var d := _director()
	for i in 3:
		d.tick()
	assert_eq(d.monsters().size(), 0)


func test_never_near_a_lantern_or_a_home_bed() -> void:
	_light_everywhere = true
	var d := _director()
	for i in 3:
		d.tick()
	assert_eq(d.monsters().size(), 0, "a light near every spot")
	_light_everywhere = false
	_homes = []
	for a in 24:   # home beds all round the ring
		for r in [18.0, 24.0, 30.0, 36.0, 42.0]:
			_homes.append(Vector3i(Vector3(cos(a * TAU / 24) * r, FLOOR, sin(a * TAU / 24) * r)))
	for i in 3:
		d.tick()
	assert_eq(d.monsters().size(), 0, "home beds all round")


func test_levels_grow_far_from_the_world_spawn() -> void:
	_players = [Vector3(1000, FLOOR, 0)]
	var d := _director()
	for i in 4:
		d.tick()
	assert_gt(d.monsters().size(), 0)
	for m in d.monsters():
		assert_gte(m.level, 4, "about 1000 blocks out: level 5, one less at random")
	_players = [Vector3(0.5, FLOOR, 0.5)]
	var near := _director()
	for i in 4:
		near.tick()
	for m in near.monsters():
		assert_lte(m.level, 2, "near the spawn: level 1, one more at random")


# --- Sandbox (§12.15) ---

func test_sandbox_monsters_are_at_most_8_and_level_1_or_2() -> void:
	_players = [Vector3(1000, FLOOR, 0), Vector3(1300, FLOOR, 0)]
	var d := _director(true)
	for i in 20:
		d.tick()
	assert_eq(d.monsters().size(), MonsterRules.GENTLE_MAX)
	for m in d.monsters():
		assert_lte(m.level, MonsterRules.GENTLE_MAX_LEVEL)


func test_monsters_off_means_none_come_and_the_wild_ones_puff_away() -> void:
	var d := _director(true)
	d.tick()
	assert_gt(d.monsters().size(), 0)
	var summoned := d.summon(MonsterRules.GOBLIN, 1, _players[0])
	assert_eq(summoned, "")
	_on = false
	d.tick()
	assert_eq(d.monsters().size(), 1, "the wild ones puff away; a summoned one stays")
	assert_false(d.monsters()[0].wild)
	for i in 3:
		d.tick()
	assert_eq(d.monsters().size(), 1, "and no more come")


# --- Sunrise, far away ---

func test_at_sunrise_wild_monsters_puff_away_and_summoned_ones_stay() -> void:
	var d := _director()
	d.tick()
	d.tick()
	d.summon(MonsterRules.SLIME, 2, _players[0])
	var coins_before := d.coins().size()
	_time = DayCycle.SUNRISE
	d.tick()
	assert_eq(d.monsters().size(), 1)
	assert_false(d.monsters()[0].wild)
	assert_eq(d.coins().size(), coins_before, "a puff gives no gold")
	assert_eq(Profile.data.survivor_gold, 0)


func test_monsters_far_from_every_player_leave() -> void:
	var d := _director()
	d.tick()
	var m := d.monsters()[0]
	_players = [Vector3(500, FLOOR, 500)]
	d.tick()
	assert_true(m.is_queued_for_deletion())


# --- Defeats, coins, the slime split ---

func test_a_defeat_bursts_into_confetti_and_coins_worth_its_gold() -> void:
	var d := _director()
	d.summon(MonsterRules.GOBLIN, 2, _players[0])
	var g := d.monsters()[0]
	var bursts := get_tree().root.find_children("*", "CPUParticles3D", false, false).size()
	g.take_hit(100, _players[0], Vector3.ZERO)
	assert_gt(get_tree().root.find_children("*", "CPUParticles3D", false, false).size(), bursts, "confetti")
	var coins := d.coins()
	assert_eq(coins.size(), MonsterRules.MAX_COINS_PER_DEFEAT)
	var total := 0
	for c in coins:
		total += c.value
	assert_eq(total, MonsterRules.gold(MonsterRules.GOBLIN, 2), "6 gold in 5 coins")


func test_sandbox_defeats_give_confetti_but_no_coins() -> void:
	Game.mode = ModeRules.SANDBOX
	var d := _director(true)
	d.summon(MonsterRules.SLIME, 2, _players[0])
	var bursts := get_tree().root.find_children("*", "CPUParticles3D", false, false).size()
	d.monsters()[0].take_hit(100, _players[0], Vector3.ZERO)
	assert_gt(get_tree().root.find_children("*", "CPUParticles3D", false, false).size(), bursts, "confetti")
	assert_eq(d.coins().size(), 0)


func test_a_big_slime_splits_into_two_small_ones() -> void:
	var d := _director()
	d.summon(MonsterRules.SLIME, 3, _players[0])
	var big := d.monsters()[0]
	var where := big.global_position
	big.take_hit(100, _players[0], Vector3.ZERO)
	var small := d.monsters()
	assert_eq(small.size(), MonsterRules.SPLIT_COUNT)
	for s in small:
		assert_eq(s.kind, MonsterRules.SLIME)
		assert_eq(s.level, MonsterRules.SPLIT_LEVEL)
		assert_false(s.wild, "the children of a summoned slime are not wild either")
		assert_lt(s.global_position.distance_to(where), 1.0)
		s.take_hit(100, _players[0], Vector3.ZERO)
	assert_eq(d.monsters().size(), 0, "small slimes never split again")


func test_a_level_2_slime_does_not_split() -> void:
	var d := _director()
	d.summon(MonsterRules.SLIME, 2, _players[0])
	d.monsters()[0].take_hit(100, _players[0], Vector3.ZERO)
	assert_eq(d.monsters().size(), 0)


func test_a_coin_flies_to_the_nearest_player_within_2_blocks_and_gives_its_gold_once() -> void:
	var d := _director()
	var me := _player(Vector3(0.5, FLOOR, 0.5))
	_player(Vector3(5.5, FLOOR, 0.5), 7)
	await get_tree().physics_frame                # players join between frames
	var coin := d.spawn_coins(Vector3(0.9, FLOOR + 0.25, 0.5), 3)[0]
	var got: Array[int] = []   # lambdas capture locals by value: collect into an array
	coin.collected.connect(func(_c: Coin, peer: int) -> void: got.append(peer))
	for i in 90:
		if is_instance_valid(coin) and not coin.is_queued_for_deletion():
			coin._physics_process(DT)
	assert_eq(got, [me.peer_id] as Array[int], "the nearest player, once")
	assert_eq(Profile.data.survivor_gold, 1, "one gold for this coin, once")
	assert_eq(Session.gold_of(7), 0, "nothing for the other player")
	assert_true(coin.is_queued_for_deletion())


func test_a_coin_stays_while_nobody_is_within_2_blocks() -> void:
	var d := _director()
	_player(Vector3(8.5, FLOOR, 0.5))
	await get_tree().physics_frame
	var coin := d.spawn_coins(Vector3(1.5, FLOOR + 1.0, 0.5), 1)[0]
	for i in 90:
		coin._physics_process(DT)
	assert_eq(coin.collector, 0)
	assert_true(coin.is_landed(), "it lies on the ground")
	assert_almost_eq(coin.global_position.y, FLOOR + Coin.HOVER, 0.01)
	assert_eq(Profile.data.survivor_gold, 0)


func test_coins_are_capped() -> void:
	var d := _director()
	for i in 12:
		d.spawn_coins(Vector3(0.5, FLOOR + 2, 0.5), 5)
	await get_tree().process_frame
	assert_lte(d.coins().size(), MonsterDirector.MAX_COINS)


func test_coins_share_one_mesh() -> void:
	var d := _director()
	var list := d.spawn_coins(Vector3(0.5, FLOOR + 2, 0.5), 2)
	var a := list[0].find_children("*", "MeshInstance3D", true, false)
	var b := list[1].find_children("*", "MeshInstance3D", true, false)
	assert_eq(a.size(), 1)
	assert_same((a[0] as MeshInstance3D).mesh, (b[0] as MeshInstance3D).mesh)


# --- /summon ---

func test_summon_brings_a_monster_of_that_level_that_the_sun_leaves_alone() -> void:
	_time = DayCycle.NOON
	var d := _director()
	assert_eq(d.summon(MonsterRules.GOBLIN, 4, _players[0]), "")
	var g := d.monsters()[0]
	assert_eq(g.kind, MonsterRules.GOBLIN)
	assert_eq(g.level, 4)
	assert_false(g.wild)
	assert_between(Vector2(g.global_position.x - 0.5, g.global_position.z - 0.5).length(), 3.9, 6.0)
	d.tick()
	assert_eq(d.monsters().size(), 1, "still there in the day")


func test_summon_is_capped() -> void:
	var d := _director()
	for i in MonsterRules.MAX_TOTAL:
		d.summon(MonsterRules.SLIME, 1, _players[0])
	assert_eq(d.summon(MonsterRules.SLIME, 1, _players[0]), MonsterDirector.CROWDED_MESSAGE)
	assert_eq(d.monsters().size(), MonsterRules.MAX_TOTAL)


## M5 Task 6 (the whole-game review): LOW (M5 Task 3) keeps at most 6 monsters near a child on a weak phone, but owner
## #51's MOBS tab brings one a tap (/summon) up to the game's 20. On LOW a summon near a child who has 6 is refused with
## the same kind words; elsewhere, and on MEDIUM, the game's caps only.
func test_low_caps_what_a_summon_brings_near_a_child() -> void:
	var d := _director()
	d.apply_preset("low")
	for i in 6:
		assert_eq(d.summon(MonsterRules.SLIME, 1, _players[0]), "", "summon %d" % i)
	assert_eq(d.summon(MonsterRules.SLIME, 1, _players[0]), MonsterDirector.CROWDED_MESSAGE, "a 7th on a weak phone")
	assert_eq(d.monsters().size(), 6)
	assert_eq(d.summon(MonsterRules.GOBLIN, 1, Vector3(200.5, FLOOR, 0.5)), "", "far from them: another child's 6")
	d.apply_preset("medium")
	assert_eq(d.summon(MonsterRules.SLIME, 1, _players[0]), "", "MEDIUM: the game's caps")


# --- Lights near a spot: one bulk scan ---

func test_lanterns_and_light_blocks_are_found_in_a_copied_box() -> void:
	var buf := VoxelBuffer.new()
	buf.create(17, 17, 17)
	buf.fill(BlockIds.GRASS, VoxelBuffer.CHANNEL_TYPE)
	buf.set_voxel(BlockIds.LANTERN, 2, 3, 4, VoxelBuffer.CHANNEL_TYPE)
	buf.set_voxel(BlockIds.LIGHT, 16, 0, 9, VoxelBuffer.CHANNEL_TYPE)
	buf.set_voxel(BlockIds.LANTERN, 0, 16, 16, VoxelBuffer.CHANNEL_TYPE)
	var origin := Vector3i(100, -5, 40)
	var found := MonsterDirector.find_blocks(buf, origin, MonsterRules.LIGHT_BLOCKS)
	assert_eq(found.size(), 3)
	for cell in [Vector3i(2, 3, 4), Vector3i(16, 0, 9), Vector3i(0, 16, 16)]:
		assert_has(found, origin + cell)
	var air := VoxelBuffer.new()
	air.create(17, 17, 17)
	assert_eq(MonsterDirector.find_blocks(air, origin, MonsterRules.LIGHT_BLOCKS).size(), 0)


# --- Lead ruling: monsters never change blocks (a child's builds are safe) ---

## Stands in for the world and counts every change anybody makes to it.
class WatchedWorld:
	extends WorldService
	const GROUND := 10
	var edits := 0

	func get_block(pos: Vector3i) -> int:
		return BlockIds.GRASS if pos.y < GROUND or (pos.z == -3 and pos.y < GROUND + 3) else BlockIds.AIR

	func set_block(_pos: Vector3i, _id: int) -> void:
		edits += 1

	func is_editable(_pos: Vector3i) -> bool:
		return true


func test_monsters_never_change_blocks() -> void:
	var w := WatchedWorld.new()
	autofree(w)
	var before := Session.world
	Session.register_world(w)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(80, 1, 80)
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
	ground.global_position = Vector3(0, FLOOR - 0.5, 0)
	var d := _director()
	d.block_at = w.get_block
	var p := _player(Vector3(0.5, FLOOR, -5.5))   # behind a wall of blocks
	await get_tree().physics_frame
	for kind in MonsterRules.KINDS:
		for level in [1, 3, 5]:
			d.summon(kind, level, p.global_position)
	for i in 240:                                  # 4 s of chasing, hopping, swinging at the wall
		for m in d.monsters():
			m._physics_process(DT)
	for m in d.monsters():
		m.take_hit(100, p.global_position, Vector3(0, 2, 3))   # defeats, splits and coins
	for c in d.coins():
		c._physics_process(DT)
	_time = DayCycle.SUNRISE
	d.tick()
	Session.register_world(before)
	assert_eq(w.edits, 0, "no monster ever edits a block")
	for path in ["res://entities/monsters/monster.gd", "res://entities/monsters/monster_models.gd",
			"res://world/monster_director.gd", "res://entities/pickups/coin.gd", "res://core/rules/monster_rules.gd"]:
		var src := FileAccess.get_file_as_string(path)
		for call in ["set_block", "request_set_block", "set_voxel(", "do_box", "do_sphere"]:
			assert_false(src.contains(call), "%s never calls %s" % [path.get_file(), call])


## The sandbox gives the director every player's home bed from the SleepDirector.
func test_home_beds_come_from_the_sleep_director() -> void:
	var s := SleepDirector.new()
	autofree(s)
	assert_eq(s.home_beds(), [] as Array[Vector3i])
	s._homes = {1: Vector3i(1, 2, 3), 7: Vector3i(-4, 5, 6)}
	var beds := s.home_beds()
	assert_eq(beds.size(), 2)
	assert_has(beds, Vector3i(1, 2, 3))
	assert_has(beds, Vector3i(-4, 5, 6))


# --- Golden slimes (spec §12.16 #4) ---

## Caught: the player who hit it last gets the secret's reward (a pile of gold), never coins; it never
## splits.
func test_a_caught_golden_slime_gives_its_reward_to_the_catcher_not_coins() -> void:
	var d := _director()
	var caught: Array = []
	d.golden_caught = func(peer: int, pos: Vector3, id: String) -> void: caught.append([peer, id])
	var me := _player(_players[0], multiplayer.get_unique_id())
	await get_tree().physics_frame   # players join between frames
	var g := d.spawn_monster({"kind": MonsterRules.SLIME, "level": 3, "id": "gold1", "golden": true,
		"pos": _players[0] + Vector3(0, 0, -2), "wild": true, "universe": 1})
	g.take_hit(1000, me.global_position, Vector3.ZERO)
	assert_eq(caught, [[multiplayer.get_unique_id(), "gold1"]])
	assert_eq(d.coins().size(), 0, "the reward instead of coins")
	assert_eq(d.monsters().size(), 0, "a golden slime never splits")


func test_a_survivor_night_brings_a_golden_slime_now_and_then() -> void:
	var d := _director()
	var golden := 0
	for night in 60:
		_time = DayCycle.MIDNIGHT
		d.tick()
		for m in d.monsters():
			if m.golden:
				golden += 1
			m.queue_free()
		await get_tree().process_frame
	assert_gt(golden, 0, "some golden slimes over many spawns")

