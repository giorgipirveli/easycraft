extends GutTest
## Owner #110 (VR round 4, idea 7; ruling R12 of docs/devlog/parts/vr-ideas-research.md §7): the instruments' tones are
## our own, rendered by tools/make_instrument_tones.gd (no recording, no download): a wooden bar for each of the
## xylophone's eight notes, the bongos' two skins and their wooden shell. Each is a short mono sound at its note's pitch
## that starts without a click, rings and dies away, under the peak limit and credited as our own work.

const RATE := 32000


## The 16-bit mono samples of a WAV the tool wrote (its source file, as written), as floats -1..1; [] if it is not one.
func _samples(path: String) -> PackedFloat32Array:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return PackedFloat32Array()
	var bytes := f.get_buffer(f.get_length())
	if bytes.size() < 44 or bytes.slice(0, 4).get_string_from_ascii() != "RIFF":
		return PackedFloat32Array()
	assert_eq(bytes.decode_u16(20), 1, "%s: PCM" % path)
	assert_eq(bytes.decode_u16(22), 1, "%s: mono" % path)
	assert_eq(bytes.decode_u32(24), RATE, "%s: %d Hz" % [path, RATE])
	assert_eq(bytes.decode_u16(34), 16, "%s: 16 bits" % path)
	var out := PackedFloat32Array()
	var n := bytes.decode_u32(40) / 2
	out.resize(n)
	for i in n:
		out[i] = bytes.decode_s16(44 + i * 2) / 32768.0
	return out


## The pitch of `s` from `from` (samples), by autocorrelation between 120 Hz and 2 kHz.
func _pitch(s: PackedFloat32Array, from: int, length: int = 2048) -> float:
	var best := 0.0
	var best_lag := 0
	var scores := {}
	for lag in range(RATE / 2000, RATE / 120):
		var sum := 0.0
		for i in range(from, from + length):
			sum += s[i] * s[i + lag]
		scores[lag] = sum
		if sum > best:
			best = sum
			best_lag = lag
	# the first lag nearly as good as the best is the period (an octave's lag scores as well)
	for lag in range(RATE / 2000 + 1, best_lag):   # (a true peak: both neighbours scored, none higher)
		if float(scores[lag]) > 0.9 * best and float(scores[lag]) >= float(scores[lag - 1]) \
				and float(scores[lag]) >= float(scores[lag + 1]):
			best_lag = lag
			break
	var a := float(scores.get(best_lag - 1, 0.0))
	var b := float(scores[best_lag])
	var c := float(scores.get(best_lag + 1, 0.0))
	var shift := 0.5 * (a - c) / (a - 2.0 * b + c) if absf(a - 2.0 * b + c) > 1e-9 else 0.0
	return RATE / (best_lag + shift)


func _rms(s: PackedFloat32Array, from: int, to: int) -> float:
	var sum := 0.0
	for i in range(from, mini(to, s.size())):
		sum += s[i] * s[i]
	return sqrt(sum / maxf(float(mini(to, s.size()) - from), 1.0))


func test_every_voice_has_its_tone_and_the_game_can_load_it() -> void:
	for v in MusicBlockRules.VOICES:
		var path := MusicBlockRules.tone_file(v)
		assert_true(FileAccess.file_exists(path), path)
		var stream := load(path) as AudioStreamWAV
		assert_not_null(stream, "%s loads as a sound" % path)
		if stream:
			assert_between(stream.get_length(), 0.2, 1.6, "%s is short" % path)


func test_each_bar_rings_at_its_note() -> void:
	for v in MusicBlockRules.BARS:
		var s := _samples(MusicBlockRules.tone_file(v))
		assert_gt(s.size(), RATE / 2, "voice %d: half a second or more" % v)
		if s.size() < RATE / 2:
			continue
		var want := MusicBlockRules.frequency(v)
		var got := _pitch(s, RATE / 20)
		assert_almost_eq(got, want, want * 0.012, "bar %d (%s): %.1f Hz" % [v, MusicBlockRules.NOTES[v], got])


func test_the_low_skin_sounds_lower_than_the_high_one() -> void:
	var low := _pitch(_samples(MusicBlockRules.tone_file(MusicBlockRules.BONGO_LOW)), RATE / 25)
	var high := _pitch(_samples(MusicBlockRules.tone_file(MusicBlockRules.BONGO_HIGH)), RATE / 25)
	assert_almost_eq(low, MusicBlockRules.frequency(MusicBlockRules.BONGO_LOW), 25.0, "the big skin")
	assert_almost_eq(high, MusicBlockRules.frequency(MusicBlockRules.BONGO_HIGH), 35.0, "the small skin")
	assert_lt(low, high)


func test_every_tone_starts_without_a_click_rings_and_dies_away_under_the_peak_limit() -> void:
	for v in MusicBlockRules.VOICES:
		var path := MusicBlockRules.tone_file(v)
		var s := _samples(path)
		if s.is_empty():
			fail_test("%s: no samples" % path)
			continue
		var peak := 0.0
		for x in s:
			peak = maxf(peak, absf(x))
		assert_lte(peak, db_to_linear(-1.0), "%s: under -1 dBFS" % path)
		assert_gte(peak, db_to_linear(-3.0), "%s: rendered to one level, not quiet" % path)
		assert_lt(absf(s[0]), 0.01, "%s: starts at silence (no click)" % path)
		assert_lt(absf(s[s.size() - 1]), 0.01, "%s: ends at silence" % path)
		var start := _rms(s, 0, RATE / 20)
		var end := _rms(s, s.size() - RATE / 20, s.size())
		assert_lt(end, start * 0.05, "%s: it dies away" % path)
		assert_lt(FileAccess.get_file_as_bytes(path).size(), 110_000, "%s: small" % path)


func test_the_tones_are_credited_as_our_own_work() -> void:
	var credits := FileAccess.get_file_as_string("res://assets/CREDITS.md")
	assert_string_contains(credits, "tools/make_instrument_tones.gd")
	assert_string_contains(credits, "instrument_*.wav")
