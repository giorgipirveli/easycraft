class_name ShortCheck
extends RefCounted
## EasyCraft Shorts (owner #94, spec §5.12b): a Short's data checked like the School's lessons. problems(short) lists
## everything wrong ([] when it can play): its id, title and topic; LEARN IT's link (a written School unit, the Mission
## Board or the Star Map); 3-6 scenes and 20-60 seconds (a Lesson in a minute: 2-24 scenes, 30-60 s); each scene's
## background, caption (always on screen: short enough to read), `say` (read aloud: it must fit the scene's seconds),
## sounds (the game's own effects or a SchoolSound tune, on cue inside the scene); every actor's kind and its fields (a
## School picture's data by SchoolPicture.problem, a block, a rocket part, a Star Map body, a character, a shape, a map,
## colours, where it stands); every move known, with what it needs, inside its scene. A hand-made Short ends with a
## question to wonder about. The words' kindness, spelling and letters are checked by the tests over every Short.
## A child's own Short (MAKE MY SHORT, spec §5.12b "As built (My Shorts)"; id "mine:<n>": MyShortRules) is checked the
## same way, but its topic is "mine", LEARN IT is optional, and only it may show a photo (the child's, on this device).

const LESSON_PREFIX := "lesson:"
const LESSON_MAX_TITLE := 48
const MAX_MAP_POINTS := 8
const MAX_MAP_LABEL := 14
const MAX_SEA := 60
const SIZE_RANGE := Vector2(8.0, 400.0)
const MAX_TUNE_SECONDS := 4.0   # a quiet cue, not a song

static var _hand_id := RegEx.create_from_string("^[a-z][a-z0-9_]{2,39}$")


## Everything wrong with `short` ([] when nothing). `lesson`: a Lesson in a minute (made from a School unit).
static func problems(short: Variant, lesson: bool = false) -> Array[String]:
	var out: Array[String] = []
	if not short is Dictionary:
		return ["a Short is a dictionary"]
	var s: Dictionary = short
	var id := str(s.get("id", ""))
	var mine := not lesson and MyShortRules.is_mine_id(id)   # MAKE MY SHORT: a child's own, made on this device
	if lesson:
		if not id.begins_with(LESSON_PREFIX) or not SchoolData.valid_id(id.trim_prefix(LESSON_PREFIX)):
			out.append("a lesson Short's id is lesson:<unit id>, not '%s'" % id)
	elif not mine and _hand_id.search(id) == null:
		out.append("the id '%s' is 3-40 small letters, digits and _" % id)
	var title := str(s.get("title", "")).strip_edges()
	var most := LESSON_MAX_TITLE if lesson else ShortRules.MAX_TITLE
	if title == "" or title.length() > most:
		out.append("%s: the title is 1-%d letters" % [id, most])
	var topic := str(s.get("topic", ""))
	if mine:
		if topic != MyShortRules.TOPIC:
			out.append("%s: a child's own Short's topic is '%s'" % [id, MyShortRules.TOPIC])
	elif (lesson and not Curriculum.SUBJECTS.has(topic)) or (not lesson and not ShortRules.TOPICS.has(topic)):
		out.append("%s: unknown topic '%s'" % [id, topic])
	if s.has("grade") and (typeof(s.grade) not in [TYPE_INT, TYPE_FLOAT] or int(s.grade) < 3 or int(s.grade) > 8):
		out.append("%s: grade is 3-8" % id)
	var why := "" if mine and not s.has("link") else link_problem(s.get("link"))   # a child's Short: LEARN IT where it fits
	if why != "":
		out.append("%s: link: %s" % [id, why])
	if s.has("music") and not (s.music is String and MyShortRules.MUSIC.has(s.music) and s.music != ""):
		out.append("%s: music is one of the game's pieces (MyShortRules.MUSIC)" % id)
	if s.has("voice") and not s.voice is bool:
		out.append("%s: voice is true or false" % id)
	var scenes: Variant = s.get("scenes")
	var least := 2 if lesson else ShortRules.MIN_SCENES
	var most_scenes := ShortRules.LESSON_MAX_SCENES if lesson else ShortRules.MAX_SCENES
	if not scenes is Array or (scenes as Array).size() < least or (scenes as Array).size() > most_scenes:
		out.append("%s: %d-%d scenes" % [id, least, most_scenes])
		return out
	var total := 0.0
	for i in (scenes as Array).size():
		var scene: Variant = scenes[i]
		var where := "%s scene %d" % [id, i + 1]
		if not scene is Dictionary:
			out.append("%s: a scene is a dictionary" % where)
			continue
		total += ShortTimeline.seconds_of(scene)
		_scene(scene, where, lesson, out)
		if not mine and (scene as Dictionary).get("actors") is Array:
			for a: Variant in scene.actors:
				if a is Dictionary and str((a as Dictionary).get("kind", "")) == "photo":
					out.append("%s: a photo is a child's own: only in My Shorts" % where)
	var shortest := ShortRules.LESSON_MIN_SECONDS if lesson else ShortRules.MIN_SECONDS
	if total < shortest - ShortRules.SLACK or total > ShortRules.MAX_SECONDS + ShortRules.SLACK:
		out.append("%s: %.1f seconds in all (%d-%d)" % [id, total, int(shortest), int(ShortRules.MAX_SECONDS)])
	# The Reel Studio (owner #96): a cinematic reel's own 3D stage (its times the Short's) and its rendered video.
	if s.has("stage"):
		var stage_why := Scene3DKind.stage_problem(s.stage, total)
		if stage_why != "":
			out.append("%s: stage: %s" % [id, stage_why])
	if s.has("video"):
		var video_why := VideoKind.name_problem(s.video)
		if video_why != "":
			out.append("%s: video: %s" % [id, video_why])
		elif not s.has("stage"):
			out.append("%s: video: a video reel keeps the stage it is rendered from" % id)
	if not lesson:
		var last: Variant = scenes[(scenes as Array).size() - 1]
		if last is Dictionary and not str((last as Dictionary).get("caption", "")).strip_edges().ends_with("?"):
			out.append("%s: the last caption asks a question to wonder about" % id)
	return out


## "" when LEARN IT can open `link`: {unit: a written School unit}, {board: true} or {star_map: true}.
static func link_problem(link: Variant) -> String:
	if not link is Dictionary or (link as Dictionary).size() != 1:
		return "one of {unit: id}, {board: true}, {star_map: true}"
	var l: Dictionary = link
	if l.has(ShortRules.LINK_UNIT):
		var unit := str(l.unit)
		if Curriculum.unit(unit).is_empty():
			return "no School unit %s" % unit
		if not Curriculum.has_content(unit):
			return "%s is not written yet" % unit
		return ""
	if l.get(ShortRules.LINK_BOARD) == true or l.get(ShortRules.LINK_STAR_MAP) == true:
		return ""
	return "unknown link %s" % [l]


static func _scene(scene: Dictionary, where: String, lesson: bool, out: Array[String]) -> void:
	var seconds := ShortTimeline.seconds_of(scene)
	if typeof(scene.get("seconds")) not in [TYPE_INT, TYPE_FLOAT] or seconds < ShortRules.SCENE_MIN \
			or seconds > ShortRules.SCENE_MAX:
		out.append("%s: %s seconds (%.1f-%.1f)" % [where, scene.get("seconds"), ShortRules.SCENE_MIN, ShortRules.SCENE_MAX])
	var bg := str(scene.get("background", ""))
	if not ShortRules.BACKGROUNDS.has(bg):
		out.append("%s: unknown background '%s'" % [where, bg])
	if scene.has("tint") and not ShortRules.is_colour(scene.tint):
		out.append("%s: the tint is a colour" % where)
	if scene.has("camera"):
		var cam: Variant = scene.camera
		if not cam is Dictionary or (cam.has("zoom") and (not ShortRules.is_point(cam.zoom) or ShortRules.point(cam.zoom).x < 0.5
				or ShortRules.point(cam.zoom).y > 2.0)) or (cam.has("focus") and not ShortRules.is_point(cam.focus)):
			out.append("%s: a camera is {zoom: [from, to] (0.5-2), focus: [x, y]}" % where)
	var caption := str(scene.get("caption", "")).strip_edges()
	var most := ShortRules.LESSON_MAX_CAPTION if lesson else ShortRules.MAX_CAPTION
	if caption == "" or caption.length() > most:
		out.append("%s: the caption is 1-%d letters (%d)" % [where, most, caption.length()])
	elif ShortRules.speech_seconds(caption) > seconds + ShortRules.SLACK:
		out.append("%s: the caption's %d words need %.1f s to read (%.1f words a second at most)" % [where,
			ShortRules.word_count(caption), ShortRules.speech_seconds(caption), ShortStyle.WORDS_PER_SECOND])
	var say := str(scene.get("say", "")).strip_edges()
	if say == "" or say.length() > ShortRules.MAX_SAY:
		out.append("%s: say is 1-%d letters" % [where, ShortRules.MAX_SAY])
	elif ShortRules.speech_seconds(say) > seconds + ShortRules.SLACK:
		out.append("%s: say needs %.1f s to read aloud: longer than its %.1f s" % [where, ShortRules.speech_seconds(say), seconds])
	var sounds: Variant = scene.get("sounds", [])
	if not sounds is Array or (sounds as Array).size() > ShortRules.MAX_SOUNDS:
		out.append("%s: at most %d sounds" % [where, ShortRules.MAX_SOUNDS])
	else:
		for k in (sounds as Array).size():
			_sound(sounds[k], "%s sound %d" % [where, k + 1], seconds, out)
	var actors: Variant = scene.get("actors", [])
	if not actors is Array or (actors as Array).size() > ShortRules.MAX_ACTORS:
		out.append("%s: at most %d actors" % [where, ShortRules.MAX_ACTORS])
		return
	for k in (actors as Array).size():
		_actor(actors[k], "%s actor %d" % [where, k + 1], seconds, out)


static func _sound(sound: Variant, where: String, seconds: float, out: Array[String]) -> void:
	if not sound is Dictionary:
		out.append("%s: a sound is {at, effect} or {at, tune}" % where)
		return
	var d: Dictionary = sound
	if typeof(d.get("at")) not in [TYPE_INT, TYPE_FLOAT] or float(d.at) < 0.0 or float(d.at) > seconds:
		out.append("%s: the sound's at is inside its scene" % where)
	if d.has("effect"):
		if not ShortRules.EFFECTS.has(str(d.effect)):
			out.append("%s: unknown effect '%s'" % [where, d.effect])
	elif d.has("tune"):
		var why := SchoolSound.problem(d.tune)
		if why != "":
			out.append("%s: tune: %s" % [where, why])
		elif SchoolSound.duration(d.tune) > MAX_TUNE_SECONDS:
			out.append("%s: a tune lasts at most %d s" % [where, int(MAX_TUNE_SECONDS)])
	else:
		out.append("%s: a sound has an effect or a tune" % where)


static func _actor(actor: Variant, where: String, seconds: float, out: Array[String]) -> void:
	if not actor is Dictionary:
		out.append("%s: an actor is a dictionary" % where)
		return
	var a: Dictionary = actor
	var kind := str(a.get("kind", ""))
	where += " (%s)" % kind
	if not ShortKinds.has(kind):   # owner #96: kinds are pluggable (ShortKinds)
		out.append("%s: unknown actor kind" % where)
		return
	if not ShortRules.is_point(a.get("at")) and not (kind in ["arrow", "line"] and not a.has("at")):
		out.append("%s: at is [x, y] on the stage" % where)
	else:
		var p := ShortRules.anchor(a)
		var room := Rect2(-Vector2.ONE * ShortRules.OFF_STAGE, ShortRules.STAGE + Vector2.ONE * 2.0 * ShortRules.OFF_STAGE)
		if not room.has_point(p):
			out.append("%s: %s is off the stage" % [where, p])
	if a.has("size") and (typeof(a.size) not in [TYPE_INT, TYPE_FLOAT] or float(a.size) < SIZE_RANGE.x \
			or float(a.size) > SIZE_RANGE.y):
		out.append("%s: size is %d-%d" % [where, int(SIZE_RANGE.x), int(SIZE_RANGE.y)])
	for key: String in ["color", "box", "fill", "color2", "on"]:
		if a.has(key) and not ShortRules.is_colour(a[key]):
			out.append("%s: %s is a colour name or #rrggbb" % [where, key])
	if kind in ["words", "count"]:   # the style guide: big enough, legible
		if a.has("size") and typeof(a.size) in [TYPE_INT, TYPE_FLOAT] and float(a.size) < ShortStyle.MIN_LETTER:
			out.append("%s: letters of size %s are too small (%d at least)" % [where, a.size, ShortStyle.MIN_LETTER])
		var text := ShortRules.colour(a.get("color"), Color.WHITE)
		var behind: Variant = ShortRules.colour(a.box) if a.has("box") else (ShortRules.colour(a.on) if a.has("on") else null)
		if not ShortStyle.legible(text, behind):
			out.append("%s: %s words are not legible on %s" % [where, a.get("color", "white"), a.get("box", a.get("on", "their outline"))])
	var why := ShortKinds.problem(kind, a)
	if why != "":
		out.append("%s: %s" % [where, why])
	var moves: Variant = a.get("moves", [])
	if not moves is Array or (moves as Array).size() > ShortRules.MAX_MOVES:
		out.append("%s: at most %d moves" % [where, ShortRules.MAX_MOVES])
		return
	for k in (moves as Array).size():
		_move(moves[k], "%s move %d" % [where, k + 1], seconds, out, kind)


static func _kind_problem(kind: String, a: Dictionary) -> String:
	match kind:
		"words":
			var text := str(a.get("text", "")).strip_edges()
			if text == "" or text.length() > ShortRules.MAX_WORDS:
				return "words need 1-%d letters of text" % ShortRules.MAX_WORDS
		"picture":
			var why := SchoolPicture.problem(a.get("picture"))
			if why != "":
				return "picture: %s" % why
			if a.has("w") and (typeof(a.w) not in [TYPE_INT, TYPE_FLOAT] or float(a.w) < 60.0 or float(a.w) > 360.0):
				return "a picture is 60-360 wide"
		"block":
			if block_id(a.get("block")) < 0:
				return "unknown block %s" % a.get("block")
		"part":
			if not RocketParts.is_part(block_id(a.get("part"))):
				return "%s is not a rocket part" % a.get("part")
		"planet":
			if StarMap.body(StringName(str(a.get("body", "")))).is_empty():
				return "unknown body %s" % a.get("body")
		"character":
			var who := str(a.get("who", ""))
			if not ShortRules.PEOPLE.has(who) and not AnimalRules.SPECIES.has(StringName(who)):
				return "unknown who '%s'" % who
		"arrow", "line":
			if not ShortRules.is_point(a.get("from")) or not ShortRules.is_point(a.get("to")):
				return "an arrow or a line needs from and to points"
			if a.has("bend") and typeof(a.bend) not in [TYPE_INT, TYPE_FLOAT]:
				return "bend is a number"
		"shape":
			if not ShortRules.SHAPES.has(str(a.get("shape", ""))):
				return "unknown shape '%s'" % a.get("shape")
			if str(a.shape) == "pizza" and (typeof(a.get("slices")) not in [TYPE_INT, TYPE_FLOAT] or int(a.slices) < 1
					or int(a.slices) > 16):
				return "a pizza has 1-16 slices"
		"map":
			return _map_problem(a)
		"count":
			for key: String in ["from", "to"]:
				if typeof(a.get(key)) not in [TYPE_INT, TYPE_FLOAT]:
					return "a count has from and to numbers"
	return ""


static func _map_problem(a: Dictionary) -> String:
	var lat: Variant = a.get("lat")
	var lon: Variant = a.get("long")
	if not ShortRules.is_point(lat) or not ShortRules.is_point(lon):
		return "a map has lat [from, to] and long [from, to]"
	var la := ShortRules.point(lat)
	var lo := ShortRules.point(lon)
	if la.x < -90.0 or la.y > 90.0 or la.x >= la.y or lo.x < -180.0 or lo.y > 180.0 or lo.x >= lo.y:
		return "a map's lat is inside -90..90 and its long inside -180..180, from the smaller"
	var points: Variant = a.get("points", [])
	if not points is Array or (points as Array).size() > MAX_MAP_POINTS:
		return "a map has at most %d points" % MAX_MAP_POINTS
	for pt: Variant in points:
		if not pt is Dictionary or typeof(pt.get("lat")) not in [TYPE_INT, TYPE_FLOAT] \
				or typeof(pt.get("long")) not in [TYPE_INT, TYPE_FLOAT]:
			return "a map point is {lat, long, label}"
		if float(pt.lat) < la.x or float(pt.lat) > la.y or float(pt.long) < lo.x or float(pt.long) > lo.y:
			return "a map point %s is off the map" % pt.get("label", "")
		if str(pt.get("label", "")).length() > MAX_MAP_LABEL:
			return "a map label is at most %d letters" % MAX_MAP_LABEL
	var seas: Variant = a.get("seas", [])
	var lands: Variant = a.get("lands", [])
	if not seas is Array or (seas as Array).size() > 4 or not lands is Array or (lands as Array).size() > 4:
		return "a map has at most 4 seas and 4 islands"
	for sea: Variant in [a.get("sea", [])] + (seas as Array) + (lands as Array):
		if not sea is Array or (sea as Array).size() > MAX_SEA:
			return "a map's sea is at most %d [lat, long] corners" % MAX_SEA
		for c: Variant in sea:
			if not ShortRules.is_point(c):
				return "a sea corner is [lat, long]"
	return ""


static func _move(move: Variant, where: String, seconds: float, out: Array[String], actor_kind: String = "") -> void:
	if not move is Dictionary:
		out.append("%s: a move is a dictionary" % where)
		return
	var m: Dictionary = move
	var kind := str(m.get("do", ""))
	if not ShortRules.MOVES.has(kind):
		out.append("%s: unknown move '%s'" % [where, kind])
		return
	if typeof(m.get("at")) not in [TYPE_INT, TYPE_FLOAT] or float(m.at) < 0.0:
		out.append("%s: a move starts at a time (seconds into its scene)" % where)
		return
	if float(m.at) > seconds:
		out.append("%s: %s starts after its scene ends" % [where, kind])
	elif float(m.at) + ShortTimeline.duration(m) > seconds + ShortRules.SLACK:
		out.append("%s: %s ends after its scene ends" % [where, kind])
	if m.has("ease") and not ShortTimeline.EASES.has(str(m.ease)):
		out.append("%s: unknown ease '%s'" % [where, m.ease])
	# The style guide's motion: arrivals of about 12-18 frames, nothing sliding at a constant speed.
	if ShortStyle.ARRIVALS.has(kind) and not (kind == "draw" and actor_kind == "map"):   # a map shows its dots in turn
		var span: Array = ShortStyle.ARRIVALS[kind]
		var d := ShortTimeline.duration(m)
		if d < float(span[0]) - ShortRules.SLACK or d > float(span[1]) + ShortRules.SLACK:
			out.append("%s: a %s takes %.2f-%.2f s (%d-%d frames), not %.2f" % [where, kind, float(span[0]), float(span[1]),
				ShortStyle.frames(float(span[0])), ShortStyle.frames(float(span[1])), d])
	if ShortStyle.EASED.has(kind) and str(m.get("ease", "")) == "linear":
		out.append("%s: a %s eases (no linear slides: 'smooth' for a drift)" % [where, kind])
	if kind == "move" and ShortTimeline.duration(m) < ShortStyle.MOVE_MIN - ShortRules.SLACK:
		out.append("%s: a move takes %.1f s at least (%d frames)" % [where, ShortStyle.MOVE_MIN, ShortStyle.frames(ShortStyle.MOVE_MIN)])
	match kind:
		"move":
			if not ShortRules.is_point(m.get("to")):
				out.append("%s: a move needs to: [x, y]" % where)
		"slide":
			if not ShortRules.is_point(m.get("from")):
				out.append("%s: a slide needs from: [x, y]" % where)
		"orbit":
			if not ShortRules.is_point(m.get("around")) or typeof(m.get("period")) not in [TYPE_INT, TYPE_FLOAT] \
					or float(m.period) <= 0.0:
				out.append("%s: an orbit needs around: [x, y] and a period above 0" % where)
		"grow":
			if typeof(m.get("to")) not in [TYPE_INT, TYPE_FLOAT] or float(m.to) <= 0.0:
				out.append("%s: grow needs to: a size above 0" % where)
		"value":
			if typeof(m.get("to")) not in [TYPE_INT, TYPE_FLOAT]:
				out.append("%s: value needs to: a number" % where)
		"fade":
			if m.has("to") and (typeof(m.to) not in [TYPE_INT, TYPE_FLOAT] or float(m.to) < 0.0 or float(m.to) > 1.0):
				out.append("%s: fade's to is 0-1" % where)


## A block's id from its number or its BlockIds name ("ROCKET_ENGINE"); -1 for anything else.
static func block_id(v: Variant) -> int:
	var id := -1
	if typeof(v) in [TYPE_INT, TYPE_FLOAT]:
		id = int(v)
	elif v is String:
		var names := (BlockIds as Script).get_script_constant_map()
		if names.has(v) and typeof(names[v]) == TYPE_INT:
			id = int(names[v])
	if BlockIds.is_block_id(id) and BlockIds.display_name(id) != "":
		return id
	return -1
