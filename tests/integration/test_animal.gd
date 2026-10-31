extends GutTest
## Animal entities (one mesh each, small collision, pets with name tags) and the host-side
## AnimalDirector (spawn near players up to the cap, despawn far wild animals, never duplicates).


func _data(species: StringName, owner: int = 0) -> Dictionary:
	return {"species": species, "id": "t_%s" % species, "pos": Vector3(1, 40, 2), "yaw": 0.0,
		"owner": owner, "name": "Biscuit" if owner != 0 else "", "sitting": false}


func test_every_species_builds_one_mesh_and_a_small_body() -> void:
	for sp: StringName in AnimalRules.SPECIES:
		var a := Animal.new()
		a.setup(_data(sp))
		add_child_autofree(a)
		assert_lte(a.find_children("*", "MeshInstance3D", true, false).size(), 2,
			"%s: at most two draw calls, the body and its wagging tail or bobbing head" % sp)
		var shapes := a.find_children("*", "CollisionShape3D", false, false)
		assert_eq(shapes.size(), 1)
		var box := (shapes[0] as CollisionShape3D).shape as BoxShape3D
		assert_lte(maxf(box.size.x, box.size.z), 1.0, "%s footprint stays small" % sp)
		assert_eq(a.find_children("*", "Label3D", true, false).size(), 0, "wild animals have no name tag")


func test_the_same_species_shares_one_mesh() -> void:
	var a := Animal.new()
	a.setup(_data(&"sheep"))
	add_child_autofree(a)
	var b := Animal.new()
	b.setup(_data(&"sheep"))
	add_child_autofree(b)
	var ma := (a.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
	var mb := (b.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh
	assert_same(ma, mb)


func test_three_quick_pets_tame_a_dog_for_that_player() -> void:
	var a := Animal.new()
	a.setup(_data(&"dog"))
	add_child_autofree(a)
	assert_false(a.pet_tap(7, 1.0, 0))
	assert_false(a.pet_tap(7, 1.5, 0))
	assert_true(a.pet_tap(7, 2.0, 0), "tamed on the third pet")
	assert_eq(a.owner_peer, 7)
	assert_true(a.is_pet())
	assert_ne(a.pet_name, "")
	assert_eq(a.find_children("*", "Label3D", true, false).size(), 1, "a name tag appears")


func test_cows_and_full_pet_owners_cannot_tame() -> void:
	var cow := Animal.new()
	cow.setup(_data(&"cow"))
	add_child_autofree(cow)
	for t in 5:
		cow.pet_tap(7, t * 0.2, 0)
	assert_false(cow.is_pet())
	var dog := Animal.new()
	dog.setup(_data(&"dog"))
	add_child_autofree(dog)
	for t in 5:
		dog.pet_tap(7, t * 0.2, AnimalRules.MAX_PETS)
	assert_false(dog.is_pet(), "already has 3 pets")


func test_the_owner_tapping_a_pet_makes_it_sit_and_stand() -> void:
	var a := Animal.new()
	a.setup(_data(&"cat", 7))
	add_child_autofree(a)
	a.pet_tap(7, 1.0, 1)
	assert_true(a.sitting)
	a.pet_tap(7, 5.0, 1)
	assert_false(a.sitting)
	a.pet_tap(9, 9.0, 0)
	assert_false(a.sitting, "only the owner gives commands")


func test_pet_save_round_trip() -> void:
	var a := Animal.new()
	a.setup(_data(&"dog", 1))
	add_child_autofree(a)
	var saved := a.to_save()
	assert_eq(saved.species, "dog")
	assert_eq(saved.name, "Biscuit")
	assert_eq(saved.id, "t_dog")
	assert_eq((saved.pos as Array).size(), 3)


# --- AnimalDirector ---

var _spawned: Array[Dictionary] = []
var _container: Node3D


func _director(players: Array[Vector3], ready := true) -> AnimalDirector:
	_spawned.clear()
	_container = Node3D.new()
	add_child_autofree(_container)
	var d := AnimalDirector.new()
	d.shape = MeadowsShape.new(12345)
	d.container = _container
	d.player_positions = func() -> Array[Vector3]: return players
	d.is_ready = func(_p: Vector3) -> bool: return ready
	d.spawn = func(data: Dictionary) -> void:
		_spawned.append(data)
		var a := Animal.new()
		a.setup(data)
		_container.add_child(a)
	add_child_autofree(d)
	return d


func test_director_fills_up_to_the_cap_around_a_player() -> void:
	var land := MeadowsShape.new(12345).spawn_column()
	var d := _director([Vector3(land.x, 40, land.y)] as Array[Vector3])
	for i in 5:
		d.tick()
	assert_gt(_spawned.size(), 0, "animals appear")
	assert_lte(_container.get_child_count(), AnimalRules.MAX_PER_PLAYER)
	var ids := {}
	for s in _spawned:
		assert_false(ids.has(s.id), "never spawns the same animal twice")
		ids[s.id] = true


## Emulator frame spikes (M1b acceptance run 1): the first tick built up to 20 animals in one frame
## (8-11 ms on the desktop). A few per tick fill the area over some seconds instead.
func test_director_spawns_only_a_few_animals_per_tick() -> void:
	var land := MeadowsShape.new(12345).spawn_column()
	var d := _director([Vector3(land.x, 40, land.y)] as Array[Vector3])
	d.tick()
	assert_between(_spawned.size(), 1, AnimalDirector.MAX_SPAWNS_PER_TICK, "a few at a time")
	for i in 20:
		d.tick()
	assert_gt(_spawned.size(), AnimalDirector.MAX_SPAWNS_PER_TICK, "and the area still fills up")
	assert_lte(_container.get_child_count(), AnimalRules.MAX_PER_PLAYER)


## The frame spikes (2026-09-30): a tick worked out its new areas' herds and built its animals in one frame (world 41: an
## area 3-6 ms on this PC, an animal 3-5 ms; ticks of 9-19 ms, a phone 3-5x, often in the same frame as the terrain's
## collision). In a world (one_a_frame) the tick only queues them and each frame does one piece (step): the next
## animal, else the next area.
func test_in_a_world_the_tick_s_work_comes_one_piece_a_frame() -> void:
	var land := MeadowsShape.new(12345).spawn_column()
	var at := Vector3(land.x, 40, land.y)
	var d := _director([at] as Array[Vector3])
	d.one_a_frame = true
	d.set_process(false)   # the frames by hand
	d.tick()
	assert_eq(d.known_areas().size(), 0, "no herd worked out in the tick's frame")
	assert_eq(d.areas_queued(), AnimalDirector.NEW_AREAS_PER_TICK, "the nearest areas queued")
	for i in AnimalDirector.NEW_AREAS_PER_TICK:
		d.step()
		assert_eq(d.known_areas().size(), i + 1, "one area a frame")
	assert_eq(d.known_areas(), AnimalDirector.areas_near(at).slice(0, AnimalDirector.NEW_AREAS_PER_TICK), "nearest first")
	for i in 20:   # ticks, each followed by its frames, until animals are queued
		d.tick()
		if d.queued() > 0:
			break
		while d.areas_queued() > 0:
			d.step()
	var queued := d.queued()
	assert_between(queued, 1, AnimalDirector.MAX_SPAWNS_PER_TICK)
	assert_eq(_spawned.size(), 0, "queued, none built in the tick's frame")
	var areas := d.known_areas().size()
	for i in queued:
		d.step()
		assert_eq(_spawned.size(), i + 1, "one animal a frame")
		assert_eq(d.known_areas().size(), areas, "the animals before the areas")
	d.tick()
	d.tick()   # a tick before the queue is built never queues the same animal again
	while d.queued() > 0 or d.areas_queued() > 0:
		d.step()
	var ids := {}
	for s in _spawned:
		assert_false(ids.has(s.id), "never the same animal twice")
		ids[s.id] = true


## M7 (the browser's freezes): working out an area's herd reads the terrain's rules (about 1 ms here, several times
## that on a phone), and the first tick near a child worked out all ~16 areas in reach at once (17 ms here). A few
## new areas a tick, the nearest first; a few ticks later every area in reach is known.
func test_director_works_out_a_few_new_areas_per_tick_nearest_first() -> void:
	var land := MeadowsShape.new(12345).spawn_column()
	var at := Vector3(land.x, 40, land.y)
	var d := _director([at] as Array[Vector3])
	var nearest := AnimalDirector.areas_near(at)
	assert_gt(nearest.size(), AnimalDirector.NEW_AREAS_PER_TICK)
	for i in nearest.size() - 1:
		var a := Vector2(nearest[i] * AnimalRules.CELL) + Vector2.ONE * AnimalRules.CELL * 0.5
		var b := Vector2(nearest[i + 1] * AnimalRules.CELL) + Vector2.ONE * AnimalRules.CELL * 0.5
		assert_lte(a.distance_to(Vector2(at.x, at.z)), b.distance_to(Vector2(at.x, at.z)), "nearest first")
	d.tick()
	assert_eq(d.known_areas(), nearest.slice(0, AnimalDirector.NEW_AREAS_PER_TICK))
	for i in ceili(nearest.size() / float(AnimalDirector.NEW_AREAS_PER_TICK)):
		d.tick()
	assert_eq(d.known_areas().size(), nearest.size(), "every area in reach, a few ticks later")


func test_director_waits_for_the_terrain() -> void:
	var land := MeadowsShape.new(12345).spawn_column()
	var d := _director([Vector3(land.x, 40, land.y)] as Array[Vector3], false)
	d.tick()
	assert_eq(_spawned.size(), 0)


func test_director_removes_far_wild_animals_but_keeps_pets() -> void:
	var d := _director([Vector3.ZERO] as Array[Vector3], false)
	var wild := Animal.new()
	wild.setup({"species": &"pig", "id": "far", "pos": Vector3(0, 30, 500), "yaw": 0.0, "owner": 0, "name": "", "sitting": false})
	_container.add_child(wild)
	var pet := Animal.new()
	pet.setup({"species": &"dog", "id": "pet", "pos": Vector3(0, 30, 600), "yaw": 0.0, "owner": 1, "name": "Rex", "sitting": false})
	_container.add_child(pet)
	d.tick()
	assert_true(wild.is_queued_for_deletion())
	assert_false(pet.is_queued_for_deletion())


# --- Spec §3b details (review M11): idle animations, collars, looking at players ---

func test_idle_dogs_wag_and_idle_pigs_bob_their_heads() -> void:
	for sp: StringName in [&"dog", &"cat", &"pig", &"cow", &"sheep", &"chicken"]:
		var a := Animal.new()
		a.setup(_data(sp))
		add_child_autofree(a)
		var part := a.find_child("Part", true, false) as Node3D
		assert_not_null(part, "%s has a moving part" % sp)
		a._process(0.1)
		var before := part.rotation
		a._process(0.13)
		assert_ne(part.rotation, before, "%s moves it while standing" % sp)


func test_a_pet_wears_a_collar_in_its_owners_colour() -> void:
	var wild := Animal.new()
	wild.setup(_data(&"dog"))
	add_child_autofree(wild)
	assert_null(wild.find_child("Collar", true, false), "wild dogs have no collar")
	for sp: StringName in [&"dog", &"cat"]:
		var pet := Animal.new()
		pet.setup(_data(sp, 7))
		add_child_autofree(pet)
		var collar := pet.find_child("Collar", true, false) as MeshInstance3D
		assert_not_null(collar, "%s pet wears a collar" % sp)
		var mat := collar.material_override as StandardMaterial3D
		assert_eq(mat.albedo_color, AnimalRules.collar_color(7), "in its owner's colour")
	wild.pet_tap(9, 1.0, 0)
	wild.pet_tap(9, 1.5, 0)
	wild.pet_tap(9, 2.0, 0)
	wild._process(0.016)
	assert_not_null(wild.find_child("Collar", true, false), "a newly tamed dog gets its collar")


# --- Simulation cost (M1b acceptance run 1: animals made frames of up to 150 ms) ---

func _world() -> WorldService:
	var w: WorldService = load("res://world/world.tscn").instantiate()
	w.setup("", 42)
	add_child_autofree(w)
	return w


func _player_at(w: WorldService, pos: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = "1"
	p.world = w
	add_child_autofree(p)
	p.viewer.free()   # no terrain streaming in these tests
	p.global_position = pos
	return p


func _steps(a: Animal, n: int) -> void:
	for i in n:
		a._physics_process(1.0 / 60.0)


func test_a_wild_animal_far_from_every_player_rests() -> void:
	var w := _world()
	var a := Animal.new()
	a.setup(_data(&"sheep"))   # at (1, 40, 2) over unloaded terrain: a simulated animal falls
	a.world = w
	add_child_autofree(a)
	_steps(a, 30)
	assert_eq(a.global_position, Vector3(1, 40, 2), "nobody near: it rests and costs nothing")
	_player_at(w, Vector3(6, 40, 2))
	await get_tree().physics_frame   # players join between frames
	_steps(a, 30)
	assert_lt(a.global_position.y, 40.0, "a player close by: it is simulated again (and falls here)")


func test_a_standing_animal_keeps_still_and_falls_when_its_floor_goes() -> void:
	var w := _world()
	_player_at(w, Vector3(6, 40, 2))
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20, 1, 20)
	shape.shape = box
	ground.add_child(shape)
	add_child_autofree(ground)
	ground.global_position = Vector3(1, 39.5, 2)
	var a := Animal.new()
	a.setup(_data(&"sheep"))
	a.world = w
	add_child_autofree(a)
	await get_tree().physics_frame
	_steps(a, 90)
	var rest := a.global_position
	assert_almost_eq(rest.y, 40.0, 0.05, "stands on the ground")
	_steps(a, 60)
	assert_almost_eq(a.global_position, rest, Vector3.ONE * 0.001, "and keeps still")
	ground.free()
	await get_tree().physics_frame
	_steps(a, 30)
	assert_lt(a.global_position.y, rest.y - 0.2, "the floor dug away: it drops")

# --- Review M8: owner, name and sitting are synced on change ---

func test_owner_name_and_sitting_are_sent_only_when_they_change() -> void:
	var a := Animal.new()
	a.setup(_data(&"dog", 7))
	add_child_autofree(a)
	var cfg := (a.get_node("Sync") as MultiplayerSynchronizer).replication_config
	for prop: String in [".:owner_peer", ".:pet_name", ".:sitting"]:
		assert_eq(cfg.property_get_replication_mode(NodePath(prop)), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE, prop)
		assert_true(cfg.property_get_spawn(NodePath(prop)), "%s arrives with the spawn" % prop)
	for prop: String in [".:position", ".:rotation"]:
		assert_eq(cfg.property_get_replication_mode(NodePath(prop)), SceneReplicationConfig.REPLICATION_MODE_ALWAYS, prop)


# --- Review M12: a guest's pets when the guest leaves (host side) ---

## Stone below GROUND, air above. The test sets the world spawn and whether the ground there is
## loaded yet.
class FlatWorld:
	extends WorldService
	const GROUND := 10
	var spawn := Vector2i(4, -3)
	var loaded := true

	func get_block(pos: Vector3i) -> int:
		return BlockIds.STONE if pos.y < GROUND else BlockIds.AIR

	func spawn_column() -> Vector2i:
		return spawn

	func surface_height(_x: int, _z: int) -> int:
		return GROUND - 1

	func find_standing_y(_x: int, _z: int) -> int:
		return GROUND

	func is_area_ready(_center: Vector3) -> bool:
		return loaded


const GONE := 99                  # an owner id that no player in the game has (the guest left)


func _flat_world() -> FlatWorld:
	var w := FlatWorld.new()
	autofree(w)
	return w


## A remote player (peer `peer`) standing at `pos`, as the host sees a guest.
func _player(peer: int, pos: Vector3 = Vector3(0, FlatWorld.GROUND, 0)) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.viewer.free()
	p._spawned = true
	p.global_position = pos
	return p


func _animal_in(w: WorldService, species: StringName, owner: int, pos: Vector3, id: String = "") -> Animal:
	var a := Animal.new()
	a.setup({"species": species, "id": id if id != "" else "w_%s_%d" % [species, owner], "pos": pos, "yaw": 0.0,
		"owner": owner, "name": "Biscuit" if owner != 0 else "", "sitting": false})
	a.world = w
	add_child_autofree(a)
	return a


## Decisions run Animal.AI_INTERVAL apart (the M1b frame-spike fix): step until one surely happened.
func _until_decided(a: Animal) -> void:
	for i in ceili(Animal.AI_INTERVAL * 60.0) + 1:
		a._physics_process(1.0 / 60.0)


func test_a_pet_whose_owner_left_sits_down_and_waits_wagging_its_tail() -> void:
	var a := _animal_in(_flat_world(), &"dog", GONE, Vector3(2, FlatWorld.GROUND, 2))
	_until_decided(a)
	assert_true(a.sitting, "it sits down where it is and waits")
	assert_eq(a._dir, Vector3.ZERO)
	assert_false(a.is_queued_for_deletion())
	var tail := a.find_child("Part", true, false) as Node3D
	a._process(0.1)
	var before := tail.rotation.y
	a._process(0.13)
	assert_ne(tail.rotation.y, before, "wagging its tail")


func test_a_waiting_pet_stands_up_when_its_owner_is_back() -> void:
	var a := _animal_in(_flat_world(), &"dog", GONE, Vector3(2, FlatWorld.GROUND, 2))
	_until_decided(a)
	assert_true(a.sitting)
	_player(GONE, Vector3(8, FlatWorld.GROUND, 2))
	await get_tree().physics_frame                        # players join between frames
	_until_decided(a)
	assert_false(a.sitting, "it follows again")
	assert_ne(a._dir, Vector3.ZERO)


func test_a_pet_told_to_sit_still_sits_when_its_owner_is_back() -> void:
	var a := _animal_in(_flat_world(), &"cat", GONE, Vector3(2, FlatWorld.GROUND, 2))
	a.sitting = true                                      # the owner said "sit" before leaving
	_until_decided(a)
	_player(GONE, Vector3(8, FlatWorld.GROUND, 2))
	await get_tree().physics_frame
	_until_decided(a)
	assert_true(a.sitting)


func test_a_waiting_pet_that_fell_out_of_the_world_comes_back_at_the_world_spawn() -> void:
	var w := _flat_world()
	w.loaded = false
	var a := _animal_in(w, &"dog", GONE, Vector3(40, SpawnRules.FALL_LIMIT_Y - 5.0, 40))
	a._physics_process(1.0 / 60.0)
	assert_lt(a.global_position.y, SpawnRules.FALL_LIMIT_Y, "waits until the ground at the spawn is there")
	assert_false(a.is_queued_for_deletion(), "a pet is never removed")
	w.loaded = true
	a._physics_process(1.0 / 60.0)
	var spawn := Vector2(w.spawn.x + 0.5, w.spawn.y + 0.5)
	assert_lte(Vector2(a.global_position.x, a.global_position.z).distance_to(spawn), 1.5, "next to the world spawn")
	assert_almost_eq(a.global_position.y, SpawnRules.spawn_y(FlatWorld.GROUND), 0.001, "standing on the ground")
	assert_eq(a.velocity, Vector3.ZERO)
	assert_true(a.sitting, "and waits there")


func test_fallen_pets_come_back_side_by_side() -> void:
	var w := _flat_world()
	var spots := {}
	for i in 3:
		var a := _animal_in(w, &"dog", GONE, Vector3(40, SpawnRules.FALL_LIMIT_Y - 5.0, 40), "gone%d" % i)
		a._physics_process(1.0 / 60.0)
		spots[Vector2i(floori(a.global_position.x), floori(a.global_position.z))] = true
	assert_eq(spots.size(), 3, "three pets, three spots")
	assert_false(spots.has(w.spawn), "the spawn column itself stays free for players")


func test_a_pet_that_fell_comes_back_to_its_owner() -> void:
	var w := _flat_world()
	var owner := _player(7, Vector3(20, FlatWorld.GROUND, 5))
	await get_tree().physics_frame
	var a := _animal_in(w, &"dog", 7, Vector3(40, SpawnRules.FALL_LIMIT_Y - 5.0, 40))
	a._physics_process(1.0 / 60.0)
	assert_almost_eq(a.global_position, owner.global_position + Vector3(1.5, 1.0, 1.5), Vector3.ONE * 0.001)


func test_a_wild_animal_that_fell_out_of_the_world_is_gone() -> void:
	var a := _animal_in(_flat_world(), &"sheep", 0, Vector3(40, SpawnRules.FALL_LIMIT_Y - 5.0, 40))
	a._physics_process(1.0 / 60.0)
	assert_true(a.is_queued_for_deletion())


# --- Real water (M2 Task 14, owner feedback #17) --------------------------------------------------

## Water up to row 12 everywhere.
class WetWorld:
	extends WorldService

	func get_block(p: Vector3i) -> int:
		return BlockIds.WATER if p.y <= 12 else BlockIds.AIR


func _root_particles() -> int:
	return get_tree().root.find_children("*", "CPUParticles3D", false, false).size()


func _wet_animal(species: StringName) -> Animal:
	var w := WetWorld.new()
	add_child_autofree(w)
	var a := Animal.new()
	a.setup(_data(species))
	a.world = w
	add_child_autofree(a)
	return a


func test_an_animal_that_falls_into_water_splashes_once() -> void:
	var a := _wet_animal(&"sheep")
	var before := _root_particles()
	a.global_position = Vector3(1, 14, 2)
	a._check_water(Animal.WATER_CHECK)
	assert_eq(_root_particles(), before, "on dry land: nothing")
	a.global_position = Vector3(1, 12.4, 2)
	a._check_water(Animal.WATER_CHECK)
	var splashed := _root_particles()
	assert_gt(splashed, before, "a splash where it fell in")
	a._check_water(Animal.WATER_CHECK)
	assert_eq(_root_particles(), splashed, "once, not every check")
	for p in get_tree().root.find_children("*", "CPUParticles3D", false, false):
		p.free()


func test_fish_live_in_the_water_and_never_splash() -> void:
	var fish := _wet_animal(&"fish")
	var before := _root_particles()
	fish.global_position = Vector3(1, 10, 2)
	fish._check_water(Animal.WATER_CHECK)
	assert_eq(_root_particles(), before)


## M2 Task 17: a pet dog trots towards a buried treasure its host knows about, and paws the ground there.
func test_a_pet_dog_leads_its_owner_towards_buried_treasure() -> void:
	var dog: Animal = await _pet_dog_for_treasure()
	var chest: Vector3 = dog.get_meta(&"tour_chest")
	var start := Vector2(chest.x - dog.global_position.x, chest.z - dog.global_position.z).length()
	for i in 240:
		dog._physics_process(1.0 / 60.0)
	var now := Vector2(chest.x - dog.global_position.x, chest.z - dog.global_position.z).length()
	assert_lt(now, start - 1.0, "closer to the treasure (%.1f -> %.1f)" % [start, now])
	assert_true(dog.sniffing, "sniffing its way there")


func _pet_dog_for_treasure() -> Animal:
	var w := _flat_world()
	_player(7, Vector3(0, FlatWorld.GROUND, 0))
	await get_tree().physics_frame
	var dog := _animal_in(w, &"dog", 7, Vector3(1, FlatWorld.GROUND, 0), "sniffer")
	var chest := Vector3(14, FlatWorld.GROUND - 3, 0.5)
	dog.treasure_near = func(_from: Vector3) -> Vector3: return chest
	dog._sniff_t = 0.0
	dog.set_meta(&"tour_chest", chest)
	return dog

