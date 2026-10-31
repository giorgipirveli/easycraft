class_name BlockPalette
extends Control
## Full-screen overlay with every placeable block plus a golden row of magic items; picking one
## puts it in the selected hotbar slot.
## Tapping outside the panel closes it (and never reaches the world behind it).
## Two pages (M2 Task 6): BLOCKS (blocks, MAGIC, TOOLS) and ARMORY (every tier, and potions).
## Survivor (M2 Task 3, `counted`): only what the player owns (Session.my_inventory), with counts.
## Survivor games and crafting (spec §12.19): a third page, CRAFT, the picture recipe book (CraftBook), in
## Survivor only; the ARMORY tab shows in the Sandbox only.

signal picked(block_id: int)

const BUTTON_SIZE := Vector2(86, 86)   # 4 block rows, MAGIC, TOOLS and the page tabs fit above the hotbar
const GAP := 4
const COLUMNS := 8
## More blocks widen the grid instead of adding a row (M2 Tasks 5 and 8): with the M2 blocks it is 11
## wide and 3 rows high, so the palette stays above the hotbar.
const MAX_BLOCK_ROWS := 3
## Blocks that go with the magic, in the MAGIC row after the wand and the stamps (M3 Task 20a: the saddle, built
## into a buddy to ride it).
const MAGIC_BLOCKS: Array[int] = [BlockIds.SADDLE,
	BlockIds.PUMPKIN, BlockIds.JACK_O_LANTERN, BlockIds.SNOWMAN_HEAD]   # M3 Task 21c: things the wand wakes
## M3 Task 21b: the SMART page's HOME row — the trophy shelf (the world owner's badges as trophies) and the bookshelf
## (a tap opens the books). The MAGIC row was full (it is as wide as the screen allows).
const HOME_BLOCKS: Array[int] = [BlockIds.TROPHY_SHELF, BlockIds.BOOKSHELF,
	BlockIds.LAB_BENCH,   # spec §23: a tap opens the Science Lab
	BlockIds.XYLOPHONE, BlockIds.DRUM]   # owner #110: the music blocks (a tap plays them; mallets in VR)
const HOME_COLOR := Color("e0b36a")

var _grid := GridContainer.new()
## M7 (the browser's freezes): the HUD's palette is built the first time it opens (open, show_page), not when it enters
## the tree: a world switch built its ~330 nodes with the rest of the HUD in one frame. Set before adding it.
var build_later := false
var _built := false


func _ready() -> void:
	visible = false
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if not build_later:
		_build()


## The pages (once; open and show_page ask for it).
func _build() -> void:
	if _built:
		return
	_built = true
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.35)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.08, 0.1, 0.16, 0.92)
	box.set_corner_radius_all(16)
	box.set_content_margin_all(16)
	panel.add_theme_stylebox_override("panel", box)
	add_child(panel)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 10)
	panel.add_child(outer)
	outer.add_child(_tabs())

	var column := VBoxContainer.new()
	column.name = "BLOCKS"
	column.add_theme_constant_override("separation", 8)
	outer.add_child(column)
	_grid.columns = block_columns()
	_grid.add_theme_constant_override("h_separation", GAP)
	_grid.add_theme_constant_override("v_separation", GAP)
	column.add_child(_grid)
	for id in BlockIds.PLACEABLE:
		_grid.add_child(_button(id, false))
	var magic := HBoxContainer.new()
	magic.add_theme_constant_override("separation", GAP)
	var label := Label.new()
	label.text = "MAGIC"
	label.add_theme_color_override("font_color", Color("ffd23f"))
	label.add_theme_font_size_override("font_size", 24)
	label.custom_minimum_size.x = BUTTON_SIZE.x * 2 + GAP
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	magic.add_child(label)
	for id in ItemIds.MAGIC:
		magic.add_child(_button(id, true))
	for id in MAGIC_BLOCKS:   # M3 Task 20a
		magic.add_child(_button(id, true))
	column.add_child(magic)
	var tools := _tools_row()
	column.add_child(tools)
	_add_owned_view(column, [_grid, magic, tools], column.get_combined_minimum_size())
	outer.add_child(_armory_page())
	outer.add_child(_smart_page())   # M3 Task 7
	outer.add_child(_gifts_page())   # M4 I: friends' builds as stamps
	outer.add_child(craft_book)   # spec §12.19
	outer.add_child(_pets_page())   # M3 Task 11: pet treats
	outer.add_child(_build_page())   # M3 Task 8: the building tools and the paints
	outer.add_child(_stamps_page())   # M3 Task 20b: My Stamps
	outer.add_child(_mobs_page())   # owner #51
	_pages = [column, outer.get_node("ARMORY"), outer.get_node("SMART"), outer.get_node("GIFTS"), craft_book, outer.get_node("PETS"),
		outer.get_node("BUILD"), outer.get_node("STAMPS"), outer.get_node("MOBS")]
	_fit(panel)
	show_page(0)


## Columns of the block grid: COLUMNS, or more so that every block fits in MAX_BLOCK_ROWS rows.
static func block_columns() -> int:
	return maxi(COLUMNS, ceili(BlockIds.PLACEABLE.size() / float(MAX_BLOCK_ROWS)))


func _button(id: int, magic: bool) -> Button:
	var b := Button.new()
	b.icon = BlockIcons.icon(id)
	b.expand_icon = true
	b.custom_minimum_size = BUTTON_SIZE
	b.tooltip_text = ItemIds.display_name(id)
	if magic:
		var gold := StyleBoxFlat.new()
		gold.bg_color = Color(0.35, 0.26, 0.05, 0.95)
		gold.border_color = Color("ffd23f")
		gold.set_border_width_all(3)
		gold.set_corner_radius_all(10)
		gold.set_content_margin_all(8)
		b.add_theme_stylebox_override("normal", gold)
	b.pressed.connect(_on_pick.bind(id))
	return b


func open() -> void:
	_build()
	tab_bar.set_tab_hidden(1, counted)   # Survivor: one page of what the player owns; ARMORY offers every tier
	tab_bar.set_tab_hidden(SMART_PAGE, counted)   # M3 Task 7's smart blocks are the Sandbox's
	tab_bar.set_tab_hidden(CRAFT_PAGE, not counted)   # spec §12.19: crafting is Survivor's (Sandbox has it all)
	if counted:
		show_page(0)
		_show_owned()
	_gifts_open()   # M4 I
	_build_open()   # M3 Task 8
	_stamps_open()   # M3 Task 20b
	visible = true


func _on_pick(id: int) -> void:
	visible = false
	picked.emit(id)


## Taps on the dimmed area (outside the panel) close the palette.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and (event as InputEventMouseButton).pressed:
		visible = false
		accept_event()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"pause"):
		visible = false
		get_viewport().set_input_as_handled()


# --- TOOLS row: weapons, tools and targets (M1b Task 11) ---

## Slightly smaller buttons, so the label and all eight items fit the width of the block grid.
const TOOL_BUTTON_SIZE := Vector2(80, 80)


func _tools_row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", GAP)
	var label := Label.new()
	label.text = "TOOLS"
	label.add_theme_color_override("font_color", Color("9fd3ff"))
	label.add_theme_font_size_override("font_size", 22)
	label.custom_minimum_size.x = BUTTON_SIZE.x
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	for id in ItemIds.TOOLS:
		var b := _button(id, false)
		b.custom_minimum_size = TOOL_BUTTON_SIZE
		var steel := StyleBoxFlat.new()
		steel.bg_color = Color(0.12, 0.2, 0.3, 0.95)
		steel.border_color = Color("9fd3ff")
		steel.set_border_width_all(3)
		steel.set_corner_radius_all(10)
		steel.set_content_margin_all(8)
		b.add_theme_stylebox_override("normal", steel)
		row.add_child(b)
	return row


# --- Survivor: only what the player owns, with counts (M2 Task 3) ---

## Survivor counts blocks: set before the palette opens.
var counted := false

## A little smaller than the Sandbox buttons, so a long list's scrollbar fits beside the grid.
const OWNED_BUTTON_SIZE := Vector2(82, 82)

var _sandbox_rows: Array[Control] = []   # every block, MAGIC and TOOLS
var _owned_scroll := ScrollContainer.new()
var _owned := GridContainer.new()
var _empty_hint := Label.new()


func _add_owned_view(column: VBoxContainer, sandbox_rows: Array[Control], room: Vector2) -> void:
	_sandbox_rows = sandbox_rows
	_owned_scroll.custom_minimum_size = room
	_owned_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_owned_scroll.visible = false
	_owned.columns = COLUMNS
	_owned.add_theme_constant_override("h_separation", GAP)
	_owned.add_theme_constant_override("v_separation", GAP)
	var box := VBoxContainer.new()
	box.add_child(_owned)
	_empty_hint.text = "Nothing yet! Break blocks to collect them."
	_empty_hint.add_theme_font_size_override("font_size", 28)
	_empty_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_hint.custom_minimum_size.x = room.x
	box.add_child(_empty_hint)
	_owned_scroll.add_child(box)
	column.add_child(_owned_scroll)
	Session.inventory_changed.connect(_on_inventory_changed)


func _on_inventory_changed() -> void:
	if visible and counted:
		_show_owned()


## The Survivor view: a button with a count for everything the player owns, in the order they got it.
func _show_owned() -> void:
	for row in _sandbox_rows:
		row.visible = false
	_owned_scroll.visible = true
	for child in _owned.get_children():
		_owned.remove_child(child)
		child.queue_free()
	var inv := Session.my_inventory
	for id in inv.ids():
		if not ItemIds.is_hotbar_valid(id):
			continue
		var b := _button(id, ItemIds.MAGIC.has(id))
		b.custom_minimum_size = OWNED_BUTTON_SIZE
		if b.icon == null:
			b.text = ItemIds.display_name(id)
			b.clip_text = true
		var badge := Hotbar.make_badge(24)
		badge.text = Hotbar.badge_text(id, inv.count(id))
		badge.name = "Count"
		b.add_child(badge)
		_owned.add_child(b)
	if Vr.active():   # owner #110 (VR-WONDER): the lenses are free tools in a headset, owned or not
		for id: int in ItemIds.LENSES:
			if not inv.ids().has(id):
				var lens := _button(id, false)
				lens.custom_minimum_size = OWNED_BUTTON_SIZE
				_owned.add_child(lens)
	_empty_hint.visible = _owned.get_child_count() == 0


## The number shown on id's button in the Survivor view ("" for none, or when it isn't shown).
func count_text(id: int) -> String:
	if not _owned_scroll.visible:
		return ""
	for b in _owned.get_children():
		if (b as Button).tooltip_text == ItemIds.display_name(id):
			return (b.get_node("Count") as Label).text
	return ""


func empty_hint() -> Label:
	return _empty_hint

# --- ARMORY page (M2 Task 6) ---
# Rows by tier (WOOD to COSMIC, names in the rarity colours of §13.2), then POTIONS. The wood sword,
# bow, pickaxe and axe stay in the TOOLS row, so the WOOD row starts with the spear, mace and shield.
# Every tier item's button has a rim in its rarity colour (its icon also counts the tier in pips).

const ARMORY_KINDS: Array[int] = [ItemIds.SPEAR, ItemIds.MACE, ItemIds.SHIELD_WOOD, ItemIds.SWORD, ItemIds.BOW,
	ItemIds.PICKAXE, ItemIds.AXE]
const PANEL_SHIFT := 40.0        # the panel sits this far above the middle (clear of the hotbar)

var tab_bar := TabBar.new()
var _pages: Array[Control] = []


## Shows page i (0 BLOCKS, 1 ARMORY, 2 SMART, 3 CRAFT).
func show_page(i: int) -> void:
	_build()
	for k in _pages.size():
		_pages[k].visible = k == i
	if tab_bar.current_tab != i:
		tab_bar.current_tab = i


func _tabs() -> TabBar:
	var tabs := tab_bar
	tabs.add_tab("BLOCKS")
	tabs.add_tab("ARMORY")
	tabs.add_tab("SMART")   # M3 Task 7: smart blocks and Game Blocks
	tabs.add_tab("GIFTS")   # M4 I: friends' builds as stamps
	tabs.add_tab("CRAFT")   # spec §12.19
	tabs.add_tab("PETS")   # M3 Task 11: pet treats
	tabs.add_tab("BUILD")   # M3 Task 8: the building tools and the paints
	tabs.add_tab("STAMPS")   # M3 Task 20b: My Stamps
	tabs.add_tab("MOBS")   # owner #51: every animal, monster and boss (Sandbox)
	tabs.tab_changed.connect(show_page)
	tabs.add_theme_font_size_override("font_size", 24)
	for state in ["tab_selected", "tab_unselected", "tab_hovered"]:
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.2, 0.26, 0.4, 1.0) if state == "tab_selected" else Color(0.1, 0.13, 0.2, 0.9)
		box.set_corner_radius_all(8)
		box.content_margin_left = 22
		box.content_margin_right = 22
		box.content_margin_top = 8
		box.content_margin_bottom = 8
		tabs.add_theme_stylebox_override(state, box)
	return tabs


func _armory_page() -> Control:
	var page := BoxContainer.new()   # a row: the tier grid, then the BLASTERS (M3 Task 14b) and GADGETS (14a) columns
	page.name = "ARMORY"
	page.add_theme_constant_override("separation", GAP * 4)
	var grid := GridContainer.new()
	grid.columns = 1 + ARMORY_KINDS.size()
	grid.add_theme_constant_override("h_separation", GAP)
	grid.add_theme_constant_override("v_separation", GAP)
	page.add_child(grid)
	for tier in WeaponRules.TIER_NAMES.size():
		grid.add_child(_row_label(WeaponRules.TIER_NAMES[tier].to_upper(), ItemRarity.color(ItemRarity.of_tier(tier))))
		var cells := 0
		for kind in ARMORY_KINDS:
			var id: int = WeaponRules.TIERS[kind][tier]
			if ItemIds.ARMORY.has(id):
				grid.add_child(_armory_button(id))
				cells += 1
		_pad(grid, ARMORY_KINDS.size() - cells)
	grid.add_child(_row_label("POTIONS", Color("9fe3ff")))
	for id in ItemIds.POTIONS:
		grid.add_child(_armory_button(id))
	_pad(grid, ARMORY_KINDS.size() - ItemIds.POTIONS.size())
	page.add_child(_blasters_column())   # M3 Task 14b
	page.add_child(_gadgets_column())   # M3 Task 14a
	return page


## M3 Task 14b: the BLASTERS column right of the tier rows, common to legendary (rims in their rarity).
const BLASTER_COLOR := Color("ff9a3c")


func _blasters_column() -> Control:
	var column := VBoxContainer.new()
	column.name = "BLASTERS"
	column.add_theme_constant_override("separation", GAP)
	column.add_child(_row_label("BLASTERS", BLASTER_COLOR))
	for id in ItemIds.BLASTERS:
		column.add_child(_armory_button(id))
	return column


func _row_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	label.add_theme_constant_override("outline_size", 5)
	label.custom_minimum_size = Vector2(BUTTON_SIZE.x, TOOL_BUTTON_SIZE.y)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label


func _armory_button(id: int) -> Button:
	var b := _button(id, false)
	b.custom_minimum_size = TOOL_BUTTON_SIZE
	var rarity := ItemRarity.of_item(id)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.1, 0.12, 0.2, 0.95)
	box.border_color = ItemRarity.color(rarity) if rarity >= 0 else Color("9fe3ff")
	box.set_border_width_all(4 if rarity >= 0 else 3)
	box.set_corner_radius_all(10)
	box.set_content_margin_all(6)
	b.add_theme_stylebox_override("normal", box)
	return b


func _pad(grid: GridContainer, n: int) -> void:
	for i in n:
		var gap := Control.new()
		gap.custom_minimum_size = TOOL_BUTTON_SIZE
		gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grid.add_child(gap)


## Sizes every page like the biggest one and centres the panel on it, a little above the middle.
func _fit(panel: PanelContainer) -> void:
	var biggest := Vector2.ZERO
	for page in _pages:
		biggest = biggest.max(page.get_combined_minimum_size())
	for page in _pages:
		page.custom_minimum_size = biggest
	show_page(0)
	var need := panel.get_combined_minimum_size()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -ceilf(need.x * 0.5)
	panel.offset_right = ceilf(need.x * 0.5)
	panel.offset_top = -ceilf(need.y * 0.5) - PANEL_SHIFT
	panel.offset_bottom = ceilf(need.y * 0.5) - PANEL_SHIFT

# --- SMART page (M3 Task 7) ---
# Smart blocks (buttons, levers, plates, powered doors, lamps and their switch, teleport pads) and the Game
# Blocks (START, CHECKPOINT, FINISH, coins, the bounce pad), each row with its word; not in the BLOCKS grid,
# so that page keeps its size (the palette fits above the hotbar). Grids, not boxes: the TOOLS row stays the
# palette's second row of boxes.

const SMART_COLOR := Color("7ee0ff")
const GAME_COLOR := Color("8cf07a")
const SPACE_COLOR := Color("b9c7ff")   # spec §21d: the SPACE row of rocket parts
## Owner #110 (VR-WONDER): the LOOK row, the telescope and the magnifier, in a headset only (VrLens; off VR as before).
const LOOK_COLOR := Color("9fe3e6")


func _smart_page() -> Control:
	SmartPage.register()   # the icons come from its page (in a world, BlockLibrary.build registers it first)
	var page := VBoxContainer.new()
	page.name = "SMART"
	page.add_theme_constant_override("separation", 12)
	var rows: Array = [["SMART", SMART_COLOR, SmartPage.SMART_ROW], ["GAME", GAME_COLOR, SmartPage.GAME_ROW],
			["HOME", HOME_COLOR, HOME_BLOCKS],   # M3 Task 21b: the shelves
			["SPACE", SPACE_COLOR, RocketPage.SPACE_ROW]]   # spec §21d: rocket parts (a launch needs them bought)
	if Vr.active():
		rows.append(["LOOK", LOOK_COLOR, ItemIds.LENSES])   # owner #110 (VR-WONDER): the lenses, VR only
	for row: Array in rows:
		var grid := GridContainer.new()
		var ids: Array[int] = row[2]
		grid.columns = 1 + ids.size()
		grid.add_theme_constant_override("h_separation", GAP)
		grid.add_child(_row_label(row[0], row[1]))
		for id in ids:
			var b := _button(id, false)
			var box := StyleBoxFlat.new()
			box.bg_color = Color(0.1, 0.14, 0.2, 0.95)
			box.border_color = row[1]
			box.set_border_width_all(3)
			box.set_corner_radius_all(10)
			box.set_content_margin_all(8)
			b.add_theme_stylebox_override("normal", box)
			grid.add_child(b)
		page.add_child(grid)
	page.add_child(_crystal_row())   # owner 39: universe crystals
	return page

# --- Owner feedback #39: universe crystals (the Sandbox's SMART page) ---
## PORTALS: a frame, and a crystal of every universe the child reached (CrystalRules.sandbox_crystals): placed in a
## portal frame's core slot, a crystal opens a portal to its universe's Sandbox world. Survivor's owned view shows the
## crystals in the bag like everything else.

const CRYSTAL_COLOR := Color("c38bff")

var crystal_row := GridContainer.new()


func _crystal_row() -> Control:
	var ids: Array[int] = [BlockIds.PORTAL_FRAME]
	ids.append_array(CrystalRules.sandbox_crystals(Profile.data.universe_unlocked))
	crystal_row.name = "PORTALS"
	crystal_row.columns = 1 + ids.size()
	crystal_row.add_theme_constant_override("h_separation", GAP)
	crystal_row.add_child(_row_label("PORTALS", CRYSTAL_COLOR))
	for id in ids:
		var b := _button(id, false)
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.12, 0.08, 0.2, 0.95)
		box.border_color = CRYSTAL_COLOR
		box.set_border_width_all(3)
		box.set_corner_radius_all(10)
		box.set_content_margin_all(8)
		b.add_theme_stylebox_override("normal", box)
		crystal_row.add_child(b)
	return crystal_row

# --- GIFTS page (M4 Wave 3, agent I) ---
# Friends' builds as stamps (GiftStampBook: opened presents and bottles' tiny builds), one button each
# with who sent it; picking one puts it in the hotbar slot like the M1 stamps (placed whole; in Survivor
# paid with the blocks, like every stamp). The small x deletes one (tap it twice: SURE?). In Survivor the
# tab bar shows BLOCKS and GIFTS only, and only once there is a gift stamp.

const GIFTS_TAB := 3
const GIFT_COLUMNS := 6
const GIFT_COLOR := Color("ff8fd8")

var gifts_grid := GridContainer.new()
var _gifts_hint := Label.new()
var _gift_book: GiftStampBook          # tests give their own (default GiftStampBook.current())


func _gifts_page() -> Control:
	var page := VBoxContainer.new()
	page.name = "GIFTS"
	page.add_theme_constant_override("separation", 10)
	var label := _row_label("GIFTS", GIFT_COLOR)
	label.custom_minimum_size.x = BUTTON_SIZE.x * 2
	page.add_child(label)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, (BUTTON_SIZE.y + 30 + GAP) * 2)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	gifts_grid.columns = GIFT_COLUMNS
	gifts_grid.add_theme_constant_override("h_separation", GAP * 3)
	gifts_grid.add_theme_constant_override("v_separation", GAP)
	scroll.add_child(gifts_grid)
	page.add_child(scroll)
	_gifts_hint.text = "No gift stamps yet! Open presents from friends in PLAY ONLINE, FRIENDS, PRESENTS."
	_gifts_hint.add_theme_font_size_override("font_size", 24)
	_gifts_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_gifts_hint.custom_minimum_size.x = 600
	page.add_child(_gifts_hint)
	return page


func use_gift_book(book: GiftStampBook) -> void:
	_gift_book = book


func _book() -> GiftStampBook:
	return _gift_book if _gift_book != null else GiftStampBook.current()


## Fills the GIFTS page from the book (it changes while the game runs); Survivor's tabs.
func _gifts_open() -> void:
	for c in gifts_grid.get_children():
		gifts_grid.remove_child(c)
		c.queue_free()
	var book := _book()
	for slot in book.slots():
		gifts_grid.add_child(_gift_button(slot, book.stamp(slot)))
	_gifts_hint.visible = book.slots().is_empty()
	var has_gifts := not book.slots().is_empty()
	tab_bar.visible = true   # Survivor always has CRAFT (spec §12.19), so its tabs always show
	for i in tab_bar.tab_count:
		if counted:   # Survivor: BLOCKS, CRAFT, BUILD (M3 Task 8: paint), and GIFTS once there is a gift stamp
			tab_bar.set_tab_hidden(i, not (i == 0 or i == CRAFT_PAGE or i == BUILD_TAB or i == STAMPS_TAB   # M3 Task 20b
				or (i == GIFTS_TAB and has_gifts)))
		else:   # Sandbox: everything but CRAFT (it has every block already)
			tab_bar.set_tab_hidden(i, i == CRAFT_PAGE)


func _gift_button(slot: int, stamp: Dictionary) -> Control:
	var cell := VBoxContainer.new()
	cell.name = "Gift_%d" % slot
	cell.add_theme_constant_override("separation", 2)
	var b := _button(GiftStampBook.item_of(slot), true)
	b.name = "Pick"
	b.tooltip_text = _book().name_of(slot)
	cell.add_child(b)
	var who := Label.new()
	who.text = str(stamp.get("from", ""))
	who.add_theme_font_size_override("font_size", 16)
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	who.custom_minimum_size.x = BUTTON_SIZE.x
	who.clip_text = true
	cell.add_child(who)
	var x := Button.new()
	x.name = "Delete"
	x.text = "x"
	x.tooltip_text = "Delete"
	x.add_theme_font_size_override("font_size", 20)
	x.custom_minimum_size = Vector2(36, 36)
	x.position = Vector2(BUTTON_SIZE.x - 30, -6)
	x.pressed.connect(_delete_gift.bind(slot, x))
	b.add_child(x)
	return cell


## The first tap asks (SURE?), the second deletes the stamp from this device.
func _delete_gift(slot: int, x: Button) -> void:
	if x.text != "SURE?":
		x.text = "SURE?"
		x.custom_minimum_size = Vector2(80, 36)
		return
	var book := _book()
	if book.remove(slot):
		if _gift_book == null:
			GiftStampBook.save_current()
	_gifts_open()

# --- Survivor games and crafting (spec §12.19): the CRAFT page -----------------------------------------------

const SMART_PAGE := 2
const CRAFT_PAGE := 4   # after M4 I's GIFTS (3)

## The picture recipe book (the HUD sets where the player can craft: CraftBook.stations_provider).
var craft_book := CraftBook.new()
# --- GADGETS (M3 Task 14a) ---
# Right of the tier rows on the ARMORY page: the action kit's gadgets (glider, hook, orbs, quick builds) and
# its two blocks (the zipline post and the launch pad), two to a row under the word, free in Sandbox.

const GADGET_COLOR := Color("ffd23f")
const GADGET_BLOCKS: Array[int] = [BlockIds.ZIPLINE_POST, BlockIds.LAUNCH_PAD]


func _gadgets_column() -> Control:
	PortalPage.register()   # the posts' and pads' icons come from page 10 (a world's BlockLibrary registers it too)
	var column := VBoxContainer.new()
	column.name = "GADGETS"
	column.add_theme_constant_override("separation", GAP)
	var label := _row_label("GADGETS", GADGET_COLOR)
	label.custom_minimum_size.x = TOOL_BUTTON_SIZE.x * 2 + GAP
	column.add_child(label)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", GAP)
	grid.add_theme_constant_override("v_separation", GAP)
	for id in ItemIds.GADGETS + GADGET_BLOCKS:
		var b := _armory_button(id)
		((b.get_theme_stylebox("normal") as StyleBoxFlat)).border_color = GADGET_COLOR
		grid.add_child(b)
	column.add_child(grid)
	return column
# --- M3 Task 11: the PETS page (pet treats) ---
# Its own page, so ARMORY keeps its height (a TREATS row there pushed the palette onto the hotbar). Free in
# Sandbox; in Survivor the treats bought from Tilly show with the other things owned.

const PETS_TAB := 5   # after M4 I's GIFTS (3) and CRAFT (4)
const TREAT_COLOR := Color("ff9ec4")


func _pets_page() -> Control:
	var page := VBoxContainer.new()
	page.name = "PETS"
	page.add_theme_constant_override("separation", 10)
	var row := GridContainer.new()   # a grid, not a box: the TOOLS row stays the palette's second box row
	row.columns = 1 + ItemIds.TREATS.size()
	row.add_theme_constant_override("h_separation", GAP)
	var label := _row_label("TREATS", TREAT_COLOR)
	label.custom_minimum_size.x = BUTTON_SIZE.x * 2 + GAP
	row.add_child(label)
	for id in ItemIds.TREATS:
		var b := _button(id, false)
		var box := StyleBoxFlat.new()
		box.bg_color = Color(0.2, 0.1, 0.18, 0.95)
		box.border_color = TREAT_COLOR
		box.set_border_width_all(3)
		box.set_corner_radius_all(10)
		box.set_content_margin_all(8)
		b.add_theme_stylebox_override("normal", box)
		row.add_child(b)
	page.add_child(row)
	var hint := Label.new()
	hint.text = "Hold a treat and tap your pet!"
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", TREAT_COLOR)
	page.add_child(hint)
	return page

# --- M3 Task 8: the BUILD page (the building tools and the paints) ---------------------------------------------
# Its own tab (the BLOCKS page's TOOLS row is full: the palette must fit above the hotbar): a TOOLS row (LINE,
# FILL, COPY, REWIND) and the 16 paint buckets in two rows. Survivor paints and rewinds (spec §14.5); LINE, FILL
# and COPY are the Sandbox's power tools, hidden there.

const BUILD_TAB := 6   # after M3 Task 11's PETS (5)
const BUILD_COLOR := Color("ffb347")
const PAINT_COLUMNS := 8
const POWER_TOOLS: Array[int] = [ItemIds.LINE_TOOL, ItemIds.FILL_TOOL, ItemIds.COPY_TOOL]

var _power_buttons: Array[Button] = []


func _build_page() -> Control:
	var page := VBoxContainer.new()
	page.name = "BUILD"
	page.add_theme_constant_override("separation", 10)
	var tools := GridContainer.new()   # grids, not boxes: the BLOCKS page's TOOLS row stays the palette's second box row
	tools.columns = 1 + ItemIds.BUILD_TOOLS.size()
	tools.add_theme_constant_override("h_separation", GAP)
	var label := _row_label("TOOLS", BUILD_COLOR)
	label.custom_minimum_size.x = BUTTON_SIZE.x * 2 + GAP
	tools.add_child(label)
	for id in ItemIds.BUILD_TOOLS:
		var b := _build_button(id, BUILD_COLOR)
		if POWER_TOOLS.has(id):
			_power_buttons.append(b)
		tools.add_child(b)
	page.add_child(tools)
	var paints := GridContainer.new()
	paints.columns = 1 + PAINT_COLUMNS
	paints.add_theme_constant_override("h_separation", GAP)
	paints.add_theme_constant_override("v_separation", GAP)
	for i in ItemIds.PAINTS.size():
		if i % PAINT_COLUMNS == 0:
			var word := _row_label("PAINT" if i == 0 else "", BUILD_COLOR)
			word.custom_minimum_size.x = BUTTON_SIZE.x * 2 + GAP
			paints.add_child(word)
		var id: int = ItemIds.PAINTS[i]
		paints.add_child(_build_button(id, PaintRules.color(PaintRules.tint_of_item(id))))
	page.add_child(paints)
	return page


func _build_button(id: int, rim: Color) -> Button:
	var b := _button(id, false)
	b.custom_minimum_size = TOOL_BUTTON_SIZE
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.14, 0.12, 0.1, 0.95)
	box.border_color = rim
	box.set_border_width_all(3)
	box.set_corner_radius_all(10)
	box.set_content_margin_all(8)
	b.add_theme_stylebox_override("normal", box)
	return b


## Survivor hides the power tools (the host refuses them there too).
func _build_open() -> void:
	for b in _power_buttons:
		b.visible = not counted

# --- M3 Task 20b: the STAMPS page (My Stamps) ---------------------------------------------------------------------
# The child's own stamps (MyStampBook, on this device): each with its picture (the front of the build, drawn from
# its blocks' tiles), its name and a small x (tap twice: SURE?); picking one puts it in the hotbar slot like the M1
# stamps (placed whole, one undo; in Survivor paid with its blocks). NEW STAMP closes the palette and the next tap
# on the world picks a build (the sandbox's MyStampBar). In both modes. No HBoxContainer here: the BLOCKS page's
# MAGIC and TOOLS rows stay the palette's first box rows (test_block_palette).

signal new_stamp_requested

const STAMPS_TAB := 7   # after M3 Task 8's BUILD (6)
const STAMP_COLOR := Color("b48cff")

var stamps_grid := GridContainer.new()
var stamps_hint := Label.new()
var new_stamp_button := Button.new()


func _stamps_page() -> Control:
	var page := VBoxContainer.new()
	page.name = "STAMPS"
	page.add_theme_constant_override("separation", 10)
	var top := GridContainer.new()
	top.columns = 2
	top.add_theme_constant_override("h_separation", GAP * 4)
	var label := _row_label("MY STAMPS", STAMP_COLOR)
	label.custom_minimum_size.x = BUTTON_SIZE.x * 2 + GAP
	top.add_child(label)
	new_stamp_button.name = "NewStamp"
	new_stamp_button.text = "+ NEW STAMP"
	new_stamp_button.icon = BlockIcons.my_stamp_icon()
	new_stamp_button.expand_icon = false
	new_stamp_button.add_theme_font_size_override("font_size", 24)
	new_stamp_button.custom_minimum_size = Vector2(260, BUTTON_SIZE.y)
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.2, 0.12, 0.35, 0.95)
	box.border_color = STAMP_COLOR
	box.set_border_width_all(3)
	box.set_corner_radius_all(10)
	box.set_content_margin_all(8)
	new_stamp_button.add_theme_stylebox_override("normal", box)
	new_stamp_button.pressed.connect(func() -> void:
		visible = false
		new_stamp_requested.emit())
	top.add_child(new_stamp_button)
	page.add_child(top)
	stamps_grid.columns = MyStampBook.SLOTS
	stamps_grid.add_theme_constant_override("h_separation", GAP * 3)
	page.add_child(stamps_grid)
	stamps_hint.text = "Save a build of yours as a stamp: tap NEW STAMP, then tap your build!"
	stamps_hint.add_theme_font_size_override("font_size", 22)
	stamps_hint.add_theme_color_override("font_color", STAMP_COLOR)
	stamps_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stamps_hint.custom_minimum_size.x = 600
	page.add_child(stamps_hint)
	return page


## Fills the STAMPS page from the device's book (it changes while the game runs).
func _stamps_open() -> void:
	for c in stamps_grid.get_children():
		stamps_grid.remove_child(c)
		c.queue_free()
	var book := MyStampBook.current()
	for slot in book.slots():
		stamps_grid.add_child(_stamp_cell(slot, book))
	stamps_hint.visible = book.slots().is_empty()
	new_stamp_button.disabled = book.is_full()
	new_stamp_button.tooltip_text = MyStampBook.message("full") if book.is_full() else ""


func _stamp_cell(slot: int, book: MyStampBook) -> Control:
	var cell := VBoxContainer.new()
	cell.name = "Stamp_%d" % slot
	cell.add_theme_constant_override("separation", 2)
	var b := Button.new()
	b.name = "Pick"
	b.custom_minimum_size = BUTTON_SIZE
	b.tooltip_text = MyStampBook.name_of(slot)
	var gold := StyleBoxFlat.new()
	gold.bg_color = Color(0.2, 0.12, 0.35, 0.95)
	gold.border_color = STAMP_COLOR
	gold.set_border_width_all(3)
	gold.set_corner_radius_all(10)
	b.add_theme_stylebox_override("normal", gold)
	b.pressed.connect(_on_pick.bind(MyStampBook.item_of(slot)))
	var pic := BuildPicture.new(BUTTON_SIZE.x - 16)
	pic.name = "Picture"
	pic.show_code(BuddyPicture.code_of(book.blocks_of(slot)))   # stamp z = 0 is the side the child saw: its front
	pic.position = Vector2(8, 8)
	pic.size = BUTTON_SIZE - Vector2(16, 16)
	b.add_child(pic)
	cell.add_child(b)
	var words := Label.new()
	words.text = MyStampBook.name_of(slot)
	words.add_theme_font_size_override("font_size", 16)
	words.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	words.custom_minimum_size.x = BUTTON_SIZE.x
	cell.add_child(words)
	var x := Button.new()
	x.name = "Delete"
	x.text = "x"
	x.tooltip_text = "Delete"
	x.add_theme_font_size_override("font_size", 20)
	x.custom_minimum_size = Vector2(36, 36)
	x.position = Vector2(BUTTON_SIZE.x - 30, -6)
	x.pressed.connect(_delete_stamp.bind(slot, x))
	b.add_child(x)
	return cell


## The first tap asks (SURE?), the second deletes the stamp from this device.
func _delete_stamp(slot: int, x: Button) -> void:
	if x.text != "SURE?":
		x.text = "SURE?"
		x.custom_minimum_size = Vector2(80, 36)
		return
	if MyStampBook.current().remove(slot):
		MyStampBook.save_current()
	_stamps_open()


# --- Owner #51: the MOBS page (every animal, monster and boss; Sandbox) ------------------------------------------
# "In sandbox add a mob version, where all the monsters or pets are": a tap closes the palette and asks for that
# creature in front of the child (the sandbox sends the host's /summon, so its checks and its chat line apply).
# Survivor has no MOBS tab (open() shows only Survivor's own tabs). Small tiles in grids, so the page keeps the
# palette's size above the hotbar and the BLOCKS page's MAGIC and TOOLS rows stay its first box rows. Pip is a pet
# (the PETS tab's treats), not a mob.

signal mob_requested(word: String)

const MOBS_TAB := 8   # after M3 Task 20b's STAMPS (7)
const MOB_TILE := Vector2(72, 72)
const MOB_COLUMNS := 14
const ANIMAL_COLOR := Color("9be07a")
const MONSTER_COLOR := Color("ff8a65")
const BOSS_COLOR := Color("ffd23f")
## The bosses' /summon words and their pictures (ProgressPictures).
const BOSS_PICTURES := {"golem": &"golem", "serpent": &"serpent", "giant": &"giant", "cake": &"cake",
	"skydragon": &"dragon"}


## The animals on the MOBS page: every /summon animal but Pip (a pet).
static func mob_animals() -> Array[String]:
	var out: Array[String] = []
	for w: String in ChatCommands.ANIMALS:
		if w != "pip":
			out.append(w)
	return out


func _mobs_page() -> Control:
	var page := VBoxContainer.new()
	page.name = "MOBS"
	page.add_theme_constant_override("separation", 4)
	_mob_group(page, "ANIMALS", ANIMAL_COLOR, mob_animals(), &"animal")
	_mob_group(page, "MONSTERS", MONSTER_COLOR, ChatCommands.MONSTERS, &"monster")
	_mob_group(page, "BOSSES", BOSS_COLOR, ChatCommands.BOSSES, &"boss")
	return page


func _mob_group(page: VBoxContainer, title: String, color: Color, words: Array[String], kind: StringName) -> void:
	var label := _row_label(title, color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.custom_minimum_size = Vector2(0, 26)
	page.add_child(label)
	var grid := GridContainer.new()
	grid.columns = MOB_COLUMNS
	grid.add_theme_constant_override("h_separation", GAP)
	grid.add_theme_constant_override("v_separation", GAP)
	for w: String in words:
		grid.add_child(_mob_tile(w, kind, color))
	page.add_child(grid)


func _mob_tile(word: String, kind: StringName, color: Color) -> Button:
	var b := Button.new()
	b.name = "Mob_%s" % word
	b.custom_minimum_size = MOB_TILE
	b.tooltip_text = word.replace("_", " ").capitalize()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.1, 0.13, 0.2, 0.95)
	box.border_color = color
	box.set_border_width_all(2)
	box.set_corner_radius_all(10)
	b.add_theme_stylebox_override("normal", box)
	var px := MOB_TILE.x - 12.0
	var pic: Control
	match kind:
		&"animal":
			pic = AnimalPortrait.new(StringName(word), px)
		&"monster":
			var m := AnimalPortrait.new(&"", px)
			m.monster = ChatCommands.monster_kind(word)
			pic = m
		_:
			pic = ProgressPicture.new(BOSS_PICTURES.get(word, &"monster"), px)
	pic.name = "Picture"
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pic.position = Vector2(6, 6)
	pic.size = MOB_TILE - Vector2(12, 12)
	b.add_child(pic)
	b.pressed.connect(func() -> void:
		visible = false
		mob_requested.emit(word))
	return b

