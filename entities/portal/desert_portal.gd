class_name DesertPortal
extends Node3D
## The portal the Stone Golem's defeat opens by the Totem (M2 Task 10, spec §12.9; research D8 "portal
## peek"): a stone frame (a shared box mesh) around a moving window into the Sandstorm Desert (one
## quad with one shared scrolling shader, shaders/desert_window.gdshader), sand blowing out of it and
## a desert wind while a player is near, and the words "Sandstorm Desert opens in the next update!"
## over it (also told once to a child who walks up to it). No countdown, no "come back tomorrow".
## M3 makes it lead to universe 2. It is not a block and changes no blocks; the host spawns it (and
## saves where it stands), every peer shows it. Cheap: the window moves on the GPU, the sand and the
## wind run only while this device's player is within NEAR, checked twice a second.
## M3 Task 5: it leads to `target` (the next universe of the ladder): its words say where (or M2's words
## while that universe's file isn't there yet), and in Survivor walking in emits `entered` (the portal hub
## travels). A window into another universe than the desert is the portals' swirl.

## This device's player walked into the doorway (Survivor, the target universe exists).
signal entered(target: int)

const WINDOW := Vector2(2.0, 3.1)
const WINDOW_Y := 0.35 + 3.1 * 0.5   # the window's middle (the frame's opening starts at 0.35)
const NEAR := 24.0
const TALK := 3.5
const CHECK_EVERY := 0.5
const WIND := preload("res://assets/audio/sfx/portal_wind.wav")
const SHADER := preload("res://shaders/desert_window.gdshader")

static var _material: ShaderMaterial
static var _quad: QuadMesh
static var _grain: BoxMesh

var portal_id := ""
## The universe this portal leads to (M3 Task 5).
var target := BossRules.NEXT_UNIVERSE
var _frame := MeshInstance3D.new()
var _window := MeshInstance3D.new()
var _label := Label3D.new()
var _sand := CPUParticles3D.new()
var _wind := AudioStreamPlayer3D.new()
var _check_t := 0.0
var _told := false


## data = {id, pos, yaw}
func setup(data: Dictionary) -> void:
	portal_id = str(data.get("id", "portal"))
	var t := int(data.get("target", BossRules.NEXT_UNIVERSE))
	target = UniverseRules.HUB if t == UniverseRules.HUB else UniverseRules.valid(t)   # M3 Task 4: the hub
	name = portal_id
	position = data.get("pos", Vector3.ZERO)
	rotation.y = float(data.get("yaw", 0.0))


func _ready() -> void:
	_frame.mesh = GolemModels.portal_frame_mesh()
	add_child(_frame)
	_window.mesh = window_quad()
	_window.material_override = window_material() if target == BossRules.NEXT_UNIVERSE else PortalSwirl.material()
	_window.position.y = WINDOW_Y
	_window.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_window)
	_label.text = words()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 44
	_label.outline_size = 12
	_label.pixel_size = 0.01
	_label.width = 420.0
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.modulate = Color("ffe9a8")
	_label.position.y = 5.0
	add_child(_label)
	_setup_sand()
	_wind.stream = WIND
	_wind.unit_size = 5.0
	_wind.max_distance = NEAR
	_wind.volume_db = -6.0
	add_child(_wind)


func message() -> String:
	return _label.text


func window() -> MeshInstance3D:
	return _window


func frame() -> MeshInstance3D:
	return _frame


## Sand is blowing and the wind is playing (a player is near).
func is_blowing() -> bool:
	return _sand.emitting and _wind.playing


## Sand grains pouring out of the window on both sides (the shared Fx material, one emitter).
func _setup_sand() -> void:
	if _grain == null:
		_grain = BoxMesh.new()
		_grain.size = Vector3.ONE * 0.07
		_grain.material = Fx.material()
	_sand.mesh = _grain
	_sand.amount = 28
	_sand.lifetime = 1.4
	_sand.color = GolemModels.SAND
	_sand.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_sand.emission_box_extents = Vector3(WINDOW.x * 0.45, WINDOW.y * 0.4, 0.05)
	_sand.position.y = WINDOW_Y
	_sand.direction = Vector3(0.3, 0.1, 1.0)
	_sand.spread = 35.0
	_sand.initial_velocity_min = 1.5
	_sand.initial_velocity_max = 3.5
	_sand.gravity = Vector3(0, -2.5, 0)
	_sand.scale_amount_min = 0.5
	_sand.scale_amount_max = 1.2
	_sand.emitting = false
	add_child(_sand)


func _process(delta: float) -> void:
	tick(delta)


## Twice a second: sand and wind while this device's player is near; the words once when they walk up.
## While they are near, every frame: walking into the doorway (M3 Task 5).
func tick(delta: float) -> void:
	_check_t -= delta
	if _check_t > 0.0:
		if is_instance_valid(_near_player):
			_check_walk_in(_near_player)
		return
	_check_t = CHECK_EVERY
	var me := _local_player()
	var d := me.global_position.distance_to(global_position) if me else INF
	var near := d <= NEAR
	if _sand.emitting != near:
		_sand.emitting = near
	if near and not _wind.playing:
		_wind.play()
	elif not near and _wind.playing:
		_wind.stop()
	_near_player = me if near else null
	if near:
		_check_walk_in(me)
	if d <= TALK and not _told:
		_told = true
		Session.magic_feedback.emit(message())
	elif d > TALK * 2.0:
		_told = false


func _local_player() -> Player:
	for p in Monster.players_now(get_tree()):
		if p.is_local:
			return p
	return null


## The one material every portal window shares.
static func window_material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
	return _material


static func window_quad() -> QuadMesh:
	if _quad == null:
		_quad = QuadMesh.new()
		_quad.size = WINDOW
	return _quad


## Compiles the window's shader, the glow material and the Label3D's as the world appears (the camera
## must be in place for them to be drawn), so the first Golem and portal never cost a frame
## (DEVELOPMENT.md §8: a new shader's first draw was a 100+ ms frame on the emulator).
static func prewarm(camera: Camera3D) -> void:
	if camera == null or not camera.is_inside_tree():
		return
	var holder := Node3D.new()
	camera.add_child(holder)
	holder.position = Vector3(0, 0, -1.5)
	var quad := MeshInstance3D.new()
	var tiny := QuadMesh.new()
	tiny.size = Vector2(0.01, 0.01)
	quad.mesh = tiny
	quad.material_override = window_material()
	holder.add_child(quad)
	var glow := MeshInstance3D.new()
	glow.mesh = GolemModels.eyes_mesh()
	glow.scale = Vector3.ONE * 0.003
	holder.add_child(glow)
	var label := Label3D.new()
	label.text = "."
	label.pixel_size = 0.0005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED   # the same kind of label as the portal's words
	label.outline_size = 12
	label.font_size = 44
	holder.add_child(label)
	var t := holder.create_tween()
	t.tween_interval(0.25)
	t.tween_callback(holder.queue_free)

# --- M3 Task 5: where it leads ---------------------------------------------------------------------------

const WALK_IN := Vector3(1.0, 2.6, 0.6)   # the doorway: half its width, its height, half its depth
const WALK_OUT := 1.6                     # this far in front or behind: walking in counts again

var _near_player: Player
var _armed := true


## "Walk in: Sandstorm Desert!", M2's "Sandstorm Desert opens in the next update!" while that universe's
## file isn't there, or "… waits in Survivor!" in a Sandbox world (UniverseRules.portal_words).
func words() -> String:
	if target == UniverseRules.HUB:
		return UniverseRules.HUB_WORDS   # M3 Task 4: after the last universe
	return UniverseRules.portal_words(UniverseRegistry.display_name(target), UniverseRegistry.exists(target), Game.mode)


## Survivor, and the universe it leads to exists.
func leads_somewhere() -> bool:
	return not ModeRules.allows(Game.mode, ModeRules.CHEATS) and (UniverseRegistry.exists(target) or target == UniverseRules.HUB)


func _check_walk_in(me: Player) -> void:
	var local := to_local(me.global_position)
	var inside := absf(local.x) <= WALK_IN.x and local.y >= -0.5 and local.y <= WALK_IN.y and absf(local.z) <= WALK_IN.z
	if inside and _armed:
		_armed = false
		if leads_somewhere():
			entered.emit(target)
	elif not inside and (absf(local.z) > WALK_OUT or absf(local.x) > WALK_OUT + 0.5 or local.y > WALK_IN.y):
		_armed = true
