extends GutTest
## M2 Task 4: weapons hit monsters through the CombatDirector (group "monsters", duck-typed
## take_hit(damage, from, knockback)), host-validated as before. Solo: this game is the host.

## Anything in the group "monsters" with take_hit is hittable (the Stone Golem, wave monsters...).
class FakeMonster:
	extends Node3D
	var hits: Array = []

	func take_hit(damage: int, from: Vector3, knockback: Vector3) -> void:
		hits.append([damage, from, knockback])


var director: CombatDirector
var _mode_before: StringName


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SURVIVOR
	director = CombatDirector.new()
	director.name = "Combat"
	add_child_autofree(director)
	director.block_at = func(p: Vector3i) -> int: return BlockIds.GRASS if p.y < 0 else BlockIds.AIR


func after_each() -> void:
	Game.mode = _mode_before


func _monster(kind: StringName, level: int, pos: Vector3, universe: int = 1) -> Monster:
	var m := Monster.new()
	m.setup({"kind": kind, "level": level, "id": "c_%s_%d" % [kind, level], "pos": pos, "yaw": 0.0, "wild": true,
		"universe": universe})
	m.block_at = director.block_at
	add_child_autofree(m)
	return m


func test_monsters_are_hittable() -> void:
	var g := _monster(MonsterRules.GOBLIN, 2, Vector3(0.5, 0, -1.5))
	var found := CombatDirector.hittables(get_tree()).filter(func(t: Dictionary) -> bool: return t.node == g)
	assert_eq(found.size(), 1)
	assert_eq(found[0].kind, WeaponRules.MONSTER)
	assert_almost_eq(found[0].pos, g.hit_center(), Vector3.ONE * 0.001)
	assert_eq(found[0].radius, g.hit_radius())


func test_a_sword_hurts_a_monster_in_front_and_pushes_it_away() -> void:
	var g := _monster(MonsterRules.GOBLIN, 2, Vector3(0.5, 0, -1.5))
	var hits := director.resolve_melee(Vector3(0.5, 1, 0.5), Vector3.FORWARD, ItemIds.SWORD)
	assert_eq(hits.size(), 1)
	assert_eq(g.hp, MonsterRules.hp(MonsterRules.GOBLIN, 2) - int(WeaponRules.stats(ItemIds.SWORD).damage))
	assert_lt(g.velocity.z, -3.0, "pushed away")


func test_a_monster_out_of_reach_or_behind_a_wall_is_not_hit() -> void:
	var far := _monster(MonsterRules.SLIME, 1, Vector3(0.5, 0, -7.5))
	director.resolve_melee(Vector3(0.5, 1, 0.5), Vector3.FORWARD, ItemIds.SWORD)
	assert_eq(far.hp, far.max_hp)
	var cells := {}
	for x in range(-2, 3):
		for y in range(0, 3):
			cells[Vector3i(x, y, -1)] = BlockIds.STONE
	director.block_at = func(p: Vector3i) -> int: return cells.get(p, BlockIds.GRASS if p.y < 0 else BlockIds.AIR)
	var hidden := _monster(MonsterRules.SLIME, 1, Vector3(0.5, 0, -2.0))
	director.resolve_melee(Vector3(0.5, 1, 0.5), Vector3.FORWARD, ItemIds.SWORD)
	assert_eq(hidden.hp, hidden.max_hp, "never through a wall")


func test_the_hammer_defeats_a_small_slime() -> void:
	var s := _monster(MonsterRules.SLIME, 1, Vector3(0.5, 0, -1.5))
	watch_signals(s)
	director.resolve_melee(Vector3(0.5, 1, 0.5), Vector3.FORWARD, ItemIds.HAMMER)
	assert_signal_emitted(s, "defeated")


func test_any_monster_with_take_hit_gets_the_damage_and_the_push() -> void:
	var fake := FakeMonster.new()
	fake.add_to_group(&"monsters")
	add_child_autofree(fake)
	fake.global_position = Vector3(0.5, 0.5, -1.5)
	director.resolve_melee(Vector3(0.5, 1, 0.5), Vector3.FORWARD, ItemIds.SWORD, 2)
	assert_eq(fake.hits.size(), 1)
	assert_eq(fake.hits[0][0], WeaponRules.damage_to(WeaponRules.MONSTER, ItemIds.SWORD, 2), "the spin finisher hits harder")
	assert_lt((fake.hits[0][2] as Vector3).z, 0.0)


func test_an_arrow_hurts_a_monster_and_is_gone() -> void:
	var g := _monster(MonsterRules.GOBLIN, 3, Vector3(0.5, 0, -5.5))
	var arrow := director.spawn_arrow(Vector3(0.5, g.hit_center().y, 0.5), Vector3(0, 0, -30), 1, 1.0)
	await wait_physics_frames(20)
	assert_eq(g.hp, g.max_hp - int(WeaponRules.stats(ItemIds.BOW).damage))
	assert_false(is_instance_valid(arrow) and not arrow.is_queued_for_deletion(), "no arrow stuck in a monster")


func test_the_boomerang_hurts_a_monster() -> void:
	var g := _monster(MonsterRules.GOBLIN, 3, Vector3(0.5, 0, -4.5), 3)   # owner #53: tough enough for its big hit
	director.spawn_boomerang(Vector3(0.5, g.hit_center().y, 0.5), Vector3.FORWARD, 1)
	await wait_physics_frames(30)
	assert_eq(g.hp, g.max_hp - int(WeaponRules.stats(ItemIds.BOOMERANG).damage))


## A tap on a monster with a weapon aims at the monster (not at the ground behind it).
func test_a_weapon_tap_on_a_monster_aims_at_it() -> void:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = Vector3(0.5, 0, 4.5)
	p.rig.process_mode = Node.PROCESS_MODE_DISABLED   # the test holds the camera still
	var g := _monster(MonsterRules.GOBLIN, 3, Vector3(0.5, 0, 0.5))
	var cam := p.camera()
	cam.global_position = Vector3(0.5, 1.2, 7.0)
	cam.look_at(g.hit_center())
	await get_tree().physics_frame
	var interactor := p.get_node("BlockInteractor") as BlockInteractor
	var center := cam.unproject_position(g.hit_center())
	assert_eq(interactor.hittable_at(center, 20.0), g)
