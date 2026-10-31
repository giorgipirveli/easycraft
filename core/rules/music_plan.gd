class_name MusicPlan
extends RefCounted
## What music plays, as pure state (owner feedback #31: "musics i like, please also add some clasical
## musics like bethhoven, mozart and etc."). The MUSIC setting has three styles:
## - GAME: the game's own loops (M2 §12.10: calm day, tense night, boss theme; caves get the night's
##   Crystal Cave loop).
## - CLASSICAL: only classical pieces (MusicPieces) that fit the mood, a breath of REST between two.
## - MIX (the default): by day classical pieces take turns with the game's day loop (MIX_LOOP_TIME of the
##   loop, then a piece); the sunrise plays Morning Mood; night, caves and boss fights keep the game's loops,
##   whose moods tell a child what is going on. The menu plays gentle pieces.
## A mood change keeps a piece that fits the new mood (no cut in the middle of it). Pieces are chosen least
## heard first, never the one that just played, the universe's own favourites first among equals.
## M7: only pieces whose file is in the game now (MusicPieces.present): in a browser they come in the music pack a
## little after the start. Until then the mood's own loop stands in wherever a piece would play (no silence), and
## after MIX_LOOP_TIME of it the chooser tries a piece again (the loop is never cut).
## Music (the autoload) cross-fades whatever `cue` names.

const GAME := &"game"
const CLASSICAL := &"classical"
const MIX := &"mix"
const STYLES: Array[StringName] = [GAME, CLASSICAL, MIX]

const MENU := MusicPieces.MENU
const MORNING := MusicPieces.MORNING
const DAY := MusicPieces.DAY
const NIGHT := MusicPieces.NIGHT
const BOSS := MusicPieces.BOSS
const UNDERGROUND := MusicPieces.UNDERGROUND
const MOODS: Array[StringName] = [MENU, MORNING, DAY, NIGHT, BOSS, UNDERGROUND]

const MORNING_END := 0.3          # the morning: sunrise until 0.3 (a new world starts at 0.3, in the day)
const MIX_LOOP_TIME := 150.0      # MIX by day: seconds of the game's loop between two pieces
const REST := 2.0                 # CLASSICAL: seconds of silence between two pieces (never in a boss fight)

var style: StringName = MIX
## The universe's own pieces (UniverseRegistry.classical), played first among the least heard.
var favourites: Array[StringName] = []
## What plays now: a MusicRules track, a MusicPieces id, or &"" (silence).
var cue: StringName = &""
var mood: StringName = &""
var elapsed := 0.0                # seconds of the current cue (or rest)

var _resting := false
var _dirty := false               # the style changed: choose again on the next update
var _last_piece: StringName = &""
var _heard := {}                  # piece -> times started
var _rng := RandomNumberGenerator.new()


## seed_value < 0: a random order every game.
func _init(seed_value: int = -1) -> void:
	if seed_value < 0:
		_rng.randomize()
	else:
		_rng.seed = seed_value


static func valid_style(s: Variant) -> StringName:
	var n := StringName(str(s))
	return n if STYLES.has(n) else MIX


static func mood_for(time_of_day: float, boss: bool, underground: bool) -> StringName:
	if boss:
		return BOSS
	if underground:
		return UNDERGROUND
	if DayCycle.is_night(time_of_day):
		return NIGHT
	var t := DayCycle.wrap_time(time_of_day)
	return MORNING if t >= DayCycle.SUNRISE and t < MORNING_END else DAY


## The game's own loop for a mood (&"" for none).
static func game_track(m: StringName) -> StringName:
	match m:
		&"":
			return &""
		BOSS:
			return MusicRules.BOSS
		NIGHT, UNDERGROUND:
			return MusicRules.NIGHT
	return MusicRules.DAY


func set_style(s: Variant) -> void:
	var n := valid_style(s)
	if n != style:
		style = n
		_dirty = true


## `delta` seconds passed in `new_mood` (&"" = silence). True when the cue changed.
func update(new_mood: StringName, delta: float) -> bool:
	var before := cue
	elapsed += delta if is_finite(delta) and delta > 0.0 else 0.0
	if new_mood != mood or _dirty:
		mood = new_mood
		_dirty = false
		if not _fits(cue, mood):
			_start(_first())
	else:
		_advance()
	return cue != before


## Owner #40's /music next: the next piece that fits the mood starts now, if this style plays pieces in it.
## False (nothing changes) in the game's own music.
func skip() -> bool:
	if mood == &"" or style == GAME or not (style == CLASSICAL or _mix_plays_pieces(mood)):
		return false
	var next := _next_piece()
	if not MusicPieces.has(next) or next == cue:
		return false
	_start(next)
	return true


func _fits(c: StringName, m: StringName) -> bool:
	if c == &"" or m == &"":
		return false
	if MusicPieces.has(c):
		if style == GAME or not MusicPieces.fits(c, m) or (MusicPieces.is_own(c) and not favourites.has(c)):
			return false
		return style == CLASSICAL or _mix_plays_pieces(m)
	if style == CLASSICAL or (style == MIX and m == MENU):
		return false
	return c == game_track(m)


func _mix_plays_pieces(m: StringName) -> bool:
	return m == MENU or m == MORNING or m == DAY


func _first() -> StringName:
	if mood == &"":
		return &""
	match style:
		GAME:
			return game_track(mood)
		CLASSICAL:
			return _next_piece()
	return _next_piece() if mood == MENU or mood == MORNING else game_track(mood)


func _advance() -> void:
	if _resting:
		if elapsed >= REST:
			_start(_next_piece())
	elif MusicPieces.has(cue):
		if elapsed >= MusicPieces.length(cue):
			_after_piece()
	elif cue != &"" and elapsed >= MIX_LOOP_TIME and (style == CLASSICAL or (style == MIX and _mix_plays_pieces(mood))):
		_start(_next_piece())   # the loop's turn is over (or it stood in for pieces not in yet, M7): a piece


func _after_piece() -> void:
	if style == MIX and mood != MENU:
		_start(game_track(mood))   # by day the game's loop takes its turn again
	elif mood == BOSS:
		_start(_next_piece())
	else:
		cue = &""
		_resting = true
		elapsed = 0.0


func _start(c: StringName) -> void:
	cue = c
	elapsed = 0.0
	_resting = false
	if MusicPieces.has(c):
		_last_piece = c
		_heard[c] = int(_heard.get(c, 0)) + 1


## The least heard piece that fits the mood, never the one that just played; the mood's own first piece
## (the sunrise's Morning Mood) and then the universe's favourites win among equals.
func _next_piece() -> StringName:
	var fitting := MusicPieces.for_mood(mood).filter(func(id: StringName) -> bool:
		return not MusicPieces.is_own(id) or favourites.has(id))   # M5 Task 2: a universe's own piece plays there only
	if fitting.is_empty():
		return game_track(mood) if style != CLASSICAL else &""
	fitting = fitting.filter(func(id: StringName) -> bool: return MusicPieces.present(id))   # M7: the music pack
	if fitting.is_empty():
		return game_track(mood)   # M7: not in yet: the mood's own loop stands in (never silence)
	var first: StringName = MusicPieces.FIRST.get(mood, &"")
	if first != &"" and first != _last_piece and fitting.has(first):
		return first
	if fitting.size() > 1:
		fitting.erase(_last_piece)
	var least := INF
	for id: StringName in fitting:
		least = minf(least, float(_heard.get(id, 0)))
	var pool: Array[StringName] = []
	for id: StringName in fitting:
		if float(_heard.get(id, 0)) == least:
			pool.append(id)
	var favs := pool.filter(func(id: StringName) -> bool: return favourites.has(id))
	if not favs.is_empty():
		return favs[_rng.randi() % favs.size()]
	return pool[_rng.randi() % pool.size()]
