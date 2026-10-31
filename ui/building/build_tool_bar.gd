class_name BuildToolBar
extends Control
## The building tools' bar (M3 Task 8): at the top centre, what to tap next for the tool in the hand ("Now tap
## the other corner!") and its buttons: CANCEL while a first tap waits, TURN and NEW COPY while the COPY tool holds
## a copy. It shows only while LINE, FILL or COPY is in the hand (a context bar: no always-visible HUD button),
## under the toasts and between the top corners' buttons, like SharePanel's picking bar.

const BAR_TOP := 130.0
const WIDTH := 560.0

var tools: BuildToolUser
var box := PanelContainer.new()
var words := Label.new()
var cancel_button := UiKit.big_button("CANCEL", UiKit.BLUE, Vector2(HudLayout.BUTTON, 72))
var turn_button := UiKit.big_button("TURN", UiKit.GREEN, Vector2(HudLayout.BUTTON, 72))
var new_copy_button := UiKit.big_button("NEW COPY", UiKit.ORANGE, Vector2(180, 72))


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	box.add_theme_stylebox_override("panel", UiKit.box(Color(0.08, 0.1, 0.17, 0.9), 18, 12))
	box.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(box)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	box.offset_top = BAR_TOP
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_END
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	box.add_child(column)
	words = OnlineUi.words("", 26, WIDTH)
	words.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	column.add_child(words)
	cancel_button.name = "Cancel"
	turn_button.name = "Turn"
	new_copy_button.name = "NewCopy"
	column.add_child(OnlineUi.row([turn_button, new_copy_button, cancel_button], 14))


func setup(t: BuildToolUser) -> void:
	tools = t
	cancel_button.pressed.connect(tools.cancel)
	turn_button.pressed.connect(tools.turn)
	new_copy_button.pressed.connect(tools.new_copy)
	tools.state_changed.connect(refresh)
	refresh()


func refresh() -> void:
	if tools == null or not is_instance_valid(tools.interactor):
		visible = false
		return
	var hint := tools.hint()
	visible = hint != ""
	words.text = hint
	var copying := tools.interactor.selected_block() == ItemIds.COPY_TOOL and not tools.clipboard.is_empty()
	cancel_button.visible = tools.first != BuildToolUser.NO_CELL
	turn_button.visible = copying
	new_copy_button.visible = copying


## The bar's box, for the HUD's look area (its taps never build).
func blockers() -> Array[Control]:
	return [box]
