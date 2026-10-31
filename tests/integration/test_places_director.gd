extends GutTest
## Owner feedback #45b (spec §14.18): the PlacesDirector (node "Places" on every game). The host notices when a
## player comes within a place's find circle and marks it found for the whole world (saved in WorldMeta); every game
## keeps the found list (a guest asks for it); the world map shows only found places; villagers stand in villages
## near players (they wave, and trade with Tilly's rules in Survivor) and go when nobody is near.

const SEED := 12345

var shape: MeadowsBiomeShape
var rules: SecretRules
var director: PlacesDirector
var _village: Dictionary
var _other: Dictionary


class FakePlayer:
	extends Node3D


func before_all() -> void:
	shape = MeadowsBiomeShape.new(SEED)
	rules = SecretRules.new(SEED, shape)
	var places := MeadowsPlaces.new(SEED, shape, rules)
	for r in 8:
		for rz in range(-r, r + 1):
			for rx in range(-r, r + 1):
				for p: Dictionary in places.places_in_region(Vector2i(rx, rz)):
					if _village.is_empty() and p.kind == MeadowsPlaces.VILLAGE:
						_village = p
					elif _other.is_empty() and p.kind != MeadowsPlaces.VILLAGE:
						_other = p


func before_each() -> void:
	director = PlacesDirector.new()
	director.auto_tick = false
	add_child_autofree(director)
	director.setup_host(shape, rules, [])


func _player_at(pos: Vector3, peer: int = 1) -> FakePlayer:
	var p := FakePlayer.new()
	p.name = str(peer)
	add_child_autofree(p)
	p.add_to_group(&"players")
	p.global_position = pos
	return p


func _anchor(p: Dictionary) -> Vector3:
	var a: Vector3i = p.anchor
	return Vector3(a.x + 0.5, a.y, a.z + 0.5)


func test_a_place_is_found_when_a_player_comes_near() -> void:
	assert_false(_village.is_empty(), "a village near the spawn of seed 12345")
	assert_true(director.enabled())
	watch_signals(director)
	var p := _player_at(_anchor(_village) + Vector3(_village.radius + 20.0, 0, 0))
	director.tick()
	assert_false(director.found.has(_village.id), "not yet: outside its circle")
	p.global_position = _anchor(_village) + Vector3(_village.radius - 3.0, 0, 0)
	director.tick()
	assert_true(director.found.has(_village.id), "found")
	assert_signal_emitted(director, "place_found")
	assert_signal_emitted(director, "found_changed")
	director.tick()
	assert_signal_emit_count(director, "place_found", 1, "once")
	assert_eq(director.found_ids(), [_village.id] as Array[String], "what the world saves")


## The world map's rule: only places somebody found in this world, with their picture's kind, name and spot.
func test_the_map_shows_only_found_places() -> void:
	assert_eq(director.found_places(), [], "nothing found yet: an empty map (secrets stay secret)")
	_player_at(_anchor(_other))
	director.tick()
	var list := director.found_places()
	assert_eq(list.size(), 1)
	assert_eq(list[0].id, _other.id)
	assert_eq(list[0].kind, _other.kind)
	assert_eq(list[0].name, _other.name)
	assert_eq(list[0].pos, _anchor(_other))
	for e: Dictionary in list:
		assert_ne(e.id, _village.id, "a place nobody found is never on the map")
	director.mark({"id": "quest_1", "kind": &"quest", "name": "The old well", "pos": Vector3(10, 30, 10)})
	assert_eq(director.found_places().size(), 2, "another task's found place (a quest's) joins the map")


func test_a_saved_world_remembers_its_found_places() -> void:
	var again := PlacesDirector.new()
	again.auto_tick = false
	add_child_autofree(again)
	again.setup_host(shape, rules, [_village.id, "nonsense", _village.id, "village_999_999"] as Array[String])
	assert_eq(again.found_ids(), [_village.id, "village_999_999"] as Array[String], "valid ids once each")
	assert_eq(again.found_places().size(), 1, "an id with no place there shows nothing")
	var m := WorldMeta.new_random()
	m.places_found = again.found_ids()
	assert_eq(WorldMeta.from_json(m.to_json()).places_found, again.found_ids())


func test_a_guest_gets_the_found_list_and_later_finds() -> void:
	var guest := PlacesDirector.new()
	guest.auto_tick = false
	add_child_autofree(guest)
	guest.places = MeadowsPlaces.new(SEED, shape, rules)
	guest._rpc_found_list([_village.id, 7, "x"])
	assert_eq(guest.found_ids(), [_village.id] as Array[String])
	guest._rpc_found(_other.id, 5)
	assert_true(guest.found.has(_other.id))


func test_the_old_meadows_have_no_places() -> void:
	var old := PlacesDirector.new()
	old.auto_tick = false
	add_child_autofree(old)
	old.setup_host(MeadowsShape.new(SEED), SecretRules.new(SEED), [])
	assert_false(old.enabled())
	_player_at(_anchor(_village))
	old.tick()
	assert_eq(old.found_places(), [])


func test_villagers_stand_in_a_village_near_a_player_and_go_when_nobody_is_near() -> void:
	var p := _player_at(_anchor(_village))
	director.trades = true
	director.tick()
	var here: Array = director.villagers_of(_village.id)
	assert_eq(here.size(), (_village.villagers as Array).size(), "every villager of the village")
	for v: Villager in here:
		assert_true(v.is_in_group(&"traders"), "Survivor: a tap trades with Tilly's rules")
		assert_true(v is Trader, "Tilly's shop takes a villager")
		var near := false
		for spot: Array in _village.villagers:
			if v.global_position.distance_to(spot[0]) < 0.01:
				near = true
		assert_true(near, "on its spot")
	p.global_position = _anchor(_village) + Vector3(PlacesDirector.VILLAGERS_GONE + 10.0, 0, 0)
	director.tick()
	await wait_process_frames(1)
	assert_eq(director.villagers_of(_village.id).size(), 0, "gone when nobody is near")


func test_sandbox_villagers_wave_but_do_not_trade() -> void:
	var first := _player_at(_anchor(_village))
	director.trades = false
	director.tick()
	var here: Array = director.villagers_of(_village.id)
	assert_gt(here.size(), 0)
	for v: Villager in here:
		assert_false(v.is_in_group(&"traders"))
	var v: Villager = here[0]
	first.global_position += Vector3(0, 60, 0)   # far above: nobody near the villagers
	var close := _player_at(v.global_position + Vector3(2, 0, 0), 2)
	v._look_for_players()
	assert_true(v.is_greeting(), "a villager waves at a player who comes near")
	close.global_position += Vector3(40, 0, 0)
	v._look_for_players()
	assert_false(v.is_greeting())
