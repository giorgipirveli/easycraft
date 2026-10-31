extends GutTest
## Owner #94 (spec §5.12b): a Short is data, checked like the School's lessons (ShortCheck): every actor kind known,
## every School picture's data valid (SchoolPicture.problem), 20-60 seconds, words short enough to read and to say in
## their time, sounds that play, LEARN IT's link to something that exists, and a question to wonder about at the end.


func _good() -> Dictionary:
	return {"id": "sample_short", "title": "A sample", "topic": "science", "link": {"unit": "g4.science.circuits"},
		"scenes": [
			{"seconds": 8, "background": "sky", "caption": "A circuit is a loop.", "say": "A circuit is a loop.",
				"sounds": [{"at": 0.2, "effect": "pop"}, {"at": 2, "tune": {"kind": "notes", "notes": ["C5", "E5", "G5"]}}],
				"actors": [
					{"kind": "words", "text": "Loop!", "at": [180, 120], "size": 48, "color": "yellow",
						"moves": [{"do": "pop", "at": 0.2}, {"do": "pulse", "at": 3}]},
					{"kind": "picture", "picture": {"kind": "circuit", "parts": ["cell", "bulb"], "lit": true}, "at": [180, 300], "w": 320,
						"moves": [{"do": "pop", "at": 1}]},
					{"kind": "arrow", "from": [40, 400], "to": [320, 400], "color": "red", "moves": [{"do": "draw", "at": 2}]},
				]},
			{"seconds": 7, "background": "space", "caption": "The Moon is round.", "say": "The Moon is round.",
				"actors": [{"kind": "planet", "body": "moon", "at": [180, 250], "size": 60, "moves": [{"do": "drop", "at": 0}]},
					{"kind": "part", "part": "ROCKET_ENGINE", "at": [60, 400], "size": 80, "moves": []},
					{"kind": "block", "block": "STONE", "at": [300, 400], "size": 60, "moves": []},
					{"kind": "character", "who": "hoot", "at": [300, 150], "size": 100, "moves": [{"do": "slide", "at": 0, "from": [500, 150]}]}]},
			{"seconds": 8, "background": "paper", "caption": "What else is round?", "say": "What else is round?",
				"actors": [{"kind": "shape", "shape": "pizza", "slices": 8, "at": [180, 250], "size": 200, "value": 0,
						"moves": [{"do": "value", "at": 1, "dur": 2, "to": 3}]},
					{"kind": "count", "from": 0, "to": 250, "suffix": " t", "at": [180, 420], "size": 40, "moves": [{"do": "value", "at": 0, "to": 250}]},
					{"kind": "map", "lat": [25, 40], "long": [20, 45], "points": [{"lat": 29.98, "long": 31.13, "label": "Giza"}],
						"at": [180, 250], "w": 320, "h": 240, "moves": [{"do": "draw", "at": 4}]}]},
		]}


func _problems(s: Dictionary, lesson: bool = false) -> String:
	return "\n".join(ShortCheck.problems(s, lesson))


func _with(path: Array, value: Variant) -> Dictionary:
	var s := _good()
	var d: Variant = s
	for i in path.size() - 1:
		d = d[path[i]]
	d[path[path.size() - 1]] = value
	return s


func test_a_good_short_passes() -> void:
	assert_eq(ShortCheck.problems(_good()), [] as Array[String])


func test_the_shape_of_a_short() -> void:
	assert_string_contains(_problems(_with(["id"], "Bad Id")), "id")
	assert_string_contains(_problems(_with(["title"], "")), "title")
	assert_string_contains(_problems(_with(["title"], "x".repeat(ShortRules.MAX_TITLE + 1))), "title")
	assert_string_contains(_problems(_with(["topic"], "cooking")), "topic")
	assert_string_contains(_problems(_with(["scenes"], [])), "scenes")
	assert_ne(_problems({"id": "x"}), "")
	assert_ne(ShortCheck.problems("text").size(), 0)


func test_20_to_60_seconds_and_3_to_6_scenes() -> void:
	var short := _good()
	short.scenes[0].seconds = 3
	short.scenes[1].seconds = 3
	short.scenes[2].seconds = 3
	assert_string_contains(_problems(short), "seconds")
	var long := _good()
	for s: Dictionary in long.scenes:
		s.seconds = 16
	long.scenes.append(long.scenes[0].duplicate(true))
	assert_string_contains(_problems(long), "seconds")
	var many := _good()
	for i in 4:
		many.scenes.insert(0, {"seconds": 3, "background": "sky", "caption": "Hi.", "say": "Hi.", "actors": []})
	assert_string_contains(_problems(many), "scenes")
	assert_string_contains(_problems(_with(["scenes", 0, "seconds"], 30)), "seconds")


func test_captions_and_the_voice_fit() -> void:
	assert_string_contains(_problems(_with(["scenes", 0, "caption"], "")), "caption")
	assert_string_contains(_problems(_with(["scenes", 0, "caption"], "word ".repeat(30))), "caption")
	assert_string_contains(_problems(_with(["scenes", 0, "say"], "word ".repeat(40))), "say")
	assert_string_contains(_problems(_with(["scenes", 2, "caption"], "Round things are fun.")), "question",
		"a hand-made Short ends with a question to wonder about")


func test_backgrounds_and_sounds() -> void:
	assert_string_contains(_problems(_with(["scenes", 0, "background"], "disco")), "background")
	assert_string_contains(_problems(_with(["scenes", 0, "sounds", 0, "effect"], "explosion")), "effect")
	assert_string_contains(_problems(_with(["scenes", 0, "sounds", 1, "tune"], {"kind": "notes", "notes": ["H9"]})), "tune")
	assert_string_contains(_problems(_with(["scenes", 0, "sounds", 0, "at"], 99)), "sound")


func test_every_actor_kind_is_known_and_checked() -> void:
	assert_string_contains(_problems(_with(["scenes", 0, "actors", 0, "kind"], "hologram")), "kind")
	assert_string_contains(_problems(_with(["scenes", 0, "actors", 0, "text"], "")), "words")
	assert_string_contains(_problems(_with(["scenes", 0, "actors", 1, "picture"], {"kind": "circuit", "parts": ["toaster"]})),
		"picture", "the School's own check of the picture's data")
	assert_string_contains(_problems(_with(["scenes", 1, "actors", 0, "body"], "vulcan")), "body")
	assert_string_contains(_problems(_with(["scenes", 1, "actors", 1, "part"], "STONE")), "part", "a part is a rocket part")
	assert_string_contains(_problems(_with(["scenes", 1, "actors", 2, "block"], "NO_SUCH_BLOCK")), "block")
	assert_string_contains(_problems(_with(["scenes", 1, "actors", 3, "who"], "dragon_king")), "who")
	assert_string_contains(_problems(_with(["scenes", 2, "actors", 0, "shape"], "hexaflexagon")), "shape")
	assert_string_contains(_problems(_with(["scenes", 0, "actors", 2, "to"], "there")), "arrow")
	assert_string_contains(_problems(_with(["scenes", 2, "actors", 2, "points"], [{"lat": 99, "long": 0, "label": "X"}])), "map")
	assert_string_contains(_problems(_with(["scenes", 0, "actors", 0, "color"], "plaid")), "colo")
	assert_string_contains(_problems(_with(["scenes", 0, "actors", 0, "at"], [9000, 0])), "stage")


func test_every_move_is_known_and_inside_its_scene() -> void:
	assert_string_contains(_problems(_with(["scenes", 0, "actors", 0, "moves", 0, "do"], "moonwalk")), "move")
	assert_string_contains(_problems(_with(["scenes", 0, "actors", 0, "moves", 0, "at"], 9)), "after")
	assert_string_contains(_problems(_with(["scenes", 0, "actors", 0, "moves", 1, "dur"], 20)), "after")
	var orbit := _good()
	orbit.scenes[1].actors[0].moves = [{"do": "orbit", "at": 0, "dur": 5}]
	assert_string_contains(_problems(orbit), "orbit", "an orbit needs its middle and period")
	var move := _good()
	move.scenes[1].actors[0].moves = [{"do": "move", "at": 0}]
	assert_string_contains(_problems(move), "move", "a move needs where to")


func test_learn_it_links_to_something_that_exists() -> void:
	assert_string_contains(_problems(_with(["link"], {"unit": "g4.science.no_such_unit"})), "link")
	assert_string_contains(_problems(_with(["link"], {"unit": "g8.science.no_file_yet"})), "link")
	assert_string_contains(_problems(_with(["link"], {"teleport": true})), "link")
	assert_eq(_problems(_with(["link"], {"board": true})), "")
	assert_eq(_problems(_with(["link"], {"star_map": true})), "")


func test_a_lesson_short_has_its_own_limits() -> void:
	var s := _good()
	s.id = "lesson:g4.science.circuits"
	s.topic = "science"
	s.scenes[2].caption = "Tap LEARN IT to read it all and practise."
	s.scenes[2].say = "Tap LEARN IT to read it all and practise."
	s.scenes[0].seconds = 15
	assert_eq(_problems(s, true), "", "no question needed at the end; longer captions allowed")
	s.scenes[0].caption = "word ".repeat(40).strip_edges()
	assert_string_contains(_problems(s, true), "caption")
