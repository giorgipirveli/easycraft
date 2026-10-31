extends SceneTree
## Renders the music blocks' tones (owner #110, VR round 4 idea 7; ruling R12: our own work, no recording, no download):
## assets/audio/sfx/instrument_*.wav (MusicBlockRules.tone_file), mono 16-bit PCM at 32 kHz, deterministic (each voice
## has its own seed). Imported as QOA (compress/mode=2) like the build notes.
## - The xylophone's eight bars (C5-C6): a struck wooden bar, its overtones tuned as a xylophone's are (the first a
##   twelfth up, three times the note), the note ringing longest, the overtones dying fast, a soft knock of the mallet.
## - The bongos' two skins (MusicBlockRules.DRUM_HZ): a struck membrane, its modes at a drum's ratios (1, 1.59, 2.14,
##   2.30, 2.65), the pitch dropping a little as the skin settles, a slap of noise; the small skin shorter and higher.
## - The drum's wooden shell: a woodblock's click.
## Every tone starts from silence (a 2 ms rise), ends at silence (a 40 ms fade) and is brought to one peak (PEAK).
## Run: godot --headless --path . --script res://tools/make_instrument_tones.gd   (then godot --headless --path . --import)

const RATE := 32000
const PEAK := 0.84   # -1.5 dBFS
const XYLO_SECONDS := 1.1
const BONGO_SECONDS := 0.7
const SHELL_SECONDS := 0.3


func _init() -> void:
	for v in MusicBlockRules.VOICES:
		var s: PackedFloat32Array
		if v < MusicBlockRules.BARS:
			s = _bar(MusicBlockRules.frequency(v), v)
		elif v == MusicBlockRules.SHELL:
			s = _shell(MusicBlockRules.frequency(v), v)
		else:
			s = _skin(MusicBlockRules.frequency(v), v, v == MusicBlockRules.BONGO_HIGH)
		_finish(s)
		var path := MusicBlockRules.tone_file(v)
		var err := _write_wav(path, s)
		print("INSTRUMENT_TONE %s %.1f Hz %.2f s err=%d" % [path.get_file(), MusicBlockRules.frequency(v),
			s.size() / float(RATE), err])
	quit()


## A struck wooden bar at `hz`.
func _bar(hz: float, voice: int) -> PackedFloat32Array:
	var n := int(XYLO_SECONDS * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	# [ratio, amplitude, decay seconds]: the note, its tuned twelfth, a faint higher one
	var partials := [[1.0, 1.0, 0.32], [3.0, 0.32, 0.09], [6.1, 0.07, 0.03]]
	var short := lerpf(1.0, 0.75, voice / 7.0)   # a higher bar is shorter: it rings a little less
	for i in n:
		var t := float(i) / RATE
		var x := 0.0
		for p: Array in partials:
			var f := hz * float(p[0])
			if f >= RATE * 0.45:
				continue
			x += float(p[1]) * exp(-t / (float(p[2]) * short)) * sin(TAU * f * t)
		out[i] = x
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261016 + voice
	_knock(out, rng, 0.004, 0.18, 0.35)
	return out


## A struck skin at `hz`; the small one (`small`) rings shorter.
func _skin(hz: float, voice: int, small: bool) -> PackedFloat32Array:
	var n := int(BONGO_SECONDS * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var modes := [[1.0, 1.0], [1.59, 0.45], [2.14, 0.3], [2.30, 0.22], [2.65, 0.15]]
	var tau := 0.11 if small else 0.16
	var phase := []
	phase.resize(modes.size())
	phase.fill(0.0)
	for i in n:
		var t := float(i) / RATE
		var glide := 1.0 + 0.06 * exp(-t / 0.03)   # the skin settles: its pitch drops a little
		var x := 0.0
		for m in modes.size():
			var mode: Array = modes[m]
			phase[m] = float(phase[m]) + TAU * hz * float(mode[0]) * glide / RATE
			x += float(mode[1]) * exp(-t * (1.0 + m * 0.8) / tau) * sin(float(phase[m]))
		out[i] = x
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261016 + voice
	_knock(out, rng, 0.006, 0.35, 0.5)
	return out


## A woodblock's click at `hz`.
func _shell(hz: float, voice: int) -> PackedFloat32Array:
	var n := int(SHELL_SECONDS * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var partials := [[1.0, 1.0, 0.035], [2.42, 0.5, 0.02], [3.9, 0.25, 0.012]]
	for i in n:
		var t := float(i) / RATE
		var x := 0.0
		for p: Array in partials:
			x += float(p[1]) * exp(-t / float(p[2])) * sin(TAU * hz * float(p[0]) * t)
		out[i] = x
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261016 + voice
	_knock(out, rng, 0.003, 0.5, 0.3)
	return out


## The mallet's knock: `seconds` of noise, smoothed (a one-pole low-pass, `smooth` 0..1), `level` loud, dying fast.
func _knock(out: PackedFloat32Array, rng: RandomNumberGenerator, seconds: float, smooth: float, level: float) -> void:
	var n := int(seconds * RATE)
	var y := 0.0
	for i in mini(n, out.size()):
		y = lerpf(rng.randf_range(-1.0, 1.0), y, smooth)
		out[i] += level * y * (1.0 - float(i) / n)


## From silence (a 2 ms rise) to silence (a 40 ms fade), at one peak.
func _finish(s: PackedFloat32Array) -> void:
	var rise := int(0.002 * RATE)
	var fade := int(0.04 * RATE)
	for i in s.size():
		var g := 1.0
		if i < rise:
			g = float(i) / rise
		if i >= s.size() - fade:
			g *= float(s.size() - 1 - i) / fade
		s[i] *= g
	var peak := 0.0
	for x in s:
		peak = maxf(peak, absf(x))
	if peak > 0.0:
		for i in s.size():
			s[i] *= PEAK / peak


## A 16-bit mono PCM WAV (RIFF) at RATE.
func _write_wav(path: String, s: PackedFloat32Array) -> int:
	var data := PackedByteArray()
	data.resize(s.size() * 2)
	for i in s.size():
		data.encode_s16(i * 2, clampi(roundi(s[i] * 32767.0), -32768, 32767))
	var head := PackedByteArray()
	head.resize(44)
	head.encode_u32(0, 0x46464952)        # "RIFF"
	head.encode_u32(4, 36 + data.size())
	head.encode_u32(8, 0x45564157)        # "WAVE"
	head.encode_u32(12, 0x20746d66)       # "fmt "
	head.encode_u32(16, 16)
	head.encode_u16(20, 1)                # PCM
	head.encode_u16(22, 1)                # mono
	head.encode_u32(24, RATE)
	head.encode_u32(28, RATE * 2)
	head.encode_u16(32, 2)
	head.encode_u16(34, 16)
	head.encode_u32(36, 0x61746164)       # "data"
	head.encode_u32(40, data.size())
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return FileAccess.get_open_error()
	f.store_buffer(head)
	f.store_buffer(data)
	f.close()
	return OK
