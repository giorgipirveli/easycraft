class_name AvatarEditor
extends HBoxContainer
## The avatar editor (M3 Task 9; spec §5.9, §14.6), in the main menu and the pause menu: a turning 3D
## preview on the left (either style), picture tabs and big picture tiles on the right. Tapping a tile
## tries it on at once, even a locked one; a locked item shows its fixed gold price (BUY) or how it is
## earned. DONE keeps only what is owned (AvatarUnlocks.wearable) and saves.
##
## Gold: outside a world (and in a Sandbox world) BUY spends the profile's Survivor gold itself
## (AvatarUnlocks.buy); in a Survivor world the host decides (world_economy: Session.request_cosmetic_buy).
## profile / save_profile can be swapped (tests).

signal closed

const TAB_WORDS := {
	AvatarCatalog.SKIN: "SKIN", AvatarCatalog.FACE: "FACE", AvatarCatalog.HAIR: "HAIR", AvatarCatalog.HAT: "HAT",
	AvatarCatalog.SHIRT: "SHIRT", AvatarCatalog.PANTS: "PANTS", AvatarCatalog.CLOTHES: "CLOTHES",
	AvatarCatalog.CAPE: "CAPE", AvatarCatalog.WINGS: "WINGS", AvatarCatalog.TRAIL: "TRAIL", AvatarCatalog.OUTFIT: "COSTUME",   # Owner 36
	AvatarCatalog.EMOTE: "DANCE",
}
## The picture on each tab: an item of that slot.
const TAB_PICTURES := {
	AvatarCatalog.SKIN: &"peach", AvatarCatalog.FACE: &"grin", AvatarCatalog.HAIR: &"spiky", AvatarCatalog.HAT: &"crown",
	AvatarCatalog.SHIRT: &"red", AvatarCatalog.PANTS: &"jeans", AvatarCatalog.CLOTHES: &"dress", AvatarCatalog.CAPE: &"hero",
	AvatarCatalog.WINGS: &"angel", AvatarCatalog.TRAIL: &"rainbow", AvatarCatalog.OUTFIT: &"knight", AvatarCatalog.EMOTE: &"cheer",
}
const TAB_SIZE := Vector2(130, 64)
const TILE_SIZE := Vector2(124, 124)
const WHEEL_TILE := Vector2(92, 92)
const COLUMNS := 6
## Owner 48 (spec §14.6a): the first choice at the top, and the view of the ready-made looks it opens.
const LOOKS := &"looks"
const BASE_WORDS := {AvatarCatalog.BOY: "BOY", AvatarCatalog.GIRL: "GIRL", AvatarCatalog.NEUTRAL: "JUST ME"}
const BASE_SIZE := Vector2(108, 88)   # three over the 340 px preview
const PRESET_TILE := Vector2(180, 124)
const START_WORDS := "Tap a ready look, or change anything you like!"

var profile: ProfileData          # default: Profile.data
var save_profile := Callable()    # default: Profile.save + Profile.avatar_changed
## True in a Survivor world: the host takes the gold (Session).
var world_economy := false
## "blocky" or "realistic"; default: the profile's graphics style.
var preview_style := ""
## The look being edited (tried-on items included until DONE).
var look: AvatarLook
var tab: StringName = AvatarCatalog.SKIN

var preview := AvatarPreview.new(Vector2(340, 276))   # Owner 48: shorter, under BOY / GIRL / JUST ME
var message := Label.new()
var buy_button := UiKit.big_button("BUY", UiKit.ORANGE, Vector2(200, 72))
## Owner 35 (spec §18.5): WISH (a heart) on an item a grown-up could give (a pack's); in BUY's place.
var wish_button := OnlineUi.button(ShopWords.WISH, Color("c2185b"), Vector2(200, 72), &"heart")
var done_button := UiKit.big_button("DONE", UiKit.GREEN, Vector2(200, 72))
var gold_label := Label.new()

var _tabs: Array[AvatarTile] = []
var _bases: Array[AvatarTile] = []   # Owner 48: BOY / GIRL / JUST ME
var _tiles: Array[AvatarTile] = []
var _wheel: Array[AvatarTile] = []
var _wheel_slot := 0
var _grid := GridContainer.new()
var _scroll := ScrollContainer.new()
var _wheel_row := HBoxContainer.new()
var _style_buttons := {}
var _trying := ""        # the tried-on item that isn't owned ("" = none)
var _waiting := ""       # the item the host is being asked about (world_economy)


func _ready() -> void:
	if profile == null:
		profile = Profile.data
	if not save_profile.is_valid():
		save_profile = func() -> void:
			Profile.save()
			Profile.avatar_changed.emit()
	if preview_style == "":
		preview_style = str(profile.settings.get("style", "blocky"))
	var earned := _costumes_on_open()   # Owner 36: costumes already earned by playing
	look = profile.avatar.duplicate()
	add_theme_constant_override("separation", 20)
	_build_left()
	_build_right()
	Session.cosmetic_result.connect(_on_cosmetic_result)
	preview.set_style(preview_style)
	preview.set_look(look)
	select_tab(tab)
	_say_earned(earned)


func _build_left() -> void:
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 10)
	add_child(left)
	var bases := HBoxContainer.new()   # Owner 48: the first choice, at the top, over the preview
	bases.add_theme_constant_override("separation", 8)
	for b: StringName in AvatarCatalog.BASES:
		var t := AvatarTile.new(AvatarIcon.BASE, b, BASE_SIZE)
		t.caption = BASE_WORDS[b]
		t.look = look
		t.pressed.connect(choose_base.bind(b))
		bases.add_child(t)
		_bases.append(t)
	left.add_child(bases)
	left.add_child(preview)
	var styles := HBoxContainer.new()
	styles.add_theme_constant_override("separation", 10)
	for st: String in GraphicsPreset.STYLES:
		var b := UiKit.big_button("BLOCKY" if st == "blocky" else "REAL", Color(), Vector2(165, 56))
		b.add_theme_font_size_override("font_size", 24)
		b.pressed.connect(set_preview_style.bind(st))
		styles.add_child(b)
		_style_buttons[st] = b
	left.add_child(styles)
	var gold := HBoxContainer.new()
	gold.alignment = BoxContainer.ALIGNMENT_CENTER
	gold.add_theme_constant_override("separation", 10)
	var coin := CoinIcon.new(40.0)   # the gold counter's coin (M2 Task 7)
	gold.add_child(coin)
	gold_label.add_theme_font_size_override("font_size", 32)
	gold_label.add_theme_color_override("font_color", Color("ffd23f"))
	gold.add_child(gold_label)
	left.add_child(gold)


func _build_right() -> void:
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 8)
	add_child(right)
	var tab_grid := GridContainer.new()
	tab_grid.columns = COLUMNS
	tab_grid.add_theme_constant_override("h_separation", 6)
	tab_grid.add_theme_constant_override("v_separation", 6)
	for slot: StringName in AvatarCatalog.SLOTS:
		var t := AvatarTile.new(slot, TAB_PICTURES[slot], TAB_SIZE)
		t.caption = TAB_WORDS[slot]
		t.pressed.connect(select_tab.bind(slot))
		tab_grid.add_child(t)
		_tabs.append(t)
	right.add_child(tab_grid)
	_wheel_row.add_theme_constant_override("separation", 6)
	_wheel_row.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_child(_wheel_row)
	_scroll.custom_minimum_size = Vector2(COLUMNS * TILE_SIZE.x + (COLUMNS - 1) * 8 + 24, TILE_SIZE.y * 2 + 12)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 8)
	_grid.add_theme_constant_override("v_separation", 8)
	_scroll.add_child(_grid)
	right.add_child(_scroll)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	message.custom_minimum_size = Vector2(360, 72)
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 24)
	message.add_theme_color_override("font_color", Color("ffe9a8"))
	bottom.add_child(ReadAloud.button(func() -> String: return "Make your look. " + message.text, 56.0))   # M5 Task 1
	bottom.add_child(message)
	buy_button.visible = false
	buy_button.pressed.connect(buy)
	bottom.add_child(buy_button)
	wish_button.visible = false   # Owner 35
	wish_button.pressed.connect(wish)
	bottom.add_child(wish_button)
	save_button.visible = false   # M3 Task 21b
	save_button.pressed.connect(save_up)
	bottom.add_child(save_button)
	done_button.pressed.connect(done)
	bottom.add_child(done_button)
	right.add_child(bottom)


func tab_buttons() -> Array[AvatarTile]:
	return _tabs


func tiles() -> Array[AvatarTile]:
	return _tiles


func wheel_slots() -> Array[AvatarTile]:
	return _wheel


## Shows a tab's tiles (the hair tab has the hair colours first; the dance tab has the wheel on top).
func select_tab(slot: StringName) -> void:
	tab = slot
	for t in _tabs:
		t.selected = t.slot == slot
	for t in _tiles:
		t.free()   # never the tile being pressed: tabs rebuild the grid, tiles only pick
	_tiles.clear()
	var slots: Array[StringName] = [slot]
	if slot == AvatarCatalog.HAIR:
		slots = [AvatarCatalog.HAIR_COLOR, AvatarCatalog.HAIR]
	elif slot == LOOKS:
		slots = []
		_build_presets()
	elif slot == AvatarCatalog.OUTFIT:
		_build_costumes()   # Owner 36: the costume pack first
	for s: StringName in slots:
		for n: StringName in AvatarCatalog.items_in(s):
			var t := AvatarTile.new(s, n, TILE_SIZE)
			var id := AvatarCatalog.item_id(s, n)
			t.caption = AvatarCatalog.display_name(id) if n != &"none" or s == AvatarCatalog.CLOTHES else "NONE"
			t.animate_emote = s == AvatarCatalog.EMOTE
			t.look = look if s == AvatarCatalog.CLOTHES else null   # Owner 48: cuts in the child's colours
			t.pressed.connect(pick.bind(s, n))
			_grid.add_child(t)
			_tiles.append(t)
	_build_wheel(slot == AvatarCatalog.EMOTE)
	_scroll.custom_minimum_size.y = TILE_SIZE.y * (1 if slot == AvatarCatalog.EMOTE else 2) + 12
	preview.running = slot == AvatarCatalog.TRAIL
	_trying = ""
	refresh()


func _build_wheel(show: bool) -> void:
	for t in _wheel:
		t.free()
	_wheel.clear()
	_wheel_row.visible = show
	if not show:
		return
	for i in AvatarCatalog.WHEEL_SLOTS:
		var t := AvatarTile.new(AvatarCatalog.EMOTE, look.emotes[i], WHEEL_TILE)
		t.animate_emote = true
		t.pressed.connect(select_wheel_slot.bind(i))
		_wheel_row.add_child(t)
		_wheel.append(t)


## The wheel spot the next owned emote goes into.
func select_wheel_slot(i: int) -> void:
	_wheel_slot = clampi(i, 0, AvatarCatalog.WHEEL_SLOTS - 1)
	refresh()


## A tile was tapped: wear it (try it on if it is locked). An emote plays on the preview, and an owned
## one goes into the selected wheel spot.
func pick(slot: StringName, item_name: StringName) -> void:
	var id := AvatarCatalog.item_id(slot, item_name)
	var owned := AvatarUnlocks.is_owned(id, profile.cosmetics)
	if slot == AvatarCatalog.EMOTE:
		preview.play_emote(item_name)
		if owned:
			_put_on_wheel(item_name)
	else:
		look.set(String(slot), item_name)
		for built: StringName in WearRules.REPLACES:   # M3 Task 8: a catalogue item takes a built one off
			if WearRules.REPLACES[built] == String(slot):
				look.take_off(built)
		preview.set_look(look)
	_trying = "" if owned else id
	refresh()


func _put_on_wheel(emote_name: StringName) -> void:
	var at := look.emotes.find(emote_name)
	if at >= 0 and at != _wheel_slot:
		look.emotes[at] = look.emotes[_wheel_slot]
	look.emotes[_wheel_slot] = emote_name


## Buys the tried-on item at its fixed price.
func buy() -> void:
	if _trying == "" or not buy_button.visible or buy_button.disabled:
		return
	if world_economy:
		_waiting = _trying
		Session.request_cosmetic_buy(_trying)
		return
	_bought(_trying, AvatarUnlocks.buy(profile, _trying))


func _on_cosmetic_result(item: String, status: StringName) -> void:
	if item == _waiting:
		_waiting = ""
		_bought(item, status)


func _bought(id: String, status: StringName) -> void:
	message.text = AvatarUnlocks.message(status, id, profile.survivor_gold)
	if status == AvatarUnlocks.OK:
		save_profile.call()
		Audio.play(&"ding")
		if id == _trying:
			_trying = ""
		if AvatarCatalog.slot_of(id) == AvatarCatalog.EMOTE:
			_put_on_wheel(AvatarCatalog.name_of(id))
	refresh(false)


## Keeps what is owned and saves.
func done() -> void:
	profile.avatar = AvatarUnlocks.wearable(look, profile.cosmetics)
	save_profile.call()
	closed.emit()


func set_preview_style(style: String) -> void:
	preview_style = style
	preview.set_style(style)
	preview.set_look(look)
	refresh()


## Updates the gold, the tiles (worn, locked, prices), the wheel and the offer for a tried-on item.
func refresh(update_message: bool = true) -> void:
	gold_label.text = str(profile.survivor_gold)
	for st: String in _style_buttons:
		(_style_buttons[st] as Button).modulate = Color.WHITE if st == preview_style else Color(1, 1, 1, 0.55)
	for t in _bases:   # Owner 48
		t.look = look
		t.selected = look.base == t.item
		t.queue_redraw()
	for t in _tiles:
		if t.slot == AvatarIcon.COSTUME:   # Owner 36
			_refresh_costume(t)
			continue
		if t.slot == AvatarIcon.PRESET:   # Owner 48: ready looks are free parts
			t.look = look
			t.locked = false
			t.price = 0
			t.selected = AvatarLook.preset(t.item, look).equals(look)
			continue
		if t.slot == AvatarCatalog.CLOTHES:
			t.look = look
		var id := AvatarCatalog.item_id(t.slot, t.item)
		t.locked = not AvatarUnlocks.is_owned(id, profile.cosmetics)
		t.price = AvatarCatalog.price(id) if t.locked else 0
		t.rarity_color = AvatarCatalog.RARITY_COLORS[AvatarCatalog.rarity(id)]
		t.selected = look.emotes.has(t.item) if t.slot == AvatarCatalog.EMOTE else look.get(String(t.slot)) == t.item
		t.wished = WishList.has(profile, id)   # Owner 35: a heart on what is on the wish list
	for i in _wheel.size():
		_wheel[i].item = look.emotes[i]
		_wheel[i].selected = i == _wheel_slot
		_wheel[i].queue_redraw()
	_update_offer(update_message)


func _update_offer(update_message: bool) -> void:
	_update_wish()   # Owner 35
	if _trying == "":
		buy_button.visible = false
		save_button.visible = false   # M3 Task 21b
		if update_message:
			message.text = ""
		return
	var status := AvatarUnlocks.check_buy(_trying, profile.cosmetics, profile.survivor_gold)
	var gold_item := status == AvatarUnlocks.OK or status == AvatarUnlocks.NOT_ENOUGH
	buy_button.visible = gold_item
	buy_button.disabled = status != AvatarUnlocks.OK or _waiting != ""
	buy_button.text = tr("BUY %d") % AvatarCatalog.price(_trying)
	_update_saving(status)   # M3 Task 21b: SAVE UP in BUY's place while the gold isn't there yet
	if update_message:
		message.text = AvatarUnlocks.message(status, _trying, profile.survivor_gold) if status != AvatarUnlocks.OK \
			else AvatarCatalog.display_name(_trying)


# --- Owner 35: the wish list (spec §18.5) ---
# A pack item (AvatarCatalog.PACK: only in what a grown-up buys) shows no price and no BUY; WISH puts it on
# the child's wish list, which the grown-up area shows. Nothing here tells the child to ask anyone.

## WISH: puts the tried-on item on the wish list, or takes it off.
func wish() -> void:
	if _trying == "" or not wish_button.visible:
		return
	var had := WishList.has(profile, _trying)
	var on := WishList.toggle(profile, _trying)
	message.text = ShopWords.wished(on) if on or had else ShopWords.WISH_FULL
	save_profile.call()
	refresh(false)


func _update_wish() -> void:
	var giftable := _trying != "" and WishList.can_wish(_trying, profile)
	wish_button.visible = giftable
	if giftable:
		wish_button.text = ShopWords.WISHED if WishList.has(profile, _trying) else ShopWords.WISH


# --- Owner 48: boy and girl looks (spec §14.6a) ---
# BOY / GIRL / JUST ME at the top: a first choice that puts on a matching starting look (the skin tone and
# the dance wheel stay) and shows the ready-made looks, one tap each. Never a lock: every tab still mixes
# anything with anything, and nothing here is for sale.

func base_buttons() -> Array[AvatarTile]:
	return _bases


## The first choice: a new one puts on its starting look; the same one again only shows the ready looks.
func choose_base(b: StringName) -> void:
	if not AvatarCatalog.BASES.has(b):
		return
	if look.base != b:
		look = AvatarLook.start(b, look)
		preview.set_look(look)
	select_tab(LOOKS)
	message.text = START_WORDS


## A ready-made look (AvatarCatalog.PRESETS), keeping the skin tone and the dance wheel.
func pick_preset(id: StringName) -> void:
	if not AvatarCatalog.PRESETS.has(id):
		return
	look = AvatarLook.preset(id, look)
	preview.set_look(look)
	_trying = ""
	refresh(false)
	message.text = str(AvatarCatalog.PRESETS[id].name)


## The ready looks' tiles, the ones of the chosen start first.
func _build_presets() -> void:
	for id: StringName in AvatarCatalog.presets_for(look.base):
		var t := AvatarTile.new(AvatarIcon.PRESET, id, PRESET_TILE)
		t.caption = str(AvatarCatalog.PRESETS[id].name)
		t.look = look
		t.pressed.connect(pick_preset.bind(id))
		_grid.add_child(t)
		_tiles.append(t)

# --- M3 Task 21b: SAVE UP (the saving list, research R3) ---
# A gold item the child can't afford yet shows SAVE UP in BUY's place (the same spot: the editor stays its width); it
# goes on the saving list, whose bar fills with the child's gold (the book's SAVING tab, under the HUD's gold). A pack
# item keeps owner #35's WISH; nothing here spends gold.

var save_button := UiKit.big_button(SavingRules.SAVE_WORD, UiKit.BLUE, Vector2(200, 72))


func _update_saving(status: StringName) -> void:
	var on := SavingRules.has(profile.wonder, SavingRules.LOOK, _trying)
	save_button.visible = status == AvatarUnlocks.NOT_ENOUGH
	if save_button.visible:
		buy_button.visible = false
		save_button.text = SavingRules.SAVING_WORD if on else SavingRules.SAVE_WORD


## SAVE UP: the tried-on gold item on (or off) the saving list.
func save_up() -> void:
	if _trying == "" or not save_button.visible:
		return
	var was := SavingRules.has(profile.wonder, SavingRules.LOOK, _trying)
	var on := SavingRules.toggle(profile.wonder, SavingRules.LOOK, _trying, profile)
	message.text = SavingRules.ON_WORDS if on else (SavingRules.OFF_WORDS if was else SavingRules.FULL_WORDS)
	save_profile.call()
	refresh(false)

# --- Owner 36: the Storybook costume pack (spec §14.6b) ---
# The OUTFIT tab is the COSTUME tab: the pack's costumes first (one tap puts on the whole look, keeping the skin tone,
# the first choice and the dance wheel), then the outfits. A locked costume can be tried on and says how it is earned
# (never a price, never a wish); DONE keeps only what is owned. Opening the editor gives the costumes the child has
# already earned by playing (CostumeRules.sync), a profile from before the pack too.

const EARNED_ONE := "New costume: %s! Tap COSTUME to try it on."
const EARNED_MANY := "New costumes: %s! Tap COSTUME to try them on."
const EARNED_SHOWN := 3   # names in the message at most (then "and N more")


## A costume tile was tapped: the whole costume goes on (tried on when it isn't earned yet).
func pick_costume(id: StringName) -> void:
	if not CostumeRules.has(id):
		return
	look = CostumeRules.wear(id, look)
	preview.set_look(look)
	var owned := CostumeRules.is_complete(id, profile.cosmetics)
	_trying = "" if owned else CostumeRules.item_id(id)
	refresh(false)
	message.text = tr(AvatarCatalog.display_name(CostumeRules.item_id(id))) if owned else CostumeRules.line(id)


func _build_costumes() -> void:
	for id: StringName in CostumeRules.ORDER:
		var t := AvatarTile.new(AvatarIcon.COSTUME, id, TILE_SIZE)
		t.caption = AvatarCatalog.display_name(CostumeRules.item_id(id))
		t.look = look
		t.pressed.connect(pick_costume.bind(id))
		_grid.add_child(t)
		_tiles.append(t)


func _refresh_costume(t: AvatarTile) -> void:
	t.look = look
	t.locked = not CostumeRules.is_complete(t.item, profile.cosmetics)
	t.price = 0
	t.wished = false
	t.rarity_color = AvatarCatalog.RARITY_COLORS[AvatarCatalog.rarity(CostumeRules.item_id(t.item))]
	t.selected = CostumeRules.wear(t.item, look).equals(look)


## Gives what the child's play has already earned and saves it at once.
func _costumes_on_open() -> Array[String]:
	var got := CostumeRules.sync(profile)
	if not got.is_empty():
		save_profile.call()
	return got


func _say_earned(got: Array[String]) -> void:
	var names: Array[String] = []
	for n in CostumeRules.names_in(got):
		names.append(tr(n))   # M3 Task 21a: in the game's language
	if names.is_empty():
		return
	if names.size() == 1:
		message.text = tr(EARNED_ONE) % names[0]
		return
	var first := names.slice(0, mini(names.size(), EARNED_SHOWN) - 1)
	var last := names[first.size()]
	if names.size() > EARNED_SHOWN:
		first.append(last)
		last = tr("%d more") % (names.size() - EARNED_SHOWN)
	message.text = tr(EARNED_MANY) % (tr("%s and %s") % [", ".join(first), last])
