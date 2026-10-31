class_name PetPanel
extends Control
## A pet's picture card (M3 Task 11), opened by a tap on your own pet (BlockInteractor.pet_tapped): its
## name, a heart as big as it is happy (PetRules.heart_scale: never empty), SIT / COME, NAME (a list of fun
## names; a typed name through the username filter only for 13+) and COLLAR (8 colours). The host decides
## every change (Session section "M3 Task 11"); the card shows the pet's synced state. Small and in the
## middle, clear of the HUD's buttons (taps never reach them); it closes when the pet goes or strays far.

signal closed

const MAIN := &"main"
const NAMES := &"names"
const COLLARS := &"collars"
const CHEST_PAGE := &"chest"      # owner #41: a donkey's chest
const WIDTH := 440.0
const TOP := 150.0
const NAMES_PER_PAGE := 12
const NAME_COLUMNS := 4
const FAR := 14.0                 # the card closes when the pet is this far from its child
const PINK := Color("ff6fa5")

## The child's age band (Profile.data.age_band): 13+ may also type a name.
var band: StringName = AgeBand.unknown()
## Where this game's player stands (the card closes when the pet strays far); INF: don't check.
var player_position: Callable = func() -> Vector3: return Vector3.INF
var request_sit: Callable = func(animal_name: String) -> void: Session.request_pet(animal_name)
var request_name: Callable = func(animal_name: String, pet_name: String) -> void: Session.pet_request_name(animal_name, pet_name)
var request_collar: Callable = func(animal_name: String, c: int) -> void: Session.pet_request_collar(animal_name, c)
## Owner #41: a donkey's chest (the host decides) and what this child holds (PUT IN puts that stack in).
var request_chest_put: Callable = func(animal_name: String, item: int) -> void: Session.pet_request_chest_put(animal_name, item)
var request_chest_take: Callable = func(animal_name: String, slot: int) -> void: Session.pet_request_chest_take(animal_name, slot)
var held_item: Callable = func() -> int: return -1

var pet: Animal
var page: StringName = MAIN
var heart := PetHeart.new()
var message := Label.new()

var _box := PanelContainer.new()
var _content := VBoxContainer.new()
var _name_label: Label
var _sit: Button
var _name_page := 0
var _shown := {}


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_box.add_theme_stylebox_override("panel", UiKit.box(Color(0.1, 0.08, 0.16, 0.95), 22, 14))
	_box.mouse_filter = Control.MOUSE_FILTER_STOP
	_box.anchor_left = 0.5
	_box.anchor_right = 0.5
	_box.offset_left = -WIDTH * 0.5
	_box.offset_right = WIDTH * 0.5
	_box.offset_top = TOP
	add_child(_box)
	_content.add_theme_constant_override("separation", 10)
	_box.add_child(_content)
	heart.custom_minimum_size = Vector2(84, 84)
	message.add_theme_font_size_override("font_size", 20)
	message.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.custom_minimum_size.x = WIDTH - 60.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		for keep: Control in [heart, message]:   # off the tree on some pages: freed with the card
			if is_instance_valid(keep) and keep.get_parent() == null:
				keep.free()


func is_open() -> bool:
	return visible


func open(a: Animal) -> void:
	pet = a
	visible = true
	UiMotion.pop_in(self)   # owner #94: every panel pops in the same way
	_name_page = 0
	show_page(MAIN)


func close() -> void:
	if not visible:
		return
	visible = false
	pet = null
	closed.emit()


## The card's box, for the HUD's look area (its taps never build).
func blockers() -> Array[Control]:
	return [_box]


## Where the card is on a screen of this size.
func card_rect(screen: Vector2) -> Rect2:
	var need := _box.get_combined_minimum_size()
	return Rect2(Vector2(screen.x * 0.5 - WIDTH * 0.5, TOP), Vector2(maxf(need.x, WIDTH), need.y))


func show_page(p: StringName) -> void:
	page = p
	for keep: Control in [heart, message]:   # kept across pages
		if keep.get_parent():
			keep.get_parent().remove_child(keep)
	for c in _content.get_children():
		_content.remove_child(c)
		c.queue_free()
	message.text = ""
	match p:
		MAIN:
			_main_page()
		NAMES:
			_names_page()
		COLLARS:
			_collars_page()
		CHEST_PAGE:
			_chest_page()
	_box.offset_bottom = TOP + _box.get_combined_minimum_size().y
	_shown = {}
	_refresh()


func _process(_delta: float) -> void:
	if not visible:
		return
	if not is_instance_valid(pet) or pet.is_queued_for_deletion() or not pet.is_pet():
		close()
		return
	var me: Vector3 = player_position.call()
	if me.is_finite() and pet.global_position.distance_to(me) > FAR:
		close()
		return
	_refresh()


## Shows the pet's synced name, heart and sitting (only what changed).
func _refresh() -> void:
	if not is_instance_valid(pet):
		return
	var now := {"name": pet.pet_name, "heart": pet.happiness, "sitting": pet.sitting, "chest": pet.chest}
	if now == _shown:
		return
	_shown = now
	_show_chest()   # owner #41
	if _name_label:
		_name_label.text = pet.pet_name
	heart.fill = PetRules.heart_scale(pet.happiness)
	if _sit:
		_sit.text = "COME" if pet.sitting else "SIT"


func _main_page() -> void:
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	top.add_child(heart)
	_name_label = OnlineUi.words("", 36, WIDTH - 130.0)
	_name_label.name = "PetName"
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top.add_child(_name_label)
	_content.add_child(top)
	_sit = _button("SIT", UiKit.GREEN, "Sit", Vector2(190, 84))
	_sit.pressed.connect(func() -> void:
		if is_instance_valid(pet):
			request_sit.call(String(pet.name)))
	var rename := _button("NAME", UiKit.BLUE, "Name", Vector2(190, 84))
	rename.pressed.connect(show_page.bind(NAMES))
	var collar := _button("COLLAR", UiKit.ORANGE, "Collar", Vector2(190, 84))
	collar.pressed.connect(show_page.bind(COLLARS))
	var shut := _button("CLOSE", UiKit.RED, "Close", Vector2(190, 84))
	shut.pressed.connect(close)
	_content.add_child(OnlineUi.row([_sit, rename], 10))
	_content.add_child(OnlineUi.row([collar, shut], 10))
	if is_instance_valid(pet) and PetRules.has_perk(pet.species, PetRules.CHEST):   # owner #41: a donkey's chest
		var chest := _button("CHEST", Color("8a5a2b"), "Chest", Vector2(390, 84))
		chest.pressed.connect(show_page.bind(CHEST_PAGE))
		_content.add_child(chest)
	_content.add_child(message)


## A page of fun names (MORE NAMES shows the next page); 13+ may type one instead.
func _names_page() -> void:
	_name_label = null
	_sit = null
	_content.add_child(OnlineUi.words("Pick a name!", 28, WIDTH - 40.0))
	var grid := GridContainer.new()
	grid.columns = NAME_COLUMNS
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	var start := _name_page * NAMES_PER_PAGE
	for i in range(start, mini(start + NAMES_PER_PAGE, PetRules.FUN_NAMES.size())):
		var n: String = PetRules.FUN_NAMES[i]
		var b := _button(n, PINK.darkened(0.25), "Name_%d" % i, Vector2(97, 56))
		b.add_theme_font_size_override("font_size", 20)
		b.pressed.connect(_pick_name.bind(n))
		grid.add_child(b)
	_content.add_child(grid)
	if ChatRules.effective_band(band) == AgeBand.TEEN_PLUS:
		var field := LineEdit.new()
		field.name = "TypeName"
		field.placeholder_text = "Type a name"
		field.max_length = PetRules.MAX_NAME
		field.custom_minimum_size = Vector2(WIDTH - 180.0, 56)
		field.add_theme_font_size_override("font_size", 24)
		var ok := _button("OK", UiKit.GREEN, "TypeOk", Vector2(135, 56))
		ok.pressed.connect(func() -> void: _pick_name(field.text))
		_content.add_child(OnlineUi.row([field, ok], 10))
	var more := _button("MORE NAMES", UiKit.BLUE, "MoreNames", Vector2(200, 64))
	more.pressed.connect(func() -> void:
		_name_page = (_name_page + 1) % ceili(PetRules.FUN_NAMES.size() / float(NAMES_PER_PAGE))
		show_page(NAMES))
	var back := _button("BACK", UiKit.RED, "Back", Vector2(200, 64))
	back.pressed.connect(show_page.bind(MAIN))
	_content.add_child(OnlineUi.row([more, back], 10))
	_content.add_child(message)


func _pick_name(text: String) -> void:
	if not is_instance_valid(pet):
		return
	var why := PetRules.name_refusal(text, band)
	if why != "":
		message.text = PetRules.name_message(why)
		return
	request_name.call(String(pet.name), PetRules.clean_name(text))
	show_page(MAIN)


func _collars_page() -> void:
	_name_label = null
	_sit = null
	_content.add_child(OnlineUi.words("Pick a collar!", 28, WIDTH - 40.0))
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for i in PetRules.COLLARS.size():
		var b := Button.new()
		b.name = "Collar_%d" % i
		b.custom_minimum_size = Vector2(92, 80)
		b.focus_mode = Control.FOCUS_NONE
		var box := UiKit.box(PetRules.COLLARS[i], 14, 8)
		for state: String in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(state, box)
		b.pressed.connect(func() -> void:
			if is_instance_valid(pet):
				request_collar.call(String(pet.name), i)
			show_page(MAIN))
		grid.add_child(b)
	_content.add_child(grid)
	var back := _button("BACK", UiKit.RED, "Back", Vector2(WIDTH - 40.0, 64))
	back.pressed.connect(show_page.bind(MAIN))
	_content.add_child(back)


func _button(text: String, color: Color, button_name: String, min_size: Vector2) -> Button:
	var b := UiKit.big_button(text, color, min_size)
	b.name = button_name
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 24)
	return b


# --- Owner feedback #41: a donkey's chest (spec §14.19) ---

var _slots: Array[Button] = []


## Nine slots (a picture and a number each: a tap takes it back into the bag), PUT IN (the held stack goes in)
## and BACK. The host decides; the slots show the donkey's synced chest.
func _chest_page() -> void:
	_name_label = null
	_sit = null
	_slots.clear()
	_content.add_child(OnlineUi.words(tr("%s's chest") % pet.pet_name if is_instance_valid(pet) else "Chest", 28, WIDTH - 40.0))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	for i in DonkeyChest.SLOTS:
		var b := _button("", Color("5a3a22"), "Slot_%d" % i, Vector2(120, 76))
		b.expand_icon = false
		b.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_take_slot.bind(i))
		grid.add_child(b)
		_slots.append(b)
	_content.add_child(grid)
	var put := _button("PUT IN", UiKit.GREEN, "PutIn", Vector2(190, 64))
	put.pressed.connect(func() -> void:
		if is_instance_valid(pet):
			request_chest_put.call(String(pet.name), int(held_item.call())))
	var back := _button("BACK", UiKit.RED, "Back", Vector2(190, 64))
	back.pressed.connect(show_page.bind(MAIN))
	_content.add_child(OnlineUi.row([put, back], 10))
	_show_chest()


func _take_slot(i: int) -> void:
	if is_instance_valid(pet) and DonkeyChest.slot(pet.chest, i).y > 0:
		request_chest_take.call(String(pet.name), i)


## The slots show what the donkey carries now.
func _show_chest() -> void:
	if _slots.is_empty() or not is_instance_valid(pet):
		return
	for i in _slots.size():
		var b := _slots[i]
		if not is_instance_valid(b):
			continue
		var s := DonkeyChest.slot(pet.chest, i)
		b.text = str(s.y) if s.y > 0 else ""
		b.icon = BlockIcons.icon(s.x) if s.y > 0 else null
