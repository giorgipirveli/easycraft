extends GutTest
## Bot friends are saved with the world (M2 Task 15): who they are (name, personality, look); they
## come back next to the player. Broken entries are fixed or dropped, never trusted.


func test_bots_round_trip() -> void:
	var m := WorldMeta.new_random()
	m.bots = [{"name": "Pip", "personality": "builder", "look": 2},
		{"name": "Bolt", "personality": "fighter", "look": 0}]
	var back := WorldMeta.from_json(m.to_json())
	assert_eq(back.bots, [{"name": "Pip", "personality": "builder", "look": 2},
		{"name": "Bolt", "personality": "fighter", "look": 0}] as Array[Dictionary])


func test_old_saves_have_no_bots() -> void:
	assert_eq(WorldMeta.from_json('{"seed": 5}').bots, [] as Array[Dictionary])
	assert_eq(WorldMeta.from_json('{"seed": 5, "bots": "lots"}').bots, [] as Array[Dictionary])


func test_broken_bots_are_fixed_or_dropped_and_capped_at_three() -> void:
	var list: Array = [
		{"name": "Pip", "personality": "pirate", "look": 1},          # unknown personality: dropped
		"junk",
		{"name": "Bobby Tables", "personality": "explorer", "look": 1}, # not a bot name: a bot name instead
		{"name": "Fizz", "personality": "builder", "look": 99},         # no such look: a free one
		{"name": "Fizz", "personality": "fighter", "look": 3},          # the name again: another name
		{"name": "Gizmo", "personality": "fighter", "look": "x"},
		{"name": "Comet", "personality": "builder", "look": 4},         # the fourth: capped
	]
	var back := WorldMeta.from_json(JSON.stringify({"seed": 1, "bots": list}))
	assert_eq(back.bots.size(), BotRules.MAX_BOTS)
	var names := {}
	var looks := {}
	for b: Dictionary in back.bots:
		assert_true(BotRules.NAMES.has(b.name), str(b.name))
		assert_true(BotRules.valid_personality(StringName(b.personality)))
		assert_true(BotRules.valid_look(int(b.look)))
		names[b.name] = true
		looks[b.look] = true
	assert_eq(names.size(), BotRules.MAX_BOTS, "every name once")
	assert_eq(looks.size(), BotRules.MAX_BOTS, "every look once")
	assert_eq([back.bots[0].personality, back.bots[1].personality, back.bots[2].personality],
		["explorer", "builder", "fighter"])
	assert_eq(back.bots[1].name, "Fizz")
