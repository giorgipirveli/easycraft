extends GutTest
## The parrot's words (M3 Task 11): it repeats its own child's chat lines and quick phrases in a squawky
## bubble. Safety: never other players' words — a parrot must never become a way to show someone else's
## text. It hears only lines this device's own player sent, keeps them on this device and shows them only
## here (nothing about it goes over the network).

const ME := 5
const OTHER := 9


func test_it_repeats_its_own_childs_lines() -> void:
	var echo := PetEcho.new()
	assert_true(echo.hear_own("Hello!", ME, ME))
	assert_eq(echo.lines(), ["Hello!"] as Array[String])
	assert_eq(echo.squawk(0.0), "Squawk! Hello!")


func test_it_never_repeats_another_players_words() -> void:
	var echo := PetEcho.new()
	assert_false(echo.hear_own("my secret words", OTHER, ME), "another player's line")
	assert_false(echo.hear_own("hi", 0, ME), "no sender")
	assert_true(echo.lines().is_empty())
	assert_eq(echo.squawk(0.5), "", "nothing to say")


func test_it_keeps_only_a_few_short_clean_lines() -> void:
	var echo := PetEcho.new()
	for i in PetEcho.MAX_LINES + 3:
		echo.hear_own("Line %d" % i, ME, ME)
	assert_eq(echo.lines().size(), PetEcho.MAX_LINES)
	assert_eq(echo.lines()[-1], "Line %d" % (PetEcho.MAX_LINES + 2), "the newest are kept")
	echo.hear_own("This is a very long line that goes on and on and on", ME, ME)
	assert_lte(echo.lines()[-1].length(), PetEcho.MAX_LENGTH)
	assert_false(echo.hear_own("   ", ME, ME), "nothing")
	assert_false(echo.hear_own("/tp 1 2 3", ME, ME), "commands are not words")
	assert_false(echo.hear_own("call me 5551234567", ME, ME), "the chat filter still applies")


func test_a_quick_phrase_is_repeated_too() -> void:
	var echo := PetEcho.new()
	var phrase: String = ChatRules.QUICK_PHRASES[0]
	assert_true(echo.hear_own(phrase, ME, ME))
	assert_eq(echo.squawk(0.99), "Squawk! %s" % phrase)


func test_the_squawk_picks_one_of_the_lines() -> void:
	var echo := PetEcho.new()
	echo.hear_own("one", ME, ME)
	echo.hear_own("two", ME, ME)
	assert_eq(echo.squawk(0.0), "Squawk! one")
	assert_eq(echo.squawk(0.99), "Squawk! two")


## The parrot's words live on this device: its code never sends them anywhere and never listens to the
## chat everyone receives.
func test_the_echo_code_never_touches_the_network_or_others_chat() -> void:
	for path: String in ["res://core/rules/pet_echo.gd"]:
		var text := FileAccess.get_file_as_string(path)
		assert_ne(text, "", path)
		for banned in ["rpc", "chat_received", "Session.", "broadcast"]:
			assert_false(text.contains(banned), "%s mentions %s" % [path, banned])
