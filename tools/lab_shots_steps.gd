extends Node
## The steps of tools/lab_shots.gd (a Node, so it may use the autoloads and the Lab's classes).

var _out := ""
var _profile := ProfileData.new()
var _clock := [2_000_000_000]
var _panel: PanelContainer
var _lab: LabScreen


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	get_window().size = Vector2i(1600, 720) if args.has("--wide") else Vector2i(1280, 720)
	_out = ProjectSettings.globalize_path("user://lab_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	_profile.school.grade = 4
	_stage()
	await _shot("list", func() -> void: _lab.show_list())
	for id in LabExperiments.ids():
		_lab.open(id)
		_guess(id)
		await _wait(0.2)
		await _save("%s_1_predict" % id)
		_lab.try_button.pressed.emit()
		await _wait(0.3)
		await _save("%s_2_try" % id)
		_half(id)
		await _wait(0.9)
		await _save("%s_2_try_half" % id)
		_finish(id)
		await _wait(0.9)
		await _save("%s_2_try_seen" % id)
		_lab.what_button.pressed.emit()
		await _wait(0.3)
		await _save("%s_3_why" % id)
	await _shot("book", func() -> void: _lab.show_book())
	await _shot("book_card", func() -> void: _lab.book.open_card("magnets"))
	await _shot("learn", func() -> void:
		_lab.open("melting")
		_lab.show_learn("g4.science.states_of_matter"))
	# the School's unit page with TRY IT IN THE LAB, and the Lab inside the School
	_panel.remove_child(_lab)
	_lab.queue_free()
	var school := SchoolScreen.new()
	school.profile = _profile
	school.save_profile = func() -> void: pass
	_panel.add_child(school)
	await _shot("school_unit", func() -> void: school.show_unit("g3.science.magnets"))
	await _shot("school_lab", func() -> void: school.show_lab("magnets"))
	get_tree().quit()


## A guess: a sort half right, a choice's first.
func _guess(id: String) -> void:
	var w := _lab.predict_answer
	if w.sort:
		for i in w.picked.size():
			w.tap(i)
			if i % 3 == 0:
				w.tap(i)
	else:
		w.choose(1 if id == "circuit" else 0)


func _half(id: String) -> void:
	var v := _lab.view
	match _lab.model.kind:
		"tank", "magnet":
			for i in 4:
				v.thing_buttons[i].pressed.emit()
		"heat":
			for i in 5:
				v.warm_button.pressed.emit()
		"colours":
			v.paint_buttons[0].pressed.emit()
			v.paint_buttons[1].pressed.emit()
			v.light_buttons[0].pressed.emit()
			v.light_buttons[1].pressed.emit()
		"plants":
			for b: Button in v.pot_buttons:
				b.pressed.emit()
			_clock[0] += int(LabPlants.DAY)
			v.look_button.pressed.emit()
		"circuit":   # lit, then a gap: a wire out
			v.switch_button.pressed.emit()
			v.wire_buttons[1].pressed.emit()


func _finish(id: String) -> void:
	var v := _lab.view
	match _lab.model.kind:
		"tank", "magnet":
			for b: Button in v.thing_buttons:
				b.pressed.emit()
		"heat":
			for i in 4:
				v.warm_button.pressed.emit()
			for i in 7:
				v.cool_button.pressed.emit()
		"colours":
			for pair: Array in [[1, 2], [0, 1, 2]]:
				v.clean_button.pressed.emit()
				for i: int in pair:
					v.paint_buttons[i].pressed.emit()
			v.light_buttons[2].pressed.emit()
		"plants":
			_clock[0] += int(LabPlants.DAY)
			v.look_button.pressed.emit()
		"circuit":
			v.wire_buttons[1].pressed.emit()
			v.bulb_button.pressed.emit()


func _stage() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui := Control.new()
	ui.theme = UiKit.theme()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)
	var back := ColorRect.new()
	back.color = Color(0.36, 0.55, 0.42)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(back)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ui.add_child(center)
	_panel = PanelContainer.new()
	center.add_child(_panel)
	_lab = LabScreen.new()
	_lab.profile = _profile
	_lab.save_profile = func() -> void: pass
	_lab.now = func() -> int: return _clock[0]
	_panel.add_child(_lab)


func _shot(name: String, show: Callable) -> void:
	show.call()
	await _wait(0.3)
	await _save(name)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _save(shot: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := _out.path_join(shot + ".png")
	image.save_png(path)
	print("LAB_SHOT %s %dx%d" % [path, image.get_width(), image.get_height()])
