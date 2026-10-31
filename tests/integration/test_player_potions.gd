extends GutTest
## Potions and shields on the player (M2 Task 6): Moon Jump, Speed and Invisibility change this
## player's movement and look; the held spear hides while it flies; the carried shield is synced.


func _player() -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)   # no world here: the test moves the body itself
	p.viewer.free()
	p._spawned = true
	return p


func test_drinking_starts_a_potion_once() -> void:
	var p := _player()
	assert_true(p.drink(ItemIds.POTION_SPEED))
	assert_true(p.potions.is_active(ItemIds.POTION_SPEED))
	assert_false(p.drink(ItemIds.POTION_SPEED), "still working")
	assert_false(p.drink(ItemIds.SWORD), "not a potion")


func test_speed_potion_walks_one_and_a_half_times_as_fast() -> void:
	var p := _player()
	p._move_normal(1.0, Vector3(1, 0, 0))
	var normal := p.velocity.x
	assert_almost_eq(normal, Player.WALK_SPEED, 0.001)
	p.velocity = Vector3.ZERO
	p.drink(ItemIds.POTION_SPEED)
	p._move_normal(1.0, Vector3(1, 0, 0))
	assert_almost_eq(p.velocity.x, normal * 1.5, 0.001)


func test_moon_jump_jumps_1_8_times_as_high() -> void:
	var p := _player()
	p._jumps.press_jump()
	p._move_normal(0.016, Vector3.ZERO)
	var normal := p.velocity.y
	assert_almost_eq(normal, Player.JUMP_VELOCITY, 0.001)
	p.velocity = Vector3.ZERO
	p._jumps.reset()
	p.drink(ItemIds.POTION_JUMP)
	p._jumps.press_jump()
	p._move_normal(0.016, Vector3.ZERO)
	var height_ratio := (p.velocity.y * p.velocity.y) / (normal * normal)
	assert_almost_eq(height_ratio, 1.8, 0.001, "height grows with the square of the take-off speed")


func test_an_invisible_player_is_see_through_until_it_wears_off() -> void:
	var p := _player()
	var parts := p.avatar.find_children("*", "GeometryInstance3D", true, false)
	assert_gt(parts.size(), 0)
	assert_false(p.is_invisible())
	assert_eq(p.invisible_until, 0.0)
	p.drink(ItemIds.POTION_INVIS)
	p._process(0.016)
	assert_true(p.is_invisible(), "stealth (Task 5) reads this")
	assert_between(p.invisible_until - Time.get_ticks_msec() / 1000.0, 29.0, 30.01)
	for g in parts:
		assert_same((g as GeometryInstance3D).material_override, Player.ghost_material())
	p.potions.tick(30.5)
	p._process(0.016)
	assert_false(p.is_invisible())
	for g in parts:
		assert_null((g as GeometryInstance3D).material_override, "back to normal")


func test_the_held_item_goes_see_through_and_back_to_its_tier() -> void:
	var p := _player()
	p.held_item = ItemIds.SWORD_IRON
	p._process(0.016)
	var mesh := p._held.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D
	assert_same(mesh.material_override, WeaponModels.tier_material(WeaponRules.TIER_IRON))
	p.drink(ItemIds.POTION_INVIS)
	p._process(0.016)
	assert_same(mesh.material_override, Player.ghost_material())
	p.potions.tick(31.0)
	p._process(0.016)
	assert_same(mesh.material_override, WeaponModels.tier_material(WeaponRules.TIER_IRON))


func test_a_thrown_spear_leaves_the_hand_empty() -> void:
	var p := _player()
	p.held_item = ItemIds.SPEAR_STONE
	p._process(0.016)
	assert_true(p._held.visible)
	var spear := ThrownSpear.new()
	spear.setup({"id": "Spear1", "origin": Vector3.ZERO, "velocity": Vector3.ZERO, "shooter": p.peer_id, "weapon": ItemIds.SPEAR_STONE})
	spear.set_physics_process(false)
	add_child_autofree(spear)
	assert_true(p.spear_out())
	p._process(0.016)
	p._held._process(0.016)
	assert_false(p._held.visible, "the spear is out there")
	spear.queue_free()
	await wait_frames(2)
	assert_false(p.spear_out())


func test_the_carried_shield_is_synced() -> void:
	var p := _player()
	var cfg := (p.get_node("Sync") as MultiplayerSynchronizer).replication_config
	assert_true(cfg.has_property(NodePath(".:carried_shield")))
