class_name StoryShelfPage
extends SuccessPage
## Owner #115 (docs/design/success-skills.md §2.7; the brief: "twenty short read-aloud stories of real people who built
## things ... 'Which skill did they use?' questions"): THE STORY SHELF in the Life tab's Success stories. A shelf of the
## twenty true stories (PER_PAGE a page; a tick on the ones read), each read one line at a time, aloud (on the Little
## track by itself; a speaker on every page), with the story's symbol (never a portrait), the person's years and country
## and job; then "Which skill did they use?" with three picture answers in a mixed order: a right one is praised for the
## skill, any other gets its kind "why" and the child tries again. Where the facts come from is said on the question's
## page (the sources' sites). Reading pays no gold (like reading a lesson): the stories are for the stories.

const PER_PAGE := 10

var shelf_page := 0
var story_id := ""
var line := 0
var tries := 0


func _init(p: ProfileData, save: Callable, day: int, region_id: String, track_id: String) -> void:
	super(p, save, day, region_id, track_id)
	name = "StoryShelfPage"


func _ready() -> void:
	show_shelf()


func pages() -> int:
	return ceili(float(SuccessStories.list().size()) / PER_PAGE)


func show_shelf(page_index: int = -1) -> void:
	if page_index >= 0:
		shelf_page = clampi(page_index, 0, pages() - 1)
	clear()
	var d := data()
	var title := "Success Stories: %d of %d read" % [SuccessStories.read_count(d), SuccessStories.list().size()]
	header(title, func() -> void: closed.emit())
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for s in SuccessStories.list().slice(shelf_page * PER_PAGE, (shelf_page + 1) * PER_PAGE):
		var b := LifeCards.picture_button("%s: %s" % [str(s.name), str(s.title)], str(s.icon), Color("4a6fc2").darkened(0.2),
			Vector2(214, 228), 18)
		b.name = "Story_" + str(s.id)
		b.pressed.connect(show_story.bind(str(s.id)))
		if d.story_read(str(s.id)):
			var tick := LifeIcons.new("tick", 40.0)
			tick.name = "Read"
			tick.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
			tick.offset_left = -46
			tick.offset_right = -6
			tick.offset_top = 6
			tick.offset_bottom = 46
			b.add_child(tick)
		grid.add_child(b)
	add_child(grid)
	var foot := centred_row(18)
	if shelf_page > 0:
		foot.add_child(small("PREVIOUS PAGE", show_shelf.bind(shelf_page - 1), 250))
	if shelf_page < pages() - 1:
		foot.add_child(small("NEXT PAGE", show_shelf.bind(shelf_page + 1), 220))
	add_child(foot)
	say(title + ". Pick a story.")


func show_story(id: String, at_line: int = 0) -> void:
	var s := SuccessStories.story(id)
	if s.is_empty():
		show_shelf()
		return
	story_id = id
	var lines: Array = s.lines
	line = clampi(at_line, 0, lines.size() - 1)
	clear()
	header(str(s.title), show_shelf.bind(shelf_page), [],
		func() -> String: return ". ".join(PackedStringArray(lines.map(func(l: Variant) -> String: return str(l)))))
	var body := centred_row(30)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	left.add_child(LifeIcons.new(str(s.icon), 200.0))
	left.add_child(SchoolUi.words(str(s.name), 24, 300))
	var who := SchoolUi.words("%s, %s. %s." % [str(s.job), str(s.country), str(s.life)], 18, 300)
	who.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	left.add_child(who)
	body.add_child(left)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 14)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	var words := left_words(str(lines[line]), 32, 700)
	words.name = "StoryLine"
	right.add_child(words)
	var count := left_words("%d of %d" % [line + 1, lines.size()], 18, 700)
	count.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	right.add_child(count)
	body.add_child(right)
	add_child(body)
	UiMotion.pop_in(words)
	var foot := centred_row(24)
	if line > 0:
		foot.add_child(small("PREVIOUS", show_story.bind(id, line - 1), 220, UiKit.BLUE))
	var next := SchoolUi.button("NEXT", UiKit.GREEN, Vector2(260, 76))
	next.pressed.connect(show_story.bind(id, line + 1) if line < lines.size() - 1 else show_question.bind(id))
	foot.add_child(next)
	add_child(foot)
	say(str(lines[line]))


func show_question(id: String) -> void:
	var s := SuccessStories.story(id)
	story_id = id
	tries = 0
	clear()
	var q := SuccessStories.question(s)
	header("Which skill?", show_story.bind(id, (s.lines as Array).size() - 1))
	var row := centred_row(18)
	row.add_child(SchoolUi.teacher(100.0))
	row.add_child(left_words(str(q.say), 28, 860))
	add_child(row)
	var answers := centred_row(22)
	answers.name = "Answers"
	var choices: Array = q.choices
	var order: Array = range(choices.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([today, id])
	GenKit.shuffle(rng, order)
	for i: int in order:
		var c: Dictionary = choices[i]
		var b := LifeCards.picture_button(str(c.text), str(c.get("icon", "question")), Color(0.16, 0.22, 0.36), Vector2(330, 230),
			22 if str(c.text).length() < 26 else 19)
		b.name = "Answer%d" % i   # by the data's order (the right one is 0), wherever it is shown
		b.pressed.connect(_answer.bind(id, i))
		answers.add_child(b)
	add_child(answers)
	var said := SchoolUi.words("", 24, 1000)
	said.name = "Said"
	add_child(said)
	var from := SchoolUi.words("Facts checked with: " + _sites(s), 16, 1000)
	from.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	add_child(from)
	say(str(q.say))


func _answer(id: String, i: int) -> void:
	var s := SuccessStories.story(id)
	var q := SuccessStories.question(s)
	var said := find_child("Said", true, false) as Label
	tries += 1
	if i == int(q.answer):
		SuccessStories.read(data(), id, today, true)
		save()
		var words := "Yes! %s %s." % [str(s.name), str(SuccessStories.SKILL_WORDS.get(str(s.skill), "did it"))]
		if said:
			said.text = words
			said.add_theme_color_override("font_color", SchoolUi.GOOD)
		for b in find_children("Answer*", "Button", true, false):
			(b as Button).disabled = true
		var foot := centred_row(24)
		foot.add_child(small("MORE STORIES", show_shelf.bind(shelf_page), 260, UiKit.GREEN))
		var next := _next_story(id)
		if next != "":
			foot.add_child(small("NEXT STORY", show_story.bind(next, 0), 240, UiKit.BLUE))
		add_child(foot)
		Audio.play(&"jingle_goal")
		say(words)
	else:
		SuccessStories.read(data(), id, today, false)
		save()
		var why := str(((q.choices as Array)[i] as Dictionary).get("why", "Have another look at the story."))
		if said:
			said.text = why
			said.add_theme_color_override("font_color", SchoolUi.HINT)
		var b := find_child("Answer%d" % i, true, false) as Button
		if b:
			b.disabled = true
		say(why)


func _next_story(id: String) -> String:
	var list := SuccessStories.list()
	for i in list.size():
		if str(list[i].id) == id and i + 1 < list.size():
			return str(list[i + 1].id)
	return ""


## The sources' sites ("nobelprize.org, britannica.com"): where the story's facts were checked.
static func _sites(s: Dictionary) -> String:
	var out: Array[String] = []
	for src: Variant in s.get("sources", []):
		var url := str((src as Dictionary).get("url", "")) if src is Dictionary else ""
		var host := url.trim_prefix("https://").split("/")[0].trim_prefix("www.")
		if host != "" and not out.has(host):
			out.append(host)
	return ", ".join(PackedStringArray(out))
