extends GutTest
## Owner feedback #40 ("add more commands in the game"): the new commands' parsing (good and bad input,
## counts, names), Sandbox vs Survivor, host vs local, the help list and the "/" buttons by mode. (Its Georgian
## names were removed by owner #52: English only.)

const NEW: Array[StringName] = [&"weather", &"heal", &"peace", &"freeze", &"kit", &"speed", &"gravity",
	&"universe", &"build", &"dance", &"emote", &"pet", &"bot", &"boss", &"xp", &"level", &"music", &"photo",
	&"save", &"clearbag", &"find"]
## What Survivor allows (the brief: /find, /save, /music, /photo, /dance, /help …). The rule this file keeps.
const SURVIVOR_ALLOWS: Array[StringName] = [&"help", &"walk", &"jumps", &"style", &"seed", &"clear", &"dance",
	&"emote", &"pet", &"bot", &"xp", &"level", &"music", &"photo", &"save", &"clearbag", &"find", &"universe"]
## Only where blocks are counted and universes are worlds of their own.
const SURVIVOR_ONLY: Array[StringName] = [&"clearbag", &"universe"]
const HOST: Array[StringName] = [&"weather", &"heal", &"peace", &"freeze", &"pet", &"boss", &"clearbag"]
const SURVIVOR := {"mode": ModeRules.SURVIVOR, "enabled": true}
const SANDBOX := {"mode": ModeRules.SANDBOX, "enabled": true}


func _p(text: String) -> Dictionary:
	return ChatCommands.parse(text)


func _bad(texts: Array) -> void:
	for t: String in texts:
		assert_true(_p(t).has("error"), t)


func test_every_new_command_has_usage_about_and_a_handler() -> void:
	var runner := ChatCommandRunner.new()
	for name in NEW:
		assert_true(ChatCommands.COMMANDS.has(name), String(name))
		assert_string_starts_with(ChatCommands.usage(name), "/" + String(name), String(name))
		assert_ne(ChatCommands.about(name), "", String(name))
		assert_true(runner.has_method(ChatCommandRunner.handler_name(name)), "handler for /%s" % name)
	runner.free()


## M3 Task 8 brought /fill and /copy with the building tools: Sandbox cheats that run on this game (the host checks
## the edits like the FILL and COPY tools'), rate-limited like /build.
func test_fill_and_copy_came_with_the_building_tools() -> void:
	for name: StringName in [&"fill", &"copy"]:
		assert_true(ChatCommands.COMMANDS.has(name), String(name))
		assert_eq(ChatCommands.refusal(name, true, ModeRules.SURVIVOR), ChatCommands.SANDBOX_ONLY_MESSAGE, String(name))
		assert_eq(ChatCommands.refusal(name, true, ModeRules.SANDBOX), "", String(name))
		assert_false(ChatCommands.runs_on_host(name), String(name))
		assert_true(ChatCommands.LIMITED.has(name), String(name))
		var runner := ChatCommandRunner.new()
		assert_true(runner.has_method(ChatCommandRunner.handler_name(name)), String(name))
		runner.free()
	assert_eq(_p("/copy").get("name"), &"copy")


func test_fill_takes_a_block_and_a_size() -> void:
	var cmd := _p("/fill stone")
	assert_eq(cmd.get("id"), BlockIds.STONE)
	assert_eq(cmd.get("size"), Vector3i(3, 3, 3), "3 x 3 x 3 when no size is given")
	assert_eq(_p("/fill glass 5").get("size"), Vector3i(5, 5, 5))
	assert_eq(_p("/fill red 4 2 6").get("size"), Vector3i(4, 2, 6))
	assert_eq(_p("/fill Painted Pink 2").get("id"), BlockIds.PAINTED_PINK)
	assert_eq(_p("/fill painted sky blue 16").get("size"), Vector3i(16, 16, 16), "16 x 16 x 16 is 4,096: the cap")
	_bad(["/fill", "/fill wand", "/fill stone 17", "/fill stone 0", "/fill bedrock", "/fill stone 2 3", "/fill 3",
		"/fill red paint", "/fill golden trophy 2"])


# --- Each command's words ---------------------------------------------------------------------

func test_weather_words() -> void:
	for w in ["clear", "rain", "snow", "sandstorm"]:
		assert_eq(_p("/weather " + w).get("weather"), StringName(w), w)
	assert_eq(_p("/Weather SNOW").get("weather"), &"snow")
	_bad(["/weather", "/weather hail", "/weather 3"])


func test_weather_is_only_what_the_universe_has() -> void:
	assert_eq(ChatCommands.weather_refusal(&"clear", &""), "")
	assert_eq(ChatCommands.weather_refusal(&"sandstorm", &"sandstorm"), "")
	assert_eq(ChatCommands.weather_refusal(&"snow", &"snowstorm"), "")
	assert_ne(ChatCommands.weather_refusal(&"sandstorm", &""), "", "no sandstorms in Green Meadows")
	assert_ne(ChatCommands.weather_refusal(&"snow", &"sandstorm"), "", "no snow in the desert")
	assert_ne(ChatCommands.weather_refusal(&"rain", &""), "", "no rain anywhere yet")
	assert_eq(ChatCommands.weather_choices(&""), ["clear"] as Array[String])
	assert_eq(ChatCommands.weather_choices(&"sandstorm"), ["clear", "sandstorm"] as Array[String])
	assert_eq(ChatCommands.weather_choices(&"snowstorm"), ["clear", "snow"] as Array[String])
	assert_eq(ChatCommands.suggestions("/weather ", [], {"weather": &"snowstorm"}),
		["/weather clear", "/weather snow"] as Array[String], "the buttons show what this universe has")


func test_commands_without_arguments() -> void:
	for name in ["heal", "kit", "pet", "boss", "xp", "level", "photo", "save", "clearbag"]:
		var r := _p("/" + name)
		assert_false(r.has("error"), name)
		assert_eq(r.get("name"), StringName(name))


func test_peace_and_freeze_switch_on_off_or_both_ways() -> void:
	for name in ["peace", "freeze"]:
		assert_eq(_p("/%s" % name).get("switch"), &"toggle", name)
		assert_eq(_p("/%s on" % name).get("switch"), &"on", name)
		assert_eq(_p("/%s OFF" % name).get("switch"), &"off", name)
		_bad(["/%s maybe" % name])
	assert_true(ChatCommands.switch_value(&"toggle", false))
	assert_false(ChatCommands.switch_value(&"toggle", true))
	assert_true(ChatCommands.switch_value(&"on", true))
	assert_false(ChatCommands.switch_value(&"off", false))


func test_give_takes_a_count() -> void:
	var r := _p("/give planks 64")
	assert_eq(r.get("id"), BlockIds.PLANKS)
	assert_eq(r.get("count"), 64)
	assert_eq(_p("/give planks").get("count"), 1, "one when no count is given")
	assert_eq(_p("/give deep stone 5").get("id"), BlockIds.DEEPSTONE)
	assert_eq(_p("/give deep stone 5").get("count"), 5)
	assert_eq(_p("/give 12 glass").get("count"), 12, "the count may come first")
	assert_eq(_p("/give 12 glass").get("id"), BlockIds.GLASS)
	assert_eq(_p("/give planks %d" % ChatCommands.MAX_GIVE).get("count"), ChatCommands.MAX_GIVE)
	for bad in ["/give planks 0", "/give planks 1000", "/give planks -3"]:
		assert_string_contains(str(_p(bad).get("error", "")), str(ChatCommands.MAX_GIVE), bad)
	_bad(["/give planks 2.5", "/give 64"])
	assert_eq(ChatCommands.give_words(BlockIds.PLANKS, 1), "You got Planks!")
	assert_eq(ChatCommands.give_words(BlockIds.PLANKS, 64), "You got 64 Planks!")


func test_the_builders_kit_fits_the_hotbar() -> void:
	assert_eq(ChatCommands.KIT.size(), WorldMeta.HOTBAR_SIZE)
	for id in ChatCommands.KIT:
		assert_true(ItemIds.is_hotbar_valid(id), str(id))
		assert_false(ChatCommands.NEVER_GIVEN.has(id), str(id))
	assert_true(ChatCommands.KIT.has(BlockIds.PLANKS))


func test_speed_one_to_three() -> void:
	for n in [1, 2, 3]:
		assert_eq(_p("/speed %d" % n).get("speed"), n)
	assert_eq(_p("/speed slow").get("speed"), 1)
	assert_eq(_p("/speed Normal").get("speed"), 2)
	assert_eq(_p("/speed fast").get("speed"), 3)
	_bad(["/speed", "/speed 0", "/speed 4", "/speed turbo"])


func test_gravity_is_the_physics_labs() -> void:
	assert_eq(_p("/gravity moon").get("gravity"), LabRules.Mode.MOON)
	assert_eq(_p("/gravity zero").get("gravity"), LabRules.Mode.ZERO_G)
	assert_eq(_p("/gravity normal").get("gravity"), LabRules.Mode.NORMAL)
	_bad(["/gravity", "/gravity mars"])


func test_universe_by_number_or_name() -> void:
	assert_eq(_p("/universe 2").get("universe"), 2)
	assert_eq(_p("/universe desert").get("universe"), 2)
	assert_eq(_p("/universe Frostpeak").get("universe"), 3)
	assert_eq(_p("/universe green meadows").get("universe"), 1)
	assert_eq(_p("/universe dragon realm").get("universe"), 5, "owner 39: the Dragon Realm")
	assert_eq(_p("/universe 5").get("universe"), 5)
	for bad in ["/universe 0", "/universe 99"]:
		assert_string_contains(str(_p(bad).get("error", "")), str(UniverseRegistry.size()), bad)
	_bad(["/universe", "/universe mars"])
	assert_eq(ChatCommands.choices(&"universe", [], {"universes": [1, 2]}), ["meadows", "desert"] as Array[String])


func test_build_the_stamps_in_front() -> void:
	assert_eq(_p("/build house").get("stamp"), ItemIds.STAMP_HOUSE)
	assert_eq(_p("/build tower").get("stamp"), ItemIds.STAMP_TOWER)
	assert_eq(_p("/build bridge").get("stamp"), ItemIds.STAMP_BRIDGE)
	assert_eq(_p("/build tree").get("stamp"), ItemIds.STAMP_TREE)
	assert_eq(_p("/build Rainbow").get("stamp"), ItemIds.STAMP_RAINBOW)
	_bad(["/build", "/build castle"])
	# two blocks ahead of the feet, on the feet's level (the stamp's floor replaces the ground under it)
	assert_eq(ChatCommands.build_anchor(Vector3(10.3, 64.0, -5.7), Vector3i(0, 0, -1)), Vector3i(10, 64, -8))
	assert_eq(ChatCommands.build_anchor(Vector3(0.5, 70.2, 0.5), Vector3i(1, 0, 0)), Vector3i(2, 70, 0))


func test_dance_and_emote_names() -> void:
	assert_eq(_p("/dance").get("emote"), &"", "any dance you own")
	assert_eq(_p("/dance robot").get("emote"), &"dance_robot")
	assert_eq(_p("/dance hop").get("emote"), &"dance_hop")
	assert_eq(_p("/dance star").get("emote"), &"dance_star")
	assert_eq(_p("/dance victory").get("emote"), &"victory")
	_bad(["/dance twerk"])
	assert_eq(_p("/emote wave").get("emote"), &"wave")
	assert_eq(_p("/emote thumbs up").get("emote"), &"thumbs_up")
	assert_eq(_p("/emote Thumbs_Up").get("emote"), &"thumbs_up")
	_bad(["/emote", "/emote fly"])
	for e: StringName in EmotePoses.DURATIONS:
		assert_eq(_p("/emote %s" % e).get("emote"), e, String(e))
		assert_true(ChatCommands.choices(&"emote").has(String(e)), String(e))


func test_only_emotes_you_own_play() -> void:
	var free := ChatCommands.owned_dances([])
	assert_true(free.has(&"dance_hop"))
	assert_true(free.has(&"dance_robot"))
	assert_false(free.has(&"dance_star"), "the Star Spin is bought")
	assert_false(free.has(&"victory"), "the Victory dance is earned")
	assert_true(ChatCommands.owned_dances(["emote.dance_star"]).has(&"dance_star"))
	assert_true(ChatCommands.owns_emote(&"wave", []))
	assert_false(ChatCommands.owns_emote(&"bow", []))
	assert_true(ChatCommands.owns_emote(&"bow", ["emote.bow"]))


func test_bot_add_and_remove() -> void:
	var r := _p("/bot add")
	assert_eq(r.get("action"), &"add")
	assert_eq(r.get("personality"), &"", "any friend")
	assert_eq(_p("/bot add Fighter").get("personality"), BotRules.FIGHTER)
	r = _p("/bot remove Pip")
	assert_eq(r.get("action"), &"remove")
	assert_eq(r.get("bot"), "Pip")
	assert_eq(_p("/bot remove").get("bot"), "", "the only friend")
	_bad(["/bot", "/bot jump", "/bot add dragon"])
	var s := ChatCommands.suggestions("/bot ", [], {"bots": ["Pip"]})
	assert_true(s.has("/bot add builder"))
	assert_true(s.has("/bot remove Pip"))
	assert_eq(ChatCommands.suggestions("/bot rem", [], {"bots": ["Pip", "Bolt"]}),
		["/bot remove Pip", "/bot remove Bolt"] as Array[String])


func test_music_words() -> void:
	for m in ["next", "classical", "game", "on", "off"]:
		assert_eq(_p("/music " + m).get("music"), StringName(m), m)
	_bad(["/music", "/music loud"])


func test_find_words() -> void:
	for t in ["tilly", "home", "portal", "treasure", "launch"]:   # owner #98: /find launch
		assert_eq(_p("/find " + t).get("target"), StringName(t), t)
	_bad(["/find", "/find dragon"])


## yaw 0 looks along -Z; +X is on the right.
func test_find_says_how_far_and_which_way() -> void:
	var here := Vector3(0, 64, 0)
	var ahead := ChatCommands.find_words("Tilly", here, Vector3(0, 64, -42), 0.0)
	assert_string_contains(ahead, "Tilly")
	assert_string_contains(ahead, "42 blocks")
	assert_string_contains(ahead, "ahead")
	assert_string_contains(ChatCommands.find_words("Tilly", here, Vector3(30, 64, 0), 0.0), "right")
	assert_string_contains(ChatCommands.find_words("Tilly", here, Vector3(-30, 64, 0), 0.0), "left")
	assert_string_contains(ChatCommands.find_words("Tilly", here, Vector3(0, 64, 30), 0.0), "behind")
	assert_string_contains(ChatCommands.find_words("Tilly", here, Vector3(0, 64, 30), PI), "ahead", "turned round")
	assert_string_contains(ChatCommands.find_words("the portal", here, Vector3(0, 90, -40), 0.0), "up")
	assert_string_contains(ChatCommands.find_words("your bed", here, Vector3(1, 64, 1), 0.0), "right here")
	assert_string_starts_with(ChatCommands.find_words("your bed", here, Vector3(1, 64, 1), 0.0), "Your bed")


## Fair fun (§6, §12.16): treasure is found by playing. In Survivor /find treasure needs a Treasure Map.
func test_find_treasure_in_survivor_needs_a_map() -> void:
	assert_ne(ChatCommands.find_refusal(&"treasure", ModeRules.SURVIVOR, false), "")
	assert_eq(ChatCommands.find_refusal(&"treasure", ModeRules.SURVIVOR, true), "")
	assert_eq(ChatCommands.find_refusal(&"treasure", ModeRules.SANDBOX, false), "")
	for t: StringName in [&"tilly", &"home", &"portal"]:
		assert_eq(ChatCommands.find_refusal(t, ModeRules.SURVIVOR, false), "", String(t))


func test_xp_and_level_words() -> void:
	var d := ProgressData.new()
	d.xp = LevelRules.xp_to_reach(3) + 10
	var to_next := LevelRules.xp_to_reach(4) - d.xp
	assert_string_contains(ChatCommands.xp_words(d), str(d.xp))
	assert_string_contains(ChatCommands.xp_words(d), str(to_next))
	assert_string_contains(ChatCommands.level_words(d), "Level 3")
	assert_string_contains(ChatCommands.level_words(d), "level 4")
	d.xp = LevelRules.xp_to_reach(LevelRules.MAX_LEVEL) + 5
	assert_string_contains(ChatCommands.level_words(d), "top")


func test_pets_words() -> void:
	assert_string_contains(ChatCommands.pets_words([]), "no pets")
	assert_eq(ChatCommands.pets_words(["Biscuit"]), "Biscuit is coming!")
	assert_eq(ChatCommands.pets_words(["Biscuit", "Luna"]), "Biscuit and Luna are coming!")
	assert_eq(ChatCommands.pets_words(["Biscuit", "Luna", "Max"]), "Biscuit, Luna and Max are coming!")


## /clearbag asks twice: the second one within CLEARBAG_SECONDS empties the bag.
func test_clearbag_asks_twice() -> void:
	assert_false(ChatCommands.confirmed(-INF, 100.0))
	assert_true(ChatCommands.confirmed(100.0, 110.0))
	assert_false(ChatCommands.confirmed(100.0, 100.0 + ChatCommands.CLEARBAG_SECONDS + 1.0))


# --- Sandbox vs Survivor ----------------------------------------------------------------------

func test_survivor_allows_exactly_its_list() -> void:
	for name: StringName in ChatCommands.COMMANDS:
		assert_eq(ChatCommands.refusal(name, true, ModeRules.SURVIVOR) == "", SURVIVOR_ALLOWS.has(name), String(name))


func test_sandbox_allows_everything_but_the_survivor_only_ones() -> void:
	for name: StringName in ChatCommands.COMMANDS:
		assert_eq(ChatCommands.refusal(name, true, ModeRules.SANDBOX) == "", not SURVIVOR_ONLY.has(name), String(name))
	assert_eq(ChatCommands.refusal(&"clearbag", true, ModeRules.SANDBOX), ChatCommands.ENDLESS_BAG_MESSAGE)
	assert_eq(ChatCommands.refusal(&"universe", true, ModeRules.SANDBOX), ChatCommands.ONE_WORLD_MESSAGE)
	# owner #39: each universe has its own Sandbox world, reached through a portal the child builds
	assert_true(ChatCommands.ONE_WORLD_MESSAGE.contains("portal"), ChatCommands.ONE_WORLD_MESSAGE)
	assert_false(ChatCommands.ONE_WORLD_MESSAGE.contains("one world"), "no longer true since owner #39")


func test_new_cheats_say_sandbox_only_in_survivor() -> void:
	for name: StringName in [&"weather", &"heal", &"peace", &"freeze", &"kit", &"speed", &"gravity", &"build", &"boss"]:
		assert_eq(ChatCommands.refusal(name, true, ModeRules.SURVIVOR), ChatCommands.SANDBOX_ONLY_MESSAGE, String(name))


func test_commands_off_leave_only_help() -> void:
	for name in NEW:
		assert_eq(ChatCommands.refusal(name, false, ModeRules.SANDBOX), ChatCommands.OFF_MESSAGE, String(name))


# --- Host vs local ----------------------------------------------------------------------------

func test_where_the_new_commands_run() -> void:
	for name in NEW:
		assert_eq(ChatCommands.runs_on_host(name), HOST.has(name), String(name))


func test_the_host_checks_the_new_commands() -> void:
	assert_eq(ChatCommands.host_check("/weather snow", true, ModeRules.SANDBOX).get("weather"), &"snow")
	assert_eq(ChatCommands.host_check("/heal", true, ModeRules.SURVIVOR).get("error"), ChatCommands.SANDBOX_ONLY_MESSAGE)
	assert_eq(ChatCommands.host_check("/clearbag", true, ModeRules.SURVIVOR).get("name"), &"clearbag")
	assert_eq(ChatCommands.host_check("/clearbag", true, ModeRules.SANDBOX).get("error"), ChatCommands.ENDLESS_BAG_MESSAGE)
	assert_eq(ChatCommands.host_check("/pet", true, ModeRules.SURVIVOR).get("name"), &"pet")
	assert_true(ChatCommands.host_check("/kit", true, ModeRules.SANDBOX).has("error"), "a raw request for a local one")
	assert_true(ChatCommands.host_check("/peace", false, ModeRules.SANDBOX).has("error"), "commands off")


func test_heavy_local_commands_are_rate_limited() -> void:
	for name: StringName in [&"build", &"save", &"bot"]:
		assert_true(ChatCommands.LIMITED.has(name), String(name))
	assert_false(ChatCommands.LIMITED.has(&"help"))


# --- The help list and the "/" buttons --------------------------------------------------------

func _help_names(ctx: Dictionary) -> Array:
	var out := []
	for w in ChatCommands.help_lines(&"", ctx)[0].trim_prefix("Commands: ").split(" "):
		out.append(StringName(w.trim_prefix("/")))
	return out


func test_help_lists_exactly_what_a_child_may_use() -> void:
	var survivor := _help_names(SURVIVOR)
	var sandbox := _help_names(SANDBOX)
	for name: StringName in ChatCommands.COMMANDS:
		assert_eq(survivor.has(name), SURVIVOR_ALLOWS.has(name), "survivor: %s" % name)
		assert_eq(sandbox.has(name), not SURVIVOR_ONLY.has(name), "sandbox: %s" % name)
	assert_eq(_help_names({"mode": ModeRules.SANDBOX, "enabled": false}), [&"help"], "commands off: /help")
	assert_eq(_help_names({}).size(), ChatCommands.COMMANDS.size(), "no mode given: everything")


func test_slash_buttons_follow_the_mode() -> void:
	var s := ChatCommands.suggestions("/", [], SURVIVOR)
	assert_eq(s.size(), SURVIVOR_ALLOWS.size())
	for name in SURVIVOR_ALLOWS:
		assert_true(s.has("/" + String(name)), String(name))
	assert_false(ChatCommands.suggestions("/", [], SANDBOX).has("/clearbag"))
	assert_true(ChatCommands.suggestions("/", [], SANDBOX).has("/weather"))


func test_every_new_suggestion_is_a_valid_command() -> void:
	var ctx := {"bots": ["Pip"], "universes": [1, 2, 3], "weather": &"sandstorm"}
	for name in NEW:
		for s in ChatCommands.suggestions("/%s " % name, [], ctx):
			assert_false(ChatCommands.parse(s).has("error"), s)


func test_the_live_context() -> void:
	var c := ChatCommands.context(ModeRules.SURVIVOR, true, 2, 3, ["Pip"])
	assert_eq(c.mode, ModeRules.SURVIVOR)
	assert_eq(c.enabled, true)
	assert_eq(c.weather, &"sandstorm", "the Sandstorm Desert's weather")
	assert_true((c.universes as Array).has(1))
	assert_true((c.universes as Array).has(2))
	assert_eq(c.bots, ["Pip"])
	assert_eq(ChatCommands.context(ModeRules.SANDBOX, true, 1, 1).weather, &"", "Green Meadows: clear skies only")


# --- English only (owner #52) ------------------------------------------------------------------

func test_commands_have_english_names_only() -> void:
	for name: StringName in ChatCommands.COMMANDS:
		assert_eq(ChatCommands.command_name(String(name)), name)
		assert_false(ChatCommands.COMMANDS[name].has("ge"), "%s has no Georgian name" % name)
	assert_eq(ChatCommands.command_name("dragon"), &"")
	assert_true(ChatCommands.parse("/\u10D0\u10DB").has("error"), "Georgian letters are no command")
	for s2 in ChatCommands.suggestions("/"):
		assert_true(s2.unicode_at(1) < 128, "the / list is English: %s" % s2)
	var help := ChatCommands.help_lines(&"weather")[0]
	assert_true(help.begins_with("/weather "), "/help names only the English command: %s" % help)
	assert_null(RegEx.create_from_string("[\\x{10A0}-\\x{10FF}]").search(help), "no Georgian: %s" % help)
