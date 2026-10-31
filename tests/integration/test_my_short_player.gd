extends GutTest
## MAKE MY SHORT: a child's Short in the same player as every Short. Drawn, it meets the quality checker's frame rules
## (every actor inside the frame and above the caption's band, no words on words, big captions) whatever was picked or
## typed; its photo loads off the main thread; the avatar moves; a build rises layer by layer; the voice can be off;
## the music plays under it.

const EDGE := 1.0

class FakeVoice:
	extends ReadAloud.Voice

	func has_voice(_language: String) -> bool:
		return true


var _voice: ReadAloud.Voice
var _root := ""


func before_each() -> void:
	_voice = ReadAloud.voice
	ReadAloud.voice = FakeVoice.new()
	_root = "user://test_my_player_%d" % OS.get_process_id()
	MyShortAlbum.use(_root, PackedStringArray())


func after_each() -> void:
	ReadAloud.voice = _voice
	MyShortAlbum.forget()
	MyShortAlbum.use(MyShortAlbum.ROOT)
	for sub in ["photos", "builds"]:
		var d := _root.path_join(sub)
		if DirAccess.dir_exists_absolute(d):
			for f in DirAccess.get_files_at(d):
				DirAccess.remove_absolute(d.path_join(f))
			DirAccess.remove_absolute(d)
	DirAccess.remove_absolute(_root)


func _recipes() -> Array:
	var long := "I built a very tall tower with red glass and stone walls and bright lamps."
	var out: Array = []
	for n in range(MyShortRules.MIN_PHOTOS, MyShortRules.MAX_PHOTOS + 1):
		var photos: Array = []
		var captions: Array = []
		for i in n:
			photos.append("p_2026100%d_10000%d.jpg" % [n, i])
			captions.append(long if i % 2 == 0 else "")
		out.append({"template": "built", "title": ["", "How I built my castle", "My amazing build"][n % 3], "photos": photos,
			"captions": captions})
	out.append({"template": "built", "title": "Wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww", "photos": ["p_1.jpg", "p_2.jpg"]})
	for kind: String in MyShortFacts.KINDS:
		for id: String in MyShortFacts.things(kind):
			out.append({"template": "facts", "subject": {"kind": kind, "id": id}})
	for id: String in MyShortRules.BLUEPRINTS:
		out.append({"template": "steps", "build": {"kind": "blueprint", "id": id}, "captions": [long, "", long]})
	return out


func _rest(a: Dictionary, seconds: float) -> float:
	var at := 0.05
	for m: Dictionary in ShortTimeline.sorted_moves(a):
		if ShortRules.ENTRANCES.has(str(m.do)):
			at = float(m.at) + ShortTimeline.duration(m) + 0.05
			break
	return minf(at, seconds - 0.02)


func _check(s: Dictionary, p: ShortPlayer, found: Array[String]) -> void:
	var frame := Rect2(Vector2.ZERO, ShortRules.STAGE).grow(EDGE)
	var scenes := ShortTimeline.scenes(s)
	for i in scenes.size():
		var seconds := ShortTimeline.seconds_of(scenes[i])
		var start := ShortTimeline.scene_start(s, i)
		var actors: Array = p.actors_of(i)
		for actor: ShortActor in actors:
			for t: float in [_rest(actor.data, seconds), seconds - 0.03]:   # arrived, and at the scene's end (a photo drifts closer)
				p.seek(start + t)
				if not actor.visible or actor.modulate.a < 0.5:
					continue
				var r := actor.stage_rect()
				var where := "%s scene %d %s at %.2f s" % [s.title, i + 1, str(actor.data.get("text", actor.kind)), t]
				if not frame.encloses(r):
					found.append("%s: outside the frame %s" % [where, r])
				if r.grow(-2.0).intersects(p.caption_rect()):
					found.append("%s: under the caption's band %s / %s" % [where, r, p.caption_rect()])
				if actor.kind == "words":
					for other: ShortActor in actors:
						if other != actor and other.visible and other.modulate.a >= 0.5 and other.kind == "words" \
								and r.grow(-2.0).intersects(other.stage_rect().grow(-2.0)):
							found.append("%s: over %s" % [where, str(other.data.get("text", ""))])
		p.seek(start + 0.6)
		if p.caption.get_theme_font_size("font_size") < ShortStyle.MIN_CAPTION:
			found.append("%s scene %d: caption letters too small" % [s.title, i + 1])


func test_every_made_short_is_inside_the_frame_and_nothing_on_words() -> void:
	var found: Array[String] = []
	var n := 0
	for r: Dictionary in _recipes():
		var s := MyShortMaker.make(r)
		assert_false(s.is_empty(), str(r))
		var p := ShortPlayer.new()
		p.size = Vector2(288, 512)
		add_child(p)
		p.build(s)
		_check(s, p, found)
		p.free()
		n += 1
	assert_gt(n, 60)
	assert_eq(found, [] as Array[String], "%d problems:\n%s" % [found.size(), "\n".join(found.slice(0, 40))])


func _png() -> PackedByteArray:
	var img := Image.create(1280, 720, false, Image.FORMAT_RGB8)
	img.fill(Color(0.3, 0.7, 0.4))
	return img.save_png_to_buffer()


func test_the_photo_shows_once_loaded_and_the_avatar_moves() -> void:
	MyShortAlbum.keep_png_now(_png(), "p_1.jpg")
	var s := MyShortMaker.make({"template": "built", "photos": ["p_1.jpg", "p_2.jpg"]})
	var p := ShortPlayer.new()
	p.size = Vector2(288, 512)
	add_child_autofree(p)
	p.build(s)
	var photo: ShortActor = p.actors_of(1).filter(func(a: ShortActor) -> bool: return a.kind == "photo")[0]
	for i in 60:
		await wait_process_frames(1)
		if photo.has_meta(&"photo"):
			break
	assert_true(photo.get_meta(&"photo") is Texture2D, "loaded on a worker, then shown")
	var missing: ShortActor = p.actors_of(2).filter(func(a: ShortActor) -> bool: return a.kind == "photo")[0]
	await wait_process_frames(3)
	assert_false(missing.has_meta(&"photo"), "a photo that is gone shows the camera")
	var me: ShortActor = p.actors_of(0).filter(func(a: ShortActor) -> bool: return a.kind == "me")[0]
	assert_true(me.animated, "the avatar waves")


func test_a_step_ends_with_its_layers_shown() -> void:
	var s := MyShortMaker.make({"template": "steps", "build": {"kind": "blueprint", "id": "tower"}})
	var p := ShortPlayer.new()
	p.size = Vector2(288, 512)
	add_child_autofree(p)
	p.build(s)
	var layers := MyShortRules.blueprint_layers("tower")
	var last := 0.0
	for k in MyShortRules.MAX_STEPS:
		var i := k + 1
		p.seek(ShortTimeline.scene_start(s, i) + ShortTimeline.seconds_of(s.scenes[i]) - 0.05)
		var b: ShortActor = p.actors_of(i).filter(func(a: ShortActor) -> bool: return a.kind == "build")[0]
		assert_gt(b.value, last)
		last = b.value
	assert_almost_eq(last, float(layers), 0.01)


func test_the_voice_can_be_off_and_the_music_plays_under_it() -> void:
	var r := {"template": "facts", "subject": {"kind": "planet", "id": "mars"}, "voice": false, "music": "spring"}
	var p := ShortPlayer.new()
	p.size = Vector2(288, 512)
	add_child_autofree(p)
	p.build(MyShortMaker.make(r))
	p.play(true)
	for i in 120:
		await wait_process_frames(1)
		if p.music_playing():
			break
	assert_true(p.music_playing(), "the piece plays")
	p.advance(8.0)
	for e in p.events:
		assert_false(e.begins_with("say:"), "no voice: " + e)
	p.pause()
	assert_false(p.music_playing(), "a pause stops it")
	r.voice = true
	r.erase("music")
	p.build(MyShortMaker.make(r))
	p.play(true)
	await wait_process_frames(2)
	assert_true(p.events.has("say:3 facts about Mars"))
	assert_false(p.music_playing())
