extends GutTest
## Owner #96 (spec §5.12b "High quality, with real tools"): the quality checker on the drawn frames. Every Short (the
## hand-made ones, and every fourth Lesson in a minute of grades 3-7) is played in a real player and, at the moment each
## actor has arrived: it is inside the frame (actors marked `bleed` are meant to peek in from an edge: a giant Sun, the
## ground), it is not under the caption's band, and no two words stand on each other; the caption's letters are big
## enough and white on its dark band.

const EDGE := 1.0   # a drawing may touch the frame's edge


func after_each() -> void:
	ShortLibrary.clear_cache()
	Curriculum.clear_cache()


func _shorts() -> Array:
	var out: Array = []
	for id in ShortLibrary.hand_ids():
		out.append(ShortLibrary.hand(id))
	for g in ShortFeed.GRADES:
		var entries := ShortFeed.lesson_entries(g)
		for i in range(0, entries.size(), 4):
			out.append(LessonShort.make(str(entries[i].unit)))
	return out


## When the actor has arrived: its first entrance's end (the scene's start without one).
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
			if bool(actor.data.get("bleed", false)):
				continue
			if actor.kind in ["words", "count"]:   # at the scene's end too: a count's last number is its widest
				p.seek(start + seconds - 0.03)
				if actor.visible and actor.modulate.a >= 0.5 and not frame.encloses(actor.stage_rect()):
					found.append("%s scene %d %s at its end: outside the frame %s" % [s.id, i + 1,
						str(actor.data.get("text", actor.kind)), actor.stage_rect()])
			var t := _rest(actor.data, seconds)
			p.seek(start + t)
			if not actor.visible or actor.modulate.a < 0.5:
				continue
			var r := actor.stage_rect()
			var where := "%s scene %d %s at %.2f s" % [s.id, i + 1, str(actor.data.get("text", actor.kind)), t]
			if not frame.encloses(r):
				found.append("%s: outside the frame %s" % [where, r])
			if r.grow(-2.0).intersects(p.caption_rect()):
				found.append("%s: under the caption's band %s / %s" % [where, r, p.caption_rect()])
			if actor.kind in ["words", "count"]:
				for other: ShortActor in actors:
					if other == actor or not other.visible or other.modulate.a < 0.5 or not other.kind in ["words", "count"]:
						continue
					if r.grow(-2.0).intersects(other.stage_rect().grow(-2.0)):
						found.append("%s: over %s" % [where, str(other.data.get("text", other.kind))])
		p.seek(start + 0.6)
		var fs := p.caption.get_theme_font_size("font_size")
		if fs < ShortStyle.MIN_CAPTION:
			found.append("%s scene %d: caption letters %d" % [s.id, i + 1, fs])


func test_every_actor_inside_the_frame_and_nothing_on_top_of_words() -> void:
	var found: Array[String] = []
	var n := 0
	for s: Dictionary in _shorts():
		var p := ShortPlayer.new()
		p.size = Vector2(288, 512)
		add_child(p)
		p.build(s)
		_check(s, p, found)
		p.free()
		n += 1
	assert_gt(n, 150, "the hand-made Shorts and a fourth of the lessons")
	assert_eq(found, [] as Array[String], "%d problems:\n%s" % [found.size(), "\n".join(found.slice(0, 60))])


func test_the_caption_is_white_on_a_dark_band() -> void:
	var p := ShortPlayer.new()
	add_child_autofree(p)
	p.build(ShortLibrary.hand(ShortLibrary.hand_ids()[0]))
	var band := p.caption_colour()
	assert_gte(ShortStyle.contrast(p.caption.get_theme_color("font_color"), Color(band.r, band.g, band.b)), 12.0)
	assert_gte(band.a, 0.8, "dark enough over any background")
