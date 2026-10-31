class_name DailyPage
extends VBoxContainer
## Owner #85 (Wordle's lesson; the world game plan §2b; brief 2026-09-30 item 1): TODAY'S MISSION, in the School's own
## panel (SchoolScreen's page DAILY; every page fits SchoolUi.FRAME). Pages:
## - INTRO: the date, "5 questions from your grade's subjects. The same mission for every grade 4 explorer today!",
##   today's subjects, the last 7 days (mission days and rest days, DailyWeek), the mission days so far (never down),
##   START (or GO ON after a STOP: the same mission all day).
## - ROUND: the 5 exercises (DailyMission.plan; ExercisePanel), each answer kept at once (DailyData.answer): a star for
##   each right the first time. No answer gold here: the day's own line pays at the end (EarnRules.daily_gold).
## - DONE: the result card (DailyCard: the date, the grade, the stars as pictures, "Today's Mission: 4 of 5!", the invite
##   code and link, never an answer), the gold the first time today, SHARE (a browser's or Android's share sheet, where
##   a grown-up's switch allows), COPY, SAVE PICTURE, and the grown-ups' line. A finished day opens here again.
## Finishing tells the server this child learned today (SocialSender: friendship days, study buddies, the crew's week).
## Hooks (tests set them): `profile`, `save_profile`, `today` (the UTC day), `grade`, `service`, `copy_text`,
## `can_share`, `share`, `save_png`, `render`.

signal closed

const INTRO := &"intro"
const ROUND := &"round"
const DONE := &"done"
const CARD_PX := Vector2i(640, 440)

var profile: ProfileData
var save_profile := Callable()
var today := Callable()
var grade := 0
var service: OnlineService
var copy_text := func(t: String) -> void: DisplayServer.clipboard_set(t)
var can_share := Callable()
var share := func(text: String, url: String, png: PackedByteArray) -> String: return CardPicture.share(text, url, png)
var save_png := func(png: PackedByteArray) -> Dictionary: return CardPicture.save_png(png)
## (card: Control) -> Image or null: the card as a picture (CardPicture.render; tests pretend).
var render := Callable()

var page: StringName = &""
var day := 0
var plan: Array[Dictionary] = []
var index := 0
var gold_now := 0
var exercise_panel: ExercisePanel
var card: DailyCard
var note: Label


func _init() -> void:
	name = "DailyMission"
	add_theme_constant_override("separation", 12)
	custom_minimum_size.x = SchoolUi.FRAME.x


func _ready() -> void:
	if profile == null:
		profile = Profile.data
	if not save_profile.is_valid():
		save_profile = Profile.save
	if not today.is_valid():
		today = DailyMission.today
	if not can_share.is_valid():
		can_share = func() -> bool: return CardPicture.can_share(profile)
	if not render.is_valid():
		render = func(c: Control) -> Image: return await CardPicture.render(self, c, CARD_PX)
	if grade <= 0:
		grade = profile.school.grade if SchoolData.GRADES.has(profile.school.grade) else SchoolData.GRADES[0]
	day = int(today.call())
	plan = DailyMission.plan(day, grade)
	if profile.daily.is_done(day):
		show_done()
	else:
		show_intro()


func code() -> String:
	if profile.invite.code != "":
		return profile.invite.code
	return str(service.invite_state.get("code", "")) if service != null else ""


# --- INTRO -------------------------------------------------------------------------------------------------------

func show_intro() -> void:
	_clear(INTRO)
	add_child(_header("Today's Mission", DailyMission.date_words(day)))
	var body := HBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 36)
	body.add_child(SchoolUi.teacher(170.0))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.custom_minimum_size.x = 760
	if plan.is_empty():
		col.add_child(SchoolUi.words("Professor Hoot is still writing your grade's mission.", 30, 760))
		body.add_child(col)
		add_child(body)
		return
	var intro := SchoolUi.words(DailyMission.intro_words(grade), 30, 760)
	intro.name = "Intro"
	col.add_child(intro)
	col.add_child(_subjects())
	var done := profile.daily.stars_of(day).length()
	if profile.daily.total > 0:
		col.add_child(_week_row())
	var start := SchoolUi.button("START" if done == 0 else "GO ON: %d OF %d DONE" % [done, DailyMission.SIZE], UiKit.GREEN,
		Vector2(420, 96))
	start.name = "Start"
	start.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	start.pressed.connect(show_round)
	col.add_child(start)
	body.add_child(col)
	add_child(body)
	ReadAloud.auto(DailyMission.intro_words(grade))


## Today's subjects as coloured tags (the questions themselves stay a surprise).
func _subjects() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Subjects"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	var seen: Array[String] = []
	for ex in plan:
		var s := str(ex.get("daily_subject", ""))
		if seen.has(s):
			continue
		seen.append(s)
		var tag := PanelContainer.new()
		tag.add_theme_stylebox_override("panel", UiKit.box(SchoolUi.SUBJECT_COLORS.get(s, UiKit.BLUE), 12, 8))
		var l := Label.new()
		l.text = str(SchoolUi.SUBJECT_WORDS.get(s, s.to_upper()))
		l.add_theme_font_size_override("font_size", 20)
		tag.add_child(l)
		row.add_child(tag)
	return row


## The last 7 days (a star: a mission day, a moon: a rest day), the mission days so far and the calm words.
func _week_row(width: float = 760.0) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.name = "Week"
	v.add_theme_constant_override("separation", 4)
	var week := DailyWeek.new(profile.daily.week(day), day)
	week.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(week)
	var days := SchoolUi.words("%s so far. %s" % [DailyMission.days_words(profile.daily.total), DailyMission.REST_LINE],
		20, width)
	days.name = "Days"
	days.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	v.add_child(days)
	return v


# --- ROUND -------------------------------------------------------------------------------------------------------

func show_round() -> void:
	index = profile.daily.stars_of(day).length()
	if index >= plan.size():
		_finish()
		return
	_show_exercise()


func _show_exercise() -> void:
	_clear(ROUND)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 20)
	var stop := SchoolUi.button("STOP", UiKit.BLUE, Vector2(160, 60))
	stop.name = "Stop"
	stop.pressed.connect(show_intro)   # the answers so far are kept: GO ON comes back to the next one
	bar.add_child(stop)
	var title := Label.new()
	title.text = "Today's Mission"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 28)
	bar.add_child(title)
	var s := str(plan[index].get("daily_subject", ""))
	var tag := Label.new()
	tag.name = "Subject"
	tag.text = str(SchoolUi.SUBJECT_WORDS.get(s, s.to_upper()))
	tag.add_theme_font_size_override("font_size", 24)
	tag.add_theme_color_override("font_color", SchoolUi.SUBJECT_COLORS.get(s, UiKit.BLUE).lightened(0.35))
	bar.add_child(tag)
	var progress := Label.new()
	progress.text = "%d of %d" % [index + 1, plan.size()]
	progress.add_theme_font_size_override("font_size", 28)
	bar.add_child(progress)
	add_child(bar)
	exercise_panel = ExercisePanel.new(plan[index], index)
	exercise_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	exercise_panel.answered.connect(_on_answered)
	add_child(exercise_panel)


func _on_answered(first_try: bool) -> void:
	if page != ROUND:
		return
	profile.daily.answer(day, grade, first_try)
	save_profile.call()
	index += 1
	if index < plan.size():
		_show_exercise()
	else:
		_finish()


func _finish() -> void:
	gold_now = EarnRules.daily_gold(profile, day)
	SocialSender.learned("", profile)   # learning today: friends' days together, study buddies, the crew's week
	save_profile.call()
	show_done()
	if gold_now > 0:
		add_child(CoinShower.new())
		Audio.play(&"jingle_badge")
	else:
		Audio.play(&"jingle_goal")


# --- DONE --------------------------------------------------------------------------------------------------------

func show_done() -> void:
	_clear(DONE)
	var stars := profile.daily.stars_of(day)
	var n := DailyMission.stars_in(stars)
	add_child(_header("Today's Mission", DailyMission.date_words(day)))
	var body := HBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 30)
	card = DailyCard.new(day, profile.daily.grade_of(day) if profile.daily.grade_of(day) > 0 else grade, stars, code())
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	body.add_child(card)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.custom_minimum_size.x = 560
	var score := SchoolUi.words(DailyMission.score_words(n), 36, 560)
	score.name = "Score"
	col.add_child(score)
	col.add_child(SchoolUi.words(DailyMission.praise(n), 24, 560))
	if gold_now > 0:
		var gold := SchoolUi.words(EarnRules.daily_words(gold_now), 26, 560)
		gold.name = "DailyGold"
		gold.add_theme_color_override("font_color", SchoolUi.GOLD)
		col.add_child(gold)
	col.add_child(_week_row(560.0))
	var buttons: Array[Control] = []
	if can_share.call():
		var sh := SchoolUi.button("SHARE", UiKit.GREEN, Vector2(160, 64))
		sh.name = "Share"
		sh.pressed.connect(_share)
		buttons.append(sh)
	var copy := SchoolUi.button("COPY", UiKit.BLUE, Vector2(150, 64))
	copy.name = "Copy"
	copy.pressed.connect(_copy)
	buttons.append(copy)
	var keep := SchoolUi.button(CardPicture.save_label(), OnlineUi.PURPLE, Vector2(230, 64))
	keep.name = "SavePicture"
	keep.add_theme_font_size_override("font_size", 24)
	keep.pressed.connect(_save_picture)
	buttons.append(keep)
	col.add_child(OnlineUi.row(buttons, 12))
	note = SchoolUi.words("", 20, 560)
	note.name = "Note"
	note.add_theme_color_override("font_color", SchoolUi.GOLD)
	note.visible = false
	col.add_child(note)
	var grown := SchoolUi.words(DailyMission.GROWN_UPS_LINE, 16, 560)
	grown.name = "GrownUpLine"
	grown.add_theme_color_override("font_color", Color(1, 1, 1, 0.65))
	col.add_child(grown)
	body.add_child(col)
	add_child(body)
	var more := SchoolUi.words(DailyMission.DONE_LINE, 20, 1000)
	more.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	add_child(more)
	ReadAloud.auto(DailyMission.score_words(n))
	if code() == "" and service != null and service.status == OnlineService.ONLINE:
		_fetch_code()


## The card carries the invite code: read it once from the server when this device doesn't know it yet.
func _fetch_code() -> void:
	var r := await service.invite_info()
	if is_inside_tree() and page == DONE and r.get("text", "") == "" and code() != "":
		show_done()


func share_text() -> String:
	return DailyMission.share_text(day, profile.daily.grade_of(day) if profile.daily.grade_of(day) > 0 else grade,
		profile.daily.stars_of(day), code())


func _say(text: String) -> void:
	if note and text != "":
		note.text = text
		note.visible = true


func _copy() -> void:
	copy_text.call(share_text())
	_say("Copied! A grown-up can paste it in a message.")
	Audio.play(&"ui_click")


func _picture() -> PackedByteArray:
	var copy := DailyCard.new(day, card.grade, card.stars, card.code)
	var img: Image = await render.call(copy)
	return CardPicture.png_of(img)


func _share() -> void:
	var png: PackedByteArray = await _picture()
	if not is_inside_tree():
		return
	_say(str(share.call(share_text(), DailyMission.link(code()), png)))


func _save_picture() -> void:
	var png: PackedByteArray = await _picture()
	if not is_inside_tree():
		return
	if png.is_empty():
		_say(CardPicture.FAILED)
		return
	var r: Dictionary = save_png.call(png)
	_say(str(r.get("text", "")))


# --- Pieces ------------------------------------------------------------------------------------------------------

## BACK (to the School's map), the title with its speaker, the date on the right.
func _header(title: String, date: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var back := SchoolUi.button("BACK", UiKit.BLUE, Vector2(150, 64))
	back.name = "Back"
	back.pressed.connect(func() -> void: closed.emit())
	row.add_child(back)
	var label := SchoolUi.fit_title(title, 560.0)
	var titled := ReadAloud.with_speaker(label, self)
	titled.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(titled)
	var when := Label.new()
	when.name = "Date"
	when.text = date
	when.add_theme_font_size_override("font_size", 24)
	when.add_theme_color_override("font_color", SchoolUi.GOLD)
	when.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(when)
	return row


## Empties the page at once (tests look at the new one in the same frame); a coin shower keeps raining.
func _clear(next: StringName) -> void:
	page = next
	note = null
	if next != ROUND:
		exercise_panel = null
	for c in get_children():
		if c is CoinShower:
			continue
		remove_child(c)
		c.queue_free()
