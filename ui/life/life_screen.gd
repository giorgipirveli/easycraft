class_name LifeScreen
extends VBoxContainer
## Owner #112, #113, #115 (docs/design/life-skills.md §3, §7, §10, §11; docs/design/success-skills.md; spec §27): Life,
## the School's 13th tab (shown inside the School's frame: every page fits SchoolUi.FRAME). Pages:
## - TRACK: "Which one are you?": LITTLE, MIDDLE, BIG as big pictures with their ages, read aloud (a grown-up's lock
##   keeps it);
## - MAP: the ten areas in Life's two strands (LIVING WELL; SUCCESS: money and business, thinking and the future), with
##   the track, the PASSPORT and GROWN-UPS; AREA: its units on the track shown (EASIER, HARDER look at the others);
## - UNIT: its goals, LESSON and PRACTICE (REVIEW when due) in the School's format, and for an Experience TRY IT with
##   the Passport's three stamps and, once done by the child alone, EXPERT TRY; "Coming soon" for one not built yet;
## - LESSON, ROUND, ROUND_END: the School's lesson and practice (ExercisePanel, RoundPlan, MasteryRules): answers right
##   the first time and a unit mastered pay gold like any lesson (EarnRules); a School unit keeps the School's progress;
## - CHECK: the before-and-after picture check (the before only the first time); ROOM: the practice room
##   (LifeRoomHost); CARD: the "name it" card; RESULT: the stamps (a surprise on a new Expert stamp), the Experience's
##   gold the first time, the honest before-and-after, Try it for real; CALM: after STOP FOR NOW;
## - PASSPORT (LifePassportPage); GATE and GROWN_UPS (LifeGrownUpsPage, behind the parent gate).
## `profile`, `save_profile`, `today`, `next_seed`, `locale` and `measure` default to the game's (tests set theirs).
## Life L2, Life Town (owner #112): `town_experience` set, Life opens on that Experience's unit on the child's track (the
## track first, the very first time) and that unit's BACK closes Life (`closed`): the building in the world started it.
## Life L3a (owner #118, design §6, §14): after an emergency Experience (LifeExperience.emergency) the calm DEBRIEF page
## comes before the name-it card ("You did it. In real life, grown-ups help too."), and the CALM page says it too; the room
## gets the grown-up's intensity for the track (LifeData.intensity_for) and the skill's finished runs (the danger moments'
## time); an area with many units shows them in two rows.

signal closed

const TRACK := &"track"
const MAP := &"map"
const AREA := &"area"
const UNIT := &"unit"
const LESSON := &"lesson"
const ROUND := &"round"
const ROUND_END := &"round_end"
const CHECK := &"check"
const ROOM := &"room"
const CARD := &"card"
const RESULT := &"result"
const CALM := &"calm"
const DEBRIEF := &"debrief"   # Life L3a (owner #118)
const PASSPORT := &"passport"
const TOOL_BOOK := &"tool_book"   # owner #116
const SUCCESS := &"success"   # owner #115: a Success place (SuccessPlaces: the Goal Board, the Connections Book, the stories)
const GATE := &"gate"
const GROWN_UPS := &"grown_ups"
const COLOUR := LifeCards.COLOUR
const WHICH_ONE := "Which one are you? Pick the one for your age. You can try the others too."
const CALM_WORDS := "Well done for practising. You can come back any time: nothing is lost."
const FIRST_CHECK := "Before we start: what do you know already? Any answer is fine!"
const AFTER_CHECK := "Now the same questions again. Let's see what you know now!"
## Life L3a (owner #118, design §6): the calm debrief after an emergency Experience.
const DEBRIEF_WORDS := "You did it. In real life, grown-ups help too."
const DEBRIEF_MORE := "It was practice, and everyone is safe. If something worries you, talk to a grown-up you trust. In a real emergency, the number is %s."
## A unit row on an area page holds this many cards; more go into a second row.
const AREA_ROW := 5

var profile: ProfileData
var save_profile := Callable()
var today := Callable()
var next_seed := Callable()
var locale := ""
var measure: LifeMeasure
var town_experience := ""

var page: StringName = &""
var view_track := ""
var area_id := ""
var unit_id := ""
var exercise_panel: ExercisePanel
var round: Array[Dictionary] = []
var host: LifeRoomHost
var passport: LifePassportPage
var grown_ups: LifeGrownUpsPage
var check_questions: Array[Dictionary] = []
var check_index := 0
var check_right := 0
var check_after := false
var trying := {}   # the Experience try in progress: {experience, track, expert}
var last := {}     # the last finished try: {experience, track, expert, outcome, record}
var _index := 0
var _right_first := 0
var _round_gold := 0
var _round_seed := 0


func _init() -> void:
	name = "Life"
	custom_minimum_size = SchoolUi.FRAME
	add_theme_constant_override("separation", 12)


func _ready() -> void:
	if profile == null:
		profile = Profile.data
	if not save_profile.is_valid():
		save_profile = Profile.save
	if not today.is_valid():
		today = SchoolClock.today
	if not next_seed.is_valid():
		next_seed = func() -> int: return randi()
	if locale == "":
		locale = OS.get_locale()
	if measure == null:
		measure = LifeMeasure.new()
	if not LifeData.valid_track(profile.life.track):
		show_track()
	elif town_experience != "":
		show_unit(LifeCatalog.experience_unit(town_experience, track()))
	else:
		show_map()


func region() -> String:
	return LifeRegion.resolve(profile.life.region, locale)


func track() -> String:
	return profile.life.track if LifeData.valid_track(profile.life.track) else "middle"


# --- TRACK ---------------------------------------------------------------------------------------------------------

func show_track() -> void:
	_clear(TRACK)
	var first := not LifeData.valid_track(profile.life.track)
	add_child(_header("Life", (func() -> void: closed.emit()) if first else show_map, []))
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 20)
	top.add_child(SchoolUi.teacher(120.0))
	var words := SchoolUi.words(WHICH_ONE, 30, 760)
	top.add_child(ReadAloud.with_speaker(words, self))
	add_child(top)
	var locked := profile.life.track_locked
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 26)
	for t in LifeData.TRACKS:
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 6)
		var b := LifeCards.picture_button(LifeCatalog.track_words(t), "track_" + t,
			COLOUR if t == profile.life.track else UiKit.BLUE, Vector2(300, 260), 32)
		b.name = "Track_" + t
		b.disabled = locked
		b.pressed.connect(_pick_track.bind(t))
		col.add_child(b)
		col.add_child(SchoolUi.words(LifeCatalog.track_ages(t), 24, 300))
		row.add_child(col)
	add_child(row)
	var note := SchoolUi.words("A grown-up chose %s." % LifeCatalog.track_words(profile.life.track) if locked
		else "Not sure? Ask a grown-up. You can change it later.", 24, 900)
	note.add_theme_color_override("font_color", SchoolUi.HINT)
	add_child(note)
	LifeVoice.say(WHICH_ONE, "little")   # the track is not known yet: every child hears the question


func _pick_track(t: String) -> void:
	if profile.life.track_locked:
		return
	profile.life.track = t
	view_track = t
	save_profile.call()
	if town_experience != "":
		show_unit(LifeCatalog.experience_unit(town_experience, t))
	else:
		show_map()


# --- MAP and AREA --------------------------------------------------------------------------------------------------

func show_map() -> void:
	_clear(MAP)
	view_track = track()
	var track_button := LifeCards.picture_button(LifeCatalog.track_words(track()), "track_" + track(), COLOUR,
		Vector2(150, 64), 18)
	track_button.name = "TrackButton"
	track_button.pressed.connect(show_track)
	add_child(_header("Life", func() -> void: closed.emit(), [track_button, _small("PASSPORT", show_passport, 190),
		_small("TOOL BOOK", show_tool_book, 200), _small("GROWN-UPS", show_grown_ups, 200)]))
	for strand in LifeCatalog.STRANDS:
		var label := SchoolUi.words(str(LifeCatalog.STRAND_TITLES[strand]), 24, 1100)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.add_theme_color_override("font_color", SchoolUi.GOLD if strand == "success" else Color(1, 1, 1, 0.85))
		add_child(label)
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 14)
		grid.add_theme_constant_override("v_separation", 12)
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		for a in LifeCatalog.areas_of(strand):
			grid.add_child(_area_button(a))
		SuccessPlaces.fit_grid(grid)   # owner #115: the Success strand's six areas in one row
		add_child(grid)


func _area_button(a: Dictionary) -> Button:
	var b := LifeCards.picture_button(str(a.title), str(a.icon), Color(str(a.get("colour", "3a7be8"))), Vector2(270, 132), 21)
	b.name = "Area_" + str(a.id)
	b.pressed.connect(show_area.bind(str(a.id)))
	if _area_due(str(a.id)):
		var leaf := SchoolUi.words("practise again", 15, 130)
		leaf.name = "Due"
		leaf.add_theme_color_override("font_color", SchoolUi.GOOD)
		leaf.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		leaf.offset_left = -136
		b.add_child(leaf)
	return b


func _area_due(id: String) -> bool:
	for u in LifeCatalog.all_units():
		if str(u.area) == id and str(u.get("experience", "")) != "":
			if LifePassport.repeat_due(profile.life, LifeExperience.skill_id(str(u.experience), str(u.track)), int(today.call())):
				return true
	return false


func show_area(id: String, shown_track: String = "") -> void:
	area_id = id
	if shown_track != "":
		view_track = shown_track
	if not LifeData.valid_track(view_track):
		view_track = track()
	_clear(AREA)
	var a := LifeCatalog.area(id)
	add_child(_header("%s: %s" % [a.get("title", id), LifeCatalog.track_words(view_track)], show_map, []))
	var list := LifeCatalog.units(id, view_track)
	var per_row := mini(list.size(), AREA_ROW) if list.size() <= AREA_ROW else ceili(list.size() / 2.0)
	var grid := GridContainer.new()   # Life L3a: many units (Staying safe) wrap into two rows
	grid.columns = maxi(per_row, 1)
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var wide := floorf(minf(270.0, (SchoolUi.FRAME.x - 24.0 - 14.0 * (per_row - 1)) / maxf(per_row, 1.0)))
	var tall := 300.0 if list.size() <= AREA_ROW else 230.0
	for u in list:
		grid.add_child(_unit_card(u, wide, tall))
	add_child(grid)
	SuccessPlaces.add_places(self, id, show_success_place)   # owner #115: MY GOAL BOARD, MY CONNECTIONS BOOK, THE STORY SHELF
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", 20)
	var i := LifeData.TRACKS.find(view_track)
	if i > 0:
		var easier := SchoolUi.button("EASIER", Color(0.2, 0.24, 0.36), Vector2(220, 64))
		easier.pressed.connect(show_area.bind(id, LifeData.TRACKS[i - 1]))
		foot.add_child(easier)
	foot.add_child(SchoolUi.words("The %s track: %s." % [LifeCatalog.track_words(view_track), LifeCatalog.track_ages(view_track)],
		22, 420))
	if i < LifeData.TRACKS.size() - 1:
		var harder := SchoolUi.button("HARDER", Color(0.2, 0.24, 0.36), Vector2(220, 64))
		harder.pressed.connect(show_area.bind(id, LifeData.TRACKS[i + 1]))
		foot.add_child(harder)
	add_child(foot)


## Each Experience's own picture on its unit cards (the emulator, 2026-10-17: every card showed the passport). A new
## Experience adds its line here; one without a line shows the passport.
const EXPERIENCE_ICONS := {
	"animals": "dog_happy", "calm_corner": "smile", "connections": "connections", "earth_weather": "cloud",
	"electricity": "plug", "find_way": "compass_rose", "fire_escape": "fire_engine", "goal_board": "goal",
	"home_helper": "house", "kitchen": "pan", "little_lifesaver": "recovery", "medical": "ambulance",
	"money_stall": "stall", "online_city": "tablet", "poisons_cupboard": "warning_sign", "real_builder": "build_blocks",
	"safe_streets": "crossing", "success_stories": "story_book", "talk_deal": "handshake", "water_safety": "ring_buoy",
	"my_shop": "shop", "market_square": "price_board",   # owner #115 (S3)
}


static func experience_icon(exp_id: String) -> String:
	return str(EXPERIENCE_ICONS.get(exp_id, "passport"))


## The band under a unit card's title for its stars or stamps.
const BADGE_ROOM := 56.0


func _unit_card(u: Dictionary, wide: float, tall: float = 300.0) -> Button:
	var id := str(u.id)
	var exp_id := str(u.get("experience", ""))
	var icon := experience_icon(exp_id) if exp_id != "" else ("clock" if u.has("soon") else "book")
	var b := LifeCards.picture_button(LifeCatalog.title(id), icon, COLOUR if exp_id != "" else Color(0.2, 0.3, 0.5),
		Vector2(wide, tall), 20 if tall >= 300.0 else 18, 0.42 if tall >= 300.0 else 0.34, BADGE_ROOM)
	b.name = "Unit_" + id.replace(".", "_")
	b.pressed.connect(show_unit.bind(id))
	var badge: Control
	if exp_id != "":
		badge = LifeCards.stamps_row(LifePassport.stamps(profile.life, LifeExperience.skill_id(exp_id, str(u.track))), 40.0, false)
	elif u.has("soon"):
		badge = SchoolUi.words("Coming soon", 18, wide - 20.0)
	else:
		badge = SchoolUi.stars(MasteryRules.stars(_progress(id)), 30.0)
	badge.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	badge.offset_top = -BADGE_ROOM
	badge.offset_bottom = -10
	badge.offset_left = -wide * 0.4
	badge.offset_right = wide * 0.4
	b.add_child(badge)
	return b


# --- UNIT, LESSON, ROUND -------------------------------------------------------------------------------------------

func _progress(id: String) -> Dictionary:
	return profile.school.progress(id) if LifeCatalog.is_school(id) else profile.life.unit(id)


func _set_progress(id: String, p: Dictionary) -> void:
	if LifeCatalog.is_school(id):
		profile.school.set_progress(id, p)
	else:
		profile.life.set_unit(id, p)


func _unit_track(id: String) -> String:
	return str(LifeCatalog.unit(id).get("track", track()))


func show_unit(id: String) -> void:
	var u := LifeCatalog.unit(id)
	if u.is_empty():
		show_map()
		return
	unit_id = id
	area_id = str(u.area)
	_clear(UNIT)
	var p := _progress(id)
	add_child(_header(LifeCatalog.title(id), func() -> void:
		if town_experience != "" and str(u.get("experience", "")) == town_experience:
			closed.emit()   # Life Town: back to the world
		else:
			show_area(area_id, str(u.track)),
		[SchoolUi.stars(MasteryRules.stars(p), 40.0)] if not u.has("soon") else []))
	var body := HBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 36)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	left.custom_minimum_size.x = 640
	left.add_child(_left_words("You will learn to:", 30))
	for goal in LifeCatalog.goals(id, region()):
		left.add_child(_left_words("•  " + goal, 26))
	if LifeCatalog.is_school(id):
		var from := Curriculum.unit(id)
		var note := _left_words("A lesson from the School: grade %d, %s." % [int(from.get("grade", 0)),
			str(SchoolUi.SUBJECT_WORDS.get(str(from.get("subject", "")), "")).capitalize()], 20)
		note.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
		left.add_child(note)
	var tip := HBoxContainer.new()
	tip.add_theme_constant_override("separation", 16)
	tip.add_child(SchoolUi.teacher(110.0))
	# Owner #122 (learning is play, rule 2): play first, words after; the cards are the BOOK, there to read on request.
	var line := _left_words("Jump in and TRY IT: the coach helps you. The BOOK is there if you want to read." if u.has(
		"experience") else "Have a go at PRACTICE: the coach helps you. The BOOK is there if you want to read.", 24)
	line.custom_minimum_size.x = 480
	line.add_theme_color_override("font_color", SchoolUi.HINT)
	tip.add_child(line)
	left.add_child(tip)
	body.add_child(left)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 14)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	if u.has("soon"):
		right.add_child(SchoolUi.teacher(100.0))
		right.add_child(SchoolUi.words(SchoolWords.COMING_SOON, 34, 380))
		right.add_child(SchoolUi.words("Its practice room is still being built.", 22, 380))
	else:
		if u.has("experience"):
			var exp_id := str(u.experience)
			var t := str(u.track)
			var skill := LifeExperience.skill_id(exp_id, t)
			var go := SchoolUi.button("TRY IT", COLOUR, Vector2(380, 96))
			go.name = "TryIt"
			go.add_theme_font_size_override("font_size", 34)
			go.pressed.connect(start_experience.bind(exp_id, t, false))
			right.add_child(go)
			right.add_child(LifeCards.stamps_row(LifePassport.stamps(profile.life, skill), 56.0))
			if LifePassport.expert_open(profile.life, skill):
				var ex := SchoolUi.button("EXPERT TRY", SchoolUi.GOLD.darkened(0.35), Vector2(380, 70))
				ex.name = "ExpertTry"
				ex.add_theme_font_size_override("font_size", 26)
				ex.pressed.connect(start_experience.bind(exp_id, t, true))
				right.add_child(ex)
		var review := MasteryRules.review_due(p, int(today.call()))
		var practice := SchoolUi.button(SchoolWords.REVIEW if review else "PRACTICE", UiKit.GREEN, Vector2(380, 80))
		practice.pressed.connect(show_round.bind(id))
		right.add_child(practice)
		var book := SchoolUi.button("BOOK", UiKit.BLUE, Vector2(380, 64))   # owner #122: the cards, last, on request
		book.name = "Book"
		book.pressed.connect(show_lesson.bind(id))
		right.add_child(book)
	body.add_child(right)
	add_child(body)


func show_lesson(id: String, card: int = 0) -> void:
	var c := LifeCatalog.content(id, region())
	if c.is_empty():
		show_unit(id)
		return
	unit_id = id
	var cards: Array = c.lesson
	card = clampi(card, 0, cards.size() - 1)
	_clear(LESSON)
	var text := str(cards[card].get("text", ""))
	add_child(_header("%s  (%d of %d)" % [LifeCatalog.title(id), card + 1, cards.size()], show_unit.bind(id), [],
		func() -> String: return SchoolSpeech.spoken(text)))
	var body := HBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 30)
	body.custom_minimum_size.y = 400
	var has_picture: bool = cards[card].get("picture") is Dictionary
	if has_picture:
		body.add_child(SchoolPicture.new(cards[card].picture, Vector2(540, 370)))
	var words := SchoolUi.words(text, 30 if has_picture else 34, 560.0 if has_picture else 1000.0)
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if has_picture else HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(words)
	add_child(body)
	UiMotion.pop_in(body)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	if card > 0:
		var prev := SchoolUi.button("PREVIOUS", UiKit.BLUE, Vector2(240, 80))
		prev.pressed.connect(show_lesson.bind(id, card - 1))
		row.add_child(prev)
	var last_card := card == cards.size() - 1
	var next := SchoolUi.button("LET'S PRACTISE!" if last_card else "NEXT", UiKit.GREEN if last_card else SchoolUi.TEAL,
		Vector2(320, 80))
	next.pressed.connect(show_round.bind(id) if last_card else show_lesson.bind(id, card + 1))
	row.add_child(next)
	add_child(row)
	if last_card and not bool(_progress(id).l):
		_set_progress(id, MasteryRules.lesson_read(_progress(id)))
		save_profile.call()
	LifeVoice.say(SchoolSpeech.spoken(text), _unit_track(id))


func show_round(id: String) -> void:
	var c := LifeCatalog.content(id, region())
	unit_id = id
	_round_seed = int(next_seed.call())
	round = RoundPlan.plan(c, _round_seed, MasteryRules.stars(_progress(id)))
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
	stop.pressed.connect(func() -> void:
		if _round_gold > 0:
			save_profile.call()
		show_unit(unit_id))
	bar.add_child(stop)
	var title := Label.new()
	title.text = LifeCatalog.title(unit_id)
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
	exercise_panel.first_try_gold = func() -> int:
		var g := EarnRules.answer_gold(profile, int(today.call()))
		_round_gold += g
		return g
	add_child(exercise_panel)


func _on_answered(first_try: bool) -> void:
	if page != ROUND:
		return
	if first_try:
		_right_first += 1
	_index += 1
	if _index < round.size():
		_show_exercise()
		return
	var r := MasteryRules.after_round(_progress(unit_id), _right_first, round.size(), int(today.call()))
	_set_progress(unit_id, r.progress)
	if r.pay:
		EarnRules.credit(profile, EarnRules.UNIT_GOLD)
	save_profile.call()
	_round_end(r)


func _round_end(r: Dictionary) -> void:
	_clear(ROUND_END)
	add_child(_header(LifeCatalog.title(unit_id), show_unit.bind(unit_id)))
	var body := HBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 40)
	body.add_child(SchoolUi.teacher(170.0))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 14)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(SchoolUi.words(SchoolWords.round_score(_right_first, round.size()), 40, 720))
	col.add_child(SchoolUi.words(SchoolWords.round_end(_right_first, round.size(), r.mastered_now), 28, 720))
	var stars := SchoolUi.stars(int(r.stars), 56.0)
	stars.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(stars)
	UiMotion.pop_in(stars, 0.15)
	if _round_gold > 0:
		var answers := SchoolUi.words(EarnRules.round_words(_round_gold), 26, 720)
		answers.add_theme_color_override("font_color", SchoolUi.GOLD)
		col.add_child(answers)
	if r.pay:
		var gold := SchoolUi.words("+%d gold for Survivor!" % MasteryRules.UNIT_GOLD, 28, 720)
		gold.add_theme_color_override("font_color", SchoolUi.GOLD)
		col.add_child(gold)
	body.add_child(col)
	add_child(body)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	var again := SchoolUi.button("PRACTISE AGAIN", UiKit.GREEN, Vector2(320, 84))
	again.pressed.connect(show_round.bind(unit_id))
	row.add_child(again)
	var u := LifeCatalog.unit(unit_id)
	if u.has("experience"):
		var go := SchoolUi.button("TRY IT", COLOUR, Vector2(260, 84))
		go.pressed.connect(start_experience.bind(str(u.experience), str(u.track), false))
		row.add_child(go)
	var back := SchoolUi.button("BACK", SchoolUi.TEAL, Vector2(200, 84))
	back.pressed.connect(show_unit.bind(unit_id))
	row.add_child(back)
	add_child(row)
	if r.pay:
		add_child(CoinShower.new())
		Audio.play(&"jingle_badge")
	else:
		Audio.play(&"jingle_goal")
	LifeVoice.say(SchoolWords.round_score(_right_first, round.size()), _unit_track(unit_id))


# --- TRY IT: the check, the room, the card, the result ------------------------------------------------------------

## TRY IT: the before-check the first time, then the practice room.
func start_experience(exp_id: String, t: String, expert: bool) -> void:
	trying = {"experience": exp_id, "track": t, "expert": expert}
	if int(profile.life.skill(LifeExperience.skill_id(exp_id, t)).b) < 0:
		show_check(exp_id, t, false)
	else:
		_open_room()


func show_check(exp_id: String, t: String, after: bool) -> void:
	if trying.is_empty():
		trying = {"experience": exp_id, "track": t, "expert": false}
	check_after = after
	check_questions = LifeExperience.check(exp_id, t, region(), int(next_seed.call()))
	check_index = 0
	check_right = 0
	_show_question()


func _show_question() -> void:
	_clear(CHECK)
	var t := str(trying.track)
	var q: Dictionary = check_questions[check_index]
	add_child(_header(("After: %d of %d" if check_after else "What do you know? %d of %d") % [check_index + 1,
		check_questions.size()], _leave_check, []))
	if check_index == 0:
		var intro := SchoolUi.words(AFTER_CHECK if check_after else FIRST_CHECK, 24, 1000)
		intro.add_theme_color_override("font_color", SchoolUi.HINT)
		add_child(intro)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	row.add_child(SchoolUi.teacher(110.0))
	row.add_child(SchoolUi.words(str(q.say), 32, 800))
	add_child(row)
	var choices := HBoxContainer.new()
	choices.alignment = BoxContainer.ALIGNMENT_CENTER
	choices.add_theme_constant_override("separation", 22)
	var n := (q.choices as Array).size()
	var wide := minf(320.0, (SchoolUi.FRAME.x - 22.0 * (n - 1)) / n)
	for i in n:
		var c: Dictionary = q.choices[i]
		var b := LifeCards.picture_button(str(c.text), str(c.get("icon", "question")), Color(0.16, 0.22, 0.36),
			Vector2(wide, 250), 24 if str(c.text).length() < 26 else 20)
		b.name = "Check%d" % i
		b.pressed.connect(answer_check.bind(i))
		choices.add_child(b)
	add_child(choices)
	LifeVoice.say(str(q.say), t)


## A check's answer (only the first answer counts; no question is ever marked wrong in the before-check).
func answer_check(i: int) -> void:
	if page != CHECK:
		return
	var q: Dictionary = check_questions[check_index]
	if i == int(q.answer):
		check_right += 1
	check_index += 1
	if check_index < check_questions.size():
		_show_question()
		return
	var skill := LifeExperience.skill_id(str(trying.experience), str(trying.track))
	LifePassport.record_check(profile.life, skill, check_after, check_right, check_questions.size())
	save_profile.call()
	if check_after:
		show_result()
	else:
		_open_room()


func _leave_check() -> void:
	if check_after:
		show_result()   # the after-check is a bonus: leaving it still shows the stamps
	else:
		show_unit(unit_id) if unit_id != "" else show_map()


func _open_room() -> void:
	_clear(ROOM)
	add_child(SchoolUi.words("In the practice room...", 30, 900))
	host = ToolRoomHost.new()   # owner #116: Life's room host with the tool engine (it plays every Experience as before)
	var skill := LifeExperience.skill_id(str(trying.experience), str(trying.track))
	host.setup(str(trying.experience), str(trying.track), bool(trying.expert), int(next_seed.call()), region(),
		profile.life.intensity_for(str(trying.track)), int(profile.life.skill(skill).r))   # Life L3a (owner #118)
	host.finished.connect(_on_room_finished)
	host.stopped.connect(_on_room_stopped)
	host.open(self)


func _on_room_finished(outcome: Dictionary) -> void:
	var exp_id := str(trying.experience)
	var t := str(trying.track)
	var skill := LifeExperience.skill_id(exp_id, t)
	var record := LifePassport.record_run(profile.life, skill, outcome, int(today.call()))
	if int(record.gold) > 0:
		EarnRules.credit(profile, int(record.gold))
	_measure(skill, outcome)
	if host is ToolRoomHost:   # owner #116: the Tool Book's stamps
		profile.tools.record((host as ToolRoomHost).tool_entries(), bool(trying.expert))
	if host and host.run:   # owner #115: the Connections Book's people, the stories acted (SuccessPlaces)
		SuccessPlaces.record_try(profile.life.success, host.run.steps, outcome, int(today.call()))
		# owner #115 (S3): the shop's day into its ledger, its customers' gold (paid only for what was played)
		record["shop_gold"] = SuccessPlaces.after_try(profile, exp_id, host.run.steps, outcome, int(today.call()))
	save_profile.call()
	last = {"experience": exp_id, "track": t, "expert": trying.expert, "outcome": outcome, "record": record}
	host = null
	if LifeExperience.emergency(exp_id):
		show_debrief(exp_id, t)   # Life L3a (owner #118): the calm debrief first
	else:
		show_card(exp_id, t)


## Life L3a (owner #118, design §6): after an emergency Experience, a short calm debrief: you did it, in real life
## grown-ups help too, it was practice, talk to a grown-up you trust, the region's number. Then the name-it card.
func show_debrief(exp_id: String, t: String) -> void:
	_clear(DEBRIEF)
	var more := DEBRIEF_MORE % LifeRegion.number(region())
	add_child(_header(LifeExperience.title(exp_id), show_card.bind(exp_id, t), [],
		func() -> String: return "%s %s" % [DEBRIEF_WORDS, more]))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 30)
	row.add_child(SchoolUi.teacher(170.0))
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 16)
	col.add_child(LifeIcons.new("heart", 110.0))
	col.add_child(SchoolUi.words(DEBRIEF_WORDS, 36, 720))
	var calm := SchoolUi.words(more, 24, 720)
	calm.add_theme_color_override("font_color", SchoolUi.HINT)
	col.add_child(calm)
	row.add_child(col)
	add_child(row)
	var next := SchoolUi.button("NEXT", UiKit.GREEN, Vector2(280, 84))
	next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next.pressed.connect(show_card.bind(exp_id, t))
	add_child(next)
	LifeVoice.say("%s %s" % [DEBRIEF_WORDS, more], t)


func _on_room_stopped(outcome: Dictionary) -> void:
	_measure(LifeExperience.skill_id(str(trying.experience), str(trying.track)), outcome)
	if host and host.run:   # owner #115 (S3): customers served before STOP FOR NOW still pay (and go in the ledger)
		SuccessPlaces.after_try(profile, str(trying.experience), host.run.steps, outcome, int(today.call()))
		save_profile.call()
	host = null
	show_calm()


func _measure(skill: String, outcome: Dictionary) -> void:
	var entries: Array[Dictionary] = []
	for e: Variant in outcome.get("log", []):
		if e is Dictionary:
			entries.append(e)
	if not entries.is_empty() and measure != null:
		measure.note(skill, entries)
		measure.save()


## The "name it" card: the steps in the authorities' own words, read aloud; then the after-check.
func show_card(exp_id: String, t: String) -> void:
	if trying.is_empty():
		trying = {"experience": exp_id, "track": t, "expert": false}
	_clear(CARD)
	var card := LifeExperience.card(exp_id, t, region())
	add_child(_header(LifeExperience.title(exp_id), show_unit.bind(unit_id) if unit_id != "" else show_map, [],
		func() -> String: return "%s. %s" % [card.get("title", ""), ". ".join(PackedStringArray(card.get("lines", [])))]))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	row.add_child(SchoolUi.teacher(150.0))
	row.add_child(LifeCards.name_it(card, 780.0))
	add_child(row)
	if exp_id == "little_lifesaver":
		var note := SchoolUi.words(LifeExperience.PRACTICE_NOTE, 22, 1000)
		note.add_theme_color_override("font_color", SchoolUi.HINT)
		add_child(note)
	var next := SchoolUi.button("NEXT", UiKit.GREEN, Vector2(280, 84))
	next.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next.pressed.connect(show_check.bind(exp_id, t, true))
	add_child(next)
	LifeVoice.say("%s. %s" % [card.get("title", ""), ". ".join(PackedStringArray(card.get("lines", [])))], t)


func show_result() -> void:
	_clear(RESULT)
	var exp_id := str(trying.get("experience", last.get("experience", "")))
	var t := str(trying.get("track", last.get("track", track())))
	var skill := LifeExperience.skill_id(exp_id, t)
	var record: Dictionary = last.get("record", {})
	add_child(_header("%s: %s" % [LifeExperience.title(exp_id), str(LifeExperience.track_data(exp_id, t).get("skill", ""))],
		show_unit.bind(unit_id) if unit_id != "" else show_map, []))
	var body := HBoxContainer.new()
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_theme_constant_override("separation", 30)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 12)
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	var stamps := LifeCards.stamps_row(LifePassport.stamps(profile.life, skill), 92.0)
	left.add_child(stamps)
	UiMotion.pop_in(stamps, 0.1)
	var said := _result_words(record)
	left.add_child(SchoolUi.words(said, 28, 520))
	if int(record.get("gold", 0)) > 0:
		var gold := SchoolUi.words("+%d gold for Survivor!" % int(record.gold), 28, 520)
		gold.add_theme_color_override("font_color", SchoolUi.GOLD)
		left.add_child(gold)
	if int(record.get("shop_gold", 0)) > 0:   # owner #115 (S3): the shop's customers' gold
		var shop := SchoolUi.words(SuccessShop.gold_words(int(record.shop_gold)), 24, 520)
		shop.name = "ShopGold"
		shop.add_theme_color_override("font_color", SchoolUi.GOLD)
		left.add_child(shop)
	var line := LifePassport.summary_line(profile.life, skill)
	if line != "":
		var honest := SchoolUi.words(line, 20, 520)
		honest.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
		left.add_child(honest)
	body.add_child(left)
	body.add_child(LifeCards.try_real(LifeExperience.words(exp_id, t, "try_real", region()), 560.0))
	add_child(body)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	var again := SchoolUi.button("AGAIN", UiKit.GREEN, Vector2(220, 80))
	again.pressed.connect(start_experience.bind(exp_id, t, false))
	row.add_child(again)
	if LifePassport.expert_open(profile.life, skill) and not profile.life.has_stamp(skill, LifeData.EXPERT):
		var ex := SchoolUi.button("EXPERT TRY", SchoolUi.GOLD.darkened(0.35), Vector2(260, 80))
		ex.pressed.connect(start_experience.bind(exp_id, t, true))
		row.add_child(ex)
	row.add_child(_small("PASSPORT", show_passport, 220))
	var done := SchoolUi.button("DONE", SchoolUi.TEAL, Vector2(200, 80))
	done.pressed.connect(func() -> void: show_unit(unit_id) if unit_id != "" else show_map())
	row.add_child(done)
	add_child(row)
	if bool(record.get("expert_new", false)):
		_expert_surprise(stamps)
	elif int(record.get("gold", 0)) > 0:
		add_child(CoinShower.new())
		Audio.play(&"jingle_badge")
	else:
		Audio.play(&"jingle_goal")
	LifeVoice.say(said, t)


## Praise for the doing and the way (engagement research §1.8: effort and strategy, never talent).
func _result_words(record: Dictionary) -> String:
	var bits := int(record.get("new", 0))
	if bits & LifeData.EXPERT:
		return "An Expert stamp! You did the harder try all by yourself."
	if bits & LifeData.SELF:
		return "A By myself stamp! You did every step without the coach."
	if bits & LifeData.DONE:
		return "A Done it stamp! You practised every step. Next time, try it by yourself."
	return "You practised it again: that is how it sticks."


## The surprise on a new Expert stamp: unexpected and informational (engagement research §1.8).
func _expert_surprise(stamps: Control) -> void:
	var l := UiKit.title("EXPERT!", 64)
	l.name = "ExpertSurprise"
	l.add_theme_color_override("font_color", SchoolUi.GOLD)
	add_child(l)
	move_child(l, 1)
	UiMotion.pop_in(l)
	add_child(CoinShower.new())
	Audio.play(&"jingle_level")
	if is_inside_tree():
		var tw := create_tween()
		tw.tween_interval(0.3)
		tw.tween_callback(func() -> void:
			if is_instance_valid(stamps) and stamps.is_inside_tree():
				UiMotion.glow(stamps)
				UiMotion.burst(self, stamps.get_global_rect().get_center(), 14))


func show_calm() -> void:
	_clear(CALM)
	add_child(_header("Life", show_map, []))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 26)
	row.add_child(SchoolUi.teacher(170.0))
	var said := CALM_WORDS
	if LifeExperience.emergency(str(trying.get("experience", ""))):   # Life L3a: the debrief's calm words too
		said = "%s %s" % [CALM_WORDS, DEBRIEF_WORDS.trim_prefix("You did it. ")]
	row.add_child(SchoolUi.words(said, 34, 700))
	add_child(row)
	var back := SchoolUi.button("BACK", SchoolUi.TEAL, Vector2(260, 84))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(func() -> void: show_unit(unit_id) if unit_id != "" else show_map())
	add_child(back)
	LifeVoice.say(said, track())


# --- PASSPORT and GROWN-UPS ----------------------------------------------------------------------------------------

func show_passport() -> void:
	_clear(PASSPORT)
	passport = LifePassportPage.new(profile, region(), int(today.call()))
	passport.closed.connect(show_map)
	add_child(passport)


## Owner #116, #117: every tool and device the child has used, its safety rule and its three stamps (ToolBookPage).
func show_tool_book() -> void:
	_clear(TOOL_BOOK)
	var book := ToolBookPage.new(profile)
	book.closed.connect(show_map)
	add_child(book)


## Owner #115: a Success place of the Life map (SuccessPlaces.page); its BACK returns to the area.
func show_success_place(place: String) -> void:
	var p := SuccessPlaces.page(place, profile, save_profile, int(today.call()), region(), track())
	if p == null:
		return
	_clear(SUCCESS)
	p.closed.connect(func() -> void: show_area(area_id) if area_id != "" else show_map())
	p.try_it = func(exp_id: String) -> void:   # owner #115 (S3): MY SHOP opens a shop day, THE PRICE BOARD the market
		unit_id = LifeCatalog.experience_unit(exp_id, track())
		start_experience(exp_id, track(), false)
	add_child(p)


func show_grown_ups() -> void:
	_clear(GATE)
	var gate := GrownUpGate.new()
	gate.passed.connect(show_grown_ups_page)
	gate.cancelled.connect(show_map)
	add_child(gate)


func show_grown_ups_page() -> void:
	_clear(GROWN_UPS)
	grown_ups = LifeGrownUpsPage.new(profile, save_profile, locale, int(today.call()))
	grown_ups.closed.connect(show_map)
	add_child(grown_ups)


# --- Shared pieces -------------------------------------------------------------------------------------------------

func _header(title: String, back: Callable, extra: Array = [], text: Callable = Callable()) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var b := SchoolUi.button("BACK", UiKit.BLUE, Vector2(150, 64))
	b.pressed.connect(back)
	row.add_child(b)
	var room := SchoolUi.FRAME.x - 150.0 - 16.0 * (2 + extra.size()) - 70.0
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
	var l := SchoolUi.words(text, font_size, 640)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return l


## Empties the page at once (tests look at the new one in the same frame); the room host and a coin shower stay.
func _clear(next: StringName) -> void:
	page = next
	if next != ROUND:
		exercise_panel = null
	if next != PASSPORT:
		passport = null
	if next != GROWN_UPS:
		grown_ups = null
	for c in get_children():
		if c is CoinShower or c is LifeRoomHost:
			continue
		remove_child(c)
		c.queue_free()
