class_name LifePassportPage
extends VBoxContainer
## Owner #112 (docs/design/life-skills.md §3 step 7, §7): the Life Passport, a book like the Secret Book: a page per
## skill (every Experience on every track) with its three stamps (Done it, By myself, Expert: what the child can do, never
## paid for themselves). A tap opens the skill's page: its stamps, its "name it" card and its Try it for real card. A
## skill due for a repeat says "practise again". Fits SchoolUi.FRAME; read aloud by its speakers. Life L2: a book of pages,
## PER_PAGE Experiences a page (L1's three, L2's three, and more as Life grows), turned with NEXT PAGE and PREVIOUS PAGE.

signal closed

const PAPER := Color("f3e6c8")
const PER_PAGE := 3
const INK := Color("3b2a18")

var profile: ProfileData
var region := LifeRegion.DEFAULT
var today := 0
var showing := ""
var book_page := 0


func _init(p: ProfileData, region_id: String, day: int) -> void:
	profile = p
	region = region_id
	today = day
	name = "LifePassportPage"
	add_theme_constant_override("separation", 10)
	custom_minimum_size.x = SchoolUi.FRAME.x


func _ready() -> void:
	show_book()


func stamp_count() -> int:
	var n := 0
	for page in LifePassport.skills():
		var s := LifePassport.stamps(profile.life, str(page.id))
		for bit: int in [LifeData.DONE, LifeData.SELF, LifeData.EXPERT]:
			if s & bit:
				n += 1
	return n


func pages() -> int:
	return ceili(float(LifeExperience.IDS.size()) / PER_PAGE)


func show_book(page_index: int = -1) -> void:
	if page_index >= 0:
		book_page = clampi(page_index, 0, pages() - 1)
	showing = ""
	OnlineUi.clear(self)
	var n := stamp_count()
	add_child(_header("My Life Passport: %d stamp%s" % [n, "" if n == 1 else "s"], func() -> void: closed.emit()))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	grid.add_child(Control.new())
	for t in LifeData.TRACKS:
		var head := SchoolUi.words("%s (%s)" % [LifeCatalog.track_words(t), LifeCatalog.track_ages(t)], 18, 300)
		grid.add_child(head)
	for exp_id in LifeExperience.IDS.slice(book_page * PER_PAGE, (book_page + 1) * PER_PAGE):
		var who := HBoxContainer.new()
		who.custom_minimum_size = Vector2(190, 0)
		who.add_child(LifeIcons.new(str(LifeCatalog.area(str(LifeExperience.data(exp_id).area)).get("icon", "passport")), 48.0))
		var l := SchoolUi.words(LifeExperience.title(exp_id), 20, 136)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		who.add_child(l)
		grid.add_child(who)
		for t in LifeData.TRACKS:
			grid.add_child(_skill_button(exp_id, t))
	add_child(grid)
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", 20)
	if book_page > 0:
		var prev := SchoolUi.button("PREVIOUS PAGE", Color(0.2, 0.24, 0.36), Vector2(250, 56))
		prev.name = "PreviousPage"
		prev.add_theme_font_size_override("font_size", 20)
		prev.pressed.connect(show_book.bind(book_page - 1))
		foot.add_child(prev)
	var note := SchoolUi.words("Done it: with the coach's help. By myself: no help at all. Expert: the harder try. (Page %d of %d)"
		% [book_page + 1, pages()], 18, 620)
	note.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	foot.add_child(note)
	if book_page < pages() - 1:
		var next := SchoolUi.button("NEXT PAGE", Color(0.2, 0.24, 0.36), Vector2(220, 56))
		next.name = "NextPage"
		next.add_theme_font_size_override("font_size", 20)
		next.pressed.connect(show_book.bind(book_page + 1))
		foot.add_child(next)
	add_child(foot)


func _skill_button(exp_id: String, t: String) -> Button:
	var skill := LifeExperience.skill_id(exp_id, t)
	var b := SchoolUi.button("", Color(0.32, 0.25, 0.16) if LifePassport.stamps(profile.life, skill) else Color(0.2, 0.22, 0.3),
		Vector2(300, 140))
	b.name = "Skill_" + skill.replace(".", "_")
	b.pressed.connect(show_skill.bind(skill))
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 4)
	b.add_child(col)
	var title := SchoolUi.words(str(LifeExperience.track_data(exp_id, t).get("skill", "")), 19, 280)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(title)
	col.add_child(LifeCards.stamps_row(LifePassport.stamps(profile.life, skill), 46.0, false))
	if LifePassport.repeat_due(profile.life, skill, today):
		var due := SchoolUi.words("practise again", 15, 280)
		due.add_theme_color_override("font_color", SchoolUi.GOOD)
		col.add_child(due)
	return b


## A skill's page: its stamps, the "name it" card, Try it for real.
func show_skill(skill: String) -> void:
	var parts := LifeExperience.of_skill(skill)
	if parts.is_empty():
		return
	showing = skill
	OnlineUi.clear(self)
	add_child(_header("%s: %s" % [LifeExperience.title(parts[0]), str(LifeExperience.track_data(parts[0], parts[1]).get(
		"skill", ""))], show_book.bind(book_page)))
	var s := LifePassport.stamps(profile.life, skill)
	add_child(LifeCards.stamps_row(s, 84.0))
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	row.add_child(LifeCards.name_it(LifeExperience.card(parts[0], parts[1], region), 540.0))
	row.add_child(LifeCards.try_real(LifeExperience.words(parts[0], parts[1], "try_real", region), 520.0))
	add_child(row)
	if s == 0:
		var hint := SchoolUi.words("Not stamped yet: open its unit in Life and press TRY IT.", 22, 1000)
		hint.add_theme_color_override("font_color", SchoolUi.HINT)
		add_child(hint)


func _header(title: String, back: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var b := SchoolUi.button("BACK", UiKit.BLUE, Vector2(150, 64))
	b.pressed.connect(back)
	row.add_child(b)
	row.add_child(LifeIcons.new("passport", 60.0))
	var label := SchoolUi.fit_title(title, SchoolUi.FRAME.x - 150.0 - 60.0 - 80.0 - 48.0)
	var titled := ReadAloud.with_speaker(label, self)
	titled.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(titled)
	return row
