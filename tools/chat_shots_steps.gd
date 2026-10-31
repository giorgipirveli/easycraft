extends Node
## The steps of tools/chat_shots.gd (a Node, so it may use the autoloads and the HUD's classes).

## The emulator's 20:9 canvas (2400 × 1080 shows 1600 × 720) and a 16:9 phone.
const SCREENS: Array[Vector2i] = [Vector2i(1600, 720), Vector2i(1280, 720)]
## A phone's landscape keyboard covers about the bottom half of the screen (Gboard, Samsung Keyboard).
const KEYBOARD_SHARE := 0.55
const TYPED := "Hello! Come here, let's build a house together"
const LINES: Array[Array] = [
	["Hi!", &"chat", "Pip"],
	["Sure! Where are you?", &"chat", "Kid"],
	["I found a cave with lots of shiny blocks and a waterfall behind the big tree near the river, come see it before it gets dark!", &"chat", "Pip"],
	["Hello! Come over here", &"chat", "Nika"],
	["*Wave*", &"chat", "Nika"],
	["OK! I'm right behind you!", &"bot", "Mossy (bot)"],
	["Night is coming. Build a roof!", &"system", ""],
	["Follow me!", &"chat", "Pip"],
	["aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", &"chat", "Pip"],
	["ok building a house 🙂", &"chat", "Nika"],
]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := ProjectSettings.globalize_path("user://chat_shots")
	DirAccess.make_dir_recursive_absolute(out)
	var back := ColorRect.new()
	back.color = Color(0.62, 0.8, 0.95)   # a bright sky: the hardest background for white words
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var band := Profile.data.age_band
	Profile.data.age_band = AgeBand.TEEN_PLUS
	for screen in SCREENS:
		get_window().size = screen
		var p := _player()
		var hud := Hud.new()
		add_child(hud)
		hud.setup(p, "Kid", true, true)
		hud.add_health_controls()
		hud.add_secret_controls(null)
		hud.show_difficulty_badge(DifficultyRules.BRAVE)
		hud.add_game_clock()
		hud.game_clock.show_build(DayCycle.SUNSET - 50.0 * BuildRules.DAY_SPEED / DayCycle.LENGTH, 3, 5, ShelterRules.SAFE)
		hud.game_line.show_line("Build to Survive: night in 0:50")
		for l: Array in LINES:
			hud.chat.add_line(l[0], l[1], l[2])
		var keyboard := ColorRect.new()   # the phone's keyboard, over everything
		keyboard.color = Color(0.13, 0.14, 0.16)
		keyboard.mouse_filter = Control.MOUSE_FILTER_IGNORE
		keyboard.anchor_top = 1.0 - KEYBOARD_SHARE
		keyboard.anchor_right = 1.0
		keyboard.anchor_bottom = 1.0
		var px := int(round(DisplayServer.window_get_size().y * KEYBOARD_SHARE))
		hud.chat.keyboard_height = func() -> int: return px   # the chat's own reading of it (owner 49)
		var tag := "%dx%d" % [screen.x, screen.y]
		await _shot(out, "%s_closed" % tag)
		hud.chat.open()
		add_child(keyboard)
		await _shot(out, "%s_open_phrases" % tag)
		hud.chat._set_text(TYPED)
		await _shot(out, "%s_open_typing" % tag)
		hud.chat._set_text("/")
		await _shot(out, "%s_open_commands" % tag)
		keyboard.queue_free()
		hud.chat.open_wheel()
		await _shot(out, "%s_wheel" % tag)
		hud.chat.close()
		hud.free()
		p.free()
	Profile.data.age_band = band
	print("CHAT_SHOT done: %s" % out)
	get_tree().quit()


## A player standing in empty air (the HUD's buttons need one), kept still.
func _player() -> Player:
	var w := _AirWorld.new()
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	p.world = w
	add_child(p)
	p.set_physics_process(false)
	p.viewer.free()
	p.visible = false
	return p


class _AirWorld:
	extends WorldService

	func get_block(_pos: Vector3i) -> int:
		return BlockIds.AIR


func _shot(dir: String, shot_name: String) -> void:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [dir, shot_name]
	image.save_png(path)
	print("CHAT_SHOT %s %s" % [shot_name, image.get_size()])
