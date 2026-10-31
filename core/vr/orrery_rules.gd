class_name OrreryRules
extends RefCounted
## Owner #110 (VR round 4, VR-WONDER, idea 1 "hold a planet"; docs/devlog/parts/vr-r4-wonder.md, the research
## docs/devlog/parts/vr-ideas-research.md §5.3): the Star Map in a headset is a moving orrery within reach. Pure: the
## bodies' real sizes, where each one is on the orrery today (the flat map's StarMap.longitude), how big it is there, in
## the hand and in TRUE SIZE, the TRUE SIZE row, the landing ring and the comparison words.
##
## The orrery's own space: the Sun at the origin, x to the child's right, y up, z towards the child (metres, the child's
## own: VrOrrery scales it with the world scale). On the orrery sizes are the flat map's ("bigger means bigger, not to
## scale"); in a hand and in TRUE SIZE they are true against each other.

## Real equatorial diameters (km): NASA's planetary fact sheets (the Sun's: 1,392,700 km).
const DIAMETER_KM := {&"sun": 1392700.0, &"mercury": 4879.0, &"venus": 12104.0, &"earth": 12756.0, &"moon": 3475.0,
	&"mars": 6792.0, &"jupiter": 142984.0, &"io": 3643.0, &"europa": 3122.0, &"ganymede": 5268.0, &"callisto": 4821.0,
	&"saturn": 120536.0, &"titan": 5150.0, &"uranus": 51118.0, &"neptune": 49528.0, &"triton": 2707.0,
	&"pluto": 2376.0}

## Each planet's orbit on the orrery (m): the flat map's order and spacing, the outer ones spread a little more so a
## planet's moons never touch the next orbit.
const ORBIT := {&"mercury": 0.08, &"venus": 0.12, &"earth": 0.165, &"mars": 0.21, &"jupiter": 0.28, &"saturn": 0.36,
	&"uranus": 0.42, &"neptune": 0.47, &"pluto": 0.52}
## The orrery's radius (m): Pluto's orbit and a little more. 1.06 m across, its middle ORRERY_AHEAD from the eyes.
const REACH := 0.53
## Where it stands: its middle this far ahead of the eyes (m) and this far below them (m): under the eye panel (its
## bottom edge is 0.55 m under the eyes at 1.4 m), so the laser to a far planet passes under the panel.
const ORRERY_AHEAD := 0.65
const ORRERY_DROP := 0.55
## The Sun on the orrery (m), and every other body's radius per pixel of the flat map's size (StarMap "size").
const SUN_RADIUS := 0.045
const MAP_SIZE := 0.0009
## A moon goes round this far outside its planet's surface (m), its planet's moons spread evenly round it.
const MOON_GAP := 0.01
## A planet's moons go round it in this many seconds (the flat map's MOON_RING_SECONDS).
const MOON_SECONDS := {&"earth": 27.0, &"jupiter": 24.0, &"saturn": 20.0, &"neptune": 16.0}
## An Earth year in seconds: the flat map's (SpacePanel.EARTH_YEAR_SECONDS).
const EARTH_YEAR_SECONDS := 40.0
## In a hand a body is its true size against Earth's, Earth 4 cm across (Jupiter 45 cm: holding something huge).
const HAND_EARTH_RADIUS := 0.02
## TRUE SIZE: every body true against every other, Earth 1.2 cm across (the Sun 1.3 m), the planets in a row in order
## ROW_Z towards the child, ROW_GAP between them, the Sun behind the row (SUN_BEHIND past its edge).
const TRUE_EARTH_RADIUS := 0.006
const ROW: Array[StringName] = [&"mercury", &"venus", &"earth", &"mars", &"jupiter", &"saturn", &"uranus", &"neptune",
	&"pluto"]
const ROW_Z := 0.12
const ROW_GAP := 0.03
const SUN_BEHIND := 0.2
## Saturn's ring reaches this many of its radii (the main rings: about 2.3).
const RING_INNER := 1.25
const RING_OUTER := 2.3
## The landing ring (drop a planet in it to fly there, as LAND): beside the orrery on the pointing hand's side, a little
## up and towards the child; a drop within RING_CATCH of its middle counts. RING_RADIUS is its drawn size.
const RING_SIDE := 0.66
const RING_UP := 0.1
const RING_TOWARDS := 0.18
const RING_RADIUS := 0.09
const RING_CATCH := 0.13
## The comparison's words fit one line on the orrery.
const MAX_WORDS := 60
## The School's units the orrery teaches with (every wonder teaches): how rockets work, the Sun and other stars, the
## solar system, gravity and orbits; ratios (Jupiter is 11 Earths across) and scale drawings (TRUE SIZE is a scale model).
const UNITS: Array[String] = ["g4.science.rockets_explorer", "g5.science.sun_stars", "g8.science.solar_system",
	"g8.science.gravity_orbits", "g6.maths.ratios", "g7.maths.scale_drawings"]


## How many times as wide `a` is as `b` (their real diameters); 0 when either is unknown.
static func ratio(a: StringName, b: StringName) -> float:
	var db := float(DIAMETER_KM.get(b, 0.0))
	return float(DIAMETER_KM.get(a, 0.0)) / db if db > 0.0 else 0.0


## Days of the Star Map (StarMap.longitude) a second of the orrery: an Earth year in EARTH_YEAR_SECONDS.
static func days_per_second() -> float:
	return StarMap.year_days(&"earth") / EARTH_YEAR_SECONDS


## A body's radius (m): on the orrery (the Sun SUN_RADIUS, the rest the flat map's size × MAP_SIZE), or in TRUE SIZE.
static func radius(id: StringName, true_size: bool) -> float:
	if true_size:
		return ratio(id, &"earth") * TRUE_EARTH_RADIUS
	if id == &"sun":
		return SUN_RADIUS
	return float(StarMap.body(id).get("size", 10.0)) * MAP_SIZE


## A body's radius (m) in a hand: true against Earth's HAND_EARTH_RADIUS.
static func hand_radius(id: StringName) -> float:
	return ratio(id, &"earth") * HAND_EARTH_RADIUS


## Half a body's width (m): its radius, Saturn's ring included.
static func half_width(id: StringName, true_size: bool) -> float:
	return radius(id, true_size) * (RING_OUTER if id == &"saturn" else 1.0)


## A hand may take it: everything but the Sun (109 Earths across: it stays in the middle).
static func takeable(id: StringName) -> bool:
	return id != &"sun" and DIAMETER_KM.has(id)


## Where body `id` is on the orrery (its own space, m): a planet on its orbit where it is `days` after 2000 (StarMap's
## real places), a moon round its planet `moon_t` seconds on; in TRUE SIZE the planets in their row and the Sun behind.
static func place(id: StringName, days: float, moon_t: float, true_size: bool) -> Vector3:
	if id == &"sun":
		return Vector3(0.0, 0.0, -(radius(&"sun", true) + SUN_BEHIND)) if true_size else Vector3.ZERO
	var d := StarMap.body(id)
	if str(d.get("kind", "")) == "moon":
		var parent: StringName = d.get("parent", &"")
		var at := place(parent, days, moon_t, true_size)
		var ring := radius(parent, true_size) + MOON_GAP
		if true_size:
			ring = radius(parent, true) * (RING_OUTER if parent == &"saturn" else 1.0) + MOON_GAP * 0.5
		var a := moon_angle(id, moon_t)
		return at + Vector3(cos(a) * ring, 0.0, -sin(a) * ring)
	if true_size:
		return Vector3(row_x(id), 0.0, ROW_Z)
	if not ORBIT.has(id):
		return Vector3.ZERO
	var r := float(ORBIT[id])
	var lon := StarMap.longitude(id, days)
	return Vector3(cos(lon) * r, 0.0, -sin(lon) * r)


## A moon's angle round its planet (radians): its planet's moons evenly spread, a turn in MOON_SECONDS.
static func moon_angle(id: StringName, moon_t: float) -> float:
	var parent: StringName = StarMap.body(id).get("parent", &"")
	var siblings: Array[StringName] = []
	for other: Dictionary in StarMap.SOLAR:
		if str(other.kind) == "moon" and other.get("parent", &"") == parent:
			siblings.append(other.id)
	var turn := float(MOON_SECONDS.get(parent, 20.0))
	var i := maxi(siblings.find(id), 0)
	return fposmod(TAU * moon_t / turn + TAU * i / maxf(siblings.size(), 1.0) + 0.6, TAU)


## A planet's x in the TRUE SIZE row (m): left to right in ROW's order, each its own width apart (ROW_GAP between), the
## row centred on the Sun.
static func row_x(id: StringName) -> float:
	var total := 0.0
	for r: StringName in ROW:
		total += half_width(r, true) * 2.0
	total += ROW_GAP * (ROW.size() - 1)
	var x := -total * 0.5
	for r: StringName in ROW:
		var w := half_width(r, true)
		if r == id:
			return x + w
		x += w * 2.0 + ROW_GAP
	return 0.0


## The landing ring's middle (the orrery's space) on the pointing hand's side.
static func ring_at(pointing: StringName) -> Vector3:
	return Vector3(RING_SIDE * (-1.0 if pointing == VrRules.LEFT else 1.0), RING_UP, RING_TOWARDS)


## A body let go at `p` is in the ring at `ring` (both in the orrery's space).
static func in_ring(p: Vector3, ring: Vector3) -> bool:
	return p.distance_to(ring) <= RING_CATCH


## Two bodies in the hands: how many times as wide the bigger is ("Jupiter is 11 times as wide as Earth!"), whole
## from 10, one decimal under; about the same under 1.2; "" for the same body.
static func compare_words(a: StringName, b: StringName) -> String:
	if a == b or ratio(a, b) <= 0.0:
		return ""
	var big := a if ratio(a, b) >= 1.0 else b
	var small := b if big == a else a
	var r := ratio(big, small)
	if r < 1.2:
		return "%s and %s are about the same size!" % [_name(big, true), _name(small, false)]
	var times := str(roundi(r)) if r >= 10.0 else "%.1f" % r
	return "%s is %s times as wide as %s!" % [_name(big, true), times, _name(small, false)]


## The Star Map's name ("The Moon"), "the" small in the middle of a sentence.
static func _name(id: StringName, first: bool) -> String:
	var n := str(StarMap.body(id).get("name", String(id).capitalize()))
	if not first and n.begins_with("The "):
		n = "the " + n.substr(4)
	return n
