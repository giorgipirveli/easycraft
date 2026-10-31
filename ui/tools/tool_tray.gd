class_name ToolTray
extends CanvasLayer
## Owner #117 (docs/design/life-skills.md §13): flat play's hand. The room's tools in a row of big pictures along the
## bottom (over the practice room's HUD: LifeRoomHud.LAYER + 1): tap one to pick it up, it stays in the hand until another
## is picked. The right one glows when the job wants it ("the right tool for the job": the host says so kindly). In VR the
## tools are on the bench and taken by hand: the tray hides.

signal picked(tool_id: String)

const LAYER := 41
const SIZE := Vector2(104, 104)
const GLOW := Color(1.0, 0.86, 0.3)

var root: Control
var row: HBoxContainer
var buttons := {}
var selected := ""
var glowing := ""
var _t := 0.0


func _init() -> void:
	name = "ToolTray"
	layer = LAYER
	root = Control.new()
	root.name = "Root"
	root.theme = UiKit.theme()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	row = HBoxContainer.new()
	row.name = "Row"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	row.offset_top = -SIZE.y - 14
	row.offset_bottom = -14
	row.offset_left = -560
	row.offset_right = 560
	root.add_child(row)


## The tools to show (Tool Book ids).
func set_tools(ids: Array[String]) -> void:
	OnlineUi.clear(row)
	buttons.clear()
	for id in ids:
		var b := Button.new()
		b.name = "Tool_" + id
		b.custom_minimum_size = SIZE
		b.tooltip_text = ToolBook.name_of(id)
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		var pic := ToolIcons.new(ToolBook.icon(id), SIZE.x - 22)
		pic.name = "Picture"
		pic.position = Vector2(11, 6)
		b.add_child(pic)
		b.pressed.connect(select.bind(id))
		row.add_child(b)
		buttons[id] = b
	_refresh()


## Picks a tool up (flat): the one in the hand now.
func select(id: String) -> void:
	selected = id
	_refresh()
	picked.emit(id)


func glow(id: String) -> void:
	glowing = id
	_refresh()


func _refresh() -> void:
	for id: String in buttons:
		var b: Button = buttons[id]
		b.set_pressed_no_signal(id == selected)
		b.modulate = Color.WHITE


func _process(delta: float) -> void:
	_t += delta
	if glowing != "" and buttons.has(glowing) and glowing != selected:
		var k := 0.5 + 0.5 * sin(_t * TAU / 1.6)
		(buttons[glowing] as Button).modulate = Color.WHITE.lerp(GLOW, k * 0.8)


## The centre of a tool's button (canvas pixels), for the coach's ghost finger and the tests.
func centre_of(id: String) -> Vector2:
	var b: Button = buttons.get(id)
	return b.get_global_rect().get_center() if b != null else Vector2.ZERO
