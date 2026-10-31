extends Node
## The steps of tools/costume_shots.gd (a Node, so it may use the autoloads and the avatar classes).

const SCREEN := Vector2i(1600, 720)   # the emulator's 20:9 canvas (2400 × 1080 shows 1600 × 720)
const SPACING := 1.5
const PER_ROW := 7
## Skin tones to show the costumes on (each costume keeps the child's own).
const SKINS: Array[StringName] = [&"light", &"tan", &"peach", &"brown", &"light", &"deep", &"peach"]
const FACES: Array[StringName] = [&"pinocchio", &"merlin", &"alice", &"dorothy", &"fairy", &"hercules"]

var _out := ""
var _stage: Node3D
var _cam: Camera3D


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	if RealisticAvatar.model_path == "":
		RealisticAvatar.model_path = RealisticAvatar.MODEL_PATH
	_out = ProjectSettings.globalize_path("user://costume_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	get_window().size = SCREEN
	_world()
	var ids := CostumeRules.ORDER
	var n := 0
	for start in range(0, ids.size(), PER_ROW):
		n += 1
		var looks: Array[AvatarLook] = []
		for i in range(start, mini(start + PER_ROW, ids.size())):
			var own := AvatarLook.new()
			own.skin = SKINS[(i - start) % SKINS.size()]
			looks.append(CostumeRules.wear(ids[i], own))
		await _rows(looks, "costumes_%d_front" % n, false)
		await _rows(looks, "costumes_%d_back" % n, true)
	var faces: Array[AvatarLook] = []
	for id in FACES:
		var own := AvatarLook.new()
		own.skin = &"peach"
		faces.append(CostumeRules.wear(id, own))
	await _faces(faces, "faces_close")
	await _editor()
	print("COSTUME_SHOT done: %s" % _out)
	get_tree().quit()


func _world() -> void:
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("9ec9e8")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.78, 0.8, 0.88)
	env.environment.ambient_light_energy = 0.75
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_energy = 1.1
	add_child(sun)
	_cam = Camera3D.new()
	add_child(_cam)
	_cam.current = true


## A blocky body over a realistic person for each look, from the front or the back.
func _rows(looks: Array[AvatarLook], shot: String, back: bool) -> void:
	_clear()
	(get_node("Sun") as DirectionalLight3D).rotation_degrees = Vector3(-42, 150.0 if back else -30.0, 0)
	var width := (PER_ROW - 1) * SPACING
	var bodies: Array[AvatarModel] = []
	for i in looks.size():
		for row in 2:
			var a: AvatarModel = BlockyAvatar.new() if row == 0 else RealisticAvatar.new()
			var x := i * SPACING - width * 0.5
			a.position = Vector3(x if back else -x, 2.3 - row * 2.3, 0.0)   # the first look on the left
			a.apply_look(looks[i])
			_stage.add_child(a)
			bodies.append(a)
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = maxf(4.8, (width + SPACING) * float(SCREEN.y) / float(SCREEN.x))
	var aim := Vector3(0, 2.0, 0)
	_cam.look_at_from_position(aim + Vector3(0, 0.4, 12.0 if back else -12.0), aim)
	await _settle(bodies)
	await _save(shot)


## Heads close up: blocky above, realistic below, a little from the side so noses and beards show.
func _faces(looks: Array[AvatarLook], shot: String) -> void:
	_clear()
	(get_node("Sun") as DirectionalLight3D).rotation_degrees = Vector3(-30, -20, 0)
	var bodies: Array[AvatarModel] = []
	for i in looks.size():
		for row in 2:
			var a: AvatarModel = BlockyAvatar.new() if row == 0 else RealisticAvatar.new()
			a.position = Vector3(-(i - (looks.size() - 1) * 0.5) * 1.1, -row * 1.25, 0.0)
			a.rotation_degrees.y = 30.0
			a.apply_look(looks[i])
			_stage.add_child(a)
			bodies.append(a)
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = 2.6
	var aim := Vector3(0, 0.85, 0)
	_cam.look_at_from_position(aim + Vector3(0, 0.1, -6.0), aim)
	await _settle(bodies)
	await _save(shot)


## The avatar editor's COSTUME tab (a private profile with two costumes earned: nothing is saved).
func _editor() -> void:
	_clear()
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.theme = UiKit.theme()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 130   # like the main menu, under the logo
	ui.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var editor := AvatarEditor.new()
	var profile := ProfileData.new()
	profile.progress.xp = LevelRules.xp_to_reach(3)
	profile.progress.quests.done.append("tilly_pets")
	editor.profile = profile
	editor.save_profile = func() -> void: pass
	panel.add_child(editor)
	await _wait(0.8)
	await _save("editor_opened")
	editor.select_tab(AvatarCatalog.OUTFIT)
	editor.pick_costume(&"alice")
	await _wait(1.0)
	await _save("editor_costume_alice")
	editor.pick_costume(&"sherlock")
	await _wait(1.0)
	await _save("editor_costume_locked")
	editor.set_preview_style("realistic")
	editor.pick_costume(&"dorothy")
	await _wait(1.2)
	await _save("editor_costume_dorothy_real")
	layer.free()


func _clear() -> void:
	if _stage:
		_stage.free()
	_stage = Node3D.new()
	add_child(_stage)


func _settle(bodies: Array[AvatarModel]) -> void:
	await get_tree().process_frame
	for f in 20:
		for a in bodies:
			a.animate(0.0, true, 1.0 / 30.0)
		await get_tree().process_frame


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _save(shot: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := _out.path_join(shot + ".png")
	image.save_png(path)
	print("COSTUME_SHOT %s %dx%d" % [path, image.get_width(), image.get_height()])
