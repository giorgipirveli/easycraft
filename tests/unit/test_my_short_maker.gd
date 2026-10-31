extends GutTest
## MAKE MY SHORT: a recipe becomes a Short the player plays. The maker paces and sizes it itself, so whatever a child
## picks or types (within the rules), the Short passes ShortCheck: 3-6 scenes, 20-60 s, captions and the voice at most
## 2.5 words a second, every actor's moves eased and inside its scene, words legible, a question at the end.

var _rng := RandomNumberGenerator.new()


func before_each() -> void:
	_rng.seed = 20261001


func _words(n: int) -> String:
	var pool := ["big", "blocks", "I", "built", "a", "tall", "tower", "with", "red", "glass", "and", "stone", "walls",
		"windows", "my", "buddy", "helped", "then", "roof", "garden", "bright", "lamps"]
	var out: Array[String] = []
	for i in n:
		out.append(pool[_rng.randi_range(0, pool.size() - 1)])
	var t := " ".join(out).capitalize().left(MyShortRules.MAX_CAPTION).strip_edges()
	return t + "."


func _caption() -> String:
	match _rng.randi_range(0, 3):
		0:
			return MyShortRules.PHOTO_PHRASES[_rng.randi_range(0, MyShortRules.PHOTO_PHRASES.size() - 1)]
		1:
			return ""   # the maker says its own
		2:
			return _words(_rng.randi_range(1, 4))
	return _words(_rng.randi_range(10, 16))   # as long as typing allows


func _common(r: Dictionary, template: String) -> Dictionary:
	r.template = template
	r.backdrop = MyShortRules.BACKDROPS[_rng.randi_range(0, MyShortRules.BACKDROPS.size() - 1)]
	r.music = MyShortRules.MUSIC[_rng.randi_range(0, MyShortRules.MUSIC.size() - 1)]
	r.voice = _rng.randf() < 0.7
	var endings: Array = MyShortRules.ENDINGS[template]
	r.ending = endings[_rng.randi_range(0, endings.size() - 1)]
	return r


func _built(n: int) -> Dictionary:
	var photos: Array[String] = []
	var captions: Array[String] = []
	for i in n:
		photos.append("p_%d.jpg" % (100 + i))
		captions.append(_caption())
	var r := {"photos": photos, "captions": captions}
	var titles: Array = MyShortRules.TITLES[MyShortRules.BUILT]
	r.title = ["", titles[_rng.randi_range(0, titles.size() - 1)], "x".repeat(34), "My castle"][_rng.randi_range(0, 3)]
	return _common(r, MyShortRules.BUILT)


func _assert_good(s: Dictionary, what: String) -> void:
	assert_false(s.is_empty(), what)
	assert_eq(ShortCheck.problems(s), [] as Array[String], what)


func test_how_i_built_it_passes_the_checker_whatever_is_picked() -> void:
	for i in 60:
		var r := _built(_rng.randi_range(MyShortRules.MIN_PHOTOS, MyShortRules.MAX_PHOTOS))
		_assert_good(MyShortMaker.make(r), str(r))


func test_three_facts_pass_for_every_subject() -> void:
	var n := 0
	for kind: String in MyShortFacts.KINDS:
		for id: String in MyShortFacts.things(kind):
			var count := MyShortFacts.facts(kind, id).size()
			var picks := [_rng.randi_range(0, count - 1), _rng.randi_range(0, count - 1), _rng.randi_range(0, count - 1)]
			var r := _common({"subject": {"kind": kind, "id": id}, "facts": picks, "title": ""}, MyShortRules.FACTS)
			_assert_good(MyShortMaker.make(r), "%s %s" % [kind, id])
			n += 1
	assert_gt(n, 50)


func test_step_by_step_passes_for_every_blueprint_and_any_stamp() -> void:
	for id: String in MyShortRules.BLUEPRINTS:
		var r := _common({"build": {"kind": "blueprint", "id": id}, "captions": [_caption(), _caption(), _caption()]},
			MyShortRules.STEPS)
		_assert_good(MyShortMaker.make(r), id)
	for layers in range(MyShortRules.MIN_STEPS, MyShortRules.MAX_LAYERS + 1):
		var r := _common({"build": {"kind": "stamp", "file": "b_1.txt", "layers": layers}, "captions": [_caption()]},
			MyShortRules.STEPS)
		_assert_good(MyShortMaker.make(r), "stamp of %d layers" % layers)


func test_how_i_built_it_shows_the_photos_in_order_with_the_child_s_words() -> void:
	var r := _common({"title": "My secret base", "photos": ["p_1.jpg", "p_2.jpg", "p_3.jpg"],
		"captions": ["I started with the floor.", "", "Look how tall it is!"]}, MyShortRules.BUILT)
	r.ending = "Can you build one too?"
	var s := MyShortMaker.make(r)
	var scenes: Array = s.scenes
	assert_eq(scenes.size(), 5, "the title, a scene a photo, the ending")
	assert_eq(s.title, "My secret base")
	assert_eq(s.topic, MyShortRules.TOPIC)
	assert_eq(scenes[0].caption, "My secret base")
	assert_eq(scenes[1].caption, "I started with the floor.")
	assert_ne(scenes[2].caption, "", "an empty caption gets the maker's own words")
	assert_eq(scenes[3].caption, "Look how tall it is!")
	assert_eq(scenes[4].caption, "Can you build one too?")
	for i in 3:
		var photos := _actors(scenes[i + 1], "photo")
		assert_eq(photos.size(), 1)
		assert_eq(photos[0].file, r.photos[i])
	assert_eq(_actors(scenes[4], "photo").size(), 3, "the ending shows them all")
	assert_eq(_actors(scenes[0], "me").size(), 1, "the child's avatar says hello (never a name)")
	assert_false(s.has("link"), "nothing to LEARN for a build of one's own")


func test_the_voice_reads_the_caption_and_can_be_off() -> void:
	var r := _built(2)
	r.voice = false
	r.music = "spring"
	var s := MyShortMaker.make(r)
	assert_eq(s.voice, false)
	assert_eq(s.music, "spring")
	for scene: Dictionary in s.scenes:
		assert_eq(scene.say, scene.caption)
	r.voice = true
	r.music = ""
	s = MyShortMaker.make(r)
	assert_eq(s.voice, true)
	assert_false(s.has("music"), "no music: none")


func test_three_facts_shows_the_facts_picked_and_links_the_star_map() -> void:
	var r := _common({"subject": {"kind": "planet", "id": "saturn"}, "facts": [2, 0]}, MyShortRules.FACTS)
	var s := MyShortMaker.make(r)
	var facts := MyShortFacts.facts("planet", "saturn")
	assert_eq(s.title, "3 facts about Saturn")
	assert_eq(s.scenes.size(), 5)
	assert_eq(s.scenes[1].caption, facts[2])
	assert_eq(s.scenes[2].caption, facts[0])
	assert_eq(s.scenes[3].caption, facts[1], "the third: the first one not picked")
	assert_eq(s.link, {"star_map": true})
	assert_eq(_actors(s.scenes[0], "planet")[0].body, "saturn")
	var w := MyShortMaker.make(_common({"subject": {"kind": "wonder", "id": "pyramid"}}, MyShortRules.FACTS))
	assert_eq(_actors(w.scenes[0], "wonder")[0].id, "pyramid")
	var a := MyShortMaker.make(_common({"subject": {"kind": "animal", "id": "penguin"}}, MyShortRules.FACTS))
	assert_eq(_actors(a.scenes[0], "character")[0].who, "penguin")
	assert_false(a.has("link"))


func test_step_by_step_builds_up_layer_by_layer() -> void:
	var r := _common({"build": {"kind": "blueprint", "id": "house"}}, MyShortRules.STEPS)
	var s := MyShortMaker.make(r)
	var layers := MyShortRules.blueprint_layers("house")
	assert_eq(s.scenes.size(), 2 + MyShortRules.MAX_STEPS)
	assert_eq(s.title, "How to build a house")
	var shown := 0.0
	for k in MyShortRules.MAX_STEPS:
		var b: Dictionary = _actors(s.scenes[k + 1], "build")[0]
		assert_eq(float(b.value), shown, "each step starts where the last ended")
		var to := float(b.moves[0].to)
		assert_gt(to, shown)
		shown = to
	assert_eq(shown, float(layers), "the last step shows every layer")
	var two := MyShortMaker.make(_common({"build": {"kind": "stamp", "file": "b_1.txt", "layers": 2}}, MyShortRules.STEPS))
	assert_eq(two.scenes.size(), 4, "two layers: two steps")
	assert_eq(_actors(two.scenes[1], "build")[0].file, "b_1.txt")


func test_pacing_fits_the_voice() -> void:
	var r := _built(4)
	r.captions = [_words(16), _words(16), _words(16), _words(16)]
	var s := MyShortMaker.make(r)
	var total := 0.0
	for scene: Dictionary in s.scenes:
		assert_lte(ShortRules.speech_seconds(scene.say), float(scene.seconds) - 1.0, "a moment to look after the words")
		total += float(scene.seconds)
	assert_between(total, ShortRules.MIN_SECONDS, ShortRules.MAX_SECONDS)
	var short := MyShortMaker.make(_common({"photos": ["p_1.jpg", "p_2.jpg"], "captions": ["Wow.", "Ok."], "title": "Hi"},
		MyShortRules.BUILT))
	assert_gte(ShortTimeline.length(short), ShortRules.MIN_SECONDS, "stretched to 20 s at least")


func test_a_preview_has_an_id_and_a_kept_one_its_own() -> void:
	var r := _built(2)
	assert_eq(MyShortMaker.make(r).id, MyShortMaker.PREVIEW_ID)
	r.id = "mine:7"
	assert_eq(MyShortMaker.make(r).id, "mine:7")
	assert_eq(MyShortMaker.make({}), {})
	assert_eq(MyShortMaker.make({"template": "built", "photos": []}), {})


func test_the_checker_knows_a_child_s_short_apart() -> void:
	var s := MyShortMaker.make(_built(2))
	var hand := s.duplicate(true)
	hand.id = "my_castle"
	assert_false(ShortCheck.problems(hand).is_empty(), "a hand-made Short has a hand-made topic and a link")
	var stolen := ShortLibrary.hand("rocket_parts").duplicate(true)
	stolen.scenes[0].actors.append({"kind": "photo", "file": "p_1.jpg", "at": [180, 200]})
	assert_true(" ".join(ShortCheck.problems(stolen)).contains("photo"), "a photo is a child's own: only in My Shorts")
	var odd := s.duplicate(true)
	odd.music = "a_song"
	odd.voice = "yes"
	assert_eq(ShortCheck.problems(odd).size(), 2)


func _actors(scene: Dictionary, kind: String) -> Array:
	var out: Array = []
	for a: Dictionary in scene.actors:
		if a.kind == kind:
			out.append(a)
	return out
