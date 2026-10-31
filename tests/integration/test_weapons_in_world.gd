extends GutTest
## Weapons in a world (M1b Task 11): cheap models, the item in the avatar's hand, practice
## targets, the host's hit resolution (reach, cooldown, knockback), arrows and the boomerang. Runs in
## solo mode (OfflineMultiplayerPeer), where this game is the host. Animals are hurt too since owner
## feedback #26 (test_animals_can_be_defeated.gd).

## Stands in for the lead's Animal (group "animals", knockback(impulse)).
class FakeAnimal:
	extends Node3D
	var pushes: Array[Vector3] = []

	func knockback(impulse: Vector3) -> void:
		pushes.append(impulse)


var director: CombatDirector


func before_each() -> void:
	director = CombatDirector.new()
	director.name = "Combat"
	add_child_autofree(director)
	director.block_at = func(p: Vector3i) -> int: return BlockIds.GRASS if p.y < 0 else BlockIds.AIR


func _animal(pos: Vector3) -> FakeAnimal:
	var a := FakeAnimal.new()
	a.add_to_group(&"animals")
	add_child_autofree(a)
	a.global_position = pos
	return a


## This game's own player (its pushes arrive as Session.knocked_back), standing still at `feet`.
func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)   # no world here: the body stays where the test puts it
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


## A wall (or water) of `id` at z = -1, x -2..2, y 0..2, in front of a swing from (0.5, 1, 0.5).
func _wall_of(id: int) -> Dictionary:
	var cells := {}
	for x in range(-2, 3):
		for y in range(0, 3):
			cells[Vector3i(x, y, -1)] = id
	director.block_at = func(p: Vector3i) -> int: return cells.get(p, BlockIds.GRASS if p.y < 0 else BlockIds.AIR)
	return cells


# --- Models ---

func test_every_weapon_and_target_is_one_cheap_mesh() -> void:
	for id in ItemIds.TOOLS:
		var m := WeaponModels.mesh_for(id) as ArrayMesh
		assert_not_null(m, ItemIds.display_name(id))
		if m == null:
			continue
		assert_eq(m.get_surface_count(), 1, "one draw call: %s" % ItemIds.display_name(id))
		assert_ne(m.surface_get_format(0) & Mesh.ARRAY_FORMAT_COLOR, 0, "vertex coloured: %s" % ItemIds.display_name(id))
		var size := m.get_aabb().size
		if ItemIds.is_target(id):
			assert_between(size.y, 1.2, 2.0, "about a player tall: %s" % ItemIds.display_name(id))
		else:
			assert_lt(maxf(size.x, maxf(size.y, size.z)), 1.3, "hand-sized: %s" % ItemIds.display_name(id))
	assert_null(WeaponModels.mesh_for(BlockIds.STONE))
	assert_null(WeaponModels.mesh_for(ItemIds.WAND))


## Godot draws clockwise triangles as front faces: seen from outside (along the vertex normal),
## every triangle must wind clockwise, or the faces vanish or look inside out.
func test_every_model_faces_outwards() -> void:
	assert_eq(_inside_out(BoxMesh.new().get_mesh_arrays()), 0, "the rule matches Godot's own BoxMesh")
	var meshes: Array[Mesh] = [WeaponModels.arrow()]
	for id in ItemIds.TOOLS:
		meshes.append(WeaponModels.mesh_for(id))
	for m in meshes:
		assert_eq(_inside_out(m.surface_get_arrays(0)), 0, "inside-out triangles in %s" % m.get_aabb())


## Triangles that wind counter-clockwise seen from outside (along their vertex normal).
func _inside_out(arrays: Array) -> int:
	var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var n: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var idx: Variant = arrays[Mesh.ARRAY_INDEX]
	var order: Array = Array(idx as PackedInt32Array) if idx != null and (idx as PackedInt32Array).size() > 0 else range(v.size())
	assert_gt(order.size(), 0)
	var wrong := 0
	for i in range(0, order.size(), 3):
		var a := v[order[i]]
		var face := (v[order[i + 1]] - a).cross(v[order[i + 2]] - a)
		if face.length() > 0.000001 and face.dot(n[order[i]]) > 0.0:
			wrong += 1
	return wrong


func test_the_arrow_tip_leads() -> void:
	var aabb := WeaponModels.arrow().get_aabb()
	assert_eq(WeaponModels.arrow().get_surface_count(), 1)
	assert_gt(aabb.position.z, -0.05, "the tip is at the origin, the shaft trails behind (+Z)")
	assert_gt(aabb.end.z, 0.6)


# --- The item in the hand ---

func test_the_held_weapon_hangs_in_the_avatars_hand() -> void:
	var avatar := BlockyAvatar.new()
	add_child_autofree(avatar)
	assert_not_null(avatar.hand())
	assert_eq(avatar.hand().get_parent(), avatar._right_arm, "at the end of the right arm")
	var held := HeldItem.new()
	avatar.hand().add_child(held)
	held.show_item(ItemIds.SWORD)
	assert_true(held.visible)
	assert_eq(held.find_children("*", "MeshInstance3D", true, false).size(), 1)
	held.show_item(BlockIds.STONE)
	assert_false(held.visible, "blocks are not held")


func test_an_attack_swings_the_arm_and_the_item_then_rests() -> void:
	var avatar := BlockyAvatar.new()
	add_child_autofree(avatar)
	var held := HeldItem.new()
	avatar.hand().add_child(held)
	held.show_item(ItemIds.HAMMER)
	avatar.play_attack(ItemIds.HAMMER)
	held.play_attack(ItemIds.HAMMER, 0, true)
	var highest := 0.0
	var item_moved := false
	for i in 14:
		await wait_seconds(0.05)
		avatar.animate(0.0, true, 0.05)
		highest = maxf(highest, avatar._right_arm.rotation.x)
		item_moved = item_moved or absf(held.rotation.x) > 0.2
	assert_gt(highest, 2.0, "the hammer goes up over the head")
	assert_true(item_moved, "the wrist moves too")
	await wait_seconds(0.4)
	avatar.animate(0.0, true, 0.05)
	assert_almost_eq(avatar._right_arm.rotation.z, 0.0, 0.01, "back to rest")
	assert_lt(avatar._right_arm.rotation.x, 0.5)


func test_drawing_the_bow_raises_both_arms() -> void:
	var avatar := BlockyAvatar.new()
	add_child_autofree(avatar)
	avatar.set_aiming(true)
	for i in 20:
		avatar.animate(0.0, true, 0.05)
	assert_almost_eq(avatar._right_arm.rotation.x, BlockyAvatar.AIM_ANGLE, 0.05)
	assert_almost_eq(avatar._left_arm.rotation.x, BlockyAvatar.AIM_ANGLE, 0.05)
	avatar.set_aiming(false)
	for i in 20:
		avatar.animate(0.0, true, 0.05)
	assert_lt(absf(avatar._right_arm.rotation.x), 0.1)


func test_players_sync_what_they_hold() -> void:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	add_child_autofree(p)
	var cfg := (p.get_node("Sync") as MultiplayerSynchronizer).replication_config
	assert_true(cfg.has_property(NodePath(".:held_item")))
	p.held_item = ItemIds.BOW
	p._process(0.016)
	var held := p.avatar.hand().get_child(0) as HeldItem
	assert_not_null(held)
	assert_eq(held.item_id, ItemIds.BOW)


# --- Practice targets ---

func test_a_dummy_is_cheap_and_wobbles_with_a_hit_number() -> void:
	var t := director.spawn_target(ItemIds.DUMMY, Vector3(0.5, 0, 0.5), 0.0)
	assert_true(t is PracticeDummy)
	assert_true(t.is_in_group(&"targets"))
	assert_eq(t.collision_layer, PracticeTarget.LAYER)
	assert_eq(t.collision_mask, 0, "never collides with the terrain")
	assert_eq(t.find_children("*", "MeshInstance3D", true, false).size(), 1)
	var shapes := t.find_children("*", "CollisionShape3D", true, false)
	assert_eq(shapes.size(), 1)
	var box := (shapes[0] as CollisionShape3D).shape as BoxShape3D
	assert_lte(maxf(box.size.x, box.size.z), 0.8, "small footprint")
	var labels_before := get_tree().root.find_children("*", "Label3D", false, false).size()
	t.show_hit(4, Vector3(0.5, 1, -3))
	assert_eq(t.last_damage, 4)
	assert_eq(get_tree().root.find_children("*", "Label3D", false, false).size(), labels_before + 1, "a floating number")
	await wait_seconds(0.05)
	assert_ne(t._visual.rotation, Vector3.ZERO, "it wobbles")


func test_melee_hits_a_dummy_in_front_but_not_one_out_of_reach() -> void:
	var near := director.spawn_target(ItemIds.DUMMY, Vector3(0.5, 0, -1.5), PI)
	var far := director.spawn_target(ItemIds.DUMMY, Vector3(0.5, 0, -9.5), PI)
	var behind := director.spawn_target(ItemIds.DUMMY, Vector3(0.5, 0, 2.5), 0.0)
	var hits := director.resolve_melee(Vector3(0.5, 1, 0.5), Vector3.FORWARD, ItemIds.SWORD)
	assert_eq(hits.size(), 1)
	assert_eq(near.hits_taken, 1)
	assert_eq(near.last_damage, int(WeaponRules.stats(ItemIds.SWORD).damage))
	assert_eq(far.hits_taken, 0, "out of reach")
	assert_eq(behind.hits_taken, 0, "behind")


## Owner feedback #26 overrules M1b's "never hurt": animals take the damage too (a real Animal's
## take_hit, test_animals_can_be_defeated.gd); one without take_hit is still pushed.
func test_animals_are_pushed_back() -> void:
	var cow := _animal(Vector3(0.5, 0, -1.5))
	var hits := director.resolve_melee(Vector3(0.5, 1, 0.5), Vector3.FORWARD, ItemIds.HAMMER)
	assert_eq(hits.size(), 1)
	assert_eq(cow.pushes.size(), 1)
	assert_lt(cow.pushes[0].z, -5.0, "pushed away")
	assert_gt(cow.pushes[0].y, 0.0)
	assert_gt(WeaponRules.damage_to(hits[0].kind, ItemIds.HAMMER), 0, "and hurt (owner feedback #26)")
	var plain := Node3D.new()                     # an animal without knockback: nothing breaks
	plain.add_to_group(&"animals")
	add_child_autofree(plain)
	plain.global_position = Vector3(0.5, 0, -1.0)
	director.resolve_melee(Vector3(0.5, 1, 0.5), Vector3.FORWARD, ItemIds.SWORD)
	assert_eq(cow.pushes.size(), 2)


func test_a_far_animal_is_out_of_reach() -> void:
	var cow := _animal(Vector3(0.5, 0, -6.5))
	assert_eq(director.resolve_melee(Vector3(0.5, 1, 0.5), Vector3.FORWARD, ItemIds.HAMMER).size(), 0)
	assert_eq(cow.pushes.size(), 0)


## Review M10: a swing never reaches through a wall: not a dummy, an animal or a player behind it.
func test_melee_never_hits_through_a_wall() -> void:
	var wall := _wall_of(BlockIds.STONE)
	var dummy := director.spawn_target(ItemIds.DUMMY, Vector3(0.5, 0, -1.5), PI)
	var cow := _animal(Vector3(1.5, 0, -1.8))
	_player(Vector3(-0.5, 0, -1.8))
	watch_signals(Session)
	assert_eq(director.resolve_melee(Vector3(0.5, 1, 0.5), Vector3.FORWARD, ItemIds.HAMMER).size(), 0)
	assert_eq(dummy.hits_taken, 0)
	assert_eq(cow.pushes.size(), 0)
	assert_signal_not_emitted(Session, "knocked_back")
	wall.clear()   # the same swing without the wall reaches all three
	assert_eq(director.resolve_melee(Vector3(0.5, 1, 0.5), Vector3.FORWARD, ItemIds.HAMMER).size(), 3)
	assert_eq(dummy.hits_taken, 1)
	assert_eq(cow.pushes.size(), 1)
	assert_signal_emitted(Session, "knocked_back")


func test_water_never_blocks_a_swing() -> void:
	_wall_of(BlockIds.WATER)
	var dummy := director.spawn_target(ItemIds.DUMMY, Vector3(0.5, 0, -1.5), PI)
	var cow := _animal(Vector3(1.5, 0, -1.8))
	assert_eq(director.resolve_melee(Vector3(0.5, 1, 0.5), Vector3.FORWARD, ItemIds.HAMMER).size(), 2)
	assert_eq(dummy.hits_taken, 1)
	assert_eq(cow.pushes.size(), 1)


## Something behind a wall must not take the swing's only hit, nor pull its aim away from a
## target in the open. The axe hits one thing within 30° of its aim; aim assist pulls the swing
## onto whatever is closest to the aim within 35°.
func test_a_hidden_animal_never_steals_the_swing() -> void:
	var pillar := {}
	for y in range(0, 3):
		pillar[Vector3i(0, y, -1)] = BlockIds.STONE
	director.block_at = func(p: Vector3i) -> int: return pillar.get(p, BlockIds.GRASS if p.y < 0 else BlockIds.AIR)
	var origin := Vector3(1.0, 1.0, 0.5)   # on a cell edge: the pillar hides only the left side
	var left := Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(15.0))
	var right := Vector3.FORWARD.rotated(Vector3.UP, deg_to_rad(-20.0))
	var cow := _animal(Vector3(origin.x, 0, origin.z) + left * 1.8)            # closer to the aim
	var dummy := director.spawn_target(ItemIds.DUMMY, Vector3(origin.x, 0, origin.z) + right * 2.0, PI)
	var hits := director.resolve_melee(origin, Vector3.FORWARD, ItemIds.AXE)
	assert_eq(cow.pushes.size(), 0, "hidden behind the pillar")
	assert_eq(dummy.hits_taken, 1, "the swing goes to the dummy in the open")
	assert_eq(hits.size(), 1)


func test_targets_are_saved_and_restored() -> void:
	director.spawn_target(ItemIds.DUMMY, Vector3(3.5, 2, 4.5), 1.0)
	director.spawn_target(ItemIds.BULLSEYE, Vector3(-2.5, 3, 0.5), 2.0)
	var m := WorldMeta.new_random()
	m.targets = director.to_save()
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.targets.size(), 2)
	var other := CombatDirector.new()
	other.name = "Combat2"
	add_child_autofree(other)
	other.restore(back.targets)
	var restored := other.targets()
	assert_eq(restored.size(), 2)
	assert_true(restored[0] is PracticeDummy)
	assert_true(restored[1] is Bullseye)
	assert_almost_eq(restored[0].global_position, Vector3(3.5, 2, 4.5), Vector3.ONE * 0.001)
	assert_almost_eq(restored[1].rotation.y, 2.0, 0.001)


## Review I1: the yaw comes from a LAN message; a NaN one must not reach the save.
func test_host_ignores_a_non_finite_target_yaw() -> void:
	var t := director.spawn_target(ItemIds.DUMMY, Vector3(3.5, 2, 4.5), NAN)
	assert_true(is_finite(t.rotation.y), "the target stands straight")
	var m := WorldMeta.new_random()
	m.targets = director.to_save()
	assert_eq(JSON.new().parse(m.to_json()), OK, "the save stays valid JSON")


# --- Arrows and the boomerang ---

func test_an_arrow_in_the_gold_scores_10() -> void:
	var b := director.spawn_target(ItemIds.BULLSEYE, Vector3(0.5, 0, -12.5), PI) as Bullseye
	assert_almost_eq(b.face_normal(), Vector3(0, 0, 1), Vector3.ONE * 0.001, "faces the archer")
	var from := Vector3(0.5, 1.6, 0.5)
	var dir := WeaponRules.launch_direction(from, b.center(), WeaponRules.ARROW_SPEED)
	var arrow := director.spawn_arrow(from, dir * WeaponRules.ARROW_SPEED, 1, 1.0)
	await wait_physics_frames(40)
	assert_eq(b.last_score, 10)
	assert_true(is_instance_valid(arrow) and arrow.stuck, "the arrow sticks in the target")


func test_an_arrow_sticks_into_the_ground() -> void:
	var arrow := director.spawn_arrow(Vector3(0.5, 3, 0.5), Vector3(8, 2, 0), 1, 0.5)
	await wait_physics_frames(60)
	assert_true(arrow.stuck)
	assert_true(arrow.in_block)
	assert_lt(arrow.global_position.y, 0.01)
	assert_gt(arrow.global_position.x, 2.0, "after an arc")


func test_an_arrow_bonks_an_animal_and_is_gone() -> void:
	var cow := _animal(Vector3(0.5, 1.2, -6.5))
	cow.position = Vector3(0.5, 1.2 - CombatDirector.ANIMAL_CENTER, -6.5)
	var arrow := director.spawn_arrow(Vector3(0.5, 1.2, 0.5), Vector3(0, 0, -30), 1, 1.0)
	await wait_physics_frames(20)
	assert_eq(cow.pushes.size(), 1, "pushed")
	assert_false(is_instance_valid(arrow) and not arrow.is_queued_for_deletion(), "no arrow stuck in an animal")


func test_the_boomerang_hits_a_dummy_once_and_comes_back() -> void:
	var dummy := director.spawn_target(ItemIds.DUMMY, Vector3(0.5, 0, -4.5), PI)
	var b := director.spawn_boomerang(Vector3(0.5, 1.15, 0.5), Vector3.FORWARD, 1)
	assert_eq(director.boomerang_of(1), b, "one boomerang in the air per player")
	await wait_physics_frames(150)
	assert_eq(dummy.hits_taken, 1, "hit on the way out, not again on the way back")
	assert_null(director.boomerang_of(1), "caught")


## The weapons smoke run's miss, in a test: the thrower stands one block above the dummy.
func test_the_boomerang_hits_a_dummy_below_the_thrower() -> void:
	var dummy := director.spawn_target(ItemIds.DUMMY, Vector3(0.5, 0, -3.5), PI)
	var origin := Vector3(0.5, 2.15, 0.5)
	director.spawn_boomerang(origin, dummy.center() - origin, 1)
	await wait_physics_frames(150)
	assert_eq(dummy.hits_taken, 1, "aimed at the dummy below: it hits")


# --- The host's checks ---

func test_host_rejects_attacks_faster_than_the_cooldown() -> void:
	var peer := 770001
	assert_true(Session.accept_attack(peer, ItemIds.SWORD, Vector3.FORWARD, 1.0, 10000))
	assert_false(Session.accept_attack(peer, ItemIds.SWORD, Vector3.FORWARD, 1.0, 10050), "too fast")
	assert_true(Session.accept_attack(peer, ItemIds.SWORD, Vector3.FORWARD, 1.0, 10350))
	assert_false(Session.accept_attack(peer, ItemIds.HAMMER, Vector3.FORWARD, 1.0, 10400), "a swing just happened")
	assert_false(Session.accept_attack(peer + 1, BlockIds.STONE, Vector3.FORWARD, 1.0, 10000), "not a weapon")
	assert_false(Session.accept_attack(peer + 1, ItemIds.SWORD, Vector3.ZERO, 1.0, 10000), "no aim")
	assert_false(Session.accept_attack(peer + 1, ItemIds.BOW, Vector3.FORWARD, NAN, 10000), "bad draw")
	Session._last_attack.erase(peer)
	Session._last_attack.erase(peer + 1)


func test_only_accepted_attacks_reach_the_director() -> void:
	watch_signals(Session)
	var peer := 770005
	Session._host_attack(peer, ItemIds.SWORD, Vector3(0, 0, -2), 1.0)
	Session._host_attack(peer, ItemIds.SWORD, Vector3(0, 0, -2), 1.0)
	assert_signal_emit_count(Session, "attack_requested", 1)
	assert_signal_emitted_with_parameters(Session, "attack_requested", [peer, ItemIds.SWORD, Vector3(0, 0, -1), 1.0])
	Session._last_attack.erase(peer)
