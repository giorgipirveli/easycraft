extends GutTest
## Owner feedback #39 (spec §14.2a): what universe portals save. A world keeps its universe portals and, after a trip
## through one, the universe the traveller came from (they arrive at its portal back); a Sandbox world of another
## universe is its own save slot, arrived in front of its portal back; the profile keeps which crystals were handed
## over, its crystal gifts and the Sky Dragon's baby dragon — never lost by the profile backup.


func test_a_worlds_universe_portals_and_arrival_are_saved() -> void:
	var m := WorldMeta.new_random()
	var g := PortalGates.new()
	g.add(Vector3i(3, 40, -2), 4)
	m.gates = g.to_save()
	m.arrival_gate = 2
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(PortalGates.from_save(back.gates).universe_of(Vector3i(3, 40, -2)), 4)
	assert_eq(back.arrival_gate, 2)


func test_old_and_broken_worlds_have_no_portals_and_no_arrival() -> void:
	var old := WorldMeta.from_json('{"seed": 5}')
	assert_eq(old.gates, [])
	assert_eq(old.arrival_gate, 0)
	var broken := WorldMeta.from_json('{"seed": 5, "gates": "x", "arrival_gate": 77}')
	assert_eq(broken.gates, [])
	assert_eq(broken.arrival_gate, 0, "a universe without a crystal is no arrival")


func test_a_sandbox_world_of_another_universe_is_made_for_the_first_trip() -> void:
	var m := UniverseRules.sandbox_arrival_meta(null, 3, 1)
	assert_eq(m.mode, ModeRules.SANDBOX)
	assert_eq(m.universe, 3)
	assert_eq(m.arrival_gate, 1, "in front of its portal back to Green Meadows")
	assert_false(m.has_player_pos(), "by the spawn the first time")
	var seen := WorldMeta.new_random()
	seen.player_pos = Vector3(4, 50, 4)
	var again := UniverseRules.sandbox_arrival_meta(seen, 3, 2)
	assert_same(again, seen, "the same world again")
	assert_false(again.has_player_pos(), "arrived at the portal back, not where they last stood")
	assert_eq(again.arrival_gate, 2)


func test_a_survivor_trip_through_a_portal_arrives_at_its_portal_back() -> void:
	var m := UniverseRules.arrival_meta(null, 2, DifficultyRules.COZY, "me")
	assert_eq(m.arrival_gate, 0, "the stone circle's travel arrives by the spawn, as before")


func test_the_profile_keeps_crystals_given_gifts_and_the_baby_dragon() -> void:
	var p := ProfileData.new()
	p.crystals_given = 3
	p.crystal_gifts = [5] as Array[int]
	p.baby_dragon = PetRules.pip_record("Ember", 2, 0.8)
	var back := ProfileData.from_json(p.to_json())
	assert_eq(back.crystals_given, 3)
	assert_eq(back.crystal_gifts, [5] as Array[int])
	assert_eq(str(back.baby_dragon.name), "Ember")
	var broken := ProfileData.from_json('{"crystals_given": "x", "crystal_gifts": [99, "a"], "baby_dragon": 4}')
	assert_eq(broken.crystals_given, 0, "the crystals come again: nothing is lost")
	assert_eq(broken.crystal_gifts, [] as Array[int])
	assert_eq(broken.baby_dragon, {})


func test_the_backup_never_loses_the_baby_dragon_or_hands_a_crystal_twice() -> void:
	var phone := ProfileData.new()
	phone.universe_unlocked = 5
	phone.crystals_given = 5
	phone.baby_dragon = PetRules.pip_record("Ember", 1, 0.9)
	phone.updated_at = 100
	var server := ProfileData.new()
	server.universe_unlocked = 5
	server.crystals_given = 2
	server.updated_at = 200
	var merged: ProfileData = ProfileBackup.merge(phone, ProfileBackup.to_backup(server)).profile
	assert_eq(merged.crystals_given, 5, "the newer copy won, but the crystals given stay given")
	assert_eq(str(merged.baby_dragon.name), "Ember", "the baby dragon is never lost")
	assert_false(ProfileBackup.is_new(phone), "a profile with a baby dragon has progress")
