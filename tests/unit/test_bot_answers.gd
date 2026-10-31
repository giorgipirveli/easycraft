extends GutTest
## Owner feedback #38: what bot friends answer (spec §12.14a). Every answer is a fixed, friendly line in the
## English (owner #52: English only), filled in from the game: where Tilly
## or the nearest secret is from where the child looks, the child's hearts, the day clock, what the bot does.

const A := preload("res://core/bots/bot_answers.gd")
const EN := &"en"
const NORTH := Vector3(0, 0, -1)     # the child looks along -Z


# --- Directions from where the child looks ---

func test_directions_are_told_from_where_the_child_looks() -> void:
	var at := Vector3.ZERO
	assert_eq(A.direction(at, NORTH, Vector3(0, 0, -40), EN), "40 blocks straight ahead")
	assert_eq(A.direction(at, NORTH, Vector3(0, 0, 30), EN), "30 blocks behind you")
	assert_eq(A.direction(at, NORTH, Vector3(-25, 0, 0), EN), "25 blocks to your left")
	assert_eq(A.direction(at, NORTH, Vector3(25, 0, 0), EN), "25 blocks to your right")
	assert_eq(A.direction(at, NORTH, Vector3(20, 0, -20), EN), "28 blocks ahead, to the right")
	assert_eq(A.direction(at, Vector3(1, 0, 0), Vector3(0, 0, -30), EN), "30 blocks to your left", "turned")
	assert_eq(A.direction(at, NORTH, Vector3(0, 12, -40), EN), "40 blocks straight ahead, up high")
	assert_eq(A.direction(at, NORTH, Vector3(0, -9, -40), EN), "40 blocks straight ahead, down below")
	assert_eq(A.direction(at, NORTH, Vector3(0, -20, -10), EN), "10 blocks straight ahead, deep underground")
	assert_eq(A.direction(at, NORTH, Vector3(1, 0, 1), EN), "right here")
	assert_eq(A.direction(at, NORTH, Vector3(0, 0, -1), EN), "right here")


# --- Answers from the game ---

func test_where_tilly_is() -> void:
	var line := A.tilly(Vector3.ZERO, NORTH, Vector3(-14, 0, 0), EN, true)
	assert_eq(line, "Tilly's shop is 14 blocks to your left! Follow me!")
	assert_eq(A.tilly(Vector3.ZERO, NORTH, Vector3(-14, 0, 0), EN, false), "Tilly's shop is 14 blocks to your left!")
	assert_string_contains(A.tilly(Vector3.ZERO, NORTH, Vector3.INF, EN, true), "Survivor", "no shop in this world")


func test_where_the_nearest_secret_is() -> void:
	var s := {"pos": Vector3(0, 10, -60), "kind": &"room"}
	assert_eq(A.treasure(Vector3.ZERO, NORTH, s, EN, true),
		"I know! There's a hidden room 60 blocks straight ahead, up high. Follow me!")
	assert_eq(A.treasure(Vector3.ZERO, NORTH, {"pos": Vector3(30, 0, 0), "kind": &"treasure"}, EN, false),
		"I know! There's buried treasure 30 blocks to your right.")
	assert_string_contains(A.treasure(Vector3.ZERO, NORTH, {}, EN, true), "Let's look around")
	for kind: StringName in [&"treasure", &"room", &"temple", &"island", &"geode", &"star", &"something"]:
		assert_ne(A.treasure(Vector3.ZERO, NORTH, {"pos": Vector3(0, 0, -20), "kind": kind}, EN, true), "", kind)


func test_how_many_hearts_the_child_has() -> void:
	assert_eq(A.hearts(20, 20, true, EN), "You have all 10 hearts!")
	assert_eq(A.hearts(14, 20, true, EN), "You have 7 hearts out of 10!")
	assert_eq(A.hearts(15, 20, true, EN), "You have 7 and a half hearts out of 10!")
	assert_eq(A.hearts(1, 20, true, EN), "You have a half heart out of 10! Let's be careful!")
	assert_eq(A.hearts(2, 20, true, EN), "You have 1 heart out of 10! Let's be careful!")
	assert_eq(A.hearts(20, 20, false, EN), "You have all 10 hearts. Nothing can hurt you here!")
	assert_string_contains(A.hearts(0, 20, true, EN), "back in a moment")


func test_is_it_night_soon() -> void:
	assert_eq(A.night(0.5, EN), "It's day. Night comes in about 7 minutes.")
	assert_eq(A.night(0.84, EN), "The sun is setting! Night starts in less than a minute.")
	assert_eq(A.night(0.7875, EN), "It's day. Night comes in about 1 minute.")
	assert_eq(A.night(0.95, EN), "It's night now! The sun comes up in about 4 minutes.")
	assert_eq(A.night(0.1, EN), "It's night now! The sun comes up in about 1 minute.")


func test_what_the_bot_is_doing() -> void:
	for b: StringName in A.DOING.keys():
		assert_ne(A.doing(b, EN), "", str(b))
	assert_eq(A.doing(&"build", EN), "I'm building something for you!")
	assert_eq(A.doing(&"nonsense", EN), A.doing(&"idle", EN))


func test_a_bot_always_says_it_is_a_bot() -> void:
	assert_eq(A.name_line("Mossy", &"builder", EN), "I'm Mossy, your builder bot!")


func test_where_the_bot_is() -> void:
	assert_eq(A.where_me(Vector3.ZERO, NORTH, Vector3(0, 0, 12), EN), "Over here! I'm 12 blocks behind you.")
	assert_eq(A.where_me(Vector3.ZERO, NORTH, Vector3(1, 0, 0), EN), "I'm right here, next to you!")


func test_words_it_does_not_know_get_a_kind_hint() -> void:
	var hint := A.line(&"hint", EN)
	assert_string_contains(hint, "follow me")
	assert_string_contains(hint, "build a house")
	assert_string_contains(hint, "find treasure")


func test_more_than_one_bot_answers_as_we() -> void:
	assert_eq(A.line(&"follow", EN, 0, true), "OK! We're right behind you!")
	assert_eq(A.line(&"follow", EN, 0, false), "OK! I'm right behind you!")
	assert_eq(A.line(&"praise", EN, 0, true), A.line(&"praise", EN, 0, false), "no 'we' line: the same")


# --- Every line is kind, plain and short ---

func _every_line() -> Array[String]:
	var out: Array[String] = []
	for lang in [EN]:
		for key: StringName in A.LINES.keys():
			for we in [false, true]:
				for pick in 4:
					out.append(A.line(key, lang, pick, we))
		for b: StringName in A.DOING.keys():
			out.append(A.doing(b, lang))
		for hp in [0, 1, 2, 7, 20]:
			out.append(A.hearts(hp, 20, true, lang))
		out.append(A.hearts(20, 20, false, lang))
		for t in [0.0, 0.1, 0.5, 0.84, 0.95]:
			out.append(A.night(t, lang))
		out.append(A.name_line("Pip", &"fighter", lang))
		out.append(A.tilly(Vector3.ZERO, NORTH, Vector3(0, 0, -200), lang, true))
		out.append(A.tilly(Vector3.ZERO, NORTH, Vector3.INF, lang, true))
		out.append(A.treasure(Vector3.ZERO, NORTH, {"pos": Vector3(0, -30, -300), "kind": &"temple"}, lang, true))
		out.append(A.treasure(Vector3.ZERO, NORTH, {}, lang, true))
		out.append(A.where_me(Vector3.ZERO, NORTH, Vector3(100, 0, 100), lang))
	return out


func test_every_answer_is_plain_short_text() -> void:
	for text in _every_line():
		assert_ne(text, "")
		assert_lte(text.length(), 100, text)
		assert_eq(ChatRules.clean(text), text, "plain text the chat shows as is: %s" % text)


## The child-psychology rulings (spec §6): no guilt or pressure, never asking for anything personal.
func test_answers_never_use_guilt_or_ask_anything_personal() -> void:
	var banned: Array[String] = ["miss you", "miss me", "don't go", "dont go", "last chance", "hurry", "only today",
		"you'll lose", "youll lose", "come back", "don't leave", "dont leave", "lonely", "sad", "your name", "how old",
		"your age", "where do you live", "school", "address", "phone", "password", "email", "photo", "your mom",
		"your dad", "real name", "stupid", "wrong", "can't you", "failed"]
	for text in _every_line():
		for phrase in banned:
			assert_false(text.to_lower().contains(phrase), "\"%s\" contains \"%s\"" % [text, phrase])


## Owner #52: English only. Every line is English, and a request marked with another language still gets English.
func test_every_line_is_english_only() -> void:
	for key: StringName in A.LINES.keys():
		assert_eq((A.LINES[key] as Dictionary).keys(), [EN], str(key))
	assert_eq(A.line(&"follow", &"ka"), A.line(&"follow", EN))
	assert_eq(A.hearts(14, 20, true, &"ka"), "You have 7 hearts out of 10!")
