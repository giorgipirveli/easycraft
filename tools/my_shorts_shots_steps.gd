extends Node
## The steps of tools/my_shorts_shots.gd (a Node, so it may use the autoloads and the classes).

const CELL := Vector2i(225, 400)
const PANEL_SCREENS: Array[Vector2i] = [Vector2i(1600, 720), Vector2i(1280, 720)]
const SAMPLES := "res://docs/store/graphics/next"
const ALBUM := "user://my_shorts_shots_album"

var _photos: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := ProjectSettings.globalize_path("user://my_shorts_shots")
	DirAccess.make_dir_recursive_absolute(out)
	print("MY_SHORTS_SHOT dir %s" % out)
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "true"
	_album()
	if args.has("panel"):
		await _panel(out)
	if args.has("sheets"):
		await _sheets(out)
	if args.has("bench"):
		await _bench()
	get_tree().quit()


## The store's pictures of the game as the album's photos (as if photo mode had taken them).
func _album() -> void:
	MyShortAlbum.use(ALBUM, PackedStringArray())
	var n := 0
	for f in DirAccess.get_files_at(SAMPLES):
		if not f.begins_with("shot-") or not f.ends_with(".jpg"):
			continue
		var img := Image.load_from_file(SAMPLES.path_join(f))
		if img == null:
			continue
		var file := "p_20261001_1%05d.jpg" % n
		MyShortAlbum.keep_png_now(img.save_png_to_buffer(), file)
		_photos.append(file)
		n += 1
	print("MY_SHORTS_SHOT album %d photos" % _photos.size())


func _profile() -> ProfileData:
	var p := ProfileData.new()
	p.age_band = AgeBand.TEEN_PLUS
	p.username = "Pip"
	p.avatar = Profile.data.avatar.duplicate()
	return p


func _panel_for(profile: ProfileData, screen: Vector2i) -> Array:
	get_window().size = screen
	await get_tree().process_frame
	var back := ColorRect.new()
	back.color = Color("5b8fd6")
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(back)
	var panel: Variant = TheaterPanel.new()
	panel.list = TheaterChannels.load_path(TheaterChannels.BUNDLED_PATH)
	panel.profile = profile
	panel.save_profile = func() -> void: pass
	panel.frees_mouse = false
	panel.is_mobile = false
	add_child(panel)
	await get_tree().process_frame
	panel.open()
	return [panel, back]


func _panel(dir: String) -> void:
	for screen in PANEL_SCREENS:
		var tag := "%dx%d" % [screen.x, screen.y]
		var profile := _profile()
		var made: Array = await _panel_for(profile, screen)
		var panel: TheaterPanel = made[0]
		var v := panel.shorts
		v.set_filter(ShortFeed.MINE)
		await _shot(dir, "mine_empty_" + tag)
		v.open_maker()
		var m := v.maker
		await _shot(dir, "maker_1_kind_" + tag)
		m.choose_template(MyShortRules.BUILT)
		for i in [0, 3, 6]:
			m.toggle_photo(i)
		await _settle(m)
		await _shot(dir, "maker_2_photos_" + tag)
		m.next()
		m.choose_slot("body:0")
		m.choose_words("First, I picked my blocks.")
		await _settle(m)
		await _shot(dir, "maker_3_words_" + tag)
		m.start_typing()
		m.type_field.text = "I hid a secret door"
		await _shot(dir, "maker_3_typing_" + tag)
		m.type_words("shit")
		await _shot(dir, "maker_3_refused_" + tag)
		m._close_typing()
		m.next()
		m.choose_backdrop("sunset")
		m.choose_music("spring")
		await _settle(m)
		await _shot(dir, "maker_4_look_" + tag)
		m.next()
		await _settle(m)
		for i in 75:
			m.preview.advance(1.0 / 30.0)
		await _shot(dir, "maker_5_save_" + tag)
		m.next()
		await _settle(m)
		for i in 150:
			v.player().advance(1.0 / 30.0)
		await _shot(dir, "mine_playing_" + tag)
		v.open_maker()
		m.choose_template(MyShortRules.FACTS)
		await _settle(m)
		await _shot(dir, "maker_2_planets_" + tag)
		m.choose_subject(MyShortFacts.WONDER, "pyramid")
		m.thing_kind = MyShortFacts.WONDER
		m._build_page()
		await _settle(m)
		await _shot(dir, "maker_2_wonders_" + tag)
		m.thing_kind = MyShortFacts.ANIMAL
		m._build_page()
		await _shot(dir, "maker_2_animals_" + tag)
		m.back()
		m.choose_template(MyShortRules.STEPS)
		m.choose_build({"kind": "blueprint", "id": "house", "blocks": {}})
		await _settle(m)
		await _shot(dir, "maker_2_builds_" + tag)
		m.close()
		for i in MyShortRules.MAX_SHORTS:
			profile.my_shorts.add({"template": "facts", "subject": {"kind": "planet", "id": "mars"}}, i)
		v.open_maker()
		await _shot(dir, "maker_full_" + tag)
		m.close()
		panel.queue_free()
		made[1].queue_free()
		await get_tree().process_frame


func _settle(m: MyShortMakerView) -> void:
	m.finish_imports()
	for i in 6:
		await get_tree().process_frame


## Made Shorts, a picture every 2 s.
func _sheets(dir: String) -> void:
	var recipes := {
		"built": {"template": "built", "title": "How I built my castle", "photos": [_photos[0], _photos[3], _photos[6]],
			"captions": ["First, I picked my blocks.", "I made it colourful!", ""], "backdrop": "sky"},
		"facts_saturn": {"template": "facts", "subject": {"kind": "planet", "id": "saturn"}, "backdrop": "space"},
		"facts_wonder": {"template": "facts", "subject": {"kind": "wonder", "id": "taj_mahal"}, "backdrop": "sunset"},
		"facts_animal": {"template": "facts", "subject": {"kind": "animal", "id": "penguin"}, "backdrop": "sea"},
		"steps_house": {"template": "steps", "build": {"kind": "blueprint", "id": "house"}, "backdrop": "paper"},
		"steps_rainbow": {"template": "steps", "build": {"kind": "blueprint", "id": "rainbow"}, "backdrop": "grass"},
	}
	for key: String in recipes:
		var s := MyShortMaker.make(recipes[key])
		var problems := ShortCheck.problems(s)
		print("MY_SHORTS_SHOT %s checker %s, %.1f s" % [key, problems, ShortTimeline.length(s)])
		var times: Array[float] = []
		var t := 1.0
		while t < ShortTimeline.length(s):
			times.append(t)
			t += 2.0
		var cols := mini(times.size(), 8)
		var rows := ceili(float(times.size()) / cols)
		get_window().size = Vector2i(CELL.x * cols, CELL.y * rows)
		await get_tree().process_frame
		var player := ShortPlayer.new()
		player.size = Vector2(CELL)
		player.hide_play_sign = true
		add_child(player)
		player.build(s)
		for i in 20:   # the photos load on workers
			await get_tree().process_frame
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
		var path := "%s/sheet_%s.png" % [dir, key]
		sheet.save_png(path)
		print("MY_SHORTS_SHOT sheet %s %s" % [key, path])
		player.queue_free()
		await get_tree().process_frame


## Frame times at the emulator's canvas: MY SHORTS (six Shorts of every kind) played a while each and swiped, then the
## maker with its preview playing while choices change.
func _bench() -> void:
	if OS.get_cmdline_user_args().has("--novoice"):   # the system voice off (a Linux desktop's speech service is slow)
		ReadAloud.voice = ReadAloud.Voice.new()
	var profile := _profile()
	profile.my_shorts.add({"template": "built", "photos": [_photos[0], _photos[1], _photos[2], _photos[3]]}, 1)
	profile.my_shorts.add({"template": "facts", "subject": {"kind": "planet", "id": "saturn"}}, 2)
	profile.my_shorts.add({"template": "steps", "build": {"kind": "blueprint", "id": "tower"}}, 3)
	profile.my_shorts.add({"template": "facts", "subject": {"kind": "wonder", "id": "colosseum"}, "music": "spring"}, 4)
	profile.my_shorts.add({"template": "built", "photos": [_photos[4], _photos[5]], "music": "ode_to_joy"}, 5)
	profile.my_shorts.add({"template": "facts", "subject": {"kind": "animal", "id": "fox"}}, 6)
	var made: Array = await _panel_for(profile, Vector2i(1600, 720))
	var panel: TheaterPanel = made[0]
	var v := panel.shorts
	v.set_filter(ShortFeed.MINE)
	for k in 8:
		await get_tree().process_frame
	var times: Array[float] = []
	var last := Time.get_ticks_usec()
	for n in 6:
		v.shown = 0
		if n == 0:
			v.toggle_play()
		else:
			v.step(1)
		var until := Time.get_ticks_msec() + 2500
		while Time.get_ticks_msec() < until:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			times.append((now - last) / 1000.0)
			if times.back() > 12.0:
				print("MY_SHORTS_BENCH slow frame %.1f ms: %s at %.2f s" % [times.back(), v.current_entry().get("id", ""), v.player().time])
			last = now
	_report("feed", times)
	v.open_maker()
	var m := v.maker
	m.choose_template(MyShortRules.BUILT)
	times.clear()
	last = Time.get_ticks_usec()
	var picks := [0, 1, 2, 3]
	for n in 24:
		if n < 4:
			m.toggle_photo(picks[n])
		elif n == 4:
			m.next()
		elif n < 10:
			m.choose_slot("body:%d" % ((n - 5) % 4))
			m.choose_words(MyShortRules.PHOTO_PHRASES[n])
		elif n == 10:
			m.next()
		elif n < 18:
			m.choose_backdrop(MyShortRules.BACKDROPS[n % MyShortRules.BACKDROPS.size()])
		elif n == 18:
			m.choose_music("waltz_flowers")
			m.next()
		var until := Time.get_ticks_msec() + 400
		while Time.get_ticks_msec() < until:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			times.append((now - last) / 1000.0)
			if times.back() > 12.0:
				print("MY_SHORTS_BENCH slow frame %.1f ms: maker step %d action %d" % [times.back(), m.step, n])
			last = now
	_report("maker", times)
	panel.queue_free()
	made[1].queue_free()
	await get_tree().process_frame


func _report(what: String, times: Array[float]) -> void:
	times.remove_at(0)
	var total := 0.0
	for t in times:
		total += t
	var sorted := times.duplicate()
	sorted.sort()
	print("MY_SHORTS_BENCH %s frames %d avg %.2f ms (%.0f FPS) p99 %.2f ms worst %.2f ms" % [what, times.size(),
		total / times.size(), 1000.0 * times.size() / total, sorted[int(sorted.size() * 0.99)], sorted.back()])


func _shot(dir: String, shot_name: String) -> void:
	for i in 5:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := "%s/%s.png" % [dir, shot_name]
	image.save_png(path)
	print("MY_SHORTS_SHOT %s %s" % [shot_name, image.get_size()])
