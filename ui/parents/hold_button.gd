class_name HoldButton
extends Button
## A button a grown-up holds down for `hold_seconds` before it acts (M4 Task 8b, agent G: DELETE MY
## ONLINE ACCOUNT), so one stray tap can't. A light fill grows from the left while it is held and
## goes back when let go early, hidden or disabled; `held` comes once per hold. A tap (pressed)
## alone never acts.

signal held

const HOLD_SECONDS := 3.0
const FILL := Color(1, 1, 1, 0.35)

var hold_seconds := HOLD_SECONDS
var progress := 0.0   # 0..1 of the hold

var _holding := false


func _init() -> void:
	custom_minimum_size = Vector2(420, 90)
	button_down.connect(_on_down)
	button_up.connect(let_go)
	visibility_changed.connect(let_go)


func _process(delta: float) -> void:
	step(delta)


## Advances the hold by `delta` seconds while it is held (the game's frames; tests step it by hand).
func step(delta: float) -> void:
	if not _holding:
		return
	if disabled or not is_visible_in_tree():
		let_go()
		return
	progress = minf(progress + delta / hold_seconds, 1.0)
	queue_redraw()
	if progress >= 1.0:
		_holding = false
		held.emit()


## Let go before the end: it starts over.
func let_go() -> void:
	_holding = false
	if progress < 1.0:
		progress = 0.0
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		let_go()   # a finger lifted during a pause is never heard (DEVELOPMENT.md §8)


func _on_down() -> void:
	if not disabled:
		_holding = true
		progress = 0.0


func _draw() -> void:
	if progress > 0.0:
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * progress, size.y)), FILL)
