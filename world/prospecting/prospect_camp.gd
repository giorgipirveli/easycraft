class_name ProspectCamp
extends Node3D
## Gemma the geologist's camp (spec §26.2): a short walk from the world spawn in Green Meadows and the Sandstorm Desert
## (every home world with deposits), found from the seed alone like the quest givers (the same place on every game of
## the world): a canvas tent in the brand's teal and orange, a folding table with her map, a crate of rock samples, a
## pick and a little flag, and Gemma herself (a hard hat, an orange vest, a hand lens) who turns to a child coming near
## and waves. Walking up to her opens her board (ProspectDirector). Cheap: three meshes of vertex-coloured boxes with
## the Theater's shared material (ProspectModels), no collision (children walk round it), nothing per frame but her
## wave and a turn. Spec §26.5: on the Moon and Mars her space camp by the landing pad, off the colony's ground and clear
## of the landmark and the way to it: Gemma in a white spacesuit (a helmet with a golden visor, her orange vest over
## it), a little white habitat with a round window instead of the tent, a sample table, a crate and an ice drill.

const RADII: Array[int] = [23, 24, 22, 25, 21, 26]
const ANGLE_STEPS := 48
const CLEAR_OF := 7.0             # this far from Tilly's stall, the Totem, the hub circle, the Theater, a helper, the pad
const WAY_CLEAR := 4.0            # this far off the straight way from the spawn to each of them
const TREE_CLEAR := 3
const BOARD_REACH := 3.4          # walking up this close to Gemma opens her board
const BOARD_HIGH := 4.0
const GREET := 9.0
const BUBBLE_Y := 2.7

var gemma := Node3D.new()
var bubble := Label3D.new()
## Spec §26.5: the space camp (a spacesuit and a habitat).
var space := false
var _arm := Node3D.new()
var _time := 0.0
var _greeting := false
var _look := 0.0
var _turn := 0.0
## () -> Vector3: the local player's feet (INF: none): Gemma looks at a child near her.
var player_position: Callable = func() -> Vector3: return Vector3.INF


## Where the camp stands: {pos: Vector3 (Gemma's feet), yaw (her front towards the spawn)}. The first ring cell (22-26
## blocks out) on dry, level ground clear of trees, of the landmarks and of the straight ways to them; with none, the
## first cell clear of the landmarks.
static func spot(world_seed: int, spawn: Vector2i, height_at: Callable, ground_ok: Callable, tree_at: Callable,
		landmarks: Array[Vector3]) -> Dictionary:
	var start := absi(world_seed * 92821 ^ 55441) % ANGLE_STEPS
	for strict in [true, false]:
		for r in RADII:
			for i in ANGLE_STEPS:
				var a := TAU * float((start + i) % ANGLE_STEPS) / ANGLE_STEPS
				var c := spawn + Vector2i(roundi(cos(a) * r), roundi(sin(a) * r))
				if not _clear(c, spawn, landmarks):
					continue
				if strict and not _good(c, height_at, ground_ok, tree_at):
					continue
				var d := Vector2(spawn - c)
				return {"pos": Vector3(c.x + 0.5, float(height_at.call(c.x, c.y)), c.y + 0.5), "yaw": atan2(-d.x, -d.y)}
	var c0 := spawn + Vector2i(RADII[0], 0)
	return {"pos": Vector3(c0.x + 0.5, float(height_at.call(c0.x, c0.y)), c0.y + 0.5), "yaw": 0.0}


## The camp in a real world: its landmarks are the quest givers' (Tilly's stall, the Totem, the hub circle, the
## Theater), the universe's helper and the Launch Site's pad when there is one.
static func spot_for_world(world_seed: int, shape: MeadowsShape, spawn: Vector2i, universe: int, launch_pad: Vector3) -> Dictionary:
	if shape is SpaceShape:
		return space_spot(world_seed, shape as SpaceShape, spawn)
	var caves := CaveShape.new(world_seed)
	var ground_ok := func(x: int, z: int) -> bool:
		return shape.height_at(x, z) > MeadowsShape.SEA_LEVEL + 1 and not shape.is_river(x, z) and not caves.entrance_open(x, z)
	var marks := QuestRules.landmarks(world_seed, shape, spawn)
	if universe != 1 and QuestRules.giver_in(universe) != &"":
		marks.append(QuestRules.giver_for_world(world_seed, shape, spawn).pos)
	if launch_pad.is_finite():
		marks.append(launch_pad)
	return spot(world_seed, spawn, shape.height_at, ground_ok, shape.tree_at, marks)


## Spec §26.5: the space camp on the Moon or Mars: off the colony's ground (and 6 more), clear of the quest givers'
## places (the Theater's whole building), the planet's landmark, the aliens' camp and the colony's airlock and of the
## straight ways to them. {pos, yaw, space: true}.
static func space_spot(world_seed: int, sp: SpaceShape, spawn: Vector2i) -> Dictionary:
	var marks := QuestRules.landmarks(world_seed, sp, spawn)
	var theater := TheaterSite.pick_for(sp)
	if not theater.is_empty():   # its 9 × 9 building's corners too (the camp's props reach 4 blocks behind Gemma)
		var mid := Vector3(theater.pos as Vector3i) + Vector3(0.5, 0.0, 0.5)
		var k := float(TheaterSite.HALF + 2)
		for c: Vector3 in [Vector3(-k, 0, -k), Vector3(k, 0, -k), Vector3(-k, 0, k), Vector3(k, 0, k)]:
			marks.append(mid + c)
	var landmark: Dictionary = SpaceSecretRules.new(world_seed, sp).landmark()
	if not landmark.is_empty():
		marks.append(Vector3(landmark.anchor as Vector3i))
	var aliens := alien_camp(world_seed, sp, landmark)
	if not aliens.is_empty():   # the aliens' camp (SpaceCreatures: a 9 × 9 camp 27-50 blocks out), its corners too
		var at: Vector3 = aliens.pos
		marks.append(at)
		var k := float(AlienRules.CAMP_HALF + 2)
		for c: Vector3 in [Vector3(-k, 0, -k), Vector3(k, 0, -k), Vector3(-k, 0, k), Vector3(k, 0, k)]:
			marks.append(at + c)
	if sp.colony != null:
		var door := sp.colony.entrance()
		marks.append(Vector3(door.x + 0.5, sp.height_at(door.x, door.y), door.y + 0.5))
	var ground_ok := func(x: int, z: int) -> bool:
		return not sp.is_river(x, z) and (sp.colony == null or not sp.colony.covers(x, z, 6))
	var out := spot(world_seed, spawn, sp.height_at, ground_ok, sp.tree_at, marks)
	out.space = true
	return out


## Where the planet's travelling aliens camp (SpaceCreatures' own site: AlienRules.site with its landmark and sights
## kept clear), {} on a world without a camp.
static func alien_camp(world_seed: int, sp: SpaceShape, landmark: Dictionary) -> Dictionary:
	var u := SpaceRules.MOON if sp.planet == SpaceShape.MOON else (SpaceRules.MARS if sp.planet == SpaceShape.MARS else -1)
	if u < 0 or not AlienRules.has_camp(u):
		return {}
	var keep: Array = []
	if not landmark.is_empty():
		var a: Vector3i = landmark.anchor
		keep.append({"at": Vector2(a.x, a.z), "r": AlienRules.LANDMARK_CLEAR})
	for s: Dictionary in sp.sights():
		keep.append({"at": Vector2(s.pos.x, s.pos.z), "r": SpaceCreatures.SIGHT_CLEAR})
	return AlienRules.site(sp, world_seed, keep, AlienRules.CAMP_HALF)


static func _clear(c: Vector2i, spawn: Vector2i, marks: Array[Vector3]) -> bool:
	var p := Vector2(c.x + 0.5, c.y + 0.5)
	var from := Vector2(spawn.x + 0.5, spawn.y + 0.5)
	for m in marks:
		if not m.is_finite():
			continue
		var at := Vector2(m.x, m.z)
		if p.distance_to(at) < CLEAR_OF or QuestRules.way_distance(p, from, at) < WAY_CLEAR:
			return false
	return true


static func _good(c: Vector2i, height_at: Callable, ground_ok: Callable, tree_at: Callable) -> bool:
	var h := int(height_at.call(c.x, c.y))
	for dx in range(-2, 3):
		for dz in range(-2, 3):
			if absi(int(height_at.call(c.x + dx, c.y + dz)) - h) > 1 or not ground_ok.call(c.x + dx, c.y + dz):
				return false
	for dx in range(-TREE_CLEAR, TREE_CLEAR + 1):
		for dz in range(-TREE_CLEAR, TREE_CLEAR + 1):
			if tree_at.call(c.x + dx, c.y + dz):
				return false
	return true


## True when feet at `feet` stand close enough to Gemma (at `at`) to open her board.
static func near_gemma(at: Vector3, feet: Vector3) -> bool:
	return at.is_finite() and feet.is_finite() and Vector2(at.x - feet.x, at.z - feet.z).length() <= BOARD_REACH \
		and absf(at.y - feet.y) <= BOARD_HIGH


## Stands the camp at `data` ({pos, yaw}).
func setup(data: Dictionary) -> void:
	name = "ProspectCamp"
	position = data.pos
	rotation.y = float(data.get("yaw", 0.0))
	space = bool(data.get("space", false))
	add_child(gemma)
	gemma.name = "Gemma"
	if space:   # spec §26.5
		_space_figure()
		_space_props()
	else:
		_figure()
		_props()
	ProspectModels.label(self, "Gemma\nthe space geologist" if space else "Gemma\nthe geologist", Vector3(0, 2.4 if space else 2.25, 0))
	bubble.font_size = 110
	bubble.outline_size = 22
	bubble.pixel_size = 0.006
	bubble.modulate = Color("ffd23f")
	bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bubble.no_depth_test = true
	bubble.position = Vector3(0, BUBBLE_Y + (0.15 if space else 0.0), 0)
	bubble.visible = false
	add_child(bubble)


## "!" when a quest waits for this child, "" for nothing.
func show_bubble(text: String) -> void:
	bubble.text = text
	bubble.visible = text != ""


func _process(delta: float) -> void:
	_time += delta
	_look -= delta
	if _look <= 0.0:
		_look = 0.3
		var feet: Vector3 = player_position.call()
		var was := _greeting
		_greeting = feet.is_finite() and feet.distance_to(global_position) < GREET
		if _greeting and not was:
			AnimGreet.hop(gemma)   # owner #94: a hop hello as the child walks up
		if _greeting:
			var d := to_local(feet)
			_turn = atan2(d.x, d.z)
		else:
			_turn = 0.0
	gemma.rotation.y = lerp_angle(gemma.rotation.y, _turn, clampf(5.0 * delta, 0.0, 1.0))
	var arm := 2.4 + sin(_time * 9.0) * 0.35 if _greeting else 0.1 + sin(_time * 1.6) * 0.05
	_arm.rotation.z = lerpf(_arm.rotation.z, arm, clampf(8.0 * delta, 0.0, 1.0))
	if bubble.visible:
		bubble.position.y = BUBBLE_Y + sin(_time * 3.0) * 0.12


# --- The pieces (ProspectModels: vertex-coloured boxes, one mesh per moving part) -----------------------------------

func _figure() -> void:
	var skin := Color("c98a5a")
	ProspectModels.add(gemma, [
		[Vector3(0.18, 0.7, 0.2), Vector3(-0.13, 0.35, 0), Color("3b4a6b")],   # legs: work trousers
		[Vector3(0.18, 0.7, 0.2), Vector3(0.13, 0.35, 0), Color("3b4a6b")],
		[Vector3(0.2, 0.12, 0.3), Vector3(-0.13, 0.06, -0.04), Color("5a3d1e")],   # boots
		[Vector3(0.2, 0.12, 0.3), Vector3(0.13, 0.06, -0.04), Color("5a3d1e")],
		[Vector3(0.52, 0.62, 0.3), Vector3(0, 1.0, 0), Color("f08a1c")],   # the orange vest
		[Vector3(0.54, 0.08, 0.32), Vector3(0, 0.9, 0), Color("139e9b")],   # its teal band (spec §3c)
		[Vector3(0.36, 0.36, 0.34), Vector3(0, 1.52, 0), skin],   # head
		[Vector3(0.06, 0.06, 0.02), Vector3(-0.08, 1.56, -0.18), Color("1b1b1b")],   # eyes
		[Vector3(0.06, 0.06, 0.02), Vector3(0.08, 1.56, -0.18), Color("1b1b1b")],
		[Vector3(0.4, 0.14, 0.4), Vector3(0, 1.76, 0), Color("ffd23f")],   # the hard hat
		[Vector3(0.48, 0.04, 0.48), Vector3(0, 1.7, 0), Color("ffd23f")],
		[Vector3(0.12, 0.5, 0.14), Vector3(-0.33, 1.02, 0), skin],   # left arm
	], "Body")
	_arm.position = Vector3(0.33, 1.26, 0)
	gemma.add_child(_arm)
	ProspectModels.add(_arm, [
		[Vector3(0.12, 0.5, 0.14), Vector3(0, -0.24, 0), skin],
		[Vector3(0.14, 0.14, 0.04), Vector3(0, -0.52, -0.06), Color("dfe5ec")],   # a hand lens
	], "Arm")


## The tent, the table with her map and samples, the crate with a pick (behind Gemma, seen past her from the spawn).
func _props() -> void:
	var tent := Vector3(-2.4, 0, 3.8)
	var table := Vector3(1.6, 0, 2.6)
	var crate := Vector3(3.0, 0, 2.0)
	var boxes: Array = [
		[Vector3(2.6, 0.08, 2.4), tent + Vector3(0, 0.04, 0), Color("6d4c41")],   # the groundsheet
		[Vector3(1.9, 0.08, 2.4), tent + Vector3(-0.55, 0.85, 0), Color("139e9b"), Vector3(0, 0, 1.0)],   # its two sides
		[Vector3(1.9, 0.08, 2.4), tent + Vector3(0.55, 0.85, 0), Color("0c7876"), Vector3(0, 0, -1.0)],
		[Vector3(0.06, 1.7, 0.06), tent + Vector3(0, 0.85, -1.2), Color("8a5a36")],   # the front pole
		[Vector3(0.06, 1.2, 0.06), tent + Vector3(1.6, 0.6, -1.6), Color("8a5a36")],   # the flag
		[Vector3(0.5, 0.32, 0.03), tent + Vector3(1.86, 1.05, -1.6), Color("f08a1c")],
		[Vector3(1.6, 0.06, 0.8), table + Vector3(0, 0.78, 0), Color("a0764a")],   # the table's top
		[Vector3(0.9, 0.02, 0.6), table + Vector3(-0.2, 0.82, 0), Color("f3e2b8")],   # her map
		[Vector3(0.12, 0.03, 0.12), table + Vector3(-0.1, 0.84, 0.05), Color("d9302a")],   # its X
		[Vector3(0.18, 0.14, 0.16), table + Vector3(0.55, 0.88, -0.1), Color("f5c542")],   # a rock sample (gold)
		[Vector3(0.16, 0.12, 0.14), table + Vector3(0.52, 0.87, 0.18), Color("2f9a5c")],   # malachite
		[Vector3(0.8, 0.5, 0.6), crate + Vector3(0, 0.25, 0), Color("8a5a36")],   # the crate
		[Vector3(0.2, 0.16, 0.2), crate + Vector3(-0.2, 0.56, 0), Color("a63a28")],   # banded iron
		[Vector3(0.2, 0.16, 0.2), crate + Vector3(0.15, 0.56, 0.1), Color("25262b")],   # coal
		[Vector3(0.06, 1.1, 0.06), crate + Vector3(0.52, 0.55, 0), Color("6e4527"), Vector3(0, 0, 0.25)],   # a pick
		[Vector3(0.5, 0.08, 0.08), crate + Vector3(0.66, 1.06, 0), Color("8d9098"), Vector3(0, 0, 0.25)],
	]
	for x in [-0.72, 0.72]:
		for z in [-0.32, 0.32]:
			boxes.append([Vector3(0.06, 0.78, 0.06), table + Vector3(x, 0.39, z), Color("6e4527")])   # its legs
	ProspectModels.add(self, boxes, "Props")


# --- Spec §26.5: the space camp (ProspectModels' boxes, the same three meshes) -----------------------------------------

## Gemma in a white spacesuit: its helmet with a golden visor, her orange vest with the teal band over it, a backpack.
func _space_figure() -> void:
	var suit := Color("eef1f4")
	var shade := Color("c9cfd6")
	ProspectModels.add(gemma, [
		[Vector3(0.22, 0.72, 0.24), Vector3(-0.14, 0.36, 0), suit],   # legs
		[Vector3(0.22, 0.72, 0.24), Vector3(0.14, 0.36, 0), suit],
		[Vector3(0.24, 0.14, 0.32), Vector3(-0.14, 0.07, -0.04), Color("8d939c")],   # boots
		[Vector3(0.24, 0.14, 0.32), Vector3(0.14, 0.07, -0.04), Color("8d939c")],
		[Vector3(0.58, 0.66, 0.34), Vector3(0, 1.02, 0), suit],   # the suit's body
		[Vector3(0.6, 0.3, 0.36), Vector3(0, 1.1, -0.01), Color("f08a1c")],   # the orange vest over it
		[Vector3(0.62, 0.08, 0.38), Vector3(0, 0.94, 0), Color("139e9b")],   # its teal band (spec §3c)
		[Vector3(0.5, 0.56, 0.22), Vector3(0, 1.08, 0.28), shade],   # the backpack (air and power)
		[Vector3(0.48, 0.46, 0.46), Vector3(0, 1.58, 0), suit],   # the helmet
		[Vector3(0.36, 0.26, 0.04), Vector3(0, 1.6, -0.23), Color("d9a82e")],   # its golden visor
		[Vector3(0.1, 0.08, 0.02), Vector3(-0.08, 1.66, -0.255), Color("ffe9a8")],   # the visor's shine
		[Vector3(0.14, 0.52, 0.16), Vector3(-0.36, 1.02, 0), suit],   # left arm
	], "Body")
	_arm.position = Vector3(0.36, 1.28, 0)
	gemma.add_child(_arm)
	ProspectModels.add(_arm, [
		[Vector3(0.14, 0.52, 0.16), Vector3(0, -0.25, 0), suit],
		[Vector3(0.16, 0.12, 0.16), Vector3(0, -0.54, 0), Color("8d939c")],   # a glove
		[Vector3(0.14, 0.14, 0.04), Vector3(0, -0.56, -0.1), Color("dfe5ec")],   # a hand lens
	], "Arm")


## A little white habitat (a round window, a teal stripe, a door), the sample table, a crate, an ice drill on its tripod
## and a flag, behind Gemma as seen from the landing pad.
func _space_props() -> void:
	var hab := Vector3(-2.6, 0, 3.9)
	var table := Vector3(1.6, 0, 2.6)
	var drill := Vector3(3.2, 0, 1.6)
	var boxes: Array = [
		[Vector3(2.8, 1.6, 2.4), hab + Vector3(0, 0.8, 0), Color("eef1f4")],   # the habitat
		[Vector3(2.4, 0.3, 2.0), hab + Vector3(0, 1.75, 0), Color("dfe5ec")],   # its rounded top
		[Vector3(2.82, 0.16, 2.42), hab + Vector3(0, 1.1, 0), Color("139e9b")],   # its teal stripe
		[Vector3(0.62, 0.62, 0.04), hab + Vector3(0.6, 0.95, -1.22), Color("5aa9f0")],   # a round window (square here)
		[Vector3(0.7, 1.2, 0.05), hab + Vector3(-0.6, 0.6, -1.22), Color("8d939c")],   # the door
		[Vector3(1.6, 0.06, 0.8), table + Vector3(0, 0.78, 0), Color("c9cfd6")],   # the table's top
		[Vector3(0.9, 0.02, 0.6), table + Vector3(-0.2, 0.82, 0), Color("f3e2b8")],   # her map
		[Vector3(0.12, 0.03, 0.12), table + Vector3(-0.1, 0.84, 0.05), Color("d9302a")],   # its X
		[Vector3(0.18, 0.14, 0.16), table + Vector3(0.55, 0.88, -0.1), Color("cfe4f7")],   # an ice sample
		[Vector3(0.16, 0.12, 0.14), table + Vector3(0.52, 0.87, 0.18), Color("1c1d22")],   # ilmenite
		[Vector3(0.14, 0.12, 0.14), table + Vector3(0.25, 0.87, 0.2), Color("5b5f6b")],   # a blueberry
		[Vector3(0.8, 0.5, 0.6), drill + Vector3(-1.2, 0.25, 0.6), Color("8d939c")],   # the crate
		[Vector3(0.06, 1.6, 0.06), drill + Vector3(0.35, 0.75, 0), Color("dfe5ec"), Vector3(0, 0, 0.22)],   # the tripod
		[Vector3(0.06, 1.6, 0.06), drill + Vector3(-0.35, 0.75, 0), Color("dfe5ec"), Vector3(0, 0, -0.22)],
		[Vector3(0.06, 1.6, 0.06), drill + Vector3(0, 0.75, 0.35), Color("dfe5ec"), Vector3(-0.22, 0, 0)],
		[Vector3(0.22, 0.3, 0.22), drill + Vector3(0, 1.45, 0), Color("f08a1c")],   # the drill's motor
		[Vector3(0.08, 1.4, 0.08), drill + Vector3(0, 0.7, 0), Color("b9c2cc")],   # the drill going down
		[Vector3(0.06, 1.6, 0.06), hab + Vector3(1.7, 0.8, -1.6), Color("b9c2cc")],   # the flag
		[Vector3(0.5, 0.32, 0.03), hab + Vector3(1.96, 1.45, -1.6), Color("139e9b")],
	]
	for x in [-0.72, 0.72]:
		for z in [-0.32, 0.32]:
			boxes.append([Vector3(0.06, 0.78, 0.06), table + Vector3(x, 0.39, z), Color("8d939c")])   # its legs
	ProspectModels.add(self, boxes, "Props")
