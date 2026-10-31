class_name StudioParticles
extends RefCounted
## The Reel Studio (owner #96, spec §5.12b): simple particles a 3D stage can show (an engine's flame, smoke, dust blown
## off the ground, a launch's white billows, sparkles, steam, snow), every one a pure function of the time: particle i
## of an effect is born again every `life` seconds at its own phase, its randoms from (i, its birth's number), so a seek
## shows the frame playing reaches (a CPUParticles3D could not). A flame is local to its engine (it rides with the
## rocket); smoke and dust stay where they were made (the world's frame: the smoke a climbing rocket leaves behind).
## Drawn by ui/shorts/actors/scene3d_effects.gd as one multimesh of little boxes (the game's own particle looks: the
## flame, billows and sparkles the golem's glow, the rest Fx's). fill() writes a multimesh's buffer directly (a phone's
## frame: no array per particle); its randoms come from one table and its anchors are kept per 60th of a second.

## The effects' looks: amount, life (s), speed [min, max] (m/s), spread (degrees round `dir`), gravity (m/s², + up),
## drag (share of speed lost a second), size [born, dying] (m), colours over a life, local (rides with its anchor),
## glow (unshaded, bright), dir (in the anchor's frame), jitter (m round the anchor), ring (out sideways all round),
## twinkle.
const LOOKS := {
	"flame": {"amount": 80, "life": 0.5, "speed": [18.0, 30.0], "spread": 6.0, "gravity": 0.0, "drag": 0.0,
		"size": [1.1, 0.35], "colors": [Color(1.0, 0.98, 0.82), Color(1.0, 0.8, 0.32), Color(1.0, 0.46, 0.12),
		Color(0.7, 0.16, 0.06)], "local": true, "glow": true, "dir": [0, -1, 0], "jitter": 0.55},
	"smoke": {"amount": 60, "life": 4.0, "speed": [5.0, 11.0], "spread": 40.0, "gravity": 1.2, "drag": 0.8,
		"size": [1.6, 6.5], "colors": [Color(1.0, 0.97, 0.92), Color(0.92, 0.92, 0.94), Color(0.8, 0.8, 0.84)],
		"local": false, "glow": false, "dir": [0, -1, 0], "jitter": 1.0},
	"dust": {"amount": 70, "life": 1.8, "speed": [7.0, 15.0], "spread": 90.0, "gravity": -0.8, "drag": 1.4,
		"size": [0.5, 1.6], "colors": [Color(0.9, 0.88, 0.84), Color(0.78, 0.76, 0.72)], "local": false, "glow": false,
		"dir": [0, 0.15, 0], "jitter": 1.2, "ring": true},
	"billow": {"amount": 110, "life": 3.2, "speed": [4.0, 10.0], "spread": 90.0, "gravity": 0.15, "drag": 1.1,
		"size": [0.5, 1.7], "colors": [Color(1.0, 1.0, 1.0), Color(0.96, 0.96, 0.97), Color(0.86, 0.87, 0.9)],
		"local": false, "glow": true, "dir": [0, 0.06, 0], "jitter": 1.4, "ring": true},
	"sparkles": {"amount": 40, "life": 1.4, "speed": [0.3, 1.4], "spread": 180.0, "gravity": 0.3, "drag": 0.5,
		"size": [0.28, 0.0], "colors": [Color(1.0, 0.97, 0.7), Color(1.0, 0.84, 0.3)], "local": false, "glow": true,
		"dir": [0, 1, 0], "jitter": 2.0, "twinkle": true},
	"steam": {"amount": 36, "life": 2.6, "speed": [1.2, 2.6], "spread": 18.0, "gravity": 0.6, "drag": 0.4,
		"size": [0.5, 2.4], "colors": [Color(1, 1, 1), Color(0.93, 0.95, 0.98)], "local": false, "glow": false,
		"dir": [0, 1, 0], "jitter": 0.6},
	"snow": {"amount": 80, "life": 6.0, "speed": [0.4, 1.0], "spread": 30.0, "gravity": -0.5, "drag": 0.0,
		"size": [0.14, 0.14], "colors": [Color(1, 1, 1)], "local": false, "glow": true, "dir": [0, -1, 0],
		"jitter": 18.0},
	# Round 2 (learning reels): rain falling from a cloud in long upright streaks over a wide flat patch (flat: no
	# height to its jitter), and a volcano's lava fountain: glowing blobs thrown up that gravity pulls back down.
	"rain": {"amount": 180, "life": 1.1, "speed": [13.0, 17.0], "spread": 3.0, "gravity": 0.0, "drag": 0.0,
		"size": [0.07, 0.07], "colors": [Color(0.72, 0.84, 1.0), Color(0.62, 0.78, 1.0)], "local": false, "glow": false,
		"dir": [0, -1, 0], "jitter": 4.0, "flat": true, "upright": true, "stretch": 7.0},
	"lava": {"amount": 90, "life": 1.9, "speed": [7.0, 12.0], "spread": 20.0, "gravity": -9.8, "drag": 0.15,
		"size": [0.6, 0.3], "colors": [Color(1.0, 0.95, 0.6), Color(1.0, 0.62, 0.16), Color(0.92, 0.26, 0.06),
		Color(0.4, 0.09, 0.04)], "local": false, "glow": true, "dir": [0, 1, 0], "jitter": 0.5},
}
const SEED := 7919
## Floats a particle takes in a multimesh buffer (TRANSFORM_3D with colours and custom data: CPUParticles3D's layout).
const STRIDE := 20
const TABLE_ROWS := 997          # a prime: (i, k) spread over it
const RANDOMS := 8
const ANCHOR_RATE := 60.0        # an anchor at a birth is kept per 60th of a second

static var _table := PackedFloat32Array()
static var _turns: Array[Basis] = []   # each slot's own tilt (a box never lines up with its neighbours)


static func look(effect: Dictionary) -> Dictionary:
	return LOOKS.get(str(effect.get("kind", "")), LOOKS.sparkles)


## How many particles the effect keeps (its `amount`, else its look's).
static func amount(effect: Dictionary) -> int:
	return clampi(int(StudioRules.num(effect, "amount", float(look(effect).amount))), 1, 400)


## Seconds a particle lives.
static func life(effect: Dictionary) -> float:
	return maxf(StudioRules.num(effect, "life", float(look(effect).life)), 0.05)


## True when the particles ride with their anchor.
static func is_local(effect: Dictionary) -> bool:
	return bool(effect.get("local", look(effect).local))


## The particles alive at `t`: [[pos (Vector3: the anchor's frame when local, else the world's), size, colour], ...].
## `anchor(t) -> Transform3D`: where the effect comes from at a moment (its model's engine, the ground's middle).
static func alive(effect: Dictionary, t: float, anchor: Callable) -> Array:
	var buf := PackedFloat32Array()
	buf.resize(amount(effect) * STRIDE)
	var n := fill(effect, t, anchor, buf, {})
	var out: Array = []
	for k in n:
		var o := k * STRIDE
		out.append([Vector3(buf[o + 3], buf[o + 7], buf[o + 11]), buf[o + 19], Color(buf[o + 12], buf[o + 13], buf[o + 14],
			buf[o + 15])])
	return out


## Writes the particles alive at `t` into `buf` (a multimesh's buffer: STRIDE floats each, the first ones; the custom
## data's last float holds the size) and returns how many. `anchors`: a cache of anchor transforms by 60ths of a second
## (kept by the caller: the anchor is a pure function of the time).
static func fill(effect: Dictionary, t: float, anchor: Callable, buf: PackedFloat32Array, anchors: Dictionary) -> int:
	if _table.is_empty():
		_make_table()
	var lk := look(effect)
	var n := amount(effect)
	var lf := life(effect)
	var from := StudioRules.num(effect, "from", 0.0)
	var to := StudioRules.num(effect, "to", 1e9)
	if t < from or t > to + lf:
		return 0
	var scale := StudioRules.num(effect, "size", 1.0)
	var local := is_local(effect)
	var tint := ShortRules.colour(effect.get("color"), Color.WHITE) if effect.has("color") else Color.WHITE
	var lift := StudioRules.vec(effect.get("dir", lk.dir))   # a ring's lift (how far up its way tips), else its way
	var dir := lift.normalized()
	var side := dir.cross(Vector3.RIGHT if absf(dir.x) < 0.9 else Vector3.FORWARD).normalized()
	var speeds: Array = lk.speed
	var fast := StudioRules.num(effect, "speed", 1.0)   # an effect's own speed (its size leaves it alone)
	var s0 := float(speeds[0]) * scale * fast
	var s1 := float(speeds[1]) * scale * fast
	var sizes: Array = lk.size
	var z0 := float(sizes[0]) * scale
	var z1 := float(sizes[1]) * scale
	var colours: Array = lk.colors
	var spread := deg_to_rad(float(lk.spread))
	var gravity := StudioRules.num(effect, "gravity", float(lk.gravity))   # round 2: an effect's own (Io's weak pull)
	var drag := float(lk.drag)
	var jitter := float(lk.jitter) * scale * 2.0
	var ring := bool(lk.get("ring", false))
	var twinkle := bool(lk.get("twinkle", false))
	var flat := bool(lk.get("flat", false))
	var upright := bool(lk.get("upright", false))
	var stretch := float(lk.get("stretch", 1.0))
	# Round 2: an effect's own `area` [x, z] (m): born anywhere on that flat patch (vapour off a whole sea).
	var area := Vector2.ZERO
	var spec: Variant = effect.get("area")
	if spec is Array and (spec as Array).size() == 2:
		area = Vector2(float(spec[0]), float(spec[1]))
	var count := 0
	for i in n:
		var phase := lf * float(i) / n
		var k := floori((t - from - phase) / lf)
		if k < 0:
			continue
		var born := from + phase + k * lf
		if born > to:
			k = floori((to - from - phase) / lf)
			if k < 0:
				continue
			born = from + phase + k * lf
		var age := t - born
		if age < 0.0 or age >= lf:
			continue
		var r := ((i * 31 + k * 7919 + SEED) % TABLE_ROWS) * RANDOMS
		var way: Vector3
		if ring:
			var a := _table[r] * TAU
			way = (Vector3(cos(a), 0.0, sin(a)) + lift).normalized()
		else:
			way = dir.rotated(side.rotated(dir, _table[r] * TAU), sqrt(_table[r + 1]) * spread)
		var speed := lerpf(s0, s1, _table[r + 2])
		var travel := speed * age if drag <= 0.0 else speed * (1.0 - exp(-drag * age)) / drag
		var offset := Vector3(_table[r + 3] - 0.5, 0.0 if flat else _table[r + 4] - 0.5, _table[r + 5] - 0.5) * jitter
		if area != Vector2.ZERO:
			offset.x = (_table[r + 3] - 0.5) * area.x
			offset.z = (_table[r + 5] - 0.5) * area.y
		var pos := way * travel + offset
		if not local:
			var at := _anchor(anchor, born, anchors)
			pos = at.origin + at.basis * pos
		pos.y += 0.5 * gravity * age * age
		var f := age / lf
		var size := lerpf(z0, z1, f) * lerpf(0.75, 1.25, _table[r + 6])
		if twinkle:
			size *= 0.55 + 0.45 * sin(age * 9.0 + _table[r + 7] * TAU)
		size = maxf(size, 0.0001)
		var c := _ramp(colours, f) * tint
		var turn: Basis = Basis.from_scale(Vector3(1.0, stretch, 1.0)) if upright else _turns[(i + k) % _turns.size()]
		var o := count * STRIDE
		buf[o] = turn.x.x * size
		buf[o + 1] = turn.y.x * size
		buf[o + 2] = turn.z.x * size
		buf[o + 3] = pos.x
		buf[o + 4] = turn.x.y * size
		buf[o + 5] = turn.y.y * size
		buf[o + 6] = turn.z.y * size
		buf[o + 7] = pos.y
		buf[o + 8] = turn.x.z * size
		buf[o + 9] = turn.y.z * size
		buf[o + 10] = turn.z.z * size
		buf[o + 11] = pos.z
		buf[o + 12] = c.r
		buf[o + 13] = c.g
		buf[o + 14] = c.b
		buf[o + 15] = c.a
		buf[o + 16] = 0.0
		buf[o + 17] = 0.0
		buf[o + 18] = 0.0
		buf[o + 19] = size
		count += 1
	return count


## The anchor at a birth, kept per 60th of a second (orthonormal: a scaled rocket's frame does not stretch its smoke).
static func _anchor(anchor: Callable, born: float, cache: Dictionary) -> Transform3D:
	var key := roundi(born * ANCHOR_RATE)
	if not cache.has(key):
		var at: Transform3D = anchor.call(key / ANCHOR_RATE)
		cache[key] = Transform3D(at.basis.orthonormalized(), at.origin)
	return cache[key]


static func _ramp(colours: Array, f: float) -> Color:
	if colours.size() == 1:
		return colours[0]
	var x := clampf(f, 0.0, 1.0) * (colours.size() - 1)
	var i := mini(floori(x), colours.size() - 2)
	return (colours[i] as Color).lerp(colours[i + 1], x - i)


static func _make_table() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = SEED
	_table.resize(TABLE_ROWS * RANDOMS)
	for j in _table.size():
		_table[j] = rng.randf()
	for j in 64:
		_turns.append(Basis.from_euler(Vector3(rng.randf() * TAU, rng.randf() * TAU, rng.randf() * TAU)))
