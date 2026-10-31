class_name LookBuildArea
extends Control
## Full-screen touch layer behind the other controls. A finger that drags looks around,
## a quick tap places the selected block, and holding still breaks the block under the finger.
## Touches that start on a blocker (joystick, buttons, hotbar, palette) are ignored.

var player: Player
var interactor: BlockInteractor
var blockers: Array[Control] = []

var _classifier := TouchClassifier.new()
var _last_pos := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _input(event: InputEvent) -> void:
	if player == null or not is_visible_in_tree() or not player.is_spawned():
		return
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if _blocked(t.position):
				return
			_classifier.down(t.index, t.position, _now())
			if _classifier.owns(t.index):
				_last_pos = t.position
				interactor.preview_at_screen(_target(t.position))
		elif _classifier.owns(t.index):
			var gesture := _classifier.up(t.index, t.position, _now(), t.canceled)
			interactor.clear_preview()
			if gesture == TouchClassifier.Gesture.TAP:
				interactor.place_at_screen(_target(t.position))
	elif event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if not _classifier.owns(d.index):
			return
		_last_pos = d.position
		if _classifier.move(d.index, d.position, _now()) == TouchClassifier.Gesture.DRAG:
			interactor.clear_preview()
			player.look_delta(d.relative)


## The game paused under the finger: forget it, or a late HOLD would break a block after RESUME
## (a finger lifted during the pause menu is never heard).
func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED:
		_classifier.cancel()
		if interactor:
			interactor.clear_preview()
			interactor.show_break_progress(null, -1.0)


func _process(_delta: float) -> void:
	if not is_instance_valid(interactor):   # the player's; freed with it when a LAN host quits
		return
	_update_break_ring()
	if _classifier.update(_now()) == TouchClassifier.Gesture.HOLD:
		interactor.clear_preview()
		interactor.break_at_screen(_target(_last_pos))


## Where a tap or hold acts: the crosshair in first person / crosshair mode, else the finger.
static func target_point(finger: Vector2, crosshair_mode: bool, screen_size: Vector2) -> Vector2:
	return screen_size * 0.5 if crosshair_mode else finger


func _target(finger: Vector2) -> Vector2:
	return target_point(finger, interactor.crosshair_mode, get_viewport().get_visible_rect().size)


func _blocked(pos: Vector2) -> bool:
	for b in blockers:
		if b.is_visible_in_tree() and b.get_global_rect().has_point(pos):
			return true
	return false


func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


## The break ring fills on the block under a finger that holds still, until it breaks (M2 Task 3).
## Only while a finger holds: otherwise it is one check that the ring is hidden.
func _update_break_ring() -> void:
	var progress := _classifier.hold_progress(_now())
	if progress < 0.0:
		interactor.show_break_progress(null, -1.0)
	else:
		interactor.show_break_progress(interactor.ray_at(_target(_last_pos)), progress)
