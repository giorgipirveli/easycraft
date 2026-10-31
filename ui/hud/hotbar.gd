class_name Hotbar
extends HBoxContainer
## Nine block slots plus a palette button, bound to a BlockInteractor.
## Survivor (M2 Task 3, `counted`): each slot shows how many of it the player has
## (Session.my_inventory) and a slot with none is faded; it refreshes on Session.inventory_changed.

signal palette_requested

const SLOT_SIZE := Vector2(62, 62)
const FADED_ALPHA := 0.35

var counted := false   # set before setup()

var _interactor: BlockInteractor
var _slots: Array[TouchButton] = []
var _badges: Array[Label] = []
## P5 (VR draws): redraws of the row's frames as one batch in a headset (tests count them).
var vr_draws := 0


func setup(interactor: BlockInteractor) -> void:
	_interactor = interactor
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_theme_constant_override("separation", 6)
	for i in interactor.hotbar.size():
		var slot := _make_button()
		slot.pressed.connect(interactor.tap_slot.bind(i))   # a potion slot drinks it (M2 Task 6)
		var badge := make_badge()
		slot.add_child(badge)
		_badges.append(badge)
		_slots.append(slot)
		add_child(slot)
	var palette := _make_button()
	palette.text = "+"
	palette.font_size = 38
	# Open on release: the touch-down also produces an emulated mouse press that would hit the new overlay.
	palette.released.connect(func() -> void: palette_requested.emit())
	add_child(palette)
	interactor.selection_changed.connect(func(_slot: int, _id: int) -> void: refresh())
	Session.inventory_changed.connect(refresh)
	refresh()


func refresh() -> void:
	if not is_instance_valid(_interactor):   # the player's; freed with it when a LAN host quits
		return
	var inv := Session.my_inventory
	for i in _slots.size():
		var id := _interactor.hotbar[i]
		var n := inv.count(id) if counted and not ItemIds.is_free_tool(id) else -1   # M3 Task 8: paint is free
		_slots[i].icon = BlockIcons.icon(id)
		_slots[i].selected = i == _interactor.selected_slot
		_slots[i].modulate.a = FADED_ALPHA if n == 0 else 1.0
		_badges[i].text = badge_text(id, n)
		_slots[i].queue_redraw()
	_vr_redraw()   # P5: in a headset the row draws the frames (the selected one, the faded ones)


## The number on slot i ("" for none).
func count_text(slot: int) -> String:
	return _badges[slot].text


func is_faded(slot: int) -> bool:
	return _slots[slot].modulate.a < 1.0


## The count shown for `n` of `id` (n < 0: not counted). Blocks always show theirs; a single tool
## or item needs no number.
static func badge_text(id: int, n: int) -> String:
	if n <= 0 or (n == 1 and not BlockIds.is_valid(id)):
		return ""
	return str(n)


## A count in the bottom-right corner of a slot or palette button.
static func make_badge(font_size: int = 20) -> Label:
	var badge := Label.new()
	badge.add_theme_font_size_override("font_size", font_size)
	badge.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	badge.add_theme_constant_override("outline_size", 6)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	badge.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	badge.offset_right = -5
	badge.offset_bottom = -1
	return badge


func _make_button() -> TouchButton:
	var b := TouchButton.new()
	b.round_shape = false
	b.custom_minimum_size = SLOT_SIZE
	b.frame_drawn_by_parent = true   # P5: in a headset the row draws every frame at once (_draw); a phone as before
	b.pressed.connect(_vr_redraw)
	b.released.connect(_vr_redraw)
	return b


func _vr_redraw() -> void:
	if GraphicsPreset.vr_session:
		queue_redraw()


## P5 (VR draws): in a headset's HUD canvas (drawn every frame into the tray) the slots' frames are one draw, under the
## slots, which draw only their pictures and numbers then: the row was 22 draws, a frame and a picture each.
func _draw() -> void:
	if GraphicsPreset.vr_session:
		vr_draws += 1
		var m := vr_frames()
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), m.indices, m.points, m.colors)


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN and GraphicsPreset.vr_session:
		queue_redraw.call_deferred()   # the slots moved: their frames with them


## P5: the row's frames as one triangle list ({points, colors, indices}): each slot's cached frame moved to its place
## (native calls only), the row's indices kept for its number of slots.
static var _row_indices := {}


func vr_frames() -> Dictionary:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var one: Dictionary = {}
	var n := 0
	for c: Node in get_children():
		if c is TouchButton and (c as TouchButton).visible and (c as TouchButton).frame_drawn_by_parent:
			one = (c as TouchButton).frame_mesh()
			points.append_array(Transform2D(0.0, (c as TouchButton).position) * (one.points as PackedVector2Array))
			colors.append_array(one.colors)
			n += 1
	if n == 0:
		return {"points": points, "colors": colors, "indices": PackedInt32Array()}
	var per := (one.points as PackedVector2Array).size()
	var key := "%d|%d" % [n, per]
	if not _row_indices.has(key):
		var row := PackedInt32Array()
		for k in n:
			for i: int in one.indices:
				row.append(k * per + i)
		_row_indices[key] = row
	return {"points": points, "colors": colors, "indices": _row_indices[key]}
