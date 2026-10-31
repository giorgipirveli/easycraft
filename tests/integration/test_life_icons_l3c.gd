extends GutTest
## Owner #112, #118 (Life L3c): every new picture (LifeIconsEveryday: Online City, Find Your Way, Home Helper) is known to
## LifeIcons, drawn in one place only and draws at the screens' sizes; every picture an L3c Experience names exists; the
## Tool Book's new entries (the metro ticket, the washing label, the ticket gates, the help point, the dishwasher) have
## their own pictures, drawn by Life's.


func test_every_l3c_picture_is_known_and_draws() -> void:
	var box := HFlowContainer.new()
	box.size = Vector2(1280, 720)
	add_child_autofree(box)
	for name in LifeIconsEveryday.NAMES:
		assert_true(LifeIcons.has(name), name)
		assert_false(LifeIcons.NAMES.has(name) or LifeIconsMore.NAMES.has(name) or LifeIconsDanger.NAMES.has(name)
			or LifeIconsHazards.NAMES.has(name) or SuccessIcons.has(name), name + " is drawn in one place only")
		assert_false(ToolIcons.NAMES.has(name), name + ": never a tools' picture's name")
		for px: float in [48.0, 96.0, 190.0]:
			box.add_child(LifeIcons.new(name, px))
	await wait_process_frames(3)
	assert_eq(box.get_child_count(), LifeIconsEveryday.NAMES.size() * 3)


func test_an_unknown_name_draws_nothing() -> void:
	var c := Control.new()
	add_child_autofree(c)
	assert_false(LifeIconsEveryday.paint(c, "no_such_picture", func(x: float, y: float) -> Vector2: return Vector2(x, y), 1.0))


func test_every_picture_the_l3c_experiences_name_is_drawn() -> void:
	for id: String in ["online_city", "find_way", "home_helper"]:
		for track in LifeData.TRACKS:
			for expert: bool in [false, true]:
				for s in LifeExperience.steps(id, track, expert, 1, "ge") + LifeExperience.check(id, track, "ge"):
					for c: Variant in s.get("choices", []):
						assert_true(LifeIcons.has(str((c as Dictionary).get("icon", ""))), "%s.%s %s: %s" % [id, track,
							s.get("id"), c])
					var m: Variant = s.get("safe_mistake")
					if m is Dictionary:
						assert_true(LifeIcons.has(str((m as Dictionary).get("icon", ""))), "%s.%s %s" % [id, track, s.get("id")])


func test_the_tool_books_new_entries_have_their_own_pictures() -> void:
	for id: String in ["metro_ticket", "washing_label", "gates", "help_point", "dishwasher"]:
		var icon := ToolBook.icon(id)
		assert_false(icon in ["safety", "device", "tool"], "%s: its own picture, not %s" % [id, icon])
		assert_true(ToolIcons.has(icon), "%s: ToolIcons draws %s" % [id, icon])
		var pic := ToolIcons.new(icon, 96.0)
		add_child_autofree(pic)
		assert_eq(pic.find_children("*", "LifeIcons", false, false).size(), 1, id + ": drawn by Life's picture")
