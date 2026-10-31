class_name AcademyBuildings
extends Node3D
## Owner #132 (W1), stage 3, and the learning places' look (2026-10-18, docs/devlog/parts/academy-look.md): the
## Discovery Academy as models (nobody can break them; nothing stamped), a landmark worth walking to. A storybook tower
## over the trees: pale stone below and cream brick above in the world's own block pictures, teal bands, four corner
## turrets with pointed teal roofs and pennants, an observatory dome with its telescope to the sky, warm windows on every
## side, a great wooden door, DISCOVER's magnifying glass glowing in a golden ring over the front, and Professor Hoot in
## his square cap perched on top, facing the spawn. Round it twelve picture-doors on a ring, one per subject family and
## Life's (AcademyIcons: no words, owner #133): pillars of brick in the subject's colour, its picture glowing on a sign
## under a little roof, both leaves standing open, warm light at the threshold and a lantern lit over it (open). A paved
## courtyard laid on the ground as it lies, lanterns round it, and the places kept for the games that come, each marked
## with its picture: the bakery's plot (beside the Maths Workshop), the Voyage Garden's bed (beside it on the other side),
## the Word Tower's scaffolding round the English door, and the temple's little island floating above with clouds for a
## stair. A world with no room: the tower alone on a small floating island. The tower and each door stand on the highest
## ground under their own footprint with a stone plinth down to lower ground (Life Town's way).
## Draws: LifeRoomDecor's three meshes (the block pictures, the lit pieces with the perched Hoot, the glowing pieces:
## bright at night with no light), all warmed. Local space: the site's middle cell's centre at its height, +Z towards
## the spawn (LifeTown's frame, turned by `facing`).

const LAYER := 1
const STONE := Color("9aa3ad")
const CREAM := Color("f1e4cc")
const TEAL := Color("139e9b")
const WINDOW := Color("ffe39a")
const CAP := Color("23263a")
const GRASS := Color("5fae4a")
const EARTH := Color("8a6a48")
const GOLD := Color("f2c95a")
const WOOD := Color("9a6a3e")
const PALE_STONE := Color("fff3de")
const PLASTER := Color("f6ead6")
const TOWER_TOP := 15.1   # over the meadows' trees: seen from the spawn
const HOOT_SCALE := 3.2
const PEDESTAL := 2.4
const SIGN_SIZE := 1.4
const SIGN_Y := 3.55
const TOWER_HALF_M := 3.0
## The courtyard's paved ring round the tower (m from its middle), and the lanterns' ring.
const PAVED_IN := 4.2
const PAVED_OUT := 6.0
const LAMP_RING := 9.6
## The places kept for the games that come (local; the bakery and the garden in the courtyard flanking the front path).
const BAKERY_AT := Vector2(2.4, 4.75)
const GARDEN_AT := Vector2(-2.4, 4.75)
const PLOT := Vector2(1.8, 1.6)
const TEMPLE_AT := Vector3(0, 26.0, -6.5)

var site := {}
var island := false
var floors := {}   # "tower" and each door -> its floor (m, from the site's height)
var solids: Array[AABB] = []
var hoot: Node3D
## Every piece of the look, a box in local space (LifeRoomDecor.pieces): the look tests read them.
var look_pieces: Array[Dictionary] = []
var _ground := Callable()
var _d: LifeRoomDecor
var _shadow_boxes: Array = []   # [centre, size, colour]: what casts the Academy's shadow


## Stands the Academy on `academy_site`; `ground` (x, z) -> the first empty y there (flat at the site's y when none).
func setup(academy_site: Dictionary, ground: Callable = Callable()) -> void:
	site = academy_site
	island = bool(site.get("island", false))
	_ground = ground if not island else Callable()
	name = "AcademyBuildings"
	var p: Vector3i = site.pos
	position = Vector3(p.x + 0.5, p.y, p.z + 0.5)
	rotation = Vector3(0, int(site.facing) * PI / 2.0, 0)
	for id: String in AcademyPlaza.SPOTS:
		floors[id] = _floor_of(id)
	_d = LifeRoomDecor.new()
	if island:
		_island()
	else:
		for id: String in AcademyPlaza.DOORS:
			_gate(id)
		_courtyard()
		_coming()
	_tower()
	_turrets()
	_top()
	look_pieces = _d.pieces
	_d.commit(self, "")
	_d = null
	var shadow := MeshInstance3D.new()   # its shadow: a few plain boxes (the drawn meshes cast none: half the triangles)
	shadow.name = "Shadow"
	shadow.mesh = LifeRoomDecor.boxes_mesh(_shadow_boxes)
	shadow.material_override = LifeRoomDecor.lit_material()
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	add_child(shadow)
	hoot = Node3D.new()   # where Hoot perches (his model is part of the lit mesh)
	hoot.name = "Hoot"
	hoot.position = Vector3(0, float(floors["tower"]) + TOWER_TOP + PEDESTAL, 0)
	hoot.rotation = Vector3(0, PI, 0)
	add_child(hoot)
	var body := StaticBody3D.new()
	body.name = "Walls"
	body.collision_layer = LAYER
	body.collision_mask = 0
	for b in solids:
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = b.size
		shape.shape = box
		shape.position = b.get_center()
		body.add_child(shape)
	add_child(body)


## A place's floor: the highest ground under its footprint (m from the site's height).
func _floor_of(id: String) -> float:
	if not _ground.is_valid():
		return 0.0
	var s: Dictionary = AcademyPlaza.SPOTS[id]
	var hi := -INF
	for lx in range((s.min as Vector2i).x, (s.max as Vector2i).x + 1):
		for lz in range((s.min as Vector2i).y, (s.max as Vector2i).y + 1):
			var w := AcademyPlaza.to_world(site, Vector2i(lx, lz))
			hi = maxf(hi, float(_ground.call(w.x, w.y)))
	return hi - float((site.pos as Vector3i).y)


func _ground_at(local: Vector2) -> float:
	if not _ground.is_valid():
		return 0.0
	var w := AcademyPlaza.to_world(site, Vector2i(local.floor()))
	return float(_ground.call(w.x, w.y)) - float((site.pos as Vector3i).y)


## A solid box between two corners (local): the walls' collision, and its shadow.
func _solid(lo: Vector3, hi: Vector3) -> void:
	solids.append(AABB(lo, hi - lo))
	_shadow_box(lo, hi)


## A box between two corners (local) in the Academy's shadow.
func _shadow_box(lo: Vector3, hi: Vector3) -> void:
	_shadow_boxes.append([(lo + hi) * 0.5, hi - lo, Color.WHITE])


## An AcademyIcons picture glowing on a face of frame `t`: the picture's square `side` metres wide, its middle at `middle`
## (the frame's x right, y up), standing `out` in front of the face (+Z).
func _picture(piece: String, t: Transform3D, picture: String, middle: Vector2, side: float, out: float) -> void:
	for e: Array in AcademyIcons.PICTURES.get(picture, []):
		var c: Color = Color.WHITE if e[5] == null else e[5]
		var at := Vector3(middle.x + (float(e[0]) - 0.5) * side, middle.y + (0.5 - float(e[1])) * side, out)
		_d.glow_box_basis(piece, Vector3(float(e[2]) * side, float(e[3]) * side, 0.03),
			t * Transform3D(Basis(Vector3(0, 0, 1), -deg_to_rad(float(e[4]))), at), c)


## A board on a post facing +Z of `t` with `picture` glowing on it (a place's "coming soon": a picture, never words).
func _board(piece: String, t: Transform3D, picture: String, colour: Color, height: float) -> void:
	_d.box_basis(piece + "_Post", Vector3(0.1, height, 0.1), t * Transform3D(Basis(), Vector3(0, height * 0.5, -0.08)), WOOD)
	_d.box_basis(piece + "_Board", Vector3(0.9, 0.8, 0.07), t * Transform3D(Basis(), Vector3(0, height + 0.25, 0)), colour)
	_d.box_basis(piece + "_Frame", Vector3(1.0, 0.9, 0.05), t * Transform3D(Basis(), Vector3(0, height + 0.25, -0.03)), GOLD)
	_picture(piece + "_Picture", t, picture, Vector2(0, height + 0.25), 0.62, 0.05)


# --- The tower ------------------------------------------------------------------------------------------------------

func _tower() -> void:
	var f := float(floors["tower"])
	var h := TOWER_HALF_M
	if not island:   # the island's own rock is under it
		_d.box("Plinth", Vector3(2 * h + 1.0, LifeTown.PLINTH_DEPTH, 2 * h + 1.0),
			Vector3(0, f - LifeTown.PLINTH_DEPTH * 0.5, 0), Color("b9b3a8"), 0.0, LifeRoomDecor.SHELL)
	# the walls: pale stone, cream brick above, pale stone at the top; teal bands between
	var levels := [[0.0, 4.0, h, "WallGround"], [4.35, 11.0, h - 0.25, "WallMiddle"], [11.35, 14.6, h - 0.5, "WallTop"]]
	for lv: Array in levels:
		var w: float = lv[2]
		var y0: float = lv[0]
		var y1: float = lv[1]
		if str(lv[3]) == "WallGround":   # a base of the world's own stone blocks (both styles: pale or grey stone)
			_d.tiled(str(lv[3]), LifeRoomDecor.SLABS, Vector3(2 * w, y1 - y0, 2 * w), Vector3(0, f + (y0 + y1) * 0.5, 0),
				PALE_STONE, 1.0)
		else:   # smooth cream plaster above (the realistic page's stone read dark up there)
			_d.box(str(lv[3]), Vector3(2 * w, y1 - y0, 2 * w), Vector3(0, f + (y0 + y1) * 0.5, 0), PLASTER, 0.0,
				LifeRoomDecor.SHELL)
		_solid(Vector3(-w, f + y0, -w), Vector3(w, f + y1, w))
	for band: Array in [[4.0, 4.35, h + 0.15], [11.0, 11.35, h - 0.05], [14.6, TOWER_TOP, h - 0.05]]:
		var w: float = band[2]
		_d.box("Band", Vector3(2 * w, float(band[1]) - float(band[0]), 2 * w),
			Vector3(0, f + (float(band[0]) + float(band[1])) * 0.5, 0), TEAL, 0.0, LifeRoomDecor.SHELL)
		_solid(Vector3(-w, f + float(band[0]), -w), Vector3(w, f + float(band[1]), w))
	_d.glow_box("GlowBand", Vector3(2 * (h - 0.47), 0.12, 2 * (h - 0.47)), Vector3(0, f + 14.5, 0), WINDOW)
	# battlements round the roof
	var edge := h - 0.05
	for k in 6:
		var x := -edge + 0.25 + k * (2.0 * edge - 0.5) / 5.0
		for side: float in [-1.0, 1.0]:
			_d.box("Battlement", Vector3(0.5, 0.45, 0.5), Vector3(x, f + TOWER_TOP + 0.225, side * (edge - 0.25)), CREAM)
			_d.box("Battlement", Vector3(0.5, 0.45, 0.5), Vector3(side * (edge - 0.25), f + TOWER_TOP + 0.225, x), CREAM)
	# warm windows on every side: two a floor below, one great arched window at the top
	for face in 4:
		var t := Transform3D(Basis(Vector3.UP, face * PI / 2.0), Vector3(0, f, 0))
		for row: Array in [[1.9, h], [6.0, h - 0.25], [9.2, h - 0.25]]:
			for x: float in [-1.75, 1.75]:
				_window(t, Vector3(x, float(row[0]), float(row[1])), Vector2(0.72, 1.12))
		_window(t, Vector3(0, 12.95, h - 0.5), Vector2(1.3, 1.9))
		for s: float in [-1.0, 1.0]:   # the great window's arch
			_d.glow_box_basis("Window", Vector3(0.34, 0.16, 0.04), t * Transform3D(Basis(), Vector3(s * 0.33, 14.0, h - 0.48)),
				WINDOW)
		_d.glow_box_basis("Window", Vector3(0.38, 0.14, 0.04), t * Transform3D(Basis(), Vector3(0, 14.13, h - 0.48)), WINDOW)
	# the great door at the front, its stepped stone arch, the warm light over it and a doorstep
	_d.tiled("Door", LifeRoomDecor.PLANKS, Vector3(1.7, 2.7, 0.12), Vector3(0, f + 1.35, h + 0.05), Color("c58a55"), 0.5,
		0.0, LifeRoomDecor.DECOR)
	for k in 3:
		var w := 2.3 - k * 0.45
		_d.box("DoorArch", Vector3(w, 0.22, 0.2), Vector3(0, f + 2.8 + k * 0.22, h + 0.1), CREAM)
	_d.glow_box("DoorLight", Vector3(1.2, 0.3, 0.05), Vector3(0, f + 3.0, h + 0.13), WINDOW)
	for x: float in [-0.25, 0.25]:
		_d.box("DoorKnob", Vector3(0.08, 0.08, 0.08), Vector3(x, f + 1.3, h + 0.14), GOLD)
	_d.tiled("Doorstep", LifeRoomDecor.SLABS, Vector3(2.2, 0.12, 0.7), Vector3(0, f + 0.06, h + 0.35), Color("efe6d6"), 1.0)
	# DISCOVER's magnifying glass over the front, in a golden ring on a dark teal ground
	var front := Transform3D(Basis.IDENTITY, Vector3(0, f, 0))
	var mid := Vector2(0, 7.6)
	for k in 2:
		_d.box_basis("Emblem", Vector3(2.3, 2.3, 0.05), front * Transform3D(Basis(Vector3(0, 0, 1), k * PI / 4.0),
			Vector3(mid.x, mid.y, h - 0.2)), Color("1d6f6d"))
	for k in 8:
		var a := k * PI / 4.0 + PI / 8.0
		_d.box_basis("EmblemRing", Vector3(1.0, 0.16, 0.08), front * Transform3D(Basis(Vector3(0, 0, 1), a + PI / 2.0),
			Vector3(mid.x + cos(a) * 1.27, mid.y + sin(a) * 1.27, h - 0.18)), GOLD)
	_picture("Emblem_Picture", front, "discover", mid, 2.05, h - 0.14)


## A warm window in frame `t` at `at` (its middle on the wall's face at z), `size` wide and high: a pale frame, the glow,
## its cross bars and a sill.
func _window(t: Transform3D, at: Vector3, size: Vector2) -> void:
	_d.box_basis("WindowFrame", Vector3(size.x + 0.18, size.y + 0.18, 0.06), t * Transform3D(Basis(), at + Vector3(0, 0, 0.03)),
		Color("fbf6ec"))
	_d.glow_box_basis("Window", Vector3(size.x, size.y, 0.04), t * Transform3D(Basis(), at + Vector3(0, 0, 0.05)), WINDOW)
	_d.box_basis("WindowBar", Vector3(0.05, size.y, 0.03), t * Transform3D(Basis(), at + Vector3(0, 0, 0.075)), Color("fbf6ec"))
	_d.box_basis("WindowBar", Vector3(size.x, 0.05, 0.03), t * Transform3D(Basis(), at + Vector3(0, size.y * 0.12, 0.075)),
		Color("fbf6ec"))
	_d.box_basis("WindowSill", Vector3(size.x + 0.3, 0.08, 0.2), t * Transform3D(Basis(), at + Vector3(0, -size.y * 0.5 - 0.12,
		0.08)), CREAM)


## Four corner turrets rising from the first band to over the roof: round, cream, pointed teal roofs, slit windows
## glowing, a pennant on each tip in a subject's colour.
func _turrets() -> void:
	var f := float(floors["tower"])
	var pennants := [Color("e8544e"), Color("3a7be8"), Color("ffcf3a"), Color("2fae4e")]
	var k := 0
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			var c := Vector3(sx * 2.62, 0, sz * 2.62)
			var out := Vector3(sx, 0, sz).normalized()
			_d.cylinder("TurretCorbel", 0.15, 0.9, c + Vector3(0, f + 3.9, 0), CREAM.darkened(0.08), 0.72, 8)
			_d.cylinder("Turret", 0.72, 12.0, c + Vector3(0, f + 10.35, 0), CREAM, -1.0, 8)
			_shadow_box(c + Vector3(-0.6, f + 4.35, -0.6), c + Vector3(0.6, f + 18.4, 0.6))
			_d.cylinder("TurretBand", 0.8, 0.22, c + Vector3(0, f + 16.25, 0), TEAL, -1.0, 8)
			_d.cylinder("TurretRoof", 0.95, 2.6, c + Vector3(0, f + 17.66, 0), TEAL, 0.0, 8)
			for y: float in [7.8, 12.6]:
				_d.glow_box("TurretWindow", Vector3(0.2, 0.62, 0.2), c + out * 0.66 + Vector3(0, f + y, 0), WINDOW)
			_d.box("PennantPole", Vector3(0.05, 0.9, 0.05), c + Vector3(0, f + 19.35, 0), Color("4a4f60"))
			_d.box("Pennant", Vector3(0.04, 0.32, 0.55), c + Vector3(0, f + 19.6, 0.3 * sz), pennants[k])
			k += 1


## The roof: an observatory dome with its slit and telescope, a glowing ring at its foot, and Hoot's perch on its top
## with Professor Hoot himself (part of the lit mesh: he never moves there), turned to the spawn.
func _top() -> void:
	var f := float(floors["tower"])
	var top := f + TOWER_TOP
	_d.ball("Dome", 1.75, Vector3(0, top, 0), Color("3aa99f"), Vector3.ONE, LifeRoomDecor.DECOR, false, 8, 14)
	_d.cylinder("DomeRing", 1.82, 0.14, Vector3(0, top + 0.07, 0), WINDOW, -1.0, 14, LifeRoomDecor.DECOR, true)
	_d.box_basis("DomeSlit", Vector3(0.38, 1.25, 0.08), Transform3D(Basis(Vector3.RIGHT, -0.97), Vector3(0, top + 1.49, 1.01)),
		Color("23263a"))
	var tube := Transform3D(Basis(Vector3.UP, 0.3) * Basis(Vector3.RIGHT, -0.75), Vector3(0, top + 1.55, 1.25))
	_d.box_basis("Telescope", Vector3(0.34, 0.34, 2.3), tube, Color("2d3550"))
	for z: float in [-0.5, 0.45]:
		_d.box_basis("TelescopeRing", Vector3(0.42, 0.42, 0.1), tube * Transform3D(Basis(), Vector3(0, 0, z)), GOLD)
	_d.glow_box_basis("TelescopeLens", Vector3(0.26, 0.26, 0.04), tube * Transform3D(Basis(), Vector3(0, 0, 1.17)),
		Color("bfe9ff"))
	var perch := top + PEDESTAL
	_d.box("Perch", Vector3(0.72, perch - (top + 1.6), 0.72), Vector3(0, (perch + top + 1.6) * 0.5, 0), TEAL)
	_d.box("PerchTop", Vector3(0.95, 0.1, 0.95), Vector3(0, perch - 0.05, 0), GOLD)
	HootModel.add_to(_d, "Hoot", Transform3D(Basis(Vector3.UP, PI), Vector3(0, perch, 0)), HOOT_SCALE)
	_shadow_box(Vector3(-1.3, top, -1.3), Vector3(1.3, top + 1.5, 1.3))   # the dome
	_shadow_box(Vector3(-0.5, top + 1.5, -0.5), Vector3(0.5, perch + 2.3, 0.5))   # the perch and Hoot


# --- The doors ------------------------------------------------------------------------------------------------------

## A picture-door on the ring for door `id`, facing out: a stone plinth, pillars of brick in its subject's colour, a
## lintel, its picture glowing on a sign under a little roof, a lantern lit on top (open), both leaves standing open
## into the courtyard with warm light at the threshold, and a paved square where to walk up.
func _gate(id: String) -> void:
	var s: Dictionary = AcademyPlaza.SPOTS[id]
	var a := deg_to_rad(float(s.angle))
	var dir := Vector3(cos(a), 0.0, sin(a))
	var f := float(floors[id])
	var t := Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.z)), dir * AcademyPlaza.RING + Vector3(0, f, 0))
	var colour := _colour(str(s.subject))
	_d.box_basis(id + "_Plinth", Vector3(3.2, LifeTown.PLINTH_DEPTH, 1.6),
		t * Transform3D(Basis(), Vector3(0, -LifeTown.PLINTH_DEPTH * 0.5, 0)), Color("b9b3a8"), LifeRoomDecor.SHELL)
	_d.tiled_basis(id + "_Step", LifeRoomDecor.SLABS, Vector3(2.5, 0.1, 1.3), t * Transform3D(Basis(), Vector3(0, 0.05, 0)),
		Color("efe6d6"))
	for x: float in [-1.05, 1.05]:
		_d.tiled_basis(id + "_PillarFoot", LifeRoomDecor.SLABS, Vector3(0.55, 0.5, 0.6),
			t * Transform3D(Basis(), Vector3(x, 0.35, 0)), PALE_STONE, 0.5)
		_gate_part(id, t, "Pillar", Vector3(0.45, 2.0, 0.5), Vector3(x, 1.6, 0), colour.lightened(0.15))
		_gate_part(id, t, "Capital", Vector3(0.6, 0.18, 0.62), Vector3(x, 2.69, 0), colour.darkened(0.15))
	_gate_part(id, t, "Lintel", Vector3(2.75, 0.32, 0.62), Vector3(0, 2.94, 0), colour)
	for box: Array in [[Vector3(-1.05, 1.4, 0), Vector3(0.45, 2.8, 0.5)], [Vector3(1.05, 1.4, 0), Vector3(0.45, 2.8, 0.5)],
			[Vector3(0, 3.6, 0.1), Vector3(2.0, 1.9, 0.4)]]:
		_shadow_boxes.append([t * (box[0] as Vector3), box[1], Color.WHITE, t.basis])
	# the sign: a golden frame, the subject's colour, the picture glowing; a little roof over it and a lantern on top
	_gate_part(id, t, "SignFrame", Vector3(SIGN_SIZE + 0.4, SIGN_SIZE + 0.3, 0.1), Vector3(0, SIGN_Y, 0.12), GOLD)
	_gate_part(id, t, "Sign", Vector3(SIGN_SIZE + 0.22, SIGN_SIZE + 0.12, 0.12), Vector3(0, SIGN_Y, 0.16), colour)
	_picture(id + "_Picture", t, str(s.picture), Vector2(0, SIGN_Y), SIGN_SIZE, 0.25)
	for side: float in [-1.0, 1.0]:
		_gate_part(id, t, "Roof", Vector3(1.25, 0.12, 0.5), Vector3(side * 0.52, SIGN_Y + 0.98, 0.12), colour.darkened(0.3),
			Basis(Vector3(0, 0, 1), -side * 0.5))
	_gate_part(id, t, "LanternBase", Vector3(0.34, 0.08, 0.34), Vector3(0, SIGN_Y + 1.27, 0.12), Color("4a4f60"))
	_d.glow_box_basis(id + "_Lantern", Vector3(0.26, 0.32, 0.26), t * Transform3D(Basis(), Vector3(0, SIGN_Y + 1.47, 0.12)),
		Color("ffe08a"))
	_gate_part(id, t, "LanternCap", Vector3(0.36, 0.08, 0.36), Vector3(0, SIGN_Y + 1.67, 0.12), Color("4a4f60"))
	# both leaves standing open into the courtyard, warm light on the threshold
	var open := 1.25
	for side: float in [-1.0, 1.0]:
		var hinge := Vector3(side * 0.825, 0, -0.2)
		var along := Vector3(-side * cos(open), 0, -sin(open))
		var leaf := t * Transform3D(Basis(Vector3.UP, -side * open), hinge + along * 0.4 + Vector3(0, 1.25, 0))
		_d.box_basis(id + "_Leaf", Vector3(0.8, 2.3, 0.08), leaf, colour.lightened(0.45))
		_d.box_basis(id + "_DoorPanel", Vector3(0.56, 0.9, 0.1), leaf * Transform3D(Basis(), Vector3(0, 0.45, 0)),
			colour.lightened(0.25))
		_d.box_basis(id + "_DoorPanel", Vector3(0.56, 0.7, 0.1), leaf * Transform3D(Basis(), Vector3(0, -0.6, 0)),
			colour.lightened(0.25))
	_d.glow_box_basis(id + "_Threshold", Vector3(1.6, 0.03, 0.45), t * Transform3D(Basis(), Vector3(0, 0.115, 0)),
		Color("ffe7a6"))
	# where to walk up: a paved square in the subject's colour
	var door: Vector2 = s.door
	var g := _ground_at(door)
	_d.tiled(id + "_WalkUp", LifeRoomDecor.SLABS, Vector3(1.4, 0.06, 1.4), Vector3(door.x, g + 0.03, door.y),
		colour.lightened(0.5), 1.4)


## A lit part of door `id`'s gate in its frame `t` (turned a further `extra`).
func _gate_part(id: String, t: Transform3D, n: String, size: Vector3, at: Vector3, c: Color, extra: Basis = Basis.IDENTITY) -> void:
	_d.box_basis(id + "_" + n, size, t * Transform3D(extra, at), c)


# --- The courtyard --------------------------------------------------------------------------------------------------

## The courtyard: a paved ring round the tower, the front path to the spawn's side and a way through each door, each
## slab on its own ground (as the meadow lies); a lantern between each two doors.
func _courtyard() -> void:
	var kept := _kept_cells()
	for cx in range(AcademyPlaza.PLAZA_MIN.x, AcademyPlaza.PLAZA_MAX.x + 1):
		for cz in range(AcademyPlaza.PLAZA_MIN.y, AcademyPlaza.PLAZA_MAX.y + 1):
			var cell := Vector2i(cx, cz)
			if kept.has(cell):
				continue
			var r := Vector2(cx, cz).length()
			var way := r >= PAVED_IN and r <= PAVED_OUT
			if absi(cx) <= 1 and cz >= TOWER_HALF_M + 1:
				way = true   # the front path
			for door: String in AcademyPlaza.DOORS:
				var d: Vector2 = (AcademyPlaza.SPOTS[door].door as Vector2).normalized()
				var along := Vector2(cx, cz).dot(d)
				if along > PAVED_OUT - 0.5 and along < AcademyPlaza.DOOR_RING + 0.6 \
						and absf(Vector2(cx, cz).dot(Vector2(-d.y, d.x))) <= 0.75:
					way = true   # the way through the door
			if not way:
				continue
			var g := _ground_at(Vector2(cx, cz))
			_d.tiled("Paving", LifeRoomDecor.SLABS, Vector3(1.0, 0.06, 1.0), Vector3(cx, g + 0.03, cz),
				Color("f3e8d3") if r <= PAVED_OUT + 0.1 else Color("eadcc4"), 1.0)
	for door: String in AcademyPlaza.DOORS:
		var a := deg_to_rad(float(AcademyPlaza.SPOTS[door].angle) + 15.0)
		var at := Vector2(cos(a), sin(a)) * LAMP_RING
		_d.street_lamp("Lamp", Vector3(at.x, _ground_at(at), at.y), 2.6, Color("3d4a5c"))


## The cells the paving keeps off: the tower's and the doors' own footprints, the bakery's and the garden's plots.
func _kept_cells() -> Dictionary:
	var out := {}
	for id: String in AcademyPlaza.SPOTS:
		var s: Dictionary = AcademyPlaza.SPOTS[id]
		for lx in range((s.min as Vector2i).x, (s.max as Vector2i).x + 1):
			for lz in range((s.min as Vector2i).y, (s.max as Vector2i).y + 1):
				out[Vector2i(lx, lz)] = true
	for at: Vector2 in [BAKERY_AT, GARDEN_AT]:
		for lx in range(floori(at.x - PLOT.x * 0.5 + 0.5), ceili(at.x + PLOT.x * 0.5 - 0.5) + 1):
			for lz in range(floori(at.y - PLOT.y * 0.5 + 0.5), ceili(at.y + PLOT.y * 0.5 - 0.5) + 1):
				out[Vector2i(lx, lz)] = true
	return out


# --- The places kept for the games that come -------------------------------------------------------------------------

## The bakery's plot beside the Maths Workshop (bread), the Voyage Garden's bed on the front path's other side (a leaf),
## the Word Tower's scaffolding round the English door (a book), the temple's island floating above with clouds for a
## stair (a balance): pictures, never words; each local to the child's world, like the crystals.
func _coming() -> void:
	# the bakery's plot: posts and beams of a frame going up, a stack of bricks, its picture
	var b := Vector3(BAKERY_AT.x, _ground_at(BAKERY_AT), BAKERY_AT.y)
	_d.tiled("Bakery_Plot", LifeRoomDecor.DIRT, Vector3(PLOT.x, 0.08, PLOT.y), b + Vector3(0, 0.04, 0), Color("c9a27a"), 1.0)
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_d.box("Bakery_Post", Vector3(0.1, 2.2, 0.1), b + Vector3(sx * (PLOT.x * 0.5 - 0.1), 1.1, sz * (PLOT.y * 0.5 - 0.1)),
				WOOD)
		_d.box("Bakery_Beam", Vector3(0.1, 0.1, PLOT.y - 0.1), b + Vector3(sx * (PLOT.x * 0.5 - 0.1), 2.15, 0), WOOD)
	_d.box("Bakery_Beam", Vector3(PLOT.x - 0.1, 0.1, 0.1), b + Vector3(0, 2.15, 0), WOOD)
	_d.tiled("Bakery_Bricks", LifeRoomDecor.BRICK, Vector3(0.6, 0.4, 0.4), b + Vector3(-0.35, 0.28, -0.3), Color.WHITE, 0.5,
		0.0, LifeRoomDecor.DECOR)
	_board("Bakery", Transform3D(Basis(), b + Vector3(0.3, 0, PLOT.y * 0.5 - 0.15)), "bread", Color("e8834a"), 0.9)
	# the Voyage Garden's bed: dark earth, sprouts, a little white fence, its picture
	var g := Vector3(GARDEN_AT.x, _ground_at(GARDEN_AT), GARDEN_AT.y)
	_d.tiled("Garden_Bed", LifeRoomDecor.DIRT, Vector3(PLOT.x, 0.14, PLOT.y), g + Vector3(0, 0.07, 0), Color("a88466"), 1.0)
	for i in 6:
		var at := g + Vector3(-0.55 + (i % 3) * 0.55, 0.14, -0.35 + (i / 3) * 0.7)
		_d.box("Garden_Stem", Vector3(0.04, 0.22, 0.04), at + Vector3(0, 0.11, 0), Color("4f9a3e"))
		_d.ball("Garden_Sprout", 0.09, at + Vector3(0.05, 0.25, 0), Color("7cd05a"), Vector3(1.0, 0.5, 0.7),
			LifeRoomDecor.DECOR, false, 3, 6)
		_d.ball("Garden_Sprout", 0.08, at + Vector3(-0.05, 0.2, 0), Color("6cc24a"), Vector3(1.0, 0.5, 0.7),
			LifeRoomDecor.DECOR, false, 3, 6)
	for sx: float in [-1.0, 1.0]:
		_d.box("Garden_Fence", Vector3(0.05, 0.3, PLOT.y), g + Vector3(sx * PLOT.x * 0.5, 0.15, 0), Color("fbf6ec"))
	_d.box("Garden_Fence", Vector3(PLOT.x, 0.3, 0.05), g + Vector3(0, 0.15, -PLOT.y * 0.5), Color("fbf6ec"))
	_board("Garden", Transform3D(Basis(), g + Vector3(-0.3, 0, PLOT.y * 0.5 - 0.15)), "leaf", Color("2fae4e"), 0.9)
	# the Word Tower's scaffolding round the English door (the door becomes its door)
	var s: Dictionary = AcademyPlaza.SPOTS["english"]
	var a := deg_to_rad(float(s.angle))
	var dir := Vector3(cos(a), 0.0, sin(a))
	var t := Transform3D(Basis(Vector3.UP, atan2(dir.x, dir.z)), dir * AcademyPlaza.RING + Vector3(0, float(floors["english"]), 0))
	for x: float in [-1.55, 1.55]:
		for z: float in [-0.6, 0.6]:
			_d.box_basis("WordTower_Pole", Vector3(0.09, 6.6, 0.09), t * Transform3D(Basis(), Vector3(x, 3.3, z)), WOOD)
		_d.box_basis("WordTower_Brace", Vector3(0.06, 1.6, 0.06), t * Transform3D(Basis(Vector3(1, 0, 0), 0.62),
			Vector3(x, 4.4, 0)), WOOD.darkened(0.1))
	for y: float in [5.3, 6.5]:
		_d.box_basis("WordTower_Plank", Vector3(3.3, 0.07, 1.35), t * Transform3D(Basis(), Vector3(0, y, 0)), Color("c89a62"))
	for k in 3:
		_d.tiled_basis("WordTower_Stones", LifeRoomDecor.STONE, Vector3(0.5, 0.5, 0.5),
			t * Transform3D(Basis(), Vector3(-1.55 + (k % 2) * 3.1, 0.25 + (k / 2) * 0.5, 1.0)), PALE_STONE, 0.5)
	_board("WordTower", t * Transform3D(Basis(), Vector3(0, 6.5, 0.4)), "book", Color("3a7be8"), 0.15)
	# the temple's little island floating above, a column or two begun, clouds stepping down from it
	var f := float(floors["tower"])
	var isle := Vector3(TEMPLE_AT.x, f + TEMPLE_AT.y, TEMPLE_AT.z)
	_d.tiled("Temple_Grass", LifeRoomDecor.GRASS, Vector3(4.2, 0.6, 4.2), isle + Vector3(0, -0.3, 0), Color("dcefc8"), 1.0,
		0.0, LifeRoomDecor.DECOR)
	_d.tiled("Temple_Earth", LifeRoomDecor.DIRT, Vector3(3.4, 1.2, 3.4), isle + Vector3(0, -1.2, 0), Color.WHITE, 1.0, 0.0,
		LifeRoomDecor.DECOR)
	_d.tiled("Temple_Rock", LifeRoomDecor.STONE, Vector3(2.2, 1.4, 2.2), isle + Vector3(0, -2.5, 0), Color.WHITE, 1.0, 0.0,
		LifeRoomDecor.DECOR)
	_d.tiled("Temple_Rock", LifeRoomDecor.STONE, Vector3(1.0, 1.2, 1.0), isle + Vector3(0, -3.8, 0), Color.WHITE, 1.0, 0.0,
		LifeRoomDecor.DECOR)
	_d.box("Temple_Floor", Vector3(3.0, 0.2, 3.0), isle + Vector3(0, 0.1, 0), Color("fbf6ec"))
	for c: Vector2 in [Vector2(-1.2, -1.2), Vector2(1.2, -1.2), Vector2(-1.2, 1.2)]:
		var tall := 2.2 if c.y < 0.0 else 0.9   # the back pair stands; the front one is begun
		_d.cylinder("Temple_Column", 0.22, tall, isle + Vector3(c.x, 0.2 + tall * 0.5, c.y), Color("fbf6ec"), -1.0, 10)
	_d.box("Temple_Lintel", Vector3(3.0, 0.26, 0.5), isle + Vector3(0, 2.53, -1.2), Color("fbf6ec"))
	_board("Temple", Transform3D(Basis(), isle + Vector3(1.0, 0.2, 1.4)), "scales", Color("7b5cd6"), 0.6)
	var steps := [Vector3(2.4, -0.8, -0.2), Vector3(3.7, -2.2, 0.9), Vector3(4.6, -3.7, 2.3), Vector3(5.0, -5.2, 3.9),
		Vector3(4.9, -6.7, 5.5)]
	for k in steps.size():
		var at: Vector3 = isle + (steps[k] as Vector3)
		_d.ball("Temple_Cloud", 0.75, at, Color("fbfdff"), Vector3(1.3, 0.45, 1.0), LifeRoomDecor.DECOR, false, 4, 8)
		_d.ball("Temple_Cloud", 0.5, at + Vector3(0.45, 0.12, 0.2), Color("f2f7ff"), Vector3(1.2, 0.5, 1.0),
			LifeRoomDecor.DECOR, false, 4, 8)


# --- The island -----------------------------------------------------------------------------------------------------

## No room on the ground: the tower on a small floating island (grass, earth, rock) in the world's own pictures.
func _island() -> void:
	_d.tiled("Island_Grass", LifeRoomDecor.GRASS, Vector3(11.0, 1.2, 11.0), Vector3(0, -0.6, 0), Color("dcefc8"), 1.0)
	_solid(Vector3(-5.5, -1.2, -5.5), Vector3(5.5, 0.0, 5.5))
	_d.tiled("Island_Earth", LifeRoomDecor.DIRT, Vector3(9.0, 2.0, 9.0), Vector3(0, -2.2, 0), Color.WHITE, 1.0)
	_d.tiled("Island_Rock", LifeRoomDecor.STONE, Vector3(5.6, 2.2, 5.6), Vector3(0, -4.3, 0), Color.WHITE, 1.0)
	_d.tiled("Island_Rock", LifeRoomDecor.STONE, Vector3(2.4, 1.4, 2.4), Vector3(0, -6.1, 0), Color.WHITE, 1.0)


static func _colour(subject: String) -> Color:
	if subject == "life":
		return LifeCards.COLOUR
	return SchoolUi.SUBJECT_COLORS.get(subject, TEAL)
