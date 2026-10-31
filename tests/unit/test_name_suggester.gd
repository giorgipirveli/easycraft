extends GutTest


func test_suggestions_are_always_valid_usernames() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 300:
		var name := NameSuggester.suggest(rng)
		assert_eq(UsernameRules.validate(name), "", name)


func test_suggestions_vary() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var seen := {}
	for i in 20:
		seen[NameSuggester.suggest(rng)] = true
	assert_gt(seen.size(), 15)
