class_name CarModels
extends RefCounted
## Owner #109 (spec §3b "Cars"): the cars' looks, our own blocky designs (no brands, no real makes). Each is ONE merged,
## vertex-coloured mesh per kind and colour with WeaponModels' one shared material, built from boxes once and cached
## (nothing is made per car); its wheels are one mesh per kind (a tyre, a rim and a hub, spun by their nodes; a wheel's
## face looks along -Z: a car's wheel nodes turn it to face outwards), the sky taxi's rotor one mesh. Origin: the car's
## feet (the middle of its bottom); its front looks along -Z. The open cars (go-kart, off-roader, race car, monster truck,
## hover car) show their riders; the bus, the pickup's cab and the sky taxi have open windows, so friends see each other
## inside. parts() is the same boxes for the garage's picture.

const TRIM := Color("2b2f3a")
const TYRE := Color("26282e")
const RIM := Color("c3cbd4")
const METAL := Color("9aa6b2")
const SEAT := Color("4a4038")
const LIGHT := Color("fff3b0")
const TAIL := Color("ff4a3d")
const WHITE := Color("f4f6f8")
const GLOW := Color("7ff7ff")
const STRIPE := Color("ffd23f")

static var _cache := {}


static func _cached(key: Variant, parts: Callable) -> Mesh:
	if not _cache.has(key):
		_cache[key] = WeaponModels.build(parts.call())
	return _cache[key]


## The body of a car of `kind` in colour `colour` (CarKinds.colour_index), without its wheels.
static func body(kind: StringName, colour: int) -> Mesh:
	if not CarKinds.exists(kind):
		return null
	var c := CarKinds.colour_index(colour)
	return _cached([&"body", kind, c], func() -> Array: return parts(kind, c))


## One wheel of `kind` (null for a hover car): its face along -Z, its middle at the origin.
static func wheel(kind: StringName) -> Mesh:
	var r := CarKinds.wheel_radius(kind)
	if r <= 0.0:
		return null
	var thick := clampf(r * 0.7, 0.14, 0.7)
	return _cached([&"wheel", kind], func() -> Array:
		return [{"center": Vector3.ZERO, "thickness": thick, "back": TYRE,
			"rings": [[0.0, r * 0.22, TRIM], [r * 0.22, r * 0.6, RIM], [r * 0.6, r, TYRE]]}])


## The sky taxi's rotor: two crossed blades round a hub, spun round Y by its node.
static func rotor() -> Mesh:
	return _cached(&"rotor", func() -> Array:
		return [[Vector3.ZERO, Vector3(1.1, 0.03, 0.12), TRIM], [Vector3.ZERO, Vector3(0.12, 0.03, 1.1), TRIM],
			[Vector3(0, 0.03, 0), Vector3(0.16, 0.06, 0.16), METAL]])


## Where the sky taxi's rotors turn (its feet's space).
static func rotor_spots(kind: StringName) -> Array[Vector3]:
	if kind != CarKinds.SKY_TAXI:
		return []
	return [Vector3(-1.3, 1.98, -1.45), Vector3(1.3, 1.98, -1.45), Vector3(-1.3, 1.98, 1.45), Vector3(1.3, 1.98, 1.45)]


## Its headlights' middles (tests; the front of every car).
static func headlights(kind: StringName) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for p: Variant in parts(kind, 0):
		if p is Array and p[2] == LIGHT:
			out.append(p[0])
	return out


## How many meshes are cached (tests: none is made per car).
static func cached_count() -> int:
	return _cache.size()


## The boxes of a car's body: [centre, size, colour] (and a basis), in its feet's space.
static func parts(kind: StringName, colour: int) -> Array:
	var c := CarKinds.colour_of(kind, colour)
	var dark := c.darkened(0.35)
	match kind:
		CarKinds.GO_KART:
			return _kart(c, dark)
		CarKinds.OFF_ROADER:
			return _off_roader(c, dark)
		CarKinds.RACE_CAR:
			return _race_car(c, dark)
		CarKinds.PICKUP:
			return _pickup(c, dark)
		CarKinds.BUS:
			return _bus(c, dark)
		CarKinds.MONSTER_TRUCK:
			return _monster_truck(c, dark)
		CarKinds.HOVER_CAR:
			return _hover_car(c, dark)
		CarKinds.SKY_TAXI:
			return _sky_taxi(c, dark)
	return []


## Two lights at the front (`z`), `x` apart from the middle, at height `y`; two tail lights at the back.
static func _lights(x: float, y: float, z: float, back_z: float, s := 0.16) -> Array:
	return [[Vector3(-x, y, z), Vector3(s * 1.4, s, 0.06), LIGHT], [Vector3(x, y, z), Vector3(s * 1.4, s, 0.06), LIGHT],
		[Vector3(-x, y, back_z), Vector3(s * 1.4, s * 0.8, 0.06), TAIL],
		[Vector3(x, y, back_z), Vector3(s * 1.4, s * 0.8, 0.06), TAIL]]


static func _kart(c: Color, dark: Color) -> Array:
	var p: Array = [
		[Vector3(0, 0.18, 0), Vector3(1.0, 0.08, 1.8), TRIM],                      # the frame
		[Vector3(0, 0.26, -0.86), Vector3(1.1, 0.16, 0.24), c],                    # the nose
		[Vector3(-0.45, 0.3, 0.05), Vector3(0.22, 0.2, 0.9), c],                   # side pods
		[Vector3(0.45, 0.3, 0.05), Vector3(0.22, 0.2, 0.9), c],
		[Vector3(0, 0.27, 0.22), Vector3(0.5, 0.1, 0.42), SEAT],                   # the seat
		[Vector3(0, 0.5, 0.45), Vector3(0.5, 0.5, 0.1), SEAT],
		[Vector3(0.24, 0.38, 0.74), Vector3(0.36, 0.32, 0.3), METAL],              # the engine behind the seat
		[Vector3(-0.2, 0.33, 0.82), Vector3(0.12, 0.12, 0.3), TRIM],               # its exhaust
		[Vector3(0, 0.45, -0.38), Vector3(0.06, 0.06, 0.42), TRIM, Basis(Vector3.RIGHT, 0.7)],   # the steering column
		[Vector3(0, 0.58, -0.22), Vector3(0.34, 0.3, 0.05), TRIM, Basis(Vector3.RIGHT, 0.7)],    # the wheel
		[Vector3(0, 0.25, 0.96), Vector3(1.2, 0.12, 0.08), dark],                  # the back bumper
	]
	p.append_array(_lights(0.32, 0.28, -0.99, 0.99, 0.1))
	return p


static func _off_roader(c: Color, dark: Color) -> Array:
	var p: Array = [
		[Vector3(0, 0.75, 0), Vector3(1.9, 0.5, 3.2), c],                          # the tub
		[Vector3(0, 1.08, -1.05), Vector3(1.8, 0.18, 1.1), c],                     # the bonnet
		[Vector3(0, 1.08, -1.62), Vector3(1.6, 0.14, 0.04), TRIM],                 # the grille's bar
		[Vector3(-0.97, 0.95, -1.15), Vector3(0.12, 0.12, 1.0), dark],             # wheel arches
		[Vector3(0.97, 0.95, -1.15), Vector3(0.12, 0.12, 1.0), dark],
		[Vector3(-0.97, 0.95, 1.15), Vector3(0.12, 0.12, 1.0), dark],
		[Vector3(0.97, 0.95, 1.15), Vector3(0.12, 0.12, 1.0), dark],
		[Vector3(0, 1.4, -0.52), Vector3(1.8, 0.5, 0.06), Color("9ad7ff")],        # the windscreen
		[Vector3(-0.88, 1.4, -0.52), Vector3(0.08, 0.56, 0.08), TRIM],
		[Vector3(0.88, 1.4, -0.52), Vector3(0.08, 0.56, 0.08), TRIM],
		[Vector3(0, 1.72, 0.4), Vector3(1.8, 0.08, 0.08), TRIM],                   # the roll bar
		[Vector3(-0.88, 1.36, 0.4), Vector3(0.08, 0.72, 0.08), TRIM],
		[Vector3(0.88, 1.36, 0.4), Vector3(0.08, 0.72, 0.08), TRIM],
		[Vector3(-0.45, 1.12, -0.05), Vector3(0.6, 0.12, 0.5), SEAT],              # front seats
		[Vector3(0.45, 1.12, -0.05), Vector3(0.6, 0.12, 0.5), SEAT],
		[Vector3(0, 1.15, 0.95), Vector3(1.6, 0.12, 0.6), SEAT],                   # the back bench
		[Vector3(0, 0.55, -1.66), Vector3(2.0, 0.22, 0.12), TRIM],                 # bumpers
		[Vector3(0, 0.55, 1.66), Vector3(2.0, 0.22, 0.12), TRIM],
		{"center": Vector3(0, 1.1, 1.72), "thickness": 0.22, "back": TYRE,          # the spare tyre on the back
			"rings": [[0.0, 0.12, TRIM], [0.12, 0.26, RIM], [0.26, 0.4, TYRE]]},
	]
	p.append_array(_lights(0.62, 0.95, -1.66, 1.62))
	return p


static func _race_car(c: Color, dark: Color) -> Array:
	var p: Array = [
		[Vector3(0, 0.42, 0.1), Vector3(1.0, 0.32, 3.2), c],                       # the body
		[Vector3(0, 0.36, -1.6), Vector3(0.6, 0.2, 0.6), c],                       # the nose
		[Vector3(-0.62, 0.4, 0.25), Vector3(0.42, 0.3, 1.4), c],                   # side pods
		[Vector3(0.62, 0.4, 0.25), Vector3(0.42, 0.3, 1.4), c],
		[Vector3(0, 0.6, 0.95), Vector3(0.5, 0.26, 1.0), c],                       # the engine cover
		[Vector3(0, 0.6, -0.4), Vector3(0.24, 0.02, 2.0), WHITE],                  # a racing stripe
		[Vector3(0, 0.44, 0.32), Vector3(0.5, 0.18, 0.6), SEAT],                   # the cockpit
		[Vector3(0, 0.66, -0.06), Vector3(0.5, 0.12, 0.06), TRIM],                 # its little screen
		[Vector3(0, 0.16, -1.86), Vector3(1.9, 0.06, 0.08), dark],                 # the front wing
		[Vector3(0, 0.2, -1.8), Vector3(1.9, 0.04, 0.2), dark],
		[Vector3(0, 0.9, 1.72), Vector3(1.7, 0.08, 0.34), c],                      # the back wing
		[Vector3(-0.8, 0.82, 1.72), Vector3(0.06, 0.28, 0.34), dark],
		[Vector3(0.8, 0.82, 1.72), Vector3(0.06, 0.28, 0.34), dark],
		[Vector3(0, 0.66, 1.62), Vector3(0.1, 0.3, 0.12), TRIM],                   # the wing's post
	]
	p.append_array(_lights(0.22, 0.38, -1.91, 1.86, 0.1))
	return p


static func _pickup(c: Color, dark: Color) -> Array:
	var glass := Color("9ad7ff")
	var p: Array = [
		[Vector3(0, 0.72, 0), Vector3(1.9, 0.5, 4.0), c],                          # the body
		[Vector3(0, 1.05, -1.5), Vector3(1.85, 0.16, 1.0), c],                     # the bonnet
		[Vector3(0, 1.02, -0.6), Vector3(1.85, 0.1, 0.9), dark],                   # the cab's floor
		[Vector3(0, 1.82, -0.6), Vector3(1.85, 0.1, 1.1), c],                      # the cab's roof
		[Vector3(-0.88, 1.42, -1.1), Vector3(0.1, 0.72, 0.1), c],                  # its posts (open windows)
		[Vector3(0.88, 1.42, -1.1), Vector3(0.1, 0.72, 0.1), c],
		[Vector3(-0.88, 1.42, -0.1), Vector3(0.1, 0.72, 0.1), c],
		[Vector3(0.88, 1.42, -0.1), Vector3(0.1, 0.72, 0.1), c],
		[Vector3(0, 1.42, -0.08), Vector3(1.85, 0.72, 0.06), c],                   # the cab's back
		[Vector3(0, 1.46, -1.14), Vector3(1.66, 0.5, 0.04), glass],                # the windscreen
		[Vector3(-0.45, 1.12, -0.5), Vector3(0.62, 0.12, 0.5), SEAT],              # the seats
		[Vector3(0.45, 1.12, -0.5), Vector3(0.62, 0.12, 0.5), SEAT],
		[Vector3(0, 1.0, 1.0), Vector3(1.8, 0.06, 1.9), dark],                     # the bed
		[Vector3(-0.9, 1.2, 1.0), Vector3(0.1, 0.34, 1.9), c],                     # its sides
		[Vector3(0.9, 1.2, 1.0), Vector3(0.1, 0.34, 1.9), c],
		[Vector3(0, 1.2, 1.95), Vector3(1.9, 0.34, 0.1), c],                       # the tailgate
		[Vector3(0, 0.55, -2.03), Vector3(2.0, 0.2, 0.1), TRIM],                   # bumpers
		[Vector3(0, 0.55, 2.03), Vector3(2.0, 0.2, 0.1), TRIM],
	]
	p.append_array(_lights(0.66, 0.85, -2.02, 2.02))
	return p


## Where the pickup's load shows (its bed's middle, a little above its floor): CargoView puts the cubes there.
const BED := Vector3(0, 1.05, 1.0)


static func _bus(c: Color, dark: Color) -> Array:
	var p: Array = [
		[Vector3(0, 1.02, 0), Vector3(2.35, 1.05, 5.5), c],                        # the lower body (its floor inside)
		[Vector3(0, 2.52, 0), Vector3(2.35, 0.16, 5.5), WHITE],                    # the roof
		[Vector3(0, 1.98, -2.7), Vector3(2.35, 0.94, 0.1), c],                     # the front, round the windscreen
		[Vector3(0, 1.98, 2.7), Vector3(2.35, 0.94, 0.1), c],                      # the back
		[Vector3(0, 2.0, -2.76), Vector3(2.0, 0.7, 0.04), Color("9ad7ff")],        # the windscreen
		[Vector3(0, 1.2, 0), Vector3(2.37, 0.12, 5.3), WHITE],                     # a stripe
		[Vector3(0, 0.5, -2.78), Vector3(2.4, 0.24, 0.1), TRIM],                   # bumpers
		[Vector3(0, 0.5, 2.78), Vector3(2.4, 0.24, 0.1), TRIM],
		[Vector3(1.18, 1.0, -1.9), Vector3(0.04, 0.9, 0.7), dark],                 # the door
	]
	for z: float in [-1.6, -0.75, 0.15, 1.05, 1.95]:                               # window posts (open windows)
		p.append([Vector3(-1.13, 1.98, z), Vector3(0.1, 0.94, 0.1), c])
		p.append([Vector3(1.13, 1.98, z), Vector3(0.1, 0.94, 0.1), c])
	for s: Vector3 in CarKinds.seat_offsets(CarKinds.BUS):                         # the seats inside
		p.append([Vector3(s.x, 1.6, s.z + 0.12), Vector3(0.7, 0.1, 0.5), SEAT])
		p.append([Vector3(s.x, 1.85, s.z + 0.38), Vector3(0.7, 0.45, 0.08), SEAT])
	p.append_array(_lights(0.8, 0.8, -2.77, 2.77, 0.2))
	return p


static func _monster_truck(c: Color, dark: Color) -> Array:
	var p: Array = [
		[Vector3(0, 1.0, 0), Vector3(1.2, 0.26, 3.4), TRIM],                       # the frame, high up
		[Vector3(-0.95, 1.25, -1.3), Vector3(0.2, 0.7, 0.2), METAL],               # springs
		[Vector3(0.95, 1.25, -1.3), Vector3(0.2, 0.7, 0.2), METAL],
		[Vector3(-0.95, 1.25, 1.3), Vector3(0.2, 0.7, 0.2), METAL],
		[Vector3(0.95, 1.25, 1.3), Vector3(0.2, 0.7, 0.2), METAL],
		[Vector3(0, 1.72, 0), Vector3(2.2, 0.36, 3.6), c],                         # the body
		[Vector3(0, 2.0, -1.3), Vector3(2.1, 0.22, 1.0), c],                       # the bonnet
		[Vector3(-0.98, 1.95, 0.6), Vector3(0.24, 0.12, 2.2), STRIPE],             # flames down its sides
		[Vector3(0.98, 1.95, 0.6), Vector3(0.24, 0.12, 2.2), STRIPE],
		[Vector3(0, 2.36, -0.78), Vector3(1.9, 0.56, 0.06), Color("9ad7ff")],      # the windscreen
		[Vector3(-1.0, 2.5, -0.2), Vector3(0.1, 0.9, 0.1), TRIM],                  # the cage (open: riders show)
		[Vector3(1.0, 2.5, -0.2), Vector3(0.1, 0.9, 0.1), TRIM],
		[Vector3(-1.0, 2.5, 0.6), Vector3(0.1, 0.9, 0.1), TRIM],
		[Vector3(1.0, 2.5, 0.6), Vector3(0.1, 0.9, 0.1), TRIM],
		[Vector3(0, 2.92, 0.2), Vector3(2.1, 0.08, 1.0), TRIM],
		[Vector3(0, 2.98, -0.25), Vector3(1.4, 0.1, 0.12), LIGHT],                 # the roof lights
		[Vector3(-0.45, 2.0, -0.05), Vector3(0.6, 0.14, 0.5), SEAT],
		[Vector3(0.45, 2.0, -0.05), Vector3(0.6, 0.14, 0.5), SEAT],
		[Vector3(0, 1.5, -1.86), Vector3(2.2, 0.2, 0.1), dark],                    # bumpers
		[Vector3(0, 1.5, 1.86), Vector3(2.2, 0.2, 0.1), dark],
	]
	p.append_array(_lights(0.7, 1.75, -1.82, 1.82))
	return p


static func _hover_car(c: Color, dark: Color) -> Array:
	var p: Array = [
		[Vector3(0, 0.66, 0.05), Vector3(1.9, 0.4, 3.3), c],                       # the body, floating
		[Vector3(0, 0.58, -1.6), Vector3(1.5, 0.24, 0.36), dark],                  # the nose
		[Vector3(0, 0.88, -0.75), Vector3(1.5, 0.08, 0.6), c],                     # the dash
		[Vector3(0, 1.08, -0.98), Vector3(1.5, 0.34, 0.05), Color("b8ecff"), Basis(Vector3.RIGHT, -0.5)],   # the screen
		[Vector3(-0.45, 0.9, 0.05), Vector3(0.6, 0.12, 0.55), SEAT],
		[Vector3(0.45, 0.9, 0.05), Vector3(0.6, 0.12, 0.55), SEAT],
		[Vector3(-0.86, 1.05, 1.45), Vector3(0.08, 0.5, 0.5), dark],               # fins
		[Vector3(0.86, 1.05, 1.45), Vector3(0.08, 0.5, 0.5), dark],
		[Vector3(0, 0.62, 1.72), Vector3(1.4, 0.2, 0.08), GLOW],                   # its glowing jet
	]
	for x: float in [-0.65, 0.65]:                                                 # the hover pads (no wheels)
		for z: float in [-1.15, 1.15]:
			p.append([Vector3(x, 0.38, z), Vector3(0.5, 0.1, 0.6), GLOW])
			p.append([Vector3(x, 0.45, z), Vector3(0.56, 0.06, 0.66), TRIM])
	p.append_array(_lights(0.6, 0.62, -1.78, 1.72, 0.12))
	return p


static func _sky_taxi(c: Color, dark: Color) -> Array:
	var p: Array = [
		[Vector3(0, 0.82, 0), Vector3(1.8, 0.64, 3.6), c],                         # the lower body (its floor inside)
		[Vector3(0, 1.84, 0), Vector3(1.8, 0.14, 3.2), c],                         # the roof
		[Vector3(0, 1.98, -0.3), Vector3(0.6, 0.16, 0.3), WHITE],                  # the TAXI light
		[Vector3(0, 1.48, -1.62), Vector3(1.6, 0.6, 0.04), Color("9ad7ff")],       # the windscreen
		[Vector3(0, 1.48, 1.62), Vector3(1.8, 0.62, 0.1), c],                      # the back
		[Vector3(0, 0.62, 0), Vector3(1.82, 0.1, 3.4), TRIM],                      # a checker band
		[Vector3(0, 0.46, -1.86), Vector3(1.9, 0.18, 0.08), TRIM],                 # bumpers
		[Vector3(0, 0.46, 1.86), Vector3(1.9, 0.18, 0.08), TRIM],
	]
	for z: float in [-1.55, 0.0, 1.55]:                                            # window posts (open windows)
		p.append([Vector3(-0.85, 1.48, z), Vector3(0.1, 0.62, 0.1), c])
		p.append([Vector3(0.85, 1.48, z), Vector3(0.1, 0.62, 0.1), c])
	for s: Vector3 in CarKinds.seat_offsets(CarKinds.SKY_TAXI):                     # the seats
		p.append([Vector3(s.x, 1.18, s.z + 0.05), Vector3(0.6, 0.1, 0.5), SEAT])
	for spot: Vector3 in rotor_spots(CarKinds.SKY_TAXI):                            # the arms to the rotors
		var side := signf(spot.x)
		p.append([Vector3(spot.x * 0.68, 1.86, spot.z), Vector3(absf(spot.x) * 0.64, 0.08, 0.1), dark])
		p.append([Vector3(spot.x, 1.9, spot.z), Vector3(0.24, 0.12, 0.24), METAL])
		p.append([Vector3(spot.x - side * 0.02, 1.84, spot.z), Vector3(0.06, 0.06, 0.06), TRIM])
	p.append_array(_lights(0.6, 0.72, -1.82, 1.82, 0.12))
	return p
