extends Node
## The steps of tools/polish_shots.gd (a Node, so it may use the autoloads and the game's classes).

const SCREENS: Array[Vector2i] = [Vector2i(1600, 720), Vector2i(1334, 750)]

var _out := ""


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	_out = ProjectSettings.globalize_path("user://polish_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	Profile.data.universe_unlocked = UniverseRegistry.size()
	Profile.data.settings.reduce_motion = false
	for screen in SCREENS:
		get_window().size = screen
		var tag := "%dx%d" % [screen.x, screen.y]
		var menu: Node = load("res://ui/menus/menu.tscn").instantiate()
		add_child(menu)
		await get_tree().create_timer(3.0).timeout   # the backdrop world streams in
		menu.call("_show_main")
		var d := (menu.get("_cam") as Camera3D).find_children("*", "TitleDiorama", false, false)[0] as TitleDiorama
		d.set_process(false)
		for t: float in [1.0, 4.3, 5.1, 7.0]:
			d.step(t - d.time())
			await _shot("%s_menu_t%.1f" % [tag, t])
		menu.call("_show_hub")
		await _shot("%s_hub" % tag)
		menu.call("_choose_difficulty", 3)
		await _shot("%s_brave_frost" % tag)
		menu.call("_choose_game", DifficultyRules.NORMAL, 5)
		await _shot("%s_game_dragon" % tag)
		menu.free()
		for u in range(1, UniverseRegistry.size() + 1):
			var layer := CanvasLayer.new()
			var card := LoadingCard.new()
			card.setup(ModeRules.SURVIVOR, u)
			layer.add_child(card)
			add_child(layer)
			await _shot("%s_loading_%d" % [tag, u])
			layer.free()
	print("POLISH_SHOT done: %s" % _out)
	get_tree().quit()


func _shot(shot_name: String) -> void:
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.save_png("%s/%s.png" % [_out, shot_name])
	print("POLISH_SHOT %s %s" % [shot_name, image.get_size()])
