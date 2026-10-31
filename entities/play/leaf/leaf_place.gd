class_name LeafPlace
extends LeafRoom
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.5, §3.8, §3.11, §4.3, §4.5): the leaf's inside at the child's
## size, a green cathedral of cells under a glass roof. Drawn from the pure layout (LeafSpace) with LeafKit's merged
## meshes and MultiMeshes (docs/devlog/parts/game-leaf-b.md §1): the sky through the roof (the Sun, a cloud that slides
## over it, the sunflower's bud far above, filling with gold), the haze where the leaf goes on, the roof and the light's
## soft beams falling through the skylight in the columns onto the doors, the tall columns, the round cells (plump, or
## thirsty: wrinkled and pale), the green workshops on them (dim, or glowing as they build), the vein's blue and gold
## pipes behind a glassy sheath, the floor (the leaf's lower skin: soft cells, and its underside seen from below) with its
## doors (two green guard cells closed into an oval round a dark slit, or bowed apart like lips), grey air puffs (they wait
## at shut doors, drift in through open ones and float up to the working cells), gold sugars at the workshops, blue drops
## from the vein, the mist streaming into open doors and out below, and the light's gold sparks. The glowing parts (the
## haze, the roof) take the weather's tint, so a night is a night. `CactusDressing` re-dresses it as the cactus's stem.
## For B2's host: targets (door_i, its guard cells door_i_a / door_i_b, sugar_k, gold_pipe, blue_pipe), views (WORK, the
## flat overview and the VR start; UNDER, the dive's arrival under the leaf; UP, the cathedral looking up; a VR stand by
## every door, sugar and pipe), and `show_sim(sim, weather, dt)` each frame (the place eases toward the leaf's state).

const WORK := "work"
const UNDER := "under"
const UP := "up"
const DOOR_RADIUS := 1.1
const BEAN_RADIUS := 0.45
const SUGAR_RADIUS := 0.72
const PIPE_RADIUS := 0.8
## How far the place sees into its haze (the far wall), and the floor's thickness.
const HAZE := 14.0
const FLOOR_DEPTH := 0.2
const PUFFS_PER_DOOR := 4
const DROPS := 24
## How fast shown things follow the simulation (per second).
const EASE_DOOR := 2.6
const EASE_CELL := 1.4
const EASE_WORK := 1.8
const EASE_WEATHER := 1.2
## The Sun's place in the sky (the light's pitch and yaw, degrees).
const SUN_PITCH := -62.0
const SUN_YAW := 28.0

## The leaf's colours (§3.11: chartreuse light at the top, emerald in the middle, deep teal-green below).
const HAZE_TOP := Color("cdee7a")
const HAZE_MID := Color("3aa262")
const HAZE_LOW := Color("10504a")
const OUTSIDE := Color("d9eef3")
const COLUMN := Color("62bf4f")
const CELL := Color("74d068")
const CELL_DRY := Color("a8d49a")
const WORK_DIM := Color("3e7c48")
const WORK_LIT := Color("f0ff86")
const GUARD := Color("42d25f")
const PAVING := Color("7fbf6c")
const GROOVE := Color("2f6a45")
const UNDERSIDE := Color("a3dc86")
const SHEATH := Color(0.86, 0.97, 0.8, 0.24)
const BLUE := Color("3d9bff")
const GOLD := Color("ffc23b")
const SUGAR := Color("ffc93e")
const DROP := Color("4bb6ff")
const MIST := Color("a9e0ff")
const SPARK := Color("fff3ad")
const PUFF := Color("c3c9cf")
const PUFF_CORE := Color("2b2f33")
const PUFF_RED := Color("e5484d")
## The weathers' looks: the Sun's colour and energy, the ambient fill, the beams (0-1), the Sun's disc, the sky (top,
## horizon) and the tint of the glowing far parts (the haze, the roof).
const LOOKS := {
	"blaze": {"sun": Color("fff3d6"), "energy": 1.15, "ambient": Color("d8eeb8"), "fill": 1.18, "rays": 1.0, "disc": 1.0,
		"top": Color("4aa2ee"), "low": Color("e2f4ff"), "tint": Color(1.0, 1.0, 1.0)},
	"cloud": {"sun": Color("d2ece3"), "energy": 0.66, "ambient": Color("b3d8c7"), "fill": 0.98, "rays": 0.3, "disc": 0.25,
		"top": Color("7c9fb8"), "low": Color("cfe0e8"), "tint": Color(0.78, 0.86, 0.88)},
	"evening": {"sun": Color("ffc58c"), "energy": 0.62, "ambient": Color("e0bf98"), "fill": 0.84, "rays": 0.5, "disc": 0.7,
		"top": Color("5b6fb5"), "low": Color("ffc89a"), "tint": Color(1.0, 0.84, 0.72)},
	"night": {"sun": Color("8197ff"), "energy": 0.22, "ambient": Color("34497a"), "fill": 0.62, "rays": 0.0, "disc": 0.0,
		"top": Color("0b1640"), "low": Color("223773"), "tint": Color(0.2, 0.27, 0.45)},
	"desert_day": {"sun": Color("fffaf0"), "energy": 1.32, "ambient": Color("eef0cc"), "fill": 1.18, "rays": 1.0, "disc": 1.2,
		"top": Color("6fb6f0"), "low": Color("fff6e0"), "tint": Color(1.04, 1.02, 0.95)},
	"desert_night": {"sun": Color("8197ff"), "energy": 0.24, "ambient": Color("34497a"), "fill": 0.64, "rays": 0.0,
		"disc": 0.0, "top": Color("0a1238"), "low": Color("1f2f66"), "tint": Color(0.2, 0.26, 0.46)},
}

var dressing := "sunflower"
var space: LeafSpace
var key_light: DirectionalLight3D
var dress: CactusDressing
## What the place shows now (eased toward the simulation): each door's opening (0 shut, 1 open), each cell's fullness
## (0 thirsty, 1 full), the workshops' glow, sugar waiting, the bud's gold (0-1), the weather.
var opening: Array[float] = []
var fullness: Array[float] = []
var glow_work := 0.0
var waiting := 0
var bud_fill := 0.0
var weather_kind := "blaze"
var heat := 1.0

var _body: Node3D
var _cells_full: MultiMeshInstance3D
var _cells_dry: MultiMeshInstance3D
var _columns: MultiMeshInstance3D
var _workshops: MultiMeshInstance3D
var _guards_shut: MultiMeshInstance3D
var _guards_open: MultiMeshInstance3D
var _slits: MultiMeshInstance3D
var _puffs: MultiMeshInstance3D
var _sugars: MultiMeshInstance3D
var _drops: MultiMeshInstance3D
var _mist: CPUParticles3D
var _sparks: CPUParticles3D
var _rays: MeshInstance3D
var _roof: MeshInstance3D
var _haze: MeshInstance3D
var _sky_dome: MeshInstance3D
var _sun_disc: MeshInstance3D
var _halo: MeshInstance3D
var _cloud: MeshInstance3D
var _bud: MeshInstance3D
var _bud_gold: MeshInstance3D
var _want_open: Array[float] = []
var _want_full := 0.9
var _want_work := 0.0
var _want_bud := 0.0
var _look := {}
var _look_from := {}
var _look_t := 1.0
var _tinted := []        # [{mi, arrays (the mesh's own), base (its colours)}]: glowing far parts the weather tints
var _tint := Color.WHITE
var _sky_tint := []
var _sugar_scale: Array[float] = []
## The spots in the order sugar waits at them: the first `waiting` show; the one a child takes goes last (`take_sugar`).
var _sugar_order: Array[int] = []
var _work_spots: Array[Dictionary] = []    # {host: column/cell index, kind, dir, h, lean}
var _puff_state: Array[Dictionary] = []    # {door, phase, at, to, t, spin, k}
var _drop_state: Array[Dictionary] = []    # {from, to, t, dur}
var _clock := 0.0
var _lift := 1.0
var _want_lift := 1.0
var _mist_doors := "-"
var _cell_shown: Array[float] = []     # each cell's fullness as last written (-1: never)
var _door_shown: Array[float] = []     # each door's opening as last written
var _work_shown := -1.0                # the workshops' glow as last written
var _work_tint := Color(-1, -1, -1)
var _under_mesh: LeafKit.Mesher
## B2: built in steps over several frames (`build_step`), and whole yet.
var staged := false
var built := false
var _steps: Array[Callable] = []
var _driven := -1


func _init(leaf_dressing: String = "sunflower", leaf_seed: int = 0) -> void:
	super()
	name = "LeafPlace"
	dressing = leaf_dressing
	space = LeafSpace.make(dressing, leaf_seed)
	start_view = WORK


func build() -> void:
	_body = Node3D.new()
	_body.name = "Leaf"
	add_child(_body)
	weather_kind = "desert_day" if dressing == "cactus" else "blaze"
	_look = (LOOKS[weather_kind] as Dictionary).duplicate()
	_look_from = _look.duplicate()
	env = LeafKit.environment(HAZE_MID, _look.ambient, _look.fill)
	key_light = LeafKit.sun(self, SUN_PITCH, SUN_YAW, _look.sun, _look.energy)
	for d in space.doors:
		opening.append(0.0)
		_want_open.append(0.0)
	for c in space.cells:
		fullness.append(0.9)
		_cell_shown.append(-1.0)
	for d in space.doors:
		_door_shown.append(-1.0)
	_steps = [_build_sky, _build_haze, _build_roof, _build_rays, _build_columns, _build_cells, _build_workshops,
		_build_vein, _build_floor, _build_doors, _build_puffs, _build_sugars, _build_drops, _build_mist, _build_sparks,
		_build_dressing, _targets_and_views, _finish_build]
	if not staged:
		while not build_step():
			pass


## B2: one more piece of the place (a builder: a few milliseconds); true once it is whole. A `staged` place (set before
## it enters the tree) builds only this way, so the host spreads it over the garden's frames (a phone never stops for
## the whole leaf at once); any other builds whole at once.
func build_step() -> bool:
	if _steps.is_empty():
		return true
	var step: Callable = _steps.pop_front()
	step.call()
	return _steps.is_empty()


func _build_dressing() -> void:
	if dressing == "cactus":
		dress = CactusDressing.new(self)
		_body.add_child(dress)


func _finish_build() -> void:
	_apply_all(0.0)
	built = true


# --- The simulation, shown ------------------------------------------------------------------------------------------

## Each frame (B2's host): the place eases toward the leaf's state and the weather.
func show_sim(sim: LeafSim, w: Dictionary, dt: float) -> void:
	_driven = Engine.get_process_frames()
	for i in mini(sim.doors.size(), _want_open.size()):
		var was := _want_open[i]
		_want_open[i] = 1.0 if sim.doors[i] else 0.0
		if was > 0.5 and _want_open[i] < 0.5:
			pulse_drops(i)
	_want_full = sim.water
	_want_work = sim.work()
	waiting = sim.waiting()
	_want_bud = clampf(sim.bud / maxf(float(sim.params.get("bud", 12)), 1.0), 0.0, 1.0)
	heat = float(w.get("heat", 1.0))
	set_weather(str(w.get("kind", weather_kind)))
	_want_lift = 1.0 if sim.standing() else 0.0
	if dress:
		dress.show_jars(sim.jars, float(sim.params.get("jar_cap", 8.0)))
	_apply_all(dt)


## The weather's look (light, ambient, beams, the Sun, the sky, the far parts' tint), eased over about a second.
func set_weather(kind: String) -> void:
	if kind == weather_kind or not LOOKS.has(kind):
		return
	weather_kind = kind
	_look_from = _look.duplicate()
	_look_t = 0.0


## Blue drops from the vein to the cells by a door just shut (they plump with a bloop as the drops arrive).
func pulse_drops(door: int) -> void:
	if door < 0 or door >= space.doors.size():
		return
	var from: Vector3 = space.vein.blue_mouth
	var at: Vector3 = space.doors[door].at
	for k in 4:
		var to := at + Vector3(randf_range(-1.6, 1.6), randf_range(1.6, 2.6), randf_range(-1.6, 1.6))
		_drop_state.append({"from": from, "to": to, "t": -0.12 * k, "dur": 1.1 + 0.1 * k})
	while _drop_state.size() > DROPS:
		_drop_state.pop_front()


## The leaf lifts as its cells fill (1: standing, 0: drooping): the whole inside tilts a little.
func set_lift(standing: float) -> void:
	_want_lift = clampf(standing, 0.0, 1.0)


## Everything at once, for the tests, the budget and the pictures: every door open, a sugar at every spot, the
## workshops glowing, puffs drifting in, drops on their way, the mist and the sparks; or the night's look.
func show_all(night: bool = false) -> void:
	for i in _want_open.size():
		_want_open[i] = 1.0
	_want_full = 0.92
	_want_work = 0.0 if night else 1.0
	waiting = space.sugar_spots.size()
	_want_bud = 1.0
	set_weather(("desert_night" if dressing == "cactus" else "night") if night else
		("desert_day" if dressing == "cactus" else "cloud"))
	for i in 3:
		pulse_drops(i * 2)
	if dress:
		dress.show_jars(6.0, 8.0)
	for k in 30:
		_apply_all(0.2)


func _process(delta: float) -> void:
	super._process(delta)
	# Nothing to show before it is whole or while it is hidden; a frame a host drove (show_sim) is shown already.
	if built and is_visible_in_tree() and _driven != Engine.get_process_frames():
		_apply_all(delta)


func _apply_all(dt: float) -> void:
	_clock += dt
	for i in opening.size():
		opening[i] = move_toward(opening[i], _want_open[i], EASE_DOOR * dt) if dt > 0.0 else _want_open[i]
	glow_work = move_toward(glow_work, _want_work, EASE_WORK * dt) if dt > 0.0 else _want_work
	bud_fill = move_toward(bud_fill, _want_bud, 0.5 * dt) if dt > 0.0 else _want_bud
	_lift = move_toward(_lift, _want_lift, 0.35 * dt) if dt > 0.0 else _want_lift
	_body.rotation.x = deg_to_rad(-2.5) * (1.0 - _lift)
	_apply_weather(dt)
	_apply_cells(dt)
	_apply_doors()
	_apply_workshops()
	_apply_sugars(dt)
	_apply_puffs(dt)
	_apply_drops(dt)
	_apply_mist()
	_apply_bud()


# --- Building ------------------------------------------------------------------------------------------------------

static func sun_dir() -> Vector3:
	return Basis.from_euler(Vector3(deg_to_rad(SUN_PITCH), deg_to_rad(SUN_YAW), 0)) * Vector3.FORWARD


## A basis whose +Y (a disc's face) points along `normal`.
static func _facing(normal: Vector3) -> Basis:
	var y := normal.normalized()
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.95 else Vector3.RIGHT).normalized()
	return Basis(x, y, x.cross(y))


func _build_sky() -> void:
	var m := LeafKit.Mesher.new()
	var first := m.count()
	var seg := 28
	var rings := 10
	for r in rings + 1:
		var phi := PI * 0.5 * r / rings
		for k in seg + 1:
			var th := TAU * k / seg
			var dir := Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th))
			m._add(Vector3(0, LeafSpace.ROOF, 0) + dir * 38.0, -dir, Color.WHITE)
	m._grid(first, rings + 1, seg + 1, true)
	_sky_dome = LeafKit.mesh(_body, "Sky", m.commit(), LeafKit.glow())
	var to_sun := -sun_dir()
	var sun_at := Vector3(0, LeafSpace.ROOF, 0) + to_sun * 34.0
	var d := LeafKit.Mesher.new()
	d.disc(Transform3D(_facing(-to_sun), sun_at), 2.6, Color("fffbe8"), Color("ffe9a6"), 24)
	_sun_disc = LeafKit.mesh(_body, "SunDisc", d.commit(), LeafKit.glow())
	_halo = LeafKit.glow_disc(_body, "SunHalo", sun_at + to_sun * 0.3, -to_sun, 8.0, Color(1.0, 0.93, 0.62, 0.42))
	var c := LeafKit.Mesher.new()
	for b: Array in [[0.0, 0.0, 0.0, 3.0], [2.6, -0.3, 0.6, 2.4], [-2.5, -0.4, -0.3, 2.3], [1.0, 0.9, -0.4, 2.1],
			[-1.2, 0.8, 0.5, 2.0], [4.6, -0.7, -0.2, 1.6], [-4.4, -0.8, 0.4, 1.5]]:
		c.ball(Transform3D(Basis().scaled(Vector3(1, 0.62, 1)), Vector3(b[0], b[1], b[2])), float(b[3]), Color.WHITE,
			Color("dfe6ee"), 14, 8)
	_cloud = LeafKit.mesh(_body, "Cloud", c.commit(), LeafKit.glow())
	var b := LeafKit.Mesher.new()
	b.ball(Transform3D(Basis().scaled(Vector3(1.0, 0.72, 1.0)), Vector3.ZERO), 4.2, Color("4f7d37"), Color("2c4a22"), 18, 10,
		0.05, 1.3, 0.0)
	for k in 14:   # its bracts round the rim, soft leaves curving down: a sunflower's head seen from below
		var th := TAU * k / 14.0
		var out := Vector3(cos(th), 0, sin(th))
		var bract := Basis(Vector3.UP, -th) * Basis(Vector3.FORWARD, -0.55) * Basis().scaled(Vector3(1.25, 0.22, 0.75))
		b.ball(Transform3D(bract, out * 4.1 + Vector3(0, -0.9, 0)), 1.0, Color("6a9c45"), Color("3c6229"), 10, 5)
	if dressing == "cactus":   # the cactus's flower bud: pale, smooth, long (it opens white under the moon)
		b = LeafKit.Mesher.new()
		b.ball(Transform3D(Basis().scaled(Vector3(0.62, 1.0, 0.62)), Vector3.ZERO), 3.6, Color("e7f0d8"), Color("9fb98a"), 18, 10)
	_bud = LeafKit.mesh(_body, "Bud", b.commit(), LeafKit.glow())
	_bud.position = Vector3(1.5, 25.0, -7.0)
	var g := LeafKit.Mesher.new()
	g.ball(Transform3D(Basis().scaled(Vector3(1.0, 0.22, 1.0)), Vector3.ZERO), 3.7, Color("ffe68a"), Color("ffb52e"), 18, 8)
	_bud_gold = LeafKit.mesh(_bud, "Gold", g.commit(), LeafKit.glow())
	_bud_gold.position = Vector3(0, -2.75, 0)


func _build_haze() -> void:
	var m := LeafKit.Mesher.new()
	var seg := 40
	var heights := [-8.0, -0.3, 0.6, 3.5, 7.0, LeafSpace.ROOF + 0.4]
	var colours := [OUTSIDE.lerp(Color("eef8ff"), 0.4), OUTSIDE, HAZE_LOW, HAZE_MID, HAZE_MID.lerp(HAZE_TOP, 0.55),
		HAZE_TOP]
	var first := m.count()
	for r in heights.size():
		for k in seg + 1:
			var th := TAU * k / seg
			var dir := Vector3(cos(th), 0, sin(th))
			m._add(dir * HAZE + Vector3(0, heights[r], 0), -dir, colours[r])
	m._grid(first, heights.size(), seg + 1)
	# Far cells and columns in the haze: the leaf goes on.
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for k in 34:
		var th := TAU * k / 34.0 + rng.randf_range(-0.05, 0.05)
		var dist := rng.randf_range(10.4, 12.8)
		var y := rng.randf_range(1.2, 4.2)
		var r := rng.randf_range(1.0, 1.6)
		var depth := clampf((dist - 9.5) / 4.0, 0.0, 1.0)
		var col := CELL.darkened(0.2).lerp(_haze_at(y), 0.35 + depth * 0.5)
		m.ball(Transform3D(Basis(), Vector3(cos(th) * dist, y, sin(th) * dist)), r, col.lightened(0.08), col.darkened(0.1),
			10, 6, 0.05, float(k))
	for k in 30:
		var th := TAU * k / 30.0 + rng.randf_range(-0.06, 0.06)
		var dist := rng.randf_range(9.8, 12.6)
		var depth := clampf((dist - 9.5) / 4.0, 0.0, 1.0)
		var col := COLUMN.darkened(0.1).lerp(_haze_at(7.5), 0.35 + depth * 0.5)
		m.capsule(Transform3D(Basis(), Vector3(cos(th) * dist, LeafSpace.COLUMNS_FROM, sin(th) * dist)), 0.7, 4.9,
			col.lightened(0.12), col.darkened(0.08), 10, 3)
	_haze = LeafKit.mesh(_body, "Haze", m.commit(), LeafKit.glow())
	_tint_later(_haze)


func _haze_at(y: float) -> Color:
	if y < 3.5:
		return HAZE_LOW.lerp(HAZE_MID, clampf((y - 0.6) / 2.9, 0.0, 1.0))
	return HAZE_MID.lerp(HAZE_TOP, clampf((y - 3.5) / 6.5, 0.0, 1.0))


func _build_roof() -> void:
	var m := LeafKit.Mesher.new()
	var y := LeafSpace.ROOF
	var cactus := dressing == "cactus"
	var n := 10
	var first := m.count()
	var toward_sun := -sun_dir()
	for r in n + 1:
		for k in n + 1:
			var x := (float(k) / n - 0.5) * HAZE * 2.0
			var z := (float(r) / n - 0.5) * HAZE * 2.0
			var near := clampf(0.5 + 0.5 * Vector2(x, z).normalized().dot(Vector2(toward_sun.x, toward_sun.z)) * \
				clampf(Vector2(x, z).length() / HAZE, 0.0, 1.0), 0.0, 1.0)
			var col := Color(0.92, 1.0, 0.76, 0.12 + 0.12 * near) if not cactus else Color(0.86, 0.9, 0.8, 0.38 + 0.1 * near)
			m._add(Vector3(x, y, z), Vector3.DOWN, col)
	m._grid(first, n + 1, n + 1)
	# The upper skin's cells: faint wax outlines.
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var line := Color(0.98, 1.0, 0.86, 0.08) if not cactus else Color(0.95, 0.96, 0.9, 0.14)
	for row in range(-6, 7):
		for col in range(-5, 6):
			var cx := col * 2.6 + (1.3 if row % 2 != 0 else 0.0) + rng.randf_range(-0.3, 0.3)
			var cz := row * 2.25 + rng.randf_range(-0.3, 0.3)
			for e in 6:
				var a := TAU * e / 6.0 + PI / 6.0
				var b := TAU * (e + 1) / 6.0 + PI / 6.0
				var p0 := Vector3(cx + cos(a) * 1.45, y - 0.02, cz + sin(a) * 1.45)
				var p1 := Vector3(cx + cos(b) * 1.45, y - 0.02, cz + sin(b) * 1.45)
				m.quad(p0, p1 - p0, Vector3(0, 0, 0.05).rotated(Vector3.UP, -a), line, line)
	_roof = LeafKit.mesh(_body, "Roof", m.commit(), LeafKit.glass())
	_tint_later(_roof)


## The light's soft beams through the skylight, slanting down onto the doors: each three crossed panes whose middles
## glow and whose edges fade, so a beam looks round from anywhere.
func _build_rays() -> void:
	var m := LeafKit.Mesher.new()
	var down := sun_dir()
	var along_unit := down / absf(down.y)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var spots := [Vector3(-2.2, 0, -2.4), Vector3(1.4, 0, -3.0), Vector3(3.6, 0, -0.4), Vector3(-4.0, 0, 0.2),
		Vector3(0.2, 0, 0.6), Vector3(-0.8, 0, -4.6), Vector3(2.8, 0, 1.8), Vector3(-2.6, 0, 2.2)]
	for s: Vector3 in spots:
		var length := LeafSpace.ROOF - rng.randf_range(0.2, 1.4)
		var top := Vector3(s.x, LeafSpace.ROOF - 0.05, s.z) - along_unit * 0.0
		var along := along_unit * length
		var w := rng.randf_range(1.0, 1.9)
		var a := rng.randf_range(0.07, 0.11)
		for p in 3:
			var across := (along.normalized().cross(Vector3.UP).normalized()).rotated(along.normalized(), PI * p / 3.0) * w
			_soft_pane(m, top, along, across, a)
	_rays = LeafKit.mesh(_body, "Rays", m.commit(), LeafKit.glass())


## A pane from `top` along `along`, `across` wide: bright in its middle line (alpha `a` at the top, nothing at the
## bottom), fading to nothing at its sides.
static func _soft_pane(m: LeafKit.Mesher, top: Vector3, along: Vector3, across: Vector3, a: float) -> void:
	var glow_top := Color(1.0, 0.97, 0.82, a)
	var glow_low := Color(1.0, 0.97, 0.82, 0.0)
	var edge := Color(1.0, 0.97, 0.82, 0.0)
	var nn := along.cross(across).normalized()
	var l0 := m._add(top - across * 0.5, nn, edge)
	var c0 := m._add(top, nn, glow_top)
	var r0 := m._add(top + across * 0.5, nn, edge)
	var l1 := m._add(top + along - across * 0.5, nn, edge)
	var c1 := m._add(top + along, nn, glow_low)
	var r1 := m._add(top + along + across * 0.5, nn, edge)
	m.tri(l0, c0, c1)
	m.tri(l0, c1, l1)
	m.tri(c0, r0, r1)
	m.tri(c0, r1, c1)


func _build_columns() -> void:
	var m := LeafKit.Mesher.new()
	m.capsule(Transform3D(), 1.0, LeafSpace.COLUMNS_TO - LeafSpace.COLUMNS_FROM, Color(1.0, 1.0, 0.86),
		Color(0.9, 0.96, 0.86), 16, 5)
	var bounds := AABB(Vector3(-HAZE, LeafSpace.COLUMNS_FROM - 1.0, -HAZE), Vector3(HAZE * 2.0, 7.0, HAZE * 2.0))
	_columns = LeafKit.multimesh(_body, "Columns", m.commit(), LeafKit.lit(), maxi(space.columns.size(), 1), bounds)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(dressing) + 5
	var base := COLUMN if dressing != "cactus" else Color("6fb85a")
	for i in space.columns.size():
		var k: Dictionary = space.columns[i]
		var r := float(k.radius)
		var basis := Basis(Vector3.UP, float(k.turn)).scaled(Vector3(r, 1.0, r))
		_columns.multimesh.set_instance_transform(i, Transform3D(basis, k.at))
		var tint := base.lerp(Color("8fd25c"), rng.randf_range(0.0, 0.35)).darkened(rng.randf_range(0.0, 0.05))
		_columns.multimesh.set_instance_color(i, tint)


func _build_cells() -> void:
	var full := LeafKit.Mesher.new()
	full.ball(Transform3D(), 1.0, Color(1.0, 1.0, 0.94), Color(0.8, 0.88, 0.8), 18, 12, 0.07, 0.6, 0.2)
	var dry := LeafKit.Mesher.new()
	dry.ball(Transform3D(), 1.0, Color(1.0, 0.99, 0.92), Color(0.78, 0.8, 0.72), 24, 16, 0.11, 5.3, 0.08)
	var bounds := AABB(Vector3(-HAZE, -1.0, -HAZE), Vector3(HAZE * 2.0, 8.0, HAZE * 2.0))
	var n := space.cells.size()
	_cells_full = LeafKit.multimesh(_body, "CellsFull", full.commit(), LeafKit.lit(), n, bounds)
	_cells_dry = LeafKit.multimesh(_body, "CellsThirsty", dry.commit(), LeafKit.lit(), n, bounds)


func _build_workshops() -> void:
	var m := LeafKit.Mesher.new()
	m.ball(Transform3D(Basis().scaled(Vector3(1.0, 0.64, 0.4)), Vector3.ZERO), 0.29, Color(1, 1, 1), Color(0.84, 0.88, 0.82),
		12, 6, 0.0, 0.0, 0.25)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(dressing) + 9
	var cactus := dressing == "cactus"
	for i in space.columns.size():
		for k in (8 if not cactus else 10):
			var th := rng.randf_range(0.0, TAU)
			_work_spots.append({"host": i, "kind": "column", "dir": Vector3(cos(th), 0, sin(th)),
				"h": rng.randf_range(0.5, LeafSpace.COLUMNS_TO - LeafSpace.COLUMNS_FROM - 0.5),
				"lean": rng.randf_range(-0.6, 0.6)})
	for i in space.cells.size():
		if str(space.cells[i].kind) != "spongy":
			continue
		for k in 4:
			var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.2, 1.0), rng.randf_range(-1, 1)).normalized()
			_work_spots.append({"host": i, "kind": "cell", "dir": dir, "h": 0.0, "lean": rng.randf_range(-0.6, 0.6)})
	var bounds := AABB(Vector3(-HAZE, -1.0, -HAZE), Vector3(HAZE * 2.0, 12.0, HAZE * 2.0))
	_workshops = LeafKit.multimesh(_body, "Workshops", m.commit(), LeafKit.glow(), maxi(_work_spots.size(), 1), bounds)


func _build_vein() -> void:
	var v: Dictionary = space.vein
	var a := Vector3(-HAZE, (v.from as Vector3).y, (v.from as Vector3).z)
	var b := Vector3(HAZE, (v.to as Vector3).y, (v.to as Vector3).z)
	var sheath := LeafKit.Mesher.new()
	sheath.tube(a, b, float(v.radius), float(v.radius), SHEATH, SHEATH, 24, false)
	sheath.tube(a + Vector3(0, 0, 0), b, float(v.radius) * 1.04, float(v.radius) * 1.04, Color(0.95, 1.0, 0.9, 0.08),
		Color(0.95, 1.0, 0.9, 0.08), 24, false)
	_tint_later(LeafKit.mesh(_body, "VeinSheath", sheath.commit(), LeafKit.glass()))
	var pipes := LeafKit.Mesher.new()
	var pr := float(v.pipe)
	var blue_off: Vector3 = v.blue
	var gold_off: Vector3 = v.gold
	pipes.tube(a + blue_off, b + blue_off, pr, pr, BLUE, BLUE.lightened(0.15), 18, false)
	pipes.tube(a + gold_off, b + gold_off, pr, pr, GOLD, GOLD.lightened(0.1), 18, false)
	for off: Vector3 in [blue_off, gold_off]:   # glossy highlights along the tops
		var col := BLUE.lightened(0.55) if off == blue_off else GOLD.lightened(0.5)
		pipes.tube(a + off + Vector3(0, pr * 0.78, 0.06), b + off + Vector3(0, pr * 0.78, 0.06), pr * 0.18, pr * 0.18, col, col,
			6, false)
	var gold_mouth: Vector3 = v.gold_mouth
	var blue_mouth: Vector3 = v.blue_mouth
	var gold_root: Vector3 = Vector3(gold_mouth.x, (v.from as Vector3).y, (v.from as Vector3).z) + gold_off
	var blue_root: Vector3 = Vector3(blue_mouth.x, (v.from as Vector3).y, (v.from as Vector3).z) + blue_off
	pipes.tube(gold_root, gold_mouth, pr * 0.8, 0.5, GOLD.darkened(0.05), GOLD.lightened(0.2), 18, false)
	pipes.tube(blue_root, blue_mouth, pr * 0.8, 0.45, BLUE.darkened(0.05), BLUE.lightened(0.2), 18, false)
	LeafKit.mesh(_body, "VeinPipes", pipes.commit(), LeafKit.lit())
	var rims := LeafKit.Mesher.new()
	for mouth: Array in [[gold_mouth, gold_root, 0.5, Color("fff0a8"), Color("ffcf4a")],
			[blue_mouth, blue_root, 0.45, Color("c9ecff"), Color("6cc2ff")]]:
		var m_at: Vector3 = mouth[0]
		var dir := (m_at - (mouth[1] as Vector3)).normalized()
		rims.tube(m_at - dir * 0.08, m_at + dir * 0.04, float(mouth[2]) + 0.06, float(mouth[2]) + 0.06, mouth[3], mouth[3],
			20, false)
		rims.disc(Transform3D(_facing(dir), m_at - dir * 0.3), float(mouth[2]) * 0.9, mouth[4], (mouth[4] as Color).darkened(0.3),
			20)
	LeafKit.mesh(_body, "VeinMouths", rims.commit(), LeafKit.glow())


## The leaf's lower skin: soft, irregular cells (each a little dome over a dark groove), open where the doors are, and
## their undersides seen from below (the dive arrives there).
func _build_floor() -> void:
	var m := LeafKit.Mesher.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(dressing) + 21
	# The dark grooves everywhere between the cells (seen from above only), and the leaf's underside (from below only):
	# the doors' guard cells and slits reach through both.
	m.disc(Transform3D(Basis(), Vector3(0, -0.045, 0)), HAZE + 0.5, GROOVE, GROOVE.darkened(0.15), 48)
	var under := LeafKit.Mesher.new()   # seen only from below (the dive's arrival), lit softly by the sky under the leaf
	under.disc(Transform3D(Basis(Vector3.RIGHT, PI), Vector3(0, -FLOOR_DEPTH - 0.012, 0)), HAZE + 0.5, UNDERSIDE.darkened(0.18),
		UNDERSIDE.darkened(0.3), 48)
	_under_mesh = under
	var size := 1.0
	var dx := size * sqrt(3.0)
	var dz := size * 1.5
	for row in range(-11, 12):
		for col in range(-9, 10):
			var x := col * dx + (dx * 0.5 if row % 2 != 0 else 0.0) + rng.randf_range(-0.2, 0.2)
			var z := row * dz + rng.randf_range(-0.2, 0.2)
			if Vector2(x, z).length() > HAZE:
				continue
			if _near_door(Vector3(x, 0, z), 1.75):
				continue
			_skin_cell(m, rng, Vector3(x, 0, z), size * rng.randf_range(0.86, 1.04))
	for d in space.doors:
		var at: Vector3 = d.at
		var yaw := float(d.yaw)
		var pit := float(d.pit)
		for k in 9:
			var th := TAU * k / 9.0
			var p := at + Basis(Vector3.UP, yaw) * Vector3(cos(th) * (1.82 + pit), pit * 1.4, sin(th) * (1.36 + pit))
			_skin_cell(m, rng, p, 0.55 + pit * 0.4, true)
		if pit > 0.0:   # the cactus's door sunk in a pit: a slope of skin up to a raised rim
			var ring := Basis(Vector3.UP, yaw)
			for k in 18:
				var a0 := TAU * k / 18.0
				var a1 := TAU * (k + 1) / 18.0
				var inner0 := at + ring * Vector3(cos(a0) * 1.45, 0.0, sin(a0) * 1.15)
				var inner1 := at + ring * Vector3(cos(a1) * 1.45, 0.0, sin(a1) * 1.15)
				var outer0 := at + ring * Vector3(cos(a0) * (1.95 + pit), pit * 1.3, sin(a0) * (1.55 + pit))
				var outer1 := at + ring * Vector3(cos(a1) * (1.95 + pit), pit * 1.3, sin(a1) * (1.55 + pit))
				var n0 := (inner0 - at).normalized() * -0.5 + Vector3.UP
				var q0 := m._add(inner0, n0.normalized(), PAVING.darkened(0.25))
				var q1 := m._add(inner1, n0.normalized(), PAVING.darkened(0.25))
				var q2 := m._add(outer1, n0.normalized(), PAVING.lightened(0.05))
				var q3 := m._add(outer0, n0.normalized(), PAVING.lightened(0.05))
				m.tri(q0, q2, q1)
				m.tri(q0, q3, q2)
	LeafKit.mesh(_body, "Floor", m.commit(), LeafKit.lit())
	var floor_under := LeafKit.mesh(_body, "FloorUnder", _under_mesh.commit(), LeafKit.glow())
	_tint_later(floor_under)
	_under_mesh = null


## One skin cell at `at`: an irregular dome on top, its dark groove a little wider below, and its underside.
func _skin_cell(m: LeafKit.Mesher, rng: RandomNumberGenerator, at: Vector3, radius: float, small: bool = false) -> void:
	var sides := 7
	var ring := PackedVector3Array()
	var spin := rng.randf_range(0.0, TAU)
	for k in sides:
		var th := spin + TAU * k / sides
		var r := radius * rng.randf_range(0.82, 1.05)
		ring.append(Vector3(cos(th) * r, 0, sin(th) * r))
	var shade := rng.randf_range(-0.07, 0.07)
	var top := PAVING.lightened(maxf(shade, 0.0)).darkened(maxf(-shade, 0.0))
	if small:
		top = top.lightened(0.06)
	_polygon(m, at + Vector3(0, 0.0, 0), ring, 0.94, top.lightened(0.16), top.darkened(0.05),
		rng.randf_range(0.08, 0.16), true)
	_polygon(_under_mesh, at + Vector3(0, -FLOOR_DEPTH, 0), ring, 0.96, UNDERSIDE.lightened(0.06 + shade),
		UNDERSIDE.darkened(0.12), rng.randf_range(0.06, 0.12), false)


## A flat polygon round `centre` (its ring scaled by `scale`), its middle raised by `dome` (lowered when facing down).
static func _polygon(m: LeafKit.Mesher, centre: Vector3, ring: PackedVector3Array, scale: float, mid: Color,
		edge: Color, dome: float, up: bool) -> void:
	var nn := Vector3.UP if up else Vector3.DOWN
	var c := m._add(centre + nn * dome, nn, mid)
	var first := m.count()
	for p in ring:
		m._add(centre + p * scale, (nn * 0.7 + p.normalized() * 0.3).normalized(), edge)
	var n := ring.size()
	for k in n:
		if up:
			m.tri(c, first + k, first + (k + 1) % n)
		else:
			m.tri(c, first + (k + 1) % n, first + k)


func _near_door(p: Vector3, reach: float) -> bool:
	for d in space.doors:
		var at: Vector3 = d.at
		var local := Basis(Vector3.UP, -float(d.yaw)) * (p - at)
		if pow(local.x / (reach * 1.0), 2) + pow(local.z / (reach * 1.25), 2) < 1.0:
			return true
	return false


func _build_doors() -> void:
	var bounds := AABB(Vector3(-HAZE, -1.0, -HAZE), Vector3(HAZE * 2.0, 3.0, HAZE * 2.0))
	var n := space.doors.size()
	var shut := LeafKit.Mesher.new()
	shut.bean(Transform3D(), 2.3, 0.8, 0.46, 0.33, Color(1.0, 1.0, 0.94), Color(0.74, 0.82, 0.74), 14, 18, 0.12, -1.0)
	_guards_shut = LeafKit.multimesh(_body, "GuardCellsShut", shut.commit(), LeafKit.lit(), n * 2, bounds)
	var open := LeafKit.Mesher.new()
	open.bean(Transform3D(), 2.3, 0.78, 0.46, 0.62, Color(1.0, 1.0, 0.94), Color(0.74, 0.82, 0.74), 14, 18, 0.12, -1.0)
	_guards_open = LeafKit.multimesh(_body, "GuardCellsOpen", open.commit(), LeafKit.lit(), n * 2, bounds)
	var slit := LeafKit.Mesher.new()
	slit.ball(Transform3D(), 1.0, Color("143f35"), Color("0a2622"), 16, 8, 0.0, 0.0, 0.0)
	_slits = LeafKit.multimesh(_body, "Slits", slit.commit(), LeafKit.glow(), n, bounds)
	for i in n:
		for k in 2:
			var col := GUARD if k == 0 else GUARD.lerp(Color("62da6c"), 0.35)
			_guards_shut.multimesh.set_instance_color(i * 2 + k, col)
			_guards_open.multimesh.set_instance_color(i * 2 + k, col)
		_slits.multimesh.set_instance_color(i, Color.WHITE)


func _build_puffs() -> void:
	var m := LeafKit.Mesher.new()
	for b: Array in [[Vector3(0, 0, 0), 0.17], [Vector3(0.13, 0.05, -0.04), 0.13], [Vector3(-0.12, 0.04, 0.03), 0.13],
			[Vector3(0.02, 0.12, 0.02), 0.11]]:
		m.ball(Transform3D(Basis(), b[0]), float(b[1]), PUFF.lightened(0.18), PUFF.darkened(0.12), 10, 6, 0.0, 0.0, 0.2)
	m.ball(Transform3D(Basis(), Vector3(0, 0.02, 0.15)), 0.075, PUFF_CORE.lightened(0.1), PUFF_CORE, 8, 5)
	m.ball(Transform3D(Basis(), Vector3(0.11, 0.0, 0.13)), 0.05, PUFF_RED.lightened(0.15), PUFF_RED, 8, 5)
	m.ball(Transform3D(Basis(), Vector3(-0.11, 0.0, 0.13)), 0.05, PUFF_RED.lightened(0.15), PUFF_RED, 8, 5)
	var n := space.doors.size() * PUFFS_PER_DOOR
	var bounds := AABB(Vector3(-HAZE, -2.0, -HAZE), Vector3(HAZE * 2.0, 13.0, HAZE * 2.0))
	_puffs = LeafKit.multimesh(_body, "AirPuffs", m.commit(), LeafKit.lit(), n, bounds)
	for i in n:
		var door := i / PUFFS_PER_DOOR
		_puff_state.append({"door": door, "phase": "wait", "at": _under_door(door, i), "to": Vector3.ZERO, "t": 0.0,
			"spin": randf_range(0.0, TAU), "k": i % PUFFS_PER_DOOR})


## Where a puff waits at a shut door: two under it, outside the leaf (the dive sees them), two squeezing up into the seam
## between the guard cells, trying to get in.
func _under_door(door: int, i: int) -> Vector3:
	var d: Dictionary = space.doors[door]
	var k := i % PUFFS_PER_DOOR
	var along := Basis(Vector3.UP, float(d.yaw)) * Vector3(0, 0, (k - 1.5) * 0.42)
	return (d.at as Vector3) + along + Vector3(0, -0.45 if k % 2 == 0 else 0.5, 0)


func _build_sugars() -> void:
	var m := LeafKit.Mesher.new()
	m.hexagon(Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(0, 0, -0.08)), 0.34, 0.16, Color("fff0a6"), SUGAR)
	m.hexagon(Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), Vector3(0, 0, 0.08)), 0.34, 0.16, Color("fff0a6"), SUGAR)
	var bounds := AABB(Vector3(-HAZE, -1.0, -HAZE), Vector3(HAZE * 2.0, 12.0, HAZE * 2.0))
	_sugars = LeafKit.multimesh(_body, "Sugars", m.commit(), LeafKit.glow(), space.sugar_spots.size(), bounds)
	for k in space.sugar_spots.size():
		_sugar_scale.append(0.0)
		_sugar_order.append(_sugar_order.size())


func _build_drops() -> void:
	var m := LeafKit.Mesher.new()
	m.ball(Transform3D(Basis().scaled(Vector3(1, 1.25, 1)), Vector3.ZERO), 0.09, Color("bfe8ff"), DROP, 10, 6)
	m.tube(Vector3(0, 0.08, 0), Vector3(0, 0.2, 0), 0.07, 0.005, DROP.lightened(0.2), Color("d8f2ff"), 10, false)
	var bounds := AABB(Vector3(-HAZE, -1.0, -HAZE), Vector3(HAZE * 2.0, 12.0, HAZE * 2.0))
	_drops = LeafKit.multimesh(_body, "Drops", m.commit(), LeafKit.glow(), DROPS, bounds)


## The mist: from the air of the leaf it streams into each open door (blue beads drawn down into the slit), and below the
## floor it pours out (the dive sees the plumes): one particle system, its points round the open doors.
func _build_mist() -> void:
	var m := LeafKit.Mesher.new()
	m.ball(Transform3D(), 0.12, Color.WHITE, Color(0.86, 0.94, 1.0), 8, 5)
	var mesh := m.commit()
	mesh.surface_set_material(0, LeafKit.glow())
	_mist = CPUParticles3D.new()
	_mist.name = "Mist"
	_mist.mesh = mesh
	_mist.amount = 200
	_mist.lifetime = 2.4
	_mist.local_coords = true
	_mist.emission_shape = CPUParticles3D.EMISSION_SHAPE_DIRECTED_POINTS
	_mist.emission_points = PackedVector3Array([Vector3.ZERO])
	_mist.emission_normals = PackedVector3Array([Vector3.DOWN])
	_mist.direction = Vector3(0, 0, 1)
	_mist.spread = 14.0
	_mist.initial_velocity_min = 0.55
	_mist.initial_velocity_max = 0.85
	_mist.damping_min = 0.0
	_mist.damping_max = 0.1
	_mist.gravity = Vector3(0, -0.15, 0)   # a gentle drift (the default 9.8 drops it through the floor at once)
	_mist.scale_amount_min = 0.8
	_mist.scale_amount_max = 1.3
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.25, 1.0))
	curve.add_point(Vector2(0.75, 0.85))
	curve.add_point(Vector2(1.0, 0.0))
	_mist.scale_amount_curve = curve
	_mist.color = MIST
	_mist.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mist.emitting = false
	_body.add_child(_mist)


func _build_sparks() -> void:
	var m := LeafKit.Mesher.new()
	m.ball(Transform3D(), 0.045, Color.WHITE, Color(1, 0.95, 0.8), 6, 3)
	var mesh := m.commit()
	mesh.surface_set_material(0, LeafKit.glow())
	_sparks = CPUParticles3D.new()
	_sparks.name = "LightSparks"
	_sparks.mesh = mesh
	_sparks.amount = 70
	_sparks.lifetime = 8.0
	_sparks.preprocess = 8.0
	_sparks.local_coords = true
	_sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_sparks.emission_box_extents = Vector3(5.0, 0.3, 4.6)
	_sparks.position = Vector3(0, LeafSpace.ROOF - 0.4, LeafSpace.SKYLIGHT_AT)
	_sparks.direction = sun_dir()
	_sparks.spread = 10.0
	_sparks.initial_velocity_min = 0.6
	_sparks.initial_velocity_max = 1.1
	_sparks.gravity = Vector3(0, -0.04, 0)
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(0.15, 1.0))
	curve.add_point(Vector2(0.8, 1.0))
	curve.add_point(Vector2(1.0, 0.0))
	_sparks.scale_amount_curve = curve
	_sparks.color = SPARK
	_sparks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_body.add_child(_sparks)


func _targets_and_views() -> void:
	var flat: Array[String] = []
	for i in space.doors.size():
		var d: Dictionary = space.doors[i]
		var at: Vector3 = d.at
		var name_i := "door_%d" % i
		add_spot_target(name_i, _body, at + Vector3(0, 0.2, 0), DOOR_RADIUS)
		flat.append(name_i)
		var side := Basis(Vector3.UP, float(d.yaw)) * Vector3.RIGHT
		var long := Basis(Vector3.UP, float(d.yaw)) * Vector3.BACK
		add_spot_target(name_i + "_a", _body, at + side * 0.42 + Vector3(0, 0.3, 0), BEAN_RADIUS)
		add_spot_target(name_i + "_b", _body, at - side * 0.42 + Vector3(0, 0.3, 0), BEAN_RADIUS)
		var toward := Vector3(-at.x, 0, 1.5 - at.z).normalized()
		var end := long if long.dot(toward) > 0.0 else -long
		var feet := at + end * 0.5
		add_view(name_i, at + toward * 3.2 + Vector3(0, 2.6, 0), at, feet, atan2(end.x, end.z))
		add_hand(name_i + "_a", name_i)
		add_hand(name_i + "_b", name_i)
	for k in space.sugar_spots.size():
		var p: Vector3 = space.sugar_spots[k]
		var name_k := "sugar_%d" % k
		add_spot_target(name_k, _body, p, SUGAR_RADIUS)
		flat.append(name_k)
		var back := Vector3(-p.x, 0, 3.0 - p.z).normalized()
		add_view(name_k, p + back * 2.8 + Vector3(0, 0.9, 0), p, p + back * 0.6 - Vector3(0, LifeRoom.EYE, 0),
			atan2(back.x, back.z))
		add_hand(name_k, name_k)
	for pipe: Array in [["gold_pipe", "gold", space.vein.gold_mouth], ["blue_pipe", "blue", space.vein.blue_mouth]]:
		var at: Vector3 = pipe[2]
		add_spot_target(pipe[0], _body, at, PIPE_RADIUS)
		flat.append(pipe[0])
		add_view(pipe[1], at + Vector3(0, 0.9, 2.8), at, at + Vector3(0, 0, 0.6) - Vector3(0, LifeRoom.EYE, 0), 0.0)
		add_hand(pipe[0], pipe[1])
	var start := space.start
	add_view(WORK, Vector3(0, 4.3, 7.6), Vector3(0, 1.3, -1.9), Vector3(start.x, 0.05, start.z), 0.0)
	add_view(UNDER, Vector3(0.8, -2.6, 6.4), Vector3(0, 0.0, -0.6))
	add_view(UP, Vector3(0.0, 1.4, 4.2), Vector3(-0.4, 9.0, -2.4))
	add_flat(WORK, flat)


# --- Showing -------------------------------------------------------------------------------------------------------

func _apply_weather(dt: float) -> void:
	_look_t = minf(_look_t + EASE_WEATHER * dt, 1.0) if dt > 0.0 else 1.0
	var to: Dictionary = LOOKS[weather_kind]
	var f := smoothstep(0.0, 1.0, _look_t)
	for k: String in to:
		var a: Variant = _look_from.get(k, to[k])
		if to[k] is Color:
			_look[k] = (a as Color).lerp(to[k], f)
		else:
			_look[k] = lerpf(float(a), float(to[k]), f)
	key_light.light_color = _look.sun
	key_light.light_energy = _look.energy
	env.ambient_light_color = _look.ambient
	env.ambient_light_energy = _look.fill
	var rays := clampf(float(_look.rays), 0.0, 1.0)
	_rays.transparency = 1.0 - rays
	_rays.visible = rays > 0.02
	var disc := clampf(float(_look.disc), 0.0, 1.2)
	_sun_disc.visible = disc > 0.02
	_halo.visible = disc > 0.02
	_halo.transparency = 1.0 - clampf(disc, 0.0, 1.0)
	if _sparks.emitting != (rays > 0.2):
		_sparks.emitting = rays > 0.2   # set only when it changes: setting it restarts the sparks
	_sparks.speed_scale = maxf(rays, 0.3)
	_tint_sky(_look.top, _look.low)
	_set_tint(_look.tint)
	var cloudy := weather_kind == "cloud"
	var over_sun := Vector3(0, LeafSpace.ROOF, 0) - sun_dir() * 30.0 + Vector3(0, -1.5, 0)
	var away := over_sun + Vector3(-26.0, 2.0, 10.0)
	var want := over_sun if cloudy else away
	_cloud.position = _cloud.position.lerp(want, minf(1.0, 1.5 * dt)) if dt > 0.0 and _cloud.position != Vector3.ZERO \
		else want
	_cloud.visible = weather_kind in ["blaze", "cloud", "evening"]
	if dress:
		dress.set_night(weather_kind == "desert_night")


## The sky dome's colours (rebuilt only when the weather's look moves).
func _tint_sky(top: Color, low: Color) -> void:
	if _sky_tint.size() == 2 and (_sky_tint[0] as Color).is_equal_approx(top) and (_sky_tint[1] as Color).is_equal_approx(low):
		return
	_sky_tint = [top, low]
	var arr := (_sky_dome.mesh as ArrayMesh).surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var cols := PackedColorArray()
	cols.resize(verts.size())
	for i in verts.size():
		var up := clampf((verts[i].y - LeafSpace.ROOF) / 38.0, 0.0, 1.0)
		cols[i] = low.lerp(top, sqrt(up))
	arr[Mesh.ARRAY_COLOR] = cols
	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	_sky_dome.mesh = m


## A glowing far part takes the weather's tint (its own colours kept); the cactus's dressing gives its glass too.
func tint_with_weather(mi: MeshInstance3D) -> void:
	_tint_later(mi)


func _tint_later(mi: MeshInstance3D) -> void:
	var arr := (mi.mesh as ArrayMesh).surface_get_arrays(0)
	_tinted.append({"mi": mi, "arrays": arr, "base": (arr[Mesh.ARRAY_COLOR] as PackedColorArray).duplicate()})


func _set_tint(tint: Color) -> void:
	var first: bool = not _tinted.is_empty() and not (_tinted[0] as Dictionary).has("done")
	var moved := maxf(maxf(absf(tint.r - _tint.r), absf(tint.g - _tint.g)), absf(tint.b - _tint.b))
	if not first and (moved < 0.0001 or (moved < 0.04 and _look_t < 1.0)):
		return   # rebuilt in steps while the weather turns (a phone's frames), and once at its end
	_tint = tint
	for t: Dictionary in _tinted:
		var base: PackedColorArray = t.base
		var cols := PackedColorArray()
		cols.resize(base.size())
		for i in base.size():
			var c := base[i]
			cols[i] = Color(c.r * tint.r, c.g * tint.g, c.b * tint.b, c.a)
		var arr: Array = t.arrays
		arr[Mesh.ARRAY_COLOR] = cols
		var m := ArrayMesh.new()
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		(t.mi as MeshInstance3D).mesh = m
		t.done = true


func _apply_cells(dt: float) -> void:
	var base := smoothstep(0.35, 0.75, _want_full)
	for i in space.cells.size():
		var c: Dictionary = space.cells[i]
		var at: Vector3 = c.at
		var want := base
		for j in space.doors.size():
			if opening[j] > 0.05:
				var door_at: Vector3 = space.doors[j].at
				var dist := Vector2(at.x, at.z).distance_to(Vector2(door_at.x, door_at.z))
				want -= 0.32 * opening[j] * clampf(heat, 0.0, 1.3) * clampf(1.0 - dist / 4.8, 0.0, 1.0)
		want = clampf(want, 0.0, 1.0)
		fullness[i] = move_toward(fullness[i], want, EASE_CELL * dt) if dt > 0.0 else want
		var f := fullness[i]
		if absf(f - _cell_shown[i]) < 0.004:
			continue   # unchanged since it was last written
		_cell_shown[i] = f
		var kind := str(c.kind)
		if kind == "store":
			_cells_full.multimesh.set_instance_transform(i, LeafKit.hidden())
			_cells_dry.multimesh.set_instance_transform(i, LeafKit.hidden())
			continue
		var r := float(c.radius) * (0.86 + 0.14 * f)
		var squash := float(c.squash) * (0.78 + 0.22 * f)
		var basis := Basis(Vector3.UP, float(c.turn)).scaled(Vector3(r, r * squash, r))
		var xf := Transform3D(basis, at - Vector3(0, float(c.radius) * (1.0 - squash) * 0.5, 0))
		var green := CELL.lerp(Color("8fd86a"), 0.5 * fposmod(float(c.turn), 1.0)) if kind == "spongy" else Color("d5e6bb")
		var col := CELL_DRY.lerp(green, f)
		if f >= 0.45:
			_cells_full.multimesh.set_instance_transform(i, xf)
			_cells_full.multimesh.set_instance_color(i, col)
			_cells_dry.multimesh.set_instance_transform(i, LeafKit.hidden())
		else:
			_cells_dry.multimesh.set_instance_transform(i, xf)
			_cells_dry.multimesh.set_instance_color(i, col)
			_cells_full.multimesh.set_instance_transform(i, LeafKit.hidden())


## Each door: its guard cells closed into an oval (shut) or bowed apart round the open slit (they swap half way, with a
## little squeeze), and the slit between them.
func _apply_doors() -> void:
	for i in space.doors.size():
		var d: Dictionary = space.doors[i]
		if absf(opening[i] - _door_shown[i]) < 0.002:
			continue
		_door_shown[i] = opening[i]
		var o := smoothstep(0.0, 1.0, opening[i])
		var basis := Basis(Vector3.UP, float(d.yaw))
		var at: Vector3 = d.at
		var squeeze := 1.0 - 0.12 * sin(clampf(o, 0.0, 1.0) * PI)
		var a := Transform3D(basis * Basis.from_scale(Vector3(squeeze, 1.0, 1.0)), at)
		var b := Transform3D(basis * Basis(Vector3.UP, PI) * Basis.from_scale(Vector3(squeeze, 1.0, 1.0)), at)
		var open := o >= 0.5
		var shown := _guards_open if open else _guards_shut
		var other := _guards_shut if open else _guards_open
		shown.multimesh.set_instance_transform(i * 2, a)
		shown.multimesh.set_instance_transform(i * 2 + 1, b)
		other.multimesh.set_instance_transform(i * 2, LeafKit.hidden())
		other.multimesh.set_instance_transform(i * 2 + 1, LeafKit.hidden())
		var width := 0.03 + 0.24 * o
		var length := float(d.length) * (0.4 + 0.08 * o)
		_slits.multimesh.set_instance_transform(i, Transform3D(basis * Basis.from_scale(Vector3(width, 0.22, length)),
			at + Vector3(0, -0.1, 0)))


func _apply_workshops() -> void:
	var t: Color = _look.get("tint", Color.WHITE)
	var recolour := absf(glow_work - _work_shown) > 0.004 or not t.is_equal_approx(_work_tint)
	var dim := Color(WORK_DIM.r * t.r, WORK_DIM.g * t.g, WORK_DIM.b * t.b)
	var lit := dim.lerp(WORK_LIT, glow_work)
	if recolour:
		_work_shown = glow_work
		_work_tint = t
	for k in _work_spots.size():
		var s: Dictionary = _work_spots[k]
		var host := int(s.host)
		var dir: Vector3 = s.dir
		var xf: Transform3D
		var column := str(s.kind) == "column"
		var moved := not s.has("placed") or (not column and absf(fullness[host] - float(s.get("full", -1.0))) >= 0.004)
		if not moved:
			if recolour:
				_workshops.multimesh.set_instance_color(k, lit)
			continue
		s.placed = true
		if not column:
			s.full = fullness[host]
		if column:
			var col: Dictionary = space.columns[host]
			var r := float(col.radius)
			var p: Vector3 = (col.at as Vector3) + dir * (r * 0.98) + Vector3(0, float(s.h), 0)
			xf = Transform3D(Basis.looking_at(dir, Vector3.UP) * Basis(Vector3.FORWARD, float(s.lean)), p)
		else:
			var c: Dictionary = space.cells[host]
			var f := fullness[host]
			var r := float(c.radius) * (0.86 + 0.14 * f)
			var sq := float(c.squash) * (0.78 + 0.22 * f)
			var p: Vector3 = (c.at as Vector3) + Vector3(dir.x * r, dir.y * r * sq, dir.z * r) * 0.98 \
				- Vector3(0, float(c.radius) * (1.0 - sq) * 0.5, 0)
			xf = Transform3D(Basis.looking_at(dir, Vector3.UP if absf(dir.y) < 0.95 else Vector3.RIGHT) \
				* Basis(Vector3.FORWARD, float(s.lean)), p)
		_workshops.multimesh.set_instance_transform(k, xf)
		_workshops.multimesh.set_instance_color(k, lit)


## B2: the child took the sugar at spot `k`: it is the one that goes (the next spot to fill is the one it left).
func take_sugar(k: int) -> void:
	if _sugar_order.has(k):
		_sugar_order.erase(k)
		_sugar_order.append(k)


## The spots where sugar waits now (the host's taps pick among them).
func waiting_spots() -> Array[int]:
	var out: Array[int] = []
	for j in mini(waiting, _sugar_order.size()):
		out.append(_sugar_order[j])
	return out


func _apply_sugars(dt: float) -> void:
	for j in _sugar_order.size():
		var k := _sugar_order[j]
		var want := 1.0 if j < waiting else 0.0
		_sugar_scale[k] = move_toward(_sugar_scale[k], want, 3.0 * dt) if dt > 0.0 else want
		var s := _sugar_scale[k]
		if s <= 0.001:
			_sugars.multimesh.set_instance_transform(k, LeafKit.hidden())
			continue
		var pop := 1.0 + 0.18 * sin(clampf(s, 0.0, 1.0) * PI)
		var bob := sin(_clock * 1.7 + k) * 0.07
		var basis := Basis(Vector3.UP, _clock * 0.6 + k * 0.9).scaled(Vector3.ONE * s * pop)
		_sugars.multimesh.set_instance_transform(k, Transform3D(basis, space.sugar_spots[k] + Vector3(0, bob, 0)))
		_sugars.multimesh.set_instance_color(k, Color.WHITE)


func _apply_puffs(dt: float) -> void:
	var targets: Array[Vector3] = []
	if dress and weather_kind == "desert_night":
		targets = space.jars
	for i in _puff_state.size():
		var p: Dictionary = _puff_state[i]
		var door := int(p.door)
		var open := opening[door] > 0.45
		var home := _under_door(door, i)
		match str(p.phase):
			"wait":
				var bump := absf(sin(_clock * 2.3 + i * 1.7)) * 0.1
				p.at = (p.at as Vector3).lerp(home + Vector3(0, bump, 0), minf(1.0, 4.0 * dt) if dt > 0.0 else 1.0)
				if open and dt > 0.0 and int(p.k) == int(_clock * 1.3) % PUFFS_PER_DOOR:
					p.phase = "rise"
					p.t = 0.0
			"rise":
				p.t = float(p.t) + dt
				p.at = (p.at as Vector3) + Vector3(0, 1.1 * dt, 0)
				if (p.at as Vector3).y > 1.2:
					p.phase = "drift"
					p.t = 0.0
					p.to = targets[i % targets.size()] if not targets.is_empty() else _work_target(i)
			"drift":
				p.t = float(p.t) + dt
				var to: Vector3 = p.to
				var at: Vector3 = p.at
				var step := (to - at).limit_length(1.2 * dt)
				p.at = at + step + Vector3(sin(_clock * 1.9 + i) * 0.15 * dt, 0, cos(_clock * 1.6 + i) * 0.15 * dt)
				if at.distance_to(to) < 0.25 or float(p.t) > 9.0:
					p.phase = "wait"
					p.at = home + Vector3(0, -0.6, 0)
		var scale := 1.0
		if str(p.phase) == "drift":
			scale = clampf((p.at as Vector3).distance_to(p.to) / 0.8, 0.25, 1.0)
		var spin := float(p.spin) + _clock * 0.7
		_puffs.multimesh.set_instance_transform(i, Transform3D(Basis(Vector3.UP, spin).scaled(Vector3.ONE * scale), p.at))
		_puffs.multimesh.set_instance_color(i, Color.WHITE)


## Where a puff goes once inside: a working cell's or column's side.
func _work_target(i: int) -> Vector3:
	if _work_spots.is_empty():
		return Vector3(0, 4, 0)
	var s: Dictionary = _work_spots[(i * 37) % _work_spots.size()]
	if str(s.kind) == "column":
		var col: Dictionary = space.columns[int(s.host)]
		return (col.at as Vector3) + (s.dir as Vector3) * (float(col.radius) + 0.25) + Vector3(0, minf(float(s.h), 1.2), 0)
	var c: Dictionary = space.cells[int(s.host)]
	return (c.at as Vector3) + (s.dir as Vector3) * (float(c.radius) + 0.25)


func _apply_drops(dt: float) -> void:
	var keep: Array[Dictionary] = []
	for d in _drop_state:
		d.t = float(d.t) + dt
		if float(d.t) < float(d.dur):
			keep.append(d)
	_drop_state = keep
	for k in DROPS:
		if k >= _drop_state.size() or float(_drop_state[k].t) < 0.0:
			_drops.multimesh.set_instance_transform(k, LeafKit.hidden())
			continue
		var d: Dictionary = _drop_state[k]
		var f := clampf(float(d.t) / float(d.dur), 0.0, 1.0)
		var from: Vector3 = d.from
		var to: Vector3 = d.to
		var p := from.lerp(to, f) + Vector3(0, sin(f * PI) * 1.2, 0)
		var vel := ((to - from) + Vector3(0, cos(f * PI) * 1.2 * PI, 0)).normalized()
		var basis := Basis.looking_at(vel, Vector3.UP if absf(vel.y) < 0.95 else Vector3.RIGHT) * Basis(Vector3.RIGHT, -PI * 0.5)
		_drops.multimesh.set_instance_transform(k, Transform3D(basis, p))
		_drops.multimesh.set_instance_color(k, Color.WHITE)


## The mist's points: round each open door, drawn down into its slit; and under it, pouring out.
func _apply_mist() -> void:
	var key := ""
	for i in space.doors.size():
		key += "1" if opening[i] > 0.3 else "0"
	if key != _mist_doors:
		_mist_doors = key
		var points := PackedVector3Array()
		var normals := PackedVector3Array()
		for i in space.doors.size():
			if opening[i] <= 0.3:
				continue
			var d: Dictionary = space.doors[i]
			var at: Vector3 = d.at
			for k in 8:
				var th := TAU * k / 8.0 + 0.3 * i
				var from := at + Vector3(cos(th) * 1.45, 0.75 + 0.45 * (0.5 + 0.5 * sin(k * 2.1)), sin(th) * 1.45)
				points.append(from)
				normals.append((at + Vector3(0, -0.2, 0) - from).normalized())
			for k in 5:
				var along := Basis(Vector3.UP, float(d.yaw)) * Vector3(0, 0, (k - 2) * 0.28)
				points.append(at + along + Vector3(0, -0.35, 0))
				normals.append((Vector3.DOWN + along * 0.4).normalized())
		if not points.is_empty():
			_mist.emission_points = points
			_mist.emission_normals = normals
	if _mist.emitting != key.contains("1"):
		_mist.emitting = key.contains("1")   # set only when it changes: setting it restarts the mist
	_mist.speed_scale = clampf(0.55 + heat * 0.5, 0.5, 1.3)


func _apply_bud() -> void:
	_bud_gold.scale = Vector3.ONE * maxf(bud_fill, 0.001)
	_bud_gold.visible = bud_fill > 0.01
