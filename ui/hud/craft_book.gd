class_name CraftBook
extends ScrollContainer
## The block palette's CRAFT page (owner feedback #34, spec §12.19): the picture recipe book, one RecipeCard
## per recipe in CraftRules.book's order (what can be made now first). A tap on a shining card asks the host
## to craft it (Session.request_craft); a tap on another says what is missing (`said`, the HUD's toast).
## Built only in Survivor, when it is shown (refresh); it follows Session.inventory_changed while visible.

signal said(text: String)

const COLUMNS := 4
const GAP := 8

## () -> Dictionary: where this game's player can craft now (Session.craft_stations_near); by hand only
## until the HUD sets it.
var stations_provider: Callable = func() -> Dictionary:
	return {Recipes.HAND: true, Recipes.TABLE: false, Recipes.FURNACE: false}

var _grid := GridContainer.new()


func _init() -> void:
	name = "CRAFT"
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", GAP)
	_grid.add_theme_constant_override("v_separation", GAP)
	add_child(_grid)


func _ready() -> void:
	Session.inventory_changed.connect(_on_inventory_changed)
	visibility_changed.connect(func() -> void:
		if is_visible_in_tree():
			refresh())


## The cards again, for what this player has and where they stand now.
func refresh() -> void:
	for c in _grid.get_children():
		_grid.remove_child(c)
		c.queue_free()
	var inv := Session.my_inventory
	var near: Dictionary = stations_provider.call()
	for r: Dictionary in CraftRules.book(inv, near):
		var card := RecipeCard.new(r, inv, near)
		card.pressed.connect(_on_card.bind(card))
		_grid.add_child(card)


func cards() -> Array[RecipeCard]:
	var out: Array[RecipeCard] = []
	for c in _grid.get_children():
		if c is RecipeCard and not c.is_queued_for_deletion():
			out.append(c)
	return out


func card_for(recipe_id: StringName) -> RecipeCard:
	for c in cards():
		if c.recipe_id == recipe_id:
			return c
	return null


func _on_card(card: RecipeCard) -> void:
	Audio.play(&"ui_click")
	if card.can:
		Session.request_craft(card.recipe_id)
	else:
		said.emit(card.why_text)


func _on_inventory_changed() -> void:
	if is_visible_in_tree():
		refresh()
