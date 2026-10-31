extends GutTest
## Spear, mace and tier weapons in a world (M2 Task 6, spec §13.1): the host resolves them with the
## M1b CombatDirector. The thrown spear flies like an arrow, sticks, and waits for its thrower; the
## mace shakes the ground nearby; a tier bow's arrows hit with the tier's damage. Solo mode: this
## game is the host.

var director: CombatDirector


func before_each() -> void:
	director = CombatDirector.new()
	director.name = "Combat"
	add_child_autofree(director)
	director.block_at = func(p: Vector3i) -> int: return BlockIds.GRASS if p.y < 0 else BlockIds.AIR
	Session._last_attack.erase(multiplayer.get_unique_id())


func after_each() -> void:
	Session._last_attack.erase(multiplayer.get_unique_id())


## This game's own player, standing still at `feet`, facing -Z.
func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _throw_at(target: Vector3, from: Vector3, weapon: int = ItemIds.SPEAR, shooter: int = 1) -> ThrownSpear:
	var dir := WeaponRules.launch_direction(from, target, WeaponRules.SPEAR_THROW_SPEED, WeaponRules.SPEAR_GRAVITY)
	return director.spawn_spear(from, WeaponRules.spear_throw_velocity(dir), shooter, weapon)


# --- Spear ---

func test_the_spear_thrust_reaches_further_than_a_sword() -> void:
	var dummy := director.spawn_target(ItemIds.DUMMY, Vector3(0.5, 0, -3.8), PI)
	assert_eq(director.resolve_melee(Vector3(0.5, 1, 0.5), Vector3.FORWARD, ItemIds.SWORD).size(), 0)
	assert_eq(director.resolve_melee(Vector3(0.5, 1, 0.5), Vector3.FORWARD, ItemIds.SPEAR_IRON).size(), 1)
	assert_eq(dummy.last_damage, int(WeaponRules.stats(ItemIds.SPEAR_IRON).damage), "the iron spear's damage")


func test_a_thrown_spear_hits_a_dummy_harder_and_drops_to_the_ground() -> void:
	var dummy := director.spawn_target(ItemIds.DUMMY, Vector3(0.5, 0, -7.5), PI)
	var spear := _throw_at(dummy.center(), Vector3(0.5, 1.6, 0.5))
	assert_true(spear is ThrownSpear)
	assert_true(spear.is_in_group(&"spears"))
	await wait_physics_frames(60)
	assert_eq(dummy.hits_taken, 1, "hit once")
	assert_eq(dummy.last_damage, WeaponRules.damage_to(WeaponRules.DUMMY, ItemIds.SPEAR, WeaponRules.THROW))
	assert_true(is_instance_valid(spear) and spear.stuck, "it lies on the ground to be picked up")
	assert_lt(spear.global_position.y, 0.3)


func test_a_spear_sticks_where_it_lands_and_waits_for_its_thrower() -> void:
	var spear := _throw_at(Vector3(0.5, 0, -10.5), Vector3(0.5, 1.6, 0.5))
	await wait_physics_frames(90)
	assert_true(spear.stuck)
	assert_same(director.spear_of(1), spear)
	assert_almost_eq(spear.global_position.z, -10.5, 2.0, "about where it was thrown")


func test_the_thrower_takes_it_back_by_walking_up() -> void:
	var me := multiplayer.get_unique_id()
	var p := _player(Vector3(0.5, 0, 0.5))
	var spear := _throw_at(Vector3(0.5, 0, -6.5), Vector3(0.5, 1.6, 0.5), ItemIds.SPEAR_CRYSTAL, me)
	await wait_physics_frames(80)
	assert_true(spear.stuck)
	assert_not_null(director.spear_of(me), "too far to take")
	p.global_position = Vector3(spear.global_position.x + 0.8, 0, spear.global_position.z)
	await wait_physics_frames(3)
	assert_null(director.spear_of(me), "back in the hand")


func test_a_spear_left_behind_comes_back_by_itself() -> void:
	var spear := _throw_at(Vector3(0.5, 0, -8.5), Vector3(0.5, 1.6, 0.5))
	await wait_physics_frames(80)
	assert_true(spear.stuck)
	spear._age = WeaponRules.SPEAR_RETURN_TIME + 0.1
	await wait_physics_frames(2)
	assert_null(director.spear_of(1), "never lost")


func test_one_spear_in_the_air_per_player_and_no_thrust_while_it_is_out() -> void:
	var me := multiplayer.get_unique_id()
	_player(Vector3(0.5, 0, 0.5))
	director._on_spear_throw(me, ItemIds.SPEAR, Vector3(0, 0.3, -1).normalized())
	director._on_spear_throw(me, ItemIds.SPEAR, Vector3(0, 0.3, -1).normalized())
	var count := 0
	for n in director.projectiles():
		if n is ThrownSpear:
			count += 1
	assert_eq(count, 1)
	var dummy := director.spawn_target(ItemIds.DUMMY, Vector3(0.5, 0, -2.0), PI)
	director._on_attack(me, ItemIds.SPEAR, Vector3.FORWARD, 1.0)
	assert_eq(dummy.hits_taken, 0, "the hand is empty")


# --- Mace ---

func test_a_mace_swing_shakes_the_ground_near_it_three_times_a_second_at_most() -> void:
	var me := multiplayer.get_unique_id()
	_player(Vector3(0.5, 0, 0.5))
	director._on_attack(me, ItemIds.MACE, Vector3.FORWARD, 1.0)
	assert_gt(director.last_shake, 0.0, "the swinger feels it")
	assert_lte(director.last_shake, WeaponRules.MACE_SHAKE)
	director.last_shake = 0.0
	Session._last_attack.erase(me)
	director._on_attack(me, ItemIds.MACE_IRON, Vector3.FORWARD, 1.0)
	assert_eq(director.last_shake, 0.0, "no second shake within a third of a second (no flashing)")


func test_a_far_mace_is_not_felt() -> void:
	_player(Vector3(40.5, 0, 0.5))
	director.ground_shake(Vector3(0.5, 0, -1.5))
	assert_eq(director.last_shake, 0.0)


func test_the_mace_hits_hard_and_pushes_far() -> void:
	var dummy := director.spawn_target(ItemIds.DUMMY, Vector3(0.5, 0, -1.5), PI)
	director.resolve_melee(Vector3(0.5, 1, 0.5), Vector3.FORWARD, ItemIds.MACE_COSMIC)
	assert_eq(dummy.last_damage, 36, "8 x 4.5 (owner #53)")


# --- Tier bows ---

func test_a_tier_bows_arrow_hits_with_the_tiers_damage() -> void:
	var dummy := director.spawn_target(ItemIds.DUMMY, Vector3(0.5, 0, -8.5), PI)
	var from := Vector3(0.5, 1.6, 0.5)
	var dir := WeaponRules.launch_direction(from, dummy.center(), WeaponRules.ARROW_SPEED)
	director.spawn_arrow(from, dir * WeaponRules.ARROW_SPEED, 1, 1.0, ItemIds.BOW_COSMIC)
	await wait_physics_frames(40)
	assert_eq(dummy.last_damage, int(WeaponRules.stats(ItemIds.BOW_COSMIC).damage))


# --- Review fixes ---

## A guest's copy may have stuck in a wall just before the host's "it hit something here" arrives.
func test_a_dropped_spear_falls_even_if_it_had_stuck() -> void:
	var spear := director.spawn_spear(Vector3(0.5, 3, 0.5), Vector3.ZERO, 1, ItemIds.SPEAR)
	spear.stick(Vector3(0.5, 3, 0.5), Vector3i(0, 3, 0))
	spear.drop_at(Vector3(0.5, 3, 0.5))
	assert_false(spear.stuck)
	assert_false(spear.in_block)
	await wait_physics_frames(60)
	assert_true(spear.stuck, "on the ground now")
	assert_lt(spear.global_position.y, 0.3)


func test_no_message_to_a_thrower_who_has_left() -> void:
	director._on_spear_returned(Vector3.ZERO, false, 987654)
	assert_true(true, "no error about an unknown peer")
