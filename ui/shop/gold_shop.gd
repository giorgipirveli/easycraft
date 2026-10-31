class_name GoldShop
extends VBoxContainer
## Owner #83 (spec §25.5): the GOLD SHOP, from the main menu: what the child's Survivor gold buys, shelf by shelf
## (SpendRules: one price table). EXPLORER LESSONS (open for good; the grade's own lessons are always free), ROCKET PARTS
## (the missions hang them here: SpendRules.register), WEAPONS & TOOLS (into the backpack for the next Survivor world),
## AVATAR & BUDDY, DECORATIONS (the aliens' souvenirs, owner #86; more later). HOW TO EARN lists EarnRules' table: gold comes from learning, never from time.
## A shelf with nothing yet says what is coming. Every page fits the menu's frame (SchoolUi.FRAME).

signal closed

const PER_PAGE := 8
const SHELF := &"shelf"
const EARN := &"earn"

var profile: ProfileData
var save_profile := Callable()
var shelf: StringName = SpendRules.LESSONS
var page_index := 0
var view: StringName = &""
var message: Label
var gold_label: Label
var cards: Array[Button] = []


func _ready() -> void:
	RocketParts.register_shelf()   # the core loop: the missions' parts on the ROCKET PARTS shelf (owner #79, #83)
	ProspectGear.register_shelf()   # spec §26: the Metal Detector on WEAPONS & TOOLS
	AlienRules.register_shelf()   # owner #86: the aliens' souvenirs on the DECORATIONS shelf (spec §21f)
	ColonyRules.register_shelf()   # spec §21c: dome decorations on the DECORATIONS shelf (into the backpack)
	name = "GoldShop"
	add_theme_constant_override("separation", 12)
	custom_minimum_size.x = SchoolUi.FRAME.x
	if profile == null:
		profile = Profile.data
	if not save_profile.is_valid():
		save_profile = Profile.save
	show_shelf(SpendRules.LESSONS)


func show_shelf(s: StringName, page: int = 0) -> void:
	shelf = s
	_clear(SHELF)
	add_child(_header("Gold Shop"))
	var tabs := HBoxContainer.new()
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	tabs.add_theme_constant_override("separation", 10)
	for id: StringName in SpendRules.SHELVES:
		var b := UiKit.big_button(str(SpendRules.SHELF_WORDS[id]), SchoolUi.TEAL if id == s else Color(0.2, 0.24, 0.36),
			Vector2(222, 56))
		b.name = "Shelf_" + String(id)
		b.add_theme_font_size_override("font_size", 19)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART   # owner #101: in VR its words are 24 px: two lines, same width
		b.pressed.connect(show_shelf.bind(id))
		tabs.add_child(b)
	add_child(tabs)
	add_child(OnlineUi.words(str(SpendRules.SHELF_ABOUT.get(s, "")), 22, 1100))
	var items := SpendRules.items(s, profile)
	var pages := maxi(ceili(items.size() / float(PER_PAGE)), 1)
	page_index = clampi(page, 0, pages - 1)
	cards.clear()
	if items.is_empty():
		var soon := OnlineUi.words(str(SpendRules.COMING_WORDS.get(s, "More is on its way.")), 30, 900)
		soon.name = "Coming"
		soon.custom_minimum_size.y = 250
		soon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		soon.add_theme_color_override("font_color", SchoolUi.HINT)
		add_child(soon)
	else:
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 12)
		grid.add_theme_constant_override("v_separation", 12)
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		for it in items.slice(page_index * PER_PAGE, (page_index + 1) * PER_PAGE):
			grid.add_child(_card(it))
		add_child(grid)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 18)
	if page_index > 0:
		var prev := UiKit.big_button("PREVIOUS", UiKit.BLUE, Vector2(220, 64))
		prev.pressed.connect(show_shelf.bind(s, page_index - 1))
		row.add_child(prev)
	if page_index < pages - 1:
		var next := UiKit.big_button("NEXT", UiKit.BLUE, Vector2(200, 64))
		next.pressed.connect(show_shelf.bind(s, page_index + 1))
		row.add_child(next)
	var earn := UiKit.big_button("HOW TO EARN", UiKit.GREEN, Vector2(260, 64))
	earn.pressed.connect(show_earn)
	row.add_child(earn)
	add_child(row)
	message = OnlineUi.words("", 22, 1100)
	message.name = "Message"
	message.add_theme_color_override("font_color", SchoolUi.GOLD)
	add_child(message)


func _card(it: Dictionary) -> Button:
	var owned: bool = it.get("owned", false) == true
	var price := int(it.get("price", 0))
	var b := UiKit.big_button("%s\n%s" % [it.get("name", ""), "YOURS" if owned else "%s gold" % GoldFormat.short(price)],
		Color(0.16, 0.42, 0.3) if owned else Color(0.22, 0.26, 0.4), Vector2(270, 116))
	b.name = "Item_" + str(it.id).replace(":", "_").replace(".", "_")
	b.add_theme_font_size_override("font_size", 21)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.disabled = owned
	b.pressed.connect(buy.bind(str(it.id)))
	cards.append(b)
	return b


## Buys `id` and says what happened; the shelf shows it owned.
func buy(id: String) -> void:
	var cost := SpendRules.price(id, profile)
	var r := SpendRules.buy(profile, id)
	var text := ""
	match r:
		SpendRules.OK:
			save_profile.call()
			Audio.play(&"jingle_badge")
			if id.begins_with("lesson:"):
				text = "Opened for good! Find it in the SCHOOL."
			elif id.begins_with("gear:") or id.begins_with("decor:"):   # spec §21c: dome decorations wait there too
				text = "In your backpack: it comes into your next Survivor world."
			elif id.begins_with("look:"):
				text = "It's yours! Wear it in AVATAR."
			elif id.begins_with("part:"):   # owner #98 (bug 1): where a rocket part went
				text = "It's yours! " + RocketParts.GRANT_WORDS
			else:
				text = "It's yours!"
		SpendRules.NOT_ENOUGH:
			text = "You need %s more gold. Lessons in the SCHOOL earn it!" % GoldFormat.short(cost - profile.survivor_gold)
		SpendRules.OWNED:
			text = "You have it already."
		_:
			text = "That isn't in the shop."
	show_shelf(shelf, page_index)
	message.text = text


## HOW TO EARN: EarnRules' table (what pays now), then BACK to the shelf.
func show_earn() -> void:
	_clear(EARN)
	add_child(_header("How to earn gold"))
	var rows := EarnRules.TABLE.filter(func(r: Dictionary) -> bool: return r.by != "hook")
	var two := rows.size() > 7   # the ways to earn grow (the Daily Mission, prospecting…): two columns to fit the frame
	var list := GridContainer.new()
	list.columns = 2 if two else 1
	list.add_theme_constant_override("h_separation", 24)
	list.add_theme_constant_override("v_separation", 6 if rows.size() <= 15 else 2)   # owner #115: the shop's row joined
	list.name = "EarnList"
	var size := 22 if not two else (17 if rows.size() > 14 else 19)   # owner #112: Life's row joined the list
	for row: Dictionary in rows:
		var l := OnlineUi.words("+%d gold   %s (%s)" % [int(row.gold), row.when, row.limit], size, 538.0 if two else 1100.0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		l.add_theme_color_override("font_color", SchoolUi.GOLD if row.by == "game" else Color.WHITE)
		list.add_child(l)
	add_child(list)
	add_child(OnlineUi.words("Gold never comes from waiting or from time: only from learning, puzzles and friends who learn.",
		22, 1100))
	var back := UiKit.big_button("BACK", UiKit.BLUE, Vector2(220, 64))
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back.pressed.connect(show_shelf.bind(shelf, page_index))
	add_child(back)


func _header(title: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var back := UiKit.big_button("BACK", UiKit.BLUE, Vector2(160, 64))
	back.pressed.connect(func() -> void:
		if view == EARN:
			show_shelf(shelf, page_index)
		else:
			closed.emit())
	row.add_child(back)
	var label := UiKit.title(title, 38)
	var titled := ReadAloud.with_speaker(label, self)
	titled.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(titled)
	gold_label = Label.new()
	gold_label.name = "Gold"
	gold_label.text = "You have %s gold" % GoldFormat.short(profile.survivor_gold)
	gold_label.add_theme_font_size_override("font_size", 26)
	gold_label.add_theme_color_override("font_color", SchoolUi.GOLD)
	gold_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(gold_label)
	return row


func _clear(v: StringName) -> void:
	view = v
	OnlineUi.clear(self)
