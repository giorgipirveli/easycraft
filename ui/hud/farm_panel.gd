class_name FarmPanel
extends Control
## The Gold Farm's panel (M3 Task 10; HUD: a centred overlay, like the Totem's), opened by a tap on the barn.
## What the farm makes and holds as pictures and short words ("20 an hour", "Holds 12 hours", a little
## farmer for each worker), the rule in one line, and for the world's owner two equal buttons: FASTER (the
## next rate level: one more worker) and BIGGER (the next cap level: the barn holds more hours), with fixed
## prices (FarmRules), greyed with "have / need" while the gold is short, BEST! at the top. A choice asks the
## host (Session.request_farm_upgrade); its answer shows inside the panel (a toast would hide behind it) and
## the host's new farm comes back through show_farm. MOVE (the owner's) picks the farm up to place it somewhere
## else (it keeps its levels). Guests see the farm and no buttons. It closes with X, a tap outside, Back, or
## walking away.

signal opened
signal closed

const PANEL_SIZE := Vector2(800, 520)
const BUTTON := Vector2(330, 112)
const REACH := 16.0               # the panel stays open this close to the farm
const REACH_CHECK_EVERY := 0.5
const TITLE := "Gold Farm"
const RULE := "Stand on your farm when you stop playing. It makes gold while you are away!"
const GUEST_RULE := "This is the world owner's farm. It makes gold for them while they are away."

## () -> bool: this game's player owns the farm (the host's). Tests set their own.
var is_owner: Callable = func() -> bool: return Session.is_host()
## () -> Vector3: this game's player's feet (INF when not standing in the world).
var player_feet: Callable = Callable()
var faster_button: Button
var bigger_button: Button
var move_button: Button
var close_button: Button

var _farm: Dictionary = {}
var _building: FarmBuilding
var _panel := PanelContainer.new()
var _rate := Label.new()
var _cap := Label.new()
var _rule := Label.new()
var _answer := Label.new()
var _workers := HBoxContainer.new()
var _reach_timer := Timer.new()

static var _farmer: ImageTexture


func _init() -> void:
	visible = false   # hidden before it is in the tree too (Back looks at it)


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.theme()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.4)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_theme_stylebox_override("panel", UiKit.box(Color(0.16, 0.1, 0.05), 26, 22))
	add_child(_panel)
	for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
		_panel.set_anchor(side, 0.5)
	_panel.offset_left = -PANEL_SIZE.x * 0.5
	_panel.offset_right = PANEL_SIZE.x * 0.5
	_panel.offset_top = -PANEL_SIZE.y * 0.5
	_panel.offset_bottom = PANEL_SIZE.y * 0.5
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	_panel.add_child(column)
	column.add_child(_header())
	column.add_child(_picture())
	_style(_rule, 24, Color("fff3c4"))
	_rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rule.custom_minimum_size = Vector2(PANEL_SIZE.x - 60, 0)
	column.add_child(_rule)
	column.add_child(_buttons())
	_style(_answer, 24, Color.WHITE)
	_answer.custom_minimum_size = Vector2(0, 34)
	column.add_child(_answer)
	_reach_timer.wait_time = REACH_CHECK_EVERY
	_reach_timer.timeout.connect(check_reach)
	add_child(_reach_timer)


## Opens at `building` (null in tests) showing `farm` (this game's copy of the host's farm).
func open(building: FarmBuilding, farm: Dictionary) -> void:
	_building = building
	_answer.text = ""
	visible = true
	show_farm(farm)
	_reach_timer.start()
	if not Session.magic_feedback.is_connected(_on_answer):
		Session.magic_feedback.connect(_on_answer)
	if PlatformRules.captures_mouse(PlatformRules.current()):   # M7: a phone browser has no mouse to free
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	opened.emit()


func close() -> void:
	if not visible:
		return
	visible = false
	_reach_timer.stop()
	if Session.magic_feedback.is_connected(_on_answer):
		Session.magic_feedback.disconnect(_on_answer)
	closed.emit()


## The host's farm reached this game (placed, upgraded): the numbers and the buttons follow.
func show_farm(farm: Dictionary) -> void:
	_farm = farm
	if farm.is_empty():
		close()
		return
	var u := Game.universe
	_rate.text = tr("%s an hour") % GoldFormat.short(FarmRules.rate_per_hour(int(farm.rate), u))
	_cap.text = tr("Holds %d hours") % FarmRules.cap_hours(int(farm.cap))
	var n := FarmRules.workers(int(farm.rate))
	for i in _workers.get_child_count():
		(_workers.get_child(i) as Control).visible = i < n
	var owner: bool = is_owner.call()
	_rule.text = RULE if owner else GUEST_RULE
	_offer(faster_button, "FASTER", FarmRules.RATE, owner)
	_offer(bigger_button, "BIGGER", FarmRules.CAP, owner)
	move_button.visible = owner


func _offer(b: Button, word: String, kind: StringName, owner: bool) -> void:
	b.visible = owner
	var price := FarmRules.upgrade_price(_farm, kind, Game.universe)
	var gold := Profile.data.survivor_gold
	if price <= 0:
		b.text = tr("%s\nBEST!") % word
		b.disabled = true
	elif gold < price:
		b.text = "%s\n%s" % [word, GoldFormat.have_need(gold, price)]
		b.disabled = true
	else:
		b.text = "%s\n%s" % [word, GoldFormat.short(price)]
		b.disabled = false


## Closes the panel once the player has walked away from the farm (or it is gone).
func check_reach() -> void:
	if not visible or _building == null:
		return
	var feet: Vector3 = player_feet.call() if player_feet.is_valid() else Vector3.INF
	if not is_instance_valid(_building) or not feet.is_finite() or feet.distance_to(_building.global_position) > REACH:
		close()


func rate_text() -> String:
	return _rate.text


func cap_text() -> String:
	return _cap.text


func rule_text() -> String:
	return _rule.text


func answer_text() -> String:
	return _answer.text


func workers_shown() -> int:
	var n := 0
	for c in _workers.get_children():
		if (c as Control).visible:
			n += 1
	return n


## Where the panel sits on a screen of `screen` size (layout checks).
func panel_rect(screen: Vector2) -> Rect2:
	return Rect2(screen * 0.5 + Vector2(_panel.offset_left, _panel.offset_top), PANEL_SIZE)


func _on_answer(text: String) -> void:
	if visible:
		_answer.text = text


func _ask(kind: StringName) -> void:
	Session.request_farm_upgrade(kind)


## MOVE: the farm goes back in the bag (the host decides and says so); the panel closes.
func _move() -> void:
	Session.request_farm_move()
	close()


# --- Building the panel ---

func _header() -> HBoxContainer:
	var row := HBoxContainer.new()
	var icon := TextureRect.new()
	icon.texture = BlockIcons.farm_icon()
	icon.custom_minimum_size = Vector2(64, 64)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var title := Label.new()
	title.text = TITLE
	_style(title, 38, CoinIcon.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	move_button = UiKit.big_button("MOVE", UiKit.BLUE, Vector2(150, 84))
	move_button.focus_mode = Control.FOCUS_NONE
	move_button.add_theme_font_size_override("font_size", 26)
	move_button.pressed.connect(_move)
	row.add_child(move_button)
	close_button = UiKit.big_button("X", UiKit.RED, Vector2(84, 84))
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_size_override("font_size", 36)
	close_button.pressed.connect(close)
	row.add_child(close_button)
	return row


## The farm as a picture: a coin and what it makes an hour, the barn and how many hours it holds, and a
## little farmer for each worker.
func _picture() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 14)
	row.add_child(CoinIcon.new(44))
	_style(_rate, 34, CoinIcon.GOLD)
	row.add_child(_rate)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(24, 0)
	row.add_child(gap)
	_style(_cap, 34, Color.WHITE)
	row.add_child(_cap)
	row.add_child(gap.duplicate())
	_workers.add_theme_constant_override("separation", 4)
	for i in FarmRules.WORKERS.max():
		var t := TextureRect.new()
		t.texture = farmer_icon()
		t.custom_minimum_size = Vector2(44, 44)
		t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		t.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_workers.add_child(t)
	row.add_child(_workers)
	return row


func _buttons() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 22)
	faster_button = _icon_button("FASTER", CoinIcon.texture(), UiKit.GREEN)
	faster_button.pressed.connect(_ask.bind(FarmRules.RATE))
	row.add_child(faster_button)
	bigger_button = _icon_button("BIGGER", BlockIcons.farm_icon(), UiKit.ORANGE)
	bigger_button.pressed.connect(_ask.bind(FarmRules.CAP))
	row.add_child(bigger_button)
	return row


static func _icon_button(word: String, icon: Texture2D, color: Color) -> Button:
	var b := UiKit.big_button(word, color, BUTTON)
	b.icon = icon
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_constant_override("icon_max_width", 56)
	return b


static func _style(l: Label, font_size: int, color: Color) -> void:
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE


## A little farmer's face under a straw hat, 16 px drawn in code, shown at 44 px; made once.
static func farmer_icon() -> Texture2D:
	if _farmer == null:
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		var straw := Color("e8c65a")
		var band := Color("c0392b")
		var skin := Color("f1c7a1")
		var dark := Color("222222")
		for x in range(1, 15):
			img.set_pixel(x, 6, straw)
		for y in range(2, 6):
			for x in range(4, 12):
				img.set_pixel(x, y, band if y == 5 else straw)
		for y in range(7, 15):
			for x in range(4, 12):
				img.set_pixel(x, y, skin)
		for p: Vector2i in [Vector2i(6, 9), Vector2i(9, 9), Vector2i(6, 12), Vector2i(7, 13), Vector2i(8, 13), Vector2i(9, 12)]:
			img.set_pixel(p.x, p.y, dark)
		_farmer = ImageTexture.create_from_image(img)
	return _farmer


## Taps on the dimmed area (outside the panel) close it and never reach the world behind it.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		close()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		close()
		get_viewport().set_input_as_handled()
