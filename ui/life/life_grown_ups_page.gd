class_name LifeGrownUpsPage
extends VBoxContainer
## Owner #112, #113 (docs/design/life-skills.md §6, §7, §11): Life's page for grown-ups, behind the parent gate.
## - PROGRESS: "Your child can now..." in plain words (only what was done by the child alone), what is being practised
##   with the coach's help, this week's Experiences, the honest before-and-after line of each skill played ("knew 1 of 5
##   at the start, now 5 of 5, in 9 minutes": only what the game measured), the Try it for real list (the child shows the
##   grown-up), the practice note for first aid and what is kept where.
## - SETTINGS: the child's track and whether only a grown-up changes it; the region (the emergency number the
##   Experiences dial and say, which side cars drive on; from this device unless chosen); the careful topics' switches,
##   all off, with nothing behind them yet.
## Life L3a (owner #118, design §14): the intensity of the dangerous Experiences (GENTLE by default; MORE REAL is a
## grown-up's choice and only ever used on the Big track), with what it changes.
## Saved at once in the profile; nothing leaves the device but the account's backup.

signal closed

const PRIVACY := "Life's progress stays on this device and in your account's backup. Nothing else is sent: no addresses, no names, no voices. The step-by-step measurements stay on this device only."
const CAREFUL_WORDS := {"body_safety": "BODY SAFETY", "puberty": "GROWING UP", "consent": "CONSENT",
	"crises": "HARD TIMES", "substances": "ALCOHOL, DRUGS"}
const CAREFUL_NOTE := "Off until you turn them on. Nothing is behind them yet: these lessons come later, written with a child psychologist and a teacher, never in online play, always pointing to a trusted adult and your country's child helpline."
const INTENSITY_WORDS := {LifeData.GENTLE: "GENTLE", LifeData.REAL: "MORE REAL"}
const INTENSITY_NOTE := "Dangers are practised gently. MORE REAL is used only on the Big track (12 and up): danger moments at real speed from the first try, and the storm, the shaking and the alarms a little stronger. Never injuries, never scares: the freeze, the coach and the way out stay."
const SAFE_MISTAKE_NOTE := "A safe mistake: on the Middle and Big tracks your child may try the wrong way (swimming straight back against a rip, mixing two cleaners, running out while the ground shakes). Time freezes, the scene goes soft and still, the coach shows calmly what would happen and why, then your child does it right. On the Little track the coach guides first. After every emergency practice a calm debrief: in real life, grown-ups help too."
const DANGER_SOURCES :="Water Safety, The Poisons Cupboard and Earth and Weather follow the WHO, the RNLI and the Royal Life Saving Society, poison centres and the Child Accident Prevention Trust, ShakeOut and FEMA's Ready.gov, the US National Weather Service and Georgia's Emergency Management Service. A safe mistake lets your child try the wrong way, frozen in time, and hear why."
## Life L3b (owner #118): the second part of the dangers wave and its authorities.
const DANGER_SOURCES_L3B := "Electricity Safety, Safe with Animals and Medical Emergencies follow Electrical Safety First and the electricity networks, St John Ambulance and the British Red Cross, the Dogs Trust, the Kennel Club and the RSPCA, the NHS, Anaphylaxis UK, Asthma + Lung UK, Epilepsy Action and the Epilepsy Foundation. Medicine pens and inhalers are practised only with trainers: a real one is only ever the person's own."
## Life L3c (owner #112, #118): Online City, Find Your Way and Home Helper, their authorities, and what is never asked.
const SOURCES_L3C := "Online City, Find Your Way and Home Helper follow Childnet's SMART rules, the UK Safer Internet Centre, the NSPCC and UNICEF, the police's and child-safety charities' advice for a lost child (NCMEC, Kidpower), the fire and rescue services, Ordnance Survey, GINETEX's care symbols, the RSPCA and recycling advice. Online City is all pretend: nothing your child types or says is kept or sent, and the game never asks for an address or a phone number: your child says them aloud to you."

var profile: ProfileData
var save_profile: Callable
var locale := ""
var today := 0
var tab := "progress"
var body: VBoxContainer
var region_buttons := {}
var track_buttons := {}
var lock_buttons := {}
var careful_buttons := {}
var intensity_buttons := {}


func _init(p: ProfileData, save: Callable, device_locale: String, day: int) -> void:
	profile = p
	save_profile = save
	locale = device_locale
	today = day
	name = "LifeGrownUpsPage"
	add_theme_constant_override("separation", 8)
	custom_minimum_size.x = SchoolUi.FRAME.x


func _ready() -> void:
	add_child(ReadAloud.with_speaker(UiKit.title("Life: for grown-ups", 34), self))
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 14)
	for t: Array in [["PROGRESS", show_progress], ["SETTINGS", show_settings], ["SAFETY", show_safety]]:
		var b := SchoolUi.button(str(t[0]), Color(0.2, 0.24, 0.36), Vector2(240, 52))
		b.name = "Tab" + str(t[0]).capitalize()
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(t[1])
		tabs.add_child(b)
	var done := SchoolUi.button("DONE", SchoolUi.TEAL, Vector2(200, 52))
	done.pressed.connect(func() -> void: closed.emit())
	tabs.add_child(done)
	add_child(tabs)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	add_child(body)
	show_progress()


func region() -> String:
	return LifeRegion.resolve(profile.life.region, locale)


func show_progress() -> void:
	tab = "progress"
	OnlineUi.clear(body)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(SchoolUi.FRAME.x - 20.0, 470)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var list := VBoxContainer.new()
	list.add_theme_constant_override("separation", 6)
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	var r := region()
	var can := LifePassport.can_now(profile.life, r)
	_heading(list, "Your child can now...")
	if can.is_empty():
		_line(list, "Nothing done all alone yet: the Passport fills as your child practises.")
	for c in can:
		_line(list, "•  " + c)
	var practising := LifePassport.practising(profile.life, r)
	if not practising.is_empty():
		_heading(list, "Practising with the coach's help")
		for c in practising:
			_line(list, "•  " + c)
	var week := LifePassport.this_week(profile.life, today)
	if not week.is_empty():
		var names: Array[String] = []
		for skill in week:
			var parts := LifeExperience.of_skill(skill)
			names.append("%s (%s)" % [LifeExperience.title(parts[0]), LifePassport.TRACK_WORDS[parts[1]]])
		_heading(list, "This week")
		_line(list, ", ".join(names) + ".")
	var lines: Array[String] = []
	var tries: Array[String] = []
	for page in LifePassport.skills():
		var l := LifePassport.summary_line(profile.life, str(page.id))
		if l != "":
			lines.append(l)
			tries.append(LifeExperience.words(str(page.experience), str(page.track), "try_real", r))
	if not lines.is_empty():
		_heading(list, "Before and after")
		for l in lines:
			_line(list, "•  " + l)
		_heading(list, "Try it for real, together")
		for t in tries:
			_line(list, "•  " + t)
	for section: Array in SuccessPlaces.grown_ups(profile, today):   # owner #115: the goal, the habit, people, stories
		_heading(list, str(section[0]))
		for l: Variant in section[1]:
			_line(list, "•  " + str(l))
	_heading(list, "Good to know")
	_line(list, LifeExperience.PRACTICE_NOTE + " Little Lifesaver, Fire Escape and My Money Stall follow the IFRC and ERC first aid guidelines, the fire services' advice (NFPA, the US Fire Administration, the UK fire and rescue services) and the OECD/INFE and EU money frameworks.")
	_line(list, DANGER_SOURCES)   # Life L3a (owner #118)
	_line(list, DANGER_SOURCES_L3B)   # Life L3b (owner #118)
	_line(list, SOURCES_L3C)   # Life L3c (owner #112, #118)
	_line(list, PRIVACY)


func show_settings() -> void:
	tab = "settings"
	OnlineUi.clear(body)
	region_buttons.clear()
	track_buttons.clear()
	lock_buttons.clear()
	careful_buttons.clear()
	intensity_buttons.clear()
	var tracks := HBoxContainer.new()
	tracks.alignment = BoxContainer.ALIGNMENT_CENTER
	tracks.add_theme_constant_override("separation", 10)
	tracks.add_child(_label("Track", 120))
	for t in LifeData.TRACKS:
		var b := SchoolUi.button(LifeCatalog.track_words(t), Color(), Vector2(200, 50))
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(set_track.bind(t))
		track_buttons[t] = b
		tracks.add_child(b)
	body.add_child(tracks)
	var lock := HBoxContainer.new()
	lock.alignment = BoxContainer.ALIGNMENT_CENTER
	lock.add_theme_constant_override("separation", 10)
	lock.add_child(_label("Only a grown-up changes the track", 460))
	for on: bool in [true, false]:
		var b := SchoolUi.button("ON" if on else "OFF", Color(), Vector2(120, 50))
		b.toggle_mode = true
		b.pressed.connect(set_locked.bind(on))
		lock_buttons[on] = b
		lock.add_child(b)
	body.add_child(lock)
	var where := _label("Region: the emergency number the Experiences dial, and which side cars drive on", 1100)
	where.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(where)
	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 6)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var auto := SchoolUi.button("THIS DEVICE", Color(), Vector2(180, 46))
	auto.toggle_mode = true
	auto.add_theme_font_size_override("font_size", 17)
	auto.pressed.connect(set_region.bind(""))
	region_buttons[""] = auto
	grid.add_child(auto)
	for id in LifeRegion.ids():
		var b := SchoolUi.button("%s %s" % [LifeRegion.region_name(id).trim_prefix("the ").to_upper().left(14),
			LifeRegion.number(id)], Color(), Vector2(180, 46))
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 15)
		b.pressed.connect(set_region.bind(id))
		region_buttons[id] = b
		grid.add_child(b)
	body.add_child(grid)
	var now := _label("", 1100)
	now.name = "RegionNow"
	now.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(now)
	var careful := HBoxContainer.new()
	careful.alignment = BoxContainer.ALIGNMENT_CENTER
	careful.add_theme_constant_override("separation", 8)
	for topic in LifeData.CAREFUL_TOPICS:
		var b := SchoolUi.button(str(CAREFUL_WORDS[topic]), Color(), Vector2(206, 48))
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 16)
		b.toggled.connect(func(on: bool) -> void: set_careful(topic, on))
		careful_buttons[topic] = b
		careful.add_child(b)
	body.add_child(careful)
	var note := SchoolUi.words(CAREFUL_NOTE, 17, SchoolUi.FRAME.x - 40)
	note.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	body.add_child(note)
	_refresh()


## Life L3a (owner #118, design §14): SAFETY: how real the dangerous Experiences feel (GENTLE by default; MORE REAL only
## on the Big track), what it changes, and what a safe mistake is.
func show_safety() -> void:
	tab = "safety"
	OnlineUi.clear(body)
	region_buttons.clear()
	track_buttons.clear()
	lock_buttons.clear()
	careful_buttons.clear()
	intensity_buttons.clear()
	var title := SchoolUi.words("How real the dangers feel", 26, SchoolUi.FRAME.x - 60)
	title.add_theme_color_override("font_color", SchoolUi.GOLD)
	body.add_child(title)
	var level := HBoxContainer.new()
	level.alignment = BoxContainer.ALIGNMENT_CENTER
	level.add_theme_constant_override("separation", 14)
	for i: String in LifeData.INTENSITIES:
		var b := SchoolUi.button(str(INTENSITY_WORDS[i]), Color(), Vector2(260, 60))
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(set_intensity.bind(i))
		intensity_buttons[i] = b
		level.add_child(b)
	body.add_child(level)
	for t: String in [INTENSITY_NOTE, SAFE_MISTAKE_NOTE]:
		var l := SchoolUi.words(t, 20, SchoolUi.FRAME.x - 60)
		l.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
		body.add_child(l)
	_refresh()


## Life L3a: GENTLE (the default) or REAL ("more real", used only on the Big track).
func set_intensity(i: String) -> void:
	if not LifeData.INTENSITIES.has(i):
		return
	profile.life.intensity = i
	save_profile.call()
	_refresh()


func set_track(t: String) -> void:
	if not LifeData.valid_track(t):
		return
	profile.life.track = t
	save_profile.call()
	_refresh()


func set_locked(on: bool) -> void:
	profile.life.track_locked = on
	save_profile.call()
	_refresh()


## "" = this device's region (its locale).
func set_region(id: String) -> void:
	profile.life.region = id if LifeRegion.valid(id) else ""
	save_profile.call()
	_refresh()


func set_careful(topic: String, on: bool) -> void:
	if profile.life.careful_on(topic) == on:
		return
	profile.life.set_careful(topic, on)
	save_profile.call()


func _refresh() -> void:
	for t: String in track_buttons:
		(track_buttons[t] as Button).set_pressed_no_signal(profile.life.track == t)
	for on: bool in lock_buttons:
		(lock_buttons[on] as Button).set_pressed_no_signal(profile.life.track_locked == on)
	for id: String in region_buttons:
		(region_buttons[id] as Button).set_pressed_no_signal(profile.life.region == id)
	for topic: String in careful_buttons:
		(careful_buttons[topic] as Button).set_pressed_no_signal(profile.life.careful_on(topic))
	for i: String in intensity_buttons:
		(intensity_buttons[i] as Button).set_pressed_no_signal(profile.life.intensity == i)
	var now := find_child("RegionNow", true, false) as Label
	if now:
		var r := region()
		now.text = "Now: %s. Emergency number %s. Cars drive on the %s (look %s)." % [LifeRegion.region_name(r),
			LifeRegion.number(r), LifeRegion.drive(r), LifeRegion.look_order(r)]


func _heading(list: Control, text: String) -> void:
	var l := SchoolUi.words(text, 24, SchoolUi.FRAME.x - 60)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.add_theme_color_override("font_color", SchoolUi.GOLD)
	list.add_child(l)


func _line(list: Control, text: String) -> void:
	var l := SchoolUi.words(text, 19, SchoolUi.FRAME.x - 60)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	list.add_child(l)


func _label(text: String, width: float) -> Label:
	var l := SchoolUi.words(text, 20, width)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return l
