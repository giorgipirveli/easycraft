class_name FindArrow
extends Control
## /find's arrow (owner feedback #40, spec §3b "More commands"): points from this game's player to what the
## child asked for (Tilly, their bed, a portal, the treasure), with the distance under it, until they get
## there (`arrived`: the runner says they found it) or SHOW_SECONDS pass. It borrows the treasure compass's
## spot (HudLayout &"compass", no new button) and steps aside while that compass shows (`covered`). It never
## takes a touch. The runner adds it to the HUD the first time /find is used.

signal arrived(what: String)

const SHOW_SECONDS := 90.0
const SIZE := Vector2(104, 128)
const DIAL := 44.0
const DIAL_COLOR := Color(0.81, 0.91, 1.0, 0.95)
const RIM_COLOR := Color("1f4e8c")
const ARROW_COLOR := Color("ff8a1f")

var player: Player
## () -> bool: true while the treasure map's compass has the spot.
var covered: Callable = func() -> bool: return false
var what := ""
var target := Vector3.INF
var angle := 0.0                  # radians from straight ahead, positive to the right
var distance := -1                # blocks (sideways)
var _left := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudLayout.place(self, &"compass")
	visible = false


## Points at `pos` (a world position) for SHOW_SECONDS; `label` is what it is ("Tilly", "your bed").
func point_to(label: String, pos: Vector3) -> void:
	what = label
	target = pos
	_left = SHOW_SECONDS
	queue_redraw()


func is_pointing() -> bool:
	return target.is_finite() and _left > 0.0


func stop() -> void:
	target = Vector3.INF
	_left = 0.0
	visible = false


func _process(delta: float) -> void:
	tick(delta)


## The clock and the player's place (tests call it with any step).
func tick(delta: float) -> void:
	if not is_pointing():
		if visible:
			visible = false
		return
	_left -= delta
	if _left <= 0.0 or not is_instance_valid(player) or not player.is_spawned():
		stop()
		return
	update(player.global_position, player.rig.yaw)
	visible = is_pointing() and not covered.call()


## Turns the arrow from `from` for a camera turned to `yaw`; close enough counts as arrived.
func update(from: Vector3, yaw: float) -> void:
	if not target.is_finite():
		return
	var r := SurpriseRules.compass(from, target, yaw)
	angle = r.angle
	distance = r.distance
	if distance <= ChatCommands.FIND_HERE and absf(target.y - from.y) < ChatCommands.FIND_HIGH:
		var found := what
		stop()
		arrived.emit(found)
		return
	queue_redraw()


func _draw() -> void:
	var c := Vector2(SIZE.x * 0.5, DIAL + 6.0)
	draw_circle(c, DIAL, DIAL_COLOR)
	draw_arc(c, DIAL, 0.0, TAU, 40, RIM_COLOR, 4.0)
	var dir := Vector2(sin(angle), -cos(angle))
	var tip := c + dir * (DIAL - 8.0)
	var back := c - dir * (DIAL * 0.45)
	var side := Vector2(cos(angle), sin(angle)) * 12.0
	draw_colored_polygon(PackedVector2Array([tip, back + side, c, back - side]), ARROW_COLOR)
	draw_circle(c, 5.0, RIM_COLOR)
	var font := get_theme_default_font()
	var dist_text := tr("%d m") % maxi(distance, 0)
	draw_string_outline(font, Vector2(0, SIZE.y - 6), dist_text, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 26, 6, Color(0, 0, 0, 0.85))
	draw_string(font, Vector2(0, SIZE.y - 6), dist_text, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 26, Color("e8f4ff"))
	var name_y := SIZE.y + 22.0
	draw_string_outline(font, Vector2(-40, name_y), atr(what), HORIZONTAL_ALIGNMENT_CENTER, SIZE.x + 80, 20, 5, Color(0, 0, 0, 0.85))
	draw_string(font, Vector2(-40, name_y), atr(what), HORIZONTAL_ALIGNMENT_CENTER, SIZE.x + 80, 20, Color.WHITE)   # M3 Task 21a
