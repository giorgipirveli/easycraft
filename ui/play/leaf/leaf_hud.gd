class_name LeafHud
extends PlayHud
## Owner #133, #134 (docs/design/games/leaf-voyage.md §3.5 step 11, §3.8 "Words on the screen during play: none", §4.4;
## the B2 brief): what the child sees over a voyage: G0's PlayHud (Professor Hoot and the big ear that says his line
## again, the eye that is SHOW ME, two bars that are a break with CARRY ON and STOP FOR NOW, Android Back's "Leave the
## game?", the panel on the raised forearm in VR) without its exercise row (the place answers by itself: no test button,
## no NEXT), plus the camera button (the avatar's eyes, or over its shoulder), the end card (the plant, the unit's stars,
## the gold, and three pictures: again, the voyage board, a door) and the voyage board (the sunflower and the cactus, a
## lock on one not open yet). With the voice on (everyone's, owner #133) not one word is on the screen; the pictures'
## words are their tooltips, for a grown-up's pointer.

signal camera_pressed
## "again", "next" (the board), "back", or a voyage's id (the board's pictures).
signal end_chosen(what: String)

var camera_button: Button
var end_card: PanelContainer
var end_plant: LeafGlyph
var end_stars: Control
var end_gold: Label
var board_card: PanelContainer
var board_buttons := {}


func _init() -> void:
	super()
	name = "LeafHud"
	go_button.visible = false
	next_button.visible = false
	counter.visible = false
	camera_button = SchoolUi.button("", SchoolUi.TEAL, Vector2(120, 92))
	camera_button.name = "Camera"
	camera_button.tooltip_text = "CAMERA"
	camera_button.pressed.connect(func() -> void: camera_pressed.emit())
	LeafGlyph.on_button(camera_button, LeafGlyph.CAMERA, 56.0)
	go_button.get_parent().add_child(camera_button)
	_end_card()
	_board_card()
	set_voice(voice)


## With the voice on the coach's bar holds only Hoot and the ear (nothing to read, so nothing wide and empty over the
## place); without it, the whole bar for the words.
func set_voice(on: bool) -> void:
	super(on)
	var bar := root.get_node_or_null("CoachBar") as Control
	if bar != null:
		bar.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT if on else Control.PRESET_TOP_WIDE)
		bar.offset_left = 12
		bar.offset_top = 10
		bar.offset_bottom = 140
		bar.offset_right = 250 if on else -310
		say_label.custom_minimum_size = Vector2(0, 0) if on else Vector2(700, 0)
		say_label.visible = not on


## The camera button shows where it does something (inside the leaf, flat).
func show_camera(on: bool) -> void:
	camera_button.visible = on


## The end card: the plant (`plant`: "sunflower" or "cactus"), the unit's stars, the gold the voyage earned.
func show_end(plant: String, stars: int, gold: int) -> void:
	board_card.visible = false
	end_plant.kind = LeafGlyph.CACTUS if plant == "cactus" else LeafGlyph.SUNFLOWER
	end_plant.queue_redraw()
	(end_stars as Variant).count = stars
	end_gold.text = "+%d" % gold
	end_card.visible = true
	UiMotion.pop_in(end_card)
	if is_inside_tree():
		PadFocus.take(end_card)


func end_open() -> bool:
	return end_card.visible


## The voyage board: each voyage's picture, those in `open` to play, the others locked.
func show_board(open: Array[String]) -> void:
	end_card.visible = false
	for id: String in board_buttons:
		var b: Button = board_buttons[id]
		b.disabled = not open.has(id)
		(b.get_node("Lock") as Control).visible = b.disabled
	board_card.visible = true
	UiMotion.pop_in(board_card)
	if is_inside_tree():
		PadFocus.take(board_card)


func board_open() -> bool:
	return board_card.visible


func _end_card() -> void:
	end_card = _card("EndCard")   # low on the screen: the plant's bloom shows above it
	end_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	end_card.offset_left = -470
	end_card.offset_right = 470
	end_card.offset_top = -320
	end_card.offset_bottom = -16
	var col := end_card.get_child(0) as VBoxContainer
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 30)
	col.add_child(top)
	end_plant = LeafGlyph.new(LeafGlyph.SUNFLOWER, 96.0)
	top.add_child(end_plant)
	var right := VBoxContainer.new()
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override("separation", 16)
	top.add_child(right)
	end_stars = SchoolUi.stars(0, 56.0)
	end_stars.name = "EndStars"
	right.add_child(end_stars)
	var gold := HBoxContainer.new()
	gold.add_theme_constant_override("separation", 10)
	gold.add_child(LeafGlyph.new(LeafGlyph.COIN, 48.0))
	end_gold = SchoolUi.words("+0", 40, 200)
	end_gold.name = "EndGold"
	end_gold.add_theme_color_override("font_color", SchoolUi.GOLD)
	gold.add_child(end_gold)
	right.add_child(gold)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 22)
	col.add_child(buttons)
	buttons.add_child(_picture_button("Again", "AGAIN", UiKit.GREEN, LeafGlyph.AGAIN, "again"))
	var next := _picture_button("NextVoyage", "ANOTHER VOYAGE", SchoolUi.TEAL, "", "next")
	PlayGlyph.on_button(next, PlayGlyph.NEXT, 56.0)
	buttons.add_child(next)
	var back := _picture_button("Back", "BACK", Color("6b7a99"), "", "back")
	PlayGlyph.on_button(back, PlayGlyph.STOP, 52.0)
	buttons.add_child(back)


func _board_card() -> void:
	board_card = _card("BoardCard")
	board_card.offset_top = -230
	board_card.offset_bottom = 230
	var col := board_card.get_child(0) as VBoxContainer
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 40)
	col.add_child(row)
	for v: Array in [["5.1", LeafGlyph.SUNFLOWER, "THE DROOPING SUNFLOWER"], ["5.T1", LeafGlyph.CACTUS, "THE DESERT NIGHT"]]:
		var b := SchoolUi.button("", Color("2f6a4f"), Vector2(220, 220))
		b.name = "Voyage_" + str(v[0]).replace(".", "_")
		b.tooltip_text = str(v[2])
		LeafGlyph.on_button(b, str(v[1]), 170.0)
		var lock := LeafGlyph.new(LeafGlyph.LOCK, 56.0)
		lock.name = "Lock"
		lock.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		lock.offset_left = -64
		lock.offset_top = -64
		lock.offset_right = -8
		lock.offset_bottom = -8
		lock.visible = false
		b.add_child(lock)
		var id := str(v[0])
		b.pressed.connect(func() -> void: end_chosen.emit(id))
		row.add_child(b)
		board_buttons[id] = b
	var back := _picture_button("BoardBack", "BACK", Color("6b7a99"), "", "back")
	PlayGlyph.on_button(back, PlayGlyph.STOP, 52.0)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(back)


func _picture_button(node_name: String, words: String, colour: Color, glyph: String, what: String) -> Button:
	var b := SchoolUi.button("", colour, Vector2(200, 92))
	b.name = node_name
	b.tooltip_text = words
	if glyph != "":
		LeafGlyph.on_button(b, glyph, 56.0)
	b.pressed.connect(func() -> void: end_chosen.emit(what))
	return b


## The pause key (Escape, a game controller's Start) opens and closes the break, as G0's Escape does.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause") and not event.is_action_pressed(&"ui_cancel"):
		if break_card.visible:
			close_break()
		else:
			open_break()
		get_viewport().set_input_as_handled()
		return
	super(event)
