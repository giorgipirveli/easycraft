extends GutTest
## Feeding animals (M2 Task 18): a tap on an animal while holding grass or leaves is a treat (it is
## also a pet, so dogs and cats still tame). The host checks the reach, like for petting; golden
## animals are caught, not fed. Treats never use up the block (ruling in the Task 18 notes).

var _book: MindBook
var _names: Dictionary
var _got: Array = []


func before_each() -> void:
	_book = MindBook.current
	MindBook.current = MindBook.new()
	_names = Session.chat_names.duplicate()
	_got.clear()


func after_each() -> void:
	MindBook.current = _book
	Session.chat_names = _names


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


func _animals() -> Node3D:
	var n := Node3D.new()
	add_child_autofree(n)
	return n


func _animal(parent: Node, id: String, pos: Vector3, golden := false) -> Animal:
	var a := Animal.new()
	a.setup({"species": &"sheep", "id": id, "pos": pos, "golden": golden})
	parent.add_child(a)
	a.global_position = pos
	return a


func test_grass_and_leaves_are_treats() -> void:
	assert_true(AnimalSpecies.is_treat(BlockIds.GRASS))
	assert_true(AnimalSpecies.is_treat(BlockIds.LEAVES))
	assert_false(AnimalSpecies.is_treat(BlockIds.STONE))
	assert_false(AnimalSpecies.is_treat(ItemIds.SWORD))


func _on_treat(peer: int, animal_name: String) -> void:
	_got.append([peer, animal_name])


func test_a_treat_request_reaches_the_host() -> void:
	Session.mind_treat_requested.connect(_on_treat)
	Session.mind_request_treat("a1_1_0")
	Session.mind_treat_requested.disconnect(_on_treat)
	assert_eq(_got, [[multiplayer.get_unique_id(), "a1_1_0"]])


func test_the_host_feeds_an_animal_within_reach_only() -> void:
	var parent := _animals()
	var kid := _player(5, Vector3(0, 10, 0))
	var near := _animal(parent, "near", Vector3(2, 10, 0))
	var far := _animal(parent, "far", Vector3(30, 10, 0))
	var gold := _animal(parent, "gold", Vector3(1, 10, 1), true)
	assert_true(Animal.mind_treat(parent, kid, "near", true))
	assert_gt(near.mind.memory.like("Kid5"), 0.5, "fed: it likes the child")
	assert_false(Animal.mind_treat(parent, kid, "far", true), "out of reach")
	assert_eq(far.mind.memory.like("Kid5"), 0.0)
	assert_false(Animal.mind_treat(parent, kid, "gold", true), "golden animals are caught, not fed")
	assert_false(Animal.mind_treat(parent, kid, "nobody", true))
	assert_true(Animal.mind_treat(parent, kid, "near", false), "a pet")
