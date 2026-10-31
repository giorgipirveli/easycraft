class_name SuccessPage
extends VBoxContainer
## Owner #115 (Success S2): the shared frame of the Success places shown inside the Life screen (the School's frame:
## every page fits SchoolUi.FRAME): a header with BACK, a title read aloud by its speaker, and the page's own controls;
## everything said is read aloud on the Little track (LifeVoice). Subclasses: GoalBoardPage (the Goal Board and the
## habit garden), ConnectionsBookPage, StoryShelfPage. `closed` goes back to the Life map's area.

signal closed

var profile: ProfileData
var save_profile := Callable()
var today := 0
var region := LifeRegion.DEFAULT
var track := "middle"
## Owner #115 (S3): (exp_id) -> TRY IT of that Experience on the child's track (the Life screen sets it: MY SHOP opens
## the shop's day, THE PRICE BOARD the market's try).
var try_it := Callable()


func _init(p: ProfileData, save: Callable, day: int, region_id: String, track_id: String) -> void:
	profile = p
	save_profile = save
	today = day
	region = region_id
	track = track_id
	add_theme_constant_override("separation", 10)


func data() -> SuccessData:
	return profile.life.success


func save() -> void:
	if save_profile.is_valid():
		save_profile.call()


func say(text: String) -> void:
	LifeVoice.say(text, track)


## Empties the page at once (tests look at the new one in the same frame).
func clear() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()


func header(title: String, back: Callable, extra: Array = [], text: Callable = Callable()) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var b := SchoolUi.button("BACK", UiKit.BLUE, Vector2(150, 64))
	b.pressed.connect(back)
	row.add_child(b)
	var room := SchoolUi.FRAME.x - 150.0 - 16.0 * (2 + extra.size()) - 70.0
	for c: Control in extra:
		room -= c.custom_minimum_size.x
	var titled := ReadAloud.with_speaker(SchoolUi.fit_title(title, room), self, text)
	titled.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(titled)
	for c: Control in extra:
		c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(c)
	add_child(row)
	return row


func small(text: String, action: Callable, width: float = 220.0, colour: Color = Color(0.2, 0.24, 0.36)) -> Button:
	var b := SchoolUi.button(text, colour, Vector2(width, 56))
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(action)
	return b


func left_words(text: String, font_size: int, width: float) -> Label:
	var l := SchoolUi.words(text, font_size, width)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	return l


func paper(width: float) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.1, 0.17, 0.72), 20, 16))
	p.custom_minimum_size.x = width
	return p


func centred_row(separation: int = 18) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", separation)
	return row
