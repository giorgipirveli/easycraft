class_name ShopPage
extends VBoxContainer
## The grown-up area's SHOP page (owner feedback #35, spec §18), made only by GrownUpsPanel, which the
## menus open only after the parent gate. Views: PLUS (EasyCraft Plus: its universes and set), PACKS
## (every pack on sale with its exact items), WISH LIST (the child's wishes, GIVE AS A GIFT), ALWAYS FREE,
## and RESTORE (asks the store what this account owns). BUY opens a confirm page that says what is
## bought, the price in the store's currency and "paid once"; only its PAY starts a purchase, and the
## store's own sheet follows. The words are for grown-ups (plain, no pressure; ShopWords).
##
## While the page shows, the shop may buy (ShopService.enter_grown_up_area); leaving it closes that.

const VIEW_PLUS := &"plus"
const VIEW_PACKS := &"packs"
const VIEW_WISHES := &"wishes"
const VIEW_FREE := &"free"
const VIEW_CONFIRM := &"confirm"
const TILE := Vector2(84, 84)
const WISH_TILE := Vector2(72, 72)
const MAX_WISH_ROWS := 2
const WIDTH := 1100.0

var shop: ShopService
var view: StringName = VIEW_PLUS
## The line under the view: the store's state, or what just happened.
var note := Label.new()
var body := VBoxContainer.new()
var tab_buttons := {}   # view -> Button

var _confirming := ""
var _back_view: StringName = VIEW_PLUS
var _wish_tab: Button


func _ready() -> void:
	add_theme_constant_override("separation", 10)
	shop.enter_grown_up_area()
	shop.changed.connect(_on_changed)
	shop.purchase_finished.connect(_on_purchase_finished)
	shop.restore_done.connect(_on_restore_done)
	var tabs: Array = []
	for v: StringName in [VIEW_PLUS, VIEW_PACKS, VIEW_WISHES, VIEW_FREE]:
		var words: String = {VIEW_PLUS: "PLUS", VIEW_PACKS: "PACKS", VIEW_WISHES: "WISH LIST", VIEW_FREE: "ALWAYS FREE"}[v]
		var b := _button(words, Color(), {VIEW_WISHES: 250.0, VIEW_FREE: 230.0}.get(v, 160.0))
		b.toggle_mode = true
		b.pressed.connect(show_view.bind(v))
		tab_buttons[v] = b
		tabs.append(b)
	_wish_tab = tab_buttons[VIEW_WISHES]
	var restore := _button("RESTORE", Color(), 200.0)
	restore.pressed.connect(_restore)
	tabs.append(restore)
	add_child(OnlineUi.row(tabs, 12))
	body.add_theme_constant_override("separation", 8)
	add_child(body)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(WIDTH, 0)
	note.add_theme_font_size_override("font_size", 22)
	note.add_theme_color_override("font_color", OnlineUi.HINT_COLOR)
	add_child(note)
	show_view(view)


func _exit_tree() -> void:
	shop.leave_grown_up_area()


## Shows a view with the store's state under it.
func show_view(v: StringName) -> void:
	view = v
	_rebuild()
	note.text = _base_note()


func _base_note() -> String:
	if view == VIEW_FREE:
		return ShopWords.TRUST
	if not shop.store_open():
		return ShopWords.STORE_OFF
	if view == VIEW_CONFIRM:
		var how := "through the test store: nothing is charged" if shop.is_test_store() else "through Google Play"
		return tr("Paid once %s. Nothing random: exactly this, kept on this account.") % how
	return ShopWords.TEST_STORE if shop.is_test_store() else ShopWords.TITLE_TRUST


func _rebuild() -> void:
	for key: StringName in tab_buttons:
		(tab_buttons[key] as Button).set_pressed_no_signal(key == view)
	_wish_tab.text = tr("WISH LIST (%d)") % shop.profile.wishes.size() if not shop.profile.wishes.is_empty() else "WISH LIST"
	OnlineUi.clear(body)
	match view:
		VIEW_PACKS:
			_packs_view()
		VIEW_WISHES:
			_wishes_view()
		VIEW_FREE:
			_free_view()
		VIEW_CONFIRM:
			_confirm_view()
		_:
			_plus_view()


# --- Views ---

func _plus_view() -> void:
	var p := ShopCatalog.PLUS
	body.add_child(OnlineUi.row([_words("%s · %s, %s" % [ShopCatalog.product_name(p), shop.price_words(p), ShopWords.ONE_TIME],
		28, 760.0), _buy_or_owned(p)], 16))
	var column := OnlineUi.column(4)
	column.add_child(_words(ShopCatalog.contents(p)[0] + ".", 22, 700.0))
	column.add_child(_words(tr("The Plus set: %s.") % ", ".join(_item_names(p)), 22, 700.0))
	body.add_child(OnlineUi.row([_tiles(p, TILE), column], 16))


func _packs_view() -> void:
	var cards: Array = []
	for id in ShopCatalog.for_sale():
		if id == ShopCatalog.PLUS:
			continue
		var card := OnlineUi.column(8)
		card.add_child(OnlineUi.row([_words("%s\n%s, %s" % [ShopCatalog.product_name(id), shop.price_words(id), ShopWords.ONE_TIME],
			24, 330.0), _buy_or_owned(id)], 12))
		card.add_child(_tiles(id, TILE))
		card.add_child(_words(", ".join(_item_names(id)), 20, 520.0))
		cards.append(card)
	body.add_child(OnlineUi.row(cards, 40))


func _wishes_view() -> void:
	var rows := WishList.for_grown_up(shop.profile, shop.prices)
	if rows.is_empty():
		body.add_child(_words("No wishes yet. In the avatar editor your child can tap WISH on a look from a pack.", 24, WIDTH))
		return
	body.add_child(_words("Your child's wish list. Gifts are optional; nothing is sent or shown to your child about prices.", 20, WIDTH))
	for i in mini(rows.size(), MAX_WISH_ROWS):
		body.add_child(_wish_row(rows[i]))
	if rows.size() > MAX_WISH_ROWS:
		body.add_child(_words(tr("%d more after these.") % (rows.size() - MAX_WISH_ROWS), 20, WIDTH))


func _wish_row(r: Dictionary) -> HBoxContainer:
	var parts: Array = []
	if AvatarCatalog.ITEMS.has(r.id):
		parts.append(_tile(r.id, WISH_TILE))
	var what := tr("%s: in the %s, %s") % [r.name, r.product_name, r.price] if r.id != r.product \
		else "%s, %s" % [r.name, r.price]
	if r.product == ShopCatalog.PLUS and r.id != r.product:
		what = tr("%s: comes with EasyCraft Plus, %s") % [r.name, r.price]
	parts.append(_words(what, 22, 620.0))
	if r.how == WishList.OWNED:
		parts.append(_words(ShopWords.OWNED_WORD, 24, 160.0))
	elif shop.store_open():
		var give := _button("GIVE AS A GIFT", UiKit.GREEN, 280.0)
		give.pressed.connect(_confirm.bind(str(r.product), VIEW_WISHES))
		parts.append(give)
	var row := OnlineUi.row(parts, 14)
	row.name = "Wish_" + str(r.id).replace(".", "_")
	return row


func _free_view() -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 30)
	grid.add_theme_constant_override("v_separation", 0)
	for key: StringName in ShopCatalog.FREE_FOREVER:
		var l := _words("• " + ShopCatalog.free_words(key), 20, 530.0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		grid.add_child(l)
	var center := CenterContainer.new()
	center.add_child(grid)
	body.add_child(center)


func _confirm_view() -> void:
	var p := _confirming
	var price := shop.price_words(p)
	var pay := _button("PAY " + price, UiKit.GREEN, 250.0)
	pay.pressed.connect(_pay.bind(p, pay))
	var back := _button("BACK", UiKit.BLUE, 160.0)
	back.pressed.connect(show_view.bind(_back_view))
	body.add_child(OnlineUi.row([_words(tr("You are buying: %s — %s, %s") % [ShopCatalog.product_name(p), price, ShopWords.ONE_TIME],
		26, 700.0), pay, back], 14))
	var column := OnlineUi.column(2)
	if p == ShopCatalog.PLUS:
		column.add_child(_words(ShopCatalog.contents(p)[0] + ".", 20, 700.0))
	column.add_child(_words(tr("Looks: %s.") % ", ".join(_item_names(p)), 20, 700.0))
	body.add_child(OnlineUi.row([_tiles(p, TILE), column], 16))


# --- Buying ---

func _buy_or_owned(product: String) -> Control:
	if shop.owns(product):
		return _words(ShopWords.OWNED_WORD + " ✓", 26, 150.0)
	if not shop.store_open():
		return Control.new()
	var b := _button("BUY", UiKit.ORANGE, 150.0)
	b.pressed.connect(_confirm.bind(product, view))
	return b


func _confirm(product: String, back_to: StringName) -> void:
	_confirming = product
	_back_view = back_to
	show_view(VIEW_CONFIRM)


func _pay(product: String, pay: Button) -> void:
	var status := shop.buy(product)
	if status != ShopService.STARTED:
		note.text = ShopWords.refusal(status)
		return
	pay.disabled = true
	note.text = ShopWords.WAITING


func _on_purchase_finished(product: String, status: StringName) -> void:
	if not is_inside_tree():
		return
	show_view(_back_view if view == VIEW_CONFIRM else view)
	note.text = ShopWords.result(status, product)


func _restore() -> void:
	note.text = ShopWords.RESTORING
	shop.restore()


func _on_restore_done(ok: bool, added: Array) -> void:
	if not is_inside_tree():
		return
	_rebuild()
	note.text = ShopWords.restored(ok, added)


func _on_changed() -> void:
	if is_inside_tree() and view != VIEW_CONFIRM:
		var said := note.text
		_rebuild()
		note.text = said


# --- Pieces ---

func _button(text: String, color: Color, width: float) -> Button:
	var b := OnlineUi.button(text, color, Vector2(width, 72))
	b.add_theme_font_size_override("font_size", 24)
	return b


func _words(text: String, font_size: int, width: float) -> Label:
	return OnlineUi.words(text, font_size, width)


func _item_names(product: String) -> Array[String]:
	var out: Array[String] = []
	for item in ShopCatalog.items_of(product):
		out.append(AvatarCatalog.display_name(item))
	return out


## A product's items as pictures (the avatar editor's tiles, not pressable).
func _tiles(product: String, size_px: Vector2) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	for item in ShopCatalog.items_of(product):
		row.add_child(_tile(item, size_px))
	return row


func _tile(item: String, size_px: Vector2) -> AvatarTile:
	var t := AvatarTile.new(AvatarCatalog.slot_of(item), AvatarCatalog.name_of(item), size_px)
	t.caption = AvatarCatalog.display_name(item)
	t.rarity_color = AvatarCatalog.RARITY_COLORS[AvatarCatalog.rarity(item)]
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t
