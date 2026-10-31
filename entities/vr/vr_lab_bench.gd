class_name VrLabBench
extends Node3D
## Owner #110 (VR round 4, VR-WONDER, idea 4 "the Lab bench by hand"; docs/devlog/parts/vr-r4-wonder.md, the research
## docs/devlog/parts/vr-ideas-research.md §5.3): in a headset the Lab's float-or-sink and magnets are done with the
## hands. LabPanel (its VR branch) makes this bench while the Lab shows such an experiment; the panel keeps the predict
## prompt, TRY IT!, WHAT HAPPENED? and the why cards (read aloud): the hands do the experiment, the words come after
## (Makransky's warning, the research §3). LabBenchRules has the places and sums.
##
## - A bench at hand height in front of the child (seated too); its handle (the right end) lifts or lowers it.
## - PREDICT: a shelf of little cubes (the experiment's things: wood, stone, ice, an iron nail...) and two baskets with
##   the experiment's groups (FLOATS / SINKS, STICKS / DOES NOT STICK). A cube put in a basket is the guess: the Lab's own
##   sort form (LabPredict) gets it, so TRY IT! opens on the panel once every cube is sorted.
## - TRY, float or sink: a cube let go over the tank is dropped in (once, as a tap on its button: the Lab's view and its
##   model, LabTank, decide): it bobs at the surface or rests on the bottom. Anywhere else it goes back to its basket.
## - TRY, magnets: take the magnet; a magnetic thing (LabMagnet.sticks: the Lab's tested data) is pulled to its tip from
##   10 cm with a click and a buzz and hangs there; any other thing is tried when the tip touches it and stays put.
## - Cheap: the bench, its baskets and handle one mesh; the cubes one MultiMesh; the tank's glass and water; the magnet;
##   three labels (the baskets' words, the name of the cube a hand is on): at most 8 draws while it is open.
## The outcome is never this file's: the 3D only shows what the Lab's models (and their content test) say.

## A cube glides to its place in this long (s); a floater bobs this much (m).
const GLIDE_TIME := 0.7
const BOB := 0.004
## The magnet: its tip ahead of the grip (its poles point along -Z), where stuck things hang from it.
const MAGNET_TIP := Vector3(0.0, 0.0, -0.13)
## Each thing's cube colour (LabModels.THINGS).
const LOOKS := {"wood": Color("b07a45"), "stone": Color("8d8f93"), "ice": Color("dff4ff"), "iron": Color("4f555e"),
	"leaf": Color("4fa43a"), "gold": Color("ffc21a"), "sponge": Color("efe07a"), "glass": Color("8fdcf2"),
	"clip": Color("c9cfd8"), "copper": Color("c8733a"), "tin": Color("aeb4bb")}
const TOP_COLOR := Color("a8794a")
const LEG_COLOR := Color("6e4a2c")
const BASKET_COLORS: Array[Color] = [Color("3a7be8"), Color("f08a1c")]   # LabPredict's groups' colours
const HANDLE_COLOR := Color("2fae4e")
const WATER_COLOR := Color(0.3, 0.6, 0.95, 0.45)
const GLASS_COLOR := Color(0.85, 0.95, 1.0, 0.18)

## The experiment it shows (LabScreen.experiment_id).
var experiment_id := ""
var screen: LabScreen

var _kind := ""                      # "tank" or "magnet"
var _things: Array[Thing] = []
var _mm := MultiMeshInstance3D.new()
var _bench := MeshInstance3D.new()
var _water: MeshInstance3D
var _glass: MeshInstance3D
var _magnet: Magnet
var _words: Array[Label3D] = []
var _name := Label3D.new()
var _handle := VrGrabbable.new()
var _handle_hand := Vector3.INF      # where the hand took the handle, and the bench then
var _handle_from := 0.0
var _local := Transform3D()
var _predict: LabPredict = null
var _page: StringName = &""
var _clock := 0.0


## One thing: a cube (the MultiMesh draws it at this node) with its grabbable.
class Thing:
	extends Node3D
	var index := 0
	var thing := ""
	var label := ""
	var grabbable := VrGrabbable.new()
	var home := Vector3.ZERO          # its place on the bench (the bench's space)
	var glide := 1.0
	var from := Vector3.ZERO
	var group := -1                   # the basket it was sorted into
	var in_tank := false
	var floats := false
	var stuck := -1                   # its place on the magnet, -1: not stuck
	var shake := 0.0

	func _init(i: int, t: Dictionary) -> void:
		index = i
		thing = str(t.get("thing", ""))
		label = str(t.get("name", ""))
		name = "Thing%d" % i
		grabbable.name = "Grabbable"
		grabbable.kind = &"hold"
		grabbable.throwable = false
		grabbable.far_pull = true
		grabbable.radius = LabBenchRules.CUBE * 0.6
		add_child(grabbable)


## The magnet: a red horseshoe with silver poles along -Z, a VrGrabbable of kind &"tool".
class Magnet:
	extends Node3D
	var grabbable := VrGrabbable.new()
	var glide := 1.0
	var from := Transform3D()

	func _init() -> void:
		name = "Magnet"
		grabbable.name = "Grabbable"
		grabbable.kind = &"tool"
		grabbable.throwable = false
		grabbable.far_pull = true
		grabbable.radius = 0.05
		add_child(grabbable)
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var red := Color("d9463b")
		var silver := Color("d7dde4")
		VrLabBench._box(st, Vector3(0.0, 0.0, 0.02), Vector3(0.09, 0.025, 0.03), red)   # the bend
		for x: float in [-0.032, 0.032]:
			VrLabBench._box(st, Vector3(x, 0.0, -0.04), Vector3(0.025, 0.025, 0.09), red)
			VrLabBench._box(st, Vector3(x, 0.0, -0.1), Vector3(0.026, 0.026, 0.03), silver)   # the poles
		var m := MeshInstance3D.new()
		m.name = "Horseshoe"
		m.mesh = st.commit()
		m.material_override = AvatarParts.part_material()
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(m)


func _init() -> void:
	name = "VrLabBench"
	process_mode = Node.PROCESS_MODE_ALWAYS


## Builds the bench for the Lab's experiment now (LabScreen: its experiment, page and models), before the head.
func open(lab: LabScreen) -> void:
	screen = lab
	experiment_id = lab.experiment_id
	var scene: Dictionary = lab.experiment.get("scene", {})
	_kind = str(scene.get("kind", ""))
	_build(scene.get("things", []), (lab.experiment.get("predict", {}) as Dictionary).get("groups", []))
	var s := Vr.world_scale()
	var at := LabBenchRules.place_before(Vr.head_transform())
	var head := Vr.head_transform().origin
	global_transform = Transform3D(at.basis * s, head + (at.origin - head) * s)
	_remember_place()
	if not Vr.ended.is_connected(queue_free):
		Vr.ended.connect(queue_free)
	_reset()
	step(0.0)


func close() -> void:
	if Vr.ended.is_connected(queue_free):
		Vr.ended.disconnect(queue_free)
	for n: Node in find_children("*", "VrGrabbable", true, false):
		(n as VrGrabbable).enabled = false   # no hand takes a thing of a closed bench in the frame before it goes
	queue_free()


func _exit_tree() -> void:
	if Vr.ended.is_connected(queue_free):
		Vr.ended.disconnect(queue_free)


func _process(delta: float) -> void:
	step(delta)

# --- Read by tests and the bench tool ---

func thing_count() -> int:
	return _things.size()


func thing(i: int) -> Node3D:
	return _things[i] if i >= 0 and i < _things.size() else null


func thing_grabbable(i: int) -> VrGrabbable:
	return _things[i].grabbable if i >= 0 and i < _things.size() else null


func basket_words() -> Array[String]:
	var out: Array[String] = []
	for l in _words:
		out.append(l.text)
	return out


func has_tank() -> bool:
	return _water != null


func has_magnet() -> bool:
	return _magnet != null


func magnet() -> Node3D:
	return _magnet


func magnet_grabbable() -> VrGrabbable:
	return _magnet.grabbable if _magnet else null


## The magnet's tip in the world.
func magnet_tip() -> Vector3:
	return _magnet.global_transform * MAGNET_TIP if _magnet else Vector3.INF


func handle_position() -> Vector3:
	return global_transform * LabBenchRules.HANDLE_AT

# --- Every frame ---

func step(delta: float) -> void:
	_clock += delta
	_follow(delta)
	_sync_page()
	for t: Thing in _things:
		_step_thing(t, delta)
	if _magnet:
		_step_magnet(delta)
	_draw_things()


## The bench stays with the child's body (the rig); the handle, while held, lifts or lowers it.
func _follow(_delta: float) -> void:
	if Vr.rig == null or not is_inside_tree():
		return
	var by := _handle.held_by()
	if by == VrRules.LEFT or by == VrRules.RIGHT:
		var hand := Vr.hand_grip(by).origin
		if not _handle_hand.is_finite():
			_handle_hand = hand
			_handle_from = global_position.y
		var eye := Vr.head_transform().origin.y
		var s := Vr.world_scale()
		var wanted := _handle_from + hand.y - _handle_hand.y   # the bench goes up and down with the hand
		global_position.y = eye + LabBenchRules.lifted(0.0, (wanted - eye) / s) * s
		_remember_place()
		return
	_handle_hand = Vector3.INF
	global_transform = Vr.rig.global_transform * _local


func _remember_place() -> void:
	_local = Vr.rig.global_transform.affine_inverse() * global_transform if Vr.rig != null else global_transform


## The Lab's page: a new prediction puts every cube back on the shelf; TRY shows what the model already knows.
func _sync_page() -> void:
	if screen == null or not is_instance_valid(screen):
		return
	if screen.page == LabScreen.PREDICT and screen.predict_answer != _predict:
		_reset()
	_page = screen.page


func _reset() -> void:
	_predict = screen.predict_answer if screen != null and is_instance_valid(screen) else null
	var model := screen.model if screen != null and is_instance_valid(screen) else null
	for t: Thing in _things:
		t.group = -1
		t.in_tank = false
		t.stuck = -1
		t.grabbable.enabled = true
		if t.top_level:
			t.top_level = false
		t.floats = model is LabTank and (model as LabTank).floats(t.index)
		_send_home(t, LabBenchRules.shelf_spot(t.index, _things.size()), true)


func _step_thing(t: Thing, delta: float) -> void:
	if t.grabbable.held_by() != &"" or _pulled(t.grabbable):
		return   # in a hand: the grabber's
	if t.stuck >= 0 and _magnet:
		var b := _magnet.global_basis.orthonormalized()
		var at := magnet_tip() + b * Vector3(LabBenchRules.CUBE * 1.05 * _stuck_side(t.stuck), 0.0,
			-LabBenchRules.CUBE * 0.5 * Vr.world_scale())
		t.global_transform = Transform3D(b * Basis.from_scale(Vector3.ONE * LabBenchRules.CUBE * Vr.world_scale()), at)
		return
	var target := t.home
	if t.in_tank and t.floats:
		target.y += BOB * sin(_clock * 2.4 + t.index)
	if t.glide < 1.0:
		t.glide = minf(t.glide + delta / GLIDE_TIME, 1.0)
		var e := 1.0 - pow(1.0 - t.glide, 3.0)
		target = t.from.lerp(target, e)
	if t.shake > 0.0:
		t.shake = maxf(t.shake - delta, 0.0)
		target.x += 0.004 * sin(t.shake * 60.0)
	t.transform = Transform3D(Basis.from_scale(Vector3.ONE * LabBenchRules.CUBE), target)


## 0, -1, 1, -2, 2...: where the n-th stuck thing hangs beside the tip.
static func _stuck_side(n: int) -> float:
	return 0.0 if n == 0 else float((n + 1) / 2) * (-1.0 if n % 2 == 1 else 1.0)


func _pulled(g: VrGrabbable) -> bool:
	return Vr.grabber != null and (Vr.grabber.held(VrRules.LEFT) == g or Vr.grabber.held(VrRules.RIGHT) == g)


func _send_home(t: Thing, spot: Vector3, at_once: bool = false) -> void:
	t.home = spot
	t.from = t.position
	t.glide = 1.0 if at_once else 0.0
	if at_once:
		t.transform = Transform3D(Basis.from_scale(Vector3.ONE * LabBenchRules.CUBE), spot)


## The magnet: back to its rest when let go; held in the TRY page, its tip pulls or tries the things.
func _step_magnet(delta: float) -> void:
	var by := _magnet.grabbable.held_by()
	if by == &"" and not _pulled(_magnet.grabbable):
		var rest := Transform3D(Basis(), LabBenchRules.MAGNET_REST)
		if _magnet.glide < 1.0:
			_magnet.glide = minf(_magnet.glide + delta / GLIDE_TIME, 1.0)
			_magnet.transform = _magnet.from.interpolate_with(rest, 1.0 - pow(1.0 - _magnet.glide, 3.0))
		else:
			_magnet.transform = rest
		return
	if _page != LabScreen.TRY or not (screen.model is LabMagnet):
		return
	var model := screen.model as LabMagnet
	var tip := magnet_tip()
	var s := Vr.world_scale()
	for t: Thing in _things:
		if model.is_tested(t.index):
			continue
		var gap := (tip.distance_to(t.global_position) / s) - LabBenchRules.CUBE * 0.5
		if LabBenchRules.magnet_catches(gap, model.sticks(t.index)):
			_press(t.index)
			if model.sticks(t.index):
				t.stuck = _stuck_count()
				t.grabbable.enabled = false
				Vr.haptic(by if by != &"" else Vr.pointing_hand(), 0.6, 0.06, 160.0)   # the click onto the magnet
			else:
				t.shake = 0.25   # a little wobble: no pull


func _stuck_count() -> int:
	var n := 0
	for t: Thing in _things:
		if t.stuck >= 0:
			n += 1
	return n


## A thing's step in the Lab: its button in the Lab's view pressed, exactly as a tap (the view plays its sound and
## the model decides; the Lab says what happened and opens WHAT HAPPENED? when it is done).
func _press(i: int) -> void:
	var view := screen.view as LabThingsView if screen != null and is_instance_valid(screen) else null
	if view != null and i < view.thing_buttons.size():
		view.thing_buttons[i].pressed.emit()


func _draw_things() -> void:
	var mm := _mm.multimesh
	if mm == null:
		return
	var inv := _mm.global_transform.affine_inverse()
	for i in _things.size():
		mm.set_instance_transform(i, inv * _things[i].global_transform)

# --- The hands ---

func _on_hovered(_side: StringName, on: bool, t: Thing) -> void:
	_name.visible = on
	if on:
		_name.text = t.label
		_name.position = t.home + Vector3(0.0, LabBenchRules.CUBE * 1.6, 0.0)


func _on_grabbed(_side: StringName, t: Thing) -> void:
	t.top_level = true
	_name.text = t.label
	_name.visible = false


func _on_released(_side: StringName, _velocity: Vector3, t: Thing) -> void:
	if t.grabbable.held_by() != &"":
		return
	var at := global_transform.affine_inverse() * t.global_position
	t.top_level = false
	if _page == LabScreen.PREDICT and _predict != null and is_instance_valid(_predict):
		var g := LabBenchRules.basket_at(at)
		if g >= 0:
			_guess(t, g)
	elif _page == LabScreen.TRY and _kind == "tank" and LabBenchRules.in_tank(at) and not t.in_tank:
		_press(t.index)
		var model := screen.model as LabTank
		if model != null and model.is_dropped(t.index):
			t.in_tank = true
			t.floats = model.floats(t.index)
			t.grabbable.enabled = false   # in once, as a tap
			_send_home(t, _tank_spot(t))
			return
	_send_home(t, _basket_or_shelf(t))


func _on_magnet_grabbed(_side: StringName) -> void:
	_magnet.top_level = true


## Let go, the magnet glides back to its rest on the bench (the things stuck to it with it).
func _on_magnet_released(_side: StringName, _velocity: Vector3) -> void:
	if _magnet.grabbable.held_by() != &"":
		return
	_magnet.top_level = false
	_magnet.from = _magnet.transform
	_magnet.glide = 0.0


## The guess: the Lab's sort form puts thing t in `group` (its own taps, round its groups).
func _guess(t: Thing, group: int) -> void:
	var guard := 0
	while _predict.picked[t.index] != group and guard < 4:
		_predict.tap(t.index)
		guard += 1
	t.group = group


func _basket_or_shelf(t: Thing) -> Vector3:
	if t.group < 0:
		return LabBenchRules.shelf_spot(t.index, _things.size())
	var k := 0
	for o: Thing in _things:
		if o != t and o.group == t.group and o.index < t.index:
			k += 1
	return LabBenchRules.basket_slot(t.group, k)


## A thing's place in the tank: side by side with the others of its kind (the data's order, so nothing moves later).
func _tank_spot(t: Thing) -> Vector3:
	var model := screen.model as LabTank
	var same: Array[int] = []
	for i in _things.size():
		if model.floats(i) == t.floats:
			same.append(i)
	return LabBenchRules.tank_spot(t.floats, same.find(t.index), same.size())

# --- Building ---

func _build(things: Array, groups: Array) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := LabBenchRules.TOP
	_box(st, Vector3(0.0, -top.y * 0.5, 0.0), top, TOP_COLOR)
	for x: float in [-top.x * 0.45, top.x * 0.45]:
		for z: float in [-top.z * 0.4, top.z * 0.4]:
			_box(st, Vector3(x, -top.y - 0.15, z), Vector3(0.04, 0.3, 0.04), LEG_COLOR)   # short legs: a table look
	for g in mini(groups.size(), LabBenchRules.BASKETS.size()):
		_basket(st, LabBenchRules.BASKETS[g], BASKET_COLORS[g])
	var h := LabBenchRules.HANDLE_AT
	_box(st, h + Vector3(0.0, 0.04, 0.0), Vector3(0.03, 0.08, 0.12), HANDLE_COLOR)   # the handle: a green post
	_bench.name = "Bench"
	_bench.mesh = st.commit()
	_bench.material_override = AvatarParts.part_material()
	_bench.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_bench)
	_handle.name = "Handle"
	_handle.kind = &"hold"
	_handle.follows_hand = false
	_handle.throwable = false
	_handle.far_pull = false
	_handle.radius = 0.05
	_handle.position = h + Vector3(0.0, 0.04, 0.0)
	add_child(_handle)
	var words := LabBenchRules.basket_words(groups)
	for g in mini(words.size(), LabBenchRules.BASKETS.size()):
		var l := Label3D.new()
		l.name = "Basket%d" % g
		_label(l, words[g], 30)
		l.modulate = BASKET_COLORS[g].lightened(0.45)
		l.position = LabBenchRules.BASKETS[g] + Vector3(0.0, LabBenchRules.BASKET_SIZE.y + 0.03,
			LabBenchRules.BASKET_SIZE.z * 0.5 + 0.01)
		add_child(l)
		_words.append(l)
	_label(_name, "", 28)
	_name.name = "ThingName"
	_name.visible = false
	add_child(_name)
	if _kind == "tank":
		_build_tank()
	elif _kind == "magnet":
		_magnet = Magnet.new()
		add_child(_magnet)
		_magnet.position = LabBenchRules.MAGNET_REST
		_magnet.grabbable.grabbed.connect(_on_magnet_grabbed)
		_magnet.grabbable.released.connect(_on_magnet_released)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE
	mm.mesh = cube
	mm.instance_count = things.size()
	for i in things.size():
		var t := Thing.new(i, things[i] as Dictionary)
		add_child(t)
		_things.append(t)
		t.grabbable.hovered.connect(_on_hovered.bind(t))
		t.grabbable.grabbed.connect(_on_grabbed.bind(t))
		t.grabbable.released.connect(_on_released.bind(t))
		mm.set_instance_color(i, LOOKS.get(t.thing, Color.WHITE))
	_mm.name = "Things"
	_mm.multimesh = mm
	_mm.material_override = AvatarParts.part_material()
	_mm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_mm.custom_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))   # a cube in the hand is still drawn
	add_child(_mm)


func _build_tank() -> void:
	var size := LabBenchRules.TANK_SIZE
	var at := LabBenchRules.TANK_AT
	_glass = MeshInstance3D.new()
	_glass.name = "TankGlass"
	var g := BoxMesh.new()
	g.size = size
	_glass.mesh = g
	_glass.position = at + Vector3(0.0, size.y * 0.5, 0.0)
	_glass.material_override = _see_through(GLASS_COLOR)
	_glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_glass)
	_water = MeshInstance3D.new()
	_water.name = "Water"
	var w := BoxMesh.new()
	var depth := size.y * LabBenchRules.WATER
	w.size = Vector3(size.x - 0.01, depth, size.z - 0.01)
	_water.mesh = w
	_water.position = at + Vector3(0.0, depth * 0.5 + LabBenchRules.GLASS, 0.0)
	_water.material_override = _see_through(WATER_COLOR)
	_water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_water)


## The mirror wall's see-through settings (unshaded, alpha, both sides).
static func _see_through(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = c
	return m


## An open box: a floor and four low walls.
static func _basket(st: SurfaceTool, at: Vector3, c: Color) -> void:
	var s := LabBenchRules.BASKET_SIZE
	var wall := 0.008
	_box(st, at + Vector3(0.0, wall * 0.5, 0.0), Vector3(s.x, wall, s.z), c.darkened(0.2))
	for side: float in [-1.0, 1.0]:
		_box(st, at + Vector3(side * (s.x - wall) * 0.5, s.y * 0.5, 0.0), Vector3(wall, s.y, s.z), c)
		_box(st, at + Vector3(0.0, s.y * 0.5, side * (s.z - wall) * 0.5), Vector3(s.x, s.y, wall), c)


## A box of vertex colour `c` (AvatarParts.part_material draws vertex colours) into `st`: each face's triangles
## clockwise seen from outside (Godot's front faces).
static func _box(st: SurfaceTool, centre: Vector3, size: Vector3, c: Color) -> void:
	var h := size * 0.5
	for n: Vector3 in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		var u := Vector3.RIGHT if absf(n.x) < 0.5 else Vector3.FORWARD
		var v := n.cross(u)   # u × v = n
		var q := [n - u - v, n + u - v, n + u + v, n - u + v]
		var shade := c if n.y > 0.5 else (c.darkened(0.3) if n.y < -0.5 else c.darkened(0.12))
		for k: int in [0, 2, 1, 0, 3, 2]:
			st.set_color(shade)
			st.set_normal(n)
			st.add_vertex(centre + (q[k] as Vector3) * h)


static func _label(l: Label3D, text: String, size: int) -> void:
	l.text = text
	l.font_size = size
	l.pixel_size = 0.0007
	l.outline_size = 8
	l.modulate = Color("fff3b0")
	l.outline_modulate = Color(0.05, 0.05, 0.12)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
