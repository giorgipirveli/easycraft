class_name ShortsTab
extends Button
## The Theater's SHORTS tab, first of its picture tabs (owner #94, spec §5.12b): a tall screen with a play sign over
## the word SHORTS, the same size and look as the channels' tabs (TheaterPanel.ChannelTab), in the Shorts' pink.

const TITLE := "SHORTS"
const COLOUR := Color("d9437a")

var picture: ShortsIcon
var label := Label.new()


func _init(size_px: Vector2) -> void:
	name = "ShortsTab"
	tooltip_text = "EasyCraft Shorts"
	custom_minimum_size = size_px
	clip_contents = true
	toggle_mode = true
	focus_mode = Control.FOCUS_NONE
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 4
	column.offset_right = -4
	column.offset_top = 6
	column.offset_bottom = -4
	column.add_theme_constant_override("separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	picture = ShortsIcon.new(&"shorts", 36.0)
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(picture)
	label.text = TITLE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 14)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(label)
