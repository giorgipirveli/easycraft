class_name GoldCounter
extends Control
## The gold counter (M2 Task 7; HUD top-right under the username): a coin and this player's Survivor
## gold in short numbers (GoldFormat), ∞ in Sandbox. It changes only when the host says so
## (Session.gold_changed), never per frame: a little bounce and a floating "+12" or "-1".

const POPUP_TIME := 0.9
const BOUNCE := 1.25
const PLUS := Color("7cfc6b")
const MINUS := Color("ff8a7a")

var _row := HBoxContainer.new()
var _coin := CoinIcon.new(40)
var _label := Label.new()
var _popup := Label.new()
var _infinite := false
var _balance := 0
var _bounce: Tween
var _float: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.alignment = BoxContainer.ALIGNMENT_END
	_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_row.add_theme_constant_override("separation", 8)
	add_child(_row)
	_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_row.add_child(_coin)
	_style(_label, 32, Color.WHITE)
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_row.add_child(_label)
	_style(_popup, 26, PLUS)
	_popup.visible = false
	add_child(_popup)
	resized.connect(func() -> void: pivot_offset = Vector2(size.x - 50.0, size.y * 0.5))
	Session.gold_changed.connect(_on_gold_changed)
	refresh()


## Shows ∞ in Sandbox, else this player's Survivor gold (call when the world starts).
func refresh() -> void:
	_infinite = Game.allows(ModeRules.INFINITE_GOLD)
	_balance = Profile.data.survivor_gold
	_label.text = "∞" if _infinite else GoldFormat.short(_balance)


func shown_text() -> String:
	return _label.text


func popup_text() -> String:
	return _popup.text


func popup_visible() -> bool:
	return _popup.visible


func _on_gold_changed(balance: int) -> void:
	if _infinite or balance == _balance:
		return
	var change := balance - _balance
	_balance = balance
	_label.text = GoldFormat.short(balance)
	if _bounce and _bounce.is_valid():
		_bounce.kill()
	scale = Vector2.ONE
	_bounce = create_tween()
	_bounce.tween_property(self, "scale", Vector2.ONE * BOUNCE, 0.08).set_ease(Tween.EASE_OUT)
	_bounce.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_float_change(change)
	if change > 0 and is_visible_in_tree():   # owner #94: coins fly from the middle of the screen to the coin
		UiMotion.fly(self, get_viewport_rect().size * Vector2(0.5, 0.6), _coin, coins_for(change), UiFlyers.COIN)


## Owner #94: how many coins fly in for a gain: one for a little, up to eight for a lot.
static func coins_for(change: int) -> int:
	return clampi(1 + int(sqrt(maxf(change, 0))) / 2, 1, 8)


## One reused label floats up and fades: "+12" in green, "-1" in red.
func _float_change(change: int) -> void:
	if _float and _float.is_valid():
		_float.kill()
	_popup.text = GoldFormat.change(change)
	_popup.add_theme_color_override("font_color", PLUS if change > 0 else MINUS)
	_popup.size = Vector2(120, 34)
	_popup.position = Vector2(size.x - 130.0, size.y - 6.0)
	_popup.modulate.a = 1.0
	_popup.visible = true
	_float = create_tween().set_parallel()
	_float.tween_property(_popup, "position:y", _popup.position.y + 30.0, POPUP_TIME).set_ease(Tween.EASE_OUT)
	_float.tween_property(_popup, "modulate:a", 0.0, POPUP_TIME * 0.5).set_delay(POPUP_TIME * 0.5)
	_float.chain().tween_callback(func() -> void: _popup.visible = false)


static func _style(l: Label, font_size: int, color: Color) -> void:
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
