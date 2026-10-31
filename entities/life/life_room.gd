class_name LifeRoom
extends Node3D
## Owner #112, #113 (docs/design/life-skills.md §3, §4, §10): a practice room: its own small space (never the voxel
## world), built in code for a track. Each subclass (LifeRooms.make) builds its props and names:
## - targets: what a step touches, holds, aims at or goes to (a node and a forgiving radius; a width for a sweep);
## - views: where the flat camera looks for a step ({cam, look}) and where the child stands in VR ({feet, yaw}); a "go"
##   step's spot is a view of the same name;
## - react(event) / after(event): what happens in the room when a step starts or is done (the alarm beeps, a door
##   closes, Bobo rolls onto the side), and progress(step, state): what a step's progress shows (a hazard found turns
##   green, a dial's digits, the coins given, the chest going down).
## The one next thing glows (glow): a soft warm shell, pulsing. Units are metres; the floor is y = 0 of the room.
## Life L3a (owner #118, design §14): the room's own time (`time_scale`, set by the host: slow at a danger step's moment on
## the first tries, real on the Expert try; the room's simulation moves by sim_delta) and a safe mistake's freeze
## (freeze: everything in the room stills, its processes and tweens, never sudden; show_mistake: the gentle picture of what
## would happen, never an injury, drawn by on_mistake under mistake_holder and taken away after). `more_real()`: a grown-up
## chose "more real" for the Big track (rooms make their effects a little stronger, never scarier).

const GLOW := Color(1.0, 0.86, 0.3, 0.32)
const GLOW_PULSE := 1.6   # pulses a second... slow and calm
## The child's eye above the floor in VR (the anchor's eye point: a child's height; crouching lowers the real head).
const EYE := 1.15

var track := "little"
## The run's words and values (LifeExperience.vars: the region's number and traffic side, the seed, the stall's money,
## the kitchen's recipe), set by LifeRooms.make before the room is built.
var vars := {}
var targets := {}
var views := {}
var start_view := "room"
var env: Environment
var events: Array[String] = []
## Life L3a: the room's time (1 real time) and the freeze of a safe mistake.
var time_scale := 1.0
var frozen := false
var mistake_shown := ""

## Life L3c (owner #112, Online City: "VR: the tablet held in the hand"): a device the child picks up and holds (`held`,
## its targets under it). Once `holding`, the host keeps it in the off hand in VR (the hand that does not point), facing
## the eyes (hold_pose), and the other hand or the laser presses its buttons; the holding hand never presses its own
## device's buttons (is_held_target). Flat, and when the headset comes off, it stays at `held_rest` (room-local, in
## front of the flat view).
var held: Node3D = null
var holding := false
var held_rest := Transform3D()

## The rooms' look brief (2026-10-17, docs/devlog/parts/rooms-look.md): every piece of the room's look, its dressing's
## (decor()) and its merged scenery's (scenery()), as {name, kind, box} (LifeRoomDecor's kinds, boxes in the room's
## space): the keep-clear rules (never on a target, a view's line or a VR reach) read them.
var look_pieces: Array[Dictionary] = []

var _glows := {}
var _glow_t := 0.0
var _mistake_holder: Node3D
var _decor: LifeRoomDecor
var _scenery: Node3D
var _sun: LifeRoomSun
var _sky: MeshInstance3D


func _init(room_track: String = "little") -> void:
	track = room_track
	name = "LifeRoom"


func _ready() -> void:
	if env == null:
		env = LifeRoomKit.environment(Color("8ec5f0"), Color("e9f3fb"))
	build()
	_finish_look()


# --- The rooms' look (2026-10-17): the dressing, the merged scenery, the sun, the sky and the tone -----------------------

## The room's dressing (floors, walls, windows, plants, the sky): pieces added in build() are drawn as a handful of
## meshes once it is built.
func decor() -> LifeRoomDecor:
	if _decor == null:
		_decor = LifeRoomDecor.new()
	return _decor


## Where a room builds its static scenery with LifeRoomKit's boxes, cylinders and spheres (as under `self`, at the same
## places): once built they merge into one mesh, except what the room keeps, moves, hides, glows or names
## (LifeRoomDecor.bake).
func scenery() -> Node3D:
	if _scenery == null:
		_scenery = Node3D.new()
		_scenery.name = "Scenery"
		add_child(_scenery)
	return _scenery


## The room's own warm key light (one: the world's sun is put away while the room shows). Rooms that call none get the
## default.
func sun(colour: Color = Color(1.0, 0.95, 0.86), energy: float = 1.0, pitch_deg: float = -52.0, yaw_deg: float = -28.0) -> LifeRoomSun:
	if _sun == null:
		_sun = LifeRoomSun.new(colour, energy, pitch_deg, yaw_deg)
		add_child(_sun)
	else:
		_sun.light_color = colour
		_sun.light_energy = energy
		_sun.rotation_degrees = Vector3(pitch_deg, yaw_deg, 0)
	return _sun


## The sky's dome stays round whoever looks (the flat camera or the head), so its horizon is as far whichever of a room's
## places the child is at (Water Safety's pool, beach and pond are 40 m apart).
func _follow_sky() -> void:
	if _sky == null or not is_inside_tree():
		return
	var cam := get_viewport().get_camera_3d()
	if cam != null:
		_sky.global_position = Vector3(cam.global_position.x, global_position.y, cam.global_position.z)


## A room's night (Connections' promise kept the next morning): the sky's dome deepens to a night blue and the sun turns
## to a soft moonlight; `false` gives the day back. The windows' painted views and the lamps glow on.
func nightfall(on: bool) -> void:
	var sky := get_node_or_null("Decor/Sky") as MeshInstance3D
	if sky != null and sky.material_override is StandardMaterial3D:
		(sky.material_override as StandardMaterial3D).albedo_color = Color(0.2, 0.26, 0.46) if on else Color.WHITE
	var s := _sun if _sun != null else sun()
	if on:
		if not s.has_meta(&"day"):
			s.set_meta(&"day", [s.light_color, s.light_energy])
		s.light_color = Color(0.72, 0.8, 1.0)
		s.light_energy = 0.35
	elif s.has_meta(&"day"):
		var day: Array = s.get_meta(&"day")
		s.light_color = day[0]
		s.light_energy = day[1]


## How near the phone held up must be to draw (it is 0.45 m from the eyes at its own view).
const HELD_PHONE_SEEN := 4.0
## How near a room's words must be to draw (the furthest a view reads a sign from is about 10 m; the places of a room
## stand 30 m and more apart).
const WORDS_SEEN := 25.0


func _finish_look() -> void:
	var d := decor()
	if not d.has_sky():
		d.sky(Color("6fb2ec"), Color("d8ecfa"))
	d.commit(self)
	look_pieces.append_array(d.pieces)
	_decor = null
	_sky = get_node_or_null("Decor/Sky") as MeshInstance3D
	if _scenery != null:
		look_pieces.append_array(LifeRoomDecor.bake(self, _scenery))
	if _sun == null:
		sun()
	LifeRoomDecor.tone(env)
	var held := get_node_or_null("HeldPhone")
	if held != null:   # the phone held up shows near it only: from the other places it is a speck (the Quest's draws)
		for g: Node in held.find_children("*", "GeometryInstance3D", true, false):
			(g as GeometryInstance3D).visibility_range_end = HELD_PHONE_SEEN
	for l: Node in find_children("*", "Label3D", true, false):   # words are read near: from another place they are a speck
		if (l as Label3D).visibility_range_end == 0.0:
			(l as Label3D).visibility_range_end = WORDS_SEEN


## Subclasses build their props, targets and views here.
func build() -> void:
	pass


func add_target(target_name: String, node: Node3D, radius: float, width: float = 0.0) -> void:
	targets[target_name] = {"node": node, "radius": radius, "width": width if width > 0.0 else radius}


## A target at a fixed place (a marker node at `at`, under `parent`).
func add_spot_target(target_name: String, parent: Node3D, at: Vector3, radius: float, width: float = 0.0) -> Node3D:
	var n := Node3D.new()
	n.name = "T_" + target_name
	n.position = at
	parent.add_child(n)
	add_target(target_name, n, radius, width)
	return n


func has_target(target_name: String) -> bool:
	return targets.has(target_name) and is_instance_valid(targets[target_name].node)


func target_names() -> Array[String]:
	var out: Array[String] = []
	for t: String in targets:
		out.append(t)
	return out


func target_node(target_name: String) -> Node3D:
	return targets[target_name].node if has_target(target_name) else null


func target_position(target_name: String) -> Vector3:
	var n := target_node(target_name)
	return n.global_position if n != null else global_position


func target_radius(target_name: String) -> float:
	return float(targets[target_name].radius) if has_target(target_name) else 0.0


func target_width(target_name: String) -> float:
	return float(targets[target_name].width) if has_target(target_name) else 0.0


## cam / look: the flat camera; feet / yaw: the child in VR (feet INF: the start view's).
func add_view(view_name: String, cam: Vector3, look: Vector3, feet: Vector3 = Vector3.INF, yaw: float = NAN) -> void:
	views[view_name] = {"cam": cam, "look": look, "feet": feet, "yaw": yaw}


func view(view_name: String) -> Dictionary:
	return views.get(view_name, views.get(start_view, {"cam": Vector3(0, 1.2, 2), "look": Vector3.ZERO,
		"feet": Vector3(0, 0, 1.5), "yaw": 0.0}))


## The flat camera's transform for a view (global).
func camera_transform(view_name: String) -> Transform3D:
	var v := view(view_name)
	var from: Vector3 = to_global(v.cam)
	var at: Vector3 = to_global(v.look)
	return Transform3D(Basis.looking_at(at - from, Vector3.UP), from)


## Where the child stands in VR for a view (global): the eye point EYE over the feet, facing the view's yaw (the
## room's -Z at yaw 0). Views without their own feet keep the start view's.
func vr_stand(view_name: String) -> Transform3D:
	var v := view(view_name)
	var start := view(start_view)
	var feet: Vector3 = v.feet if (v.feet as Vector3).is_finite() else start.feet
	var yaw: float = v.yaw if not is_nan(float(v.yaw)) else float(start.yaw)
	if not (feet as Vector3).is_finite():
		feet = Vector3(0, 0, 1.5)
	if is_nan(yaw):
		yaw = 0.0
	return Transform3D(global_basis * Basis(Vector3.UP, yaw), to_global(feet + Vector3(0, EYE, 0)))


## Whether a view stands the child somewhere else in VR than `other` (a blink is needed to move there).
func moves_in_vr(from_view: String, to_view: String) -> bool:
	return vr_stand(from_view).origin.distance_to(vr_stand(to_view).origin) > 0.3


## The one next thing glows; everything else waits.
func glow(names: Array[String]) -> void:
	for n: String in _glows.keys():
		if not names.has(n):
			if is_instance_valid(_glows[n]):
				(_glows[n] as Node3D).queue_free()
			_glows.erase(n)
	for n in names:
		if _glows.has(n) and not is_instance_valid(_glows[n]):
			_glows.erase(n)   # its target's parts were rebuilt (the phone picked up)
		if not has_target(n) or _glows.has(n):
			continue
		var shell := MeshInstance3D.new()
		shell.name = "Glow_" + n
		var mesh := SphereMesh.new()
		mesh.radius = maxf(target_radius(n), 0.06)
		mesh.height = mesh.radius * 2.0
		mesh.radial_segments = 16
		mesh.rings = 8
		shell.mesh = mesh
		shell.material_override = LifeRoomKit.material(GLOW, true)
		shell.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		target_node(n).add_child(shell)
		_glows[n] = shell


func glowing() -> Array[String]:
	var out: Array[String] = []
	for n: String in _glows:
		out.append(n)
	return out


func _process(delta: float) -> void:
	_follow_sky()
	_glow_t += delta
	var s := 1.0 + 0.08 * sin(_glow_t * TAU / GLOW_PULSE)
	for n: String in _glows:
		if is_instance_valid(_glows[n]):
			(_glows[n] as Node3D).scale = Vector3.ONE * s


## A step started (its "react" event, if any) and its view; subclasses act on the events they know.
func react(event: String) -> void:
	events.append(event)
	on_event(event)


func on_event(_event: String) -> void:
	pass


## A step's progress (LifeCheck's state) to show.
func progress(_step: Dictionary, _state: Dictionary) -> void:
	pass


## A step began (subclasses set props for it: the phone in the hand, the coins on the counter).
func step_started(_step: Dictionary) -> void:
	pass


## A step is done (its "after" event, if any, comes first; then this, for what a step's end does by its id or kind).
func step_done(_step: Dictionary) -> void:
	pass


## Life L2 (a cross step): whether it is safe to go across now (the room's traffic, the green man). Rooms without
## traffic are always safe.
func safe_now(_step: Dictionary) -> bool:
	return true


## The flat camera's height drops this much while GET LOW is on (the child sees from under the smoke).
func low_drop() -> float:
	return 0.55


# --- Life L3a (owner #118): the room's time, the freeze, the gentle picture -------------------------------------------

## How far the room's own simulation moves this frame (nothing while frozen; slower on a danger step's early tries).
func sim_delta(delta: float) -> float:
	return 0.0 if frozen else delta * time_scale


## A safe mistake: the room stills (its own processes and every tween in it pause) or moves on again.
func freeze(on: bool) -> void:
	frozen = on
	process_mode = Node.PROCESS_MODE_DISABLED if on else Node.PROCESS_MODE_INHERIT


## The gentle picture of what would happen (on), then gone again (off). Subclasses draw it in on_mistake, under
## mistake_holder() (made fresh each time, taken away after).
func show_mistake(event: String, on: bool) -> void:
	mistake_shown = event if on else ""
	if not on and is_instance_valid(_mistake_holder):
		remove_child(_mistake_holder)
		_mistake_holder.queue_free()
		_mistake_holder = null
	on_mistake(event, on)


func on_mistake(_event: String, _on: bool) -> void:
	pass


func mistake_holder() -> Node3D:
	if not is_instance_valid(_mistake_holder):
		_mistake_holder = Node3D.new()
		_mistake_holder.name = "MistakePicture"
		add_child(_mistake_holder)
	return _mistake_holder


## The grown-up's intensity for this try (LifeData.GENTLE, or REAL on the Big track).
func intensity() -> String:
	return str(vars.get("intensity", LifeData.GENTLE))


func more_real() -> bool:
	return intensity() == LifeData.REAL


# --- Life L3c (owner #112): a device held in the hand ------------------------------------------------------------------

## Where the held device sits for a hand (global): a little above the hand and towards the middle of the view, its face
## (+Z) turned to the eyes.
func hold_pose(hand: Transform3D, head: Transform3D) -> Transform3D:
	var right := head.basis.x
	right.y = 0.0
	right = right.normalized() if right.length() > 0.01 else Vector3.RIGHT
	var at := hand.origin + right * 0.1 + Vector3.UP * 0.12
	var to_eye := head.origin - at
	if to_eye.length() < 0.05:
		return Transform3D(head.basis, at)
	return Transform3D(Basis.looking_at(-to_eye, Vector3.UP), at)


## Whether a target is one of the held device's own (a button on the tablet).
func is_held_target(target_name: String) -> bool:
	var n := target_node(target_name)
	return is_instance_valid(held) and n != null and (n == held or held.is_ancestor_of(n))


## The held device back at its flat place (picked up flat, or the headset came off).
func rest_held() -> void:
	if is_instance_valid(held) and holding:
		held.transform = held_rest


const PHONE_KEYS := [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["", "0", ""]]


## The play phone held up in front of the child, big (its keys 8 cm wide, a forgiving reach), at `local` in the room;
## hidden until it is picked up (a hidden key is never pressed). Its keys are the targets key_0 .. key_9; the returned
## label is its screen.
func make_held_phone(local: Transform3D) -> Label3D:
	var held := Node3D.new()
	held.name = "HeldPhone"
	held.transform = local
	held.visible = false
	add_child(held)
	LifeRoomKit.box(held, "Body", Vector3(0.32, 0.52, 0.04), Vector3.ZERO, Color("1f2a4a"))
	LifeRoomKit.box(held, "Screen", Vector3(0.27, 0.1, 0.01), Vector3(0, 0.19, 0.025), Color("9fd8ff"))
	var screen := LifeRoomKit.sign(held, "Digits", "", Vector3(0, 0.19, 0.035), 0.003, Color("1f2a4a"))
	screen.outline_size = 0
	for r in PHONE_KEYS.size():
		for c in 3:
			var key: String = PHONE_KEYS[r][c]
			if key == "":
				continue
			var k := LifeRoomKit.box(held, "Key" + key, Vector3(0.08, 0.07, 0.02), Vector3((c - 1) * 0.095, 0.07 - r * 0.085, 0.03),
				Color("f6f2ea"))
			var l := LifeRoomKit.sign(k, "Label", key, Vector3(0, 0, 0.012), 0.0025, Color("1f2a4a"))
			l.outline_size = 0
			add_target("key_" + key, k, 0.045)
	return screen


## The digits pressed so far on the held phone's screen (a sequence step's state).
static func dialled(step: Dictionary, state: Dictionary) -> String:
	var digits := ""
	for i in int(state.get("i", 0)):
		digits += str(step.targets[i]).substr(4)
	return digits
