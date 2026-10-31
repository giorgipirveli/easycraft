extends GutTest
## Colonies under domes (owner #77: "domes for living creatures", spec §21c.2): ColonyAnimals brings the Great Dome's
## animals (the game's own: bunnies, chickens, ducks, fish in the pond) to life when a child comes near, only inside the
## dome, one a tick; one that wandered out through a doorway goes back inside; they go when every child is far; a pet
## is never touched; a defeated one comes back only after a while. On Mars they are the only animals (no life outside).

var layout: ColonyLayout
var animals: ColonyAnimals
var container: Node3D
var players: Array[Vector3] = []
var clock := 0.0


func before_each() -> void:
	layout = SpaceShape.new(12345, SpaceShape.MARS).colony
	container = Node3D.new()
	container.process_mode = Node.PROCESS_MODE_DISABLED   # no world here: the animals stand still
	add_child_autofree(container)
	players.clear()
	clock = 0.0
	animals = ColonyAnimals.new()
	animals.auto_tick = false
	animals.layout = layout
	animals.container = container
	animals.player_positions = func() -> Array[Vector3]: return players
	animals.is_ready = func(_pos: Vector3) -> bool: return true
	animals.now = func() -> float: return clock
	animals.spawn = func(data: Dictionary) -> void:
		var a := Animal.new()
		a.setup(data)
		container.add_child(a)
	add_child_autofree(animals)


func _herd() -> int:
	var n := 0
	for e: Dictionary in ColonyRules.HERD:
		n += int(e.count)
	return n


func _fill() -> void:
	for i in _herd() + 2:
		animals.tick()


## A child between two places (a respawn, a trip: not standing yet) sends nobody away: the herd is never rebuilt for it
## (building an animal costs a frame 5-15 ms here).
func test_nobody_goes_while_the_child_is_between_two_places() -> void:
	players.append(layout.great_middle())
	_fill()
	players.clear()
	animals.tick()
	assert_eq(animals.alive().size(), _herd(), "the herd stays")
	for a: Animal in animals.alive().values():
		assert_false(a.is_queued_for_deletion())


func test_they_come_when_a_child_is_near_a_few_a_tick() -> void:
	players.append(Vector3(layout.centre.x + 200, 50, layout.centre.y))
	animals.tick()
	assert_eq(animals.alive().size(), 0, "nobody near: nobody comes")
	players[0] = layout.great_middle() + Vector3(30, 0, 0)
	animals.tick()
	assert_eq(animals.alive().size(), 1, "one a tick (the frame budget)")
	_fill()
	var here := animals.alive()
	assert_eq(here.size(), _herd(), "the whole herd")
	var kinds := {}
	for a: Animal in here.values():
		kinds[a.species] = int(kinds.get(a.species, 0)) + 1
		assert_true(layout.in_great_dome(floori(a.position.x), floori(a.position.z)), "%s inside the dome" % a.species)
	for e: Dictionary in ColonyRules.HERD:
		assert_eq(int(kinds.get(e.species, 0)), int(e.count), str(e.species))


func test_one_that_wandered_out_goes_back_inside() -> void:
	players.append(layout.great_middle())
	_fill()
	var a: Animal = animals.alive().values()[0]
	var out := layout.world(0, 30)
	a.global_position = Vector3(out.x + 0.5, layout.ground, out.y + 0.5)
	animals.tick()
	assert_true(layout.in_great_dome(floori(a.global_position.x), floori(a.global_position.z)), "back under the glass")
	assert_eq(animals.alive().size(), _herd(), "no second one came")


func test_they_go_when_every_child_is_far_and_come_back() -> void:
	players.append(layout.great_middle())
	_fill()
	players[0] = layout.great_middle() + Vector3(ColonyAnimals.FAR + 10, 0, 0)
	animals.tick()
	assert_eq(animals.alive().size(), 0, "gone while nobody is near")
	await wait_physics_frames(2)
	players[0] = layout.great_middle()
	_fill()
	assert_eq(animals.alive().size(), _herd())


func test_a_pet_is_never_touched_and_keeps_its_spot() -> void:
	players.append(layout.great_middle())
	_fill()
	var a: Animal = animals.alive()[ColonyAnimals.PREFIX + "0"]
	a.owner_peer = 1   # tamed
	var out := layout.world(0, 30)
	a.global_position = Vector3(out.x + 0.5, layout.ground, out.y + 0.5)
	animals.tick()
	assert_false(layout.in_great_dome(floori(a.global_position.x), floori(a.global_position.z)), "it follows its child")
	assert_eq(animals.alive().size(), _herd(), "its spot stays taken")
	players[0] = layout.great_middle() + Vector3(500, 0, 0)
	animals.tick()
	assert_false(a.is_queued_for_deletion(), "a pet never goes away with the herd")


func test_a_defeated_one_comes_back_only_after_a_while() -> void:
	players.append(layout.great_middle())
	_fill()
	var id := ColonyAnimals.PREFIX + "1"
	var a: Animal = animals.alive()[id]
	animals.note_defeated(id)
	container.remove_child(a)
	a.free()
	_fill()
	assert_false(animals.alive().has(id), "the herd thins out for a while")
	clock += AnimalRules.REFILL_TIME + 1.0
	animals.tick()
	assert_true(animals.alive().has(id), "and fills up again")
