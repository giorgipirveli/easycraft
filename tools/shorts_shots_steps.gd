extends Node
## The steps of tools/shorts_shots.gd (a Node, so it may use the autoloads and the classes).

const CELL := Vector2i(225, 400)
const PANEL_SCREENS: Array[Vector2i] = [Vector2i(1600, 720), Vector2i(1280, 720)]


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := ProjectSettings.globalize_path("user://shorts_shots")
	DirAccess.make_dir_recursive_absolute(out)
	print("SHORTS_SHOT dir %s" % out)
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "true"
	if args.has("panel"):
		await _panel(out)
	if args.has("bench"):
		await _bench()
	var ids: Array[String] = []
	if args.has("all"):
		ids.append_array(ShortLibrary.hand_ids())
	if args.has("short"):
		ids.append_array(str(args.short).split(",", false))
	for id in ids:
		await _sheet(out, id, int(args.get("frames", "8")), args.has("motion"))
	get_tree().quit()


## A contact sheet: `frames` moments of the Short (the middle of each scene when frames is 0), side by side.
func _sheet(dir: String, id: String, frames: int, _motion: bool) -> void:
	var s := ShortLibrary.get_short(id)
	if s.is_empty():
		print("SHORTS_SHOT no short %s" % id)
		return
	var times: Array[float] = []
	var length := ShortTimeline.length(s)
	if frames <= 0:
		for i in ShortTimeline.scenes(s).size():
			times.append(ShortTimeline.scene_start(s, i) + ShortTimeline.seconds_of(ShortTimeline.scenes(s)[i]) * 0.7)
	else:
		for i in frames:
			times.append(length * (i + 0.5) / frames)
	var cols := mini(times.size(), 8)
	var rows := ceili(float(times.size()) / cols)
	get_window().size = Vector2i(CELL.x * cols, CELL.y * rows)
	await get_tree().process_frame
	var player := ShortPlayer.new()
	player.size = Vector2(CELL)
	player.position = Vector2.ZERO
	player.hide_play_sign = true
	add_child(player)
	player.build(s)
	var sheet := Image.create(CELL.x * cols, CELL.y * rows, false, Image.FORMAT_RGBA8)
	for i in times.size():
		player.seek(times[i])
		for k in 3:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.convert(Image.FORMAT_RGBA8)
		var scale := get_window().size.x / float(get_viewport().get_visible_rect().size.x)
		var cell := img.get_region(Rect2i(Vector2i.ZERO, Vector2i(Vector2(CELL) * scale)))
		cell.resize(CELL.x, CELL.y)
		sheet.blit_rect(cell, Rect2i(Vector2i.ZERO, CELL), Vector2i((i % cols) * CELL.x, (i / cols) * CELL.y))
	var path := "%s/%s.png" % [dir, id.replace(":", "_")]
	sheet.save_png(path)
	print("SHORTS_SHOT %s %s %s" % [id, times, path])
	player.queue_free()
	await get_tree().process_frame


func _panel(dir: String) -> void:
	for screen in PANEL_SCREENS:
		get_window().size = screen
		await get_tree().process_frame
		var back := ColorRect.new()
		back.color = Color("5b8fd6")
		back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(back)
		var panel: Variant = TheaterPanel.new()
		panel.list = TheaterChannels.load_path(TheaterChannels.BUNDLED_PATH)
		var profile := ProfileData.new()
		profile.age_band = AgeBand.TEEN_PLUS
		profile.shorts.mark_seen(ShortLibrary.hand_ids()[0])
		panel.profile = profile
		panel.save_profile = func() -> void: pass
		panel.frees_mouse = false
		panel.is_mobile = false
		add_child(panel)
		await get_tree().process_frame
		panel.open()
		await _shot(dir, "panel_%dx%d_open" % [screen.x, screen.y])
		panel.shorts.player().play()
		for i in 60:
			panel.shorts.player().advance(1.0 / 30.0)
		await _shot(dir, "panel_%dx%d_playing" % [screen.x, screen.y])
		panel.shorts.set_filter(ShortFeed.LESSONS)
		await _shot(dir, "panel_%dx%d_lessons" % [screen.x, screen.y])
		panel.queue_free()
		back.queue_free()
		await get_tree().process_frame


## A frame-time bench at the emulator's canvas: each Short plays a while, then a swipe snaps the next in (the hand-made
## ones, then grade 5's lessons), with the Theater's panel as the game shows it. Prints SHORTS_BENCH lines.
func _bench() -> void:
	get_window().size = Vector2i(1600, 720)
	var back := ColorRect.new()
	back.color = Color("5b8fd6")
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var panel: Variant = TheaterPanel.new()
	panel.list = TheaterChannels.load_path(TheaterChannels.BUNDLED_PATH)
	var profile := ProfileData.new()
	profile.age_band = AgeBand.TEEN_PLUS
	profile.school.grade = 5
	panel.profile = profile
	panel.save_profile = func() -> void: pass
	panel.frees_mouse = false
	panel.is_mobile = false
	add_child(panel)
	await get_tree().process_frame
	panel.open()
	if OS.get_cmdline_user_args().has("--novoice"):
		panel.shorts.toggle_voice()
	for f: StringName in [ShortFeed.HAND, ShortFeed.LESSONS]:
		panel.shorts.set_filter(f)
		for k in 8:
			await get_tree().process_frame
		var times: Array[float] = []
		var last := Time.get_ticks_usec()
		for n in 9:
			panel.shorts.shown = 0
			var s0 := Time.get_ticks_usec()
			if n == 0:
				panel.shorts.toggle_play()
			else:
				panel.shorts.step(1)
			if Time.get_ticks_usec() - s0 > 20000:
				print("SHORTS_BENCH slow call %.1f ms" % ((Time.get_ticks_usec() - s0) / 1000.0))
			var until := Time.get_ticks_msec() + 1600
			while Time.get_ticks_msec() < until:
				await get_tree().process_frame
				var now := Time.get_ticks_usec()
				times.append((now - last) / 1000.0)
				if times.back() > 50.0:
					print("SHORTS_BENCH slow frame %.1f ms: %s at %.2f s" % [times.back(), panel.shorts.current_entry().get("id", ""),
						panel.shorts.player().time])
				last = now
		times.remove_at(0)
		var total := 0.0
		for t in times:
			total += t
		var sorted := times.duplicate()
		sorted.sort()
		print("SHORTS_BENCH %s frames %d avg %.2f ms (%.0f FPS) p99 %.2f ms worst %.2f ms" % [f, times.size(),
			total / times.size(), 1000.0 * times.size() / total, sorted[int(sorted.size() * 0.99)], sorted.back()])
	panel.queue_free()
	back.queue_free()
	await get_tree().process_frame


func _shot(dir: String, shot_name: String) -> void:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [dir, shot_name]
	image.save_png(path)
	print("SHORTS_SHOT %s %s" % [shot_name, image.get_size()])
