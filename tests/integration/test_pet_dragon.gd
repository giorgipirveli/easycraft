extends GutTest
## Owner feedback #39 (spec §14.2a): the pet dragon. On the ground it follows its child like any pet; when the child
## is up in the air it flies beside them, and lands when they land. A dragon egg in a nest hatches (a tap, the host
## decides: within reach, once per world) into the tapper's pet dragon; the Sky Dragon's baby dragon comes from the
## profile into every world like Pip, and is never saved with the world's pets.


class FloorWorld:
	extends WorldService
	const GROUND := 10

	func get_block(p: Vector3i) -> int:
		return BlockIds.STONE if p.y < GROUND else BlockIds.AIR

	func surface_height(_x: int, _z: int) -> int:
		return GROUND

	func is_area_ready(_center: Vector3) -> bool:
		return true


const DT := 1.0 / 60.0

var world: FloorWorld
var _told: Array = []
var _spawned: Array[Dictionary] = []


func before_each() -> void:
	_told = []
	_spawned = []


func _world() -> void:
	world = FloorWorld.new()
	add_child_autofree(world)
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 10, 400)
	shape.shape = box
	shape.position = Vector3(0, FloorWorld.GROUND - 5, 0)
	ground.add_child(shape)
	world.add_child(ground)


func _child(pos: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = pos
	return p


func _dragon(pos: Vector3, owner: int) -> Animal:
	var a := Animal.new()
	a.setup({"species": PetRules.DRAGON, "id": "t_dragon", "pos": pos, "yaw": 0.0, "owner": owner, "name": "Ember"})
	a.world = world
	add_child_autofree(a)
	a.set_physics_process(false)
	return a


func _steps(a: Animal, n: int) -> void:
	for i in n:
		a._physics_process(DT)


func test_it_takes_off_to_fly_beside_its_child_up_in_the_air_and_lands_with_them() -> void:
	_world()
	var me := _child(Vector3(0.5, FloorWorld.GROUND + 8.0, 0.5))    # flying 8 blocks up
	var a := _dragon(Vector3(3.5, FloorWorld.GROUND, 0.5), me.peer_id)
	await get_tree().physics_frame
	_steps(a, 120)
	assert_true(a.gliding, "it flies")
	assert_lt(a.global_position.distance_to(me.global_position), 3.0, "beside its child (%.1f)" % a.global_position.distance_to(me.global_position))
	me.global_position = Vector3(0.5, FloorWorld.GROUND, 0.5)       # the child lands
	await get_tree().physics_frame
	_steps(a, 150)
	assert_false(a.gliding, "it lands too")
	assert_lt(absf(a.global_position.y - FloorWorld.GROUND), 0.6, "back on the ground")


func test_a_small_jump_is_no_flight_and_other_pets_never_fly() -> void:
	_world()
	var me := _child(Vector3(0.5, FloorWorld.GROUND + 0.8, 0.5))
	var a := _dragon(Vector3(2.5, FloorWorld.GROUND, 0.5), me.peer_id)
	var dog := Animal.new()
	dog.setup({"species": &"dog", "id": "t_dog", "pos": Vector3(-2.5, FloorWorld.GROUND, 0.5), "owner": me.peer_id, "name": "Rex"})
	dog.world = world
	add_child_autofree(dog)
	dog.set_physics_process(false)
	await get_tree().physics_frame
	_steps(a, 20)
	assert_false(a.gliding, "a hop is no flight")
	me.global_position.y = FloorWorld.GROUND + 8.0
	await get_tree().physics_frame
	for i in 60:
		dog._physics_process(DT)
	assert_false(dog.gliding, "a dog never flies")
	assert_lt(dog.global_position.y, FloorWorld.GROUND + 1.5)


func test_a_sitting_dragon_stays_put() -> void:
	_world()
	var me := _child(Vector3(0.5, FloorWorld.GROUND + 8.0, 0.5))
	var a := _dragon(Vector3(3.5, FloorWorld.GROUND, 0.5), me.peer_id)
	a.sitting = true
	await get_tree().physics_frame
	_steps(a, 60)
	assert_false(a.gliding)


# --- The dragon egg ---

func _nest() -> DragonNests:
	var n := DragonNests.new()
	n.name = "DragonNests"
	n.tell = func(peer: int, text: String) -> void: _told.append([peer, text])
	n.spawn = func(data: Dictionary) -> Animal:
		_spawned.append(data)
		return null
	n.state = SecretState.new()
	add_child_autofree(n)
	return n


func _egg(n: DragonNests, at: Vector3) -> DragonEgg:
	var e := DragonEgg.new()
	e.setup({"id": "egg_island_1_2_4", "pos": at, "secret": "island_1_2_4"})
	add_child_autofree(e)
	n.eggs = func(egg_name: String) -> DragonEgg: return e if egg_name == String(e.name) else null
	return e


func test_a_tap_within_reach_hatches_the_egg_into_the_tappers_pet_dragon_once() -> void:
	var n := _nest()
	var me := _child(Vector3(0.5, 20, 0.5))
	var e := _egg(n, Vector3(2.5, 20, 0.5))
	await get_tree().physics_frame
	n.hatch(me.peer_id, String(e.name))
	assert_eq(_spawned.size(), 1, "a dragon hatched")
	assert_eq(StringName(_spawned[0].species), PetRules.DRAGON)
	assert_eq(int(_spawned[0].owner), me.peer_id, "the tapper's pet")
	assert_eq(str(_spawned[0].id), "dragon_island_1_2_4", "one id per nest: saved with the world's pets")
	assert_true(n.state.opened.has("egg_island_1_2_4"), "remembered: never again in this world")
	assert_eq(_told.size(), 1)
	assert_true(str(_told[0][1]).contains("hatched"), str(_told[0][1]))
	n.hatch(me.peer_id, String(e.name))
	assert_eq(_spawned.size(), 1, "an egg hatches once")


func test_an_egg_out_of_reach_waits() -> void:
	var n := _nest()
	var me := _child(Vector3(0.5, 20, 0.5))
	var e := _egg(n, Vector3(30.5, 20, 0.5))
	await get_tree().physics_frame
	n.hatch(me.peer_id, String(e.name))
	assert_eq(_spawned, [] as Array[Dictionary])
	assert_eq(_told, [[me.peer_id, "Come closer to the egg!"]])


func test_a_hatched_nest_has_no_egg_again() -> void:
	var state := SecretState.new()
	var nest := {"id": "island_1_2_4", "egg": Vector3i(3, 50, 3)}
	assert_true(DragonNests.has_egg(nest, state))
	state.opened["egg_island_1_2_4"] = true
	assert_false(DragonNests.has_egg(nest, state))
	assert_false(DragonNests.has_egg({"id": "island_1_2_5"}, SecretState.new()), "a nest without an egg cell")


func test_the_egg_is_a_tap_box_and_asks_the_host() -> void:
	var e := DragonEgg.new()
	e.setup({"id": "egg_x", "pos": Vector3(1, 2, 3), "secret": "x"})
	add_child_autofree(e)
	assert_eq(e.collision_layer, SecretThing.LAYER, "only tap rays find it")
	assert_true(e.has_method(&"use_tap"))
	assert_lte(e.find_children("*", "MeshInstance3D", true, false).size(), 2, "one shared egg mesh (and its glow)")


# --- The Sky Dragon's baby dragon ---

func test_the_baby_dragon_comes_from_the_profile_and_is_never_saved_with_the_world() -> void:
	var d := PetDirector.new()
	d.name = "Pets"
	add_child_autofree(d)
	var got: Array[Dictionary] = []
	d.spawn = func(data: Dictionary) -> Animal:
		got.append(data)
		return null
	var me := _child(Vector3(0.5, 20, 0.5))
	await get_tree().physics_frame
	d.on_baby_dragon(me.peer_id, PetRules.baby_dragon_record())
	assert_eq(got.size(), 1)
	assert_eq(StringName(got[0].species), PetRules.DRAGON)
	assert_eq(str(got[0].id), "babydragon_%d" % me.peer_id)
	assert_eq(str(got[0].name), "Ember")
	assert_true(PetDirector.is_profile_pet("babydragon_%d" % me.peer_id), "the profile's: not the world's")
	assert_false(PetDirector.is_profile_pet("dragon_island_1_2_4"), "a hatched dragon is the world's")
	d.on_baby_dragon(me.peer_id, {})
	assert_eq(got.size(), 1, "no record, no dragon")


func test_beating_the_sky_dragon_gives_a_baby_dragon_and_a_dragon_crystal_once() -> void:
	var p := ProfileData.new()
	var words := Session.dragon_gift_apply(p)
	assert_false(p.baby_dragon.is_empty(), "a baby dragon")
	assert_eq(p.crystal_gifts, [5] as Array[int], "a Dragon Crystal to hand over")
	assert_true(words.contains("baby dragon"), words)
	Session.dragon_gift_apply(p)
	assert_eq(p.crystal_gifts, [5, 5] as Array[int], "another win, another crystal")
	assert_eq(str(p.baby_dragon.name), PetRules.BABY_DRAGON_NAME, "one baby dragon")
