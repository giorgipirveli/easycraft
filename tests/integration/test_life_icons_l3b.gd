extends GutTest
## Owner #118 (Life L3b): every new picture (LifeIconsHazards: electricity, animals, medical emergencies, fire and heat,
## choking) is known to LifeIcons, drawn in one place only, and draws without an error at the screens' sizes; every
## picture an L3b Experience names exists; and the Tool Book draws its entries with their own pictures (L3a's seven and
## L3b's eight through LifeIcons: never the plain "safety" or "device" stand-ins).


func test_every_l3b_picture_is_known_and_draws() -> void:
	var box := HFlowContainer.new()
	box.size = Vector2(1280, 720)
	add_child_autofree(box)
	for name in LifeIconsHazards.NAMES:
		assert_true(LifeIcons.has(name), name)
		assert_false(LifeIcons.NAMES.has(name) or LifeIconsMore.NAMES.has(name) or LifeIconsDanger.NAMES.has(name)
			or SuccessIcons.has(name), name + " is drawn in one place only")
		for px: float in [48.0, 96.0, 190.0]:
			box.add_child(LifeIcons.new(name, px))
	await wait_process_frames(3)
	assert_eq(box.get_child_count(), LifeIconsHazards.NAMES.size() * 3)


func test_an_unknown_name_draws_nothing() -> void:
	var c := Control.new()
	add_child_autofree(c)
	assert_false(LifeIconsHazards.paint(c, "no_such_picture", func(x: float, y: float) -> Vector2: return Vector2(x, y), 1.0))


func test_every_picture_the_l3b_experiences_name_is_drawn() -> void:
	for id: String in ["electricity", "animals", "medical", "kitchen", "fire_escape", "safe_streets"]:
		for track in LifeData.TRACKS:
			for expert: bool in [false, true]:
				for s in LifeExperience.steps(id, track, expert, 1, "ge") + LifeExperience.check(id, track, "ge"):
					for c: Variant in s.get("choices", []):
						assert_true(LifeIcons.has(str((c as Dictionary).get("icon", ""))), "%s.%s %s: %s" % [id, track,
							s.get("id"), c])


func test_the_tool_books_entries_have_their_own_pictures() -> void:
	for id: String in ["life_jacket", "ring_buoy", "reach_pole", "whistle", "emergency_bag", "child_lock", "co_alarm",
			"fuse_box", "rcd", "plug", "auto_injector", "inhaler", "pan_lid", "calendar", "jar"]:
		var icon := ToolBook.icon(id)
		assert_false(icon in ["safety", "device", "tool"], "%s: its own picture, not %s" % [id, icon])
		assert_true(ToolIcons.has(icon), "%s: ToolIcons draws %s" % [id, icon])
		assert_eq(ToolIcons.resolve(icon), icon, id)
		var pic := ToolIcons.new(icon, 96.0)
		add_child_autofree(pic)
		assert_eq(pic.find_children("*", "LifeIcons", false, false).size(), 1, id + ": drawn by Life's picture")
	var hammer := ToolIcons.new("hammer", 96.0)
	add_child_autofree(hammer)
	assert_eq(hammer.get_child_count(), 0, "the tools' own pictures stay ToolIcons' drawings")
