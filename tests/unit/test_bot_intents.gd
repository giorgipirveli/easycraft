extends GutTest
## Owner feedback #38: bot friends understand what the child says and asks (spec §12.14a). BotIntents reads a
## child's words in English on the device and picks an intent (owner #52: English only). The phrase table is
## child-like on purpose: typos, stretched letters, "u"/"plz"/"thx", no punctuation.

const I := preload("res://core/bots/bot_intents.gd")
const NAMES: Array[String] = ["Mossy", "Pip", "Bolt"]

## [sentence, intent, bot named ("" = none)]. The matcher is tuned on this table (>= 90 %).
const TABLE: Array = [
	# follow me / come here
	["follow me", &"follow", ""], ["folow me", &"follow", ""], ["fallow me plz", &"follow", ""],
	["come here", &"follow", ""], ["cum here", &"follow", ""], ["come heer!!", &"follow", ""],
	["come with me", &"follow", ""], ["lets go", &"follow", ""], ["let's goooo", &"follow", ""],
	["this way", &"follow", ""], ["over here guys", &"follow", ""], ["come on", &"follow", ""],
	["cmon follow me", &"follow", ""], ["follllow meee", &"follow", ""], ["keep up!", &"follow", ""],
	["stay close to me", &"follow", ""], ["come back here", &"follow", ""], ["flw me", &"follow", ""],
	["can u follow me", &"follow", ""], ["follow me please", &"follow", ""], ["come over here", &"follow", ""],
	["walk with me", &"follow", ""],
	# wait / stay / stop
	["wait", &"wait", ""], ["wait here", &"wait", ""], ["stay", &"wait", ""], ["stay here", &"wait", ""],
	["stop", &"wait", ""], ["stopp!!", &"wait", ""], ["wiat", &"wait", ""], ["w8 for me", &"wait", ""],
	["dont move", &"wait", ""], ["don't move!", &"wait", ""], ["stand still", &"wait", ""], ["freeze", &"wait", ""],
	["hold on", &"wait", ""], ["stay right there", &"wait", ""], ["hang on a sec", &"wait", ""],
	# go home
	["go home", &"home", ""], ["go hom", &"home", ""], ["go to my house", &"home", ""], ["go back home", &"home", ""],
	["go to bed", &"home", ""], ["home!", &"home", ""], ["go home and wait for me", &"home", ""],
	# give me space
	["go away", &"space", ""], ["leave me alone", &"space", ""], ["stop following me", &"space", ""],
	["dont follow me", &"space", ""], ["back off", &"space", ""], ["give me some space", &"space", ""],
	["ur too close", &"space", ""],
	# build
	["build a house", &"build", ""], ["bild a hous", &"build", ""], ["build me a house pls", &"build", ""],
	["make a house", &"build", ""], ["build a tower", &"build", ""], ["build a tall tower", &"build", ""],
	["build a wall", &"build", ""], ["make a wall here", &"build", ""], ["build something", &"build", ""],
	["build next to me", &"build", ""], ["build with my blocks", &"build", ""], ["lets build", &"build", ""],
	["let's build!", &"build", ""], ["can you build a castle", &"build", ""], ["biuld a houseee", &"build", ""],
	["build a hut", &"build", ""],
	# explore / find treasure / find secrets / where is treasure
	["find treasure", &"treasure", ""], ["find tresure", &"treasure", ""], ["lets find treasure", &"treasure", ""],
	["where is the treasure", &"treasure", ""], ["were is treasure?", &"treasure", ""], ["find secrets", &"treasure", ""],
	["find a secret", &"treasure", ""], ["any secrets near here?", &"treasure", ""], ["explore", &"treasure", ""],
	["lets explore!", &"treasure", ""], ["go explore", &"treasure", ""], ["wheres the nearest secret", &"treasure", ""],
	["search for treasure", &"treasure", ""], ["treasure hunt!", &"treasure", ""], ["is there treasure here?", &"treasure", ""],
	["where r the secrets", &"treasure", ""],
	# fight / guard me / protect me
	["fight", &"fight", ""], ["fight the monster", &"fight", ""], ["attack!", &"fight", ""], ["kill the zombie", &"fight", ""],
	["protect me", &"fight", ""], ["protekt me", &"fight", ""], ["guard me", &"fight", ""], ["gaurd me pls", &"fight", ""],
	["keep me safe", &"fight", ""], ["defend me", &"fight", ""], ["get that goblin", &"fight", ""], ["fight the slime", &"fight", ""],
	# run away / hide
	["run away", &"hide", ""], ["run!!", &"hide", ""], ["hide", &"hide", ""], ["hide!", &"hide", ""], ["lets hide", &"hide", ""],
	["run away from the monster", &"hide", ""], ["hide quick", &"hide", ""], ["flee", &"hide", ""],
	# dance / do a trick
	["dance", &"dance", ""], ["dance for me", &"dance", ""], ["do a dance", &"dance", ""], ["do a trick", &"dance", ""],
	["show me a trick", &"dance", ""], ["danse", &"dance", ""], ["can you dance?", &"dance", ""], ["do a flip", &"dance", ""],
	["lets dance party", &"dance", ""],
	# race me
	["race me", &"race", ""], ["lets race", &"race", ""], ["rase me!", &"race", ""], ["wanna race?", &"race", ""],
	["race me on the course", &"race", ""],
	# help!
	["help", &"help", ""], ["help!!", &"help", ""], ["help me", &"help", ""], ["halp", &"help", ""], ["helpp meee", &"help", ""],
	["i need help", &"help", ""], ["im stuck", &"help", ""], ["save me", &"help", ""],
	# hello / thanks / good job / bye / look / ok
	["hi", &"hello", ""], ["hello", &"hello", ""], ["helloooo", &"hello", ""], ["hey", &"hello", ""],
	["hi mossy", &"hello", "Mossy"], ["hey guys", &"hello", ""], ["good morning", &"hello", ""], ["yo", &"hello", ""],
	["sup", &"hello", ""],
	["thanks", &"thanks", ""], ["thank you", &"thanks", ""], ["thx", &"thanks", ""], ["ty", &"thanks", ""],
	["thank u so much", &"thanks", ""], ["thanks pip", &"thanks", "Pip"],
	["good job", &"praise", ""], ["gj", &"praise", ""], ["nice build", &"praise", ""], ["well done!", &"praise", ""],
	["you are awesome", &"praise", ""], ["ur the best", &"praise", ""], ["i love you", &"praise", ""], ["cool", &"praise", ""],
	["wow", &"praise", ""], ["amazing", &"praise", ""], ["good bot", &"praise", ""],
	["bye", &"bye", ""], ["bye bye", &"bye", ""], ["goodbye", &"bye", ""], ["see you", &"bye", ""], ["cya", &"bye", ""],
	["good night", &"bye", ""], ["gotta go", &"bye", ""],
	["look", &"look", ""], ["look at this", &"look", ""], ["look!", &"look", ""], ["check this out", &"look", ""],
	["look over there", &"look", ""],
	["ok", &"ack", ""], ["yes", &"ack", ""], ["no", &"ack", ""], ["lol", &"ack", ""], ["yeah", &"ack", ""],
	# questions
	["where is tilly", &"where_tilly", ""], ["where is tilly?", &"where_tilly", ""], ["wheres tily", &"where_tilly", ""],
	["where's the shop?", &"where_tilly", ""], ["where can i buy stuff", &"where_tilly", ""], ["take me to tilly", &"where_tilly", ""],
	["were is the trader", &"where_tilly", ""], ["find tilly", &"where_tilly", ""], ["where is the store", &"where_tilly", ""],
	["what are you doing", &"doing", ""], ["wat r u doing", &"doing", ""], ["what r u doin?", &"doing", ""],
	["whatcha doing", &"doing", ""], ["wyd", &"doing", ""], ["what are you up to", &"doing", ""],
	["how many hearts do i have", &"hearts", ""], ["how many harts do i have?", &"hearts", ""],
	["how much health do i have", &"hearts", ""], ["am i hurt?", &"hearts", ""], ["hearts?", &"hearts", ""],
	["how is my health", &"hearts", ""],
	["is it night soon", &"night", ""], ["is it nigth soon?", &"night", ""], ["when is night", &"night", ""],
	["when does it get dark", &"night", ""], ["what time is it", &"night", ""], ["is it day or night", &"night", ""],
	["when will the sun go down", &"night", ""],
	["what's your name", &"name", ""], ["whats ur name", &"name", ""], ["what is your name?", &"name", ""],
	["who are you", &"name", ""], ["wat is ur naem", &"name", ""],
	["can you help me", &"what_can_i_say", ""], ["what can you do", &"what_can_i_say", ""],
	["what can i say", &"what_can_i_say", ""], ["what do i say", &"what_can_i_say", ""], ["commands", &"what_can_i_say", ""],
	["where are you", &"where_are_you", ""], ["where r u", &"where_are_you", ""], ["where are u?", &"where_are_you", ""],
	["i cant see you", &"where_are_you", ""], ["where did you go", &"where_are_you", ""],
	["how are you", &"how_are_you", ""], ["how r u", &"how_are_you", ""], ["are you ok?", &"how_are_you", ""],
	["hows it going", &"how_are_you", ""],
	# one bot by name
	["Mossy, follow me", &"follow", "Mossy"], ["pip build a house", &"build", "Pip"], ["mosy come here", &"follow", "Mossy"],
	["Bolt wait here", &"wait", "Bolt"], ["follow me mossy", &"follow", "Mossy"],
	["hey pip, what are you doing?", &"doing", "Pip"], ["bolt, where is tilly?", &"where_tilly", "Bolt"],
	# not understood
	["banana", &"unknown", ""], ["purple elephant", &"unknown", ""], ["asdfgh", &"unknown", ""], ["i like pizza", &"unknown", ""],
	["the sky is blue", &"unknown", ""], ["abc", &"unknown", ""],
]

## Written before the matcher and never tuned on: how well it does on sentences it has not seen.
const HELD_OUT: Array = [
	["follow meeee pls", &"follow", ""], ["come over here now", &"follow", ""], ["hey bots come here", &"follow", ""],
	["can you come with me", &"follow", ""], ["stay put", &"wait", ""], ["wait for me here", &"wait", ""],
	["stop right there", &"wait", ""], ["go to your home", &"home", ""], ["go home now pip", &"home", "Pip"],
	["please make me a big house", &"build", ""], ["build a big wall around me", &"build", ""],
	["make a tower for me", &"build", ""], ["lets go find some treasure", &"treasure", ""],
	["is there a secret near us", &"treasure", ""], ["explore the cave", &"treasure", ""], ["fight them", &"fight", ""],
	["protect me from the monsters", &"fight", ""], ["hide from the zombie", &"hide", ""], ["can you do a dance", &"dance", ""],
	["do a backflip", &"dance", ""], ["lets have a race", &"race", ""], ["help help", &"help", ""], ["i need you", &"help", ""],
	["hello friend", &"hello", ""], ["hi guys", &"hello", ""], ["thank you so much", &"thanks", ""],
	["you did great", &"praise", ""], ["that was awesome", &"praise", ""], ["bye guys", &"bye", ""],
	["see ya later", &"bye", ""], ["look at my house", &"look", ""], ["where is the shop keeper", &"where_tilly", ""],
	["where do i buy things", &"where_tilly", ""], ["what r u doing mossy", &"doing", "Mossy"],
	["how many lives do i have", &"hearts", ""], ["when is it night", &"night", ""], ["is it dark yet", &"night", ""],
	["who r u", &"name", ""], ["what can i tell you", &"what_can_i_say", ""], ["where are you guys", &"where_are_you", ""],
	["how are you doing", &"how_are_you", ""],
]


func _score(table: Array) -> Dictionary:
	var right := 0
	var misses: Array[String] = []
	for row: Array in table:
		var r := I.parse(str(row[0]), NAMES)
		if r.intent == row[1] and r.target == str(row[2]):
			right += 1
		else:
			misses.append("\"%s\" -> %s %s (wanted %s %s)" % [row[0], r.intent, r.target, row[1], row[2]])
	return {"right": right, "total": table.size(), "misses": misses}


func test_the_phrase_table_is_understood_at_least_nine_times_in_ten() -> void:
	assert_gte(TABLE.size(), 150, "a big enough table")
	var s := _score(TABLE)
	gut.p("phrase table: %d / %d right (%.1f %%)" % [s.right, s.total, 100.0 * s.right / s.total])
	for m: String in s.misses:
		gut.p("  miss: " + m)
	assert_gte(float(s.right) / s.total, 0.9, "\n".join(s.misses))


func test_sentences_it_was_never_tuned_on() -> void:
	var s := _score(HELD_OUT)
	gut.p("held-out: %d / %d right (%.1f %%)" % [s.right, s.total, 100.0 * s.right / s.total])
	for m: String in s.misses:
		gut.p("  miss: " + m)
	assert_gte(float(s.right) / s.total, 0.75, "\n".join(s.misses))


func test_every_intent_is_in_the_table() -> void:
	var seen := {}
	for row: Array in TABLE:
		seen[row[1]] = true
	for intent in I.INTENTS:
		assert_true(seen.has(intent), "the table has %s" % intent)


# --- Cleaning the words ---

func test_words_are_cleaned_like_a_child_types_them() -> void:
	assert_eq(I.words("Fóllow  ME!!!"), ["follow", "me"] as Array[String], "accents, case, punctuation")
	assert_eq(I.words("folllooow meeee"), ["follow", "me"] as Array[String], "stretched letters")
	assert_eq(I.words("can u come here plz"), ["can", "you", "come", "here"] as Array[String], "u, plz (please is dropped)")
	assert_eq(I.words("what's ur name"), ["what", "is", "your", "name"] as Array[String], "what's, ur")
	assert_eq(I.words("thx"), ["thanks"] as Array[String])
	assert_eq(I.words("bild a hous"), ["build", "house"] as Array[String], "small typos fixed against the word list")
	assert_eq(I.words("fallow me"), ["follow", "me"] as Array[String])
	assert_eq(I.words("following"), ["follow"] as Array[String], "endings")


# --- Details of a request ---

func test_what_to_build_and_with_which_blocks() -> void:
	assert_eq(I.parse("build a tower").what, I.TOWER)
	assert_eq(I.parse("build a house").what, I.HOUSE)
	assert_eq(I.parse("make a wall").what, I.WALL)
	assert_eq(I.parse("build a castle").what, I.TOWER, "a castle is a tower")
	assert_eq(I.parse("build something").what, &"")
	assert_true(I.parse("build a house with my blocks").mine)
	assert_false(I.parse("build a house").mine)
	assert_true(I.parse("build next to me").near)


## Owner #45a: "follow the arrow" asks friends to lead to the quest's place (the treasure request), not to follow.
func test_follow_the_arrow_is_a_way_to_the_quest() -> void:
	for text in ["follow the arrow", "where is my quest", "where is the arrow going"]:
		assert_eq(I.parse(text).intent, I.TREASURE, text)
	assert_eq(I.parse("follow me").intent, I.FOLLOW, "following the child stays as it was")


func test_questions_are_marked() -> void:
	assert_true(I.parse("is it night soon?").question)
	assert_true(I.parse("where is the treasure").question)
	assert_false(I.parse("find treasure").question)
	assert_false(I.parse("follow me").question)


## Owner #52: the game is English only, so every answer is English, whatever letters the child typed.
func test_the_answer_is_always_english() -> void:
	for text in ["follow me", "banana", "გამომყევი", "gamomyevi"]:
		assert_eq(I.parse(text).lang, I.EN, text)
	assert_false((I as Script).get_script_constant_map().has("KA"), "no Georgian word list")


func test_dont_turns_a_request_around() -> void:
	assert_eq(I.parse("dont follow me").intent, I.SPACE)
	assert_eq(I.parse("stop following me").intent, I.SPACE)
	assert_eq(I.parse("stop dancing").intent, I.WAIT, "stop doing that")
	assert_eq(I.parse("don't build").intent, I.WAIT)


# --- Talking to one bot by name ---

func test_a_name_at_the_start_or_the_end_talks_to_one_bot() -> void:
	var r := I.parse("Mossy, follow me", NAMES)
	assert_eq(r.target, "Mossy")
	assert_eq(r.intent, I.FOLLOW)
	assert_eq(I.parse("follow me, Pip!", NAMES).target, "Pip")
	assert_eq(I.parse("hey bolt come here", NAMES).target, "Bolt", "after a greeting")
	assert_eq(I.parse("follow me", NAMES).target, "", "nobody named: all the child's friends near")
	assert_eq(I.parse("Gizmo, follow me", NAMES).target, "", "not one of this child's friends")


func test_a_misspelled_name_still_finds_its_bot() -> void:
	assert_eq(I.parse("mosy follow me", NAMES).target, "Mossy")
	assert_eq(I.parse("mossi come here", NAMES).target, "Mossy")


func test_a_word_is_never_taken_for_a_name() -> void:
	var names: Array[String] = ["Comet", "Bolt"]
	var r := I.parse("come here", names)
	assert_eq(r.target, "", "come is a word, not Comet")
	assert_eq(r.intent, I.FOLLOW)
	assert_eq(I.parse("comet come here", names).target, "Comet")


func test_everyone_words_talk_to_all() -> void:
	var r := I.parse("everyone follow me", NAMES)
	assert_eq(r.target, "")
	assert_eq(r.intent, I.FOLLOW)
	assert_eq(I.parse("guys come here", NAMES).intent, I.FOLLOW)


# --- Not understood ---

func test_nonsense_is_not_understood() -> void:
	for text in ["banana", "qwertyuiop", "the sky is blue", "", "   ", "!!!", "1234"]:
		assert_eq(I.parse(text).intent, I.UNKNOWN, text)


func test_long_text_is_cut_and_still_cheap() -> void:
	var long := "follow me ".repeat(200)
	var t0 := Time.get_ticks_usec()
	var r := I.parse(long)
	assert_eq(r.intent, I.FOLLOW)
	assert_lt(Time.get_ticks_usec() - t0, 200000, "a long message is cut before any work")


## Timed on this thread's CPU clock (other agents' load does not count), first reads and repeats.
func test_a_sentence_costs_little() -> void:
	I.parse("warm up the word list")
	I._memo.clear()
	var c0 := _cpu_us()
	var t0 := Time.get_ticks_usec()
	for row: Array in TABLE:
		I.parse(str(row[0]), NAMES)
	var wall := float(Time.get_ticks_usec() - t0) / TABLE.size()
	var first := float(_cpu_us() - c0) / TABLE.size() if c0 >= 0 else wall
	c0 = _cpu_us()
	for row: Array in TABLE:
		I.parse(str(row[0]), NAMES)
	var again := float(_cpu_us() - c0) / TABLE.size() if c0 >= 0 else wall
	gut.p("parse: %.0f us CPU per sentence read the first time, %.0f us again (wall clock %.0f us)" % [first, again, wall])
	assert_lt(first, 3000.0, "a few ms at most on the desktop")
	assert_lt(again, first + 1.0, "words read before are remembered")


func _cpu_us() -> int:
	var f := FileAccess.open("/proc/thread-self/schedstat", FileAccess.READ)
	if f == null:
		return -1
	var first := f.get_line().split(" ")[0]
	return first.to_int() / 1000 if first.is_valid_int() else -1
