class_name MusicPieces
extends RefCounted
## The classical pieces (owner feedback #31), their files and the moods they fit (MusicPlan). Public-domain
## compositions in public-domain or CC0 recordings (tools/make_classical_music.py, credits in
## assets/CREDITS.md). Each file is an excerpt of 1.5-3 minutes ending in a gentle fade; it plays once,
## then MusicPlan picks what comes next. `length` is the file's length in seconds (test_classical_music.gd
## checks it against the file).

const DIR := "res://assets/music/classical/"
const MENU := &"menu"
const MORNING := &"morning"
const DAY := &"day"
const NIGHT := &"night"
const BOSS := &"boss"
const UNDERGROUND := &"underground"

const PIECES := {
	&"fur_elise": {"composer": "Beethoven", "title": "Für Elise", "length": 135.7, "moods": [MENU, DAY]},
	&"ode_to_joy": {"composer": "Beethoven", "title": "Ode to Joy", "length": 131.4, "moods": [DAY]},
	&"moonlight": {"composer": "Beethoven", "title": "Moonlight Sonata", "length": 140.4, "moods": [NIGHT, UNDERGROUND]},
	&"nachtmusik": {"composer": "Mozart", "title": "Eine kleine Nachtmusik", "length": 116.5, "moods": [DAY]},
	&"figaro": {"composer": "Mozart", "title": "The Marriage of Figaro", "length": 167.0, "moods": [DAY]},
	&"symphony_40": {"composer": "Mozart", "title": "Symphony No. 40", "length": 117.6, "moods": [BOSS]},
	&"air": {"composer": "Bach", "title": "Air on the G String", "length": 167.7, "moods": [MENU, NIGHT]},
	&"goldberg_aria": {"composer": "Bach", "title": "Goldberg Variations: Aria", "length": 140.9,
		"moods": [MENU, NIGHT, UNDERGROUND]},
	&"morning_mood": {"composer": "Grieg", "title": "Morning Mood", "length": 158.1, "moods": [MORNING]},
	&"mountain_king": {"composer": "Grieg", "title": "In the Hall of the Mountain King", "length": 153.5,
		"moods": [BOSS]},
	&"waltz_flowers": {"composer": "Tchaikovsky", "title": "Waltz of the Flowers", "length": 162.8,
		"moods": [MENU, DAY]},
	&"spring": {"composer": "Vivaldi", "title": "Spring", "length": 137.6, "moods": [MORNING, DAY]},
	&"gymnopedie": {"composer": "Satie", "title": "Gymnopédie No. 1", "length": 181.4,
		"moods": [MENU, NIGHT, UNDERGROUND]},
	&"bumblebee": {"composer": "Rimsky-Korsakov", "title": "Flight of the Bumblebee", "length": 81.1, "moods": [BOSS]},
	# M5 Task 2: Frostpeak's and the Candy Kingdom's own pieces ("own": they play only where they are a universe's
	# favourite, UniverseRegistry.classical)
	&"winter_largo": {"composer": "Vivaldi", "title": "Winter", "length": 153.2, "moods": [DAY, NIGHT], "own": true},
	&"snow_dancing": {"composer": "Debussy", "title": "The Snow Is Dancing", "length": 143.1, "moods": [DAY],
		"own": true},
	&"minute_waltz": {"composer": "Chopin", "title": "Minute Waltz", "length": 107.2, "moods": [DAY], "own": true},
}
## The piece a mood asks for first (the sunrise: Morning Mood).
const FIRST := {MORNING: &"morning_mood"}

## M7: tests pretend music files are missing, as in a browser before the music pack is in (WebContent):
## (path: String) -> bool. Not valid: ResourceLoader.exists.
static var exists_check := Callable()


## M7: whether a music file is in the game now. In a browser the pieces and the universes' loops come in the music
## pack a little after the start (WebContent); the phone and desktop builds have every file from the start.
static func file_present(file_path: String) -> bool:
	if exists_check.is_valid():
		return bool(exists_check.call(file_path))
	return ResourceLoader.exists(file_path)


## A piece whose file is in the game now (MusicPlan chooses only these).
static func present(id: StringName) -> bool:
	return has(id) and file_present(path(id))


## Every piece is in (false in a browser until the music pack has come).
static func all_present() -> bool:
	for id: StringName in PIECES:
		if not present(id):
			return false
	return true


static func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in PIECES:
		out.append(id)
	return out


static func has(id: StringName) -> bool:
	return PIECES.has(id)


static func composer(id: StringName) -> String:
	return str(PIECES.get(id, {}).get("composer", ""))


static func title(id: StringName) -> String:
	return str(PIECES.get(id, {}).get("title", ""))


## "Mozart — Eine kleine Nachtmusik" ("" for an unknown id).
static func label(id: StringName) -> String:
	return "%s — %s" % [composer(id), title(id)] if has(id) else ""


static func path(id: StringName) -> String:
	return DIR + String(id) + ".ogg" if has(id) else ""


static func length(id: StringName) -> float:
	return float(PIECES.get(id, {}).get("length", 0.0))


static func moods(id: StringName) -> Array:
	return PIECES.get(id, {}).get("moods", [])


static func fits(id: StringName, mood: StringName) -> bool:
	return moods(id).has(mood)


## M5 Task 2: a universe's own piece (it plays only where it is a favourite: Frostpeak's winter, the kingdom's waltz).
static func is_own(id: StringName) -> bool:
	return bool(PIECES.get(id, {}).get("own", false))


static func for_mood(mood: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in PIECES:
		if fits(id, mood):
			out.append(id)
	return out
