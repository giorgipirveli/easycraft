extends GutTest
## Owner feedback #39 (spec §14.2a): the Dragon Realm's void. A player who falls off an island is carried back by the
## wind to the last spot it stood on (never lost: no knock-out, no damage, nothing dropped); in a world without a
## void nothing changes. On the host a VoidWatch sends monsters that fall into the void puffing away, and brings
## animals, pets, bot friends and living buddies back next to their child (or the world spawn).


## An island (sky grass on floatstone, its top at y 50) over x, z in -10..10; everything else is the void.
class IslandWorld:
	extends WorldService
	var void_below := true
	var removed := {}

	func get_block(p: Vector3i) -> int:
		if removed.has(p) or absi(p.x) > 10 or absi(p.z) > 10 or p.y >= 50 or p.y < 40:
			return BlockIds.AIR
		return BlockIds.SKY_GRASS if p.y == 49 else BlockIds.FLOATSTONE

	func surface_height(x: int, z: int) -> int:
		return 50 if absi(x) <= 10 and absi(z) <= 10 else DragonShape.VOID_HEIGHT

	func is_area_ready(_center: Vector3) -> bool:
		return true

	func is_editable(_pos: Vector3i) -> bool:
		return true

	func spawn_column() -> Vector2i:
		return Vector2i.ZERO

	func descriptor() -> Object:
		return load("res://world/universes/dragon.gd").new() if void_below else null

	func generator_shape() -> MeadowsShape:
		return DragonShape.new(1)


var _world: IslandWorld
var _player: Player
var _carried: Array = []


func _setup(void_below: bool = true) -> void:
	_world = IslandWorld.new()
	_world.void_below = void_below
	add_child_autofree(_world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(21, 10, 21)
	shape.shape = box
	shape.position = Vector3(0.5, 45, 0.5)   # the island's rock: y 40..50, x and z -10..11
	ground.add_child(shape)
	_world.add_child(ground)
	_player = load("res://entities/player/player.tscn").instantiate()
	_player.name = str(multiplayer.get_unique_id())
	_player.world = _world
	add_child_autofree(_player)
	_carried.clear()
	_player.carried_back.connect(func(to: Vector3) -> void: _carried.append(to))


func _stand(at: Vector3) -> void:
	_player.spawn_at(at)
	await wait_until(func() -> bool: return _player.is_spawned(), 3.0, "spawned")
	await wait_physics_frames(3)


func test_a_player_who_falls_off_is_carried_back_to_the_island() -> void:
	_setup()
	await _stand(Vector3(0.5, 50.0, 0.5))
	_player.global_position = Vector3(6.5, 50.05, 2.5)   # walks to the edge side of the island
	await wait_seconds(0.7)
	var hp := _player.health.hp
	_player.global_position = Vector3(16.5, 50.5, 2.5)   # steps off into the void
	_player.velocity = Vector3.ZERO
	await wait_until(func() -> bool: return not _carried.is_empty(), 6.0, "the wind carries it back")
	assert_eq(_carried.size(), 1, "once")
	var to: Vector3 = _carried[0]
	assert_almost_eq(Vector2(to.x, to.z), Vector2(6.5, 2.5), Vector2(0.6, 0.6), "back where it last stood")
	await wait_until(func() -> bool: return _player.is_spawned(), 3.0, "standing again")
	await wait_physics_frames(3)
	assert_gt(_player.global_position.y, 49.0, "on the island, not in the void")
	assert_lt(Vector2(_player.global_position.x, _player.global_position.z).distance_to(Vector2(6.5, 2.5)), 1.0)
	assert_eq(_player.health.hp, hp, "no damage")
	assert_false(_player.knocked_out, "no knock-out")


func test_a_broken_floor_carries_it_to_the_island_ground_instead() -> void:
	_setup()
	await _stand(Vector3(3.5, 50.0, 3.5))
	await wait_seconds(0.6)
	_world.removed[Vector3i(3, 49, 3)] = true   # the block it stood on is gone (dug away)
	_player.global_position = Vector3(30.5, 45.0, 30.5)
	await wait_until(func() -> bool: return not _carried.is_empty(), 6.0, "carried back")
	var to: Vector3 = _carried[0]
	assert_true(is_nan(to.y), "onto that column's ground: %s" % to)
	assert_eq(Vector2(to.x, to.z), Vector2(3.5, 3.5))


func test_without_a_void_nothing_carries_a_faller_back() -> void:
	_setup(false)
	await _stand(Vector3(0.5, 50.0, 0.5))
	await wait_seconds(0.6)
	_player.global_position = Vector3(20.5, DragonRules.RESCUE_Y + 1.0, 0.5)
	await wait_seconds(0.6)
	assert_eq(_carried.size(), 0, "Green Meadows keeps its old rule (the world's bottom)")
	assert_lt(_player.global_position.y, DragonRules.RESCUE_Y, "it kept falling")


# --- The host's VoidWatch ---------------------------------------------------------------------------------

class Body:
	extends Node3D
	var velocity := Vector3(1, -30, 0)
	var peer := 0


func _body(at: Vector3, peer: int = 0) -> Body:
	var b := Body.new()
	add_child_autofree(b)
	b.global_position = at
	b.peer = peer
	return b


func test_the_void_watch_puffs_monsters_and_brings_friends_back() -> void:
	var monster := _body(Vector3(40, DragonRules.RESCUE_Y - 2.0, 0))
	var high_monster := _body(Vector3(40, 60, 0))
	var pet := _body(Vector3(50, DragonRules.RESCUE_Y - 5.0, 0), 7)
	var stray := _body(Vector3(-50, DragonRules.RESCUE_Y - 1.0, 9))
	var fine := _body(Vector3(0, 55, 0), 7)
	var puffed: Array = []
	var w := VoidWatch.new()
	w.monsters = func() -> Array: return [monster, high_monster]
	w.puff = func(m: Node3D) -> void: puffed.append(m)
	w.friends = func() -> Array: return [pet, stray, fine]
	w.child_of = func(b: Node3D) -> Vector3:
		return Vector3(3.5, 50.0, 3.5) if (b as Body).peer == 7 else Vector3.INF
	w.spawn_feet = func() -> Vector3: return Vector3(0.5, 56.0, 0.5)
	add_child_autofree(w)
	w.set_physics_process(false)
	assert_eq(w.check(), 3, "one monster, two friends")
	assert_eq(puffed, [monster], "the fallen monster puffs away, the other stays")
	assert_almost_eq(Vector2(pet.global_position.x, pet.global_position.z).distance_to(Vector2(3.5, 3.5)), 1.8, 0.8,
		"the pet lands beside its child")
	assert_eq(pet.global_position.y, 51.0)
	assert_eq(pet.velocity, Vector3.ZERO)
	assert_almost_eq(Vector2(stray.global_position.x, stray.global_position.z).distance_to(Vector2(0.5, 0.5)), 1.8, 0.8,
		"a friend without a child: by the world spawn")
	assert_eq(fine.global_position, Vector3(0, 55, 0), "one on an island stays where it is")
	assert_eq(w.check(), 1, "the monster the test did not free is still below (the director frees it for real)")
