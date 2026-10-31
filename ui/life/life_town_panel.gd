class_name LifeTownPanel
extends Control
## Owner #112 (docs/design/life-skills.md §7, Life Town; Life L2): Life over the world when a child walks up to one of
## Life Town's places (LifeTownDirector), like a Short's LEARN IT page over the Theater (ShortsSchool): the screen dimmed,
## Life in the middle (drawn smaller on a low screen), opened on that place's Experience: its unit on the child's track
## (the track picked first, the very first time) with LESSON, PRACTICE and TRY IT. TRY IT opens the practice room as in
## the School (the world's HUD hides while it shows). BACK, Esc or Android Back closes it; while a practice room is open,
## Android Back belongs to the room (its "Leave the practice?" card) and the panel stays.

signal closed

var screen: LifeScreen
var experience := ""
var _panel: PanelContainer


func _ready() -> void:
	name = "LifeTownPanel"
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.theme()


## Life on Experience `exp_id`, with `profile` (and how to save it); the game's own when not given.
func open_experience(exp_id: String, profile: ProfileData = null, save_profile: Callable = Callable()) -> void:
	if _panel == null:
		var dim := ColorRect.new()
		dim.color = Color(0, 0, 0, 0.55)
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(dim)
		var center := CenterContainer.new()
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(center)
		_panel = PanelContainer.new()
		center.add_child(_panel)
	if screen:
		_panel.remove_child(screen)
		screen.queue_free()
	experience = exp_id
	screen = LifeScreen.new()
	if profile != null:
		screen.profile = profile
	if save_profile.is_valid():
		screen.save_profile = save_profile
	screen.town_experience = exp_id
	screen.closed.connect(close)
	_panel.add_child(screen)
	visible = true
	_fit.call_deferred()
	Audio.play(&"ui_click")


func is_open() -> bool:
	return visible


## A practice room from this panel is showing now.
func room_open() -> bool:
	return visible and screen != null and is_instance_valid(screen.host) and not screen.host.closed


func close() -> void:
	if not visible:
		return
	if screen and is_instance_valid(screen.host) and not screen.host.closed:
		screen.host.stop_for_now()   # leaving (a pause menu, walking off): the calm way out, nothing lost
	visible = false
	closed.emit()


## Android Back: true when it was handled here (the panel closed, or a practice room's own card takes it).
func close_if_open() -> bool:
	if room_open():
		return true
	if not visible:
		return false
	close()
	return true


## What covers the world's look area while it shows (the HUD's look area must not take its touches).
func blockers() -> Array[Control]:
	return [self] as Array[Control]


func _fit() -> void:
	if _panel == null or not is_inside_tree():
		return
	var room := get_viewport_rect().size
	var need := _panel.get_combined_minimum_size()
	var s := minf(1.0, minf((room.y - 16.0) / maxf(need.y, 1.0), (room.x - 16.0) / maxf(need.x, 1.0)))
	_panel.scale = Vector2(s, s)
	_panel.pivot_offset = need * 0.5


func _unhandled_input(event: InputEvent) -> void:
	if visible and not room_open() and event.is_action_pressed(&"pause"):
		close()
		get_viewport().set_input_as_handled()
