extends GutTest
## P5 (VR draws): in a headset session the HUD's drawn pictures are one draw each (CanvasBatch) instead of one per
## polygon, circle and line: the hearts row (60 draws in the Sandbox's canvas before), a HUD button's symbol, the coin, the
## stealth eye. The same pictures: the same colours in the same places. Off VR every one draws exactly as before.


func after_each() -> void:
	GraphicsPreset.vr_session = false


func _colors(mesh: Dictionary) -> Array[Color]:
	var out: Array[Color] = []
	for c: Color in mesh.colors:
		if c.a > 0.0 and not out.has(c):
			out.append(c)
	return out


func _valid(mesh: Dictionary) -> void:
	assert_eq((mesh.indices as PackedInt32Array).size() % 3, 0)
	assert_eq((mesh.colors as PackedColorArray).size(), (mesh.points as PackedVector2Array).size())
	for i: int in mesh.indices:
		assert_true(i >= 0 and i < (mesh.points as PackedVector2Array).size())


func _bar() -> HeartsBar:
	var bar := HeartsBar.new()
	add_child_autofree(bar)
	bar.size = bar.bar_size()
	return bar


func test_the_hearts_row_is_one_triangle_list_of_its_ten_hearts() -> void:
	var bar := _bar()
	bar.set_hp(Health.MAX_HP)
	var full := bar.vr_mesh()
	_valid(full)
	var cs := _colors(full)
	assert_true(cs.has(HeartsBar.RED), "full hearts are red")
	assert_true(cs.has(HeartsBar.OUTLINE))
	assert_true(cs.has(HeartsBar.SHINE), "with their shine")
	assert_false(cs.has(HeartsBar.EMPTY))
	var xs := Array(full.points).map(func(p: Vector2) -> float: return p.x)
	assert_lt(xs.min(), 2.0, "from the first heart's left")
	assert_gt(xs.max(), bar.bar_size().x - 2.0, "to the last heart's right")


func test_empty_hearts_are_hollow_in_vr_too() -> void:
	var bar := _bar()
	bar.hp = 0
	var cs := _colors(bar.vr_mesh())
	assert_true(cs.has(HeartsBar.EMPTY))
	assert_true(cs.has(HeartsBar.EMPTY_RIM), "M5 Task 1: a light rim round an empty heart")
	assert_false(cs.has(HeartsBar.RED))
	assert_false(cs.has(HeartsBar.SHINE))


func test_a_half_heart_is_half_red() -> void:
	var bar := _bar()
	bar.hp = 1
	var mesh := bar.vr_mesh()
	var red_x: Array[float] = []
	for i in (mesh.points as PackedVector2Array).size():
		if mesh.colors[i] == HeartsBar.RED:
			red_x.append(mesh.points[i].x)
	assert_false(red_x.is_empty())
	assert_lte(red_x.max(), HeartsBar.HEART_SIZE * 0.5 + 0.5, "only the first heart's left half")


func test_in_vr_the_bar_draws_batched_and_off_vr_as_before() -> void:
	var bar := _bar()
	bar.queue_redraw()
	await wait_process_frames(2)
	assert_eq(bar.vr_draws, 0, "off VR: the phone's polygons")
	GraphicsPreset.vr_session = true
	bar.queue_redraw()
	await wait_process_frames(2)
	assert_eq(bar.vr_draws, 1, "in a headset: the one triangle list")


func test_a_hud_buttons_symbol_is_one_triangle_list_in_vr() -> void:
	var b := TouchButton.new()
	b.symbol = &"jump"
	b.text = "JUMP"
	b.size = Vector2(120, 120)
	add_child_autofree(b)
	await wait_process_frames(2)
	assert_eq(b.vr_draws, 0, "off VR as before")
	GraphicsPreset.vr_session = true
	b.queue_redraw()
	await wait_process_frames(2)
	assert_eq(b.vr_draws, 1, "the frame and the picture in one batch")
	var emote := EmoteButton.new()
	emote.size = Vector2(120, 120)
	add_child_autofree(emote)
	var slot := TouchButton.new()   # a hotbar slot: a texture and a number, no picture
	slot.round_shape = false
	slot.size = Vector2(80, 80)
	add_child_autofree(slot)
	await wait_process_frames(2)
	assert_eq(emote.vr_draws, 0, "a subclass's own picture is drawn as before")
	assert_eq(slot.vr_draws, 0, "nothing to gather: as before")


func test_every_hud_symbol_draws_into_a_batch() -> void:
	var c := Control.new()
	add_child_autofree(c)
	for s: StringName in HudIcons.SYMBOLS:
		var batch := CanvasBatch.new()
		HudIcons.draw_into(batch, s, Rect2(0, 0, 64, 64))
		assert_false(batch.is_empty(), str(s))
		_valid({"points": batch.points, "colors": batch.colors, "indices": batch.indices})


func test_the_coin_and_the_stealth_eye_are_one_draw_each_in_vr() -> void:
	var coin := CoinIcon.new(32.0)
	add_child_autofree(coin)
	coin.size = Vector2(32, 32)
	var meter := StealthMeter.new()
	add_child_autofree(meter)
	meter.size = meter.meter_size()
	await wait_process_frames(2)
	assert_eq(coin.vr_draws + meter.vr_draws, 0, "off VR as before")
	GraphicsPreset.vr_session = true
	for state: int in [StealthRules.EYE_OPEN, StealthRules.EYE_HALF, StealthRules.EYE_CLOSED]:
		meter.eye_state = state
		meter.queue_redraw()
		coin.queue_redraw()
		await wait_process_frames(2)
	assert_eq(coin.vr_draws, 3)
	assert_eq(meter.vr_draws, 3)


func _hotbar() -> Hotbar:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(multiplayer.get_unique_id())
	add_child_autofree(p)
	var bar := Hotbar.new()
	add_child_autofree(bar)
	bar.setup(p.get_node("BlockInteractor") as BlockInteractor)
	return bar


func test_the_hotbars_frames_are_one_draw_in_vr_and_the_slots_draw_their_pictures() -> void:
	var off := _hotbar()
	await wait_process_frames(3)
	assert_eq(off.vr_draws, 0, "off VR: each slot its own frame, as before")
	GraphicsPreset.vr_session = true
	var bar := _hotbar()
	await wait_process_frames(3)
	assert_gt(bar.vr_draws, 0, "the row draws its slots' frames, one batch a redraw")
	var frames := bar.vr_frames()
	_valid(frames)
	var gold := false
	for c: Color in frames.colors:
		gold = gold or (is_equal_approx(c.r, 1.0) and is_equal_approx(c.g, 0.85) and c.a > 0.0)
	assert_true(gold, "the selected slot's gold border")
	var slots := 0
	for c: Node in bar.get_children():
		if c is TouchButton:
			slots += 1
			assert_true((c as TouchButton).frame_drawn_by_parent, "a slot leaves its frame to the row")
	assert_gt((frames.points as PackedVector2Array).size(), slots * 8, "a rounded frame for each of the %d" % slots)


func test_the_read_aloud_speaker_is_one_draw_in_vr() -> void:
	var b := ReadAloud.button(func() -> String: return "hello")
	b.visible = true   # headless has no voice: shown here to be drawn
	b.size = Vector2(56, 56)
	add_child_autofree(b)
	await wait_process_frames(2)
	assert_eq(int(b.get("vr_draws")), 0, "off VR as before")
	GraphicsPreset.vr_session = true
	b.queue_redraw()
	await wait_process_frames(2)
	assert_eq(int(b.get("vr_draws")), 1, "its box, cone and waves in one batch")


func test_a_slots_frame_is_built_once_per_look() -> void:
	# A hotbar redraw (a selection, a pickup) must stay cheap on a Quest's CPU: one look's triangles are built once.
	GraphicsPreset.vr_session = true
	var a := TouchButton.new()
	var b := TouchButton.new()
	for t: TouchButton in [a, b]:
		t.round_shape = false
		t.size = Vector2(62, 62)
		add_child_autofree(t)
	assert_true(is_same(a.frame_mesh(), b.frame_mesh()), "the same look: the same cached triangles")
	b.selected = true
	assert_false(is_same(a.frame_mesh(), b.frame_mesh()), "the gold border is a look of its own")
	assert_eq((a.frame_mesh().points as PackedVector2Array).size(), (b.frame_mesh().points as PackedVector2Array).size(),
		"every look has the same shape of triangles (one index list for the row)")
