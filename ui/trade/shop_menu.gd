class_name ShopMenu
extends QuestOverlay
## MORE → SHOP (owner #37, spec §14.23), Survivor only: a small picture card. Tilly (her stall, or the nearest
## villager who trades, whichever is nearer) with how far she is and an arrow the way to go; on market day Nico's
## cart too; a tap on a row's button shows the way (the HUD's find arrow; the shop opens by itself on arrival) or,
## close by, OPENs the shop. Under them the other players in this world, each with TRADE (bots are not players).
## The distances and arrows are looked at four times a second while the card is open, never otherwise.

const REFRESH := 0.25
const WAY_WORDS := "SHOW ME"
const OPEN_WORDS := "OPEN"

## () -> Array of {pos: Vector3, what: String, trader: Trader}: the full shops (Tilly, trading villagers).
var shops: Callable = func() -> Array: return []
## () -> Dictionary {pos, what, trader} of Nico's cart ({} when it is not market day).
var market: Callable = func() -> Dictionary: return {}
## () -> Array of {peer: int, name: String}: the other players in this world.
var players: Callable = func() -> Array: return []
## () -> Vector3 (the child's eye) and () -> float (the camera's turn).
var eye: Callable = func() -> Vector3: return Vector3.INF
var yaw: Callable = func() -> float: return 0.0
## (what, trader) -> void: show the way there; (trader) -> void: open its shop; (peer) -> void: ask to trade.
var on_way: Callable
var on_open: Callable
var on_trade: Callable

## The rows showing now: {"shop": {pos, what, trader}, "distance": Label, "arrow": WayArrow, "button": Button}.
var rows: Array[Dictionary] = []
var trade_buttons := {}   # peer -> Button

var _t := 0.0


func _init() -> void:
	box_width = 760.0


## The MORE panel's button for the card (the director connects it to open_menu).
static func more_button() -> TouchButton:
	var b := TouchButton.new()
	b.name = "Shop"
	b.text = "SHOP"
	b.symbol = &"shop"
	return b


func open_menu() -> void:
	clear()
	rows.clear()
	trade_buttons.clear()
	var head := row(14)
	head.add_child(CoinIcon.new(56))
	head.add_child(words("SHOP", 40, 0.0, GOLD))
	content.add_child(head)
	var near := ShopGuide.nearest(shops.call(), eye.call())
	if not near.is_empty():
		_shop_row(near, &"tilly")
	var cart: Dictionary = market.call()
	if not cart.is_empty():
		_shop_row(cart, &"wanderer")
	if near.is_empty() and cart.is_empty():
		content.add_child(words("No shop in this world.", 26, 0.0, HINT))
	var others: Array = players.call()
	if not others.is_empty():
		content.add_child(words("Trade with a friend", 28, 0.0, GOLD))
		for p: Dictionary in others:
			var r := row(18)
			r.add_child(ProgressPicture.new(&"friends", 64))
			var who := words(str(p.name), 28, 300.0)
			who.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			r.add_child(who)
			var b := button("TRADE", OnlineUi.PURPLE, Vector2(200, 76), "Trade%d" % int(p.peer))
			var peer := int(p.peer)
			b.pressed.connect(func() -> void:
				close()
				if on_trade.is_valid():
					on_trade.call(peer))
			trade_buttons[peer] = b
			r.add_child(b)
			content.add_child(r)
	var bye := button("CLOSE", Color(), Vector2(220, 72), "Close")
	bye.pressed.connect(close)
	var last := row()
	last.add_child(bye)
	content.add_child(last)
	refresh()
	show_overlay()


## The distances, arrows and OPEN / SHOW ME, from where the child is now.
func refresh() -> void:
	var from: Vector3 = eye.call()
	for r in rows:
		var shop: Dictionary = r.shop
		var pos: Vector3 = shop.pos
		var there := from.is_finite() and ShopGuide.there(from, pos)
		var way := ShopGuide.way(from, float(yaw.call()), pos) if from.is_finite() else {"angle": 0.0, "distance": 0}
		(r.distance as Label).text = ShopGuide.distance_words(int(way.distance))
		(r.arrow as WayArrow).angle = float(way.angle)
		(r.arrow as WayArrow).queue_redraw()
		(r.button as Button).text = OPEN_WORDS if there else WAY_WORDS


func _shop_row(shop: Dictionary, picture: StringName) -> void:
	var r := row(16)
	r.add_child(ProgressPicture.new(picture, 84))
	var col := VBoxContainer.new()
	var name_label := words(str(shop.get("what", "")), 28, 240.0)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(name_label)
	var dist := words("", 26, 0.0, HINT)
	dist.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	col.add_child(dist)
	r.add_child(col)
	var arrow := WayArrow.new()
	r.add_child(arrow)
	var b := button(WAY_WORDS, UiKit.GREEN, Vector2(200, 80), "Go%d" % rows.size())
	b.pressed.connect(func() -> void: _go(shop, b.text == OPEN_WORDS))
	r.add_child(b)
	content.add_child(r)
	rows.append({"shop": shop, "distance": dist, "arrow": arrow, "button": b})


func _go(shop: Dictionary, open_now: bool) -> void:
	close()
	if open_now and on_open.is_valid():
		on_open.call(shop.get("trader"))
	elif on_way.is_valid():
		on_way.call(str(shop.get("what", "")), shop.get("trader"))


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	if _t >= REFRESH:
		_t = 0.0
		refresh()


## A small dial with an arrow the way to go (up: straight ahead), like the HUD's find arrow.
class WayArrow:
	extends Control

	var angle := 0.0

	func _init() -> void:
		custom_minimum_size = Vector2(76, 76)
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var c := size * 0.5
		var r := minf(size.x, size.y) * 0.46
		draw_circle(c, r, FindArrow.DIAL_COLOR)
		draw_arc(c, r, 0.0, TAU, 32, FindArrow.RIM_COLOR, 3.0)
		var dir := Vector2(sin(angle), -cos(angle))
		var side := Vector2(cos(angle), sin(angle)) * r * 0.3
		var tip := c + dir * (r - 6.0)
		var back := c - dir * (r * 0.45)
		draw_colored_polygon(PackedVector2Array([tip, back + side, c, back - side]), FindArrow.ARROW_COLOR)
