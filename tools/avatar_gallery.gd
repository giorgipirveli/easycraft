extends SceneTree
## Renders the avatar looks in both styles to a PNG, to check parts and colours by eye (M3 Task 9):
## a row of blocky bodies over a row of realistic people, one column per look, optionally from behind
## or in an emote pose. Needs a display (not --headless):
##   godot --path . --disable-vsync --script res://tools/avatar_gallery.gd -- --out=/tmp/gallery.png [--back] [--side]
##   [--emote=wave] [--close] (--close: the realistic heads only, big)

const LOOKS := [
	{},
	{"shirt": "red", "hat": "crown", "cape": "hero", "hair": "spiky", "hair_color": "blond", "skin": "peach"},
	{"hair": "long", "hair_color": "pink", "shirt": "purple", "pants": "white", "wings": "angel", "hat": "flower", "skin": "brown", "face": "wink"},
	{"hair": "curly", "hair_color": "black", "skin": "deep", "shirt": "yellow", "hat": "cowboy", "face": "cool", "wings": "butterfly"},
	{"outfit": "knight", "cape": "royal"},
	{"outfit": "astronaut"},
	{"outfit": "dino", "skin": "tan"},
	{"outfit": "robot", "wings": "bat"},
	{"outfit": "pirate", "hair": "bun", "hair_color": "red", "skin": "light"},
	{"outfit": "ninja"},
	{"outfit": "candy", "hair": "long", "hair_color": "blond", "wings": "fairy"},
	{"outfit": "cosmic", "trail": "stars"},
]
const SPACING := 1.4


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out := "user://avatar_gallery.png"
	var back := args.has("--back")
	var side := args.has("--side")
	var close := args.has("--close")
	var emote := &""
	for a: String in args:
		if a.begins_with("--out="):
			out = a.trim_prefix("--out=")
		elif a.begins_with("--emote="):
			emote = StringName(a.trim_prefix("--emote="))
	root.size = Vector2i(1920, 720)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("9ec9e8")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.75, 0.78, 0.85)
	env.environment.ambient_light_energy = 0.7
	root.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 150 if back else -30, 0)
	root.add_child(sun)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	var width := (LOOKS.size() - 1) * SPACING
	cam.size = 2.0 if close else 6.4
	var aim := Vector3(width * 0.5, 1.55 if close else 2.0, 0.0)
	if close:
		aim = Vector3(0.0 if side else 2.5 * SPACING, 1.55, 3.0 if side else 0.0)
	var from := aim + (Vector3(-12.0, 0.0, 0.0) if side else Vector3(0.0, 0.0, 12.0 if back else -12.0))
	root.add_child(cam)
	cam.look_at_from_position(from, aim)
	cam.current = true
	var avatars: Array[AvatarModel] = []
	for i in LOOKS.size():
		var look := AvatarLook.from_dict(LOOKS[i])
		for row in 2:
			if close and (row == 0 or i > 5):
				continue
			var a: AvatarModel = BlockyAvatar.new() if row == 0 else RealisticAvatar.new()
			a.position = Vector3(i * SPACING, 2.2 - row * 2.2, 0.0)
			if close:
				a.position = Vector3(0.0, 0.0, i * 1.2) if side else Vector3(i * SPACING, 0.0, 0.0)
			a.apply_look(look)
			root.add_child(a)
			avatars.append(a)
	await process_frame
	for f in 20:
		for a in avatars:
			a.animate(0.0, true, 1.0 / 30.0)
			if f == 1 and emote != &"":
				a.play_emote(emote)
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	img.save_png(out)
	print("GALLERY saved %s (%dx%d)" % [out, img.get_width(), img.get_height()])
	quit()
