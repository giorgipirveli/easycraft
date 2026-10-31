extends GutTest
## M5 Task 2 (spec §15.2): the loading hints, as pure rules. One short line and one picture each, picked for the
## mode and the universe of the world that loads, never the same twice in a row; the words pass the house word
## tests (short, kind, no hurry).


func test_every_hint_is_short_with_a_picture() -> void:
	assert_gte(LoadingHints.HINTS.size(), 10)
	for h: Dictionary in LoadingHints.HINTS:
		var words := str(h.text).split(" ", false).size()
		assert_between(words, 3, 10, "short enough for a child to read (or hear): %s" % h.text)
		assert_true(h.has("picture"), h.text)
		assert_not_null(LoadingHints.picture(h), "a picture for: %s" % h.text)


func test_each_world_gets_hints_that_fit_it() -> void:
	for mode: StringName in [ModeRules.SANDBOX, ModeRules.SURVIVOR, ModeRules.WAVE]:
		for u in range(1, UniverseRegistry.size() + 1):
			var fit := LoadingHints.fitting(mode, u)
			assert_gte(fit.size(), 3, "%s in universe %d" % [mode, u])
			for i in fit:
				var h: Dictionary = LoadingHints.HINTS[i]
				if h.has("modes"):
					assert_true((h.modes as Array).has(mode), "%s is for %s" % [h.text, h.modes])
				if h.has("universe"):
					assert_eq(int(h.universe), u, h.text)


func test_a_universe_has_its_own_hint_and_a_mode_its_own() -> void:
	for u in range(2, UniverseRegistry.size() + 1):
		var own := LoadingHints.fitting(ModeRules.SURVIVOR, u).filter(func(i: int) -> bool:
			return LoadingHints.HINTS[i].get("universe", 0) == u)
		assert_gte(own.size(), 1, "universe %d has a hint of its own" % u)
	var night := LoadingHints.fitting(ModeRules.SURVIVOR, 1).filter(func(i: int) -> bool:
		return LoadingHints.HINTS[i].has("modes"))
	assert_gte(night.size(), 2, "Survivor's own hints (night, gold)")
	for i in LoadingHints.fitting(ModeRules.SANDBOX, 1):
		assert_false(str(LoadingHints.HINTS[i].text).contains("gold"), "no gold talk in Sandbox")


func test_never_the_same_twice_in_a_row() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var last := -1
	var seen := {}
	for i in 200:
		var next := LoadingHints.pick(ModeRules.SURVIVOR, 3, last, rng)
		assert_ne(next, last)
		assert_true(LoadingHints.fitting(ModeRules.SURVIVOR, 3).has(next))
		seen[next] = true
		last = next
	assert_eq(seen.size(), LoadingHints.fitting(ModeRules.SURVIVOR, 3).size(), "every fitting hint comes up")


func test_the_words_are_calm() -> void:
	for h: Dictionary in LoadingHints.HINTS:
		var t := str(h.text).to_lower()
		for bad in ["hurry", "quick", "last chance", "don't", "die", "kill"]:
			assert_false(t.contains(bad), "%s: %s" % [bad, h.text])
