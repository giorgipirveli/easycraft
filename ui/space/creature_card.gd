class_name CreatureCard
extends QuestOverlay
## A robot's or an alien's card on a space world (owner #86, spec §21f), opened by a tap on it (SpaceCreatures): its
## name, what it says (short, kind lines, read aloud by the speaker button for children who don't read yet), and big
## buttons (LET'S GO, GIVE A SAMPLE, COME ALONG, a souvenir to buy...), or a question with three answers (the robot's
## science quest: "Not yet!" and a hint, never a failure). Nothing counts down. A finger outside the box, Esc or
## Back closes it (QuestOverlay); a PC shows its pointer to click (the next click looks around again).

## A button: {"text", "color" (UiKit's), "call": Callable, "name"?, "disabled"?}.
var spoken := ""
var title_label: Label
var choice_buttons: Array[Button] = []
var buttons: Array[Button] = []


func _init() -> void:
	name = "CreatureCard"
	box_width = 860.0


## Shows a page: `title`, `lines` (each a paragraph; the first in gold when `lead`), `rows` of buttons (each row an
## Array of button dictionaries).
func show_page(title: String, lines: Array, rows: Array = [], lead := false) -> void:
	clear()
	choice_buttons.clear()
	buttons.clear()
	spoken = " ".join(PackedStringArray(lines.map(func(l: Variant) -> String: return tr(str(l)))))
	var head := row(16)
	title_label = words(tr(title), 34, 0.0, GOLD)
	head.add_child(title_label)
	head.add_child(ReadAloud.button(func() -> String: return spoken))
	content.add_child(head)
	for i in lines.size():
		content.add_child(words(tr(str(lines[i])), 25, box_width - 60.0, GOLD if lead and i == 0 else Color.WHITE))
	for r: Variant in rows:
		var line := row(14)
		for b: Dictionary in r:
			line.add_child(_button(b))
		content.add_child(line)
	_open()


## Shows a question: `title`, words before it, the question and its three answers (on_pick(i) hears a tap).
func show_question(title: String, before: Array, question: String, choices: Array, on_pick: Callable) -> void:
	show_page(title, before + [question], [])
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	for i in choices.size():
		var b := button(tr(str(choices[i])), UiKit.BLUE, Vector2(640, 72), "Choice%d" % i)
		b.pressed.connect(on_pick.bind(i))
		choice_buttons.append(b)
		col.add_child(b)
	content.add_child(col)


## A line under the page (an answer's words), in gold or the hint's colour.
func add_line(text: String, gold := true) -> Label:
	var l := words(tr(text), 25, box_width - 60.0, GOLD if gold else HINT)
	content.add_child(l)
	spoken += " " + tr(text)
	return l


## A row of buttons under the page.
func add_buttons(list: Array) -> void:
	var line := row(14)
	for b: Dictionary in list:
		line.add_child(_button(b))
	content.add_child(line)


## The button whose text is `text` (tests), or null.
func button_named(text: String) -> Button:
	for b in buttons + choice_buttons:
		if b.text == text or b.text == tr(text):
			return b
	return null


func _button(b: Dictionary) -> Button:
	var text := tr(str(b.get("text", "OK")))
	var size := Vector2(maxf(220.0, 26.0 * text.length() * 0.62 + 60.0), 80)
	var btn := button(text, b.get("color", UiKit.GREEN), size, str(b.get("name", text.replace(" ", ""))))
	btn.disabled = bool(b.get("disabled", false))
	var call: Variant = b.get("call")
	if call is Callable and (call as Callable).is_valid():
		btn.pressed.connect(call)
	else:
		btn.pressed.connect(close)
	buttons.append(btn)
	return btn


func _open() -> void:
	show_overlay()
	if PlatformRules.captures_mouse(PlatformRules.current()) and is_inside_tree() and DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	ReadAloud.auto(spoken)
