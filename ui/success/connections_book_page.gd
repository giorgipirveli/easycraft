class_name ConnectionsBookPage
extends SuccessPage
## Owner #115 (docs/design/success-skills.md §2.3; the brief: "the worlds' people with names, jobs, wishes and needs ...;
## meet them, remember them in the book ...; their warmth grows (never a public score); new chances open; mentors teach
## a skill when asked politely; people different from you"): MY CONNECTIONS BOOK in the Life tab's Connections area.
## A page of people (PER_PAGE a page): the ones met with their faces, names and jobs (a card that glows warmer as they
## trust the child more: no number anywhere), the others as "Not met yet". A person's page: their place, what they wish
## for and need, what they offer, who could help them, how they differ from many children, their warmth in words, the
## help and promises kept, a mentor's tip, the new chance they told the child about. CHANCES AND TIPS lists them all.
## The book is the child's own (in the profile and its backup only): nobody else sees it.

const PER_PAGE := 8
const NOT_MET := "Not met yet"
const CHANCES := "CHANCES AND TIPS"
const NO_CHANCES := "When people trust you, they tell you about new chances. Help first, and keep your promises!"
const COOL := Color(0.2, 0.3, 0.45)
const WARM := Color("c98a2b")

var book_page := 0


func _init(p: ProfileData, save: Callable, day: int, region_id: String, track_id: String) -> void:
	super(p, save, day, region_id, track_id)
	name = "ConnectionsBookPage"


func _ready() -> void:
	show_book()


func pages() -> int:
	return ceili(float(SuccessPeople.list().size()) / PER_PAGE)


func show_book(page_index: int = -1) -> void:
	if page_index >= 0:
		book_page = clampi(page_index, 0, pages() - 1)
	clear()
	var n := SuccessPeople.met_count(data())
	header("My Connections Book: you know %d %s" % [n, "person" if n == 1 else "people"], func() -> void: closed.emit())
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 10)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for p in SuccessPeople.list().slice(book_page * PER_PAGE, (book_page + 1) * PER_PAGE):
		grid.add_child(_card(p))
	add_child(grid)
	var foot := centred_row(18)
	if book_page > 0:
		foot.add_child(small("PREVIOUS PAGE", show_book.bind(book_page - 1), 250))
	foot.add_child(small(CHANCES, show_chances, 280, Color("2f7f6a")))
	if book_page < pages() - 1:
		foot.add_child(small("NEXT PAGE", show_book.bind(book_page + 1), 220))
	add_child(foot)
	say("Your Connections Book. You know %d %s." % [n, "person" if n == 1 else "people"])


func _card(p: Dictionary) -> Button:
	var id := str(p.id)
	var d := data()
	var met := d.met(id)
	var warmth := float(d.person(id).w) / SuccessData.MAX_WARMTH
	var b := LifeCards.picture_button("%s, %s" % [str(p.name), str(p.job)] if met else NOT_MET,
		"person_" + id if met else "question", COOL.lerp(WARM, warmth) if met else Color(0.16, 0.18, 0.24), Vector2(270, 200), 19)
	b.name = "Person_" + id
	b.disabled = not met
	b.pressed.connect(show_person.bind(id))
	return b


func show_person(id: String) -> void:
	var p := SuccessPeople.person(id)
	var d := data()
	var x := d.person(id)
	clear()
	header("%s, %s" % [str(p.name), str(p.job)], show_book.bind(book_page))
	var body := centred_row(26)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.add_child(LifeIcons.new("person_" + id, 190.0))
	var warm := SchoolUi.words(SuccessPeople.warmth_words(id, int(x.w)), 22, 260)
	warm.add_theme_color_override("font_color", SchoolUi.GOLD)
	left.add_child(warm)
	body.add_child(left)
	var lines: Array[String] = ["At %s. %s" % [str(p.place), str(p.get("hello", ""))],
		"Wishes for: %s." % str(p.wish), "Needs: %s." % str(p.needs), "Offers: %s." % str(p.offers)]
	var helper := str(p.get("helped_by", ""))
	if helper != "":
		lines.append("Who could help: %s." % (SuccessPeople.name_of(helper) + ", " + str(SuccessPeople.person(helper).job)
			if d.met(helper) else "someone in the village you haven't met yet"))
	if str(p.get("different", "")) != "":
		lines.append(str(p.different))
	var done: Array[String] = []
	if int(x.h) > 0:
		done.append("you helped %s %d time%s" % [str(p.name), int(x.h), "" if int(x.h) == 1 else "s"])
	if int(x.p) > 0:
		done.append("you kept %d promise%s" % [int(x.p), "" if int(x.p) == 1 else "s"])
	if int(x.i) > 0:
		done.append("you made %d introduction%s" % [int(x.i), "" if int(x.i) == 1 else "s"])
	if not done.is_empty():
		var said := ", ".join(PackedStringArray(done))
		lines.append(said.left(1).to_upper() + said.substr(1) + ".")
	if bool(x.t) and str(p.get("tip", "")) != "":
		lines.append("%s taught you: %s" % [str(p.name), str(p.tip)])
	if int(x.w) >= SuccessPeople.CHANCE_AT and str(p.get("chance", "")) != "":
		lines.append(str(p.chance))
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 6)
	for l in lines:
		right.add_child(left_words(l, 21, 760))
	body.add_child(right)
	add_child(body)
	say(". ".join(PackedStringArray(lines)))


func show_chances() -> void:
	clear()
	header("Chances and tips", show_book.bind(book_page))
	var d := data()
	var chances := SuccessPeople.chances(d)
	var tips := SuccessPeople.tips(d)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	if chances.is_empty() and tips.is_empty():
		var row := centred_row(18)
		row.add_child(SchoolUi.teacher(120.0))
		row.add_child(left_words(NO_CHANCES, 28, 760))
		col.add_child(row)
	for c in chances:
		col.add_child(left_words("•  " + c, 22, 1100))
	for t in tips:
		col.add_child(left_words("•  " + t, 22, 1100))
	add_child(col)
	var all: Array[String] = []
	all.append_array(chances)
	all.append_array(tips)
	say(NO_CHANCES if all.is_empty() else ". ".join(PackedStringArray(all)))
