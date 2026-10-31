extends GutTest


func test_names_are_case_insensitive_and_extra_spaces_are_fine() -> void:
	assert_eq(ChatCommands.parse("/FLY").get("name"), &"fly")
	assert_eq(ChatCommands.parse("   /Time    NIGHT   ").get("name"), &"time")
	assert_eq(ChatCommands.parse("   /Time    NIGHT   ").get("time"), ChatCommands.TIME_NIGHT)


func test_quoted_words_stay_together() -> void:
	assert_eq(ChatCommands.tokenize('give "deep stone"  now'), PackedStringArray(["give", "deep stone", "now"]))
	assert_eq(ChatCommands.parse('/give "Deep Stone"').get("id"), BlockIds.DEEPSTONE)


func test_unknown_command_says_try_help() -> void:
	var r := ChatCommands.parse("/moonwalk")
	assert_true(r.has("error"))
	assert_string_contains(r.error, "Try /help")
	assert_string_contains(ChatCommands.parse("/").error, "/help")


func test_tp_absolute_coordinates_land_in_the_block_centre() -> void:
	assert_eq(ChatCommands.parse("/tp 10 64 -5").get("pos"), Vector3(10.5, 64, -4.5))
	assert_eq(ChatCommands.parse("/tp 1.25 70.5 2.75").get("pos"), Vector3(1.25, 70.5, 2.75))


func test_tp_tilde_means_here() -> void:
	var here := Vector3(10.3, 64.05, -3.7)
	assert_eq(ChatCommands.parse("/tp ~ ~20 ~", here).get("pos"), Vector3(10.3, 84.05, -3.7))
	assert_eq(ChatCommands.parse("/tp ~-2 ~ ~+1.5", here).get("pos"), Vector3(8.3, 64.05, -2.2))


func test_tp_bad_numbers_give_a_friendly_error() -> void:
	for text in ["/tp 10 abc 5", "/tp ~x 1 1", "/tp 1 nan 1", "/tp 1 inf 1", "/tp 1 1e999 1"]:
		var r := ChatCommands.parse(text)
		assert_true(r.has("error"), text)
		assert_false(r.has("pos"), text)
	assert_string_contains(ChatCommands.parse("/tp 10 abc 5").error, "abc")


func test_tp_wrong_argument_count_shows_usage() -> void:
	for text in ["/tp", "/tp 1 2", "/tp 1 2 3 4", "/tp 5"]:
		var r := ChatCommands.parse(text)
		assert_true(r.has("error"), text)
		assert_string_contains(r.error, "/tp", text)


func test_tp_player_name() -> void:
	assert_eq(ChatCommands.parse("/tp Bob").get("player"), "Bob")
	assert_eq(ChatCommands.parse('/tp "Bob"').get("player"), "Bob")


func test_tp_is_clamped_to_the_world() -> void:
	var pos: Vector3 = ChatCommands.parse("/tp 99999999 9999 -99999999").pos
	assert_eq(pos, Vector3(ChatCommands.TP_LIMIT, ChatCommands.TP_MAX_Y, -ChatCommands.TP_LIMIT))
	assert_eq(ChatCommands.parse("/tp 0 -500 0").pos.y, ChatCommands.TP_MIN_Y)


func test_find_player_by_name() -> void:
	var names := {1: "Hopper", 55: "BuilderBob", 77: "Bea"}
	assert_eq(ChatCommands.find_player("hopper", names), 1)
	assert_eq(ChatCommands.find_player("builder", names), 55, "unique start of a name")
	assert_eq(ChatCommands.find_player("B", names), -1, "ambiguous")
	assert_eq(ChatCommands.find_player("Bea", names), 77, "an exact name wins over longer names")
	assert_eq(ChatCommands.find_player("Zed", names), -1)


func test_time_values() -> void:
	assert_eq(ChatCommands.parse("/time day").time, ChatCommands.TIME_DAY)
	assert_eq(ChatCommands.parse("/time night").time, ChatCommands.TIME_NIGHT)
	assert_eq(ChatCommands.parse("/time noon").time, ChatCommands.TIME_NOON)
	assert_eq(ChatCommands.parse("/time midnight").time, ChatCommands.TIME_MIDNIGHT)
	assert_eq(ChatCommands.TIME_MIDNIGHT, 0.0)
	assert_eq(ChatCommands.TIME_NOON, 0.5)   # the other values follow DayCycle (see below)
	assert_true(ChatCommands.parse("/time teatime").has("error"))
	assert_true(ChatCommands.parse("/time").has("error"))


func test_give_finds_blocks_and_items_by_name() -> void:
	assert_eq(ChatCommands.parse("/give diamond").get("id"), BlockIds.DIAMOND)
	assert_eq(ChatCommands.parse("/give DIAMOND").get("id"), BlockIds.DIAMOND)
	assert_eq(ChatCommands.parse("/give deep stone").get("id"), BlockIds.DEEPSTONE)
	assert_eq(ChatCommands.parse("/give deep_stone").get("id"), BlockIds.DEEPSTONE)
	assert_eq(ChatCommands.parse("/give magic wand").get("id"), ItemIds.WAND)
	assert_eq(ChatCommands.parse("/give BigTree").get("id"), ItemIds.STAMP_TREE)
	assert_true(ChatCommands.parse("/give bedrock").has("error"), "bedrock is never given")
	assert_true(ChatCommands.parse("/give unicorn").has("error"))
	assert_true(ChatCommands.parse("/give").has("error"))


func test_every_giveable_thing_fits_a_hotbar_slot() -> void:
	var ids := ChatCommands.giveable_ids()
	assert_true(ids.has(BlockIds.GRASS))
	assert_true(ids.has(ItemIds.WAND))
	assert_false(ids.has(BlockIds.BEDROCK))
	assert_false(ids.has(BlockIds.AIR))
	for id in ids:
		assert_true(ItemIds.is_hotbar_valid(id), str(id))
		assert_eq(ChatCommands.parse("/give %s" % ItemIds.display_name(id)).get("id"), id, ItemIds.display_name(id))


## M2 Task 16: /secret tells where the nearest secret nobody found yet is (a Sandbox cheat, for testing and
## for grown-ups helping a child).
func test_secret_asks_the_host_where_the_nearest_secret_is() -> void:
	assert_eq(ChatCommands.parse("/secret"), {"name": &"secret", "kind": &""})
	assert_eq(ChatCommands.parse("/secret Temple"), {"name": &"secret", "kind": &"temple"})
	assert_true(ChatCommands.parse("/secret dragon").has("error"))
	assert_true(ChatCommands.runs_on_host(&"secret"))
	assert_eq(ChatCommands.refusal(&"secret", true, ModeRules.SURVIVOR), ChatCommands.SANDBOX_ONLY_MESSAGE)
	assert_eq(ChatCommands.refusal(&"secret", true, ModeRules.SANDBOX), "")
	assert_eq(ChatCommands.choices(&"secret").size(), SecretRules.PLACED.size() + TreasurePlaces.KINDS.size() + 1)   # owner 42; M3 Task 21c: mice


## M2 Task 16: treasure is found by playing, never given; a fake wall is just stone to /give.
func test_treasure_is_never_given() -> void:
	for id in [BlockIds.TROPHY, BlockIds.GOLD_LAMP, ItemIds.TREASURE_MAP, BlockIds.FAKE_WALL, BlockIds.PRESSURE_PLATE]:
		assert_false(ChatCommands.giveable_ids().has(id), ItemIds.display_name(id))
	for name in ["golden trophy", "golden lamp", "treasure map"]:
		assert_string_contains(str(ChatCommands.parse("/give %s" % name).get("error", "")), "found in treasure")
	assert_eq(ChatCommands.parse("/give stone").get("id"), BlockIds.STONE)


func test_summon_animals() -> void:
	assert_eq(ChatCommands.parse("/summon Dog").get("species"), &"dog")
	assert_true(ChatCommands.parse("/summon dragon").has("error"))
	for animal in ["dog", "cat", "pig", "cow", "sheep", "chicken", "rabbit", "fish"]:
		assert_true(ChatCommands.ANIMALS.has(animal), animal)
		assert_true(AnimalRules.SPECIES.has(StringName(animal)), "%s is a species the animal system knows" % animal)


## M2 Task 4: /summon slime 3, /summon goblin 2 (Sandbox only, like every /summon).
func test_summon_monsters_with_a_level() -> void:
	var r := ChatCommands.parse("/summon Goblin 3")
	assert_eq(r.get("monster"), MonsterRules.GOBLIN)
	assert_eq(r.get("level"), 3)
	assert_false(r.has("species"), "a monster is not an animal")
	assert_eq(ChatCommands.parse("/summon slime").get("level"), 1, "level 1 when no level is given")
	assert_eq(ChatCommands.parse("/summon slime 5").get("level"), 5)
	for bad in ["/summon slime 0", "/summon slime 6", "/summon goblin big", "/summon goblin 2.5"]:
		assert_true(ChatCommands.parse(bad).has("error"), bad)
	for kind in ChatCommands.MONSTERS:   # owner #39: through the typed word ("shadowbat" is the shadow_bat)
		assert_true(MonsterRules.KINDS.has(ChatCommands.monster_kind(kind)), "%s is a kind the monster system knows" % kind)
	assert_eq(ChatCommands.host_check("/summon goblin 2", true, ModeRules.SANDBOX).get("monster"), MonsterRules.GOBLIN)
	assert_eq(ChatCommands.host_check("/summon slime 3", true, ModeRules.SURVIVOR).get("error"),
		ChatCommands.SANDBOX_ONLY_MESSAGE, "a cheat in Survivor")
	assert_true(ChatCommands.suggestions("/summon ").has("/summon slime"))
	assert_true(ChatCommands.suggestions("/summon go").has("/summon goblin"))
	assert_string_contains(ChatCommands.usage(&"summon"), "goblin")


func test_size_jumps_style() -> void:
	assert_eq(ChatCommands.parse("/size giant").get("mode"), SizeMagic.Mode.GIANT)
	assert_eq(ChatCommands.parse("/size tiny").get("mode"), SizeMagic.Mode.TINY)
	assert_eq(ChatCommands.parse("/size normal").get("mode"), SizeMagic.Mode.NORMAL)
	assert_true(ChatCommands.parse("/size huge").has("error"))
	assert_eq(ChatCommands.parse("/jumps 2").get("count"), 2)
	assert_eq(ChatCommands.parse("/jumps 3").get("count"), 3)
	for bad in ["/jumps 4", "/jumps 1", "/jumps two", "/jumps"]:
		assert_true(ChatCommands.parse(bad).has("error"), bad)
	assert_eq(ChatCommands.parse("/style Realistic").get("style"), "realistic")
	assert_eq(ChatCommands.parse("/style blocky").get("style"), "blocky")
	assert_true(ChatCommands.parse("/style cartoon").has("error"))


func test_commands_without_arguments() -> void:
	for name in ["spawn", "home", "fly", "ghost", "walk", "seed", "clear", "help"]:
		var r := ChatCommands.parse("/" + name)
		assert_false(r.has("error"), name)
		assert_eq(r.get("name"), StringName(name))
	assert_eq(ChatCommands.parse("/fly please").get("name"), &"fly", "extra words are ignored")


func test_help_topic() -> void:
	assert_eq(ChatCommands.parse("/help").get("topic"), &"")
	assert_eq(ChatCommands.parse("/help /TP").get("topic"), &"tp")
	assert_true(ChatCommands.parse("/help moonwalk").has("error"))
	assert_string_contains(ChatCommands.help_lines(&"")[0], "/tp")
	assert_string_contains(ChatCommands.help_lines(&"time")[0], ChatCommands.usage(&"time"))


func test_every_command_has_usage_text() -> void:
	for name in ["help", "tp", "spawn", "home", "time", "give", "summon", "fly", "ghost", "walk", "size", "jumps",
			"style", "seed", "clear"]:
		assert_true(ChatCommands.COMMANDS.has(StringName(name)), name)
	for name: StringName in ChatCommands.COMMANDS:
		assert_string_starts_with(ChatCommands.usage(name), "/" + String(name), String(name))
		assert_ne(ChatCommands.about(name), "", String(name))


func test_suggestions_for_a_command_prefix() -> void:
	assert_true(ChatCommands.suggestions("/ti").has("/time"))
	assert_false(ChatCommands.suggestions("/ti").has("/tp"))
	assert_eq(ChatCommands.suggestions("/").size(), ChatCommands.COMMANDS.size())
	assert_true(ChatCommands.suggestions("/S").has("/spawn"), "case-insensitive")
	assert_eq(ChatCommands.suggestions("hello"), [] as Array[String])


func test_suggestions_for_arguments() -> void:
	var s := ChatCommands.suggestions("/time n")
	assert_true(s.has("/time night"))
	assert_true(s.has("/time noon"))
	assert_false(s.has("/time day"))
	assert_eq(ChatCommands.suggestions("/time ").size(), ChatCommands.TIMES.size())
	assert_true(ChatCommands.suggestions("/give dia").has("/give diamond"))
	assert_true(ChatCommands.suggestions("/give deeps").has("/give deep stone"))
	assert_true(ChatCommands.suggestions("/summon ").has("/summon dog"))
	assert_true(ChatCommands.suggestions("/tp b", ["Bob", "Hopper"]).has("/tp Bob"))
	assert_eq(ChatCommands.suggestions("/fly "), [] as Array[String])


func test_every_suggestion_is_a_valid_command() -> void:
	for name: StringName in ChatCommands.COMMANDS:
		for s in ChatCommands.suggestions("/%s " % name, ["Bob"]):
			assert_false(ChatCommands.parse(s).has("error"), s)


func test_world_changing_commands_run_on_the_host() -> void:
	for name in [&"time", &"home", &"summon"]:
		assert_true(ChatCommands.runs_on_host(name), name)
	for name in [&"tp", &"give", &"fly", &"size", &"jumps", &"style", &"help", &"clear", &"seed", &"spawn"]:
		assert_false(ChatCommands.runs_on_host(name), name)


func test_host_runs_only_world_changing_commands_sent_over_the_network() -> void:
	assert_eq(ChatCommands.host_check("/time night", true, ModeRules.SANDBOX).get("name"), &"time")
	assert_eq(ChatCommands.host_check("/summon cat", true, ModeRules.SANDBOX).get("species"), &"cat")
	assert_true(ChatCommands.host_check("/give diamond", true, ModeRules.SANDBOX).has("error"), "a raw request for a local command")
	assert_true(ChatCommands.host_check("/time teatime", true, ModeRules.SANDBOX).has("error"))
	assert_true(ChatCommands.host_check("hello", true, ModeRules.SANDBOX).has("error"))


func test_commands_can_be_switched_off() -> void:
	assert_true(ChatCommands.host_check("/time night", false, ModeRules.SANDBOX).has("error"))
	assert_eq(ChatCommands.refusal(&"help", false, ModeRules.SANDBOX), "")
	assert_eq(ChatCommands.refusal(&"tp", false, ModeRules.SANDBOX), ChatCommands.OFF_MESSAGE)
	assert_eq(ChatCommands.refusal(&"tp", true, ModeRules.SANDBOX), "")


## Integration (Tasks 10 + 12): /time words must land in the matching phase of the real cycle.
func test_time_words_match_the_day_cycle() -> void:
	assert_true(DayCycle.is_night(ChatCommands.TIME_NIGHT), "night")
	assert_true(DayCycle.is_night(ChatCommands.TIME_MIDNIGHT), "midnight")
	assert_false(DayCycle.is_night(ChatCommands.TIME_DAY), "day")
	assert_false(DayCycle.is_night(ChatCommands.TIME_NOON), "noon")
	assert_eq(ChatCommands.TIME_SUNRISE, DayCycle.SUNRISE)
	assert_eq(ChatCommands.TIME_SUNSET, DayCycle.SUNSET)


## M2 §12.1: cheats are off in Survivor; the rest works in both modes.
func test_survivor_refuses_cheats_but_not_the_rest() -> void:
	for name: StringName in [&"tp", &"spawn", &"home", &"give", &"fly", &"ghost", &"time", &"summon", &"size"]:
		assert_eq(ChatCommands.refusal(name, true, ModeRules.SURVIVOR), ChatCommands.SANDBOX_ONLY_MESSAGE, String(name))
		assert_eq(ChatCommands.refusal(name, true, ModeRules.SANDBOX), "", "sandbox: %s" % name)
	for name: StringName in [&"help", &"walk", &"jumps", &"style", &"seed", &"clear"]:
		assert_eq(ChatCommands.refusal(name, true, ModeRules.SURVIVOR), "", "survivor: %s" % name)
	assert_eq(ChatCommands.refusal(&"seed", false, ModeRules.SANDBOX), ChatCommands.OFF_MESSAGE, "commands off")
	assert_eq(ChatCommands.refusal(&"help", false, ModeRules.SURVIVOR), "", "/help always works")
	assert_eq(ChatCommands.host_check("/time night", true, ModeRules.SURVIVOR).get("error", ""),
		ChatCommands.SANDBOX_ONLY_MESSAGE, "the host checks it too")
