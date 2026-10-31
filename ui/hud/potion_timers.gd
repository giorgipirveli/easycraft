class_name PotionTimers
extends HBoxContainer
## The HUD's potion timers (M2 Task 6): a small chip per working potion with its icon and the
## seconds left, in PotionRules order. Top-centre-left (Hud places it), never taking a tap. The last
## seconds turn orange and stay steady: nothing blinks (no flashing, lead's ruling).

const CHIP_SIZE := Vector2(92, 48)
const LOW_SECONDS := 5
const TEXT_COLOR := Color.WHITE
const LOW_COLOR := Color("ffab3d")

## The local player whose potions are shown (set by Hud.setup).
var player: Player

var _chips := {}      # potion id -> PanelContainer
var _labels := {}     # potion id -> Label
var _shown := {}      # potion id -> the whole seconds on its label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_theme_constant_override("separation", 6)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for id: int in PotionRules.EFFECTS:
		_add_chip(id)


func _add_chip(id: int) -> void:
	var chip := PanelContainer.new()
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.custom_minimum_size = CHIP_SIZE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.1, 0.17, 0.8)
	box.border_color = PotionRules.color(id)
	box.set_border_width_all(3)
	box.set_corner_radius_all(12)
	box.set_content_margin_all(4)
	chip.add_theme_stylebox_override("panel", box)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 4)
	chip.add_child(row)
	var icon := TextureRect.new()
	icon.texture = BlockIcons.icon(id)
	icon.custom_minimum_size = Vector2(38, 38)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)
	var label := Label.new()
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 5)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)
	chip.visible = false
	add_child(chip)
	_chips[id] = chip
	_labels[id] = label


## Potions whose chips show now, in order.
func shown() -> Array[int]:
	var ids: Array[int] = []
	for id: int in _chips:
		if (_chips[id] as Control).visible:
			ids.append(id)
	return ids


func seconds_text(id: int) -> String:
	return (_labels[id] as Label).text


func text_color(id: int) -> Color:
	return (_labels[id] as Label).get_theme_color("font_color")


## Cheap per frame: three numbers compared; a label changes only when its whole seconds do.
func _process(_delta: float) -> void:
	var valid := is_instance_valid(player)
	for id: int in _chips:
		var left := player.potions.time_left(id) if valid else 0.0
		var on := left > 0.0
		var chip := _chips[id] as Control
		if chip.visible != on:
			chip.visible = on
		if not on:
			_shown.erase(id)
			continue
		var whole := ceili(left)
		if _shown.get(id, -1) != whole:
			_shown[id] = whole
			var label := _labels[id] as Label
			label.text = str(whole)
			label.add_theme_color_override("font_color", LOW_COLOR if whole <= LOW_SECONDS else TEXT_COLOR)
