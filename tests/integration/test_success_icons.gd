extends GutTest
## Owner #115 (Success S2): every Success picture (SuccessIcons) is known to LifeIcons, drawn in one place only, and draws
## without an error at the sizes the screens use; every picture the Success data names (the Experiences' answers and
## checks, the Goal Board, the habits, the stories, the people) exists.


class Painter:
	extends Control
	var names: Array[String] = []
	var drawn: Array[String] = []

	func _draw() -> void:
		for n in names:
			if SuccessIcons.paint(self, n, func(x: float, y: float) -> Vector2: return Vector2(x, y), 1.0):
				drawn.append(n)


func _icons_in(v: Variant, out: Dictionary) -> void:
	if v is Dictionary:
		for k: Variant in v:
			if str(k) == "icon" and v[k] is String and not str(v[k]).begins_with("{"):   # owner #115 (S3): a whole
				out[v[k]] = true   # token ("{one_good_icon}") is a try's own picture, checked filled by test_life_experience
			_icons_in(v[k], out)
	elif v is Array:
		for x: Variant in v:
			_icons_in(x, out)


func test_every_success_picture_is_known_and_draws() -> void:
	var box := HFlowContainer.new()
	box.size = Vector2(1280, 720)
	add_child_autofree(box)
	for name in SuccessIcons.NAMES:
		assert_true(LifeIcons.has(name), name)
		assert_false(LifeIcons.NAMES.has(name), name + " is drawn in one place only")
		assert_false(LifeIconsMore.NAMES.has(name), name + " is drawn in one place only")
		for px: float in [48.0, 96.0, 190.0]:
			box.add_child(LifeIcons.new(name, px))
	var painter := Painter.new()
	painter.names = SuccessIcons.NAMES
	painter.size = Vector2(100, 100)
	add_child_autofree(painter)
	await wait_process_frames(3)
	assert_eq(painter.drawn, SuccessIcons.NAMES, "every name draws something")


func test_every_picture_the_success_data_names_exists() -> void:
	var used := {}
	for id in SuccessExperiences.IDS:
		_icons_in(LifeExperience.data(id), used)
	_icons_in(SuccessGoals.data(), used)
	_icons_in(SuccessStories.data(), used)
	for p in SuccessPeople.list():
		used["person_" + str(p.id)] = true
	for a in LifeCatalog.areas_of("success"):
		used[str(a.icon)] = true
	for name: String in used:
		assert_true(LifeIcons.has(name), name)
