extends GutTest
## Pets are saved with their world (WorldMeta.pets, M1b) — now with their collar and heart, foxes and parrots
## too (M3 Task 11). Pip is never saved with a world: he lives in the profile (PetRules.give_pip).


func test_a_pets_collar_and_heart_are_saved_with_the_world() -> void:
	var m := WorldMeta.new()
	m.pets = [{"species": "fox", "name": "Maple", "pos": [1.0, 40.0, 2.0], "id": "a1_1_0", "collar": 5, "happiness": 0.85},
		{"species": "parrot", "name": "Kiwi", "pos": [3.0, 40.0, 2.0], "id": "a2_1_0", "collar": -1, "happiness": 0.4}]
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.pets.size(), 2)
	assert_eq(back.pets[0].species, "fox")
	assert_eq(int(back.pets[0].collar), 5)
	assert_eq(float(back.pets[0].happiness), 0.85)
	assert_eq(back.pets[1].species, "parrot")
	assert_eq(int(back.pets[1].collar), PetRules.OWNER_COLOUR)
	assert_eq(float(back.pets[1].happiness), 0.4)


func test_old_saves_and_broken_values_get_the_defaults() -> void:
	var m := WorldMeta.from_json('{"pets":[{"species":"dog","name":"Biscuit","pos":[1,2,3],"id":"p1"},'
		+ '{"species":"cat","name":"Luna","pos":[1,2,3],"id":"p2","collar":"red","happiness":99},'
		+ '{"species":"cat","name":"killer","pos":[1,2,3],"id":"p3","collar":3.0,"happiness":-4}]}')
	assert_eq(m.pets.size(), 3)
	assert_eq(int(m.pets[0].collar), PetRules.OWNER_COLOUR, "an M1b pet: its owner's colour")
	assert_eq(float(m.pets[0].happiness), PetRules.HAPPY_START)
	assert_eq(int(m.pets[1].collar), PetRules.OWNER_COLOUR)
	assert_eq(float(m.pets[1].happiness), 1.0)
	assert_eq(int(m.pets[2].collar), 3)
	assert_eq(float(m.pets[2].happiness), PetRules.HAPPY_FLOOR)
	assert_true(PetRules.FUN_NAMES.has(m.pets[2].name), "a name the filter refuses becomes a fun name")


func test_pip_is_never_saved_with_a_world() -> void:
	var m := WorldMeta.from_json('{"pets":[{"species":"pip","name":"Pip","pos":[1,2,3],"id":"pip_1"}]}')
	assert_eq(m.pets.size(), 0, "he lives in the profile")
