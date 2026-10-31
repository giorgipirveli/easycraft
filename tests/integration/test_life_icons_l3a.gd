extends GutTest
## Owner #118 (Life L3a): every new picture (LifeIconsDanger) is known to LifeIcons, drawn in one place only, and draws
## without an error at the sizes the screens use (a 48 px Passport icon, a 96 px picture answer, a 190 px card).


func test_every_l3a_picture_is_known_and_draws() -> void:
	var box := HFlowContainer.new()
	box.size = Vector2(1280, 720)
	add_child_autofree(box)
	for name in LifeIconsDanger.NAMES:
		assert_true(LifeIcons.has(name), name)
		assert_false(LifeIcons.NAMES.has(name) or LifeIconsMore.NAMES.has(name), name + " is drawn in one place only")
		for px: float in [48.0, 96.0, 190.0]:
			box.add_child(LifeIcons.new(name, px))
	await wait_process_frames(3)
	assert_eq(box.get_child_count(), LifeIconsDanger.NAMES.size() * 3)


func test_an_unknown_name_draws_nothing() -> void:
	var c := Control.new()
	add_child_autofree(c)
	assert_false(LifeIconsDanger.paint(c, "no_such_picture", func(x: float, y: float) -> Vector2: return Vector2(x, y), 1.0))
