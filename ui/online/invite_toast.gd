class_name InviteToast
extends PanelContainer
## "Pip invites you to their world!" with JOIN and NOT NOW (M4 Wave 1, Agent C; spec §17.3), at the
## top of the screen over the menu or a game. It follows the OnlineService: a new invite shows, a
## cancelled one goes, and after SHOW_SECONDS it slips away quietly (no countdown, no pressure; the
## friends list keeps JOIN while the invite is open). Runs while the game is paused.

signal join_pressed(invite: Dictionary)

const SHOW_SECONDS := 30.0
const WIDTH := 640.0

var service: OnlineService:
	set(s):
		if is_instance_valid(service):
			service.invite_received.disconnect(show_invite)
			service.invite_cancelled.disconnect(_on_cancelled)
		service = s
		if is_instance_valid(s):
			s.invite_received.connect(show_invite)
			s.invite_cancelled.connect(_on_cancelled)
		if is_node_ready():
			dismiss()

var invite: Dictionary = {}
var text_label: Label
var world_label: Label
var join_button: Button
var later_button: Button

var _timer := Timer.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	theme = UiKit.theme()
	visible = false
	add_theme_stylebox_override("panel", UiKit.box(Color(0.1, 0.08, 0.22, 0.96), 22, 20))
	anchor_left = 0.5
	anchor_right = 0.5
	offset_left = -WIDTH * 0.5
	offset_right = WIDTH * 0.5
	offset_top = 20
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	var v := OnlineUi.column(12)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	var pic := OnlineIcon.new(&"friends")
	pic.custom_minimum_size = Vector2(64, 64)
	top.add_child(pic)
	var words := OnlineUi.column(2)
	text_label = OnlineUi.words("", 28, WIDTH - 120)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	world_label = OnlineUi.words("", 22, WIDTH - 120)
	world_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	words.add_child(text_label)
	words.add_child(world_label)
	top.add_child(words)
	v.add_child(top)
	join_button = OnlineUi.button("JOIN", UiKit.GREEN, Vector2(240, 80))
	join_button.pressed.connect(_join)
	later_button = OnlineUi.button("NOT NOW", UiKit.BLUE, Vector2(240, 80))
	later_button.pressed.connect(dismiss)
	v.add_child(OnlineUi.row([join_button, later_button], 24))
	add_child(v)
	_timer.one_shot = true
	_timer.wait_time = SHOW_SECONDS
	_timer.timeout.connect(dismiss)
	add_child(_timer)


func show_invite(inv: Dictionary) -> void:
	invite = inv
	text_label.text = OnlineRules.invite_text(inv)
	world_label.text = tr("A %s world") % inv.world_name if str(inv.get("world_name", "")) != "" else ""
	world_label.visible = world_label.text != ""
	visible = true
	_timer.start()


func dismiss() -> void:
	visible = false
	invite = {}
	_timer.stop()


## The toast's buttons, for the HUD's look area (a tap on them must not build).
func blockers() -> Array[Control]:
	return [self]


func _join() -> void:
	var inv := invite
	dismiss()
	if not inv.is_empty():
		if is_instance_valid(service):
			service.forget_invite(inv.match_id)
		join_pressed.emit(inv)


func _on_cancelled(match_id: String) -> void:
	if visible and invite.get("match_id") == match_id:
		dismiss()
