class_name RecipeCard
extends Button
## One recipe in the CRAFT tab's picture book (spec §12.19): the result's picture with its count ("×4"), each
## ingredient's picture with have/need ("1/2", orange when short), and where it is made (the crafting table's
## or the furnace's picture; nothing for "by hand"). A card that can be made now shines: a gold rim.

const SIZE := Vector2(236, 118)
const RESULT := 56.0
const INGREDIENT := 30.0
const STATION := 26.0
const SHINE := Color("ffd23f")
const SHORT := Color("ff9a3d")
const DIM := Color(0.62, 0.66, 0.74)

var recipe_id: StringName
var can := false
## What a tap says when it can't be made (CraftRules.message).
var why_text := ""

var _recipe: Dictionary
var _result := TextureRect.new()
var _count := Label.new()
var _lines: Array[Label] = []
var _station: StringName


func _init(recipe: Dictionary, inv: Inventory, stations_near: Dictionary) -> void:
	_recipe = recipe
	recipe_id = recipe.id
	_station = recipe.at
	var error := CraftRules.refusal(recipe, inv, stations_near)
	can = error == ""
	why_text = CraftRules.message(error, recipe, inv)
	custom_minimum_size = SIZE
	tooltip_text = tr("Craft: %s") % Lang.t(ItemIds.display_name(int(recipe.makes)))
	focus_mode = Control.FOCUS_NONE
	_style()
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 8)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 10
	row.offset_top = 8
	row.offset_right = -10
	row.offset_bottom = -8
	add_child(row)
	var left := VBoxContainer.new()
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(left)
	_result.texture = BlockIcons.icon(int(recipe.makes))
	_result.custom_minimum_size = Vector2(RESULT, RESULT)
	_result.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_result.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_result.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.add_child(_result)
	var n := int(recipe.count)
	_count.text = "×%d" % n if n > 1 else ""
	_label(_count, 20, Color.WHITE)
	_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	left.add_child(_count)
	var needs := VBoxContainer.new()
	needs.mouse_filter = Control.MOUSE_FILTER_IGNORE
	needs.alignment = BoxContainer.ALIGNMENT_CENTER
	needs.add_theme_constant_override("separation", 2)
	needs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(needs)
	var want: Dictionary = recipe.needs
	for id: int in want:
		var line := HBoxContainer.new()
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_theme_constant_override("separation", 6)
		var icon := TextureRect.new()
		icon.texture = BlockIcons.icon(id)
		icon.custom_minimum_size = Vector2(INGREDIENT, INGREDIENT)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		line.add_child(icon)
		var have := inv.count(id)
		var text := Label.new()
		text.text = CraftRules.have_need(have, int(want[id]))
		_label(text, 18, Color.WHITE if have >= int(want[id]) else SHORT)
		line.add_child(text)
		_lines.append(text)
		needs.add_child(line)
	if _station != Recipes.HAND:
		var where := TextureRect.new()
		where.texture = BlockIcons.icon(Recipes.station_block(_station))
		where.custom_minimum_size = Vector2(STATION, STATION)
		where.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		where.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		where.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		where.mouse_filter = Control.MOUSE_FILTER_IGNORE
		where.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		where.modulate = Color.WHITE if bool(stations_near.get(_station, false)) else Color(1, 1, 1, 0.45)
		row.add_child(where)


func shines() -> bool:
	return can


func result_icon() -> Texture2D:
	return _result.texture


## "×4", or "" for one.
func count_text() -> String:
	return _count.text


## Each ingredient's "have/need", in the recipe's order.
func have_need_lines() -> Array[String]:
	var out: Array[String] = []
	for l in _lines:
		out.append(l.text)
	return out


func station() -> StringName:
	return _station


func _style() -> void:
	for state in ["normal", "hover", "pressed", "focus"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.14, 0.2, 0.12, 0.97) if can else Color(0.1, 0.12, 0.2, 0.95)
		if state == "pressed":
			box.bg_color = box.bg_color.lightened(0.12)
		box.border_color = SHINE if can else DIM.darkened(0.3)
		box.set_border_width_all(5 if can else 2)
		box.set_corner_radius_all(12)
		add_theme_stylebox_override(state, box)


static func _label(l: Label, font_size: int, color: Color) -> void:
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
