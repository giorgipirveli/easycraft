class_name MyShortMaker
extends RefCounted
## MAKE MY SHORT (spec §5.12b "As built (My Shorts)"): a child's recipe (MyShortRules.clean_recipe) made into a Short
## the player plays (ShortPlayer, the same as every Short), laid out and paced here so that it always passes ShortCheck:
## - each scene lasts as long as its words need (read at most 2.5 words a second, then a moment to look: READ_PAD),
##   at least its kind's seconds; the whole is stretched to 20 s when it is shorter (never over 60: the captions are
##   short and the scenes few);
## - every actor sits inside the frame and above the caption's band at a size the style guide allows, the words on
##   their sticker; moves ease in 12-18 frames, a photo drifts closer while its scene plays (a slow Ken Burns);
## - the last scene asks the question the child picked (MyShortRules.ENDINGS).
## The three templates:
## - BUILT, "How I built it": the title with the child's avatar waving and the first photo; a scene a photo (dropping,
##   sliding or popping in turn, numbered, with the child's caption); the ending with every photo and the avatar
##   cheering;
## - FACTS, "3 facts about…": the subject's picture (a planet in the Star Map's colours, a wonder's stamp, an animal's
##   portrait) under the title; a scene a fact, numbered; the ending; LEARN IT opens the Star Map for the sky and the
##   wonders;
## - STEPS, "Step by step": the whole build; a scene a step, its layers rising one by one (the `build` actor's value);
##   the whole build again.
## No names anywhere: the words are the child's (checked) or the game's own; the avatar is a drawing of the child's look.
## Pure: no files, no profile, no network.

const PREVIEW_ID := "mine:999999"
const TITLE_SECONDS := 5.0
const BODY_SECONDS := 6.0
const END_SECONDS := 5.5
## Seconds to look after the words are read.
const READ_PAD := 1.8
const STEP := 0.5

const BUILT_WORDS := ["Here is how I made it.", "Then I kept building.", "Nearly there!", "Here it is, all done!"]
const BUILT_TITLE := "Look what I made!"
const STEP_WORDS := ["Start at the bottom: lay the first blocks.", "Build up, one layer at a time.", "Put the top on."]
const STEP_WORDS_TWO := ["Lay the first layer.", "Put the top layer on."]

const PHOTO_BOX := Vector2(296, 166)
const ME_EMOTES: Array[String] = ["thumbs_up", "clap", "cheer", "hooray"]
const FACT_EMOTES: Array[String] = ["think", "thumbs_up", "clap"]


## The Short made from `recipe` ({} when the recipe can't be made). A kept recipe's id is its Short's; a recipe being
## made (the maker's preview) plays as PREVIEW_ID.
static func make(recipe: Variant) -> Dictionary:
	var r := MyShortRules.clean_recipe(recipe)
	if r.is_empty():
		return {}
	var title := _title(r)
	var specs := _specs(r, title)
	_pace(specs)
	var scenes: Array = []
	for i in specs.size():
		scenes.append(_scene(r, specs, i))
	var short := {"id": str(r.get("id", PREVIEW_ID)), "title": title, "topic": MyShortRules.TOPIC, "scenes": scenes,
		"voice": bool(r.voice)}
	if str(r.music) != "":
		short.music = str(r.music)
	if r.template == MyShortRules.FACTS:
		var link := MyShortFacts.link_of(str(r.subject.kind), str(r.subject.id))
		if not link.is_empty():
			short.link = link
	return short


static func _title(r: Dictionary) -> String:
	if str(r.title) != "":
		return str(r.title)
	match str(r.template):
		MyShortRules.FACTS:
			return MyShortFacts.title_for(str(r.subject.kind), str(r.subject.id))
		MyShortRules.STEPS:
			return MyShortRules.STEP_TITLES[0] % build_name(r.build)
	return BUILT_TITLE


## "a house" (a blueprint) or "my stamp" (the child's own).
static func build_name(build: Dictionary) -> String:
	return MyShortRules.blueprint_name(str(build.get("id", ""))) if build.get("kind") == "blueprint" else MyShortRules.STAMP_NAME


static func build_layers(build: Dictionary) -> int:
	if build.get("kind") == "blueprint":
		return MyShortRules.blueprint_layers(str(build.id))
	return int(build.get("layers", 0))


## Each scene's kind, words and least seconds: {kind: title | body | end, caption, least, k}.
static func _specs(r: Dictionary, title: String) -> Array:
	var out: Array = [{"kind": "title", "caption": title, "least": TITLE_SECONDS, "k": 0}]
	var captions: Array = r.captions
	match str(r.template):
		MyShortRules.BUILT:
			var n: int = (r.photos as Array).size()
			for k in n:
				var own := str(captions[k]) if k < captions.size() else ""
				var said := str(BUILT_WORDS[BUILT_WORDS.size() - 1]) if k == n - 1 else str(BUILT_WORDS[mini(k, BUILT_WORDS.size() - 2)])
				out.append({"kind": "body", "caption": own if own != "" else said, "least": BODY_SECONDS, "k": k})
		MyShortRules.FACTS:
			var facts := MyShortFacts.facts(str(r.subject.kind), str(r.subject.id))
			for k in (r.facts as Array).size():
				out.append({"kind": "body", "caption": facts[int(r.facts[k])], "least": BODY_SECONDS, "k": k})
		MyShortRules.STEPS:
			var n := MyShortRules.steps_for(build_layers(r.build))
			var words: Array = STEP_WORDS_TWO if n == 2 else STEP_WORDS
			for k in n:
				var own := str(captions[k]) if k < captions.size() else ""
				out.append({"kind": "body", "caption": own if own != "" else str(words[k]), "least": BODY_SECONDS, "k": k})
	out.append({"kind": "end", "caption": str(r.ending), "least": END_SECONDS, "k": 0})
	return out


## Seconds for every scene: its words read and a moment to look (at least its least), in half seconds; then the body
## scenes stretched together until the whole lasts ShortRules.MIN_SECONDS.
static func _pace(specs: Array) -> void:
	var total := 0.0
	for s: Dictionary in specs:
		var need := maxf(float(s.least), ShortRules.speech_seconds(str(s.caption)) + READ_PAD)
		s.seconds = minf(ceilf(need / STEP) * STEP, ShortRules.SCENE_MAX)
		total += float(s.seconds)
	var bodies: Array = specs.filter(func(s: Dictionary) -> bool: return s.kind == "body")
	while total < ShortRules.MIN_SECONDS and not bodies.is_empty():
		for s: Dictionary in bodies:
			if total >= ShortRules.MIN_SECONDS:
				break
			if float(s.seconds) + STEP <= ShortRules.SCENE_MAX:
				s.seconds = float(s.seconds) + STEP
				total += STEP


static func _scene(r: Dictionary, specs: Array, i: int) -> Dictionary:
	var spec: Dictionary = specs[i]
	var secs := float(spec.seconds)
	var actors: Array = []
	var sounds: Array = []
	match str(r.template):
		MyShortRules.BUILT:
			_built_scene(r, spec, secs, actors, sounds)
		MyShortRules.FACTS:
			_facts_scene(r, spec, secs, actors, sounds)
		MyShortRules.STEPS:
			_steps_scene(r, spec, secs, actors, sounds)
	return {"seconds": secs, "background": str(r.backdrop), "caption": str(spec.caption), "say": str(spec.caption),
		"sounds": sounds, "actors": actors}


# --- How I built it --------------------------------------------------------------------------------------------------

static func _built_scene(r: Dictionary, spec: Dictionary, secs: float, actors: Array, sounds: Array) -> void:
	var photos: Array = r.photos
	match str(spec.kind):
		"title":
			actors.append(_me([92, 330], 150, "wave", [{"do": "slide", "at": 0.4, "from": [-100, 330]}]))
			actors.append(_photo(photos[0], [244, 292], Vector2(176, 99), 6, [{"do": "pop", "at": 0.8}]))
			actors.append(_title_words(str(spec.caption), [180, 104], 34))
			actors.append(_star([42, 196], 34, "yellow", 1.2, secs))
			actors.append(_star([326, 186], 26, "orange", 1.4, secs))
			sounds.append_array([_sound(0.2, "pop"), _sound(0.4, "whoosh"), _sound(1.2, "sparkle")])
		"body":
			var k := int(spec.k)
			var at := [180, 244]
			var enter: Dictionary
			match k % 3:
				0:
					enter = {"do": "drop", "at": 0.1, "dur": 0.8, "height": 220}
					sounds.append(_sound(0.7, "boing"))
				1:
					enter = {"do": "slide", "at": 0.1, "dur": 0.6, "from": [-200, 244]}
					sounds.append(_sound(0.1, "whoosh"))
				_:
					enter = {"do": "pop", "at": 0.1, "dur": 0.5}
					sounds.append(_sound(0.1, "pop"))
			var drift := {"do": "grow", "at": 1.0, "dur": maxf(secs - 1.2, 0.5), "to": 1.05, "ease": "smooth"}
			actors.append(_photo(photos[k], at, PHOTO_BOX, -2 if k % 2 == 0 else 2, [enter, drift]))
			actors.append(_badge(str(k + 1), [44, 136], 34, 0.7))
			actors.append(_me([306, 380], 104, ME_EMOTES[k % ME_EMOTES.size()], [{"do": "pop", "at": 1.0}]))
			sounds.append(_sound(0.7, "ui_tick"))
		"end":
			var spots := {2: [[112, 176, -5], [250, 214, 5]], 3: [[100, 150, -5], [262, 160, 4], [180, 262, -2]],
				4: [[100, 130, -4], [262, 136, 4], [100, 256, 3], [262, 262, -3]]}
			var list: Array = spots[photos.size()]
			for k in photos.size():
				var s: Array = list[k]
				actors.append(_photo(photos[k], [s[0], s[1]], Vector2(140, 79), float(s[2]),
					[{"do": "pop", "at": 0.15 + 0.2 * k}]))
			actors.append(_me([180, 372], 120, "cheer", [{"do": "pop", "at": 0.9}]))
			actors.append(_star([36, 404], 26, "yellow", 1.1, secs))
			actors.append(_star([324, 404], 26, "pink", 1.3, secs))
			sounds.append_array([_sound(0.15, "pop"), _sound(0.9, "sparkle"), _sound(1.4, "jingle_goal")])


# --- 3 facts about… --------------------------------------------------------------------------------------------------

static func _facts_scene(r: Dictionary, spec: Dictionary, secs: float, actors: Array, sounds: Array) -> void:
	var kind := str(r.subject.kind)
	var id := str(r.subject.id)
	var wide := kind == MyShortFacts.PLANET and bool(StarMap.body(StringName(id)).get("ring", false))
	match str(spec.kind):
		"title":
			actors.append(_picture(kind, id, [180, 262], 140 if wide else 170, [{"do": "pop", "at": 0.5, "dur": 0.6}] \
				+ ([{"do": "bounce", "at": 1.4, "height": 24, "times": 2}] if kind == MyShortFacts.ANIMAL else [])))
			actors.append(_title_words(str(spec.caption), [180, 92], 28))
			actors.append(_me([64, 382], 96, "wave", [{"do": "pop", "at": 1.0}]))
			sounds.append_array([_sound(0.5, "pop"), _sound(1.0, "sparkle")])
		"body":
			var k := int(spec.k)
			var x: int = 180 if wide else [236, 124, 180][k % 3]
			var y: int = [230, 240, 236][k % 3]
			var size: int = 112 if wide else [150, 150, 170][k % 3]
			var enter: Dictionary = {"do": "pop", "at": 0.3}
			if k % 3 == 0:
				enter = {"do": "slide", "at": 0.3, "from": [460, y]}
			elif k % 3 == 1:
				enter = {"do": "slide", "at": 0.3, "from": [-100, y]}
			var drift := {"do": "move", "at": 1.0, "dur": maxf(secs - 1.2, 0.5), "to": [x + (8 if k % 2 == 0 else -8), y - 10],
				"ease": "smooth"}   # a slow drift: a still moment still lives
			actors.append(_picture(kind, id, [x, y], size, [enter, drift, {"do": "pulse", "at": 1.6, "amount": 0.06}]))
			actors.append(_badge(str(k + 1), [52, 70], 46, 0.15, [{"do": "pulse", "at": 0.9}]))
			var star_at: Array = [[318, 92], [318, 92], [40, 150]][k % 3]
			actors.append(_star(star_at, 26, ["yellow", "orange", "lime"][k % 3], 1.0, secs))
			var me_x := 64 if k % 3 == 0 else 300
			actors.append(_me([me_x, 380], 104, FACT_EMOTES[k % FACT_EMOTES.size()], [{"do": "pop", "at": 1.2}]))
			sounds.append_array([_sound(0.15, "pop"), _sound(0.3, "whoosh"), _sound(1.2, "chime")])
		"end":
			actors.append(_picture(kind, id, [180, 206], 120 if wide else 150, [{"do": "pop", "at": 0.2}]))
			for k in 3:
				actors.append(_badge(str(k + 1), [110 + 70 * k, 326], 28, 0.6 + 0.2 * k))
			actors.append(_me([306, 392], 80, "cheer", [{"do": "pop", "at": 1.2}]))
			sounds.append_array([_sound(0.2, "sparkle"), _sound(0.6, "ui_tick"), _sound(1.2, "jingle_goal")])


## The subject's picture: a planet (the Star Map's colours), a wonder's stamp, an animal's portrait.
static func _picture(kind: String, id: String, at: Array, size: int, moves: Array) -> Dictionary:
	match kind:
		MyShortFacts.PLANET:
			return {"kind": "planet", "body": id, "at": at, "size": size, "moves": moves}
		MyShortFacts.WONDER:
			return {"kind": "wonder", "id": id, "at": at, "size": size, "moves": moves}
	return {"kind": "character", "who": id, "at": at, "size": size, "moves": moves}


# --- Step by step ----------------------------------------------------------------------------------------------------

static func _steps_scene(r: Dictionary, spec: Dictionary, secs: float, actors: Array, sounds: Array) -> void:
	var layers := build_layers(r.build)
	match str(spec.kind):
		"title":
			actors.append(_build(r.build, [180, 270], 250, layers, [{"do": "pop", "at": 0.5, "dur": 0.6}]))
			actors.append(_title_words(str(spec.caption), [180, 86], 28))
			actors.append(_me([62, 388], 90, "wave", [{"do": "pop", "at": 1.0}]))
			sounds.append_array([_sound(0.2, "pop"), _sound(0.5, "layer_pop")])
		"body":
			var k := int(spec.k)
			var n := MyShortRules.steps_for(layers)
			var from := roundi(float(layers) * k / n)
			var to := roundi(float(layers) * (k + 1) / n)
			var grow := clampf(1.0 + 0.2 * (to - from), 1.2, minf(3.0, secs - 1.2))
			actors.append(_build(r.build, [180, 262], 280, from, [{"do": "value", "at": 0.7, "dur": grow, "to": to,
				"ease": "out"}]))
			actors.append(_badge("STEP %d" % (k + 1), [86, 64], 24, 0.15))
			actors.append(_me([306, 390], 84, ["thumbs_up", "think", "clap"][k % 3], [{"do": "pop", "at": 1.2}]))
			sounds.append_array([_sound(0.15, "pop"), _sound(0.8, "layer_pop"), _sound(0.8 + grow * 0.6, "layer_pop")])
		"end":
			actors.append(_build(r.build, [180, 236], 260, layers, [{"do": "pop", "at": 0.2}, {"do": "pulse", "at": 1.2}]))
			actors.append(_me([180, 392], 90, "cheer", [{"do": "pop", "at": 0.8}]))
			actors.append(_star([40, 120], 28, "yellow", 0.8, secs))
			actors.append(_star([320, 140], 24, "orange", 1.0, secs))
			sounds.append_array([_sound(0.2, "sparkle"), _sound(0.9, "jingle_goal")])


static func _build(build: Dictionary, at: Array, size: int, value: int, moves: Array) -> Dictionary:
	var a := {"kind": "build", "at": at, "size": size, "value": value, "moves": moves}
	if build.get("kind") == "blueprint":
		a.blueprint = str(build.id)
	else:
		a.file = str(build.file)
	return a


# --- Pieces ------------------------------------------------------------------------------------------------------------

static func _title_words(text: String, at: Array, size: int) -> Dictionary:
	return {"kind": "words", "text": text, "at": at, "size": size, "color": "ink", "box": "yellow", "width": 300,
		"moves": [{"do": "pop", "at": 0.2, "dur": 0.5}]}


static func _badge(text: String, at: Array, size: int, pop_at: float, more: Array = []) -> Dictionary:
	return {"kind": "words", "text": text, "at": at, "size": size, "color": "ink", "box": "yellow",
		"moves": [{"do": "pop", "at": pop_at}] + more}


static func _photo(file: String, at: Array, box: Vector2, rot: float, moves: Array) -> Dictionary:
	return {"kind": "photo", "file": file, "at": at, "w": box.x, "h": box.y, "rot": rot, "moves": moves}


static func _me(at: Array, size: int, emote: String, moves: Array) -> Dictionary:
	return {"kind": "me", "at": at, "size": size, "emote": emote, "moves": moves}


static func _star(at: Array, size: int, colour: String, at_s: float, secs: float) -> Dictionary:
	var moves: Array = [{"do": "pop", "at": at_s}]
	if at_s + 0.6 + 1.2 <= secs:
		moves.append({"do": "spin", "at": at_s + 0.6, "dur": 1.2, "turns": 1})
	return {"kind": "shape", "shape": "star", "at": at, "size": size, "color": colour, "moves": moves}


static func _sound(at: float, effect: String) -> Dictionary:
	return {"at": at, "effect": effect}
