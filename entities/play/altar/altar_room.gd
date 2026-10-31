class_name AltarRoom
extends LifeRoom
## Owner #133, #134 (docs/design/games/balance-altar.md §3.5, §4.4; G0's place contract): Balance Altar's places are
## Life rooms (targets with forgiving radii, flat views, VR stands, the glow: G0's PlayArena's and the leaf's way) that
## also say, for B2's host and the tests, which targets the current view shows, which the hands take in VR, and the stand
## from which they reach. A room's altars stand in a ring (`build_ring`): one MultiMesh of altars at rest and one of their
## crystals, and one full BalanceAltar in the active slot; the ring turns so the active altar is always in front of the
## child (§3.5, ruling 22). The room draws its own sky (the rooms' default dome is put away) and keeps the worlds' ACES
## tone with its own warm ambient light. Professor Hoot stands by the active altar (`show_hoot`).

## The altar's own view: in front of the active altar.
const ALTAR_VIEW := "altar"

## The current altar (the ring's active one, or the hall's Great Altar once it has risen).
var altar: BalanceAltar
var room_tools: Array[String] = ["bowls", "gem_bag"]
var ring: Node3D
var ring_radius := 5.0
var exposure := 1.0

var _slots := 0
var _ring_body: MultiMeshInstance3D
var _ring_crystals: MultiMeshInstance3D
var _ring_altar: BalanceAltar
var _active := 0
var _freed: Array[int] = []
## The slots whose altar at rest is hidden now (kept here: a headless renderer keeps no MultiMesh data to read back).
var _hidden_slots: Array[int] = []
var _flat := {}
var _hands := {}
var _hoot: MeshInstance3D
var _altar_names: Array[String] = []


func _init() -> void:
	super("middle")


func _ready() -> void:
	super()
	var dome := get_node_or_null("Decor/Sky") as Node3D
	if dome != null:
		dome.visible = false
	AltarKit.own_tone(env, exposure)


## The flat views the current altar is played from (one: its own).
func flat_views() -> Array[String]:
	var out: Array[String] = []
	for v: String in _flat:
		out.append(v)
	return out


## The targets a flat view shows (each tappable from there).
func flat_targets(view_name: String) -> Array[String]:
	var out: Array[String] = []
	for t: Variant in _flat.get(view_name, []):
		out.append(str(t))
	return out


## The targets the hands take or press in VR.
func hand_targets() -> Array[String]:
	var out: Array[String] = []
	for t: String in _hands:
		out.append(t)
	return out


## The view whose VR stand reaches a hand target.
func stand_for(target_name: String) -> String:
	return str(_hands.get(target_name, start_view))


## Shows the current altar holding `s` (AltarMoves.waiting `wait` risen; `is_freed`: the free).
func show_altar(s: AltarState, wait: Dictionary = {}, is_freed: bool = false) -> void:
	if altar != null:
		altar.show_state(s, wait, is_freed)


## Professor Hoot by the current altar (left of it, facing the child).
func show_hoot(on: bool) -> void:
	if _hoot == null:
		_hoot = AltarKit.hoot(self, Vector3.ZERO, 0.0, 0.5)
	_hoot.visible = on
	if on and altar != null:
		var xf := altar.global_transform if altar.is_inside_tree() else altar.transform
		var local := to_local(xf * Vector3(-altar.stand_x - 0.42, 0, 0.12))
		_hoot.position = local
		var to_child := (xf.basis * Vector3(0.35, 0, 1)).normalized()
		_hoot.rotation.y = atan2(to_child.x, to_child.z) + PI   # BlockyAnimal's owl faces -Z


# --- The ring --------------------------------------------------------------------------------------------------------

## The ring of `count` altars at `radius` round the room's middle, each facing out (its front to the walkway), and the
## full altar in the active slot. Slot 0 faces +Z before the ring turns.
func build_ring(count: int, radius: float, glimmer: String) -> void:
	_slots = count
	ring_radius = radius
	ring = Node3D.new()
	ring.name = "Ring"
	add_child(ring)
	var box := AABB(Vector3(-radius - 1.5, -0.5, -radius - 1.5), Vector3(radius * 2 + 3, 2.5, radius * 2 + 3))
	_ring_body = AltarKit.multimesh(ring, "RingAltars", BalanceAltar.ring_mesh(room_tools), AltarKit.lit(), count, box)
	_ring_crystals = AltarKit.multimesh(ring, "RingCrystals", BalanceAltar.ring_crystal_mesh(), AltarKit.glow(), count, box)
	_ring_altar = BalanceAltar.new(false, room_tools, glimmer)
	ring.add_child(_ring_altar)
	altar = _ring_altar
	set_active(0)


func slots() -> int:
	return _slots


## A slot's place in the ring (the ring's own space).
func slot_transform(i: int) -> Transform3D:
	var th := TAU * i / maxf(_slots, 1)
	return Transform3D(Basis(Vector3.UP, th), Vector3(sin(th), 0, cos(th)) * ring_radius)


## The ring turned so slot `i` stands in front of the child, its full altar there (its Glimmer `glimmer`).
func set_active(i: int, glimmer: String = "") -> void:
	_active = clampi(i, 0, maxi(_slots - 1, 0))
	ring.rotation.y = -TAU * _active / maxf(_slots, 1)
	_ring_altar.transform = slot_transform(_active)
	_ring_altar.visible = true
	_ring_altar.set_glimmer(glimmer)
	_refresh_ring()
	focus(ALTAR_VIEW, _ring_altar)


## The ring's altars whose crystals are freed (gold); the others frozen (ice blue).
func set_freed(slots_freed: Array) -> void:
	_freed.clear()
	for s: Variant in slots_freed:
		_freed.append(int(s))
	_refresh_ring()


func freed_count() -> int:
	return _freed.size()


## Whether a slot's altar at rest is hidden (the full altar stands there).
func ring_hidden(i: int) -> bool:
	return _hidden_slots.has(i)


func _refresh_ring() -> void:
	for i in _slots:
		var xf := slot_transform(i)
		var shown := not (i == _active and _ring_altar.visible)
		if i == 0:
			_hidden_slots.clear()
		if not shown:
			_hidden_slots.append(i)
		_ring_body.multimesh.set_instance_transform(i, xf if shown else AltarKit.hidden())
		var crystal := xf * Transform3D(Basis(), Vector3(-0.35, BalanceAltar.PAN_FLOOR_Y + 0.004, -0.065))
		_ring_crystals.multimesh.set_instance_transform(i, crystal if shown else AltarKit.hidden())
		_ring_crystals.multimesh.set_instance_color(i, Color(1.0, 0.8, 0.42) if _freed.has(i) else Color(0.82, 0.95, 1.0))


## The targets of `a` registered as the room's, played from `view` (its flat view, and its VR stand for the hands).
func focus(view: String, a: BalanceAltar) -> void:
	for t in _altar_names:
		targets.erase(t)
	_altar_names.clear()
	var marks := a.targets()
	for t: String in marks:
		var pair: Array = marks[t]
		add_target(t, pair[0], float(pair[1]))
		_altar_names.append(t)
	_flat = {view: _altar_names.duplicate()}
	_hands = {}
	for t in a.hand_target_names():
		_hands[t] = view
	start_view = view
	altar = a
