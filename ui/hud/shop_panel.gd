class_name ShopPanel
extends Control
## Tilly's shop (M2 Task 7; HUD: a centred overlay). BUY and SELL tabs; the Buy tab's sections
## (tools, potions, home, blocks); big picture cards with a coin and a short price, and a have/need
## bar under prices the player can't afford yet; one big action button for the selected card. The
## player's gold shows at the top. Readable without much text: icon-first buttons with a small word
## under each (the lead's child-psychology note). Every trade goes to the host
## (Session.request_trade); the panel shows what the host answers. It updates on changes only (gold,
## the player's things, a tap), never per frame, and closes when the player walks away.

signal opened
signal closed

const BUY := &"buy"
const SELL := &"sell"
const PANEL_SIZE := Vector2(1100, 660)
const COLUMNS := 5
const REACH_SLACK := 2.0         # the shop stays open this far past the tap reach
const REACH_CHECK_EVERY := 0.5
const OK_COLOR := Color("7cfc6b")
const NO_COLOR := Color("ffb36b")
const EMPTY_SELL := "Dig up coal, iron, gold, crystals\nand diamonds to sell them here!"
const _SECTION_WORDS := {ShopRules.TOOLS: "TOOLS", ShopRules.POTIONS: "POTIONS", ShopRules.HOME: "HOME", ShopRules.BLOCKS: "BLOCKS",
	ShopRules.GADGETS: "GADGETS"}   # M3 Task 14a

var player: Player
var tab: StringName = BUY
var section: StringName = ShopRules.TOOLS
var buy_tab: Button
var sell_tab: Button
var close_button: Button
var buy_button: Button
var sell_one_button: Button
var sell_all_button: Button
var section_buttons := {}   # section -> Button

var _trader: Trader
var _gold := 0
var _inv := Inventory.new()
var _selected := -1
var _trade_said := false        # the message line shows the host's answer, not a hint
var _panel := PanelContainer.new()
var _sections := VBoxContainer.new()
var _grid := GridContainer.new()
var _empty := Label.new()
var _gold_label := Label.new()
var _sel_icon := TextureRect.new()
var _sel_name := Label.new()
var _sel_price := Label.new()
var _message := Label.new()
var _cards_group := ButtonGroup.new()
var _reach_timer := Timer.new()


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.theme()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.45)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel.add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.1, 0.17), 26, 20))   # opaque: the world never shows through
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_panel)
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.5
	_panel.anchor_bottom = 0.5
	_panel.offset_left = -PANEL_SIZE.x * 0.5
	_panel.offset_right = PANEL_SIZE.x * 0.5
	_panel.offset_top = -PANEL_SIZE.y * 0.5
	_panel.offset_bottom = PANEL_SIZE.y * 0.5
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	_panel.add_child(column)
	column.add_child(_header())
	column.add_child(_body())
	_style(_message, 24, OK_COLOR)
	_message.custom_minimum_size.y = 30
	column.add_child(_message)
	column.add_child(_footer())
	_reach_timer.wait_time = REACH_CHECK_EVERY
	_reach_timer.timeout.connect(check_reach)
	add_child(_reach_timer)
	Session.gold_changed.connect(_on_gold_changed)
	Session.trade_inventory_received.connect(_on_inventory)
	Session.trade_done.connect(_on_trade_done)
	_refresh_tabs()


## Opens the shop at `trader` (a tap within reach) on the Buy tab; asks the host for the player's things.
func open(trader: Trader) -> void:
	_trader = trader
	_own37_open(trader)   # owner #37: a stand's or Nico's own things
	_gold = Profile.data.survivor_gold
	tab = BUY
	_trade_said = false
	_message.text = ""
	visible = true
	UiMotion.pop_in(self)   # owner #94: every panel pops in the same way
	_refresh_tabs()
	_rebuild()
	Session.request_shop()
	_reach_timer.start()
	if PlatformRules.captures_mouse(PlatformRules.current()):   # M7: a phone browser has no mouse to free
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	opened.emit()


func close() -> void:
	if not visible:
		return
	visible = false
	_reach_timer.stop()
	closed.emit()


## Closes the shop once the player has walked away from Tilly (or she is gone).
func check_reach() -> void:
	if not visible:
		return
	if not is_instance_valid(_trader) or not is_instance_valid(player) \
			or not TraderRules.in_reach(player.eye_position(), _trader.global_position, TraderRules.TAP_REACH + REACH_SLACK):
		close()


func show_tab(t: StringName) -> void:
	tab = t
	_trade_said = false
	_message.text = ""
	_refresh_tabs()
	_rebuild()


func show_section(s: StringName) -> void:
	section = s
	show_tab(BUY)


## The player taps a card: it is selected, and the action button says what can happen.
func select(id: int) -> void:
	_selected = id
	_trade_said = false
	var card := card_for(id)
	if card:
		card.button_pressed = true
	_refresh_selection()


func cards() -> Array[ShopCard]:
	var list: Array[ShopCard] = []
	for c in _grid.get_children():
		if c is ShopCard:
			list.append(c)
	return list


func card_for(id: int) -> ShopCard:
	for c in cards():
		if c.id == id:
			return c
	return null


func gold_text() -> String:
	return _gold_label.text


func message_text() -> String:
	return _message.text


## Where the panel sits on a screen of `screen` size (layout checks).
func panel_rect(screen: Vector2) -> Rect2:
	return Rect2(screen * 0.5 + Vector2(_panel.offset_left, _panel.offset_top), PANEL_SIZE)


# --- Building the panel ---

func _header() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	buy_tab = _icon_button("BUY", CoinIcon.texture(), Vector2(130, 92), UiKit.GREEN)
	buy_tab.pressed.connect(show_tab.bind(BUY))
	row.add_child(buy_tab)
	sell_tab = _icon_button("SELL", BlockIcons.icon(BlockIds.DIAMOND), Vector2(130, 92), UiKit.ORANGE)
	sell_tab.pressed.connect(show_tab.bind(SELL))
	row.add_child(sell_tab)
	var title := Label.new()
	_title = title   # owner #37
	title.text = "Tilly's Shop"
	_style(title, 34, CoinIcon.GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	row.add_child(ReadAloud.button(func() -> String: return ReadAloud.words_of(self), 56.0))   # M5 Task 1
	row.add_child(CoinIcon.new(46))
	_style(_gold_label, 38, Color.WHITE)
	_gold_label.custom_minimum_size.x = 110
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	row.add_child(_gold_label)
	close_button = UiKit.big_button("X", UiKit.RED, Vector2(84, 84))
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.add_theme_font_size_override("font_size", 36)
	close_button.pressed.connect(close)
	row.add_child(close_button)
	return row


func _body() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 12)
	_sections.add_theme_constant_override("separation", 8)
	var icons := {ShopRules.TOOLS: BlockIcons.icon(ItemIds.SWORD), ShopRules.POTIONS: ShopCard.potion_icon(ItemIds.POTION_JUMP),
		ShopRules.HOME: BlockIcons.icon(BlockIds.BED), ShopRules.BLOCKS: BlockIcons.icon(BlockIds.PLANKS),
		ShopRules.GADGETS: BlockIcons.icon(ItemIds.GLIDER)}   # M3 Task 14a
	for s: StringName in ShopRules.SECTIONS:
		var b := _icon_button(_SECTION_WORDS[s], icons[s], Vector2(124, 80), UiKit.BLUE)
		b.pressed.connect(show_section.bind(s))
		section_buttons[s] = b
		_sections.add_child(b)
	row.add_child(_sections)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_grid)
	row.add_child(scroll)
	_empty.text = EMPTY_SELL
	_style(_empty, 28, Color(1, 1, 1, 0.85))
	_empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty.visible = false
	row.add_child(_empty)
	return row


func _footer() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	_sel_icon.custom_minimum_size = Vector2(72, 72)
	_sel_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_sel_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(_sel_icon)
	var info := VBoxContainer.new()
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style(_sel_name, 30, Color.WHITE)
	_sel_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info.add_child(_sel_name)
	var price := HBoxContainer.new()
	price.add_child(CoinIcon.new(28))
	_style(_sel_price, 26, Color.WHITE)
	price.add_child(_sel_price)
	info.add_child(price)
	row.add_child(info)
	buy_button = _icon_button("BUY", CoinIcon.texture(), Vector2(190, 96), UiKit.GREEN)
	buy_button.pressed.connect(func() -> void: Session.request_trade(true, _selected, 1))
	row.add_child(buy_button)
	sell_one_button = _icon_button("SELL 1", CoinIcon.texture(), Vector2(160, 96), UiKit.ORANGE)
	sell_one_button.pressed.connect(func() -> void: Session.request_trade(false, _selected, 1))
	row.add_child(sell_one_button)
	sell_all_button = _icon_button("SELL ALL", CoinIcon.texture(), Vector2(170, 96), UiKit.ORANGE)
	sell_all_button.pressed.connect(func() -> void: Session.request_trade(false, _selected, _inv.count(_selected)))
	row.add_child(sell_all_button)
	row.add_child(_add_save_button())   # M3 Task 21b: SAVE UP
	return row


## A button with its picture on top and a small word under it.
static func _icon_button(word: String, icon: Texture2D, min_size: Vector2, color: Color) -> Button:
	var b := UiKit.big_button(word, color, min_size)
	b.icon = icon
	b.expand_icon = true
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 20)
	b.add_theme_constant_override("icon_max_width", 48)
	return b


# --- Showing what there is ---

func _refresh_tabs() -> void:
	buy_tab.modulate = Color.WHITE if tab == BUY else Color(1, 1, 1, 0.5)
	sell_tab.modulate = Color.WHITE if tab == SELL else Color(1, 1, 1, 0.5)
	_sections.visible = tab == BUY and stall_stock.is_empty()   # owner #37: a stall has no sections
	for s: StringName in section_buttons:
		(section_buttons[s] as Button).modulate = Color.WHITE if s == section else Color(1, 1, 1, 0.5)
	buy_button.visible = tab == BUY
	sell_one_button.visible = tab == SELL
	sell_all_button.visible = tab == SELL


func _rebuild() -> void:
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	var ids := ShopRules.catalog(section, Game.universe) if tab == BUY else ShopRules.sellable(_inv)   # M3 Task 5
	if tab == BUY and not stall_stock.is_empty():
		ids = stall_stock.duplicate()   # owner #37: the stand's or Nico's things
	for id in ids:
		var card := ShopCard.new(id)
		card.button_group = _cards_group
		card.pressed.connect(select.bind(id))
		_grid.add_child(card)
		_offer(card)
	_empty.visible = tab == SELL and ids.is_empty()
	if not ids.has(_selected):
		_selected = ids[0] if not ids.is_empty() else -1
	var sel := card_for(_selected)
	if sel:
		sel.set_pressed_no_signal(true)
	_refresh_selection()


func _offer(card: ShopCard) -> void:
	var id := card.id
	if tab == BUY:
		var n := _own37_amount(id)   # spec §12.18: the game's prices and amounts (owner #37: Nico's)
		card.show_offer(_own37_price(id), _gold, "×%d" % n if n > 1 else "", ShopRules.one_only(id) and _inv.count(id) > 0, true)
	else:
		card.show_offer(ShopRules.sell_price(id, Game.universe), _gold, "×%d" % _inv.count(id), false, false)


func _refresh_selection() -> void:
	var has := _selected >= 0
	_sel_icon.texture = ShopCard.icon_for(_selected) if has else null
	_sel_icon.self_modulate = ShopCard.tint_for(_selected)
	var n := _own37_amount(_selected) if tab == BUY else 1
	_sel_name.text = ("%s ×%d" % [ItemIds.display_name(_selected), n] if n > 1 else ItemIds.display_name(_selected)) if has else ""
	_sel_price.text = GoldFormat.short(_own37_price(_selected) if tab == BUY \
		else ShopRules.sell_price(_selected, Game.universe)) if has else ""
	var why := ""
	if tab == BUY:
		why = _own37_refusal(_selected) if has else "none"
		buy_button.disabled = why != ""
	else:
		sell_one_button.disabled = not has
		sell_all_button.disabled = not has
	if not _trade_said:
		_say(ShopRules.message(why) if has else "", false)
	_gold_label.text = GoldFormat.short(_gold)
	_refresh_save(why)   # M3 Task 21b


func _say(text: String, ok: bool) -> void:
	_message.text = text
	_message.add_theme_color_override("font_color", OK_COLOR if ok else NO_COLOR)


# --- What the host says ---

func _on_gold_changed(balance: int) -> void:
	_gold = balance
	if visible:
		for c in cards():
			_offer(c)
		_refresh_selection()


func _on_inventory(items: Array) -> void:
	_inv = Inventory.from_save(items)
	if visible:
		_rebuild()


func _on_trade_done(ok: bool, text: String, id: int, _count: int, _gold_moved: int) -> void:
	if not visible:
		return
	_trade_said = true
	_say(text, ok)
	Audio.play(&"ding" if ok else &"thud")
	if ok and is_instance_valid(_trader):
		_trader.cheer()
	if ok and tab == BUY:
		_bought(id)   # M3 Task 21b: it came true, off the saving list


## Taps on the dimmed area (outside the panel) close the shop and never reach the world behind it.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		close()
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		close()
		get_viewport().set_input_as_handled()


static func _style(l: Label, font_size: int, color: Color) -> void:
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE

# --- M3 Task 21b: SAVE UP (the saving list, research R3) ---
# Beside BUY when the child hasn't enough gold for the thing picked (or it is on the list already): it goes on the
# child's saving list, and the book's SAVING tab and the bar under the HUD's gold show the gold filling up toward it.
# Never spends gold; buying it later takes it off the list.

## The saving list changed (the HUD's bar follows).
signal saving_changed

var save_button: Button
## The profile whose list it is (tests use their own).
var saving_profile: Callable = func() -> ProfileData: return Profile.data


func _add_save_button() -> Button:
	save_button = _icon_button(SavingRules.SAVE_WORD, CoinIcon.texture(), Vector2(190, 96), UiKit.BLUE)
	save_button.name = "SaveUp"
	save_button.visible = false
	save_button.pressed.connect(toggle_saving)
	return save_button


func _refresh_save(why: String) -> void:
	if save_button == null:
		return
	var id := str(_selected)
	var on := _selected >= 0 and SavingRules.has(saving_profile.call().wonder, SavingRules.SHOP, id)
	save_button.visible = tab == BUY and _selected >= 0 and (on or (why == "gold" and SavingRules.can_save(SavingRules.SHOP, id)))
	save_button.text = SavingRules.SAVING_WORD if on else SavingRules.SAVE_WORD


## SAVE UP: the picked thing on (or off) the saving list. The profile is saved with the world.
func toggle_saving() -> void:
	if _selected < 0:
		return
	var p: ProfileData = saving_profile.call()
	var was := SavingRules.has(p.wonder, SavingRules.SHOP, str(_selected))
	var on := SavingRules.toggle(p.wonder, SavingRules.SHOP, str(_selected), p)
	_trade_said = true
	_say(SavingRules.ON_WORDS if on else (SavingRules.OFF_WORDS if was else SavingRules.FULL_WORDS), on)
	saving_changed.emit()
	_refresh_selection()


func _bought(id: int) -> void:
	var p: ProfileData = saving_profile.call()
	if SavingRules.has(p.wonder, SavingRules.SHOP, str(id)):
		SavingRules.remove(p.wonder, SavingRules.SHOP, str(id))
		saving_changed.emit()
		_refresh_selection()

# --- Owner #37: a helper's stand and Nico's market cart ------------------------------------------------------
# A trader with its own `shop_stock` (TraderStand, MarketCart) opens the Buy tab on those things only, under its own
# `shop_title`, with no sections; Nico's cart (`market`) prices them with MarketRules (the host sells them only near
# his cart). Tilly and the villagers open the shop as before.

## The open trader's own things ([] = Tilly's whole shop), and whether they are Nico's market's.
var stall_stock: Array[int] = []
var stall_market := false
var _title: Label


func title_text() -> String:
	return _title.text if _title else ""


func _own37_open(trader: Trader) -> void:
	var stock: Variant = trader.get("shop_stock") if trader else null
	stall_stock.clear()
	if stock is Array:
		for id: Variant in stock:
			stall_stock.append(int(id))
	var market: Variant = trader.get("market") if trader else null
	stall_market = market is bool and market
	var words: Variant = trader.get("shop_title") if trader else null
	if _title:
		_title.text = str(words) if words is String and str(words) != "" else "Tilly's Shop"


func _own37_price(id: int) -> int:
	return MarketRules.price(id, Game.universe) if stall_market else ShopRules.price(id, Game.universe, Game.survivor_game)


func _own37_amount(id: int) -> int:
	return MarketRules.amount(id) if stall_market else ShopRules.amount(id, Game.survivor_game)


func _own37_refusal(id: int) -> String:
	return MarketRules.buy_refusal(id, _gold, _inv, Game.universe) if stall_market \
		else ShopRules.buy_refusal(id, _gold, _inv, Game.universe, Game.survivor_game)
