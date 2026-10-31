extends GutTest
## Owner #112, #113, #117, #118 (docs/design/life-skills.md §5 rows 7, 10, 11; §14 row 14; Life L3c): Life's third wave's
## last part as data: Online City (a calm town of pretend games, chats and news on a play tablet), Find Your Way (lost at
## the market, a school fire drill, a metro with two lines, a map and a compass) and Home Helper (the washing, folding,
## socks, tidying, recycling, plants, a pet, the smoke alarm's test, the table, the dishwasher). Each on the Little, Middle
## and Big track; safe mistakes only where a wrong way is a real danger (Online City, Find Your Way), never on Little and
## never in Home Helper's chores; the game's own password rules (#105); nothing personal typed, kept or sent; no lockdown;
## no stranger grabbing or following; no unkind words worse than "you're bad at this game"; every fact with its source.

const L3C: Array[String] = ["online_city", "find_way", "home_helper"]
## Never in L3c's words (the brief: calm, never scary; no lockdowns; nothing personal typed; no microphone).
const NEVER: Array[String] = ["lockdown", "intruder", "grab", "grabs", "kidnap", "abduct", "snatch", "follows you",
	"following you", "chases", "hate", "ugly", "stupid", "loser", "idiot", "microphone", "type your", "enter your",
	"write your", "record your", "your real name", "kill", "weapon"]


func _steps(id: String, track: String, expert: bool = false, region: String = "ge") -> Array[Dictionary]:
	return LifeExperience.steps(id, track, expert, 1, region)


func _step(id: String, track: String, step_id: String, expert: bool = false) -> Dictionary:
	for s in _steps(id, track, expert):
		if str(s.id) == step_id:
			return s
	return {}


func _words(id: String, track: String, expert: bool = false, region: String = "ge") -> String:
	var out: Array[String] = []
	for s in _steps(id, track, expert, region):
		out.append(str(s.get("say", "")))
		out.append(str(s.get("done", "")))
		for c: Variant in s.get("choices", []):
			out.append(str((c as Dictionary).get("text", "")))
			out.append(str((c as Dictionary).get("why", "")))
		var m: Variant = s.get("safe_mistake")
		if m is Dictionary:
			out.append_array([str(m.get("wrong", "")), str(m.get("why", "")), str(m.get("right", ""))])
		for key: String in ["lines", "not"]:
			var d: Variant = s.get(key)
			if d is Dictionary:
				for k: Variant in d:
					out.append(str(d[k]))
	var card := LifeExperience.card(id, track, region)
	out.append_array(card.get("lines", []))
	out.append(LifeExperience.words(id, track, "try_real", region))
	return " ".join(out)


func _mistakes(id: String, track: String) -> Dictionary:
	var out := {}
	for expert: bool in [false, true]:
		for s in _steps(id, track, expert):
			if s.get("safe_mistake") is Dictionary:
				out[str(s.safe_mistake.event)] = s
	return out


func test_the_three_are_known_with_no_problems() -> void:
	for id in L3C:
		assert_has(LifeExperience.IDS, id)
		assert_eq(LifeExperience.problems(id), [] as Array[String], id)
	assert_eq(str(LifeExperience.data("online_city").area), "online", "Life online")
	assert_eq(str(LifeExperience.data("find_way").area), "around", "Getting around")
	assert_eq(str(LifeExperience.data("home_helper").area), "home", "Home and everyday")
	assert_true(LifeExperience.emergency("online_city"), "a calm debrief after strangers and scams (a ruling)")
	assert_true(LifeExperience.emergency("find_way"), "a calm debrief after getting lost and the drill")
	assert_false(LifeExperience.emergency("home_helper"), "chores: no debrief")
	assert_eq(LifeRooms.KINDS.slice(-3), ["online", "find_way", "home_helper"] as Array[String])


func test_safe_mistakes_only_where_a_wrong_way_is_a_real_danger() -> void:
	assert_true(_mistakes("online_city", "middle").has("photo_sent"), "answering a stranger who asks for a photo")
	assert_eq(str(_mistakes("online_city", "middle").photo_sent.safe_mistake.try), "send_photo")
	assert_true(_mistakes("online_city", "big").has("scam_hook"), "clicking the free gold scam")
	assert_eq(str(_mistakes("online_city", "big").scam_hook.safe_mistake.try), "get_gold")
	assert_true(_mistakes("find_way", "middle").has("walk_off"), "walking off with someone who says come with me")
	assert_eq(str(_mistakes("find_way", "middle").walk_off.safe_mistake.try), "come_with")
	assert_true(_mistakes("find_way", "big").has("edge_wind"), "waiting at the platform's edge")
	for id in L3C:
		for expert: bool in [false, true]:
			for s in _steps(id, "little", expert):
				assert_false(s.has("safe_mistake"), "%s little %s: the coach guides first" % [id, s.id])
	for track in LifeData.TRACKS:
		for expert: bool in [false, true]:
			for s in _steps("home_helper", track, expert):
				assert_false(s.has("safe_mistake"), "home_helper.%s %s: no mistake for a chore" % [track, s.id])
	for id: String in ["online_city", "find_way"]:
		for track: String in ["middle", "big"]:
			for event: String in _mistakes(id, track):
				var s: Dictionary = _mistakes(id, track)[event]
				assert_true(LifeCheck.tries_mistake(s), "%s.%s %s: the child can try it" % [id, track, event])
				assert_true(LifeIcons.has(str(s.safe_mistake.get("icon", ""))), "%s.%s %s: the why card's picture" % [id,
					track, event])


## Owner #105's rules are Online City's password lesson: the game's own words, and every weak example the game itself
## would refuse (PasswordRules: at least 6, never the name, nothing easy to guess).
func test_the_games_own_password_rules() -> void:
	for pair: Array in [["middle", "password", "bobo"], ["big", "password", "kiki"]]:
		var s := _step("online_city", str(pair[0]), str(pair[1]))
		assert_false(s.is_empty(), "%s: the password step" % pair[0])
		var right := str((s.choices as Array)[int(s.answer)].text)
		assert_string_contains(right, "two words and a number", "the game's own idea (PasswordRules.IDEA), never a password to copy")
		for i in (s.choices as Array).size():
			if i == int(s.answer):
				continue
			var weak := str((s.choices as Array)[i].text)
			assert_ne(PasswordRules.problem(weak, str(pair[2])), "", "%s: the game refuses '%s' too" % [pair[0], weak])
	for track: String in ["middle", "big"]:
		assert_string_contains(_words("online_city", track), PasswordRules.NEVER_TELL, track + ": never shared, even with a friend")
	assert_string_contains(_words("online_city", "big"), "5 wrong tries in 15 minutes", "the game's own brake (#105)")


func test_nothing_personal_is_typed_kept_or_sent_and_everything_is_calm() -> void:
	for id in L3C:
		for track in LifeData.TRACKS:
			for expert: bool in [false, true]:
				var w := _words(id, track, expert).to_lower()
				for never: String in NEVER:
					assert_false(RegEx.create_from_string("\\b" + never + "\\b").search(w) != null, "%s.%s: '%s'" % [id, track,
						never])
	for track in LifeData.TRACKS:
		assert_string_contains(str(_steps("online_city", track)[0].say).to_lower(), "pretend", track + ": it is all pretend")
		assert_string_contains(str(_steps("online_city", track)[0].say).to_lower(), "nothing you do is kept or sent", track)
	var mean := _words("online_city", "middle")
	assert_string_contains(mean, "you're bad at this game", "the mean comment, and nothing worse")


func test_the_address_is_said_aloud_never_typed() -> void:
	var real := LifeExperience.words("find_way", "little", "try_real", "ge")
	assert_string_contains(real, "Say your address to your grown-up now", "the Try it for real card")
	for track in LifeData.TRACKS:
		var w := _words("find_way", track).to_lower()
		assert_string_contains(w, "aloud", track + ": said aloud")
		assert_string_contains(w, "never ask", track + ": the game never asks for it")


func test_the_right_ways_in_the_authorities_words() -> void:
	var o_little := _words("online_city", "little").to_lower()
	for w: String in ["ask a grown-up", "private", "kind", "break", "tell a grown-up", "feels wrong"]:
		assert_string_contains(o_little, w, "Online City (Little): " + w)
	var o_mid := _words("online_city", "middle").to_lower()
	for w: String in ["block", "report", "don't reply", "keep it", "stranger", "pop-up", "download", "who made it", "when",
			"anyone else", "kind", "break"]:
		assert_string_contains(o_mid, w, "Online City (Middle): " + w)
	var o_big := _words("online_city", "big").to_lower()
	for w: String in ["scam", "private", "school", "address", "photo", "think before you post", "picture can be changed",
			"never meet", "link"]:
		assert_string_contains(o_big, w, "Online City (Big): " + w)
	var f_little := _words("find_way", "little").to_lower()
	for w: String in ["stay where you are", "name badge", "children", "police officer", "teacher", "meeting point",
			"landmark"]:
		assert_string_contains(f_little, w, "Find Your Way (Little): " + w)
	var f_mid := _words("find_way", "middle").to_lower()
	for w: String in ["come with me", "stay where you are", "teacher", "meeting point", "change", "ticket", "yellow line",
			"north", "east", "landmark"]:
		assert_string_contains(f_mid, w, "Find Your Way (Middle): " + w)
	var f_big := _words("find_way", "big").to_lower()
	for w: String in ["bearing", "grid", "symbol", "help point", "yellow line", "towards", "south-west"]:
		assert_string_contains(f_big, w, "Find Your Way (Big): " + w)
	var h_little := _words("home_helper", "little").to_lower()
	for w: String in ["whites", "colours", "socks", "fold", "home", "soil", "water", "smoke alarm"]:
		assert_string_contains(h_little, w, "Home Helper (Little): " + w)
	var h_mid := _words("home_helper", "middle").to_lower()
	for w: String in ["red sock", "paper", "plastic", "glass", "food waste", "fork", "knife", "once a month", "vet", "walk",
			"fresh water"]:
		assert_string_contains(h_mid, w, "Home Helper (Middle): " + w)
	var h_big := _words("home_helper", "big").to_lower()
	for w: String in ["label", "hand wash", "tumble", "30", "point down", "smoke alarm", "battery"]:
		assert_string_contains(h_big, w, "Home Helper (Big): " + w)


func test_an_emergency_at_school_is_a_fire_drill_never_a_lockdown() -> void:
	for track: String in ["little", "middle"]:
		var w := _words("find_way", track).to_lower()
		assert_string_contains(w, "fire drill", track)
		assert_string_contains(w, "follow your teacher", track)
		assert_false(w.contains("hide"), track + ": never hiding from someone")


func test_the_regions_own_metro_and_bins() -> void:
	assert_string_contains(_words("find_way", "middle", false, "ge"), "Tbilisi", "Georgia's own metro: two lines")
	assert_false(_words("find_way", "middle", false, "uk").contains("Tbilisi"), "another region, its own words")
	assert_string_contains(_words("home_helper", "middle", false, "ge"), "Georgia", "the region's bins")
	for track in LifeData.TRACKS:
		var said := false
		for id: String in ["online_city", "find_way"]:
			said = said or _words(id, track, false, "uk").contains("999")
		assert_true(said, track + ": the region's number is said")


func test_the_devices_and_the_tool_book() -> void:
	assert_true(LifeExperience.devices("online_city", "ge").has("tablet"), "the play tablet: the device model")
	assert_true(LifeExperience.devices("find_way", "ge").has("gates"), "the metro's ticket gates")
	assert_true(LifeExperience.devices("home_helper", "ge").has("smoke_alarm"))
	assert_true(LifeExperience.devices("home_helper", "ge").has("washing_machine"))
	assert_true(LifeExperience.devices("home_helper", "ge").has("dishwasher"))
	for tool_id: String in ["metro_ticket", "washing_label", "tablet", "compass", "smoke_alarm"]:
		assert_true(ToolBook.has(tool_id), tool_id + " in the Tool Book")
	assert_eq(ToolBook.problems(), [] as Array[String])
	var named := {}
	for id in L3C:
		for track in LifeData.TRACKS:
			for expert: bool in [false, true]:
				for s in _steps(id, track, expert):
					for key: String in ["tool", "device"]:
						if s.has(key):
							named[str(s[key])] = true
	for tool_id: String in ["tablet", "compass", "metro_ticket", "smoke_alarm", "washing_label", "watering_can"]:
		assert_true(named.has(tool_id), tool_id + ": a step uses it, so its Tool Book stamps can be earned")


func test_every_track_has_its_unit_on_the_map() -> void:
	for id in L3C:
		for track in LifeData.TRACKS:
			assert_ne(LifeCatalog.experience_unit(id, track), "", "%s.%s has its unit" % [id, track])
	assert_eq(LifeCatalog.problems(), [] as Array[String])


func test_every_fact_has_its_authority_and_source() -> void:
	var want := {"online_city": ["Childnet", "UK Safer Internet Centre", "NSPCC", "UNICEF"],
		"find_way": ["police", "fire", "Tbilisi"], "home_helper": ["RSPCA", "fire", "recycling", "GINETEX"]}
	for id in L3C:
		var all: Array[String] = []
		for track in LifeData.TRACKS:
			var sources: Array = LifeExperience.track_data(id, track).get("sources", [])
			assert_gte(sources.size(), 3, "%s.%s: its facts and their sources" % [id, track])
			for s: Dictionary in sources:
				assert_true(str(s.url).begins_with("https://"), "%s.%s: %s" % [id, track, s.url])
				all.append("%s %s" % [s.source, s.fact])
		var joined := " ".join(all)
		for who: String in want[id]:
			assert_string_contains(joined, who, id + ": " + who)


## The three small hooks outside Life (each marked "owner #118 (L3c)").
func test_the_hooks_outside_life() -> void:
	var board := LifeExperience.data("goal_board")
	var devices := {}
	for track in LifeData.TRACKS:
		for s: Variant in (board.tracks[track].steps as Array):
			if (s as Dictionary).has("device"):
				devices["%s.%s" % [track, s.id]] = str(s.device)
				assert_eq(str(s.get("owner", "")), "#118 (L3c)", "%s.%s: the hook is marked" % [track, s.id])
	assert_eq(devices.get("little.jar"), "jar", "the saving jar's Tool Book stamp")
	assert_eq(devices.get("middle.jar"), "jar")
	assert_eq(devices.get("middle.week"), "calendar", "the habit calendar's Tool Book stamp")
	assert_eq(LifeExperience.problems("goal_board"), [] as Array[String])
	var last := str((Curriculum.content("g8.computing.cyber_security").lesson as Array)[-1].text)
	assert_string_contains(last, "Online City", "grade 8's Cyber security ends by naming Online City")
	assert_false(last.contains("The Connections Book"), "instead of the Connections Book")
	var linked := false
	for u in LifeCatalog.units("online", "big"):
		linked = linked or str(u.id) == "g8.computing.cyber_security"
	assert_true(linked, "the Life map links grade 8's Cyber security beside Online City's Big unit")
