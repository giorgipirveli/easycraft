class_name ToolBookPage
extends VBoxContainer
## Owner #117 (docs/design/life-skills.md §13, "The Tool Book"; §11): a book like the Life Passport: every tool and device
## a child can learn, by area (Building and making, Fixing at home, Kitchen ...), each with its picture and its three
## stamps (Done it, By myself, Expert: ProfileData.tools). "You can use 7 tools" counts the ones used by the child alone
## (what a parent sees). A tap opens a tool's page: what it is for, how to hold it, its motion (in VR and on a phone),
## its safety rule (a grown-up's job in real life says so), and a device's right order and safety steps. Fits
## SchoolUi.FRAME; read aloud by its speakers.

signal closed

const CARD := Vector2(176, 150)

var profile: ProfileData
var showing := ""
var scroll: ScrollContainer


func _init(p: ProfileData) -> void:
	profile = p
	name = "ToolBookPage"
	add_theme_constant_override("separation", 10)
	custom_minimum_size.x = SchoolUi.FRAME.x


func _ready() -> void:
	show_book()


## "You can use N tools" (by yourself at least once).
func headline() -> String:
	var n := profile.tools.can_use()
	return "My Tool Book: you can use %d tool%s" % [n, "" if n == 1 else "s"]


func show_book() -> void:
	showing = ""
	OnlineUi.clear(self)
	add_child(_header(headline(), func() -> void: closed.emit(), "tool"))
	scroll = ScrollContainer.new()
	scroll.name = "Areas"
	scroll.custom_minimum_size = Vector2(SchoolUi.FRAME.x, SchoolUi.FRAME.y - 150)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 8)
	col.custom_minimum_size.x = SchoolUi.FRAME.x - 24
	scroll.add_child(col)
	for area in ToolBook.AREAS:
		var title := SchoolUi.words(ToolBook.area_title(area), 24, SchoolUi.FRAME.x - 40)
		title.name = "Area_" + area
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		title.add_theme_color_override("font_color", SchoolUi.GOLD)
		col.add_child(title)
		var flow := HFlowContainer.new()
		flow.add_theme_constant_override("h_separation", 10)
		flow.add_theme_constant_override("v_separation", 10)
		flow.custom_minimum_size.x = SchoolUi.FRAME.x - 40
		for id in ToolBook.of_area(area):
			flow.add_child(_tool_button(id))
		col.add_child(flow)
	var note := SchoolUi.words("Done it: with the coach's help. By myself: no help at all. Expert: the harder try.", 20, 1100)
	note.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	add_child(note)


func _tool_button(id: String) -> Button:
	var stamps := profile.tools.stamps_of(id)
	var b := SchoolUi.button("", Color(0.32, 0.25, 0.16) if stamps else Color(0.2, 0.22, 0.3), CARD)
	b.name = "Tool_" + id
	b.pressed.connect(show_tool.bind(id))
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	col.add_theme_constant_override("separation", 2)
	b.add_child(col)
	var pic := ToolIcons.new(ToolBook.icon(id), 58.0)
	pic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(pic)
	var title := SchoolUi.words(_name(id), 16, CARD.x - 10)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(title)
	var row := LifeCards.stamps_row(stamps, 26.0, false)
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(row)
	return b


## A tool's page: its picture and stamps, what it is for, how to hold it, its motion, its safety rule; a device's order.
func show_tool(id: String) -> void:
	if not ToolBook.has(id):
		return
	showing = id
	OnlineUi.clear(self)
	var e := ToolBook.entry(id)
	add_child(_header(_name(id), show_book, ToolBook.icon(id)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 8)
	left.add_child(ToolIcons.new(ToolBook.icon(id), 150.0))
	left.add_child(LifeCards.stamps_row(profile.tools.stamps_of(id), 54.0))
	row.add_child(left)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	for line: String in lines(id):
		var l := SchoolUi.words(line, 22, 820)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		right.add_child(l)
	if bool(e.get("grown_up", false)):
		var g := SchoolUi.words("In real life this is a grown-up's job.", 22, 820)
		g.name = "GrownUpsJob"
		g.add_theme_color_override("font_color", SchoolUi.GOLD)
		right.add_child(g)
	row.add_child(right)
	add_child(row)


## A tool's page in words (read aloud): what it is for, how to hold it, its motions, its safety rule, a device's order.
static func lines(id: String) -> Array[String]:
	var e := ToolBook.entry(id)
	var out: Array[String] = ["It is for %s." % str(e.get("for", "")), "How: %s" % str(e.get("hold", ""))]
	for m in ToolBook.motions(id):
		var how: Dictionary = ToolMotion.HOW.get(m, {})
		out.append("%s: in VR, %s; on a phone, %s." % [how.get("name", m), how.get("vr", ""), how.get("phone", "")])
	out.append("Safety: %s" % str(e.get("safety", "")))
	var dev := ToolBook.device(id)
	if not dev.is_empty():
		var d := ToolDevice.from(dev, id)
		var order: Array[String] = []
		for o in d.order:
			order.append(str(o.words))
		out.append("The right order: %s." % ", then ".join(PackedStringArray(order)))
	return out


static func _name(id: String) -> String:
	var n := ToolBook.name_of(id)
	return n.substr(0, 1).to_upper() + n.substr(1)


func _header(title: String, back: Callable, icon: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var b := SchoolUi.button("BACK", UiKit.BLUE, Vector2(150, 64))
	b.name = "Back"
	b.pressed.connect(back)
	row.add_child(b)
	row.add_child(ToolIcons.new(icon, 60.0))
	var label := SchoolUi.fit_title(title, SchoolUi.FRAME.x - 150.0 - 60.0 - 80.0 - 48.0)
	var titled := ReadAloud.with_speaker(label, self)
	titled.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(titled)
	return row
