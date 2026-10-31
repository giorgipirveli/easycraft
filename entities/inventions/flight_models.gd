class_name FlightModels
extends RefCounted
## Owner #78 (spec §21e): the flying machines the child invents, in our own look (spec §3c: bright, blocky, friendly;
## never a real maker's plane): each is ONE merged, vertex-coloured mesh with WeaponModels' one shared material, built
## from boxes and discs once and cached (like GadgetModels). The rider's feet are at the origin and it faces -Z.
## - the kite: a diamond of two colours on its cross sticks with a tail of bows (it flies on its string, downwind);
## - the hot-air balloon: a round striped bag of stacked slices over a wicker basket the child stands in, ropes, the
##   burner (its flame is its own small mesh, shown while the air is heated);
## - the plane: a 1903-style biplane (two cloth wings on struts, the elevator in front, the rudder behind, two pusher
##   propellers, their own spinning discs);
## - the jet: a white body round the child's legs, swept wings, a tail fin, a windscreen, the exhaust's glow.

const CLOTH := Color("f3ead2")
const CLOTH_SHADE := Color("dccfae")
const WOOD := Color("9a6a3a")
const WICKER := Color("b88a4e")
const WICKER_DARK := Color("8a6232")
const ROPE := Color("c9a878")
const IRON := Color("4a4f5a")
const TEAL := Color("1fb5a8")      # the brand's teal band (spec §3c)
const RED := Color("e8403a")
const YELLOW := Color("ffd23f")
const WHITE := Color("f6f8fb")
const GREY := Color("aab4c0")
const GLASS := Color("9fd8ff")
const FLAME := Color("ffb02e")
const FLAME_HOT := Color("fff1a8")

const BALLOON_CENTER := 7.4   # the bag's middle, above the feet
const BALLOON_RADIUS := 3.0
const KITE_SIZE := 1.6   # a big kite reads well from the ground (real ones are about 1 m)

static var _cache := {}


static func _cached(key: StringName, parts: Callable) -> Mesh:
	if not _cache.has(key):
		_cache[key] = WeaponModels.build(parts.call())
	return _cache[key]


static func kite() -> Mesh:
	return _cached(&"kite", func() -> Array:
		var s := KITE_SIZE
		var parts: Array = []
		var turn := Basis(Vector3.BACK, PI / 4.0)   # a square turned into a diamond, in the XY plane, facing -Z
		for i in 4:   # four panels, two colours across
			var q := Vector3(-0.25 if i % 2 == 0 else 0.25, 0.25 if i < 2 else -0.25, 0.0) * s
			parts.append([turn * q, Vector3(0.5, 0.5, 0.04) * s, RED if (i == 0 or i == 3) else YELLOW, turn])
		parts.append([Vector3.ZERO, Vector3(0.05, s * 1.45, 0.07), WOOD])            # the spine
		parts.append([Vector3(0, s * 0.18, 0), Vector3(s * 1.1, 0.05, 0.07), WOOD])   # the spar
		for k in 5:   # the tail of bows
			var y := -s * 0.8 - k * 0.32
			parts.append([Vector3(sin(k * 1.3) * 0.08, y, 0.02), Vector3(0.03, 0.28, 0.03), ROPE])
			parts.append([Vector3(sin(k * 1.3) * 0.08, y - 0.14, 0.02), Vector3(0.22, 0.09, 0.04), TEAL if k % 2 == 0 else RED])
		return parts)


static func balloon() -> Mesh:
	return _cached(&"balloon", func() -> Array:
		var parts: Array = []
		var r := BALLOON_RADIUS
		var layers := 9
		for i in layers:   # the bag: slices of a sphere, bands of colour
			var dy := -r + (i + 0.5) * (2.0 * r / layers)
			var w := 2.0 * sqrt(maxf(r * r - dy * dy, 0.0)) + 0.4
			var colour: Color = [RED, YELLOW, RED, TEAL, WHITE, TEAL, RED, YELLOW, RED][i]
			parts.append([Vector3(0, BALLOON_CENTER + dy, 0), Vector3(w, 2.0 * r / layers + 0.02, w), colour])
			if i > 0 and i < layers - 1:   # stripes down the bag's sides
				for side: Vector3 in [Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 0, -1)]:
					var at := side * (w * 0.5 + 0.01) + Vector3(0, BALLOON_CENTER + dy, 0)
					var size := Vector3(0.04, 2.0 * r / layers + 0.02, 0.5) if side.x != 0.0 \
						else Vector3(0.5, 2.0 * r / layers + 0.02, 0.04)
					parts.append([at, size, YELLOW if colour == RED else RED])
		parts.append([Vector3(0, BALLOON_CENTER - r - 0.35, 0), Vector3(1.3, 0.7, 1.3), RED])   # the mouth
		for x: float in [-0.62, 0.62]:   # the ropes down to the basket's corners
			for z: float in [-0.62, 0.62]:
				parts.append([Vector3(x, 2.95, z), Vector3(0.04, 2.9, 0.04), ROPE])
		parts.append([Vector3(0, 3.1, 0), Vector3(0.5, 0.35, 0.5), IRON])   # the burner
		parts.append([Vector3(0, 0.02, 0), Vector3(1.4, 0.08, 1.4), WICKER_DARK])   # the basket: floor and four walls
		for side: float in [-1.0, 1.0]:
			parts.append([Vector3(0.66 * side, 0.5, 0), Vector3(0.1, 1.0, 1.42), WICKER])
			parts.append([Vector3(0, 0.5, 0.66 * side), Vector3(1.42, 1.0, 0.1), WICKER])
			parts.append([Vector3(0, 0.98, 0.66 * side), Vector3(1.46, 0.08, 0.14), WICKER_DARK])   # the rim
			parts.append([Vector3(0.66 * side, 0.98, 0), Vector3(0.14, 0.08, 1.46), WICKER_DARK])
		return parts)


static func balloon_flame() -> Mesh:
	return _cached(&"balloon_flame", func() -> Array:
		return [[Vector3(0, 3.55, 0), Vector3(0.34, 0.6, 0.34), FLAME], [Vector3(0, 3.9, 0), Vector3(0.18, 0.5, 0.18),
			FLAME_HOT]])


static func plane() -> Mesh:
	return _cached(&"plane", func() -> Array:
		var parts: Array = []
		for y: float in [0.55, 2.35]:   # the two wings: cloth over wooden ribs
			parts.append([Vector3(0, y, 0), Vector3(7.2, 0.08, 1.3), CLOTH])
			for x: float in [-3.0, -1.5, 1.5, 3.0]:
				parts.append([Vector3(x, y + 0.05, 0), Vector3(0.06, 0.04, 1.32), CLOTH_SHADE])
			parts.append([Vector3(0, y, -0.66), Vector3(7.24, 0.1, 0.06), WOOD])   # the front edge
		for x: float in [-3.4, -2.2, -0.7, 0.7, 2.2, 3.4]:   # the struts between them
			for z: float in [-0.55, 0.55]:
				parts.append([Vector3(x, 1.45, z), Vector3(0.06, 1.8, 0.06), TEAL if absf(x) > 3.0 else WOOD])
		parts.append([Vector3(0, 1.1, -2.3), Vector3(2.2, 0.06, 0.6), CLOTH])   # the elevator, in front
		for x: float in [-0.5, 0.5]:
			parts.append([Vector3(x, 0.8, -1.5), Vector3(0.05, 0.05, 1.6), WOOD])   # its booms
		parts.append([Vector3(0, 1.45, 2.4), Vector3(0.06, 1.2, 0.7), CLOTH])   # the rudder, behind
		for x: float in [-0.4, 0.4]:
			parts.append([Vector3(x, 1.45, 1.6), Vector3(0.05, 0.05, 1.6), WOOD])
		parts.append([Vector3(0.9, 0.85, 0.15), Vector3(0.45, 0.4, 0.55), IRON])   # the little engine, beside the pilot
		for x: float in [-1.4, 1.4]:   # the propellers' shafts
			parts.append([Vector3(x, 1.45, 0.55), Vector3(0.08, 0.08, 0.5), IRON])
		for x: float in [-1.6, 1.6]:   # the skids it lands on
			parts.append([Vector3(x, 0.08, -0.4), Vector3(0.08, 0.08, 2.6), WOOD])
		return parts)


## One propeller: a disc spun round its axis (-Z), for the plane's two.
static func propeller() -> Mesh:
	return _cached(&"propeller", func() -> Array:
		return [[Vector3.ZERO, Vector3(1.9, 0.14, 0.05), WOOD], [Vector3.ZERO, Vector3(0.16, 0.16, 0.12), IRON]])


static func jet() -> Mesh:
	return _cached(&"jet", func() -> Array:
		var parts: Array = []
		parts.append([Vector3(0, 0.5, 0.2), Vector3(1.1, 0.9, 4.6), WHITE])   # the body round the legs
		parts.append([Vector3(0, 0.5, -2.35), Vector3(0.8, 0.7, 0.6), WHITE])   # the nose, narrowing
		parts.append([Vector3(0, 0.5, -2.85), Vector3(0.45, 0.4, 0.5), RED])
		parts.append([Vector3(0, 0.96, 0.2), Vector3(1.12, 0.06, 4.62), TEAL])   # the brand's band along the top
		parts.append([Vector3(0, 1.25, -0.75), Vector3(0.95, 0.5, 0.06), GLASS, Basis(Vector3.RIGHT, -0.5)])   # windscreen
		for side: float in [-1.0, 1.0]:   # swept wings and the tail's little wings
			parts.append([Vector3(1.55 * side, 0.4, 0.55), Vector3(2.4, 0.1, 1.2), GREY, Basis(Vector3.UP, 0.45 * side)])
			parts.append([Vector3(2.55 * side, 0.4, 1.05), Vector3(0.3, 0.14, 0.6), RED, Basis(Vector3.UP, 0.45 * side)])
			parts.append([Vector3(0.75 * side, 0.55, 2.3), Vector3(0.9, 0.08, 0.6), GREY, Basis(Vector3.UP, 0.4 * side)])
			parts.append([Vector3(0.62 * side, 0.55, -0.6), Vector3(0.16, 0.5, 0.9), IRON])   # the air intakes
		parts.append([Vector3(0, 1.35, 2.2), Vector3(0.1, 1.2, 0.9), RED, Basis(Vector3.RIGHT, 0.35)])   # the tail fin
		parts.append([Vector3(0, 0.5, 2.6), Vector3(0.7, 0.6, 0.2), IRON])   # the exhaust
		return parts)


static func jet_glow() -> Mesh:
	return _cached(&"jet_glow", func() -> Array:
		return [[Vector3(0, 0.5, 2.85), Vector3(0.5, 0.42, 0.35), FLAME], [Vector3(0, 0.5, 3.15), Vector3(0.28, 0.24, 0.3),
			FLAME_HOT]])
