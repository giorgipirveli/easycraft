class_name CarKinds
extends RefCounted
## Owner #109 (spec §3b "Cars"): the ready-made cars, in one table: each kind's feel (top speed, reverse, how quickly it
## speeds up and turns, how high a step it climbs), its seats (where each rider's feet go, in the car's own space: its
## feet at the middle of its bottom, its front towards -Z, the driver's seat first), its look (its size, its compact
## collision box, its wheels, four colours), its Survivor price, its camera distance, its horn and its card (a line and
## a few checked facts: docs/devlog/parts/cars.md has their sources). Pure data; VehicleRules has the rules.
## Speeds are m/s (a block is a metre). No car is faster than GROUND_TOP on the ground and no flying car than FLY_TOP
## (the paid Fly, Player.FLY_SPEED: the rides' ruling keeps the paid Fly worth buying).

const GO_KART := &"go_kart"
const OFF_ROADER := &"off_roader"   # the brief's jeep (a 4x4; "Jeep" is a make's name)
const RACE_CAR := &"race_car"
const PICKUP := &"pickup"
const BUS := &"bus"
const MONSTER_TRUCK := &"monster_truck"
const HOVER_CAR := &"hover_car"
const SKY_TAXI := &"sky_taxi"
## The garage's order: the cheapest first, the flying cars last.
const ORDER: Array[StringName] = [GO_KART, OFF_ROADER, RACE_CAR, PICKUP, BUS, MONSTER_TRUCK, HOVER_CAR, SKY_TAXI]
const FLYING: Array[StringName] = [HOVER_CAR, SKY_TAXI]

const GROUND_TOP := 14.0
const FLY_TOP := 11.0
const COLOURS := 4
## The biggest collision box a car may have (owner feedback #9: physics cost grows with a box's footprint).
const MAX_BOX := Vector3(2.4, 3.0, 5.6)

const SMALL_HORN := &"small"
const HORN := &"mid"
const BIG_HORN := &"big"

const DATA := {
	GO_KART: {
		"name": "Go-Kart", "speed": 9.0, "reverse": 4.0, "accel": 14.0, "turn": 3.0, "climb": 1, "price": 40,
		"size": Vector3(1.3, 0.8, 2.0), "box": Vector3(1.2, 0.7, 1.9), "wheel_r": 0.22,
		"wheels": [Vector3(-0.62, 0.22, -0.72), Vector3(0.62, 0.22, -0.72), Vector3(-0.62, 0.22, 0.72),
			Vector3(0.62, 0.22, 0.72)],
		"seats": [Vector3(0.0, 0.05, 0.15)], "camera": 4.5, "horn": SMALL_HORN,
		"colours": [Color("e8403a"), Color("ffd23f"), Color("3fbf5a"), Color("3d8bff")],
		"colour_names": ["Red", "Yellow", "Green", "Blue"],
		"about": "Small and quick: it turns the sharpest of all.",
		"facts": [
			"A go-kart's small engine sits by the seat. Burning fuel pushes a piston, the piston turns a shaft, and a chain turns the back wheels.",
			"Go-karts have no springs: the frame itself bends a little over bumps.",
			"The first go-kart was built in California in 1956 by Art Ingels and his friend Lou Borelli.",
		],
	},
	OFF_ROADER: {
		"name": "Off-Roader", "speed": 10.0, "reverse": 4.0, "accel": 10.0, "turn": 2.2, "climb": 2, "price": 120,
		"size": Vector3(2.0, 1.8, 3.4), "box": Vector3(1.9, 1.6, 3.2), "wheel_r": 0.45,
		"wheels": [Vector3(-0.95, 0.45, -1.15), Vector3(0.95, 0.45, -1.15), Vector3(-0.95, 0.45, 1.15),
			Vector3(0.95, 0.45, 1.15)],
		"seats": [Vector3(-0.45, 0.55, -0.15), Vector3(0.45, 0.55, -0.15), Vector3(-0.45, 0.6, 0.85),
			Vector3(0.45, 0.6, 0.85)],
		"camera": 6.0, "horn": HORN,
		"colours": [Color("6b8e3a"), Color("d9b26a"), Color("ff8a1c"), Color("eef2f5")],
		"colour_names": ["Olive", "Sand", "Orange", "White"],
		"about": "Big tyres grip and climb steps 2 blocks high. Room for four.",
		"facts": [
			"Four-wheel drive: the engine turns all four wheels, not just two, so the car can still pull itself through mud, sand and snow.",
			"Its tyres have deep grooves, called tread, that bite into soft ground and let water and mud squeeze out.",
			"It sits up high, so rocks and bumps pass underneath it.",
		],
	},
	RACE_CAR: {
		"name": "Race Car", "speed": GROUND_TOP, "reverse": 4.0, "accel": 11.0, "turn": 2.0, "climb": 1, "price": 200,
		"size": Vector3(1.9, 0.9, 3.8), "box": Vector3(1.8, 0.8, 3.6), "wheel_r": 0.34,
		"wheels": [Vector3(-0.9, 0.34, -1.25), Vector3(0.9, 0.34, -1.25), Vector3(-0.9, 0.34, 1.2),
			Vector3(0.9, 0.34, 1.2)],
		"seats": [Vector3(0.0, 0.1, 0.35)], "camera": 5.5, "horn": SMALL_HORN,
		"colours": [Color("e3262e"), Color("1f5fd8"), Color("ffcc00"), Color("c3cbd4")],
		"colour_names": ["Red", "Blue", "Yellow", "Silver"],
		"about": "The fastest car on flat ground.",
		"facts": [
			"A race car is low and wide, so it does not tip over in fast corners.",
			"Its wings work like an upside-down aeroplane wing: the air pushes the car down onto the road, so the tyres grip harder in corners.",
			"Some races are only for electric race cars: the first Formula E race was in Beijing in 2014.",
		],
	},
	PICKUP: {
		"name": "Pickup Truck", "speed": 10.5, "reverse": 4.0, "accel": 9.0, "turn": 2.0, "climb": 1, "price": 150,
		"size": Vector3(2.0, 1.9, 4.2), "box": Vector3(1.9, 1.7, 4.0), "wheel_r": 0.42,
		"wheels": [Vector3(-0.95, 0.42, -1.4), Vector3(0.95, 0.42, -1.4), Vector3(-0.95, 0.42, 1.4),
			Vector3(0.95, 0.42, 1.4)],
		"seats": [Vector3(-0.45, 0.55, -0.7), Vector3(0.45, 0.55, -0.7)], "camera": 6.5, "horn": HORN,
		"colours": [Color("3d6fd1"), Color("c8382f"), Color("eef2f5"), Color("3a3f4a")],
		"colour_names": ["Blue", "Red", "White", "Black"],
		"about": "Carries a load of blocks in its bed. Tap the bed with blocks to load it.",
		"load": true,
		"facts": [
			"A pickup truck's open back is called the bed. It carries loads like bricks, wood or bikes.",
			"Stiff springs over the back wheels hold the bed up, even when it is full.",
			"A heavy load makes a truck slower to speed up: the more mass, the bigger the push it needs.",
		],
	},
	BUS: {
		"name": "Bus", "speed": 7.0, "reverse": 3.0, "accel": 5.0, "turn": 1.4, "climb": 1, "price": 180,
		"size": Vector3(2.4, 2.8, 5.6), "box": Vector3(2.2, 2.6, 5.4), "wheel_r": 0.5,
		"wheels": [Vector3(-1.1, 0.5, -1.8), Vector3(1.1, 0.5, -1.8), Vector3(-1.1, 0.5, 1.8), Vector3(1.1, 0.5, 1.8)],
		"seats": [Vector3(-0.6, 0.55, -2.1), Vector3(0.6, 0.55, -1.2), Vector3(-0.6, 0.55, -0.3),
			Vector3(0.6, 0.55, -0.3), Vector3(-0.6, 0.55, 0.6), Vector3(0.6, 0.55, 0.6), Vector3(-0.6, 0.55, 1.5),
			Vector3(0.6, 0.55, 1.5)],
		"camera": 9.0, "horn": BIG_HORN,
		"colours": [Color("ffc61a"), Color("d93a2b"), Color("2f9e57"), Color("2f6fd1")],
		"colour_names": ["Yellow", "Red", "Green", "Blue"],
		"about": "Slow, but the whole team rides along: eight seats.",
		"facts": [
			"A full city bus can carry around 70 people, sitting and standing. Most cars carry only one or two, so one bus can take dozens of cars off the road.",
			"Many buses are electric: a big battery powers electric motors, and braking charges the battery again.",
			"By the end of 2017 all of Shenzhen's buses in China, more than 16,000 of them, were electric.",
		],
	},
	MONSTER_TRUCK: {
		"name": "Monster Truck", "speed": 9.5, "reverse": 4.0, "accel": 9.0, "turn": 1.8, "climb": 3, "price": 250,
		"size": Vector3(3.0, 3.0, 4.0), "box": Vector3(2.4, 2.6, 3.6), "wheel_r": 0.85,
		"wheels": [Vector3(-1.25, 0.85, -1.3), Vector3(1.25, 0.85, -1.3), Vector3(-1.25, 0.85, 1.3),
			Vector3(1.25, 0.85, 1.3)],
		"seats": [Vector3(-0.45, 1.85, -0.2), Vector3(0.45, 1.85, -0.2)], "camera": 8.0, "horn": BIG_HORN,
		"bounce": true,
		"colours": [Color("8e44ff"), Color("48d14f"), Color("ff7a1a"), Color("e8403a")],
		"colour_names": ["Purple", "Green", "Orange", "Red"],
		"about": "Huge wheels climb steps 3 blocks high, and it bounces!",
		"facts": [
			"A monster truck's tyres are about 1.7 metres tall: as tall as a grown-up!",
			"A big wheel rolls over a step that stops a small wheel: the bigger the wheel, the higher the step it can climb.",
			"Long, soft springs let its wheels move up and down a long way, so it bounces over bumps and lands its jumps.",
		],
	},
	HOVER_CAR: {
		"name": "Hover Car", "speed": 10.0, "reverse": 4.0, "accel": 8.0, "turn": 2.4, "climb": 1, "price": 400,
		"fly": 10.0, "above": 24.0, "hover": true,
		"size": Vector3(2.0, 1.3, 3.6), "box": Vector3(1.9, 1.1, 3.4), "wheel_r": 0.0, "wheels": [],
		"seats": [Vector3(-0.45, 0.45, 0.0), Vector3(0.45, 0.45, 0.0)], "camera": 6.0, "horn": HORN,
		"colours": [Color("c3cbd4"), Color("21c7c7"), Color("ff6fb5"), Color("9a4dff")],
		"colour_names": ["Silver", "Teal", "Pink", "Purple"],
		"about": "Floats on air over land and water. FLY lifts it up into the sky.",
		"facts": [
			"A real hovercraft floats on a cushion of air: big fans blow air underneath it, and a rubber skirt keeps the air in.",
			"With almost nothing rubbing on the ground, it glides over land, water, mud and ice alike.",
			"Christopher Cockerell invented it. The first big one, the SR.N1, crossed the English Channel in 1959.",
			"Real ones stay low. Our hover car also flies high: that part is game magic!",
		],
	},
	SKY_TAXI: {
		"name": "Sky Taxi", "speed": 8.0, "reverse": 3.0, "accel": 7.0, "turn": 1.8, "climb": 1, "price": 500,
		"fly": FLY_TOP, "above": 64.0,
		"size": Vector3(2.9, 2.1, 4.2), "box": Vector3(2.0, 1.9, 4.0), "wheel_r": 0.3,
		"wheels": [Vector3(-0.8, 0.3, -1.3), Vector3(0.8, 0.3, -1.3), Vector3(-0.8, 0.3, 1.3), Vector3(0.8, 0.3, 1.3)],
		"seats": [Vector3(-0.45, 0.5, -0.55), Vector3(0.45, 0.5, -0.55), Vector3(-0.45, 0.55, 0.55),
			Vector3(0.45, 0.55, 0.55)],
		"camera": 7.0, "horn": HORN,
		"colours": [Color("ffcc00"), Color("eef2f5"), Color("6cc4ff"), Color("ff8a1c")],
		"colour_names": ["Yellow", "White", "Sky blue", "Orange"],
		"about": "A flying car with seats for three friends.",
		"facts": [
			"Real flying cars have been tested! In 2021 the AirCar, a car whose wings fold out, flew 35 minutes between the airports of Nitra and Bratislava in Slovakia.",
			"Air taxis are being tested too: they have many small electric rotors, like a big drone, and take off straight up like a helicopter.",
			"To fly, the rotors push air down hard enough to hold the whole taxi up: that takes a lot of energy.",
		],
	},
}


static func exists(kind: StringName) -> bool:
	return DATA.has(kind)


static func of(kind: StringName) -> Dictionary:
	return DATA.get(kind, {})


static func display_name(kind: StringName) -> String:
	return str(of(kind).get("name", ""))


static func speed(kind: StringName) -> float:
	return float(of(kind).get("speed", 0.0))


static func reverse_speed(kind: StringName) -> float:
	return float(of(kind).get("reverse", 0.0))


static func accel(kind: StringName) -> float:
	return float(of(kind).get("accel", 0.0))


## How fast it turns at speed (radians a second).
static func turn(kind: StringName) -> float:
	return float(of(kind).get("turn", 0.0))


## The highest step it hops up (blocks).
static func climb(kind: StringName) -> int:
	return int(of(kind).get("climb", 0))


static func seat_offsets(kind: StringName) -> Array:
	return of(kind).get("seats", [])


static func seats(kind: StringName) -> int:
	return seat_offsets(kind).size()


static func price(kind: StringName) -> int:
	return int(of(kind).get("price", 0))


static func flies(kind: StringName) -> bool:
	return FLYING.has(kind)


## Its top speed in the air (0 for a ground car).
static func fly_speed(kind: StringName) -> float:
	return float(of(kind).get("fly", 0.0))


## How high over the ground under it a flying car goes at most (blocks).
static func above_ground(kind: StringName) -> float:
	return float(of(kind).get("above", 0.0))


## No wheels: it floats on air (and glides over water).
static func hovers(kind: StringName) -> bool:
	return bool(of(kind).get("hover", false))


static func bounces(kind: StringName) -> bool:
	return bool(of(kind).get("bounce", false))


static func carries_load(kind: StringName) -> bool:
	return bool(of(kind).get("load", false))


## Its look's size (x across, y up, z along).
static func size(kind: StringName) -> Vector3:
	return of(kind).get("size", Vector3.ONE)


## Its collision box (its bottom at the car's feet).
static func box(kind: StringName) -> Vector3:
	return of(kind).get("box", Vector3.ONE)


static func wheels(kind: StringName) -> Array:
	return of(kind).get("wheels", [])


static func wheel_radius(kind: StringName) -> float:
	return float(of(kind).get("wheel_r", 0.0))


## How far behind the driver the camera sits (a big car needs room).
static func camera_distance(kind: StringName) -> float:
	return float(of(kind).get("camera", 4.5))


static func horn(kind: StringName) -> StringName:
	return of(kind).get("horn", HORN)


static func colours(kind: StringName) -> Array:
	return of(kind).get("colours", [])


static func colour_names(kind: StringName) -> Array:
	return of(kind).get("colour_names", [])


## A synced colour number, checked (anything unknown is the first colour).
static func colour_index(i: int) -> int:
	return i if i >= 0 and i < COLOURS else 0


static func colour_of(kind: StringName, i: int) -> Color:
	var list := colours(kind)
	return list[colour_index(i)] if not list.is_empty() else Color.WHITE


## One line about it (the garage).
static func about(kind: StringName) -> String:
	return str(of(kind).get("about", ""))


## Its card's facts.
static func facts(kind: StringName) -> Array:
	return of(kind).get("facts", [])


## Its numbers in a child's words: "Top speed 14 blocks a second · climbs 1 block · 1 seat".
static func numbers_words(kind: StringName) -> String:
	var parts: Array[String] = ["Top speed %s blocks a second" % _num(speed(kind))]
	if flies(kind):
		parts.append("flies at %s" % _num(fly_speed(kind)))
	parts.append("climbs %d block%s" % [climb(kind), "" if climb(kind) == 1 else "s"])
	parts.append("%d seat%s" % [seats(kind), "" if seats(kind) == 1 else "s"])
	return " · ".join(parts)


static func _num(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else "%.1f" % v
