extends GutTest
## Owner feedback #26 ("we have a bug in the game, we cannt kills animals, we should be able to kill
## them"; it overrules the M1b ruling that animals are only pushed back). Animals have health by kind,
## take damage from weapons, fists and arrows (they run away, squash, cry out), and when defeated
## puff away in the monsters' cartoon cloud (never blood). In Survivor they leave the one who defeated
## them a little (building blocks; never gold or anything Tilly buys: no gold farm), in the Sandbox
## nothing. A pet is never hurt (by anyone), a golden animal is never hurt (it is caught), and herds
## refill slowly. Host-decided like monsters (CombatDirector.apply_hit). Real Animal, CombatDirector,
## Player and Session; solo, so this game is the host.

var director: CombatDirector
var _mode_before: StringName


func before_each() -> void:
	_mode_before = Game.mode
	Game.mode = ModeRules.SANDBOX
	director = CombatDirector.new()
	director.name = "Combat"
	add_child_autofree(director)
	director.block_at = func(p: Vector3i) -> int: return BlockIds.GRASS if p.y < 0 else BlockIds.AIR


func after_each() -> void:
	Game.mode = _mode_before
	Session.set_inventory(multiplayer.get_unique_id(), Inventory.new())


func _animal(species: StringName, pos: Vector3, extra: Dictionary = {}) -> Animal:
	var a := Animal.new()
	var data := {"species": species, "id": "a9_9_%d" % randi_range(0, 99999), "pos": pos, "yaw": 0.0, "owner": 0,
		"name": "", "sitting": false}
	data.merge(extra, true)
	a.setup(data)
	add_child_autofree(a)
	return a


## This game's own player standing still at `feet` (its swings come from its chest).
func _player(feet: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = feet
	return p


func _swing(weapon: int, attacker: Node = null) -> Array:
	return director.resolve_melee(Vector3(0.5, 1, 0.5), Vector3.FORWARD, weapon, 0, attacker)


func _gone(a: Animal) -> bool:
	return not is_instance_valid(a) or a.is_queued_for_deletion()


func test_every_kind_has_health_by_its_size() -> void:
	var small := [&"chicken", &"rabbit", &"fish"]
	var medium := [&"pig", &"sheep", &"dog", &"cat"]
	for sp: StringName in AnimalRules.SPECIES:
		assert_gt(AnimalRules.max_hp(sp), 0, str(sp))
	for s: StringName in small:
		for m: StringName in medium:
			assert_lt(AnimalRules.max_hp(s), AnimalRules.max_hp(m), "%s is smaller than a %s" % [s, m])
	for m: StringName in medium:
		assert_lt(AnimalRules.max_hp(m), AnimalRules.max_hp(&"cow"), "a cow is the biggest")
	var cow := _animal(&"cow", Vector3(0.5, 0, -1.5))
	assert_eq(cow.hp, AnimalRules.max_hp(&"cow"), "a new animal has all its health")
	assert_eq(cow.max_hp, cow.hp)


func test_a_sword_hurts_an_animal_and_it_runs_away() -> void:
	var cow := _animal(&"cow", Vector3(0.5, 0, -1.5))
	var hits := _swing(ItemIds.SWORD)
	assert_eq(hits.size(), 1)
	assert_eq(cow.hp, cow.max_hp - int(WeaponRules.stats(ItemIds.SWORD).damage), "hurt")
	assert_gt(cow._flee, 0.0, "it runs away")
	assert_lt(cow.velocity.z, -3.0, "pushed away")
	assert_false(_gone(cow), "a cow takes more than one hit")


func test_every_peer_sees_the_hurt_squash() -> void:
	var cow := _animal(&"cow", Vector3(0.5, 0, -1.5))
	await wait_process_frames(2)
	cow.hp -= 2                     # what the synchronizer does on a guest
	cow._process(0.0)
	assert_lt(cow._body.scale.y, 0.9, "squashed by the hit")
	var cfg := (cow.get_node("Sync") as MultiplayerSynchronizer).replication_config
	assert_true(cfg.has_property(NodePath(".:hp")), "health is synced")
	assert_eq(cfg.property_get_replication_mode(NodePath(".:hp")), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)


func test_a_defeated_animal_puffs_away_and_the_host_says_so() -> void:
	var chicken := _animal(&"chicken", Vector3(0.5, 0, -1.5))
	var id := chicken.animal_id
	watch_signals(director)
	var clouds_before := _clouds()
	_swing(ItemIds.SWORD)
	assert_true(_gone(chicken), "one sword hit is enough for a chicken")
	assert_signal_emitted(director, "animal_defeated")
	var params: Variant = get_signal_parameters(director, "animal_defeated")
	assert_eq(params[0] if params is Array else "", id, "which animal, for the herd to refill later")
	assert_gt(_clouds(), clouds_before, "a cartoon cloud puffs where it stood")


func _clouds() -> int:
	var n := 0
	for c in get_tree().root.get_children():
		if c is CPUParticles3D and not c.is_queued_for_deletion():
			n += 1
	return n


func test_fists_hurt_a_little_and_many_punches_defeat_a_pig() -> void:
	var pig := _animal(&"pig", Vector3(0.5, 0, -1.4))
	_swing(WeaponRules.FISTS)
	assert_eq(pig.hp, pig.max_hp - int(WeaponRules.stats(WeaponRules.FISTS).damage))
	for i in pig.max_hp:
		if _gone(pig):
			break
		pig.global_position = Vector3(0.5, 0, -1.4)   # the punches push it: it comes back for the next
		_swing(WeaponRules.FISTS)
	assert_true(_gone(pig))


func test_an_arrow_hurts_an_animal() -> void:
	var cow := _animal(&"cow", Vector3(0.5, 1.2 - CombatDirector.ANIMAL_CENTER, -6.5))
	director.spawn_arrow(Vector3(0.5, 1.2, 0.5), Vector3(0, 0, -30), 1, 1.0)
	await wait_physics_frames(20)
	assert_eq(cow.hp, cow.max_hp - int(WeaponRules.stats(ItemIds.BOW).damage))


func test_survivor_leaves_the_hitter_a_little_never_gold() -> void:
	Game.mode = ModeRules.SURVIVOR
	var p := _player(Vector3(0.5, 0, 0.5))
	Session.set_inventory(p.peer_id, Inventory.new())
	var sheep := _animal(&"sheep", Vector3(0.5, 0, -1.5))
	var expected := AnimalRules.drops(&"sheep", sheep.animal_id)
	var gold_before := Session.gold_of(p.peer_id)
	assert_false(expected.is_empty(), "a sheep leaves something")
	for i in 3:
		if _gone(sheep):
			break
		sheep.global_position = Vector3(0.5, 0, -1.5)
		director.resolve_melee(CombatDirector.chest(p), Vector3.FORWARD, ItemIds.SWORD, 0, p)
	assert_true(_gone(sheep))
	var inv := Session.inventory_of(p.peer_id)
	for e: Array in expected:
		assert_eq(inv.count(int(e[0])), int(e[1]), "the drop is in the bag: %s" % BlockIds.display_name(int(e[0])))
	assert_eq(Session.gold_of(p.peer_id), gold_before, "never gold")


func test_the_sandbox_drops_nothing() -> void:
	var p := _player(Vector3(0.5, 0, 0.5))
	Session.set_inventory(p.peer_id, Inventory.new())
	var chicken := _animal(&"chicken", Vector3(0.5, 0, -1.5))
	director.resolve_melee(CombatDirector.chest(p), Vector3.FORWARD, ItemIds.SWORD, 0, p)
	assert_true(_gone(chicken))
	assert_eq(Session.inventory_of(p.peer_id).ids(), [] as Array[int], "unlimited blocks: nothing to drop")


func test_a_pet_is_never_hurt_only_pushed() -> void:
	var dog := _animal(&"dog", Vector3(0.5, 0, -1.5), {"owner": multiplayer.get_unique_id(), "name": "Biscuit"})
	var p := _player(Vector3(0.5, 0, 0.5))
	for i in 5:
		dog.global_position = Vector3(0.5, 0, -1.5)
		director.resolve_melee(CombatDirector.chest(p), Vector3.FORWARD, ItemIds.MACE_COSMIC, 0, p)
	assert_false(_gone(dog), "its owner's mace never hurts it")
	assert_eq(dog.hp, dog.max_hp)
	dog.global_position = Vector3(0.5, 0, -1.5)
	_swing(ItemIds.SWORD_COSMIC)                        # anybody else's swing
	assert_eq(dog.hp, dog.max_hp, "and nobody else's either")
	assert_lt(dog.velocity.z, 0.0, "a hit still pushes it")


func test_a_golden_animal_is_never_hurt_and_still_flees() -> void:
	var gold := _animal(&"pig", Vector3(0.5, 0, -1.5), {"golden": true})
	_swing(ItemIds.SWORD_COSMIC)
	assert_eq(gold.hp, gold.max_hp, "caught with a tap, never defeated")
	assert_gt(gold._flee, 0.0, "it runs")


func test_a_hit_animal_learns_fear() -> void:
	var p := _player(Vector3(0.5, 0, 0.5))
	await get_tree().physics_frame
	var cow := _animal(&"cow", Vector3(0.5, 0, -1.5))
	director.resolve_melee(CombatDirector.chest(p), Vector3.FORWARD, ItemIds.SWORD, 0, p)
	assert_eq(cow.mind.drive(Mind.FEAR), 1.0, "afraid")
	var e := cow.mind.memory.entry(Animal.mind_name(p))
	assert_gt(float(e.get("fear", 0.0)), 0.0, "of the one who hit it")


# --- Herds refill slowly (AnimalDirector) ---

var _spawned: Array[Dictionary] = []
var _clock := 0.0


func test_a_defeated_herd_animal_comes_back_only_after_a_while() -> void:
	var container := Node3D.new()
	add_child_autofree(container)
	var d := AnimalDirector.new()
	d.shape = MeadowsShape.new(12345)
	d.container = container
	var land := d.shape.spawn_column()
	var players: Array[Vector3] = [Vector3(land.x, 40, land.y)]
	d.player_positions = func() -> Array[Vector3]: return players
	d.is_ready = func(_p: Vector3) -> bool: return true
	d.now = func() -> float: return _clock
	d.spawn = func(data: Dictionary) -> void:
		_spawned.append(data)
		var a := Animal.new()
		a.setup(data)
		container.add_child(a)
	add_child_autofree(d)
	for i in 20:
		d.tick()
	assert_gt(container.get_child_count(), 0, "the herds are out")
	var gone := container.get_child(0) as Animal
	var id := gone.animal_id
	d.note_defeated(id)
	gone.free()
	_spawned.clear()
	for i in 5:
		_clock += 1.0
		d.tick()
	assert_false(_spawned.any(func(s: Dictionary) -> bool: return s.id == id), "not back at once")
	_clock += AnimalRules.REFILL_TIME
	for i in 5:
		d.tick()
	assert_true(_spawned.any(func(s: Dictionary) -> bool: return s.id == id), "back after a while: the world never runs empty")
