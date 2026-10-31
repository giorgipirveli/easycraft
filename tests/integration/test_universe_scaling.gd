extends GutTest
## M3 Task 5 (spec §14.1, §5.1, §4.3): in universe u the gold a wave, the boss and Tilly pay, the prices
## she asks, the cost of flying and the monsters' health and hits are all × 2^(u−1); the boss of
## universe u opens universe u + 1.

const FLOOR := 10
const TOTEM := Vector3(0.5, FLOOR, 0.5)
const ME := 1

var _mode_before: StringName
var _universe_before := 1
var _gold_before := 0
var _unlocked_before := 1
var _paid: Array = []
var _inventions_before: InventionData


func before_each() -> void:
	_mode_before = Game.mode
	_universe_before = Game.universe
	_gold_before = Profile.data.survivor_gold
	_unlocked_before = Profile.data.universe_unlocked
	Game.mode = ModeRules.SURVIVOR
	Game.universe = 2
	_paid = []
	_inventions_before = Profile.data.inventions
	Profile.data.inventions = InventionData.invented_to(InventionLine.PLANE)   # owner #78: flying needs a machine


func after_each() -> void:
	Game.mode = _mode_before
	Game.universe = _universe_before
	Profile.data.survivor_gold = _gold_before
	Profile.data.universe_unlocked = _unlocked_before
	Profile.data.inventions = _inventions_before
	Session.survivor_reset()
	Session.fly_reset()
	Music.reset()


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()


func _flat(p: Vector3i) -> int:
	return BlockIds.GRASS if p.y < FLOOR else BlockIds.AIR


func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


# --- Monsters ---

func test_a_monster_of_universe_2_has_twice_the_health_and_hits_twice_as_hard() -> void:
	var md := MonsterDirector.new()
	md.name = "Monsters"
	md.block_at = _flat
	md.universe = Game.universe
	add_child_autofree(md)
	var m := md.spawn_monster({"kind": MonsterRules.GOBLIN, "level": 1, "id": "g1", "pos": TOTEM, "yaw": 0.0,
		"wild": false, "universe": md.universe})
	assert_eq(m.max_hp, 2 * MonsterRules.hp(MonsterRules.GOBLIN, 1))
	assert_eq(MonsterRules.hit(MonsterRules.GOBLIN, 1, m.universe), 2 * MonsterRules.hit(MonsterRules.GOBLIN, 1))
	assert_eq(MonsterRules.gold(MonsterRules.GOBLIN, 1, m.universe), 2 * MonsterRules.gold(MonsterRules.GOBLIN, 1))


# --- Waves ---

func test_a_won_wave_in_universe_2_pays_twice_the_gold() -> void:
	var md := MonsterDirector.new()
	md.name = "Monsters"
	md.block_at = _flat
	add_child_autofree(md)
	var w := WaveDirector.new()
	w.name = "Waves"
	w.monsters = md
	w.universe = 2
	w.player_peers = func() -> Array[int]: return [ME] as Array[int]
	w.stand_spot = func(x: int, z: int) -> Vector3: return Vector3(x + 0.5, FLOOR, z + 0.5)
	w.is_ready = func(_p: Vector3) -> bool: return true
	w.eye_of = func(_peer: int) -> Vector3: return TOTEM + Vector3(0, 1.6, -3)
	w.pay = func(peer: int, gold: int) -> void: _paid.append([peer, gold])
	w.tell = func(_peer: int, _text: String) -> void: pass
	w.monsters_allowed = func() -> bool: return true
	w.rng.seed = 20260924
	add_child_autofree(w)
	w.set_process(false)
	w.place_totem(TOTEM, 0.0)
	w.next_wave = 2
	assert_eq(w.request_start(ME, 2), &"")
	for i in roundi((WaveRules.COUNTDOWN + 3.1) / WaveDirector.TICK):
		w.advance(WaveDirector.TICK)
	for i in 10:
		for m in w.wave_monsters():
			m.take_hit(100000, m.global_position, Vector3.ZERO)
	for i in 4:
		w.advance(WaveDirector.TICK)
	assert_eq(_paid, [[ME, 40]], "10 × N × 2")


# --- The boss ---

func test_the_boss_of_universe_2_pays_twice_and_opens_universe_3() -> void:
	Profile.data.universe_unlocked = 2
	_player(TOTEM + Vector3(2, 0, 0))
	await get_tree().physics_frame
	var d := BossDirector.new()
	d.name = "Boss"
	d.block_at = _flat
	d.pay_gold = func(peer: int, amount: int) -> void: _paid.append([peer, amount])
	d.celebrate = func() -> void: pass
	add_child_autofree(d)
	assert_eq(d.start(TOTEM), "")
	var g := d.golem()
	g.start_phase(BossRules.Phase.WALK)
	g.take_hit(1000000, g.global_position + Vector3(0, 1, 3), Vector3.ZERO)
	assert_eq(_paid, [[multiplayer.get_unique_id(), 600]], "300 × 2")
	assert_eq(Profile.data.universe_unlocked, 3, "the next universe opens")


func test_the_golem_of_green_meadows_still_opens_universe_2() -> void:
	Game.universe = 1
	Profile.data.universe_unlocked = 1
	_player(TOTEM + Vector3(2, 0, 0))
	await get_tree().physics_frame
	var d := BossDirector.new()
	d.name = "Boss"
	d.block_at = _flat
	d.pay_gold = func(peer: int, amount: int) -> void: _paid.append([peer, amount])
	d.celebrate = func() -> void: pass
	add_child_autofree(d)
	d.start(TOTEM)
	var g := d.golem()
	g.start_phase(BossRules.Phase.WALK)
	g.take_hit(1000000, g.global_position + Vector3(0, 1, 3), Vector3.ZERO)
	assert_eq(_paid, [[multiplayer.get_unique_id(), 300]])
	assert_eq(Profile.data.universe_unlocked, 2)


# --- Tilly and flying ---

func test_tilly_asks_twice_the_price_in_universe_2() -> void:
	var me := _player(Vector3(10.5, 30, 1.5))
	var tilly := Node3D.new()
	tilly.add_to_group(&"traders")
	add_child_autofree(tilly)
	tilly.global_position = Vector3(10.5, 30, 4.5)
	Session.set_inventory(me.peer_id, Inventory.new())
	Profile.data.survivor_gold = 30
	var r := Session.host_trade(me.peer_id, true, BlockIds.LANTERN, 1)
	assert_true(r.ok)
	assert_eq(r.gold, 10)
	assert_eq(Profile.data.survivor_gold, 20)
	Session.inventory_of(me.peer_id).add(BlockIds.DIAMOND, 1)
	Session.host_trade(me.peer_id, false, BlockIds.DIAMOND, 1)
	assert_eq(Profile.data.survivor_gold, 60, "a diamond sells for 40 in the desert")


func test_flying_costs_twice_as_much_in_universe_2() -> void:
	var me := _player(Vector3(0.5, 30, 0.5))
	Profile.data.survivor_gold = 10
	me.set_physics_mode(PhysicsMode.Mode.FLY)
	Session.fly_tick(0.016)
	assert_eq(Profile.data.survivor_gold, 8, "the first 6 s cost 2")
	Session.fly_tick(6.0)
	assert_eq(Profile.data.survivor_gold, 6)


func test_taking_off_needs_the_universes_price() -> void:
	assert_false(FlyCost.can_take_off(false, 1, 2), "1 gold is not enough in the desert")
	assert_true(FlyCost.can_take_off(false, 2, 2))
	assert_true(FlyCost.can_take_off(true, 0, 4), "Sandbox flies free")
	assert_eq(FlyCost.refused_message(1), FlyCost.REFUSED_MESSAGE)
	assert_true(FlyCost.refused_message(2).contains("20 gold a minute"))
