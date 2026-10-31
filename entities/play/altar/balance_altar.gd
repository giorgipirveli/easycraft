class_name BalanceAltar
extends Node3D
## Owner #133, #134 (docs/design/games/balance-altar.md §3.4, §3.8's table, §3.11, rulings 3, 9, 10; §4.3, §4.4): one
## balance altar, child-sized: the pedestal with the rune plaque on its front, the fluted pillar, the crown of two gold
## bars (the equals sign) carrying the beam, two bronze pans (0.7 m apart, 0.32 m wide) on gold cords, the ice-blue
## chains that hold the beam level while the crystal is frozen (ruling 3), the seal in the fulcrum, the gem bag and the
## sharing bowls on their stands (and the balloon pump in the Sky Room). The Great Altar is the same, bigger
## (`great`), its pans at the same height.
##
## What it holds is the state it is shown (`show_state`): crystals (see-through, a Glimmer asleep in each), gems in
## rows of five (a MultiMesh), balloons on strings (MultiMeshes); what waits for its twin rises and turns amber; a freed
## crystal turns gold, its chains vanish and its Glimmer sits up beside it. The rune line is carved on the plaque from
## AltarRunes' tokens (geometry, never a label). Its targets (marker nodes, `targets()`): the piles of each pan
## (`gems_0`, `gems_1`), the balloons (`balloons_0`, `balloons_1`), the crystal, the bowls, the seal, the bag, the pump,
## the runes. Front is +Z; the left pan (LEFT) is at -X. Drawn in about 9 draws (§4.5).

const GOLD := Color("e9b83f")
const GOLD_TOP := Color("ffe39a")
const STONE := Color("efe5d4")
const STONE_TOP := Color("fbf6ee")
const BRONZE := Color("c98b4f")
const BRONZE_IN := Color("f0c48c")
const ICE := Color("a9e6ff")
const AMBER := Color(1.0, 0.7, 0.32)
const GEM_GOLD := Color("ffd44d")
const CORAL := Color("ff6f5e")
## How high a waiting thing rises.
const RISE := 0.09
const MAX_GEMS := 44
const MAX_BALLOONS := 18
const MAX_CRYSTALS := 8

var great := false
var glimmer := "fox"
var stage := AltarRunes.PICTURES
var tools: Array[String] = ["bowls", "gem_bag"]
var state: AltarState
var waiting := {}
var freed := false

## Sizes (the Great Altar's are bigger; its pans hang at the same height).
var k := 1.0
var pan_x := 0.35
var pan_r := 0.16
var beam_y := 0.945
var stand_x := 0.6
const PAN_RIM_Y := 0.668
const PAN_FLOOR_Y := 0.628

var _body: MeshInstance3D
var _glow: MeshInstance3D
var _crystals: MeshInstance3D
var _runes: MeshInstance3D
var _sleepers: MultiMeshInstance3D
var _awake: MeshInstance3D
var _gems: MultiMeshInstance3D
var _balloons: MultiMeshInstance3D
var _strings: MultiMeshInstance3D
var _markers := {}
var _shown := [{}, {}]
var _lifted := 0
var _carved: Array[Dictionary] = []
var _strokes := 0
var _chained := true


func _init(is_great: bool = false, room_tools: Array[String] = ["bowls", "gem_bag"], kind: String = "fox") -> void:
	great = is_great
	tools = room_tools.duplicate()
	glimmer = kind
	name = "GreatAltar" if great else "BalanceAltar"
	if great:
		k = 1.45
		pan_x = 0.52
		pan_r = 0.24
		beam_y = 1.4
		stand_x = 0.8
	_build()


# --- What it shows --------------------------------------------------------------------------------------------------

## The altar holding `s`, with `wait` (AltarMoves.waiting: {pan, verb, kind, count, twins}) risen and amber, freed or
## not. Rebuilds only what changes (the crystals, the chains and the runes are small meshes).
func show_state(s: AltarState, wait: Dictionary = {}, is_freed: bool = false) -> void:
	state = s.copy()
	waiting = wait.duplicate()
	freed = is_freed
	_chained = not freed
	_layout()
	_carve()
	_place_markers()


## The Glimmer asleep in this altar's crystals (an altar of the ring takes the next one's as it comes round).
func set_glimmer(kind: String) -> void:
	if kind == "" or kind == glimmer:
		return
	glimmer = kind
	_sleepers.multimesh.mesh = GlimmerModel.mesh(kind, GlimmerModel.ASLEEP)
	_awake.mesh = GlimmerModel.mesh(kind, GlimmerModel.AWAKE)


## What a pan shows: {crystal, gem, balloon} as drawn now (the things on it, risen or not).
func shown(pan: int) -> Dictionary:
	return (_shown[pan] as Dictionary).duplicate()


## How many things are risen (waiting for a twin, or lifted).
func lifted_count() -> int:
	return _lifted


func chained() -> bool:
	return _chained


func glimmer_awake() -> bool:
	return _awake != null and _awake.visible


## The rune line carved on the plaque now (its glyphs, as AltarRunes.line writes them).
func carved_line() -> String:
	return " ".join(_carved.map(func(t: Dictionary) -> String: return str(t.glyph)))


func rune_count() -> int:
	return _strokes


## The altar's targets: {name: [marker node, radius]} (the room registers them).
func targets() -> Dictionary:
	return _markers.duplicate()


## The targets the hands take or press in VR (all of them but the runes, which a finger or the laser touches).
func hand_target_names() -> Array[String]:
	var out: Array[String] = []
	for t: String in _markers:
		if t != "runes":
			out.append(t)
	return out


## Where a pan's middle is (the altar's space).
func pan_centre(pan: int) -> Vector3:
	return Vector3(-pan_x if pan == AltarState.LEFT else pan_x, PAN_FLOOR_Y, 0)


# --- Building ---------------------------------------------------------------------------------------------------------

func _build() -> void:
	var m := AltarKit.Mesher.new()
	build_body(m, k, tools, pan_x, pan_r, beam_y, stand_x)
	_body = AltarKit.mesh(self, "Body", m.commit(), AltarKit.lit())
	_glow = AltarKit.mesh(self, "Glow", ArrayMesh.new(), AltarKit.glow())
	_crystals = AltarKit.mesh(self, "Crystals", ArrayMesh.new(), AltarKit.glass())
	_runes = AltarKit.mesh(self, "Runes", ArrayMesh.new(), AltarKit.lit())
	var box := AABB(Vector3(-1.2, -0.2, -0.6), Vector3(2.4, 2.2, 1.2))
	_sleepers = AltarKit.multimesh(self, "Sleepers", GlimmerModel.mesh(glimmer, GlimmerModel.ASLEEP), AltarKit.glow(),
		MAX_CRYSTALS, box)
	_awake = AltarKit.mesh(self, "Glimmer", GlimmerModel.mesh(glimmer, GlimmerModel.AWAKE), AltarKit.glow())
	_awake.visible = false
	_gems = AltarKit.multimesh(self, "Gems", gem_mesh(), AltarKit.shiny(), MAX_GEMS, box)
	_balloons = AltarKit.multimesh(self, "Balloons", balloon_mesh(), AltarKit.shiny(), MAX_BALLOONS, box)
	_strings = AltarKit.multimesh(self, "Strings", string_mesh(), AltarKit.lit(), MAX_BALLOONS, box)
	for t: String in ["gems_0", "gems_1", "balloons_0", "balloons_1", "crystal", "bowls", "seal", "bag", "runes"]:
		_marker(t)
	if tools.has(AltarMoves.PUMP):
		_marker("pump")
	show_state(AltarState.make(1, 0, 0, 1, 1))


func _marker(t: String) -> void:
	var n := Node3D.new()
	n.name = "T_" + t
	add_child(n)
	var radius := {"gems_0": 0.1, "gems_1": 0.1, "balloons_0": 0.1, "balloons_1": 0.1, "crystal": 0.085, "bowls": 0.1,
		"seal": 0.075, "bag": 0.1, "pump": 0.09, "runes": 0.12}
	_markers[t] = [n, float(radius.get(t, 0.08)) * (1.3 if great else 1.0)]


func _place_markers() -> void:
	var at := {
		"gems_0": pan_centre(0) + Vector3(0, 0.05, 0.045),
		"gems_1": pan_centre(1) + Vector3(0, 0.05, 0.045),
		"balloons_0": pan_centre(0) + Vector3(0, 0.37 if great else 0.29, -0.06),
		"balloons_1": pan_centre(1) + Vector3(0, 0.37 if great else 0.29, -0.06),
		"crystal": pan_centre(state.crystal_pan() if state != null else 0) + Vector3(0, 0.2 if great else 0.17, -0.09 if great else -0.065),
		"bowls": Vector3(stand_x, _stand_top() + 0.06, 0.12),
		"seal": Vector3(0, beam_y, 0.045),
		"bag": Vector3(-stand_x, _stand_top() + 0.1, 0.12),
		"pump": Vector3(-stand_x - 0.04, _stand_top() + 0.08, -0.13),
		"runes": Vector3(0, 0.225, 0.2 * k + 0.012),
	}
	for t: String in _markers:
		((_markers[t] as Array)[0] as Node3D).position = at[t]


func _stand_top() -> float:
	return 0.5 if not great else 0.56


## The static altar: dais, steps, pedestal and plaque, pillar, crown, beam, cords, pans, the anchors, the tool stands.
static func build_body(m: AltarKit.Mesher, k: float, room_tools: Array[String], pan_x: float, pan_r: float,
		beam_y: float, stand_x: float) -> void:
	var stand_top := 0.5 if k < 1.2 else 0.56
	# The dais and the steps.
	m.lathe(Transform3D(), [Vector2(0.84 * k, 0.0), Vector2(0.84 * k, 0.03), Vector2(0.81 * k, 0.04), Vector2(0.78 * k, 0.04),
		Vector2(0, 0.04)] as Array[Vector2], [Color("cdbb9a"), Color("ddcfb4"), GOLD, Color("e6dac4"), Color("ece2d0")]
		as Array[Color], 36)
	m.box(Transform3D(Basis(), Vector3(0, 0.08, 0)), Vector3(1.0 * k, 0.08, 0.66 * k), STONE, STONE_TOP)
	# The pedestal, its gold band and the rune plaque in its frame.
	var ped := Vector3(0.66 * k, 0.3, 0.4 * k)
	m.box(Transform3D(Basis(), Vector3(0, 0.12 + ped.y * 0.5, 0)), ped, STONE.darkened(0.02), STONE_TOP)
	m.box(Transform3D(Basis(), Vector3(0, 0.12 + ped.y - 0.012, 0)), Vector3(ped.x + 0.02, 0.024, ped.z + 0.02), GOLD,
		GOLD_TOP, 0.05)
	m.box(Transform3D(Basis(), Vector3(0, 0.13, 0)), Vector3(ped.x + 0.03, 0.02, ped.z + 0.03), GOLD.darkened(0.1),
		GOLD, 0.05)
	var front := ped.z * 0.5
	var plaque := Vector2(0.6 * k, 0.2)
	m.box(Transform3D(Basis(), Vector3(0, 0.225, front + 0.004)), Vector3(plaque.x, plaque.y, 0.008), Color("f6e9cc"),
		Color("fff6e0"), 0.03)
	for e: Array in [[Vector3(0, 0.225 + plaque.y * 0.5, front + 0.007), Vector3(plaque.x + 0.02, 0.014, 0.012)],
			[Vector3(0, 0.225 - plaque.y * 0.5, front + 0.007), Vector3(plaque.x + 0.02, 0.014, 0.012)],
			[Vector3(-plaque.x * 0.5, 0.225, front + 0.007), Vector3(0.014, plaque.y, 0.012)],
			[Vector3(plaque.x * 0.5, 0.225, front + 0.007), Vector3(0.014, plaque.y, 0.012)]]:
		m.box(Transform3D(Basis(), e[0]), e[1], GOLD, GOLD_TOP, 0.04)
	# The pillar: a round base, a fluted shaft, a gold capital.
	var base_y := 0.12 + ped.y
	var top_y := beam_y - 0.09
	m.lathe(Transform3D(), [Vector2(0.09 * k, base_y), Vector2(0.09 * k, base_y + 0.022), Vector2(0.07 * k, base_y + 0.03),
		Vector2(0.06 * k, base_y + 0.045)] as Array[Vector2],
		[STONE.darkened(0.08), STONE, STONE, STONE_TOP] as Array[Color], 24)
	m.lathe(Transform3D(), [Vector2(0.052 * k, base_y + 0.04), Vector2(0.046 * k, top_y - 0.04)] as Array[Vector2],
		[Color("e9dfcd"), Color("fbf7f0")] as Array[Color], 48, false, false, 0.0, 0.07, 12)
	m.lathe(Transform3D(), [Vector2(0.05 * k, top_y - 0.045), Vector2(0.06 * k, top_y - 0.03), Vector2(0.08 * k, top_y - 0.012),
		Vector2(0.08 * k, top_y), Vector2(0, top_y)] as Array[Vector2],
		[GOLD.darkened(0.15), GOLD, GOLD, GOLD_TOP, GOLD_TOP] as Array[Color], 24)
	# The crown: two gold bars, the equals sign the beam rests on.
	for y: float in [top_y + 0.016, top_y + 0.048]:
		m.box(Transform3D(Basis(), Vector3(0, y, 0)), Vector3(0.21 * k, 0.02, 0.07), GOLD, GOLD_TOP, 0.08)
	# The pivot and the beam, its finials and hangers.
	m.tube(Vector3(0, beam_y, -0.034), Vector3(0, beam_y, 0.034), 0.034 * minf(k, 1.2), GOLD, GOLD_TOP, 18, true)
	m.box(Transform3D(Basis(), Vector3(0, beam_y, 0)), Vector3((pan_x + 0.045) * 2.0, 0.028, 0.034), GOLD, GOLD_TOP, 0.12)
	for sx: float in [-1.0, 1.0]:
		m.sphere(Transform3D(Basis(), Vector3(sx * (pan_x + 0.06), beam_y, 0)), 0.022, GOLD_TOP, GOLD, 12, 6)
		m.torus(Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(sx * pan_x, beam_y - 0.028, 0)), 0.014, 0.004,
			GOLD_TOP, GOLD, 12, 5)
	# The cords and the pans.
	for sx: float in [-1.0, 1.0]:
		var hook := Vector3(sx * pan_x, beam_y - 0.04, 0)
		for a: float in [deg_to_rad(30.0), deg_to_rad(150.0), deg_to_rad(270.0)]:
			var rim := Vector3(sx * pan_x + cos(a) * pan_r * 0.94, PAN_RIM_Y + 0.004, sin(a) * pan_r * 0.94)
			m.tube(hook, rim, 0.0035, Color("d9b45c"), Color("c99a3e"), 5)
		var xf := Transform3D(Basis(), Vector3(sx * pan_x, 0, 0))
		m.lathe(xf, [Vector2(0.0, PAN_FLOOR_Y - 0.032), Vector2(0.05, PAN_FLOOR_Y - 0.028),
			Vector2(pan_r * 0.66, PAN_FLOOR_Y - 0.012), Vector2(pan_r * 0.9, PAN_RIM_Y - 0.018), Vector2(pan_r, PAN_RIM_Y)]
			as Array[Vector2], [BRONZE.darkened(0.35), BRONZE.darkened(0.25), BRONZE.darkened(0.08), BRONZE, BRONZE.lightened(0.1)]
			as Array[Color], 32)
		m.lathe(xf, [Vector2(pan_r - 0.006, PAN_RIM_Y), Vector2(pan_r * 0.86, PAN_RIM_Y - 0.02),
			Vector2(pan_r * 0.55, PAN_FLOOR_Y + 0.004), Vector2(0.0, PAN_FLOOR_Y)] as Array[Vector2],
			[BRONZE_IN.lightened(0.1), BRONZE_IN, BRONZE_IN.darkened(0.06), BRONZE_IN.darkened(0.1)] as Array[Color], 32)
		m.torus(Transform3D(Basis(), Vector3(sx * pan_x, PAN_RIM_Y, 0)), pan_r, 0.007, GOLD_TOP, GOLD, 32, 5)
		# The chains' anchors on the pedestal.
		m.torus(Transform3D(Basis(Vector3.FORWARD, PI * 0.5), Vector3(sx * 0.2 * k, base_y + 0.022, 0)), 0.02, 0.006,
			GOLD_TOP, GOLD, 12, 5)
	# The tool stands: the gem bag on the left, the bowls on the right (and the pump behind the bag).
	for sx: float in [-1.0, 1.0]:
		var at := Vector3(sx * stand_x, 0, 0.12)
		m.lathe(Transform3D(Basis(), at), [Vector2(0.11, 0.0), Vector2(0.11, 0.03), Vector2(0.06, 0.06), Vector2(0.045, 0.1),
			Vector2(0.04, stand_top - 0.07), Vector2(0.07, stand_top - 0.03), Vector2(0.11, stand_top - 0.012),
			Vector2(0.11, stand_top), Vector2(0, stand_top)] as Array[Vector2],
			[STONE.darkened(0.12), STONE, STONE, STONE, STONE, STONE, GOLD, GOLD_TOP, STONE_TOP] as Array[Color], 20,
			false, false, 0.0, 0.05, 8)
	_gem_bag(m, Vector3(-stand_x, stand_top, 0.12))
	_bowl_rack(m, Vector3(stand_x, stand_top, 0.12))
	if room_tools.has(AltarMoves.PUMP):
		_pump(m, Vector3(-stand_x - 0.04, 0, -0.13), stand_top)


static func _gem_bag(m: AltarKit.Mesher, at: Vector3) -> void:
	var velvet := Color("7a48c8")
	var light := Color("a87ef0")
	m.lathe(Transform3D(Basis(), at), [Vector2(0, 0.0), Vector2(0.07, 0.004), Vector2(0.095, 0.045), Vector2(0.092, 0.1),
		Vector2(0.066, 0.15), Vector2(0.044, 0.172), Vector2(0.05, 0.18), Vector2(0.07, 0.205), Vector2(0.03, 0.2), Vector2(0, 0.19)]
		as Array[Vector2], [velvet.darkened(0.4), velvet.darkened(0.2), velvet, light, light, velvet, light, light.lightened(0.15),
		velvet.darkened(0.3), velvet.darkened(0.4)] as Array[Color], 16, false, false, 0.3, 0.06, 6)
	m.torus(Transform3D(Basis(), at + Vector3(0, 0.174, 0)), 0.046, 0.007, GOLD_TOP, GOLD, 16, 5)
	for g: Vector3 in [Vector3(0.01, 0.2, 0.012), Vector3(-0.022, 0.196, -0.004), Vector3(0.014, 0.194, -0.022)]:
		m.append_mesh(gem_mesh(), Transform3D(Basis().scaled(Vector3.ONE * 0.62), at + g), Color(1, 1, 1))


static func _bowl_rack(m: AltarKit.Mesher, at: Vector3) -> void:
	var wood := Color("a8713f")
	m.box(Transform3D(Basis(), at + Vector3(0, 0.012, 0)), Vector3(0.24, 0.024, 0.17), wood, wood.lightened(0.15))
	for row in 2:
		for col in 3:
			var p := at + Vector3((col - 1) * 0.075, 0.024, (row - 0.5) * 0.08)
			m.lathe(Transform3D(Basis(), p), [Vector2(0.0, 0.0), Vector2(0.02, 0.002), Vector2(0.034, 0.02),
				Vector2(0.038, 0.04), Vector2(0.04, 0.046), Vector2(0.034, 0.043), Vector2(0.026, 0.022), Vector2(0.0, 0.014)]
				as Array[Vector2], [BRONZE.darkened(0.35), BRONZE.darkened(0.2), BRONZE, BRONZE.lightened(0.1), GOLD_TOP,
				BRONZE.darkened(0.25), BRONZE.darkened(0.42), BRONZE.darkened(0.5)] as Array[Color], 16)


static func _pump(m: AltarKit.Mesher, at: Vector3, stand_top: float) -> void:
	var brass := Color("d8a84a")
	m.lathe(Transform3D(Basis(), at), [Vector2(0.08, 0.0), Vector2(0.08, 0.02), Vector2(0.034, 0.03), Vector2(0.032, stand_top),
		Vector2(0.036, stand_top + 0.01), Vector2(0, stand_top + 0.012)] as Array[Vector2],
		[brass.darkened(0.3), brass, brass.darkened(0.1), brass.lightened(0.1), GOLD_TOP, GOLD_TOP] as Array[Color], 16)
	m.tube(at + Vector3(0, stand_top, 0), at + Vector3(0, stand_top + 0.07, 0), 0.007, brass, brass, 6)
	m.box(Transform3D(Basis(), at + Vector3(0, stand_top + 0.075, 0)), Vector3(0.12, 0.018, 0.022), Color("6b4a2a"), Color("8a6440"))
	var hose := [at + Vector3(0.03, 0.06, 0), at + Vector3(0.09, 0.03, 0.02), at + Vector3(0.12, 0.08, 0.06), at + Vector3(0.1, 0.2, 0.08)]
	for h in hose.size() - 1:
		m.tube(hose[h], hose[h + 1], 0.009, Color("3f4a5c"), Color("3f4a5c"), 6)
	m.sphere(Transform3D(Basis().scaled(Vector3(1, 1.15, 1)), at + Vector3(0.1, 0.24, 0.08)), 0.034, CORAL.lightened(0.25), CORAL.darkened(0.2), 12, 7)


# --- The pieces that move ---------------------------------------------------------------------------------------------

## A faceted round gold gem, 6 cm across (a brilliant: a flat table, a crown, the girdle, a pointed pavilion).
static func gem_mesh() -> ArrayMesh:
	if not AltarKit._meshes.has("gem"):
		var m := AltarKit.Mesher.new()
		m.lathe(Transform3D(), [Vector2(0, 0.0), Vector2(0.03, 0.019), Vector2(0.03, 0.024), Vector2(0.019, 0.039),
			Vector2(0, 0.04)] as Array[Vector2],
			[Color("b06d08"), Color("e39a14"), Color("ffc22e"), Color("ffdd6e"), Color("ffeaa0")] as Array[Color], 8, true, true)
		AltarKit._meshes["gem"] = m.commit()
	return AltarKit._meshes["gem"]


## A coral balloon on its knot (9 cm across).
static func balloon_mesh() -> ArrayMesh:
	if not AltarKit._meshes.has("balloon"):
		var m := AltarKit.Mesher.new()
		m.lathe(Transform3D(), [Vector2(0, -0.064), Vector2(0.008, -0.058), Vector2(0.005, -0.05), Vector2(0.02, -0.045),
			Vector2(0.038, -0.028), Vector2(0.046, -0.004), Vector2(0.044, 0.02), Vector2(0.032, 0.04), Vector2(0, 0.05)]
			as Array[Vector2], [CORAL.darkened(0.35), CORAL.darkened(0.3), CORAL.darkened(0.2), CORAL.darkened(0.15), CORAL,
			CORAL, CORAL.lightened(0.12), CORAL.lightened(0.3), CORAL.lightened(0.45)] as Array[Color], 16)
		AltarKit._meshes["balloon"] = m.commit()
	return AltarKit._meshes["balloon"]


## A balloon's string: a thin cord 1 m along +Y (each instance scaled to its length).
static func string_mesh() -> ArrayMesh:
	if not AltarKit._meshes.has("string"):
		var m := AltarKit.Mesher.new()
		m.tube(Vector3.ZERO, Vector3(0, 1, 0), 0.0018, Color("f2ede2"), Color("fffaf0"), 5)
		AltarKit._meshes["string"] = m.commit()
	return AltarKit._meshes["string"]


## A frozen crystal: a six-sided prism with pointed ends, 23 cm tall (`colour` at its foot, `tip` at its top).
static func crystal_geometry(m: AltarKit.Mesher, xf: Transform3D, foot: Color, tip: Color, baked: bool = true) -> void:
	m.lathe(xf, [Vector2(0, 0.0), Vector2(0.046, 0.036), Vector2(0.054, 0.062), Vector2(0.054, 0.175), Vector2(0.044, 0.205),
		Vector2(0, 0.232)] as Array[Vector2], [foot, foot, foot.lerp(tip, 0.25), foot.lerp(tip, 0.75), tip, tip] as Array[Color],
		6, true, baked, PI / 6.0)


## Where things sit on a pan (the altar's space): `n` gems in rows of five from the front, two layers; crystals at the
## back; balloons in an arc above the back.
func _gem_slot(pan: int, j: int, has_crystals: bool) -> Vector3:
	var rows: Array[float] = []
	if great:
		rows.assign([0.11, 0.052, -0.006] if has_crystals else [0.11, 0.052, -0.006, -0.064])
	else:
		rows.assign([0.072, 0.014] if has_crystals else [0.074, 0.016, -0.042])
	var per_layer := rows.size() * 5
	var layer := j / per_layer
	var in_layer := j % per_layer
	var row := in_layer / 5
	var col := in_layer % 5
	var x := (col - 2) * 0.058 + (0.029 if layer % 2 == 1 else 0.0)
	var z := rows[row] - (0.029 if layer % 2 == 1 else 0.0)
	return pan_centre(pan) + Vector3(x, 0.002 + layer * 0.034 + _floor_rise(Vector2(x, z)), z)


## The pan's floor curves up towards its rim.
func _floor_rise(p: Vector2) -> float:
	var r := p.length() / pan_r
	return 0.022 * r * r


func _crystal_slot(pan: int, j: int, count: int) -> Vector3:
	var x := (j - (count - 1) * 0.5) * (0.15 if great else 0.11)
	return pan_centre(pan) + Vector3(x, 0.004, -0.065 * (1.4 if great else 1.0))


func _balloon_slot(pan: int, j: int, count: int) -> Vector3:
	var x := (j - (count - 1) * 0.5) * 0.072
	return pan_centre(pan) + Vector3(x, (0.35 if great else 0.27) + 0.025 * sin(j * 1.7 + pan), -0.06 + 0.025 * cos(j * 2.3))


func _layout() -> void:
	var mm_g := _gems.multimesh
	var mm_b := _balloons.multimesh
	var mm_s := _strings.multimesh
	var mm_z := _sleepers.multimesh
	for i in mm_g.instance_count:
		mm_g.set_instance_transform(i, AltarKit.hidden())
	for i in mm_b.instance_count:
		mm_b.set_instance_transform(i, AltarKit.hidden())
		mm_s.set_instance_transform(i, AltarKit.hidden())
	for i in mm_z.instance_count:
		mm_z.set_instance_transform(i, AltarKit.hidden())
	var gi := 0
	var bi := 0
	var zi := 0
	_lifted = 0
	var crystal_mesh := AltarKit.Mesher.new()
	var glow := AltarKit.Mesher.new()
	var w_pan := int(waiting.get("pan", -1))
	var w_verb := str(waiting.get("verb", ""))
	var w_kind := str(waiting.get("kind", ""))
	var w_count := int(waiting.get("count", 0))
	var w_twins := int(waiting.get("twins", 0))
	for pan in 2:
		var crystals := state.amount(pan, AltarState.CRYSTAL)
		var gems := state.amount(pan, AltarState.GEM)
		var balloons := state.amount(pan, AltarState.BALLOON)
		_shown[pan] = {"crystal": crystals, "gem": gems, "balloon": balloons}
		var risen := 0
		if w_verb == AltarMoves.LIFT:
			risen = w_count if pan == w_pan else (w_twins if w_pan >= 0 else 0)
		# Crystals: glass, a Glimmer asleep in each (or, freed, gold and empty with its Glimmer beside it).
		for j in crystals:
			var at := _crystal_slot(pan, j, crystals)
			var up := w_verb == AltarMoves.LIFT and w_kind == AltarState.CRYSTAL and j < risen
			if up:
				at.y += RISE
				_lifted += 1
			var foot := Color(0.4, 0.76, 1.0, 0.7) if not freed else Color(1.0, 0.74, 0.28, 0.66)
			var tip := Color(0.84, 0.95, 1.0, 0.5) if not freed else Color(1.0, 0.93, 0.68, 0.46)
			var size := 1.35 if great else 1.0
			crystal_geometry(crystal_mesh, Transform3D(Basis().scaled(Vector3.ONE * size), at), foot, tip)
			# A soft glow round it (frost blue; warm gold once freed): the crystal is magic.
			var aura := Color(0.62, 0.86, 1.0, 0.34) if not freed else Color(1.0, 0.84, 0.45, 0.4)
			AltarKit.halo(crystal_mesh, at + Vector3(0, 0.12 * size, -0.03), Vector3.BACK, 0.15 * size, aura)
			if not freed:
				for band: float in [0.075, 0.16]:
					glow.torus(Transform3D(Basis(), at + Vector3(0, band * size, 0)), 0.058 * size, 0.004 * size,
						Color("d8f6ff"), Color("7fcdf2"), 18, 4)
				if zi < mm_z.instance_count:
					mm_z.set_instance_transform(zi, Transform3D(Basis().scaled(Vector3.ONE * 1.15 * size),
						at + Vector3(0, 0.068 * size, 0)))
					zi += 1
		# Gems in rows of five; the lifted ones rise, amber.
		for j in gems:
			if gi >= mm_g.instance_count:
				break
			var at := _gem_slot(pan, j, crystals > 0)
			var up := w_verb == AltarMoves.LIFT and w_kind == AltarState.GEM and j >= gems - risen
			if up:
				at.y += RISE
				_lifted += 1
			mm_g.set_instance_transform(gi, Transform3D(Basis(Vector3.UP, 0.3 * j), at))
			mm_g.set_instance_color(gi, AMBER if up else Color.WHITE)
			gi += 1
		# Balloons on strings tied to the pan's back rim; the lifted ones bob higher, amber.
		var tie := pan_centre(pan) + Vector3(0, PAN_RIM_Y - PAN_FLOOR_Y + 0.004, -pan_r * 0.86)
		for j in balloons:
			if bi >= mm_b.instance_count:
				break
			var at := _balloon_slot(pan, j, balloons)
			var up := w_verb == AltarMoves.LIFT and w_kind == AltarState.BALLOON and j >= balloons - risen
			if up:
				at.y += RISE
				_lifted += 1
			mm_b.set_instance_transform(bi, Transform3D(Basis(Vector3.UP, 0.4 * j), at))
			mm_b.set_instance_color(bi, AMBER if up else Color.WHITE)
			_set_string(mm_s, bi, tie, at + Vector3(0, -0.064, 0))
			bi += 1
		# Things from a supply waiting for their twin: they hang above the pan, amber (under a balloon if it has one).
		if w_verb == AltarMoves.PLACE:
			var placed := w_count if pan == w_pan else (w_twins if w_pan >= 0 else 0)
			for j in placed:
				var above := _gem_slot(pan, gems + j, crystals > 0) + Vector3(0, RISE + 0.03, 0)
				if balloons > 0:
					above = _balloon_slot(pan, j % balloons, balloons) + Vector3(0, -0.11, 0)
				_lifted += 1
				if w_kind == AltarState.BALLOON and bi < mm_b.instance_count:
					mm_b.set_instance_transform(bi, Transform3D(Basis(), above + Vector3(0, 0.12, 0)))
					mm_b.set_instance_color(bi, AMBER)
					_set_string(mm_s, bi, tie, above + Vector3(0, 0.056, 0))
					bi += 1
				elif gi < mm_g.instance_count:
					mm_g.set_instance_transform(gi, Transform3D(Basis(), above))
					mm_g.set_instance_color(gi, AMBER)
					gi += 1
	_crystals.mesh = crystal_mesh.commit()
	# The chains hold the beam while the crystal is frozen; the seal glows in the fulcrum.
	if _chained:
		_chains(glow)
	glow.lathe(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, beam_y, 0.036)), [Vector2(0, -0.012), Vector2(0.024, 0.0),
		Vector2(0.024, 0.004), Vector2(0.014, 0.012), Vector2(0, 0.013)] as Array[Vector2],
		[Color("2fa79a"), Color("5fe6d4"), Color("8ff5e6"), Color("c8fff6"), Color("eafffb")] as Array[Color], 8, true, true)
	_glow.mesh = glow.commit()
	# Freed: the Glimmer sits up beside its gold crystal.
	_awake.visible = freed and state.freed()
	if _awake.visible:
		var pan := state.crystal_pan()
		_awake.position = _crystal_slot(pan, 0, 1) + Vector3(0.09, 0.0, 0.07) * (1.4 if great else 1.0)
		_awake.scale = Vector3.ONE * (1.9 if great else 1.4)


func _set_string(mm: MultiMesh, i: int, from: Vector3, to: Vector3) -> void:
	var d := to - from
	var length := d.length()
	if length < 0.001:
		mm.set_instance_transform(i, AltarKit.hidden())
		return
	var y := d / length
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.95 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	mm.set_instance_transform(i, Transform3D(Basis(x, y * length, z), from))


## The two ice-blue chains from the beam down to the pedestal's anchors: links of frost.
func _chains(m: AltarKit.Mesher) -> void:
	var base_y := 0.12 + 0.3 + 0.022
	for sx: float in [-1.0, 1.0]:
		var top := Vector3(sx * 0.12 * k, beam_y - 0.02, 0)
		var bottom := Vector3(sx * 0.2 * k, base_y + 0.02, 0)
		var d := bottom - top
		var links := int(d.length() / 0.033)
		var y := d.normalized()
		var x := y.cross(Vector3.FORWARD).normalized()
		var z := x.cross(y)
		for l in links:
			var at := top + d * ((l + 0.5) / float(links))
			# A link: a ring in the plane of the chain and one of its sides (turning a quarter each link), stretched
			# along the chain.
			var side := x if l % 2 == 0 else z
			var link_xf := Transform3D(Basis(y * 1.45, y.cross(side), side), at)
			m.torus(link_xf, 0.011, 0.0035, Color("e6f8ff"), Color("6fc4ee"), 10, 4)


# --- The carved rune line -----------------------------------------------------------------------------------------------

## Carves AltarRunes' tokens for the state at the altar's stage on the plaque: numerals and signs as raised strokes,
## the crystal's icon in ice blue, gems as gold dots in rows of five; fitted to the plaque.
func _carve() -> void:
	_carved = AltarRunes.tokens(state, stage)
	var m := AltarKit.Mesher.new()
	var pieces: Array = []   # [x offset, Array of strokes [centre(2D), size(2D), turn, colour]]
	var x := 0.0
	var gap := 0.018
	for t: Dictionary in _carved:
		var g := _glyph(t)
		pieces.append([x, g[1]])
		x += float(g[0]) + gap
	var width := maxf(x - gap, 0.001)
	var room := 0.55 * k
	var s := minf(1.3, room / width) * (1.15 if great else 1.0)
	var front := 0.2 * k + 0.008
	_strokes = 0
	for p: Array in pieces:
		for st: Array in p[1]:
			var c2: Vector2 = st[0]
			var size: Vector2 = st[1]
			var turn: float = st[2]
			var col: Color = st[3]
			var cx := (float(p[0]) + c2.x - width * 0.5) * s
			var xf := Transform3D(Basis(Vector3.BACK, turn), Vector3(cx, 0.225 + c2.y * s, front + 0.003))
			if st.size() > 4 and bool(st[4]):
				m.lathe(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), xf.origin), [Vector2(0, -0.004), Vector2(size.x * s * 0.5, -0.002),
					Vector2(size.x * s * 0.5, 0.0), Vector2(0, 0.003)] as Array[Vector2],
					[col.darkened(0.2), col, col.lightened(0.2), col.lightened(0.45)] as Array[Color], 10)
			else:
				m.box(xf, Vector3(size.x * s, size.y * s, 0.006), col, col.lightened(0.25), 0.0)
			_strokes += 1
	_runes.mesh = m.commit()


## A rune's strokes: [its width, [[centre, size, turn, colour, (round)], ...]] (centres from its left edge, mid-height).
func _glyph(t: Dictionary) -> Array:
	var ink := Color("3b2a4c")
	var strokes: Array = []
	match str(t.rune):
		AltarRunes.EQUALS:
			strokes = [[Vector2(0.025, 0.013), Vector2(0.05, 0.011), 0.0, ink], [Vector2(0.025, -0.013), Vector2(0.05, 0.011), 0.0, ink]]
			return [0.05, strokes]
		AltarRunes.PLUS:
			strokes = [[Vector2(0.022, 0.0), Vector2(0.044, 0.011), 0.0, ink], [Vector2(0.022, 0.0), Vector2(0.011, 0.044), 0.0, ink]]
			return [0.044, strokes]
		AltarRunes.MINUS:
			return [0.04, [[Vector2(0.02, 0.0), Vector2(0.04, 0.011), 0.0, ink]]]
		AltarRunes.CRYSTAL:
			var glyph := str(t.glyph)
			if glyph.ends_with("x"):
				var coeff := glyph.trim_suffix("x")
				var out := _number(coeff, ink) if coeff != "" else [0.0, []]
				var w := float(out[0]) + (0.008 if coeff != "" else 0.0)
				var xs: Array = out[1]
				xs.append([Vector2(w + 0.021, -0.012), Vector2(0.056, 0.011), 0.86, ink])
				xs.append([Vector2(w + 0.021, -0.012), Vector2(0.056, 0.011), -0.86, ink])
				return [w + 0.042, xs]
			var count := int(t.n) if stage <= AltarRunes.PICTURES else 1
			var start := 0.0
			var out2: Array = []
			if stage > AltarRunes.PICTURES and int(t.n) > 1:
				var num := _number(str(t.n), ink)
				out2 = num[1]
				start = float(num[0]) + 0.008
			for j in count:
				var cx := start + 0.02 + j * 0.044
				out2.append([Vector2(cx, 0.0), Vector2(0.03, 0.03), PI * 0.25, Color("5cc4f2")])
				out2.append([Vector2(cx, 0.0), Vector2(0.012, 0.05), 0.0, Color("8fdcff")])
				out2.append([Vector2(cx - 0.005, 0.012), Vector2(0.006, 0.012), 0.0, Color("f2fcff")])
			return [start + count * 0.044 - 0.004, out2]
		_:
			if stage <= AltarRunes.PICTURES and int(t.n) > 0:
				var dots: Array = []
				var n := int(t.n)
				var rows := int(ceil(n / 5.0))
				for j in n:
					var r := j / 5
					var col := j % 5
					var cy := ((rows - 1) * 0.5 - r) * 0.026
					dots.append([Vector2(0.0125 + col * 0.027, cy), Vector2(0.021, 0.021), 0.0, Color("f2b630"), true])
				return [mini(n, 5) * 0.027 - 0.002, dots]
			return _number(str(t.glyph), ink)


## A number's digits as seven-segment strokes, cut like runes.
func _number(text: String, ink: Color) -> Array:
	const SEG := {"0": "abcdef", "1": "bc", "2": "abged", "3": "abgcd", "4": "fgbc", "5": "afgcd", "6": "afgedc",
		"7": "abc", "8": "abcdefg", "9": "abcdfg"}
	var w := 0.044
	var h := 0.078
	var t := 0.011
	var out: Array = []
	var x := 0.0
	for ch: String in text:
		if not SEG.has(ch):
			continue
		var segs: String = SEG[ch]
		var cw := w if ch != "1" else t + 0.004
		var ox := x if ch != "1" else x - (w - cw)
		var shapes := {
			"a": [Vector2(ox + w * 0.5, h * 0.5 - t * 0.5), Vector2(w - t - 0.004, t)],
			"g": [Vector2(ox + w * 0.5, 0.0), Vector2(w - t - 0.004, t)],
			"d": [Vector2(ox + w * 0.5, -h * 0.5 + t * 0.5), Vector2(w - t - 0.004, t)],
			"f": [Vector2(ox + t * 0.5, h * 0.25), Vector2(t, h * 0.5 - t - 0.002)],
			"b": [Vector2(ox + w - t * 0.5, h * 0.25), Vector2(t, h * 0.5 - t - 0.002)],
			"e": [Vector2(ox + t * 0.5, -h * 0.25), Vector2(t, h * 0.5 - t - 0.002)],
			"c": [Vector2(ox + w - t * 0.5, -h * 0.25), Vector2(t, h * 0.5 - t - 0.002)],
		}
		for sgm: String in segs:
			out.append([shapes[sgm][0], shapes[sgm][1], 0.0, ink])
		x += cw + 0.01
	return [maxf(x - 0.01, 0.0), out]


# --- The ring's altars (the other frozen altars around the hall) --------------------------------------------------------

## A whole altar at rest as one mesh (the ring's MultiMesh): its body, its chains, a few gems on each pan.
static func ring_mesh(room_tools: Array[String]) -> ArrayMesh:
	var key := "ring|" + ",".join(room_tools)
	if AltarKit._meshes.has(key):
		return AltarKit._meshes[key]
	var m := AltarKit.Mesher.new()
	build_body(m, 1.0, room_tools, 0.35, 0.16, 0.945, 0.6)
	var probe := BalanceAltar.new(false, room_tools)
	var glow := AltarKit.Mesher.new()
	probe._chains(glow)
	m.append_mesh(glow.commit(), Transform3D())
	for pan in 2:
		for j in [2, 5][pan]:
			m.append_mesh(gem_mesh(), Transform3D(Basis(Vector3.UP, 0.3 * j), probe._gem_slot(pan, j, pan == 0)))
	probe.free()
	var mesh := m.commit()
	AltarKit._meshes[key] = mesh
	return mesh


## A frozen crystal for the ring's MultiMesh (opaque, glowing: instanced glass is not warmed).
static func ring_crystal_mesh() -> ArrayMesh:
	if not AltarKit._meshes.has("ring_crystal"):
		var m := AltarKit.Mesher.new()
		crystal_geometry(m, Transform3D(), Color(0.72, 0.9, 1.0), Color(0.97, 1.0, 1.0))
		AltarKit._meshes["ring_crystal"] = m.commit()
	return AltarKit._meshes["ring_crystal"]
