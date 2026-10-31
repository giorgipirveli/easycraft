extends GutTest
## Owner feedback #41's taming, feeding and pets in the world (spec §14.19), through the host's PetDirector:
## two treats tame a horse; the child who owns it puts a SADDLE on it with a tap (Survivor pays one from the bag);
## a penguin eats a Fish Snack and likes the child for it (a treat it doesn't eat is kept); a donkey's chest takes
## the held stack and gives a slot back (only its own child's; nothing made from nothing).

var _book: MindBook
var _names: Dictionary
var _told: Array = []
var _bag := {}                    # the child's bag for the Survivor tests: id -> count


func before_each() -> void:
	_book = MindBook.current
	MindBook.current = MindBook.new()
	_names = Session.chat_names.duplicate()
	_told.clear()
	_bag = {}


func after_each() -> void:
	MindBook.current = _book
	Session.chat_names = _names


func after_all() -> void:
	for n in Audio.get_children():
		if n is AudioStreamPlayer3D:
			(n as AudioStreamPlayer3D).stop()
		elif n is AudioStreamPlayer:
			(n as AudioStreamPlayer).stop()


func _player(peer: int, pos: Vector3) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	p.global_position = pos
	Session.chat_names[peer] = "Kid%d" % peer
	return p


## A director whose bag rules are a Survivor bag (`_bag`) when `survivor`, else Sandbox's (everything free).
func _director(survivor := false) -> PetDirector:
	var d := PetDirector.new()
	d.auto_tick = false
	d.animals = Node3D.new()
	add_child_autofree(d.animals)
	d.tell = func(peer: int, text: String) -> void: _told.append([peer, text])
	d.save_profile = func() -> void: pass
	if survivor:
		d.take_treat = func(_peer: int, item: int) -> bool: return _take(item, 1)
		d.bag_count = func(_peer: int, id: int) -> int: return int(_bag.get(id, 0))
		d.take_items = func(_peer: int, id: int, n: int) -> bool: return _take(id, n)
		d.give_items = func(_peer: int, id: int, n: int) -> int:
			_bag[id] = int(_bag.get(id, 0)) + n
			return n
	add_child_autofree(d)
	return d


func _take(id: int, n: int) -> bool:
	if int(_bag.get(id, 0)) < n:
		return false
	_bag[id] = int(_bag[id]) - n
	return true


func _animal(d: PetDirector, species: StringName, id: String, pos: Vector3, owner := 0) -> Animal:
	var a := Animal.new()
	a.setup({"species": species, "id": id, "pos": pos, "owner": owner, "name": "Rex" if owner else ""})
	d.animals.add_child(a)
	a.global_position = pos
	return a


# --- Taming and the saddle ---

func test_two_treats_tame_a_horse_and_a_saddle_makes_it_rideable() -> void:
	var d := _director()
	_player(2, Vector3(0.5, 10, 0.5))
	var horse := _animal(d, &"horse", "h_test", Vector3(1.5, 10, 0.5))
	await get_tree().physics_frame
	d.on_treat(2, "h_test", ItemIds.TREAT_BERRIES)
	assert_false(horse.is_pet(), "one treat: it likes the child")
	d.on_treat(2, "h_test", ItemIds.TREAT_SEEDS)
	assert_true(horse.is_pet(), "two: tamed")
	assert_eq(horse.owner_peer, 2)
	assert_eq(horse.ride_kind, RideRules.Kind.NONE, "no saddle yet")
	d.on_saddle(2, "h_test")
	assert_true(horse.saddled, "saddled")
	assert_eq(horse.ride_kind, RideRules.Kind.GALLOP, "a horse gallops")
	assert_true(horse.to_save().get("saddled", false), "the saddle is saved with the pet")


func test_only_its_own_child_saddles_a_tamed_horse_and_never_a_wild_one_or_a_cow() -> void:
	var d := _director()
	_player(2, Vector3(0.5, 10, 0.5))
	_player(3, Vector3(0.5, 10, 1.5))
	var wild := _animal(d, &"horse", "h_wild", Vector3(1.5, 10, 0.5))
	var mine := _animal(d, &"horse", "h_mine", Vector3(1.5, 10, 1.5), 2)
	var cow := _animal(d, &"cow", "c_test", Vector3(-1.5, 10, 0.5))
	await get_tree().physics_frame
	d.on_saddle(2, "h_wild")
	assert_false(wild.saddled, "tame it first")
	d.on_saddle(3, "h_mine")
	assert_false(mine.saddled, "not another child's horse")
	d.on_saddle(2, "c_test")
	assert_false(cow.saddled, "a cow is never ridden")
	d.on_saddle(2, "h_mine")
	assert_true(mine.saddled)


func test_survivor_pays_one_saddle_from_the_bag() -> void:
	var d := _director(true)
	_player(2, Vector3(0.5, 10, 0.5))
	var camel := _animal(d, &"camel", "k_test", Vector3(1.5, 10, 0.5), 2)
	await get_tree().physics_frame
	d.on_saddle(2, "k_test")
	assert_false(camel.saddled, "no saddle in the bag")
	assert_string_contains(_told.back()[1].to_lower(), "saddle")
	_bag[BlockIds.SADDLE] = 1
	d.on_saddle(2, "k_test")
	assert_true(camel.saddled)
	assert_eq(int(_bag[BlockIds.SADDLE]), 0, "the saddle was used")
	assert_eq(camel.ride_kind, RideRules.Kind.TREK, "a camel treks")
	d.on_saddle(2, "k_test")
	assert_eq(int(_bag[BlockIds.SADDLE]), 0, "a saddled camel needs no second one")


# --- Feeding the wild ones ---

func test_a_penguin_eats_a_fish_snack_and_likes_the_child() -> void:
	var d := _director(true)
	_player(2, Vector3(0.5, 10, 0.5))
	var penguin := _animal(d, &"penguin", "p_test", Vector3(1.5, 10, 0.5))
	_bag[ItemIds.TREAT_FISH] = 2
	_bag[ItemIds.TREAT_BOLT] = 1
	await get_tree().physics_frame
	d.on_treat(2, "p_test", ItemIds.TREAT_BOLT)
	assert_eq(int(_bag[ItemIds.TREAT_BOLT]), 1, "a penguin doesn't eat bolts: the treat is kept")
	assert_eq(penguin.mind.memory.like("Kid2"), 0.0)
	d.on_treat(2, "p_test", ItemIds.TREAT_FISH)
	assert_eq(int(_bag[ItemIds.TREAT_FISH]), 1, "one fish snack eaten")
	assert_gt(penguin.mind.memory.like("Kid2"), 0.3, "it likes the child who fed it")
	assert_false(penguin.is_pet(), "a penguin stays wild")


# --- The donkey's chest ---

func test_a_donkey_carries_the_held_stack_and_gives_a_slot_back() -> void:
	var d := _director(true)
	_player(2, Vector3(0.5, 10, 0.5))
	var donkey := _animal(d, &"donkey", "d_test", Vector3(1.5, 10, 0.5), 2)
	_bag[BlockIds.PLANKS] = 40
	await get_tree().physics_frame
	d.on_chest_put(2, "d_test", BlockIds.PLANKS)
	assert_eq(int(_bag[BlockIds.PLANKS]), 0, "the whole stack went in")
	assert_eq(DonkeyChest.slot(donkey.chest, 0), Vector2i(BlockIds.PLANKS, 40))
	d.on_chest_put(2, "d_test", BlockIds.STONE)
	assert_eq(DonkeyChest.slot(donkey.chest, 1), Vector2i.ZERO, "nothing held: nothing goes in")
	d.on_chest_take(2, "d_test", 0)
	assert_eq(int(_bag[BlockIds.PLANKS]), 40, "back in the bag")
	assert_true(DonkeyChest.is_empty(donkey.chest))
	assert_true(donkey.to_save().is_empty() == false)


func test_only_its_own_child_uses_a_donkeys_chest() -> void:
	var d := _director(true)
	_player(2, Vector3(0.5, 10, 0.5))
	_player(3, Vector3(0.5, 10, 1.5))
	var donkey := _animal(d, &"donkey", "d_test", Vector3(1.5, 10, 0.5), 2)
	_bag[BlockIds.PLANKS] = 10
	await get_tree().physics_frame
	d.on_chest_put(2, "d_test", BlockIds.PLANKS)
	d.on_chest_take(3, "d_test", 0)
	assert_eq(DonkeyChest.slot(donkey.chest, 0), Vector2i(BlockIds.PLANKS, 10), "another child can't empty it")
	var wild := _animal(d, &"donkey", "d_wild", Vector3(-1.5, 10, 0.5))
	_bag[BlockIds.PLANKS] = 5
	d.on_chest_put(2, "d_wild", BlockIds.PLANKS)
	assert_true(DonkeyChest.is_empty(wild.chest), "a wild donkey carries nothing")
	assert_eq(int(_bag[BlockIds.PLANKS]), 5)


func test_a_saved_donkey_keeps_its_chest() -> void:
	var d := _director()
	var donkey := _animal(d, &"donkey", "d_test", Vector3(1.5, 10, 0.5), 2)
	donkey.chest = DonkeyChest.put(donkey.chest, BlockIds.GLASS, 12).chest
	var saved := donkey.to_save()
	var again := Animal.new()
	again.setup({"species": &"donkey", "id": "d_test", "pos": Vector3.ZERO, "owner": 2, "chest": saved.chest})
	autofree(again)
	assert_eq(DonkeyChest.slot(again.chest, 0), Vector2i(BlockIds.GLASS, 12))
