class_name Loudness
extends RefCounted
## The loudness balance across universes (M5 Task 2, spec §15.2). What tools/measure_loudness.py measured, as
## [full-band LUFS, LUFS through a phone speaker (two 500 Hz high-passes), true peak dBTP] per file (EBU R128, the way
## owner #50 measured the animals; docs/devlog/parts/m5-task-2.md has the run), and the gains that even it out:
## - every universe's day and night loop as loud as Green Meadows' (the mean of the full-band and the phone
##   difference: a loop heavy in bass sounds louder on headphones than on a phone), the boss loop left as it is
##   (every universe's);
## - every piece as loud as the loop it takes turns with in MIX (Green Meadows' day loop; a boss piece: the boss loop);
## - every universe's day and night ambience as loud as the birds (by day) and the crickets (at night); the sea and
##   the caves are the same in every universe and stay as they were;
## - the monsters' idle voices as loud as the goblins' grunts through a phone (like #50's animals; boosts at most
##   VOICE_BOOST).
## No gain lifts a file past PEAK_LIMIT (so a quiet piano piece stays a little quiet); a difference under MIN_STEP is
## left alone. Re-run the tool and copy its numbers here when a file changes.

const PEAK_LIMIT := -1.0          # dBTP a gain may reach
const MIN_STEP := 1.0             # dB: closer than this, nothing changes
const MAX_BOOST := 3.0            # music: at most this up (and never past PEAK_LIMIT)
const MAX_CUT := 12.0
const AMBIENCE_BOOST := 12.0      # ambience: up to its file's own level (the loops play well under it)
const VOICE_BOOST := 3.0

## Music loops by file name: [full LUFS, phone LUFS, peak dBTP].
const MUSIC := {
	"day.ogg": [-16.1, -24.5, -3.3], "night.ogg": [-17.0, -24.9, -2.5], "boss.ogg": [-15.4, -19.3, -4.2],
	"desert_day.ogg": [-17.7, -24.4, -0.9], "desert_night.ogg": [-18.2, -23.4, -1.0],
	"frost_day.ogg": [-21.8, -25.9, -1.5], "frost_night.ogg": [-16.0, -21.1, -1.0],
	"candy_day.ogg": [-14.9, -16.1, -2.3], "candy_night.ogg": [-15.7, -22.8, -3.4],
}
## Which Green Meadows loop each universe's loop is evened out against.
const MUSIC_REF := {
	"desert_day.ogg": "day.ogg", "desert_night.ogg": "night.ogg", "frost_day.ogg": "day.ogg",
	"frost_night.ogg": "night.ogg", "candy_day.ogg": "day.ogg", "candy_night.ogg": "night.ogg",
}
## The classical pieces (MusicPieces ids).
const PIECES := {
	&"air": [-18.2, -22.3, -4.8], &"bumblebee": [-20.3, -24.1, -1.1], &"figaro": [-18.0, -20.7, -1.9],
	&"fur_elise": [-23.1, -25.9, -1.1], &"goldberg_aria": [-21.2, -26.3, -2.8], &"gymnopedie": [-21.1, -24.4, -1.6],
	&"minute_waltz": [-21.1, -25.1, -2.2], &"moonlight": [-21.6, -29.3, -1.3], &"morning_mood": [-18.3, -20.7, -1.0],
	&"mountain_king": [-15.4, -18.1, -2.2], &"nachtmusik": [-17.7, -21.0, -4.0], &"ode_to_joy": [-18.1, -20.8, -0.8],
	&"snow_dancing": [-25.6, -29.4, -0.9], &"spring": [-18.5, -20.2, -0.8], &"symphony_40": [-17.6, -19.9, -2.3],
	&"waltz_flowers": [-23.2, -27.0, -0.7], &"winter_largo": [-17.6, -19.2, -2.0],
}
## The ambience loops (AmbienceSoundRules.LOOPS ids), as recorded (before the loop's own volume).
const AMBIENCE := {
	&"birds": [-22.0, -22.0, -5.0], &"crickets": [-22.0, -22.7, -10.5], &"wind": [-25.2, -30.4, -8.9],
	&"waves": [-25.3, -28.5, -2.9], &"drips": [-37.5, -38.7, -2.9], &"snow_wind": [-24.5, -27.2, -11.6],
	&"snow_night": [-25.1, -27.3, -10.6], &"chimes": [-29.2, -29.3, -2.7], &"brook": [-22.3, -22.7, -7.8],
}
## Which loop each universe's own ambience is evened out against (by day the birds, at night the crickets).
const AMBIENCE_REF := {&"wind": &"birds", &"snow_wind": &"birds", &"chimes": &"birds", &"snow_night": &"crickets",
	&"brook": &"crickets"}
## The monsters' idle voices (VoiceRules.monster_idle; the goblin: the mean of its three grunts).
const VOICES := {
	&"slime": [-9.2, -24.1, -1.9], &"goblin": [-16.5, -20.2, -2.8], &"mummy": [-11.6, -25.7, -2.5],
	&"scorpion": [-28.4, -28.4, -2.5], &"yeti": [-13.4, -20.3, -1.9], &"bat": [-10.8, -10.8, -6.0],
	&"gummy": [-12.6, -19.5, -4.4], &"sneaker": [-15.5, -15.5, -5.0], &"archer": [-15.6, -22.7, -1.8],
	&"shadow_bat": [-27.2, -30.2, -6.8], &"wisp": [-18.2, -27.9, -8.0],
	&"spore_puff": [-19.5, -28.4, -6.9], &"crawler": [-31.9, -31.9, -7.8],   # universe 6: the Glow Caves
}


## How much louder `ref` is than `m` ([full, phone, peak] each): the mean of the full-band and the phone difference.
static func balance_gap(m: Array, ref: Array) -> float:
	return ((float(ref[0]) - float(m[0])) + (float(ref[1]) - float(m[1]))) * 0.5


## The most a gain may add to `m` before its peak passes PEAK_LIMIT (negative: it is past it already).
static func headroom(m: Array) -> float:
	return PEAK_LIMIT - float(m[2])


## A gain for a `gap`: nothing for a small one, at most `room` (and `boost`) up, at most MAX_CUT down.
static func _gain(gap: float, room: float, boost: float = MAX_BOOST) -> float:
	var g := clampf(gap, -MAX_CUT, minf(boost, room))
	return 0.0 if absf(gap) < MIN_STEP or absf(g) < MIN_STEP else g


## The gain of the music loop at `path` (0 for Green Meadows' own, the boss loop and anything not measured).
static func music_gain_db(path: String) -> float:
	var f := path.get_file()
	if not MUSIC_REF.has(f) or not MUSIC.has(f):
		return 0.0
	var m: Array = MUSIC[f]
	return _gain(balance_gap(m, MUSIC[MUSIC_REF[f]]), headroom(m))


## The gain of the classical piece `id`.
static func piece_gain_db(id: StringName) -> float:
	if not PIECES.has(id):
		return 0.0
	var m: Array = PIECES[id]
	var ref: Array = MUSIC["boss.ogg" if MusicPieces.fits(id, MusicPieces.BOSS) else "day.ogg"]
	return _gain(balance_gap(m, ref), headroom(m))


## How much louder `ref_id` plays than `id` (each at its AmbienceSoundRules.LOOPS volume, before any gain).
static func ambience_gap(id: StringName, ref_id: StringName) -> float:
	var m: Array = AMBIENCE[id]
	var r: Array = AMBIENCE[ref_id]
	var base := float(AmbienceSoundRules.LOOPS.get(id, 0.0))
	var ref_base := float(AmbienceSoundRules.LOOPS.get(ref_id, 0.0))
	return balance_gap([float(m[0]) + base, float(m[1]) + base, m[2]], [float(r[0]) + ref_base, float(r[1]) + ref_base, r[2]])


## The gain on top of an ambience loop's own volume; never louder than its file, never past PEAK_LIMIT.
static func ambience_gain_db(id: StringName) -> float:
	if not AMBIENCE_REF.has(id) or not AMBIENCE.has(id):
		return 0.0
	var base := float(AmbienceSoundRules.LOOPS.get(id, 0.0))
	var room := minf(headroom(AMBIENCE[id]) - base, -base)
	return _gain(ambience_gap(id, AMBIENCE_REF[id]), room, AMBIENCE_BOOST)


## The gain of a monster kind's idle voice (through a phone, towards the goblins' grunts).
static func voice_gain_db(kind: StringName) -> float:
	if not VOICES.has(kind):
		return 0.0
	var m: Array = VOICES[kind]
	return _gain(float(VOICES[&"goblin"][1]) - float(m[1]), headroom(m), VOICE_BOOST)
