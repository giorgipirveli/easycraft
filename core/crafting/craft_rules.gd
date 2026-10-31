class_name CraftRules
extends RefCounted
## Crafting (owner feedback #34, spec §12.19), pure: whether a player can make a recipe now and making it
## against their Inventory. A craft is all or nothing and takes and gives exactly. Recipes at a TABLE or a
## FURNACE need that block within REACH of the eyes (the host allows HOST_REACH, for a guest's lag);
## furnace recipes also burn one fuel (Recipes.FUELS in order, never the recipe's own result, never what
## its ingredients need). Tools and shields are one of each, like Tilly's (ShopRules.is_tool_item); counts
## cap at Inventory.MAX_COUNT. The host runs the same checks for every request (Session, "Survivor games
## and crafting").

const REACH := 4.0
const HOST_REACH := 5.0

const _MESSAGES := {
	"unknown": "That recipe isn't in the book.",
	"have_it": "You already have one!",
	"full": "Your bag is full of those!",
	"fuel": "You need coal or a log to burn!",
	"table": "Stand next to a Workbench!",   # owner #43: our own stations
	"furnace": "Stand next to a Clay Oven!",
	"refinery": "Stand next to a Refinery!",   # spec §26
	"melter": "Stand next to an Ice Melter!",   # spec §26.5
	"oxygen_maker": "Stand next to an Oxygen Maker!",
	"solar_oven": "Stand next to a Solar Oven!",
	"survivor_only": "Crafting is for Survivor worlds.",
}


## Why `recipe` can't be made now ("" = it can): unknown, have_it, table / furnace (not near one), missing,
## fuel, full. `stations` = {Recipes.HAND: true, TABLE: bool, FURNACE: bool} (stations()).
static func refusal(recipe: Dictionary, inv: Inventory, stations_near: Dictionary) -> String:
	if recipe.is_empty() or Recipes.find(recipe.get("id", &"")).is_empty():
		return "unknown"
	var makes: int = recipe.makes
	if ShopRules.is_tool_item(makes) and inv.count(makes) > 0:
		return "have_it"
	if not stations_near.get(recipe.at, false):
		return String(recipe.at)
	if not missing(recipe, inv).is_empty():
		return "missing"
	if fuel_for(recipe, inv) < 0:
		return "fuel"
	if inv.count(makes) + int(recipe.count) > Inventory.MAX_COUNT:
		return "full"
	return ""


static func can_make(recipe: Dictionary, inv: Inventory, stations_near: Dictionary) -> bool:
	return refusal(recipe, inv, stations_near) == ""


## {id: how many more are needed} for each ingredient short ({} = all there).
static func missing(recipe: Dictionary, inv: Inventory) -> Dictionary:
	var out := {}
	var needs: Dictionary = recipe.get("needs", {})
	for id: int in needs:
		var short := int(needs[id]) - inv.count(id)
		if short > 0:
			out[id] = short
	return out


## What a recipe burns: BlockIds.AIR when it needs no fire, a fuel id, or -1 when there is none to burn.
static func fuel_for(recipe: Dictionary, inv: Inventory) -> int:
	if recipe.get("at") != Recipes.FURNACE:
		return BlockIds.AIR
	var needs: Dictionary = recipe.needs
	for f in Recipes.FUELS:
		if f != int(recipe.makes) and inv.count(f) >= int(needs.get(f, 0)) + 1:
			return f
	return -1


## Makes one `recipe`: {ok, error, id, count, fuel}. Nothing changes on a refusal.
static func craft(recipe: Dictionary, inv: Inventory, stations_near: Dictionary) -> Dictionary:
	var error := refusal(recipe, inv, stations_near)
	if error != "":
		return {"ok": false, "error": error, "id": int(recipe.get("makes", 0)), "count": 0, "fuel": BlockIds.AIR}
	var fuel := fuel_for(recipe, inv)
	var needs: Dictionary = recipe.needs
	for id: int in needs:
		inv.take(id, int(needs[id]))
	if fuel != BlockIds.AIR:
		inv.take(fuel, 1)
	inv.add(recipe.makes, recipe.count)
	return {"ok": true, "error": "", "id": int(recipe.makes), "count": int(recipe.count), "fuel": fuel}


## A kind line for a refusal ("You need 2 more Sticks!" for what is short first).
static func message(error: String, recipe: Dictionary, inv: Inventory) -> String:
	if error == "missing":
		var short := missing(recipe, inv)
		for id: int in short:
			return Lang.t("You need %d more %s!") % [short[id], Lang.t(ItemIds.display_name(id))]
		return ""
	return _MESSAGES.get(error, "")


## "You made 4 Planks!", "You made a Stone Sword!"; spec §26: a refining step adds its real fact.
static func done_message(recipe: Dictionary) -> String:
	var said := _made_message(recipe)
	var fact := RefiningRules.fact(StringName(recipe.get("id", &"")))
	return said if fact == "" else "%s %s" % [said, Lang.t(fact)]


static func _made_message(recipe: Dictionary) -> String:
	var n := int(recipe.get("count", 1))
	var thing := Lang.t(ItemIds.display_name(int(recipe.get("makes", 0))))   # M3 Task 21a
	if n != 1 or RefiningRules.is_stuff(int(recipe.makes)):   # spec §26: "You made 1 Kerosene!", never "a Kerosene"
		return Lang.t("You made %d %s%s!") % [n, thing, "" if thing.ends_with("s") or not _counts_with_s(int(recipe.makes)) else Lang.plural_s(n)]
	var article := Lang.article(thing)
	return Lang.t("You made %s %s!") % [article, thing]


## "4 Planks" stays as it is, "2 Doors", "4 Sticks", "4 Lights"; "4 Glass", "4 Brick" read as stuff.
static func _counts_with_s(id: int) -> bool:
	return [BlockIds.DOOR, BlockIds.LIGHT, ItemIds.STICK].has(id)


## "have/need" under an ingredient's picture.
static func have_need(have: int, need: int) -> String:
	return "%d/%d" % [have, need]


## Is the block in `cell` within `reach` of the eyes (to its nearest point)?
static func in_reach(eye: Vector3, cell: Vector3i, reach: float) -> bool:
	var lo := Vector3(cell)
	var nearest := eye.clamp(lo, lo + Vector3.ONE)
	return nearest.distance_to(eye) <= reach


## Where the player can craft: {HAND: true, TABLE: a table within reach, FURNACE: a furnace within reach, REFINERY: a
## refinery within reach (spec §26), and spec §26.5's machines (Recipes.MACHINES): `machines` = {machine: cells}}.
static func stations(eye: Vector3, tables: Array[Vector3i], furnaces: Array[Vector3i], reach: float,
		refineries: Array[Vector3i] = [], machines: Dictionary = {}) -> Dictionary:
	var out := {Recipes.HAND: true, Recipes.TABLE: _any_in_reach(eye, tables, reach),
		Recipes.FURNACE: _any_in_reach(eye, furnaces, reach), Recipes.REFINERY: _any_in_reach(eye, refineries, reach)}
	for m: StringName in Recipes.MACHINES:
		var cells: Array[Vector3i] = []
		cells.assign(machines.get(m, []))
		out[m] = _any_in_reach(eye, cells, reach)
	return out


static func _any_in_reach(eye: Vector3, cells: Array[Vector3i], reach: float) -> bool:
	for c in cells:
		if in_reach(eye, c, reach):
			return true
	return false


## [origin, size] of the box to search for stations around the eyes (covers HOST_REACH).
static func search_box(eye: Vector3) -> Array:
	var r := ceili(HOST_REACH)
	return [Vector3i(eye.floor()) - Vector3i(r, r, r), Vector3i(2 * r + 1, 2 * r + 1, 2 * r + 1)]


## The picture book's order: what can be made now first, then the rest, each in the table's order.
static func book(inv: Inventory, stations_near: Dictionary) -> Array[Dictionary]:
	var now: Array[Dictionary] = []
	var later: Array[Dictionary] = []
	for r: Dictionary in Recipes.LIST:
		if can_make(r, inv, stations_near):
			now.append(r)
		else:
			later.append(r)
	now.append_array(later)
	return now
