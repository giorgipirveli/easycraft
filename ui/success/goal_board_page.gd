class_name GoalBoardPage
extends SuccessPage
## Owner #115 (docs/design/success-skills.md §2.6, §4; the brief: "the Goal Board (a dream → a goal → steps → if-then
## plans ...; the Big track writes its own plan from parts), tied to the child's real goals in the game (the rocket, a
## universe, a build); the habit garden (one small good habit chosen; a plant grows on each day it is kept; a missed
## day never kills it: gentle, never guilt; no streak pressure)"): MY GOAL BOARD in the Life tab's Goals and habits.
## - The board: the goal (its dream's picture, how far the game sees it: the child's gold against Mission Control's
##   rocket, a flight, a universe opened, lessons mastered, stamps by myself; or the steps ticked), its steps to tick,
##   the "When ..., I will ..." plan and, on the Big track, the "If ..., then ..." obstacle plan. Reaching it is
##   celebrated once (no gold: the goal is its own reward).
## - The habit garden beside it: the plant of the habit (HabitPlant), "Did you do it today?" (YES, I DID IT or NOT
##   TODAY, thanked: honesty is the point; today's answer can be changed), the days kept in all (never in a row), the
##   plants of earlier habits.
## - MAKE MY GOAL, from pictures, never typed: the dream; a goal you can check; the steps (Little: ready-made; Middle and
##   Big: three picked in the child's order); the plan (Little: one of three ready plans; Middle and Big: the WHEN and
##   the I WILL from parts); the Big track's obstacle plan; then the plan read back and Try it for real.

const MAKE := "MAKE MY GOAL"
const NEW_GOAL := "A NEW GOAL"
const PICK_HABIT := "PICK A HABIT"
const OTHER_HABIT := "ANOTHER HABIT"
const YES := "YES, I DID IT!"
const NOT_TODAY := "NOT TODAY"
const CHANGE := "CHANGE"
const REACHED := "Goal reached! You did it, step by step."
const NO_GOAL := "No goal yet. What's your dream? A goal is one thing you can do and see."
const STEPS_PICK := "Pick 3 steps, in order: tap them one by one."
const STEPS_READY := "Your steps, one at a time:"
const PLAN_PICK := "Make your plan: pick WHEN, then I WILL."
const PLAN_READY := "Pick your plan:"
const OBSTACLE_PICK := "What could get in the way? Pick IF, then THEN."
const TRY_REAL := "Tell a grown-up your goal, and plan its first step together."
const GOLD := Color("d9772b")

var page := "board"
var draft := {}
var changing := false


func _init(p: ProfileData, save: Callable, day: int, region_id: String, track_id: String) -> void:
	super(p, save, day, region_id, track_id)
	name = "GoalBoardPage"


func _ready() -> void:
	show_board()


# --- The board and the garden ------------------------------------------------------------------------------------------

func show_board() -> void:
	page = "board"
	clear()
	header("My Goal Board", func() -> void: closed.emit())
	var body := centred_row(16)
	body.add_child(_goal_panel())
	body.add_child(_garden_panel())
	add_child(body)


func _goal_panel() -> PanelContainer:
	var panel := paper(620)
	panel.name = "Goal"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	panel.add_child(col)
	var d := data()
	if d.goal.is_empty():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		row.add_child(SchoolUi.teacher(110.0))
		row.add_child(left_words(NO_GOAL, 26, 440))
		col.add_child(row)
		var make := SchoolUi.button(MAKE, GOLD, Vector2(420, 90))
		make.add_theme_font_size_override("font_size", 30)
		make.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		make.pressed.connect(show_dreams)
		col.add_child(make)
		say(NO_GOAL)
		return panel
	var dream := SuccessGoals.dream(str(d.goal.d))
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	top.add_child(LifeIcons.new(str(dream.get("icon", "goal")), 72.0))
	var words := VBoxContainer.new()
	words.add_child(left_words(SuccessGoals.title(d), 24, 480))
	var pr := SuccessGoals.progress(d, profile)
	var line := left_words(str(pr.words), 18, 480)
	line.add_theme_color_override("font_color", SchoolUi.HINT)
	words.add_child(line)
	var bar := ProgressBar.new()
	bar.name = "GoalBar"
	bar.show_percentage = false
	bar.max_value = maxf(float(pr.need), 1.0)
	bar.value = minf(float(pr.have), bar.max_value)
	bar.custom_minimum_size = Vector2(460, 16)
	words.add_child(bar)
	top.add_child(words)
	col.add_child(top)
	var steps: Array = d.goal.get("s", [])
	for i in steps.size():
		var s := SuccessGoals.step_of(str(d.goal.d), str(steps[i]))
		var ticked := SuccessGoals.ticked(d, i)
		var b := SchoolUi.button("%d.  %s" % [i + 1, str(s.get("title", ""))], Color("2f7f6a") if ticked else Color(0.2, 0.24, 0.36),
			Vector2(580, 44))
		b.name = "Step%d" % (i + 1)
		b.add_theme_font_size_override("font_size", 19)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if ticked:
			var t := LifeIcons.new("tick", 40.0)
			t.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
			t.offset_left = -48
			t.offset_right = -8
			t.offset_top = -20
			t.offset_bottom = 20
			b.add_child(t)
		b.pressed.connect(_tick.bind(i))
		col.add_child(b)
	var plan := SuccessGoals.plan_words(d)
	if plan != "":
		col.add_child(left_words("Plan: " + plan, 19, 580))
	var obstacle := SuccessGoals.obstacle_words(d)
	if obstacle != "":
		col.add_child(left_words(obstacle, 19, 580))
	if int(d.goal.get("x", 0)) > 0:
		var done := left_words(REACHED, 24, 580)
		done.name = "GoalReached"
		done.add_theme_color_override("font_color", SchoolUi.GOLD)
		col.add_child(done)
	var again := small(NEW_GOAL, show_dreams, 240)
	again.size_flags_horizontal = Control.SIZE_SHRINK_END
	col.add_child(again)
	return panel


func _tick(i: int) -> void:
	var d := data()
	SuccessGoals.tick(d, i)
	var reached := SuccessGoals.check_reached(d, profile, today)
	save()
	show_board()
	if reached:
		_celebrate()


func _celebrate() -> void:
	say(REACHED)
	add_child(CoinShower.new())
	Audio.play(&"jingle_level")
	var label := find_child("GoalReached", true, false) as Control
	if label and is_inside_tree():
		UiMotion.pop_in(label)


func _garden_panel() -> PanelContainer:
	var panel := paper(520)
	panel.name = "Garden"
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(col)
	var title := SchoolUi.words("My habit garden", 24, 480)
	col.add_child(title)
	var d := data()
	var plant_row := centred_row(10)
	plant_row.add_child(HabitPlant.new(SuccessHabits.days_kept(d), 180.0))
	col.add_child(plant_row)
	var words := SuccessHabits.words(d, today)
	if d.habit.is_empty():
		col.add_child(SchoolUi.words(words, 22, 480))
		var pick := SchoolUi.button(PICK_HABIT, Color("2f7f6a"), Vector2(320, 70))
		pick.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		pick.pressed.connect(show_habits)
		col.add_child(pick)
	else:
		var h := SuccessHabits.habit(str(d.habit.h))
		var habit_row := centred_row(10)
		habit_row.add_child(LifeIcons.new(str(h.get("icon", "habit_plant")), 48.0))
		habit_row.add_child(SchoolUi.words(str(h.get("title", "")), 22, 400))
		col.add_child(habit_row)
		var said := SchoolUi.words(words, 22, 480)
		said.add_theme_color_override("font_color", SchoolUi.GOOD if words == SuccessHabits.GREW else SchoolUi.HINT)
		col.add_child(said)
		if not SuccessHabits.answered_on(d, today) or changing:
			var answers := centred_row(14)
			var yes := SchoolUi.button(YES, Color("2fae4e"), Vector2(250, 70))
			yes.add_theme_font_size_override("font_size", 22)
			yes.pressed.connect(_answer.bind(true))
			answers.add_child(yes)
			var no := SchoolUi.button(NOT_TODAY, Color("6b7a99"), Vector2(200, 70))
			no.add_theme_font_size_override("font_size", 22)
			no.pressed.connect(_answer.bind(false))
			answers.add_child(no)
			col.add_child(answers)
		else:
			var later := centred_row(14)
			later.add_child(small(CHANGE, func() -> void:
				changing = true
				show_board(), 160))
			later.add_child(small(OTHER_HABIT, show_habits, 230))
			col.add_child(later)
		var n := SuccessHabits.days_kept(d)
		var kept := SchoolUi.words("Kept on %d day%s in all." % [n, "" if n == 1 else "s"], 18, 480)
		kept.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
		col.add_child(kept)
	if not d.garden.is_empty():
		var row := centred_row(6)
		for plant in d.garden.slice(maxi(d.garden.size() - 6, 0)):
			row.add_child(HabitPlant.new(int(plant.n), 56.0))
		col.add_child(row)
	say(words)
	return panel


func _answer(yes: bool) -> void:
	SuccessHabits.answer(data(), today, yes)
	changing = false
	save()
	show_board()
	if yes:
		Audio.play(&"jingle_goal")


# --- The habits --------------------------------------------------------------------------------------------------------

func show_habits() -> void:
	page = "habits"
	clear()
	header("Pick one small good habit", show_board)
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for h in SuccessHabits.list():
		var b := LifeCards.picture_button(str(h.title), str(h.icon), Color("2f7f6a"), Vector2(212, 190), 20)
		b.name = "Habit_" + str(h.id)
		b.pressed.connect(_pick_habit.bind(str(h.id)))
		grid.add_child(b)
	add_child(grid)
	var note := SchoolUi.words(SuccessHabits.TAKES_TIME, 20, 1000)
	note.add_theme_color_override("font_color", SchoolUi.HINT)
	add_child(note)
	say("Pick one small good habit. " + SuccessHabits.TAKES_TIME)


func _pick_habit(id: String) -> void:
	SuccessHabits.choose(data(), id, today)
	save()
	show_board()


# --- MAKE MY GOAL ------------------------------------------------------------------------------------------------------

func show_dreams() -> void:
	page = "dreams"
	draft = {}
	clear()
	header("What's your dream?", show_board)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for dream in SuccessGoals.dreams():
		var b := LifeCards.picture_button(str(dream.title), str(dream.icon), GOLD.darkened(0.25), Vector2(270, 200), 22)
		b.name = "Dream_" + str(dream.id)
		b.pressed.connect(show_goals.bind(str(dream.id)))
		grid.add_child(b)
	add_child(grid)
	say("What's your dream? Pick a picture.")


func show_goals(dream_id: String) -> void:
	page = "goals"
	draft = {"d": dream_id}
	clear()
	var dream := SuccessGoals.dream(dream_id)
	header(str(dream.title), show_dreams)
	var tip := SchoolUi.words("Now pick a goal you can check: what, how much, by when.", 26, 1000)
	tip.add_theme_color_override("font_color", SchoolUi.HINT)
	add_child(tip)
	var row := centred_row(20)
	for g: Dictionary in dream.goals:
		var b := LifeCards.picture_button(str(g.title), str(dream.icon), GOLD.darkened(0.25), Vector2(440, 260), 26)
		b.name = "Goal_" + str(g.id)
		b.pressed.connect(show_steps.bind(str(g.id)))
		row.add_child(b)
	add_child(row)
	say("Now pick a goal you can check.")


func show_steps(goal_id: String) -> void:
	page = "steps"
	draft.g = goal_id
	draft.s = []
	_steps_page()


func _steps_page() -> void:
	clear()
	var dream := SuccessGoals.dream(str(draft.d))
	header("The steps", show_goals.bind(str(draft.d)))
	var list: Array = dream.get("steps", [])
	if track == "little":
		draft.s = list.slice(0, 3).map(func(s: Dictionary) -> String: return str(s.id))
		add_child(SchoolUi.words(STEPS_READY, 28, 1000))
		for i in 3:
			var row := centred_row(14)
			row.add_child(LifeIcons.new(str(list[i].get("icon", "goal_plan")), 64.0))
			row.add_child(left_words("%d.  %s" % [i + 1, str(list[i].title)], 28, 700))
			add_child(row)
		say(STEPS_READY + " " + ". ".join(PackedStringArray((draft.s as Array).map(func(id: String) -> String:
			return str(SuccessGoals.step_of(str(draft.d), id).title)))))
	else:
		add_child(SchoolUi.words(STEPS_PICK, 26, 1000))
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 10)
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		for s: Dictionary in list:
			var b := SchoolUi.button(str(s.title), Color(0.2, 0.3, 0.5), Vector2(360, 84))
			b.name = "StepPick_" + str(s.id)
			b.add_theme_font_size_override("font_size", 20)
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.disabled = (draft.s as Array).has(str(s.id)) or (draft.s as Array).size() >= 3
			b.pressed.connect(func() -> void:
				if (draft.s as Array).size() < 3 and not (draft.s as Array).has(str(s.id)):
					(draft.s as Array).append(str(s.id))
					_steps_page())
			grid.add_child(b)
		add_child(grid)
		var chosen := centred_row(18)
		for i in (draft.s as Array).size():
			chosen.add_child(SchoolUi.words("%d. %s" % [i + 1, str(SuccessGoals.step_of(str(draft.d), str(draft.s[i])).title)], 18, 340))
		add_child(chosen)
		say(STEPS_PICK)
	var foot := centred_row(20)
	if track != "little":
		foot.add_child(small("AGAIN", func() -> void:
			draft.s = []
			_steps_page(), 180))
	var next := SchoolUi.button("NEXT", UiKit.GREEN, Vector2(260, 70))
	next.disabled = (draft.s as Array).size() < 3
	next.pressed.connect(show_plan)
	foot.add_child(next)
	add_child(foot)


func show_plan() -> void:
	page = "plan"
	clear()
	header("My plan", _steps_page)
	if track == "little":
		add_child(SchoolUi.words(PLAN_READY, 28, 1000))
		for p in SuccessGoals.ready_plans():
			var b := SchoolUi.button(SuccessGoals.plan_of(str(p.w), str(p.a)), Color(0.2, 0.3, 0.5), Vector2(900, 84))
			b.add_theme_font_size_override("font_size", 24)
			b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			b.pressed.connect(func() -> void:
				draft.w = str(p.w)
				draft.a = str(p.a)
				show_done())
			add_child(b)
		say(PLAN_READY)
		return
	add_child(SchoolUi.words(PLAN_PICK, 26, 1000))
	_parts_rows("WHEN...", "cues", "w", "I WILL...", "actions", "a")
	var preview := SchoolUi.words(SuccessGoals.plan_of(str(draft.get("w", "")), str(draft.get("a", ""))), 24, 1000)
	preview.name = "Preview"
	preview.add_theme_color_override("font_color", SchoolUi.GOLD)
	add_child(preview)
	var next := SchoolUi.button("NEXT", UiKit.GREEN, Vector2(260, 70))
	next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next.disabled = not (draft.has("w") and draft.has("a"))
	next.pressed.connect(show_obstacle if track == "big" else show_done)
	add_child(next)
	say(PLAN_PICK)


func show_obstacle() -> void:
	page = "obstacle"
	clear()
	header("If something gets in the way", show_plan)
	add_child(SchoolUi.words(OBSTACLE_PICK, 26, 1000))
	_parts_rows("IF...", "obstacles", "o", "THEN...", "responses", "r")
	var o := SuccessGoals.part("obstacles", str(draft.get("o", "")))
	var r := SuccessGoals.part("responses", str(draft.get("r", "")))
	var preview := SchoolUi.words(SuccessGoals.PLAN % [str(o.title), str(r.title)] if not o.is_empty() and not r.is_empty()
		else "", 24, 1000)
	preview.add_theme_color_override("font_color", SchoolUi.GOLD)
	add_child(preview)
	var next := SchoolUi.button("NEXT", UiKit.GREEN, Vector2(260, 70))
	next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next.disabled = not (draft.has("o") and draft.has("r"))
	next.pressed.connect(show_done)
	add_child(next)
	say(OBSTACLE_PICK)


## Two rows of parts from the lists (the WHEN and the I WILL, or the IF and the THEN): the picked one stays pressed.
func _parts_rows(first: String, first_list: String, first_key: String, second: String, second_list: String,
		second_key: String) -> void:
	for spec: Array in [[first, first_list, first_key], [second, second_list, second_key]]:
		var label := left_words(str(spec[0]), 22, 1100)
		label.add_theme_color_override("font_color", SchoolUi.GOLD)
		add_child(label)
		var row := centred_row(10)
		var parts := SuccessGoals.parts(str(spec[1]))
		var wide := floorf(minf(190.0, (SchoolUi.FRAME.x - 10.0 * (parts.size() - 1)) / maxf(parts.size(), 1.0)))
		for part in parts:
			var b := SchoolUi.button(str(part.title), Color(0.2, 0.3, 0.5), Vector2(wide, 76))
			b.add_theme_font_size_override("font_size", 17)
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			b.toggle_mode = true
			b.set_pressed_no_signal(str(draft.get(str(spec[2]), "")) == str(part.id))
			var key := str(spec[2])
			var id := str(part.id)
			b.pressed.connect(func() -> void:
				draft[key] = id
				if page == "plan":
					show_plan()
				else:
					show_obstacle())
			row.add_child(b)
		add_child(row)


func show_done() -> void:
	page = "done"
	var d := data()
	var ok := SuccessGoals.set_goal(d, profile, str(draft.get("d", "")), str(draft.get("g", "")), draft.get("s", []),
		str(draft.get("w", "")), str(draft.get("a", "")), today)
	if ok and track == "big":
		SuccessGoals.set_obstacle(d, str(draft.get("o", "")), str(draft.get("r", "")))
	if ok:
		save()
	clear()
	header("Your goal is on the board!", show_board)
	var row := centred_row(24)
	row.add_child(SchoolUi.teacher(130.0))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.add_child(left_words(SuccessGoals.title(d), 30, 760))
	col.add_child(left_words(SuccessGoals.plan_words(d), 26, 760))
	if SuccessGoals.obstacle_words(d) != "":
		col.add_child(left_words(SuccessGoals.obstacle_words(d), 26, 760))
	row.add_child(col)
	add_child(row)
	var real := LifeCards.try_real(TRY_REAL, 760.0)
	add_child(real)
	var done := SchoolUi.button("DONE", UiKit.GREEN, Vector2(260, 76))
	done.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done.pressed.connect(show_board)
	add_child(done)
	Audio.play(&"jingle_goal")
	say("%s. %s %s" % [SuccessGoals.title(d), SuccessGoals.plan_words(d), SuccessGoals.obstacle_words(d)])
