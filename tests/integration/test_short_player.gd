extends GutTest
## Owner #94 (spec §5.12b): the Short's player. It builds every scene's actors at once, shows a poster until played,
## draws any moment exactly (a seek is the frame playing gets to), keeps the caption on screen under the actors, reads
## each scene aloud on the first pass (a loop is quiet but for its sounds) and plays the sounds on cue.

class FakeVoice:
	extends ReadAloud.Voice
	var said: Array[String] = []
	var stops := 0

	func has_voice(_language: String) -> bool:
		return true

	func speak(text: String, _language: String) -> void:
		said.append(text)

	func stop() -> void:
		stops += 1


var _voice: ReadAloud.Voice
var fake: FakeVoice


func before_each() -> void:
	_voice = ReadAloud.voice
	fake = FakeVoice.new()
	ReadAloud.voice = fake


func after_each() -> void:
	ReadAloud.voice = _voice
	Curriculum.clear_cache()
	ShortLibrary.clear_cache()


func _sample() -> Dictionary:
	return {"id": "sample", "title": "Sample", "topic": "space", "link": {"star_map": true}, "scenes": [
		{"seconds": 6, "background": "space", "caption": "One.", "say": "Scene one.",
			"sounds": [{"at": 0.5, "effect": "pop"}, {"at": 1.0, "tune": {"kind": "notes", "notes": ["C5", "G5"], "beat": 0.2}}],
			"actors": [
				{"kind": "planet", "body": "earth", "at": [180, 250], "size": 90, "moves": [{"do": "pop", "at": 0.2},
					{"do": "orbit", "at": 1.0, "dur": 5.0, "around": [180, 300], "period": 4.0}]},
				{"kind": "words", "text": "Hello!", "at": [180, 100], "size": 40, "moves": [{"do": "drop", "at": 0.5},
					{"do": "spin", "at": 2, "turns": 1}]},
				{"kind": "arrow", "from": [40, 400], "to": [320, 400], "moves": [{"do": "draw", "at": 1.5}]}]},
		{"seconds": 7, "background": "sky", "caption": "Two.", "say": "Scene two.",
			"sounds": [{"at": 0.0, "effect": "whoosh"}],
			"actors": [{"kind": "shape", "shape": "pizza", "slices": 8, "at": [180, 250], "size": 200,
				"moves": [{"do": "pop", "at": 0}, {"do": "value", "at": 1, "to": 3}, {"do": "bounce", "at": 3}]}]},
		{"seconds": 8, "background": "paper", "caption": "Three?", "say": "Scene three?",
			"actors": [{"kind": "character", "who": "hoot", "at": [180, 250], "size": 140, "moves": [{"do": "slide", "at": 0, "from": [500, 250]}]},
				{"kind": "count", "from": 0, "to": 250, "suffix": " t", "at": [180, 420], "size": 40, "moves": [{"do": "value", "at": 0, "to": 250}]}]},
	]}


func _player(s: Dictionary = _sample()) -> ShortPlayer:
	var p := ShortPlayer.new()
	p.size = Vector2(288, 512)
	add_child_autofree(p)
	p.build(s)
	return p


func test_it_builds_every_scene_and_shows_a_poster() -> void:
	var p := _player()
	assert_eq(p.actors_of(0).size(), 3)
	assert_eq(p.actors_of(2).size(), 2)
	assert_false(p.playing, "nothing starts by itself")
	assert_eq(p.scene_index(), 0)
	assert_eq(p.caption.text, "One.")
	assert_true((p.actors_of(0)[0] as ShortActor).visible, "the poster shows the first scene's actors arrived")
	assert_almost_eq(p.stage.scale.x, 288.0 / 360.0, 0.001, "the 9:16 stage fits the player")


func test_a_seek_is_the_frame_playing_gets_to() -> void:
	var a := _player()
	a.play(true)
	for i in 60 * 9:
		a.advance(1.0 / 60.0)
	var b := _player()
	b.seek(a.time)
	assert_eq(b.scene_index(), 1)
	assert_eq(str(b.snapshot()), str(a.snapshot()), "the same actors, in the same places, sizes, turns and colours")
	assert_eq(b.caption.text, a.caption.text)


func test_captions_follow_the_scenes_and_stay_under_the_actors() -> void:
	var p := _player()
	for t: float in [0.1, 6.5, 14.0]:
		p.seek(t)
		var band := p.caption.get_parent() as Control
		assert_gte(band.position.y, ShortRules.CAPTION_TOP - 0.5, "the caption's band is at the bottom")
		assert_lte(band.position.y + band.size.y, ShortRules.STAGE.y, "on the stage")
	p.seek(6.5)
	assert_eq(p.caption.text, "Two.")
	p.seek(14.0)
	assert_eq(p.caption.text, "Three?")


func test_the_voice_reads_each_scene_once_and_the_sounds_play_on_cue() -> void:
	var p := _player()
	p.play()
	assert_eq(fake.said, ["Scene one."] as Array[String], "the first scene is read as it starts")
	for i in 60 * 7:
		p.advance(1.0 / 60.0)
	assert_eq(fake.said, ["Scene one.", "Scene two."] as Array[String])
	assert_true(p.events.has("effect:pop"), "the pop on its cue")
	assert_true(p.events.has("tune"), "the tune on its cue")
	assert_true(p.events.has("effect:whoosh"), "a cue at a scene's start")
	for i in 60 * 16:
		p.advance(1.0 / 60.0)
	assert_eq(p.passes, 1, "it looped")
	assert_true(p.playing, "and goes on")
	assert_eq(fake.said.size(), 3, "a loop is not read again")
	assert_eq(p.events.count("effect:pop"), 2, "its sounds play again")


func test_pause_stops_the_voice_and_play_goes_on() -> void:
	var p := _player()
	p.play()
	for i in 60 * 2:
		p.advance(1.0 / 60.0)
	var stops := fake.stops
	p.pause()
	assert_gt(fake.stops, stops, "the voice stops")
	assert_false(p.playing)
	var t := p.time
	p.toggle()
	assert_true(p.playing)
	assert_almost_eq(p.time, t, 0.0001, "it goes on from where it was")


func test_the_first_play_starts_from_the_beginning() -> void:
	var p := _player()
	assert_gt(p.time, 0.0, "the poster")
	p.toggle()
	assert_eq(p.time, 0.0, "the poster was only a preview")


func test_reduce_motion_never_overshoots() -> void:
	var p := _player()
	p.reduce_motion = true
	for i in 200:
		var t := i * 0.105
		var where := ShortTimeline.at(p.short, t)
		for a: ShortActor in p.actors_of(where.scene):
			var st := ShortTimeline.actor_state(a.data, where.local, true)
			assert_lte(float(st.scale), 1.0001, "%s at %.2f" % [a.name, t])


func test_every_hand_made_short_builds_and_its_captions_fit() -> void:
	for id in ShortLibrary.hand_ids():
		var s := ShortLibrary.hand(id)
		var p := _player(s)
		for i in ShortTimeline.scenes(s).size():
			p.seek(ShortTimeline.scene_start(s, i) + 0.5)
			var band := p.caption.get_parent() as Control
			assert_gte(band.position.y, ShortRules.CAPTION_TOP - 0.5, "%s scene %d: the caption stays under the actors" % [id, i + 1])
		p.queue_free()


func test_every_lesson_caption_fits_the_band_at_the_smallest_letters() -> void:
	var p := _player()
	var smallest: int = ShortStyle.CAPTION_SIZES[ShortStyle.CAPTION_SIZES.size() - 1]
	var band := p.caption.get_parent() as PanelContainer
	var room := ShortRules.STAGE.y - ShortPlayer.CAPTION_MARGIN - ShortRules.CAPTION_TOP
	var longest := ""
	for g in [3, 4, 5, 6, 7]:
		for sub in Curriculum.subjects(g):
			for u in Curriculum.units(g, str(sub.id)):
				if not u.has("file"):
					continue
				for scene: Dictionary in LessonShort.make(str(u.id)).scenes:
					if str(scene.caption).length() > longest.length():
						longest = str(scene.caption)
	p.caption.text = longest
	p.caption.add_theme_font_size_override("font_size", smallest)
	band.reset_size()
	assert_lte(band.get_combined_minimum_size().y, room, "the longest caption (%d letters) fits" % longest.length())


func test_lesson_shorts_captions_fit_too() -> void:
	for unit: String in ["g3.maths.numbers_to_10000", "g4.science.circuits", "g6.science.water_cycle", "g7.science.photosynthesis",
			"g5.history.greek_ideas", "g6.geography.population"]:
		var s := LessonShort.make(unit)
		var p := _player(s)
		for i in ShortTimeline.scenes(s).size():
			p.seek(ShortTimeline.scene_start(s, i) + 0.5)
			var band := p.caption.get_parent() as Control
			assert_gte(band.position.y, ShortRules.CAPTION_TOP - 0.5, "%s scene %d: '%s'" % [unit, i + 1, p.caption.text])
		p.queue_free()


## Owner #96: actor kinds are pluggable. A kind registered with its check (ShortKinds) and its drawer (ShortDrawers)
## passes the checker and is drawn by its drawer, told every moment (as `scene3d` and `video` will be).
class StarDrawer:
	extends ShortDrawer
	var setups := 0
	var draws := 0
	var times: Array[float] = []

	func setup(actor: ShortActor) -> void:
		setups += 1
		actor.size = Vector2(60, 60)
		actor.animated = true

	func draw(actor: ShortActor) -> void:
		draws += 1
		actor.draw_circle(actor.size * 0.5, 30.0, Color.YELLOW)

	func update(_actor: ShortActor, _state: Dictionary, t: float) -> void:
		times.append(t)


func test_a_new_actor_kind_plugs_in_with_its_check_and_its_drawer() -> void:
	var drawer := StarDrawer.new()
	ShortKinds.register("test_star", func(a: Dictionary) -> String: return "" if a.has("points") else "a star has points")
	ShortDrawers.register("test_star", drawer)
	var s := _sample()
	s.scenes[0].actors.append({"kind": "test_star", "points": 5, "at": [180, 300], "moves": [{"do": "pop", "at": 0.5}]})
	assert_eq(ShortCheck.problems(s), [] as Array[String], "the checker knows it")
	var bad := s.duplicate(true)
	bad.scenes[0].actors[3].erase("points")
	assert_string_contains("\n".join(ShortCheck.problems(bad)), "a star has points", "its own check")
	var p := _player(s)
	assert_eq(drawer.setups, 1, "its drawer made it")
	var star: ShortActor = p.actors_of(0)[3]
	assert_eq(star.drawer, drawer)
	assert_eq(star.size, Vector2(60, 60))
	p.seek(2.0)
	p.seek(2.5)
	assert_true(drawer.times.has(2.5), "told each moment (an animated kind)")
	assert_true(ShortKinds.names().has("words"), "the built-in kinds stay")
	ShortKinds.unregister("test_star")
	ShortDrawers.unregister("test_star")
	assert_false(ShortKinds.has("test_star"))
