class_name ShortsSchool
extends Control
## LEARN IT on a School Short (owner #94, spec §5.12b): the School's page of that unit over the Theater (the screen
## dimmed, the School on the menu's panel in the middle, drawn smaller on a low screen), as the Lab's LEARN MORE shows
## it (spec §23): its LESSON and PRACTICE, as in the menu's School (the same profile: stars and gold for practising as
## ever, never for watching). The unit page's BACK, Esc or Android Back closes it and the Shorts are there again. The
## School is made only when LEARN IT is pressed.

signal closed

var screen: SchoolScreen
var _panel: PanelContainer


func _ready() -> void:
	name = "ShortsSchool"
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = UiKit.theme()


## The School on unit `unit_id`, with `profile` (and how to save it).
func open_unit(unit_id: String, profile: ProfileData, save_profile: Callable) -> void:
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
	screen = SchoolScreen.new()
	screen.profile = profile
	if save_profile.is_valid():
		screen.save_profile = save_profile
	screen.lab_link = true   # a lesson may say "tap TRY IT IN THE LAB": it works here as in the menu
	screen.home_unit = unit_id
	screen.closed.connect(close)
	_panel.add_child(screen)
	screen.show_unit(unit_id)
	visible = true
	_fit()
	Audio.play(&"ui_click")


func is_open() -> bool:
	return visible


func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()


## Android Back: true when the School was open (now closed).
func close_if_open() -> bool:
	if not visible:
		return false
	close()
	return true


## Circle / B on a controller, when nothing nearer takes it: back to the Shorts.
func pad_back() -> bool:
	return close_if_open()


func _fit() -> void:
	var room := get_viewport_rect().size if is_inside_tree() else Vector2(1280, 720)
	var need := _panel.get_combined_minimum_size()
	var s := minf(1.0, minf((room.y - 16.0) / maxf(need.y, 1.0), (room.x - 16.0) / maxf(need.x, 1.0)))
	_panel.scale = Vector2(s, s)
	_panel.pivot_offset = need * 0.5


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		close()
		get_viewport().set_input_as_handled()
