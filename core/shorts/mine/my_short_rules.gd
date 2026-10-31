class_name MyShortRules
extends RefCounted
## MAKE MY SHORT (spec §5.12b "As built (My Shorts)"): a child makes a Short of their own from the game's pieces with a
## few taps and keeps it on this device only. What a child's Short is, as pure rules:
## - a RECIPE (small: a few hundred bytes) kept in the profile (MyShortsData, ProfileData.my_shorts; never in the
##   account's server backup: ProfileBackup leaves it out), made into a Short when it plays (MyShortMaker): it always
##   passes ShortCheck, because the maker paces and sizes it itself;
## - one of three TEMPLATES that teach or show: BUILT ("How I built it": 2-4 of the child's own photos with captions),
##   FACTS ("3 facts about…": a planet, a wonder or an animal, the game's own facts: MyShortFacts) and STEPS ("Step by
##   step": a build's layers, from one of the child's stamps or a blueprint);
## - words: a quick phrase (no typing: for children who can't type yet; each is read aloud when tapped) or typed words
##   that pass check_words: the game's word filter for children (ChatRules.filter_code: bad words, phone numbers,
##   emails, links, addresses), English letters only, and no names (the child's username, "my name is…"): no real
##   child's name is ever in a Short. The avatar is fine (it is a drawing of the child's look, not a name);
## - a backdrop, music from the game's own pieces (or none), the voice on or off.
## Nothing here pays, counts or rewards: making Shorts gives nothing but the Short.

const PREFIX := "mine:"
## A child's Short's topic (its colour and its pill: "My Short").
const TOPIC := "mine"
const TOPIC_TITLE := "My Short"
const TOPIC_COLOUR := Color("d9437a")
## The most Shorts this device keeps (the maker asks for one to be deleted first).
const MAX_SHORTS := 20

const BUILT := "built"
const FACTS := "facts"
const STEPS := "steps"
const TEMPLATES: Array[String] = [BUILT, FACTS, STEPS]
const TEMPLATE_WORDS := {
	BUILT: {"title": "HOW I BUILT IT", "line": "Your photos and your words"},
	FACTS: {"title": "3 FACTS ABOUT…", "line": "A planet, a wonder or an animal"},
	STEPS: {"title": "STEP BY STEP", "line": "How to build it, layer by layer"},
}

const MIN_PHOTOS := 2
const MAX_PHOTOS := 4
const FACT_COUNT := 3
const MIN_STEPS := 2
const MAX_STEPS := 3
## Layers a build may have (a stamp is at most 16 a side).
const MAX_LAYERS := 16
const MAX_TITLE := 34              # ShortRules.MAX_TITLE
const MAX_CAPTION := 80            # typed: a caption is at most 90 (ShortRules.MAX_CAPTION)
const MAX_FACT := 90

## The backdrops a child picks from (ShortRules.BACKGROUNDS but the tint).
const BACKDROPS: Array[String] = ["sky", "grass", "sea", "sunset", "night", "space", "paper", "chalk", "lab"]
## Music: none first, then the game's own classical pieces that play in every world (MusicPieces).
const MUSIC: Array[String] = ["", "ode_to_joy", "spring", "morning_mood", "waltz_flowers", "fur_elise", "nachtmusik",
	"mountain_king"]
## Under the voice and the sounds.
const MUSIC_DB := -15.0

## The game's blueprints a Step by step can show (the palette's stamps and the fort).
const BLUEPRINTS := {"house": ItemIds.STAMP_HOUSE, "tower": ItemIds.STAMP_TOWER, "bridge": ItemIds.STAMP_BRIDGE,
	"tree": ItemIds.STAMP_TREE, "rainbow": ItemIds.STAMP_RAINBOW, "fort": ItemIds.BUILD_FORT}
const BLUEPRINT_NAMES := {"house": "a house", "tower": "a tower", "bridge": "a bridge", "tree": "a tree",
	"rainbow": "a rainbow", "fort": "a fort"}
const STAMP_NAME := "my stamp"

## Quick phrases (no typing needed).
const TITLES := {
	BUILT: ["How I built my house", "How I built my castle", "How I built my rocket", "How I built my farm",
		"How I built my tower", "How I built my zoo", "My secret base", "Look what I made!", "My dream home",
		"My amazing build"],
}
## Step by step's titles, with the build's name ("How to build a house").
const STEP_TITLES: Array[String] = ["How to build %s", "Let's build %s!", "Build %s with me!"]
const PHOTO_PHRASES: Array[String] = ["First, I picked my blocks.", "I started with the floor.", "Then I built the walls.",
	"I put on a roof.", "I added windows and a door.", "I made it colourful!", "This part was tricky!",
	"I added a garden.", "Look how tall it is!", "Here it is, all done!", "My favourite part is here.",
	"I built it with my buddy."]
const STEP_PHRASES: Array[String] = ["Start at the bottom: lay the first blocks.", "Build up, one layer at a time.",
	"Add the next layer on top.", "Leave a gap for the door.", "Now the roof goes on top.", "Add the last blocks.",
	"Make both sides match.", "Ta-da! It's done!"]
## The last scene asks a question to wonder about (as every Short does): picked, never typed.
const ENDINGS := {
	BUILT: ["What will you build next?", "Can you build one too?", "Which part do you like best?",
		"What would you add to it?"],
	FACTS: ["Which fact do you like best?", "Did you know that?", "What will you find out next?",
		"Which fact will you tell a friend?"],
	STEPS: ["Can you build it too?", "What will you build next?", "What would you change?",
		"Which step was the hardest?"],
}

## Typed words: English letters, digits, spaces and plain punctuation (the game's font and its filter read them).
static var _letters_re := RegEx.create_from_string("^[A-Za-z0-9 .,!?'’:;()&\\-]+$")
static var _id_re := RegEx.create_from_string("^mine:[1-9][0-9]{0,5}$")
static var _photo_re := RegEx.create_from_string("^p_[a-z0-9_]{1,40}\\.jpg$")
static var _build_re := RegEx.create_from_string("^b_[a-z0-9_]{1,40}\\.txt$")
static var _non_word_re := RegEx.create_from_string("[^a-z0-9]+")
## Words that give a name away (a child's own or another's): "my name is…", "I'm called…".
const NAME_PHRASES: Array[String] = ["my name", "i am called", "i m called", "im called", "i am named", "my real name",
	"my full name", "named after me"]
const MIN_NAME := 3

static var _layers_cache := {}

## The actor kinds a child's Short brings (ShortKinds registers their checks, ShortDrawers their drawers: MyShortDrawers):
## - photo {file, w?, h?}: a photo of the album (MyShortAlbum), in a white frame; only in My Shorts (it is on this
##   device only);
## - me {size, emote?}: the child's avatar, a drawing of their own look (AvatarIcon) doing an emote; never a name;
## - wonder {id, size}: a wonder's stamp (WonderStamp);
## - build {blueprint | file, size, value}: a build's blocks seen from above a corner, its first `value` layers shown
##   (a `value` move raises it layer by layer).
const ACTOR_KINDS: Array[String] = ["photo", "me", "wonder", "build"]
const ME_EMOTES: Array[String] = ["wave", "cheer", "clap", "thumbs_up", "hooray", "think", "bow", "laugh", "victory"]
const PHOTO_SIDES := Vector2(40.0, 340.0)
const BUILD_SIDES := Vector2(60.0, 340.0)


static func id_for(n: int) -> String:
	return PREFIX + str(n)


static func is_mine_id(id: Variant) -> bool:
	return id is String and _id_re.search(id) != null


static func is_photo_file(file: Variant) -> bool:
	return file is String and _photo_re.search(file) != null


static func is_build_file(file: Variant) -> bool:
	return file is String and _build_re.search(file) != null


## A blueprint's words in a title ("a house").
static func blueprint_name(id: String) -> String:
	return str(BLUEPRINT_NAMES.get(id, ""))


## How many block layers blueprint `id` has (its rows of blocks, bottom to top).
static func blueprint_layers(id: String) -> int:
	if not BLUEPRINTS.has(id):
		return 0
	if not _layers_cache.has(id):
		_layers_cache[id] = layers_of(Blueprints.local(int(BLUEPRINTS[id])))
	return _layers_cache[id]


## The layers of `blocks` (positions -> ids): the different heights with a block (air left out).
static func layers_of(blocks: Dictionary) -> int:
	var ys := {}
	for p: Vector3i in blocks:
		if int(blocks[p]) != BlockIds.AIR:
			ys[p.y] = true
	return ys.size()


## How many steps a build of `layers` layers is shown in (2 for two layers, else MAX_STEPS).
static func steps_for(layers: int) -> int:
	return clampi(layers, MIN_STEPS, MAX_STEPS)


## "" when `a` is right for its kind (one of ACTOR_KINDS).
static func kind_problem(kind: String, a: Dictionary) -> String:
	match kind:
		"photo":
			if not is_photo_file(a.get("file")):
				return "a photo is a file of the album (p_<…>.jpg)"
			for key: String in ["w", "h"]:
				if a.has(key) and (typeof(a[key]) not in [TYPE_INT, TYPE_FLOAT] or float(a[key]) < PHOTO_SIDES.x \
						or float(a[key]) > PHOTO_SIDES.y):
					return "a photo is %d-%d wide and high" % [int(PHOTO_SIDES.x), int(PHOTO_SIDES.y)]
		"me":
			if a.has("emote") and not ME_EMOTES.has(str(a.emote)):
				return "unknown emote '%s'" % a.emote
		"wonder":
			if not WonderFacts.has(StringName(str(a.get("id", "")))):
				return "unknown wonder '%s'" % a.get("id", "")
		"build":
			if a.has("blueprint"):
				if not BLUEPRINTS.has(str(a.blueprint)):
					return "unknown blueprint '%s'" % a.blueprint
			elif not is_build_file(a.get("file")):
				return "a build is a blueprint or a stamp's copy (b_<…>.txt)"
			if a.has("size") and (typeof(a.size) not in [TYPE_INT, TYPE_FLOAT] or float(a.size) < BUILD_SIDES.x \
					or float(a.size) > BUILD_SIDES.y):
				return "a build is %d-%d wide" % [int(BUILD_SIDES.x), int(BUILD_SIDES.y)]
			if a.has("value") and (typeof(a.value) not in [TYPE_INT, TYPE_FLOAT] or float(a.value) < 0.0):
				return "a build's value is the layers it shows (0 or more)"
	return ""


# --- Words ------------------------------------------------------------------------------------------------------------

## Typed words checked: {"text": cleaned} or {"error": code}: empty, too_long, letters (English letters only),
## personal_info and blocked_word (the game's filter for children), name (a username in `names`, or "my name is…").
static func check_words(text: String, most: int, names: Array = []) -> Dictionary:
	var t := ChatRules.clean(text)
	if t == "":
		return {"error": "empty"}
	if t.length() > most:
		return {"error": "too_long"}
	var code := ChatRules.filter_code(t)
	if code != "":
		return {"error": code}
	if _letters_re.search(t) == null:
		return {"error": "letters"}
	if _names_in(t, names):
		return {"error": "name"}
	return {"text": t}


static func _names_in(text: String, names: Array) -> bool:
	var plain := " %s " % _non_word_re.sub(text.to_lower(), " ", true).strip_edges()
	for phrase in NAME_PHRASES:
		if plain.contains(" %s " % phrase):
			return true
	var words := plain.split(" ", false)
	for n: Variant in names:
		var name := _non_word_re.sub(str(n).to_lower(), "", true)
		if name.length() >= MIN_NAME and words.has(name):
			return true
		# a username's letters split by its own underscores or digits ("blue_fox 42") still match together
		if name.length() >= MIN_NAME and plain.replace(" ", "").contains(name) and str(n).length() >= 6:
			return true
	return false


## What the maker says when typed words can't be used (kind words: never "bad").
static func message(code: String) -> String:
	match code:
		"empty":
			return "Type a few words first."
		"too_long":
			return "That's a lot of words! Make it a bit shorter."
		"letters":
			return "Use English letters and numbers only."
		"personal_info":
			return "Keep it safe: no phone numbers, places, emails or links."
		"blocked_word":
			return "That word can't go in a Short. Try saying it another way!"
		"name":
			return "No names in a Short, to keep everyone safe. Your avatar shows it's yours!"
	return ""


# --- A recipe ------------------------------------------------------------------------------------------------------------

## `v` as a recipe the maker can use ({} when it can't: an unknown template, too few photos, no such subject or build).
## Words that fail check_words become "" (the maker says its own), unknown choices take the first (no music, the voice
## on). Keys: template, title, captions, ending, backdrop, music, voice; BUILT photos; FACTS subject {kind, id} and
## facts (three indexes); STEPS build ({kind: "blueprint", id} or {kind: "stamp", file, layers}); id and made when kept.
static func clean_recipe(v: Variant) -> Dictionary:
	if not v is Dictionary:
		return {}
	var d: Dictionary = v
	var template := str(d.get("template", ""))
	if not TEMPLATES.has(template):
		return {}
	var out := {"template": template, "title": _clean_text(d.get("title"), MAX_TITLE)}
	var most_captions := 0
	match template:
		BUILT:
			var photos: Array[String] = []
			if d.get("photos") is Array:
				for f: Variant in d.photos:
					if not is_photo_file(f):
						return {}
					if not photos.has(f):
						photos.append(f)
			if photos.size() < MIN_PHOTOS or photos.size() > MAX_PHOTOS:
				return {}
			out.photos = photos
			most_captions = MAX_PHOTOS
		FACTS:
			var subject: Variant = d.get("subject")
			if not subject is Dictionary or not MyShortFacts.has(str(subject.get("kind", "")), str(subject.get("id", ""))):
				return {}
			out.subject = {"kind": str(subject.kind), "id": str(subject.id)}
			out.facts = _clean_facts(d.get("facts"), MyShortFacts.facts(str(subject.kind), str(subject.id)).size())
		STEPS:
			var build: Variant = d.get("build")
			if not build is Dictionary:
				return {}
			match str(build.get("kind", "")):
				"blueprint":
					var id := str(build.get("id", ""))
					if blueprint_layers(id) < MIN_STEPS:
						return {}
					out.build = {"kind": "blueprint", "id": id}
				"stamp":
					var layers: Variant = build.get("layers")
					if not is_build_file(build.get("file")) or typeof(layers) not in [TYPE_INT, TYPE_FLOAT] \
							or int(layers) < MIN_STEPS or int(layers) > MAX_LAYERS:
						return {}
					out.build = {"kind": "stamp", "file": str(build.file), "layers": int(layers)}
				_:
					return {}
			most_captions = MAX_STEPS
	var captions: Array[String] = []
	if d.get("captions") is Array:
		for c: Variant in (d.captions as Array).slice(0, most_captions):
			captions.append(_clean_text(c, MAX_CAPTION))
	out.captions = captions
	var endings: Array = ENDINGS[template]
	out.ending = str(d.ending) if d.get("ending") is String and endings.has(d.ending) else str(endings[0])
	out.backdrop = str(d.backdrop) if d.get("backdrop") is String and BACKDROPS.has(d.backdrop) else BACKDROPS[0]
	out.music = str(d.music) if d.get("music") is String and MUSIC.has(d.music) else ""
	out.voice = bool(d.voice) if d.get("voice") is bool else true
	if is_mine_id(d.get("id")):
		out.id = str(d.id)
	var made: Variant = d.get("made")
	if typeof(made) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(made)) and float(made) >= 0.0 and float(made) < 1e11:
		out.made = int(made)
	return out


## Three different fact indexes below `count`, the child's first, then the first ones not picked.
static func _clean_facts(v: Variant, count: int) -> Array[int]:
	var out: Array[int] = []
	if v is Array:
		for i: Variant in v:
			if typeof(i) in [TYPE_INT, TYPE_FLOAT] and int(i) >= 0 and int(i) < count and not out.has(int(i)) \
					and out.size() < FACT_COUNT:
				out.append(int(i))
	var k := 0
	while out.size() < mini(FACT_COUNT, count) and k < count:
		if not out.has(k):
			out.append(k)
		k += 1
	return out


static func _clean_text(v: Variant, most: int) -> String:
	if not v is String:
		return ""
	var r := check_words(v, most)
	return str(r.get("text", ""))
