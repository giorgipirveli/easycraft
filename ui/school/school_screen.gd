class_name SchoolScreen
extends VBoxContainer
## Owner #68 (spec §22): the School, opened by the main menu's DISCOVER (owner #122: "we are not school, we are something
## more"; shown inside the menu's panel; every page fits SchoolUi.FRAME). Owner #122 (G0, spec §22.0), re-scoped by
## owner #133, #134 (docs/design/future-lessons.md §6): a unit with enough to play without reading (PlayHost.plays) is
## played, never read then quizzed; every other unit stays in the School as it was (LESSON, then PRACTICE), its play
## level P0 and its reading debt counted (PlayReadless), until a deep game replaces it. Pages:
## - WELCOME (the first visit: Professor Hoot and "Which grade are you in?") and GRADES (change it; not when a grown-up
##   fixed it);
## - MAP: the grade's units of a subject, each with its stars, and its game's picture (PlayIcon) when it plays;
## - UNIT: its goals; a unit that plays: the games it plays, PLAY (PLAY: REVIEW when one would help) and THE BOOK as a
##   small choice; any other: LESSON and PRACTICE (REVIEW), as before G0; or "Coming soon";
## - PLAY (owner #122): the unit in the play arena (PlayHost: hook, try, see why, play, the world task); its end is
##   recorded as a round's was (MasteryRules, EarnRules); STOP FOR NOW records nothing;
## - LESSON is the Book: the unit's cards as they are, read aloud, ending in LET'S PLAY! for a unit that plays (on
##   request, never the path), LET'S PRACTISE! for one that doesn't;
## - ROUND: the round of 6 exercises on a panel (RoundPlan, ExercisePanel): the PRACTICE of a unit that doesn't play
##   yet. STOP leaves and records nothing;
## - ROUND_END: the score, the stars, the gold the first time the unit is mastered (MasteryRules, once), PLAY AGAIN or MAP,
##   and after PLAY the world task as a quest card to TAKE IT WITH ME (PlayQuests, on the device);
## - QUESTS (owner #122): MY QUESTS, the world tasks taken, each ticked I DID IT!;
## - GATE and GROWN_UPS: the parent gate, then SchoolGrownUpsPage.
## - LAB (spec §23): the Science Lab on one experiment, from a unit's TRY IT IN THE LAB (`lab_link`); its LEARN MORE and
##   its BACK come back to a unit's page. `home_unit`: the School was opened on this unit (the Lab's LEARN MORE): that
##   unit page's BACK leaves the School (`closed`).
## - DAILY (owner #85): TODAY'S MISSION (DailyPage), from the map's gold button; the same 5 questions for every child of
##   the grade today.
## - POSTCARD (owner #81, #82): a unit or a grade mastered offers a postcard once, on the round's end (PostcardPage).
## - LIFE (owner #112): the 13th tab on every grade's map, Life (LifeScreen: its own map, units, practice rooms, Passport
##   and grown-ups' page); its BACK comes back to the map. The School's grown-ups page links to Life's.
## `profile`, `save_profile`, `today` and `next_seed` default to the game's own (tests set theirs); `daily_today` (the
## UTC day) and `service` for the Daily Mission.

signal closed

const WELCOME := &"welcome"
const GRADES := &"grades"
const MAP := &"map"
const UNIT := &"unit"
const LESSON := &"lesson"
const ROUND := &"round"
const ROUND_END := &"round_end"
const GATE := &"gate"
const GROWN_UPS := &"grown_ups"
const LAB := &"lab"   # spec §23
const DAILY := &"daily"   # owner #85
const POSTCARD := &"postcard"   # owner #81, #82
const LIFE := &"life"   # owner #112: the Life tab (the tab's id on the map too)
const PLAY := &"play"   # owner #122 (G0): the unit in the play arena
const QUESTS := &"quests"   # owner #122 (G0): MY QUESTS

## Owner #122 (G0): DISCOVER's words (for children; the grown-ups' page keeps the programme's words).
const HELLO_WORDS := "Hoo-hoo! I'm Professor Hoot. Welcome to DISCOVER: play, explore and learn!"
const MAP_WORDS := "Pick a stop. A picture on it means a game!"
const PLACES_WORDS := "places to play"
const PLAY_WORDS := "PLAY"
const REVIEW_WORDS := "PLAY: REVIEW"
const PLAY_AGAIN_WORDS := "PLAY AGAIN"
const BOOK_WORDS := "THE BOOK"
const BOOK_TITLE := "The Book:"
const BOOK_PLAY_WORDS := "LET'S PLAY!"
const PLAY_TIP := "Play first! A miss is fine: the place shows you."
## Owner #133 (the lead on the emulator, 2026-10-18): a playing unit's page is pictures and Hoot's voice; he says this
## after the unit's title as it opens. Its goals and standards are a small note that starts with GROWN_UPS_NOTE.
const PLAY_SAY := "Tap PLAY to start! A miss is fine."
const GROWN_UPS_NOTE := "For grown-ups:"
## Owner #134: a unit with no game yet keeps the School's own way (as before G0).
const LESSON_TIP := "Read the LESSON first, then PRACTICE. A miss is fine: I'll give you a hint."
const PRACTISE_WORDS := "LET'S PRACTISE!"
const QUESTS_WORDS := "MY QUESTS"
const TAKE_WORDS := "TAKE IT WITH ME"
const TAKEN_WORDS := "It is on your quest list: MY QUESTS."
const DONE_WORDS := "I DID IT!"
const WORLD_WORDS := "Use it in the world:"

var profile: ProfileData
var save_profile := Callable()
var today := Callable()
var next_seed := Callable()

var page: StringName = &""
var subject := "maths"
var unit_id := ""
var stops: Array[UnitStop] = []
var round: Array[Dictionary] = []
var exercise_panel: ExercisePanel
var _index := 0
var _right_first := 0
var _round_seed := 0   # owner #94: the round's seed also picks where Professor Hoot's praise starts
var _round_gold := 0   # owner #79: gold paid in this round for answers right the first time (EarnRules)
## Spec §23: TRY IT IN THE LAB on the page of a unit an experiment lists (off inside the Lab); the unit the Lab's LEARN
## MORE opened (its BACK leaves the School); the Lab while it shows.
var lab_link := true
var home_unit := ""
var lab: LabScreen
## Owner #85: TODAY'S MISSION (its page while it shows); the UTC day (DailyMission.today unless a test sets it); the
## online service the mission card asks for the invite code (Session's unless a test sets it).
var daily: DailyPage
var daily_today := Callable()
var service: OnlineService
## Owner #81, #82: the proud moment of the round just finished (a unit or a grade mastered), for its postcard.
var moment := {}
var postcard: PostcardPage
## Owner #112: Life while it shows.
var life: LifeScreen
## Owner #122 (G0): the play arena's host while a unit is played; whether the last round was played (not the old
## panel), its world task; MY QUESTS' file (tests set their own).
var play_host: PlayHost
var _played := false
var _world_task := ""
var quests_path := PlayQuests.FILE


func _init() -> void:
	name = "School"
	custom_minimum_size = SchoolUi.FRAME
	add_theme_constant_override("separation", 14)


func _ready() -> void:
	if profile == null:
		profile = Profile.data
	if not save_profile.is_valid():
		save_profile = Profile.save
	if not today.is_valid():
		today = SchoolClock.today
	if not next_seed.is_valid():
		next_seed = func() -> int: return randi()
	if profile.school.grade == 0:
		show_welcome()
	else:
		show_map()


func grade() -> int:
	return profile.school.grade if SchoolData.GRADES.has(profile.school.grade) else SchoolData.GRADES[0]


# --- WELCOME and GRADES ------------------------------------------------------------------------------------------

func show_welcome() -> void:
	_grade_page(true)


func show_grades() -> void:
	_grade_page(false)


func _grade_page(first: bool) -> void:
	_clear(WELCOME if first else GRADES)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 24)
	top.add_child(SchoolUi.teacher(150.0))
	var words := VBoxContainer.new()
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	var hello := SchoolUi.words(HELLO_WORDS if first else "Choose a grade", 34, 760)   # owner #122: DISCOVER
	words.add_child(ReadAloud.with_speaker(hello, self))
	words.add_child(SchoolUi.words(SchoolWords.PICK_GRADE, 30, 760))
	top.add_child(words)
	add_child(top)
	var locked := profile.school.grade_locked and not first
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	for g in SchoolData.GRADES:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		var wide := 200.0 if SchoolData.GRADES.size() <= 5 else 168.0   # six grades and more still fit the frame
		var b := SchoolUi.button("GRADE %d" % g, SchoolUi.TEAL if g == profile.school.grade else UiKit.BLUE, Vector2(wide, 120))
		b.name = "Grade%d" % g
		b.disabled = locked
		b.pressed.connect(_pick_grade.bind(g))
		col.add_child(b)
		var ages := SchoolUi.words(str(Curriculum.grade(g).get("ages", "")), 22, int(wide))
		col.add_child(ages)
		row.add_child(col)
	add_child(row)
	var note := SchoolUi.words("A grown-up chose grade %d." % profile.school.grade if locked
		else "Not sure? Ask a grown-up. You can change it later.", 24, 900)
	note.add_theme_color_override("font_color", SchoolUi.HINT)
	add_child(note)
	var back := SchoolUi.button("BACK", UiKit.BLUE, Vector2(240, 76))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: closed.emit() if first else show_map())
	add_child(back)


## Owner #85: TODAY'S MISSION on the map, gold, with a star when today's is done.
func _mission_button() -> Button:
	var day := int(daily_today.call()) if daily_today.is_valid() else DailyMission.today()
	var done := profile.daily.is_done(day)
	var b := SchoolUi.button("TODAY'S MISSION" if not done else "MISSION DONE!", SchoolUi.GOLD.darkened(0.35),
		Vector2(250, 64))
	b.name = "DailyMission"
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(show_daily)
	return b


func _pick_grade(g: int) -> void:
	if profile.school.grade_locked and page == GRADES:
		return
	profile.school.grade = g
	save_profile.call()
	show_map("maths")


# --- MAP -----------------------------------------------------------------------------------------------------------

func show_map(s: String = "") -> void:
	if s != "":
		subject = s
	_clear(MAP)
	var g := grade()
	# The grade's own subjects (owner #70: up to every school subject): one row of big tabs, or two rows of smaller ones.
	var ids: Array[String] = []
	for sub: Dictionary in Curriculum.subjects(g):   # a subject shows once it has a written unit: never an empty tab
		if Curriculum.CORE.has(str(sub.id)) or Curriculum.has_written(g, str(sub.id)):
			ids.append(str(sub.id))
	if not ids.has(subject) and not ids.is_empty():
		subject = ids[0]
	if not Vr.active():   # owner #112: Life, the 13th tab, on every grade (in a headset: in the header, below)
		ids.append(String(LIFE))
	var many := ids.size() > 4
	var written: Array[String] = []
	for u: Dictionary in Curriculum.units(g, subject):
		if Curriculum.has_content(str(u.id)) and not SpendRules.is_bonus(u):   # owner #83: Explorer lessons are extra
			written.append(str(u.id))
	var mastered := MasteryRules.all_mastered(profile.school, written)
	var word := str(SchoolUi.SUBJECT_WORDS.get(subject, subject)).capitalize()
	# Two rows of tabs leave no room for a line under the map: the gold words go in the title.
	var extra: Array = [_mission_button(), _small("GRADE", show_grades, 150), _small("GROWN-UPS", show_grown_ups, 210)]
	if Vr.active():   # owner #112: a headset's 24 px words leave room for six columns of tabs: LIFE sits in the header
		var life_button := SchoolUi.button("LIFE", LifeCards.COLOUR, Vector2(150, 64))
		life_button.name = "Tab_life"
		life_button.add_theme_font_size_override("font_size", 24)
		life_button.pressed.connect(show_life)
		extra.insert(2, life_button)
	# owner #122 (G0): the units are places to play (on a headset's narrower header: the grade alone; read aloud either way)
	var title := "Grade %d %s: mastered!" % [g, word] if many and mastered else ("Grade %d" % g if Vr.active()
		else "Grade %d: %s" % [g, PLACES_WORDS])
	var spoken := "Grade %d. %s" % [g, MAP_WORDS]
	var header := _header(title, func() -> void: closed.emit(), extra, func() -> String: return spoken, false)
	if many and mastered:
		for l: Label in header.find_children("*", "Label", true, false):
			if l.text.ends_with("mastered!"):
				l.add_theme_color_override("font_color", SchoolUi.GOLD)
	add_child(header)
	var tabs := GridContainer.new()
	tabs.columns = ceili(ids.size() / 2.0) if many else maxi(ids.size(), 1)   # more than four: two rows
	var wide := minf(214.0, (SchoolUi.FRAME.x - 12.0 * (tabs.columns - 1)) / tabs.columns)
	tabs.add_theme_constant_override("h_separation", 12 if many else 14)
	tabs.add_theme_constant_override("v_separation", 6)
	tabs.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for sid: String in ids:
		var b := SchoolUi.button(SchoolUi.SUBJECT_WORDS.get(sid, sid.to_upper()), SchoolUi.SUBJECT_COLORS.get(sid, UiKit.BLUE)
			if sid == subject else Color(0.2, 0.24, 0.36), Vector2(wide, 40) if many else Vector2(230, 60))
		if many:
			b.add_theme_font_size_override("font_size", 19 if wide > 200.0 else 16)
		b.name = "Tab_" + sid
		if sid == String(LIFE):   # owner #112: Life keeps its own colour and icon, and opens its own pages
			b.text = "LIFE"
			var side := b.custom_minimum_size.y - 10.0
			for state: String in ["normal", "hover", "pressed"]:
				var box := UiKit.box(LifeCards.COLOUR.lightened(0.1 if state == "hover" else 0.0))
				box.content_margin_left = side + 12.0
				b.add_theme_stylebox_override(state, box)
			var icon := LifeIcons.new("heart", side)
			icon.name = "TabIcon"
			icon.position = Vector2(8, 5)
			b.add_child(icon)
			b.pressed.connect(show_life)
		else:
			b.pressed.connect(show_map.bind(sid))
		tabs.add_child(b)
	add_child(tabs)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var day := int(today.call())
	for i in Curriculum.units(g, subject).size():
		var u := Curriculum.unit(str(Curriculum.units(g, subject)[i].id))
		var stop := UnitStop.new(u, profile.school.progress(str(u.id)), day, SchoolUi.SUBJECT_COLORS.get(subject, UiKit.BLUE))
		stop.pressed.connect(show_unit.bind(str(u.id)))
		var c := Curriculum.content(str(u.id)) if Curriculum.has_content(str(u.id)) else {}
		if not c.is_empty() and PlayHost.plays(c):   # owner #122, #134: a place to play, with its game's picture
			var icon := PlayIcon.new(PlayMechanics.main_of(PlayReadless.content(c)), 30.0)
			icon.position = UnitStop.SIZE - Vector2(36, 34)
			stop.add_child(icon)
		stops.append(stop)
		grid.add_child(stop)
	add_child(grid)
	if many:
		return   # two rows of tabs: the stops keep the room
	var footer_row := HBoxContainer.new()
	footer_row.alignment = BoxContainer.ALIGNMENT_CENTER
	footer_row.add_theme_constant_override("separation", 24)
	var line := "Grade %d %s: every unit mastered. Well done!" % [g, word] if mastered else MAP_WORDS
	var footer := SchoolUi.words(line, 24, 760)
	footer.add_theme_color_override("font_color", SchoolUi.GOLD if mastered else Color(1, 1, 1, 0.8))
	footer_row.add_child(footer)
	if not PlayQuests.open_at(quests_path).open_cards().is_empty():   # owner #122: the world tasks taken along
		footer_row.add_child(_small(QUESTS_WORDS, show_quests, 220))
	add_child(footer_row)


# --- UNIT ----------------------------------------------------------------------------------------------------------

func show_unit(id: String) -> void:
	var u := Curriculum.unit(id)
	if u.is_empty():
		show_map()
		return
	unit_id = id
	subject = str(u.subject)
	_clear(UNIT)
	var p := profile.school.progress(id)
	var written := Curriculum.has_content(id)
	var plays := written and PlayHost.plays(Curriculum.content(id))   # owner #134: else the School as it was
	var back := (func() -> void: closed.emit()) if id == home_unit else show_map.bind(subject)   # spec §23: from the Lab
	var said := SchoolSpeech.spoken("%s. %s" % [u.title, PLAY_SAY]) if plays and SpendRules.lesson_open(profile, id) else ""
	add_child(_header(str(u.title), back, [SchoolUi.stars(MasteryRules.stars(p), 40.0)],
		(func() -> String: return said) if said != "" else Callable()))
	var body := HBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 40)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left.custom_minimum_size.x = 700
	# Codes alone name their framework; the research's mixed lists (grade 3 up: "UK Y4 …", "SG P3 …") say "Follows".
	var codes := PackedStringArray(u.get("standards", []))
	var named := not ["maths", "science", "english"].has(subject)
	for code in codes:
		named = named or code.contains(" ")
	var framework := "Follows" if named else "NGSS" if subject == "science" else "Common Core"
	if plays:   # owner #133: the games as big pictures first; the goals and standards a small note for grown-ups
		left.add_child(_games_row(PlayReadless.content(Curriculum.content(id))))   # owner #122: what you play here
	else:
		left.add_child(_left_words("You will learn to:", 30))
		for goal: String in u.get("goals", []):
			left.add_child(_left_words("•  " + goal, 26))
		var standards := _left_words("%s: %s" % [framework, ", ".join(codes)], 20)
		standards.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		left.add_child(standards)
	if written:
		var tip := HBoxContainer.new()
		tip.add_theme_constant_override("separation", 18)
		tip.add_child(SchoolUi.teacher(110.0))
		var line := _left_words(PLAY_TIP if plays else LESSON_TIP, 24)
		line.custom_minimum_size.x = 540
		line.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		line.add_theme_color_override("font_color", SchoolUi.HINT)
		tip.add_child(line)
		left.add_child(tip)
	if plays:
		var goals := PackedStringArray(u.get("goals", []))
		var note := _left_words("%s  %s  •  %s: %s" % [GROWN_UPS_NOTE, "  •  ".join(goals), framework, ", ".join(codes)], 16)
		note.name = "GrownUpsNote"
		note.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
		left.add_child(note)
	body.add_child(left)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 18)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	if not SpendRules.lesson_open(profile, id):   # owner #83: an Explorer lesson not bought yet (spec §25.5)
		_explorer_offer(right, id, u)
	elif written and not plays:   # owner #134: no game yet: the School as it was, LESSON then PRACTICE
		var lesson := SchoolUi.button("LESSON", UiKit.BLUE, Vector2(340, 96))
		lesson.name = "Lesson"
		lesson.pressed.connect(show_lesson.bind(id))
		right.add_child(lesson)
		var due := MasteryRules.review_due(p, int(today.call()))
		var practice := SchoolUi.button(SchoolWords.REVIEW if due else "PRACTICE", UiKit.GREEN, Vector2(340, 96))
		practice.name = "Practice"
		practice.pressed.connect(show_round.bind(id))
		right.add_child(practice)
		var rounds := int(p.r)
		right.add_child(SchoolUi.words("Not practised yet." if rounds == 0 else "%d round%s. Best: %d%% right the first time." % [
			rounds, Lang.plural_s(rounds), int(p.b)], 22, 340))
	elif written:   # owner #122 (G0): PLAY first; the Book is a small choice, never the path
		var review := MasteryRules.review_due(p, int(today.call()))
		var play := SchoolUi.button(REVIEW_WORDS if review else PLAY_WORDS, UiKit.GREEN, Vector2(340, 120))
		play.name = "Play"
		play.add_theme_font_size_override("font_size", 40)
		play.pressed.connect(show_play.bind(id))
		right.add_child(play)
		var small := HBoxContainer.new()
		small.alignment = BoxContainer.ALIGNMENT_CENTER
		small.add_theme_constant_override("separation", 12)
		var book := SchoolUi.button(BOOK_WORDS, UiKit.BLUE, Vector2(164, 60))
		book.name = "TheBook"
		book.add_theme_font_size_override("font_size", 22)
		book.pressed.connect(show_lesson.bind(id))
		small.add_child(book)
		var quests := SchoolUi.button(QUESTS_WORDS, Color(0.2, 0.24, 0.36), Vector2(164, 60))
		quests.name = "MyQuests"
		quests.add_theme_font_size_override("font_size", 22)
		quests.pressed.connect(show_quests)
		small.add_child(quests)
		right.add_child(small)
		var r := int(p.r)
		right.add_child(SchoolUi.words("Not played yet." if r == 0 else "Played %d time%s. Best: %d%% right the first time." % [
			r, Lang.plural_s(r), int(p.b)], 22, 340))
	else:
		right.add_child(SchoolUi.teacher(110.0))
		right.add_child(SchoolUi.words(SchoolWords.COMING_SOON, 34, 340))
		right.add_child(SchoolUi.words("Professor Hoot is still writing this one.", 22, 340))
	var labs := LabExperiments.for_unit(id) if lab_link else ([] as Array[String])   # spec §23: the Science Lab
	if not labs.is_empty():
		var try_lab := SchoolUi.button("TRY IT IN THE LAB", LabScreen.LAB_COLOUR, Vector2(340, 80))
		try_lab.name = "TryInLab"
		try_lab.add_theme_font_size_override("font_size", 26)
		try_lab.pressed.connect(show_lab.bind(labs[0]))
		right.add_child(try_lab)
	body.add_child(right)
	add_child(body)
	if said != "":
		ReadAloud.auto(said)   # owner #133: Hoot says what to do as the page opens


## Owner #83 (spec §25.5): an Explorer lesson (a unit marked "bonus": true) opens for good with gold; the grade's own
## units are never sold.
const EXPLORER_WORDS := "An Explorer lesson! It opens for good."


func _explorer_offer(column: VBoxContainer, id: String, u: Dictionary) -> void:
	var cost := SpendRules.lesson_price(u)
	column.add_child(SchoolUi.words(EXPLORER_WORDS, 28, 340))
	var buy := SchoolUi.button("OPEN FOR %d GOLD" % cost, SchoolUi.GOLD.darkened(0.35), Vector2(340, 96))
	buy.name = "OpenExplorer"
	buy.add_theme_font_size_override("font_size", 26)
	buy.disabled = profile.survivor_gold < cost
	buy.pressed.connect(func() -> void:
		if SpendRules.buy(profile, "lesson:" + id) == SpendRules.OK:
			save_profile.call()
			Audio.play(&"jingle_badge")
		show_unit(id))
	column.add_child(buy)
	var have := SchoolUi.words("You have %s gold. Learning earns more!" % GoldFormat.short(profile.survivor_gold), 22, 340)
	have.add_theme_color_override("font_color", SchoolUi.HINT)
	column.add_child(have)


# --- LESSON --------------------------------------------------------------------------------------------------------

func show_lesson(id: String, card: int = 0) -> void:
	var c := Curriculum.content(id)
	if not SpendRules.lesson_open(profile, id):
		show_unit(id)
		return
	if c.is_empty():
		show_unit(id)
		return
	unit_id = id
	var cards: Array = c.lesson
	card = clampi(card, 0, cards.size() - 1)
	_clear(LESSON)
	var text := str(cards[card].get("text", ""))
	var u := Curriculum.unit(id)
	add_child(_header("%s %s  (%d of %d)" % [BOOK_TITLE, u.title, card + 1, cards.size()], show_unit.bind(id), [],
		func() -> String: return SchoolSpeech.spoken(text)))   # owner #122: the Book, on request
	var body := HBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 30)
	body.custom_minimum_size.y = 400
	var has_picture: bool = cards[card].get("picture") is Dictionary
	if has_picture:
		var pic := SchoolPicture.new(cards[card].picture, Vector2(560, 380))
		pic.playing = SchoolPicture.should_play(pic.data, false)   # owner #94: a lesson's picture shows its motion
		body.add_child(pic)
	var words := SchoolUi.words(text, 30 if has_picture else 34, 560.0 if has_picture else 1000.0)
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if has_picture else HORIZONTAL_ALIGNMENT_CENTER
	if cards[card].get("sound") is Dictionary:   # a tune or claps to hear (the research's §5.3)
		var column := VBoxContainer.new()
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_theme_constant_override("separation", 16)
		column.add_child(words)
		column.add_child(SchoolUi.listen_button(cards[card].sound))
		body.add_child(column)
	else:
		body.add_child(words)
	add_child(body)
	UiMotion.pop_in(body)   # owner #94: each card pops in
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	if card > 0:
		var prev := SchoolUi.button("PREVIOUS", UiKit.BLUE, Vector2(240, 80))
		prev.pressed.connect(show_lesson.bind(id, card - 1))
		row.add_child(prev)
	var last := card == cards.size() - 1
	var plays := PlayHost.plays(c)   # owner #134: the Book ends in play where there is a game, else in practice
	var next := SchoolUi.button((BOOK_PLAY_WORDS if plays else PRACTISE_WORDS) if last else "NEXT",
		UiKit.GREEN if last else SchoolUi.TEAL, Vector2(320, 80))
	var ends := show_play.bind(id) if plays else show_round.bind(id)
	next.pressed.connect(ends if last else show_lesson.bind(id, card + 1))   # owner #122: the Book ends in play
	row.add_child(next)
	add_child(row)
	if last and not bool(profile.school.progress(id).l):
		profile.school.set_progress(id, MasteryRules.lesson_read(profile.school.progress(id)))
		save_profile.call()
	ReadAloud.auto(SchoolSpeech.spoken(text))


# --- ROUND and ROUND_END ---------------------------------------------------------------------------------------

func show_round(id: String) -> void:
	if not SpendRules.lesson_open(profile, id):   # owner #83: an Explorer lesson opens with gold first
		show_unit(id)
		return
	var c := Curriculum.content(id)
	unit_id = id
	_round_seed = int(next_seed.call())
	round = RoundPlan.plan(c, _round_seed, MasteryRules.stars(profile.school.progress(id)))
	if round.is_empty():
		show_unit(id)
		return
	_index = 0
	_right_first = 0
	_round_gold = 0
	_show_exercise()


func _show_exercise() -> void:
	_clear(ROUND)
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 20)
	var stop := SchoolUi.button("STOP", UiKit.BLUE, Vector2(160, 60))
	stop.pressed.connect(_stop_round)   # nothing recorded: a round counts only when it is finished
	bar.add_child(stop)
	var title := Label.new()
	title.text = str(Curriculum.unit(unit_id).get("title", ""))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 28)
	bar.add_child(title)
	var progress := Label.new()
	progress.text = "%d of %d" % [_index + 1, round.size()]
	progress.add_theme_font_size_override("font_size", 28)
	bar.add_child(progress)
	add_child(bar)
	exercise_panel = ExercisePanel.new(round[_index], _index)
	exercise_panel.praise_from = posmod(_round_seed, 9973)
	exercise_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	exercise_panel.answered.connect(_on_answered)
	exercise_panel.first_try_gold = _pay_answer
	add_child(exercise_panel)


## Owner #79 (spec §25.1): an answer right the first time pays a few gold, up to the day's cap (EarnRules).
func _pay_answer() -> int:
	var gold := EarnRules.answer_gold(profile, int(today.call()))
	_round_gold += gold
	return gold


## STOP: the round records nothing, but the gold its answers earned is kept.
func _stop_round() -> void:
	if _round_gold > 0:
		save_profile.call()
	_round_gold = 0
	show_unit(unit_id)


func _on_answered(first_try: bool) -> void:
	if page != ROUND:
		return
	if first_try:
		_right_first += 1
	_index += 1
	if _index < round.size():
		_show_exercise()
	else:
		_finish_round()


func _finish_round() -> void:
	_played = false
	_record_round(_right_first, round.size())


## A finished round (the old panel's, or a played one: owner #122) recorded the same way, through the games' own bridge
## (SkillShown.record_round, owner #134): MasteryRules' stars, reviews and the unit's gold once; a friend's reward; a
## proud moment; learning together (SocialSender); then its end page.
func _record_round(right_first: int, total: int) -> void:
	_right_first = right_first
	var r := SkillShown.record_round(profile, unit_id, right_first, total, int(today.call()))
	moment = r.moment
	save_profile.call()
	if r.first_unit:
		InviteSender.send_soon()
	show_round_end(r, right_first, total)


## Owner #94: the round's stars pop in; a new star (a level-up of the unit), its mastery or a remembered third star
## glows and bursts stars.
func _celebrate_stars(stars: Control, level_up: bool) -> void:
	UiMotion.pop_in(stars, 0.15)
	if not level_up or not is_inside_tree():
		return
	var tw := create_tween()
	tw.tween_interval(UiMotion.POP_TIME + 0.15)
	tw.tween_callback(func() -> void:
		if is_instance_valid(stars) and stars.is_inside_tree():
			UiMotion.glow(stars)
			UiMotion.burst(self, stars.get_global_rect().get_center(), 10))


func show_round_end(r: Dictionary, right_first: int, total: int) -> void:
	_clear(ROUND_END)
	var u := Curriculum.unit(unit_id)
	add_child(_header(str(u.get("title", "")), show_unit.bind(unit_id)))
	var body := HBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 40)
	body.add_child(SchoolUi.teacher(170.0))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(SchoolUi.words(SchoolWords.round_score(right_first, total), 40, 720))
	col.add_child(SchoolUi.words(SchoolWords.round_end(right_first, total, r.mastered_now), 28, 720))
	var stars := SchoolUi.stars(int(r.stars), 56.0)
	stars.name = "RoundStars"
	stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(stars)
	_celebrate_stars(stars, bool(r.pay) or bool(r.get("remembered_now", false))
		or int(r.stars) > int(r.get("stars_before", r.stars)))
	if _round_gold > 0:   # owner #79 (EarnRules)
		var answers := SchoolUi.words(EarnRules.round_words(_round_gold), 26, 720)
		answers.name = "AnswerGold"
		answers.add_theme_color_override("font_color", SchoolUi.GOLD)
		col.add_child(answers)
	if right_first * EarnRules.ANSWER_GOLD > _round_gold:   # the day's answer gold ran out in this round
		var full := SchoolUi.words(EarnRules.DAY_FULL_WORDS, 22, 720)
		full.name = "DayFull"
		col.add_child(full)
	if r.pay:
		var gold := SchoolUi.words("+%d gold for Survivor, and the %s badge!" % [MasteryRules.UNIT_GOLD, u.get("title", "")], 28, 720)
		gold.add_theme_color_override("font_color", SchoolUi.GOLD)
		col.add_child(gold)
	elif r.remembered_now:
		var star := SchoolUi.words("You remembered it on another day: a third star!", 28, 720)
		star.add_theme_color_override("font_color", SchoolUi.GOLD)
		col.add_child(star)
	body.add_child(col)
	add_child(body)
	if _played and _world_task != "":   # owner #122: use it in the world: the task as a quest card to take along
		add_child(_quest_card(unit_id, _world_task))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	var again := SchoolUi.button(PLAY_AGAIN_WORDS if _played else "PRACTISE AGAIN", UiKit.GREEN, Vector2(320, 84))
	again.pressed.connect(show_play.bind(unit_id) if _played else show_round.bind(unit_id))
	row.add_child(again)
	var map := SchoolUi.button("MAP", SchoolUi.TEAL, Vector2(240, 84))
	map.pressed.connect(show_map.bind(subject))
	row.add_child(map)
	if r.pay and not moment.is_empty() and PostcardRules.note_offered(profile, moment):   # owner #81, #82: once
		save_profile.call()
		var card := SchoolUi.button("MAKE A POSTCARD", UiKit.ORANGE, Vector2(320, 84))
		card.name = "MakePostcard"
		card.add_theme_font_size_override("font_size", 26)
		var m := moment
		card.pressed.connect(func() -> void: show_postcard(m))
		row.add_child(card)
	add_child(row)
	if r.pay:
		add_child(CoinShower.new())
		Audio.play(&"jingle_badge")
	else:
		Audio.play(&"jingle_goal")
	ReadAloud.auto(SchoolWords.round_score(right_first, total))


# --- PLAY and QUESTS (owner #122, G0: every unit is a game) -------------------------------------------------------

## PLAY: the unit in the play arena (PlayHost); the School hides while it shows. Its end is recorded as a round was.
## Owner #133, #134 (PlaySignature): the unit's deep game opens its own host, else G0's place; `params` (a deep game's
## `then`: the leaf's next voyage) change the play block's for this time only.
func show_play(id: String, params: Dictionary = {}) -> void:
	if not SpendRules.lesson_open(profile, id):   # owner #83: an Explorer lesson opens with gold first
		show_unit(id)
		return
	var c := Curriculum.content(id)
	if c.is_empty():
		show_unit(id)
		return
	if not params.is_empty():
		c = PlaySignature.with_params(c, params)
	unit_id = id
	subject = str(Curriculum.unit(id).get("subject", subject))
	_round_seed = int(next_seed.call())
	_round_gold = 0
	_clear(PLAY)
	add_child(SchoolUi.words("Playing...", 30, 900))
	play_host = PlaySignature.make_host(c)
	play_host.setup(id, c, _round_seed, MasteryRules.stars(profile.school.progress(id)), Curriculum.unit(id))
	if play_host.loop != null and play_host.loop.challenges.is_empty():   # a deep game's host has no exercise loop
		play_host = null
		show_unit(id)
		return
	play_host.first_try_gold = _pay_answer
	play_host.finished.connect(_on_play_finished)
	play_host.stopped.connect(_on_play_stopped)
	play_host.finished.connect(func(o: Dictionary) -> void:   # recorded first; then the game's next (`then`)
		var then := PlaySignature.then_of(o)
		if not then.is_empty():
			show_play.call_deferred(id, then))
	play_host.open(self)


func _on_play_finished(outcome: Dictionary) -> void:
	play_host = null
	_played = true
	_world_task = str(outcome.get("world_task", ""))
	_record_round(int(outcome.get("right_first", 0)), int(outcome.get("total", MasteryRules.ROUND_SIZE)))


## STOP FOR NOW: nothing is recorded (as the old round's STOP), but the gold its answers earned is kept.
func _on_play_stopped(_outcome: Dictionary) -> void:
	play_host = null
	if _round_gold > 0:
		save_profile.call()
	_round_gold = 0
	show_unit(unit_id)


## The games a unit plays as big pictures, each with its name under it (owner #133: seen, not read; three at most on
## the line, the rest play too).
func _games_row(c: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.name = "Games"
	row.add_theme_constant_override("separation", 28)
	var used := PlayMechanics.of_unit(c)
	var order := PlayMechanics.ids()
	used.sort_custom(func(a: String, b: String) -> bool: return order.find(a) < order.find(b))   # the acts first
	for m in used:
		if row.get_child_count() >= 3:
			break
		var game := VBoxContainer.new()
		game.add_theme_constant_override("separation", 4)
		var icon := PlayIcon.new(m, 96.0)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		game.add_child(icon)
		var name_label := Label.new()
		name_label.text = PlayMechanics.name_of(m)
		name_label.add_theme_font_size_override("font_size", 20)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		game.add_child(name_label)
		row.add_child(game)
	return row


## A unit's world task as a quest card: "Use it in the world:" and the task, read aloud, and TAKE IT WITH ME.
func _quest_card(id: String, task: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.name = "QuestCard"
	card.add_theme_stylebox_override("panel", UiKit.box(Color(0.12, 0.3, 0.2, 0.95), 18, 12))
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	card.add_child(row)
	var words := VBoxContainer.new()
	words.add_theme_constant_override("separation", 2)
	var head := _left_words(WORLD_WORDS, 22)
	head.custom_minimum_size.x = 640
	head.add_theme_color_override("font_color", SchoolUi.GOLD)
	words.add_child(head)
	var line := _left_words(task, 22)
	line.custom_minimum_size.x = 640
	words.add_child(line)
	row.add_child(words)
	row.add_child(ReadAloud.button(func() -> String: return "%s %s" % [WORLD_WORDS, task], 56.0))
	var quests := PlayQuests.open_at(quests_path)
	var take := SchoolUi.button(TAKE_WORDS if not quests.has(id) else "TAKEN!", UiKit.ORANGE, Vector2(250, 64))
	take.name = "TakeQuest"
	take.add_theme_font_size_override("font_size", 22)
	take.disabled = quests.has(id)
	take.pressed.connect(func() -> void:
		var q := PlayQuests.open_at(quests_path)
		q.take(id, task)
		q.save()
		take.text = "TAKEN!"
		take.disabled = true
		line.text = "%s %s" % [task, TAKEN_WORDS]
		ReadAloud.auto(TAKEN_WORDS))
	row.add_child(take)
	return card


## MY QUESTS: the world tasks taken along (newest first), each with its unit and I DID IT!
func show_quests() -> void:
	var from := unit_id
	_clear(QUESTS)
	var back := (func() -> void: show_unit(from)) if from != "" else (func() -> void: show_map(subject))
	add_child(_header(QUESTS_WORDS.capitalize(), back))
	var quests := PlayQuests.open_at(quests_path)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 10)
	list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if quests.cards.is_empty():
		list.add_child(SchoolUi.words("No quests yet. Play a place to the end, then TAKE IT WITH ME.", 26, 900))
	for c: Dictionary in quests.cards.slice(0, 6):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var words := VBoxContainer.new()
		var where := _left_words(str(Curriculum.unit(str(c.unit)).get("title", "")), 18)
		where.add_theme_color_override("font_color", SchoolUi.GOLD)
		words.add_child(where)
		var task := _left_words(str(c.task), 22)
		task.custom_minimum_size.x = 780
		words.add_child(task)
		row.add_child(words)
		var unit := str(c.unit)
		var done := SchoolUi.button(DONE_WORDS if not bool(c.done) else "DONE!", UiKit.GREEN, Vector2(200, 60))
		done.add_theme_font_size_override("font_size", 22)
		done.disabled = bool(c.done)
		done.pressed.connect(func() -> void:
			var q := PlayQuests.open_at(quests_path)
			q.tick(unit)
			q.save()
			Audio.play(&"jingle_goal")
			show_quests())
		row.add_child(done)
		list.add_child(row)
	add_child(list)
	ReadAloud.auto(ReadAloud.words_of(list))


# --- DAILY (owner #85: TODAY'S MISSION) and POSTCARD (owner #81, #82) ----------------------------------------------

func show_daily() -> void:
	_clear(DAILY)
	daily = DailyPage.new()
	daily.profile = profile
	daily.save_profile = save_profile
	if daily_today.is_valid():
		daily.today = daily_today
	daily.grade = grade()
	daily.service = service if service != null else Session.online_service_or_null()
	daily.closed.connect(func() -> void: show_map(subject))
	add_child(daily)


## A proud moment's postcard (a drawn picture: the School has no world to photograph); CLOSE comes back to the unit.
func show_postcard(m: Dictionary) -> void:
	var from := unit_id
	_clear(POSTCARD)
	postcard = PostcardPage.new(m)
	postcard.profile = profile
	postcard.closed.connect(func() -> void: show_unit(from) if from != "" else show_map(subject))
	add_child(postcard)


# --- LAB (spec §23: the Science Lab) -----------------------------------------------------------------------------

## The Science Lab on experiment `id` (a unit's TRY IT IN THE LAB); its BACK and its LEARN MORE come back to a unit.
func show_lab(id: String) -> void:
	var from := unit_id
	_clear(LAB)
	lab = LabScreen.new()
	lab.profile = profile
	lab.save_profile = save_profile
	lab.learn_more = func(unit: String) -> void: show_unit(unit)
	lab.closed.connect(func() -> void:
		if from != "":
			show_unit(from)
		else:
			show_map())
	add_child(lab)
	lab.start_on(id)


# --- GATE and GROWN_UPS ----------------------------------------------------------------------------------------

func show_grown_ups() -> void:
	_clear(GATE)
	var gate := GrownUpGate.new()
	gate.passed.connect(show_grown_ups_page)
	gate.cancelled.connect(show_map.bind(subject))
	add_child(gate)


func show_grown_ups_page() -> void:
	_clear(GROWN_UPS)
	var p := SchoolGrownUpsPage.new(profile, save_profile)
	p.subject = subject
	p.closed.connect(show_map.bind(subject))
	p.life_requested.connect(show_life.bind(true))   # owner #112: Life's page for grown-ups (already past the gate)
	add_child(p)


# --- LIFE (owner #112: the 13th tab) -------------------------------------------------------------------------------

## Life inside the School's frame; `grown_ups`: straight to its grown-ups' page (from the School's, past the gate).
func show_life(grown_ups: bool = false) -> void:
	_clear(LIFE)
	life = LifeScreen.new()
	life.profile = profile
	life.save_profile = save_profile
	life.today = today
	life.next_seed = next_seed
	life.closed.connect(func() -> void: show_map(subject))
	add_child(life)
	if grown_ups:
		life.show_grown_ups_page()


# --- Shared pieces -------------------------------------------------------------------------------------------------

## BACK, Professor Hoot (unless `owl` is false: the map's header gives his room to TODAY'S MISSION), the title with its
## speaker (it reads `text` or the whole page), then `extra` controls.
func _header(title: String, back: Callable, extra: Array = [], text: Callable = Callable(), owl: bool = true) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var b := SchoolUi.button("BACK", UiKit.BLUE, Vector2(150, 64))
	b.pressed.connect(back)
	row.add_child(b)
	if owl:
		row.add_child(SchoolUi.teacher(64.0))
	var room := SchoolUi.FRAME.x - 150.0 - (64.0 + 16.0 if owl else 0.0) - 16.0 * (2 + extra.size()) - 70.0
	for c: Control in extra:
		room -= c.custom_minimum_size.x
	var label := SchoolUi.fit_title(title, room)
	var titled := ReadAloud.with_speaker(label, self, text)
	titled.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(titled)
	for c: Control in extra:
		c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(c)
	return row


func _small(text: String, action: Callable, width: float) -> Button:
	var b := SchoolUi.button(text, Color(0.2, 0.24, 0.36), Vector2(width, 64))
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(action)
	return b


func _left_words(text: String, font_size: int) -> Label:
	var l := SchoolUi.words(text, font_size, 700)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return l


## Empties the page (at once: tests look at the new one in the same frame) and names the new one. A coin shower keeps
## raining.
func _clear(next: StringName) -> void:
	page = next
	stops.clear()
	if next != ROUND:
		exercise_panel = null
	if next != LAB:
		lab = null
	if next != DAILY:
		daily = null
	if next != POSTCARD:
		postcard = null
	if next != LIFE:
		life = null
	if next != PLAY:
		play_host = null
	for c in get_children():
		if c is CoinShower:
			continue
		remove_child(c)
		c.queue_free()
