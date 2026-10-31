class_name GlimmerModel
extends RefCounted
## Owner #133, #134 (docs/design/games/balance-altar.md §3.1, §3.8's table, ruling 19): the Glimmers, small crystal
## creatures asleep in the frozen crystals: blocky like the game's animals, made of glowing crystal (each kind its own
## pastel), with little crystal shards on the back. ASLEEP: curled up, eyes shut, small enough to sleep inside a 22 cm
## crystal; AWAKE: sitting up, bright eyes, beside its freed crystal. A Glimmer is never sad or in danger (§3.12): asleep
## means smiling-shut eyes. Drawn with AltarKit.glow (unshaded, the light baked in: a Glimmer gives light); the feet's
## middle at the origin, facing +Z. One mesh a kind and pose, cached.

const ASLEEP := "asleep"
const AWAKE := "awake"
## Each kind's crystal colour, its belly, its accent.
const LOOKS := {
	"fox": [Color("ffb27a"), Color("fff0dc"), Color("e0773f")],
	"bunny": [Color("ffb8d6"), Color("fff3f8"), Color("f48fb8")],
	"bird": [Color("b8a8ff"), Color("ece6ff"), Color("ffd27a")],
	"turtle": [Color("8fe3b0"), Color("e6fff0"), Color("45b27a")],
	"fish": [Color("7fd8f4"), Color("e6faff"), Color("ffb27a")],
	"cat": [Color("cfb0f5"), Color("f6efff"), Color("9a78d8")],
	"dragon": [Color("ffc58a"), Color("fff1dc"), Color("ff8f7a")],
}

static var _cache := {}


## A Glimmer's mesh (unknown kinds are a fox).
static func mesh(kind: String, pose: String) -> ArrayMesh:
	var key := "%s|%s" % [kind, pose]
	if not _cache.has(key):
		_cache[key] = _build(kind if LOOKS.has(kind) else "fox", pose)
	return _cache[key]


static func _build(kind: String, pose: String) -> ArrayMesh:
	var m := AltarKit.Mesher.new()
	var look: Array = LOOKS[kind]
	var body: Color = look[0]
	var belly: Color = look[1]
	var accent: Color = look[2]
	var asleep := pose == ASLEEP
	var boxes := _boxes(kind, asleep, body, belly, accent)
	for b: Array in boxes:
		var at: Vector3 = b[0]
		var size: Vector3 = b[1]
		var col: Color = b[2]
		var turn: Vector3 = b[3] if b.size() > 3 else Vector3.ZERO
		var basis := Basis.from_euler(turn)
		_lit_box(m, Transform3D(basis, at), size, col)
	return m.commit()


## A box whose faces carry the baked light (a Glimmer glows: the unshaded material).
static func _lit_box(m: AltarKit.Mesher, xf: Transform3D, size: Vector3, col: Color) -> void:
	var start := m.count()
	m.box(xf, size, col, col.lightened(0.18), 0.1)
	for k in range(start, m.count()):
		m.c[k] = AltarKit.shade(m.c[k], m.n[k], 0.78, 1.12)


## The creature as boxes [centre, size, colour, (turn)], about 0.07 tall asleep and 0.11 awake.
static func _boxes(kind: String, asleep: bool, body: Color, belly: Color, accent: Color) -> Array:
	var eye := Color("2a2440")
	var shine := Color("ffffff")
	var shard := body.lightened(0.45)
	var out: Array = []
	# The eyes: shut (smiling lines) asleep, bright awake.
	var eyes := func(y: float, z: float, gap: float) -> Array:
		if asleep:
			return [[Vector3(-gap, y, z), Vector3(0.012, 0.0035, 0.004), eye], [Vector3(gap, y, z), Vector3(0.012, 0.0035, 0.004), eye]]
		return [[Vector3(-gap, y, z), Vector3(0.011, 0.013, 0.004), eye], [Vector3(gap, y, z), Vector3(0.011, 0.013, 0.004), eye],
			[Vector3(-gap + 0.003, y + 0.003, z + 0.0025), Vector3(0.004, 0.004, 0.002), shine],
			[Vector3(gap + 0.003, y + 0.003, z + 0.0025), Vector3(0.004, 0.004, 0.002), shine]]
	match kind:
		"bird":
			if asleep:
				out += [[Vector3(0, 0.026, 0), Vector3(0.05, 0.044, 0.05), body], [Vector3(0, 0.024, 0.024), Vector3(0.036, 0.03, 0.006), belly],
					[Vector3(0, 0.052, 0.008), Vector3(0.036, 0.03, 0.034), body], [Vector3(0, 0.046, 0.03), Vector3(0.012, 0.008, 0.012), accent],
					[Vector3(-0.027, 0.03, -0.004), Vector3(0.008, 0.032, 0.04), body.darkened(0.12)],
					[Vector3(0.027, 0.03, -0.004), Vector3(0.008, 0.032, 0.04), body.darkened(0.12)],
					[Vector3(0, 0.02, -0.032), Vector3(0.026, 0.008, 0.02), body.darkened(0.1), Vector3(0.4, 0, 0)]]
				out += eyes.call(0.056, 0.026, 0.01)
			else:
				out += [[Vector3(0, 0.038, 0), Vector3(0.05, 0.05, 0.05), body], [Vector3(0, 0.034, 0.026), Vector3(0.036, 0.036, 0.004), belly],
					[Vector3(0, 0.08, 0.004), Vector3(0.042, 0.038, 0.04), body], [Vector3(0, 0.076, 0.03), Vector3(0.012, 0.009, 0.016), accent],
					[Vector3(-0.034, 0.05, 0), Vector3(0.01, 0.036, 0.04), body.darkened(0.1), Vector3(0, 0, 0.35)],
					[Vector3(0.034, 0.05, 0), Vector3(0.01, 0.036, 0.04), body.darkened(0.1), Vector3(0, 0, -0.35)],
					[Vector3(0, 0.03, -0.034), Vector3(0.028, 0.008, 0.024), body.darkened(0.1), Vector3(0.5, 0, 0)],
					[Vector3(-0.01, 0.007, 0.006), Vector3(0.006, 0.014, 0.006), accent], [Vector3(0.01, 0.007, 0.006), Vector3(0.006, 0.014, 0.006), accent],
					[Vector3(0, 0.103, 0), Vector3(0.008, 0.014, 0.008), shard, Vector3(0, 0.78, 0.6)]]
				out += eyes.call(0.088, 0.024, 0.011)
		"turtle":
			var h := 0.0 if asleep else 0.008
			out += [[Vector3(0, 0.024 + h, 0), Vector3(0.062, 0.03, 0.07), accent], [Vector3(0, 0.044 + h, 0), Vector3(0.048, 0.016, 0.054), body],
				[Vector3(0, 0.056 + h, 0), Vector3(0.028, 0.01, 0.032), shard],
				[Vector3(0, 0.012, 0), Vector3(0.056, 0.012, 0.062), belly]]
			for lx: float in [-0.028, 0.028]:
				for lz: float in [-0.024, 0.024]:
					out.append([Vector3(lx, 0.008 + h * 0.5, lz), Vector3(0.016, 0.014 + h, 0.016), body])
			if asleep:
				out += [[Vector3(0, 0.022, 0.04), Vector3(0.026, 0.02, 0.02), body]]
				out += eyes.call(0.026, 0.051, 0.007)
			else:
				out += [[Vector3(0, 0.05, 0.046), Vector3(0.03, 0.028, 0.03), body]]
				out += eyes.call(0.056, 0.062, 0.008)
		"fish":
			var y := 0.03 if asleep else 0.05
			out += [[Vector3(0, y, 0), Vector3(0.03, 0.044 if asleep else 0.05, 0.06), body],
				[Vector3(0, y - 0.004, 0.012), Vector3(0.032, 0.026, 0.03), belly],
				[Vector3(0, y, -0.04), Vector3(0.008, 0.036, 0.024), accent, Vector3(0.0, 0, 0)],
				[Vector3(0, y + 0.03, -0.004), Vector3(0.006, 0.016, 0.03), accent],
				[Vector3(-0.018, y - 0.01, 0.006), Vector3(0.004, 0.012, 0.018), accent, Vector3(0, 0, 0.5)],
				[Vector3(0.018, y - 0.01, 0.006), Vector3(0.004, 0.012, 0.018), accent, Vector3(0, 0, -0.5)]]
			if not asleep:
				out += [[Vector3(0, 0.012, 0), Vector3(0.024, 0.024, 0.024), shard]]   # a crystal pebble it floats over
			out += eyes.call(y + 0.008, 0.031, 0.012)
		_:
			# Four-legged: fox, bunny, cat, dragon.
			var ears: Array = []
			var tail: Array = []
			match kind:
				"bunny":
					ears = [[Vector3(-0.009, 0.0, 0.0), Vector3(0.01, 0.034, 0.008)], [Vector3(0.009, 0.0, 0.0), Vector3(0.01, 0.034, 0.008)]]
				"dragon":
					ears = [[Vector3(-0.011, 0.0, -0.004), Vector3(0.007, 0.016, 0.007)], [Vector3(0.011, 0.0, -0.004), Vector3(0.007, 0.016, 0.007)]]
				_:
					ears = [[Vector3(-0.012, 0.0, 0.0), Vector3(0.012, 0.014, 0.008)], [Vector3(0.012, 0.0, 0.0), Vector3(0.012, 0.014, 0.008)]]
			if asleep:
				# Curled up: the body a low round loaf, the head down on the paws, the tail wrapped round the front.
				out += [[Vector3(0, 0.022, -0.004), Vector3(0.052, 0.04, 0.05), body],
					[Vector3(0, 0.017, 0.016), Vector3(0.042, 0.026, 0.02), belly],
					[Vector3(0.008, 0.028, 0.024), Vector3(0.034, 0.03, 0.03), body],
					[Vector3(0.008, 0.022, 0.04), Vector3(0.016, 0.012, 0.01), belly]]
				for e: Array in ears:
					var ep: Vector3 = e[0]
					var es: Vector3 = e[1]
					var lay := Vector3(es.x, es.z, es.y) if kind == "bunny" else es
					out.append([Vector3(0.008, 0.046, 0.022) + Vector3(ep.x, 0, ep.z - (0.012 if kind == "bunny" else 0.0)), lay, accent if kind != "dragon" else shard])
				if kind == "bunny":
					out.append([Vector3(0, 0.03, -0.03), Vector3(0.02, 0.02, 0.016), belly])
				else:
					out.append([Vector3(-0.022, 0.012, 0.03), Vector3(0.034, 0.014, 0.016), accent if kind == "fox" else body, Vector3(0, -0.5, 0)])
					if kind == "fox":
						out.append([Vector3(-0.004, 0.012, 0.04), Vector3(0.014, 0.012, 0.012), belly])
				if kind == "dragon":
					out.append([Vector3(-0.026, 0.04, -0.004), Vector3(0.006, 0.02, 0.03), shard, Vector3(0, 0, 0.6)])
					out.append([Vector3(0.026, 0.04, -0.004), Vector3(0.006, 0.02, 0.03), shard, Vector3(0, 0, -0.6)])
				out.append([Vector3(-0.006, 0.046, -0.012), Vector3(0.01, 0.014, 0.01), shard, Vector3(0, 0.78, 0.6)])
				out += eyes.call(0.031, 0.04, 0.008).map(func(b: Array) -> Array:
					return [(b[0] as Vector3) + Vector3(0.008, 0, 0), b[1], b[2]])
			else:
				# Sitting up: haunches, a chest, the head, ears, a tail curled round the side.
				out += [[Vector3(0, 0.022, -0.008), Vector3(0.046, 0.044, 0.044), body],
					[Vector3(0, 0.05, 0.004), Vector3(0.036, 0.04, 0.032), body],
					[Vector3(0, 0.046, 0.019), Vector3(0.026, 0.032, 0.006), belly],
					[Vector3(0, 0.086, 0.008), Vector3(0.044, 0.038, 0.038), body],
					[Vector3(0, 0.077, 0.03), Vector3(0.02, 0.016, 0.012), belly],
					[Vector3(0, 0.081, 0.037), Vector3(0.007, 0.006, 0.004), eye],
					[Vector3(-0.011, 0.008, 0.022), Vector3(0.012, 0.016, 0.014), body],
					[Vector3(0.011, 0.008, 0.022), Vector3(0.012, 0.016, 0.014), body]]
				for e: Array in ears:
					var ep: Vector3 = e[0]
					var es: Vector3 = e[1]
					out.append([Vector3(0, 0.112 + es.y * 0.5, 0.006) + ep, es, accent if kind != "dragon" else shard])
				if kind == "bunny":
					out.append([Vector3(0, 0.02, -0.034), Vector3(0.02, 0.02, 0.016), belly])
				else:
					out.append([Vector3(0.03, 0.016, 0.006), Vector3(0.014, 0.014, 0.05), accent if kind == "fox" else body, Vector3(0, -0.3, 0)])
					if kind == "fox":
						out.append([Vector3(0.036, 0.016, 0.03), Vector3(0.014, 0.014, 0.012), belly])
				if kind == "dragon":
					out.append([Vector3(-0.032, 0.066, -0.012), Vector3(0.006, 0.03, 0.036), shard, Vector3(0.3, 0, 0.5)])
					out.append([Vector3(0.032, 0.066, -0.012), Vector3(0.006, 0.03, 0.036), shard, Vector3(0.3, 0, -0.5)])
				out.append([Vector3(0, 0.07, -0.024), Vector3(0.012, 0.016, 0.012), shard, Vector3(0, 0.78, 0.6)])
				out.append([Vector3(0, 0.044, -0.032), Vector3(0.01, 0.014, 0.01), shard, Vector3(0, 0.78, 0.6)])
				out += eyes.call(0.092, 0.027, 0.011)
	return out
