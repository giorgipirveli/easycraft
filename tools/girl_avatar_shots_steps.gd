extends Node
## The steps of tools/girl_avatar_shots.gd (a Node, so it may use the autoloads and the avatar classes).

const SCREEN := Vector2i(1600, 720)   # the emulator's 20:9 canvas (2400 × 1080 shows 1600 × 720)
const SPACING := 1.5
## Rows of looks: a blocky body over a realistic person in each column.
const LOOKS := [&"princess", &"adventurer", &"girl", &"skater", &"hero", &"boy", &"neutral"]
const HAIR := [["bangs", "blond"], ["ponytail", "red"], ["pigtails", "brown"], ["braid", "black"], ["buns", "pink"],
	["bob", "purple"], ["long", "platinum"], ["bun", "brown"], ["curly", "black"]]
const CUTS := [["none", "blue", "jeans"], ["dress", "lilac", "white"], ["gown", "rose", "white"], ["skirt", "mint", "pink"],
	["leggings", "sky", "purple"], ["hoodie", "yellow", "jeans"], ["overalls", "white", "jeans"], ["jacket", "teal", "jeans"]]
const FACES := ["sweet", "lovely", "rosy", "smile"]

var _out := ""
var _stage: Node3D
var _cam: Camera3D


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	if RealisticAvatar.model_path == "":
		RealisticAvatar.model_path = RealisticAvatar.MODEL_PATH
	_out = ProjectSettings.globalize_path("user://girl_avatar_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	get_window().size = SCREEN
	_world()
	var looks: Array[AvatarLook] = []
	for id: StringName in LOOKS:
		looks.append(AvatarLook.preset(id) if AvatarCatalog.PRESETS.has(id) else AvatarLook.start(id))
	await _rows(looks, "looks_front", false)
	await _rows(looks, "looks_back", true)
	var hair: Array[AvatarLook] = []
	for h: Array in HAIR:
		hair.append(AvatarLook.from_dict({"hair": h[0], "hair_color": h[1], "face": "sweet", "shirt": "rose", "skin": "peach"}))
	await _rows(hair, "hair_front", false)
	await _rows(hair, "hair_back", true)
	var cuts: Array[AvatarLook] = []
	for c: Array in CUTS:
		cuts.append(AvatarLook.from_dict({"clothes": c[0], "shirt": c[1], "pants": c[2], "hair": "ponytail", "face": "sweet",
			"skin": "light"}))
	await _rows(cuts, "clothes_front", false)
	var faces: Array[AvatarLook] = []
	for f: String in FACES:
		faces.append(AvatarLook.from_dict({"face": f, "hair": "bangs", "skin": "peach", "hair_color": "brown"}))
	await _faces(faces, "faces_close")
	await _editor()
	await _first_launch()
	print("GIRL_SHOT done: %s" % _out)
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
	var width := (looks.size() - 1) * SPACING
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


## Realistic heads close up (the lashes and cheeks), blocky heads above.
func _faces(looks: Array[AvatarLook], shot: String) -> void:
	_clear()
	(get_node("Sun") as DirectionalLight3D).rotation_degrees = Vector3(-30, -20, 0)
	var bodies: Array[AvatarModel] = []
	for i in looks.size():
		for row in 2:
			var a: AvatarModel = BlockyAvatar.new() if row == 0 else RealisticAvatar.new()
			a.position = Vector3(-(i - (looks.size() - 1) * 0.5) * 0.75, -row * 0.62, 0.0)
			a.apply_look(looks[i])
			_stage.add_child(a)
			bodies.append(a)
	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.size = 1.3
	var aim := Vector3(0, 1.28, 0)
	_cam.look_at_from_position(aim + Vector3(0, 0.1, -6.0), aim)
	await _settle(bodies)
	await _save(shot)


## The avatar editor after tapping GIRL (a private profile: nothing is saved).
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
	editor.profile = ProfileData.new()
	editor.save_profile = func() -> void: pass
	panel.add_child(editor)
	await get_tree().process_frame
	if editor.has_method(&"choose_base"):
		editor.call(&"choose_base", AvatarCatalog.GIRL)
	await _wait(1.0)
	await _save("editor_girl")
	if editor.has_method(&"select_tab"):
		editor.select_tab(AvatarCatalog.CLOTHES)
	await _wait(0.6)
	await _save("editor_clothes")
	editor.set_preview_style("realistic")
	if editor.has_method(&"pick_preset"):
		editor.call(&"pick_preset", &"princess")
	await _wait(1.0)
	await _save("editor_princess_real")
	layer.free()


## The first-launch look step (BOY / GIRL / JUST ME).
func _first_launch() -> void:
	var script := load("res://ui/avatar/look_choice.gd") as GDScript
	if script == null:
		return
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.theme = UiKit.theme()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)
	var back := ColorRect.new()
	back.color = Color(0.36, 0.55, 0.42)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(back)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.offset_top = 130
	ui.add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	panel.add_child(script.new())
	await _wait(0.5)
	await _save("first_launch")
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
	print("GIRL_SHOT %s %dx%d" % [path, image.get_width(), image.get_height()])
