class_name StaySafeCard
extends VBoxContainer
## The "stay safe online" card (M4 Wave 1, Agent C; spec §17.2, research must-have): four rules,
## each a picture and a few short words that read well aloud, before the first online game and after
## a long break (OnlineRules.safe_card_due). One big button: I WILL!

signal done

## [picture, words]: short sentences, one idea each.
const RULES: Array = [
	[&"lock", "Keep your real name, home and school a secret."],
	[&"friends", "Play with friends you know in real life."],
	[&"talk", "Something feels bad? Tell a grown-up."],
	[&"heart", "Be kind to everyone."],
]

var ok_button: Button


func _ready() -> void:
	add_theme_constant_override("separation", 16)
	var title := UiKit.title("Stay safe online")
	add_child(ReadAloud.with_speaker(title, self, read_aloud_text))   # M3 Task 21a: read it to me
	ReadAloud.auto(read_aloud_text())
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 26)
	grid.add_theme_constant_override("v_separation", 14)
	for rule: Array in RULES:
		grid.add_child(_rule(rule[0], rule[1]))
	add_child(grid)
	ok_button = OnlineUi.button("I WILL!", UiKit.GREEN, Vector2(340, 96), &"heart")
	ok_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ok_button.pressed.connect(func() -> void: done.emit())
	add_child(ok_button)


## Everything on the card as one text (for read-aloud when the game has it).
static func read_aloud_text() -> String:
	var lines: Array[String] = [Lang.t("Stay safe online.")]
	for rule: Array in RULES:
		lines.append(Lang.t(rule[1]))
	return " ".join(lines)


func _rule(icon: StringName, text: String) -> Control:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	var pic := OnlineIcon.new(icon)
	pic.custom_minimum_size = Vector2(84, 84)
	box.add_child(pic)
	var l := OnlineUi.words(text, 27, 380)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size_flags_vertical = Control.SIZE_FILL
	box.add_child(l)
	return box
