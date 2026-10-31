extends Node
## The steps of tools/theater_shots.gd (a Node, so it may use the autoloads and the panel's classes).

const SCREENS: Array[Vector2i] = [Vector2i(1600, 720), Vector2i(1280, 720)]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := ProjectSettings.globalize_path("user://theater_shots")
	DirAccess.make_dir_recursive_absolute(out)
	print("THEATER_SHOT dir %s" % out)
	var back := ColorRect.new()
	back.color = Color("5b8fd6")   # a sky behind the panel
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	for screen in SCREENS:
		get_window().size = screen
		var tag := "%dx%d" % [screen.x, screen.y]
		var panel := TheaterPanel.new()
		panel.list = TheaterChannels.load_path(TheaterChannels.BUNDLED_PATH)
		var profile := ProfileData.new()
		profile.age_band = AgeBand.TEEN_PLUS
		panel.profile = profile
		panel.save_profile = func() -> void: pass
		panel.frees_mouse = false
		panel.is_mobile = false
		add_child(panel)
		await get_tree().process_frame
		panel.open()
		await _shot(out, "%s_open" % tag)
		panel.channel_buttons[1].pressed.emit()
		panel.page_next_button.pressed.emit()
		await _shot(out, "%s_space_page2" % tag)
		for i in 12:
			panel.next_button.pressed.emit()
		await _shot(out, "%s_end_card" % tag)
		panel.queue_free()
		await get_tree().process_frame
	get_tree().quit()


func _shot(dir: String, shot_name: String) -> void:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [dir, shot_name]
	image.save_png(path)
	print("THEATER_SHOT %s %s" % [shot_name, image.get_size()])
