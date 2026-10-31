class_name GadgetModels
extends RefCounted
## The action kit's models (M3 Task 14a): each is ONE merged, vertex-coloured mesh with WeaponModels' one
## shared material, built from boxes once and cached (no material or mesh is ever made per use).
## - glider canopies (one per look, GadgetRules.GLIDER_LOOKS) that open over a player's head;
## - held gadgets (grip at the origin, pointing along -Z, like WeaponModels' held items);
## - a unit rope and a unit cable (1 m along -Z, stretched by their node's scale), the hook's head,
##   a zipline post's pole and wheel, the rider's handle, and the thrown orbs.

const ROPE := Color("b0875a")
const CABLE := Color("3a3f4a")
const METAL := Color("c3cbd4")
const METAL_DARK := Color("5f6b78")
const WOOD := Color("9a6a3a")
const PLANK := Color("d9a066")
const PLANK_DARK := Color("a86f3a")
const BOING := Color("56c8ff")
const BOING_DARK := Color("1f5fa8")
const DANCE := Color("ff7ad9")
const DANCE_DARK := Color("8a2f8f")
const WHITE := Color("ffffff")
const YELLOW := Color("ffd23f")
## Each look's two stripe colours and its frame colour.
const LOOK_COLORS := {
	&"classic": [Color("e8403a"), Color("ffd23f"), Color("2b2f3a")],
	&"sky": [Color("3d8bff"), Color("f2f7ff"), Color("24406e")],
	&"sunset": [Color("ff8a1c"), Color("9a4dff"), Color("3a2358")],
}

static var _cache := {}


static func _cached(key: Variant, parts: Callable) -> Mesh:
	if not _cache.has(key):
		_cache[key] = WeaponModels.build(parts.call())
	return _cache[key]


## The open glider over a player (its feet at the origin, facing -Z), in look `look` (GLIDER_LOOKS index).
static func canopy(look: int) -> Mesh:
	var name: StringName = GadgetRules.GLIDER_LOOKS[GadgetRules.glider_look(look)]
	return _cached([&"canopy", name], func() -> Array:
		var c: Array = LOOK_COLORS[name]
		var parts: Array = []
		var panels := [[0.0, 2.6, 0.0, 0.9], [-0.86, 2.5, 0.22, 0.9], [0.86, 2.5, -0.22, 0.9],
			[-1.62, 2.24, 0.45, 0.7], [1.62, 2.24, -0.45, 0.7]]
		for i in panels.size():
			var p: Array = panels[i]
			parts.append([Vector3(p[0], p[1], 0.0), Vector3(p[3], 0.07, 1.1), c[0] if i % 2 == 0 else c[1],
				Basis(Vector3.BACK, p[2])])
		parts.append([Vector3(0, 2.66, 0.0), Vector3(3.4, 0.05, 0.12), c[2]])   # the spar along the front edge
		for s: float in [-1.0, 1.0]:                                              # struts down to the hands
			parts.append([Vector3(0.62 * s, 2.05, 0.0), Vector3(0.05, 1.1, 0.05), c[2], Basis(Vector3.BACK, 0.42 * s)])
		parts.append([Vector3(0, 1.55, -0.05), Vector3(0.9, 0.06, 0.06), c[2]])   # the bar the hands hold
		return parts)


## A gadget in the hand, or null.
static func held(id: int) -> Mesh:
	if not GadgetRules.is_gadget(id):
		return null
	return _cached([&"held", id], func() -> Array: return _held_parts(id))


static func _held_parts(id: int) -> Array:
	match id:
		ItemIds.GLIDER:        # folded up: a striped bundle on a stick
			return [[Vector3(0, 0, -0.18), Vector3(0.05, 0.05, 0.5), WOOD],
				[Vector3(0, 0.04, -0.3), Vector3(0.14, 0.12, 0.3), Color("e8403a")],
				[Vector3(0, 0.04, -0.3), Vector3(0.15, 0.04, 0.31), YELLOW]]
		ItemIds.GRAPPLE:       # a launcher with a three-pronged hook in front and a coil of rope
			return [[Vector3(0, 0.02, -0.12), Vector3(0.1, 0.12, 0.32), METAL_DARK],
				[Vector3(0, 0.02, -0.3), Vector3(0.03, 0.03, 0.1), METAL],
				[Vector3(0, 0.02, -0.36), Vector3(0.18, 0.03, 0.03), METAL],
				[Vector3(0, 0.09, -0.36), Vector3(0.03, 0.12, 0.03), METAL],
				[Vector3(0, 0.1, -0.04), Vector3(0.12, 0.08, 0.1), ROPE]]
		ItemIds.IMPULSE_ORB:
			return _ball(Vector3(0, 0.06, -0.1), 0.22, BOING, BOING_DARK, WHITE)
		ItemIds.DANCE_ORB:
			return _ball(Vector3(0, 0.06, -0.1), 0.22, DANCE, DANCE_DARK, YELLOW)
		ItemIds.BUILD_WALL:    # a little planks panel standing up
			return [[Vector3(0, 0.12, -0.12), Vector3(0.26, 0.3, 0.04), PLANK],
				[Vector3(0, 0.12, -0.1), Vector3(0.27, 0.02, 0.03), PLANK_DARK]]
		ItemIds.BUILD_FLOOR:   # a little flat square
			return [[Vector3(0, 0.02, -0.14), Vector3(0.28, 0.04, 0.28), PLANK],
				[Vector3(0, 0.04, -0.14), Vector3(0.29, 0.02, 0.02), PLANK_DARK]]
		ItemIds.BUILD_RAMP:    # three little steps
			return [[Vector3(0, 0.02, -0.06), Vector3(0.24, 0.05, 0.09), PLANK],
				[Vector3(0, 0.07, -0.15), Vector3(0.24, 0.05, 0.09), PLANK_DARK],
				[Vector3(0, 0.12, -0.24), Vector3(0.24, 0.05, 0.09), PLANK]]
		ItemIds.BUILD_FORT:    # a little tower with battlements
			return [[Vector3(0, 0.1, -0.14), Vector3(0.22, 0.22, 0.22), PLANK],
				[Vector3(-0.07, 0.24, -0.07), Vector3(0.07, 0.06, 0.07), PLANK_DARK],
				[Vector3(0.07, 0.24, -0.21), Vector3(0.07, 0.06, 0.07), PLANK_DARK],
				[Vector3(0, 0.05, -0.03), Vector3(0.07, 0.1, 0.02), PLANK_DARK]]
	return []


## A round-ish ball of three crossed boxes, with a band and a spot.
static func _ball(c: Vector3, r: float, main: Color, dark: Color, mark: Color) -> Array:
	return [[c, Vector3(r, r * 0.8, r * 0.8), main], [c, Vector3(r * 0.8, r, r * 0.8), main],
		[c, Vector3(r * 0.8, r * 0.8, r), dark], [c, Vector3(r * 1.02, r * 0.18, r * 0.82), mark],
		[c + Vector3(-r * 0.2, r * 0.35, -r * 0.2), Vector3(r * 0.2, r * 0.2, r * 0.2), mark]]


## A thrown orb (its middle at the origin, about 0.35 m across).
static func orb(id: int) -> Mesh:
	return _cached([&"orb", id], func() -> Array:
		return _ball(Vector3.ZERO, 0.36, BOING if id == ItemIds.IMPULSE_ORB else DANCE,
			BOING_DARK if id == ItemIds.IMPULSE_ORB else DANCE_DARK, WHITE if id == ItemIds.IMPULSE_ORB else YELLOW))


## 1 m of rope (or cable) along -Z from the origin: a node stretches it with scale.z.
static func rope() -> Mesh:
	return _cached(&"rope", func() -> Array: return [[Vector3(0, 0, -0.5), Vector3(0.05, 0.05, 1.0), ROPE]])


static func cable() -> Mesh:
	return _cached(&"cable", func() -> Array: return [[Vector3(0, 0, -0.5), Vector3(0.06, 0.06, 1.0), CABLE]])


## The hook's head where it holds.
static func hook_head() -> Mesh:
	return _cached(&"hook_head", func() -> Array:
		return [[Vector3.ZERO, Vector3(0.14, 0.14, 0.14), METAL_DARK], [Vector3(0, 0.1, 0), Vector3(0.3, 0.04, 0.04), METAL],
			[Vector3(0, 0.1, 0), Vector3(0.04, 0.04, 0.3), METAL]])


## A zipline post's pole: from the post block's top (the origin) up to the line (ZIP_ATTACH), with its wheel.
static func pole() -> Mesh:
	return _cached(&"pole", func() -> Array:
		var h := GadgetRules.ZIP_ATTACH
		return [[Vector3(0, h * 0.5, 0), Vector3(0.14, h, 0.14), WOOD],
			[Vector3(0, h * 0.5 + 0.3, 0), Vector3(0.16, 0.12, 0.16), YELLOW],
			[Vector3(0, h, 0), Vector3(0.1, 0.36, 0.36), METAL], [Vector3(0, h, 0), Vector3(0.12, 0.12, 0.12), METAL_DARK]])


## The handle a zipline rider holds (feet at the origin; the wheel runs on the line ZIP_HANG up).
static func handle() -> Mesh:
	return _cached(&"handle", func() -> Array:
		var h := GadgetRules.ZIP_HANG
		return [[Vector3(0, h - 0.3, 0), Vector3(0.75, 0.07, 0.07), METAL_DARK],
			[Vector3(0, h - 0.13, 0), Vector3(0.07, 0.34, 0.07), METAL],
			[Vector3(0, h, 0), Vector3(0.1, 0.3, 0.3), METAL]])


## How many meshes are cached (tests: none is made per use).
static func cached_count() -> int:
	return _cache.size()
