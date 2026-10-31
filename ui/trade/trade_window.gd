class_name TradeWindow
extends Control
## The trade window (owner #37, spec §14.23): both children see the same trade, as the host tells it. YOU GIVE (up
## to 8 kinds of things and some gold) and BOB GIVES side by side, the child's bag under them (a tap puts one, ten
## or all of a thing in: the ×1 / ×10 / ALL button), gold chips (+1, +10, +100, 0), READY and X. A tap on one of
## your own things in YOU GIVE takes it back. Every change goes to the host, which makes both not ready; when both
## are READY the host swaps. X stops the trade (nothing moved). While open it takes every new finger (the HUD's
## buttons and the world behind never hear it) and never closes by a stray tap outside: only X or the trade's end.

signal closed

const CARD := Vector2(1180, 686)
const COLUMNS := 4                 # an offer's squares: 4 × 2 = TradeRules.MAX_KINDS
const BAG_COLUMNS := 6
const STEPS: Array[int] = [1, 10, 0]   # how many a tap on the bag puts in (0: all of it)
const STEP_WORDS: Array[String] = ["×1", "×10", "ALL"]
const GOLD_STEPS: Array[int] = [1, 10, 100]
const WOOD := Color(0.1, 0.12, 0.2, 0.98)
const SIDE := Color(0.15, 0.18, 0.3, 0.95)
const READY_GREEN := Color("7cfc6b")
const HINT := Color("c9d6ff")

## The host's view of this child's trade (TradeTable.state_for).
var state := {}
## The child's bag and gold (tests set their own).
var bag: Callable = func() -> Inventory: return Session.my_inventory
var gold: Callable = func() -> int: return Profile.data.survivor_gold
var send_offer: Callable = func(items: Array, g: int) -> void: Session.player_trade_offer(items, g)
var send_ready: Callable = func(on: bool) -> void: Session.player_trade_ready(on)
var send_cancel: Callable = func() -> void: Session.player_trade_cancel()

var box := PanelContainer.new()
var title := Label.new()
var close_button: Button
var mine_slots: Array[TradeSlot] = []
var their_slots: Array[TradeSlot] = []
var mine_gold := Label.new()
var their_gold := Label.new()
var my_ready_label := Label.new()
var their_ready_label := Label.new()
var their_heading := Label.new()
var bag_grid := GridContainer.new()
var step_button: Button
var gold_buttons: Array[Button] = []
var clear_gold_button: Button
var ready_button: Button
var message := Label.new()

var _mine := TradeRules.empty_offer()
var _step := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	theme = UiKit.theme()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.add_theme_stylebox_override("panel", UiKit.box(WOOD, 24, 12))
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	box.anchor_left = 0.5
	box.anchor_right = 0.5
	box.anchor_top = 0.5
	box.anchor_bottom = 0.5
	box.offset_left = -CARD.x * 0.5
	box.offset_right = CARD.x * 0.5
	box.offset_top = -CARD.y * 0.5
	box.offset_bottom = CARD.y * 0.5
	add_child(box)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	box.add_child(column)
	column.add_child(_header())
	var offers := HBoxContainer.new()
	offers.add_theme_constant_override("separation", 16)
	var my_heading := Label.new()
	my_heading.text = "YOU GIVE"
	offers.add_child(_side(my_heading, mine_slots, mine_gold, my_ready_label, true))
	offers.add_child(_side(their_heading, their_slots, their_gold, their_ready_label, false))
	column.add_child(offers)
	column.add_child(_bottom())
	_words(message, 24, READY_GREEN)
	message.custom_minimum_size.y = 30
	column.add_child(message)
	Session.inventory_changed.connect(_on_bag_changed)
	Session.gold_changed.connect(_on_gold_changed)


func is_open() -> bool:
	return visible


## Opens (or brings up to date) the trade as the host tells it.
func show_state(s: Dictionary) -> void:
	state = s
	var mine: Dictionary = s.get("mine", {})
	_mine = TradeRules.clean_offer(mine.get("items", []), mine.get("gold", 0), Game.universe)
	if not visible:
		message.text = ""
	visible = true
	_refresh()


## The trade ended (the host's word, or X): the window goes.
func close_window() -> void:
	if not visible:
		return
	visible = false
	state = {}
	closed.emit()


## X: the trade stops, nothing moved.
func cancel() -> void:
	send_cancel.call()
	close_window()


func say(text: String) -> void:
	message.text = text


## A tap on a thing in the bag: one, ten or all of it goes into YOU GIVE.
func add_from_bag(id: int) -> void:
	if not TradeRules.tradable(id):
		say(TradeRules.message("not_tradable"))
		return
	var have := (bag.call() as Inventory).count(id)
	var already := int(_mine.items.get(id, 0))
	var step := STEPS[_step]
	var n := mini(have - already, step if step > 0 else have)
	if n <= 0:
		return
	if not _mine.items.has(id) and (_mine.items as Dictionary).size() >= TradeRules.MAX_KINDS:
		say("8 kinds at most!")
		return
	_mine.items[id] = already + n
	_send()


## A tap on one of your own things in YOU GIVE: it goes back to the bag.
func take_back(id: int) -> void:
	if _mine.items.has(id):
		_mine.items.erase(id)
		_send()


func add_gold(n: int) -> void:
	var cap := mini(int(gold.call()), TradeRules.gold_cap(Game.universe))
	_mine.gold = clampi(int(_mine.gold) + n, 0, maxi(cap, 0))
	_send()


func clear_gold() -> void:
	_mine.gold = 0
	_send()


func next_step() -> void:
	_step = (_step + 1) % STEPS.size()
	step_button.text = STEP_WORDS[_step]


func toggle_ready() -> void:
	send_ready.call(not bool(state.get("my_ready", false)))


func _send() -> void:
	var w := TradeRules.to_wire(_mine)
	send_offer.call(w.items, int(w.gold))
	_refresh()


# --- Building the window ---

func _header() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var pic := ProgressPicture.new(&"friends", 56)
	row.add_child(pic)
	_words(title, 34, CoinIcon.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(title)
	close_button = UiKit.big_button("X", UiKit.RED, Vector2(84, 64))
	close_button.name = "Cancel"
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_size_override("font_size", 36)
	close_button.pressed.connect(cancel)
	row.add_child(close_button)
	return row


func _side(head: Label, slots: Array[TradeSlot], gold_label: Label, ready_label: Label, mine: bool) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.box(SIDE, 18, 10))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	panel.add_child(col)
	var top := HBoxContainer.new()
	_words(head, 26, Color.WHITE)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	top.add_child(head)
	_words(ready_label, 24, READY_GREEN)
	top.add_child(ready_label)
	col.add_child(top)
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for i in TradeRules.MAX_KINDS:
		var s := TradeSlot.new()
		slots.append(s)
		grid.add_child(s)
		if mine:
			s.pressed.connect(func() -> void: take_back(s.id))
	col.add_child(grid)
	var money := HBoxContainer.new()
	money.add_child(CoinIcon.new(34))
	_words(gold_label, 30, Color.WHITE)
	money.add_child(gold_label)
	col.add_child(money)
	return panel


func _bottom() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bag_head := HBoxContainer.new()
	var bag_words := Label.new()
	_words(bag_words, 24, HINT)
	bag_words.text = "YOUR BAG: tap to give"
	bag_words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_words.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	bag_head.add_child(bag_words)
	step_button = UiKit.big_button(STEP_WORDS[0], UiKit.BLUE, Vector2(110, 64))
	step_button.name = "Step"
	step_button.focus_mode = Control.FOCUS_NONE
	step_button.pressed.connect(next_step)
	bag_head.add_child(step_button)
	left.add_child(bag_head)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, TradeSlot.SIZE.y * 2 + 10)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	bag_grid.columns = BAG_COLUMNS
	bag_grid.add_theme_constant_override("h_separation", 8)
	bag_grid.add_theme_constant_override("v_separation", 8)
	scroll.add_child(bag_grid)
	left.add_child(scroll)
	row.add_child(left)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 10)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 8)
	for n in GOLD_STEPS:
		var b := UiKit.big_button("+%d" % n, UiKit.ORANGE, Vector2(88, 64))
		b.name = "Gold%d" % n
		b.focus_mode = Control.FOCUS_NONE
		b.icon = CoinIcon.texture()
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 24)
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(add_gold.bind(n))
		gold_buttons.append(b)
		chips.add_child(b)
	clear_gold_button = UiKit.big_button("0", Color(), Vector2(64, 64))
	clear_gold_button.name = "GoldZero"
	clear_gold_button.focus_mode = Control.FOCUS_NONE
	clear_gold_button.pressed.connect(clear_gold)
	chips.add_child(clear_gold_button)
	right.add_child(chips)
	ready_button = UiKit.big_button("READY", UiKit.GREEN, Vector2(380, 96))
	ready_button.name = "Ready"
	ready_button.focus_mode = Control.FOCUS_NONE
	ready_button.pressed.connect(toggle_ready)
	right.add_child(ready_button)
	row.add_child(right)
	return row


# --- Showing the trade ---

func _refresh() -> void:
	var who := str(state.get("name", ""))
	title.text = tr("Trade with %s") % who
	their_heading.text = tr("%s GIVES") % who.to_upper()
	_fill(mine_slots, _mine.items)
	var theirs: Dictionary = state.get("theirs", {})
	var their_offer := TradeRules.clean_offer(theirs.get("items", []), theirs.get("gold", 0), Game.universe)
	_fill(their_slots, their_offer.items)
	mine_gold.text = GoldFormat.short(int(_mine.gold))
	their_gold.text = GoldFormat.short(int(their_offer.gold))
	var me_ready := bool(state.get("my_ready", false))
	var they_ready := bool(state.get("their_ready", false))
	my_ready_label.text = "READY!" if me_ready else ""
	their_ready_label.text = "READY!" if they_ready else ""
	ready_button.text = "NOT READY" if me_ready else "READY"
	_paint(ready_button, UiKit.ORANGE if me_ready else UiKit.GREEN)
	if me_ready and not they_ready and message.text == "":
		say(tr("Waiting for %s...") % who)
	_fill_bag()


func _fill(slots: Array[TradeSlot], items: Dictionary) -> void:
	var ids := items.keys()
	for i in slots.size():
		if i < ids.size():
			slots[i].show_thing(int(ids[i]), int(items[ids[i]]))
		else:
			slots[i].show_thing(-1, 0)


func _fill_bag() -> void:
	for c in bag_grid.get_children():
		bag_grid.remove_child(c)
		c.queue_free()
	var inv := bag.call() as Inventory
	for id in inv.ids():
		var left := inv.count(id) - int(_mine.items.get(id, 0))
		if left <= 0 or not TradeRules.tradable(id):
			continue
		var s := TradeSlot.new()
		s.show_thing(id, left)
		s.pressed.connect(add_from_bag.bind(id))
		bag_grid.add_child(s)


## The things in the bag grid (tests read them).
func bag_ids() -> Array[int]:
	var ids: Array[int] = []
	for c in bag_grid.get_children():
		if c is TradeSlot and not c.is_queued_for_deletion():
			ids.append((c as TradeSlot).id)
	return ids


func _on_bag_changed() -> void:
	if visible:
		_refresh()


func _on_gold_changed(_balance: int) -> void:
	_on_bag_changed()


## A button's colour (UiKit.big_button's boxes).
static func _paint(b: Button, color: Color) -> void:
	b.add_theme_stylebox_override("normal", UiKit.box(color))
	b.add_theme_stylebox_override("hover", UiKit.box(color.lightened(0.12)))
	b.add_theme_stylebox_override("pressed", UiKit.box(color.darkened(0.15)))


static func _words(l: Label, font_size: int, color: Color) -> void:
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Every new finger while open stays here: the HUD's buttons and the world never hear it (its own buttons get the
## touch's click as usual). A stray tap outside does nothing (only X stops the trade).
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		accept_event()
