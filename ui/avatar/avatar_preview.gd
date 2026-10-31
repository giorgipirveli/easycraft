class_name AvatarPreview
extends SubViewportContainer
## The avatar editor's live 3D preview (M3 Task 9): the player's body in either style, on a little
## round stage in its own small world, turning slowly; a finger (or the mouse) turns it. It wears
## the editor's look as it changes, runs in place to show a trail, and shows emotes.

const TURN_SPEED := 0.45      # rad/s by itself
const DRAG_TURN := 0.012      # rad per pixel dragged
const CAMERA_AT := Vector3(0, 1.15, -4.3)
const LOOK_AT := Vector3(0, 0.98, 0)

var avatar: AvatarModel
var turntable := Node3D.new()
var style := "blocky"
## Runs in place (the trail tab: trails only show while running).
var running := false

var _viewport := SubViewport.new()
var _look := AvatarLook.new()


func _init(size_px: Vector2 = Vector2(380, 440)) -> void:
	custom_minimum_size = size_px
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_2X
	_viewport.size = Vector2i(size_px)
	add_child(_viewport)
	var cam := Camera3D.new()
	cam.fov = 38.0
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("8ec5ea")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.78, 0.8, 0.88)
	env.ambient_light_energy = 0.75
	cam.environment = env
	_viewport.add_child(cam)
	cam.look_at_from_position(CAMERA_AT, LOOK_AT)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -150, 0)
	sun.light_energy = 1.1
	_viewport.add_child(sun)
	var stage := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 0.9
	disc.bottom_radius = 0.95
	disc.height = 0.12
	disc.radial_segments = 24
	stage.mesh = disc
	stage.material_override = AvatarParts.material(Color("5fbf5a"))
	stage.position.y = -0.06
	_viewport.add_child(stage)
	_viewport.add_child(turntable)


func _ready() -> void:
	gui_input.connect(_on_gui_input)
	_rebuild()


func set_look(look: AvatarLook) -> void:
	_look = look.duplicate()
	if avatar:
		avatar.apply_look(_look)


func set_style(new_style: String) -> void:
	if new_style == style and avatar:
		return
	style = new_style
	if is_inside_tree():
		_rebuild()


func play_emote(emote_name: StringName) -> void:
	if avatar:
		avatar.play_emote(emote_name)


func _rebuild() -> void:
	if avatar:
		avatar.free()
	var realistic := style == "realistic" and RealisticAvatar.load_model() != null
	avatar = RealisticAvatar.new() if realistic else BlockyAvatar.new()
	avatar.name = "Avatar"
	avatar.apply_look(_look)
	turntable.add_child(avatar)


func _process(delta: float) -> void:
	turntable.rotation.y = wrapf(turntable.rotation.y + TURN_SPEED * delta, -PI, PI)
	if avatar:
		avatar.animate(4.0 if running else 0.0, true, delta)


## A finger or the mouse turns the stage.
func _on_gui_input(event: InputEvent) -> void:
	var drag := Vector2.ZERO
	if event is InputEventMouseMotion and (event as InputEventMouseMotion).button_mask & MOUSE_BUTTON_MASK_LEFT:
		drag = (event as InputEventMouseMotion).relative
	elif event is InputEventScreenDrag:
		drag = (event as InputEventScreenDrag).relative
	if drag != Vector2.ZERO:
		turntable.rotation.y = wrapf(turntable.rotation.y + drag.x * DRAG_TURN, -PI, PI)
		accept_event()
