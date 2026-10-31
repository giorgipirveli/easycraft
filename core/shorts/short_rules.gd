class_name ShortRules
extends RefCounted
## EasyCraft Shorts (owner #94, spec §5.12b): the words of a Short's data, in one place. A Short is a timeline of
## scenes drawn by the game itself (no video files: it plays offline), on a portrait stage of STAGE units:
##
##   {id, title, topic, link, grade?, scenes: [{seconds, background, caption, say, sounds?: [...], actors: [...]}]}
##
## - An actor: {kind, at: [x, y] (its middle, in stage units), size?, rot? (degrees), alpha?, value?, moves: [...]} and
##   its kind's fields (ACTOR_KINDS; ShortCheck knows them all). The stage is 360 × 640; the caption's band is the
##   bottom CAPTION_TOP.., so actors live above it.
## - A move: {do, at (seconds into its scene), dur?, ...}: MOVES (entrances: ENTRANCES) with DURATIONS by default.
## - A sound: {at, effect} (one of EFFECTS, the game's own sounds) or {at, tune} (SchoolSound's data: notes or claps).
## - link: what LEARN IT opens: {unit: "g4.science.circuits"} (the School at that unit), {board: true} (the Mission
##   Board), {star_map: true} (the Star Map).
## Pure: ShortTimeline does the moving, ShortCheck the checking, ShortFeed the order; ui/shorts draws them.

const STAGE := Vector2(360, 640)
const CAPTION_TOP := 440.0          # the caption's band (at most up to here): always on screen, under the actors
## A hand-made Short: one idea, 3-6 scenes, 20-60 s (the brief). A Lesson in a minute: its cards in turn.
const MIN_SECONDS := 20.0
const MAX_SECONDS := 60.0
const LESSON_MIN_SECONDS := 30.0
const MIN_SCENES := 3
const MAX_SCENES := 6
const LESSON_MAX_SCENES := 24
const SCENE_MIN := 2.5
const SCENE_MAX := 16.0
const MAX_ACTORS := 16
const MAX_MOVES := 10
const MAX_SOUNDS := 4
const MAX_TITLE := 34
const MAX_CAPTION := 90             # a hand-made caption: big letters, three lines at most
const LESSON_MAX_CAPTION := 150     # a lesson card's sentence: smaller letters, up to five lines
const MAX_SAY := 240
const MAX_WORDS := 60               # a words actor
## The read-aloud voice: about 150 words a minute (children's audiobooks and the system voices at their normal rate).
## A scene's `say` must fit its seconds, and its caption too (ShortStyle: the style guide).
const WORDS_PER_SECOND := ShortStyle.WORDS_PER_SECOND
## A move that ends after its scene is cut; the checker allows this much.
const SLACK := 0.01
## Actors may start or end a little off the stage (they slide or fall in).
const OFF_STAGE := 260.0

const ACTOR_KINDS: Array[String] = ["words", "picture", "block", "part", "planet", "character", "arrow", "line", "shape",
	"map", "count"]
## Moves. Entrances (the actor is hidden before its first one): pop, appear, fade (from 0), slide, drop, draw.
const MOVES: Array[String] = ["pop", "appear", "fade", "slide", "drop", "draw", "move", "grow", "spin", "bounce", "pulse",
	"shake", "orbit", "out", "value"]
const ENTRANCES: Array[String] = ["pop", "appear", "slide", "drop", "draw"]
const DURATIONS := {"pop": 0.45, "appear": 0.0, "fade": 0.5, "slide": 0.6, "drop": 0.8, "draw": 0.8, "move": 0.8,
	"grow": 0.5, "spin": 1.0, "bounce": 0.8, "pulse": 0.6, "shake": 0.5, "orbit": 1.0, "out": 0.35, "value": 1.0}
## Each move's own ease unless it names one (ShortTimeline.EASES).
const MOVE_EASES := {"pop": "back", "fade": "out", "slide": "back", "drop": "bounce", "draw": "out", "move": "smooth",
	"grow": "back", "spin": "smooth", "out": "in", "value": "out"}

const BACKGROUNDS: Array[String] = ["sky", "space", "paper", "grass", "sea", "night", "sunset", "chalk", "lab", "tint"]
## Drawn shapes (ShortActor), each in a box `size` wide. pizza {slices, value: slices shaded}; moon_phase {value: 0 new,
## 0.5 full, 1 new again}; bulb {value: 0 off, 1 lit}; ring (drawn round by `draw`); thermometer {value: 0-1 full}.
const SHAPES: Array[String] = ["circle", "ring", "rect", "star", "drop", "cloud", "sun", "leaf", "flame", "bolt", "pizza",
	"moon_phase", "bulb", "battery", "spark", "ice", "crater", "tree", "mountain", "heart", "thermometer", "cube",
	"plus", "equals", "wave", "gas", "pyramid"]
## The characters: Professor Hoot (the School's owl in his cap), a robot, an astronaut, or any animal of the game
## (AnimalRules.SPECIES: Pip, the owl, the fox...).
const PEOPLE: Array[String] = ["hoot", "robot", "astronaut"]
## The game's own sounds a Short may play on cue (Audio.SOUNDS has each: a test checks).
const EFFECTS: Array[String] = ["pop", "whoosh", "boing", "ding", "sparkle", "chime", "rocket_whoosh", "splash", "bubbles",
	"coin", "jingle_goal", "star_land", "layer_pop", "ui_tick", "spark_pop", "rainbow", "egg_crack", "ice_crackle",
	"thud", "fanfare", "wisp_chime", "confetti_boom", "party_horn", "rock_crash"]

## Named colours: the game's palette (UiKit, SchoolUi, the Theater's tabs), bright on every background.
const COLOURS := {"yellow": Color("ffd23f"), "green": Color("2fae4e"), "blue": Color("3a7be8"), "red": Color("d9463b"),
	"orange": Color("f08a1c"), "teal": Color("139e9b"), "purple": Color("7b4bd6"), "pink": Color("d9437a"),
	"white": Color("ffffff"), "ink": Color("1f2a4a"), "sky": Color("7fd8ff"), "brown": Color("a8642a"),
	"grey": Color("9a948c"), "gold": Color("f5c542"), "lime": Color("8dff8a"), "cream": Color("fdf6e3"),
	"black": Color("141821"), "ice": Color("d8f3ff"), "leaf": Color("5cb85c"), "sea": Color("2a7fd4")}

## The hand-made Shorts' topics, in the feed's order: a topic's Shorts stay together (the feed's order teaches).
const TOPICS := {
	"rockets": {"title": "Rockets", "color": Color("f08a1c")},
	"space": {"title": "Space", "color": Color("7b4bd6")},
	"science": {"title": "Science", "color": Color("2fae4e")},
	"nature": {"title": "Nature", "color": Color("5cb85c")},
	"maths": {"title": "Maths", "color": Color("3a7be8")},
	"history": {"title": "History", "color": Color("a8642a")},
}
const TOPIC_ORDER: Array[String] = ["rockets", "space", "science", "nature", "maths", "history"]

## LEARN IT's targets.
const LINK_UNIT := "unit"
const LINK_BOARD := "board"
const LINK_STAR_MAP := "star_map"


## A colour by name or "#rrggbb" (white for anything else).
static func colour(v: Variant, fallback: Color = Color.WHITE) -> Color:
	if v is String:
		if COLOURS.has(v):
			return COLOURS[v]
		if (v as String).begins_with("#") and Color.html_is_valid(v):
			return Color(v)
	return fallback


static func is_colour(v: Variant) -> bool:
	return v is String and (COLOURS.has(v) or ((v as String).begins_with("#") and Color.html_is_valid(v)))


## A topic's colour: a hand-made topic's, else a School subject's (a Lesson in a minute's topic), else the Theater's.
static func topic_colour(topic: String) -> Color:
	if TOPICS.has(topic):
		return TOPICS[topic].color
	if topic == MyShortRules.TOPIC:   # MAKE MY SHORT: a child's own
		return MyShortRules.TOPIC_COLOUR
	if SchoolUi.SUBJECT_COLORS.has(topic):
		return SchoolUi.SUBJECT_COLORS[topic]
	return Color("7b4bd6")


## A School subject's name as a Lesson in a minute's topic.
const SUBJECT_TITLES := {"maths": "Maths", "science": "Science", "english": "English", "history": "History",
	"geography": "Geography", "citizenship": "Citizenship", "computing": "Computing", "art": "Art", "music": "Music",
	"health_pe": "Health and PE", "design_tech": "Design and Tech", "projects": "Projects"}


## A topic's words: "Rockets" (a hand-made topic), "Science" (a School subject's).
static func topic_title(topic: String) -> String:
	if TOPICS.has(topic):
		return str(TOPICS[topic].title)
	if topic == MyShortRules.TOPIC:   # MAKE MY SHORT: a child's own
		return MyShortRules.TOPIC_TITLE
	return str(SUBJECT_TITLES.get(topic, topic.capitalize()))


## [x, y] as a Vector2 (Vector2.ZERO for anything else).
static func point(v: Variant) -> Vector2:
	if v is Array and (v as Array).size() == 2 and typeof(v[0]) in [TYPE_INT, TYPE_FLOAT] and typeof(v[1]) in [TYPE_INT, TYPE_FLOAT]:
		return Vector2(float(v[0]), float(v[1]))
	return Vector2.ZERO


## Where an actor stands (its middle): its `at`, or for an arrow or a line without one, half-way along it.
static func anchor(actor: Dictionary) -> Vector2:
	if is_point(actor.get("at")):
		return point(actor.at)
	if is_point(actor.get("from")) and is_point(actor.get("to")):
		return (point(actor.from) + point(actor.to)) * 0.5
	return Vector2.ZERO


static func is_point(v: Variant) -> bool:
	return v is Array and (v as Array).size() == 2 and typeof(v[0]) in [TYPE_INT, TYPE_FLOAT] \
		and typeof(v[1]) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v[0])) and is_finite(float(v[1]))


## How many words `text` has (for the voice's time).
static func word_count(text: String) -> int:
	var n := 0
	for w in text.split(" ", false):
		if w.strip_edges() != "":
			n += 1
	return n


## Seconds the voice needs for `text`.
static func speech_seconds(text: String) -> float:
	return word_count(text) / WORDS_PER_SECOND
