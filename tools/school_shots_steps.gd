extends Node
## The steps of tools/school_shots.gd (a Node, so it may use the autoloads and the School's classes).

var _out := ""
var _unit := "g4.maths.big_numbers"
var _screen: SchoolScreen
var _profile := ProfileData.new()


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--unit="):
			_unit = a.trim_prefix("--unit=")
	get_window().size = Vector2i(1600, 720) if args.has("--wide") else Vector2i(1280, 720)
	_out = ProjectSettings.globalize_path("user://school_shots")
	DirAccess.make_dir_recursive_absolute(_out)
	_stage()
	var u := Curriculum.unit(_unit)
	_profile.school.grade = int(u.get("grade", 4))
	_profile.school.set_progress(_unit, MasteryRules.after_round(_profile.school.progress(_unit), 5, 6,
		SchoolClock.today() - 2).progress)
	await _shot("welcome", func() -> void: _screen.show_welcome())
	for s: String in Curriculum.SUBJECTS:
		await _shot("map_" + s, func() -> void: _screen.show_map(s))
	await _shot("unit", func() -> void: _screen.show_unit(_unit))
	var c := Curriculum.content(_unit)
	for i in (c.get("lesson", []) as Array).size():
		await _shot("lesson_%d" % (i + 1), func() -> void: _screen.show_lesson(_unit, i))
	_screen.show_round(_unit)
	for i in _screen.round.size():
		await _wait(0.3)
		await _save("round_%d_%s" % [i + 1, _screen.exercise_panel.ex.type])
		_screen.exercise_panel.check_button.visible = false
		_force_answer(_screen.exercise_panel)
		await _wait(0.2)
		await _save("round_%d_answered" % (i + 1))
		_screen.exercise_panel.next_button.pressed.emit()
	await _wait(0.5)
	await _save("round_end")
	if args.has("--exercises"):
		for ex: Dictionary in c.get("exercises", []):
			var panel := ExercisePanel.new(ex, 0)
			_screen.call("_clear", SchoolScreen.ROUND)
			_screen.add_child(panel)
			await _wait(0.2)
			await _save("ex_%s" % str(ex.id).get_slice("#", 1))
			_force_answer(panel)
			await _wait(0.2)
			await _save("ex_%s_shown" % str(ex.id).get_slice("#", 1))
	await _shot("grades", func() -> void: _screen.show_grades())
	await _shot("gate", func() -> void: _screen.show_grown_ups())
	await _shot("grown_ups", func() -> void: _screen.show_grown_ups_page())
	get_tree().quit()


## A miss after one already (tries = 1), so the worked answer shows: a picture of the hint and the answer.
func _force_answer(p: ExercisePanel) -> void:
	var w := p.answer_widget
	var ex := p.ex
	p.tries = 1
	match str(ex.type):
		"choice":
			(w as ChoiceAnswer).choose((int(ex.answer) + 1) % (ex.choices as Array).size())
		"truefalse":
			(w as ChoiceAnswer).choose(1 if ex.answer else 0)
		"number":
			for ch in str(ExerciseCheck.answer_of(ex)) + "1":
				(w as NumberAnswerPad).press(ch)
			p.check()
		"order":
			for i in (w as OrderAnswer).items.size():
				(w as OrderAnswer).tap(i)
			p.check()
		"build":
			(w as BuildBoard).paint(Vector2i(0, 0), true)
			p.check()
		"point":   # grade 5: a wrong point
			var a: Vector2i = ExerciseCheck.answer_of(ex)
			(w as GridAnswer).tap(Vector2i.ZERO if a != Vector2i.ZERO else GridCheck.step(ex.grid))
			p.check()
		"sort":    # everything in the first group (a sort always uses two groups or more)
			for i in (w as SortAnswer).items.size():
				(w as SortAnswer).tap(i)
			p.check()
		"match":   # each thing with the partner beside it (never the answer)
			for i in (w as MatchAnswer).items.size():
				(w as MatchAnswer).tap_left(i)
				(w as MatchAnswer).tap_right(i)
			p.check()
		"robot":   # a turn on the spot: never at the flag
			(w as RobotAnswer).add("L")
			p.check()
		"rhythm":  # claps on the first two boxes only
			(w as RhythmAnswer).tap(0)
			if str(ExerciseCheck.answer_of(ex)).begins_with("x"):
				(w as RhythmAnswer).tap(1)
			p.check()
		"mix":     # one drop of black: no target is black alone
			(w as MixAnswer).add("black")
			p.check()
		"label":   # each label on the pin of its own number (never the answer)
			for i in (w as LabelAnswer).texts.size():
				(w as LabelAnswer).tap_label(i)
				(w as LabelAnswer).tap_pin(i)
			p.check()


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
	var panel := PanelContainer.new()
	center.add_child(panel)
	_screen = SchoolScreen.new()
	_screen.profile = _profile
	_screen.save_profile = func() -> void: pass
	_screen.next_seed = func() -> int: return 11
	panel.add_child(_screen)


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
	print("SCHOOL_SHOT %s %dx%d" % [path, image.get_width(), image.get_height()])
