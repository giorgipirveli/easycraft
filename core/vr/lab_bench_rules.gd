class_name LabBenchRules
extends RefCounted
## Owner #110 (VR round 4, VR-WONDER, idea 4 "the Lab bench by hand"; docs/devlog/parts/vr-r4-wonder.md, the research
## docs/devlog/parts/vr-ideas-research.md §5.3): in a headset the Lab's float-or-sink and magnets are done with the
## hands on a real bench. Pure: where the bench stands (hand height, a handle lifts it), the shelf, the two baskets (the
## prediction's sort), the tank (a cube let go over it is dropped in), where a floater and a sinker rest, the magnet's
## pull. What happens to each thing is never decided here: the Lab's tested models say (LabTank.floats, LabMagnet.sticks).
##
## The bench's own space: the middle of its top at the origin, x to the child's right, y up, z towards the child (m).

## The top (m): wide, deep, thick.
const TOP := Vector3(0.9, 0.04, 0.45)
## It starts this far under the eyes (seated children too: Owlchemy's desks) and this far ahead (m).
const START_DROP := 0.45
const START_AHEAD := 0.45
## The handle keeps the top between these depths under the eyes (m): never above the chest, never at the floor.
const LIFT := Vector2(0.2, 0.8)
## Where the handle is (the top's right end) and how near a hand takes it.
const HANDLE_AT := Vector3(0.5, 0.0, 0.0)
## A thing is a cube this big (m): big enough for a child's hand.
const CUBE := 0.055
## The shelf: the back row of the top.
const SHELF_Z := -0.16
const SHELF_PITCH := 0.09
## The baskets (open boxes on the top, front left): their middles at the top's surface and their size.
const BASKETS: Array[Vector3] = [Vector3(-0.3, 0.0, 0.08), Vector3(-0.02, 0.0, 0.08)]
const BASKET_SIZE := Vector3(0.25, 0.07, 0.15)
## The tank (front right): its middle on the top, its size; the water fills WATER of it (LabThingsView.WATER).
const TANK_AT := Vector3(0.27, 0.0, 0.04)
const TANK_SIZE := Vector3(0.28, 0.22, 0.2)
const WATER := 0.62
## The glass's thickness (m), and how deep a floater sits in the water (of its size).
const GLASS := 0.004
const FLOAT_DEPTH := 0.3
## A drop counts this far around a basket or the tank (m) and this high above its rim.
const MARGIN := 0.03
const DROP_ABOVE := 0.15
## The magnet: a magnetic thing is pulled to its tip from PULL_REACH (m from the thing's surface), anything is tried
## when the tip touches it (TOUCH_REACH). Where the magnet rests: the tank's place (no tank in the magnets' run).
const PULL_REACH := 0.1
const TOUCH_REACH := 0.03
const MAGNET_REST := Vector3(0.27, 0.12, 0.06)


## The School's unit every bench run practises besides its experiment's own: predict, try it, find out why.
const SCIENTIST_UNIT := "g3.science.fair_tests"


## The School's units a bench run teaches with: its experiment's own (data/lab/<id>.json "units") and SCIENTIST_UNIT.
static func units_of(experiment: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for u: Variant in experiment.get("units", []):
		out.append(str(u))
	if not out.has(SCIENTIST_UNIT):
		out.append(SCIENTIST_UNIT)
	return out


## The experiments done with the hands in VR (the others stay on the panel: heat, colours, plants, the circuit).
static func by_hand(scene: Dictionary) -> bool:
	return str(scene.get("kind", "")) in ["tank", "magnet"]


## The bench's place for a child whose head is at `head`: START_AHEAD in front along the head's yaw, START_DROP under the
## eyes, level, its +z towards the child.
static func place_before(head: Transform3D) -> Transform3D:
	var fwd := -head.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized() if fwd.length() > 0.001 else Vector3.FORWARD
	var basis := Basis.looking_at(fwd, Vector3.UP)   # -z along fwd: +z towards the child
	return Transform3D(basis, head.origin + fwd * START_AHEAD + Vector3.DOWN * START_DROP)


## The top's height when the handle asks for `wanted` (m, the world's), with the eyes at `eye_y`.
static func lifted(eye_y: float, wanted: float) -> float:
	return clampf(wanted, eye_y - LIFT.y, eye_y - LIFT.x)


## Where thing `i` of `n` waits on the shelf.
static func shelf_spot(i: int, n: int) -> Vector3:
	var x := (float(i) - (float(n) - 1.0) * 0.5) * SHELF_PITCH
	return Vector3(x, CUBE * 0.5, SHELF_Z)


## The basket a thing let go at `p` falls into (0 or 1), or -1.
static func basket_at(p: Vector3) -> int:
	for g in BASKETS.size():
		if _in_box(p, BASKETS[g], BASKET_SIZE):
			return g
	return -1


## The k-th place in basket `group` (4 across, 2 deep).
static func basket_slot(group: int, k: int) -> Vector3:
	var c: Vector3 = BASKETS[clampi(group, 0, BASKETS.size() - 1)]
	var col := k % 4
	var row := (k / 4) % 2
	return c + Vector3((col - 1.5) * (BASKET_SIZE.x - 0.01) / 4.0, CUBE * 0.5 + 0.005, (row - 0.5) * (BASKET_SIZE.z - 0.02) / 2.0)


## A thing let go at `p` goes into the tank.
static func in_tank(p: Vector3) -> bool:
	return _in_box(p, TANK_AT, TANK_SIZE)


## Where the k-th of `n` things in the tank rests: a floater at the surface, a sinker on the bottom, side by side.
static func tank_spot(floats: bool, k: int, n: int) -> Vector3:
	var pitch := minf(CUBE * 1.2, (TANK_SIZE.x - 0.04) / maxf(n, 1.0))
	var x := TANK_AT.x + (float(k) - (float(n) - 1.0) * 0.5) * pitch
	var z := TANK_AT.z + (0.03 if k % 2 == 0 else -0.03)
	var y := TANK_SIZE.y * WATER - CUBE * FLOAT_DEPTH if floats else CUBE * 0.5 + GLASS
	return Vector3(x, y, z)


## The magnet's tip `gap` m from a thing's surface catches it: a magnetic one is pulled from PULL_REACH, any one is
## tried when touched.
static func magnet_catches(gap: float, magnetic: bool) -> bool:
	return gap <= (PULL_REACH if magnetic else TOUCH_REACH)


## The baskets' words: the experiment's groups in capitals ("FLOATS", "SINKS").
static func basket_words(groups: Array) -> Array[String]:
	var out: Array[String] = []
	for g: Variant in groups:
		out.append(str(g).to_upper())
	return out


static func _in_box(p: Vector3, base: Vector3, box: Vector3) -> bool:
	return absf(p.x - base.x) <= box.x * 0.5 + MARGIN and absf(p.z - base.z) <= box.z * 0.5 + MARGIN \
		and p.y >= base.y - 0.02 and p.y <= base.y + box.y + DROP_ABOVE
