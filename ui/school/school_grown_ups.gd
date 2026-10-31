class_name SchoolGrownUpsPage
extends VBoxContainer
## Owner #68 (spec §22.3): the School's page for grown-ups, behind the parent gate: the child's grade and whether
## only a grown-up may change it, then every unit of a subject with its stars, rounds, answers right the first time and
## the day last practised. Saved at once in the profile; nothing leaves the device. Owner #122 (G0): the page keeps the
## programme's words (grades, subjects, standards) and shows each unit's play level (P0: the School's lesson and
## questions, the ones a child can do without reading played as games; P1: its own deep game). Owner #134: its tooltip
## says how much of it plays without reading (PlayReadless.debt: the reading debt).

signal closed
## Owner #112: LIFE FOR GROWN-UPS (Life's own page, already past the gate).
signal life_requested

## A unit's title column; the lead (2026-10-17): titles longer than it are fitted (`_fit_title`), never cut.
const TITLE_WIDTH := 296.0
const ABOUT := "Each unit: its play level (P0: the School's own; P1: its own game), stars, rounds, answers right the first time, day last played. Following the Common Core, the NGSS, England's National Curriculum and the world's leading schools. Kept on this device and in the backup."

var profile: ProfileData
var save_profile: Callable
var subject := "maths"
var grade_buttons := {}
var lock_buttons := {}
var rows: Array[Control] = []
var _list: GridContainer
var _tabs := {}
## Research §5.4: what the shown subject's hard-history units name, for grown-ups (hidden when there are none).
var hard_note: Label


func _init(p: ProfileData, save: Callable) -> void:
	profile = p
	save_profile = save
	name = "SchoolGrownUpsPage"
	add_theme_constant_override("separation", 8)
	custom_minimum_size.x = SchoolUi.FRAME.x


func _ready() -> void:
	var title := ReadAloud.with_speaker(UiKit.title("School: for grown-ups", 34), self)
	add_child(title)
	var grades := HBoxContainer.new()
	grades.alignment = BoxContainer.ALIGNMENT_CENTER
	grades.add_theme_constant_override("separation", 10)
	grades.add_child(_row_label("Grade", 120))
	for g in SchoolData.GRADES:
		var b := SchoolUi.button(str(g), Color(), Vector2(120, 52))
		b.toggle_mode = true
		b.pressed.connect(set_grade.bind(g))
		grade_buttons[g] = b
		grades.add_child(b)
	add_child(grades)
	var lock := HBoxContainer.new()
	lock.alignment = BoxContainer.ALIGNMENT_CENTER
	lock.add_theme_constant_override("separation", 10)
	lock.add_child(_row_label("Only a grown-up changes the grade", 460))
	for on: bool in [true, false]:
		var b := SchoolUi.button("ON" if on else "OFF", Color(), Vector2(120, 52))
		b.toggle_mode = true
		b.pressed.connect(set_locked.bind(on))
		lock_buttons[on] = b
		lock.add_child(b)
	add_child(lock)
	# Every subject a school teaches (owner #70), in two rows with DONE at the end; a grade shows its own.
	var tabs := GridContainer.new()
	tabs.columns = 7
	tabs.add_theme_constant_override("h_separation", 10)
	tabs.add_theme_constant_override("v_separation", 6)
	tabs.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for s: String in Curriculum.SUBJECTS:
		var b := SchoolUi.button(SchoolUi.SUBJECT_WORDS[s], SchoolUi.SUBJECT_COLORS[s], Vector2(156, 40))
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 15)
		b.pressed.connect(show_subject.bind(s))
		_tabs[s] = b
		tabs.add_child(b)
	var life := SchoolUi.button("LIFE", LifeCards.COLOUR, Vector2(156, 40))   # owner #112
	life.name = "LifeForGrownUps"
	life.add_theme_font_size_override("font_size", 15)
	life.pressed.connect(func() -> void: life_requested.emit())
	tabs.add_child(life)
	var done := SchoolUi.button("DONE", SchoolUi.TEAL, Vector2(156, 40))
	done.pressed.connect(func() -> void: closed.emit())
	tabs.add_child(done)
	add_child(tabs)
	_list = GridContainer.new()
	_list.columns = 2
	_list.add_theme_constant_override("h_separation", 10)
	_list.add_theme_constant_override("v_separation", 0)   # a two-line title fits grade 5 English's 18 units
	_list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_child(_list)
	hard_note = SchoolUi.words("", 16, SchoolUi.FRAME.x - 40)   # research §5.4: hard history, listed for grown-ups
	hard_note.name = "HardNote"
	hard_note.add_theme_color_override("font_color", Color("ffb45a"))
	add_child(hard_note)
	var about := SchoolUi.words(ABOUT, 18, SchoolUi.FRAME.x - 40)
	about.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	add_child(about)
	_refresh_switches()
	show_subject(subject)


func set_grade(g: int) -> void:
	if not SchoolData.GRADES.has(g):
		return
	profile.school.grade = g
	save_profile.call()
	_refresh_switches()
	show_subject(subject)


func set_locked(on: bool) -> void:
	profile.school.grade_locked = on
	save_profile.call()
	_refresh_switches()


func show_subject(s: String) -> void:
	subject = s
	var g0 := profile.school.grade if profile.school.grade > 0 else SchoolData.GRADES[0]
	var has: Array[String] = []
	for sub: Dictionary in Curriculum.subjects(g0):
		has.append(str(sub.id))
	for key: String in _tabs:
		(_tabs[key] as Button).set_pressed_no_signal(key == s)
		(_tabs[key] as Button).visible = has.is_empty() or has.has(key)
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	rows.clear()
	var g := profile.school.grade if profile.school.grade > 0 else SchoolData.GRADES[0]
	var today := SchoolClock.today()
	for u: Dictionary in Curriculum.units(g, s):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		var p := profile.school.progress(str(u.id))
		var title := Label.new()
		title.text = "%d. %s" % [rows.size() + 1, u.title]
		title.custom_minimum_size = Vector2(TITLE_WIDTH, 0)
		title.add_theme_font_size_override("font_size", 16)
		row.add_child(title)
		var level := Label.new()   # owner #122 (G0): the unit's play level
		level.name = "PlayLevel"
		level.text = PlayMechanics.level(Curriculum.content(str(u.id))) if Curriculum.has_content(str(u.id)) else ""
		if level.text != "":   # owner #134: the reading debt, for the grown-up who points at it
			var d := PlayReadless.debt(Curriculum.content(str(u.id)))
			level.tooltip_text = "%d of %d questions play without reading" % [int(d.playable),
				int(d.playable) + int(d.reading)]
			level.mouse_filter = Control.MOUSE_FILTER_PASS
		level.custom_minimum_size.x = 20
		level.add_theme_font_size_override("font_size", 13)
		level.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
		level.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(level)
		var stars := SchoolUi.stars(MasteryRules.stars(p), 16.0)
		stars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(stars)
		var stats := Label.new()
		stats.text = _stats(u, p, today)
		stats.custom_minimum_size = Vector2(186, 0)
		stats.clip_text = true
		stats.add_theme_font_size_override("font_size", 16)
		row.add_child(stats)
		rows.append(row)
	var hard: Array[String] = []
	for i in Curriculum.units(g, s).size():
		var h: Variant = Curriculum.units(g, s)[i].get("hard")
		if h is String and str(h) != "":
			hard.append("%d. %s" % [i + 1, h])
	if hard_note != null:
		hard_note.visible = not hard.is_empty()
		hard_note.text = "Hard history, told with respect and never shown: %s." % "; ".join(hard) if not hard.is_empty() else ""
	var half := ceili(rows.size() / 2.0)   # down the left column first, then the right
	for i in half:
		_list.add_child(rows[i])
		if i + half < rows.size():
			_list.add_child(rows[i + half])
	for row in rows:
		_fit_title(row.get_child(0) as Label)


## The lead (2026-10-17): a title too long for its column shows whole: one line a size or three smaller (down to 13),
## or two lines at 14 when even that is too long. Measured in the tree, with the page's own font.
static func _fit_title(l: Label) -> void:
	var font := l.get_theme_font("font")
	for fs in range(16, 12, -1):
		if font.get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x <= TITLE_WIDTH:
			l.add_theme_font_size_override("font_size", fs)
			return
	l.add_theme_font_size_override("font_size", 14)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


## "1 round · 83% · 28 Sep" (the share right the first time, the day last practised), "not started", or "coming soon".
static func _stats(u: Dictionary, p: Dictionary, _today: int) -> String:
	if not Curriculum.has_content(str(u.id)):
		return "coming soon"
	var r := int(p.r)
	if r == 0:
		return "lesson read" if bool(p.l) else "not started"
	var pct := roundi(100.0 * int(p.f) / maxi(int(p.a), 1))
	return "%d round%s · %d%% · %s" % [r, Lang.plural_s(r), pct, SchoolClock.short_date(int(p.t))]


func _refresh_switches() -> void:
	for g: int in grade_buttons:
		(grade_buttons[g] as Button).set_pressed_no_signal(g == profile.school.grade)
	for on: bool in lock_buttons:
		(lock_buttons[on] as Button).set_pressed_no_signal(on == profile.school.grade_locked)


func _row_label(text: String, width: float) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(width, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 22)
	return l
