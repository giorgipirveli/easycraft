class_name SpendRules
extends RefCounted
## Owner #83 (spec §25.5): what gold buys, in one price table, on the Gold Shop's shelves ("gold is good to buy new
## things and unlock new exciting lessons to learn, new planets, new weapons, parts for rocket and spaceships, and many
## many other things"). Things are named by one id each:
## - "lesson:<unit id>": an Explorer lesson, a School unit marked "bonus": true (its "price", else LESSON_PRICE).
##   Buying opens it for good. A grade's own units are never sold: they stay open and free for every child (#82).
## - "gear:<item id>": a weapon or a tool at Tilly's price in the highest universe opened (ShopRules); it waits in the
##   backpack for the next Survivor world (unpack_backpack). Nobody needs two.
## - "look:<avatar item>": an avatar or buddy thing at its own price (AvatarCatalog, AvatarUnlocks).
## - anything another part hangs on a shelf with register() (the missions' rocket parts "part:<id>", decorations).
## Prices are tuned with EarnRules (GUIDE). Owner #98: a rocket part costs 5 to 40 gold and Mission Control's Moon rocket
## (RocketPlan) about a good day of learning, Mars's a little more, the far worlds' a few days, Mercury's (its speed) the
## most. Buying happens outside a world (the main menu), on the profile; the caller saves.

const OK := &"ok"
const OWNED := &"owned"
const NOT_ENOUGH := &"not_enough"
const UNKNOWN := &"unknown"

const LESSONS := &"lessons"
const ROCKET := &"rocket"
const GEAR := &"gear"
const LOOKS := &"looks"
const DECOR := &"decor"
const SHELVES: Array[StringName] = [LESSONS, ROCKET, GEAR, LOOKS, DECOR]
const SHELF_WORDS := {LESSONS: "EXPLORER LESSONS", ROCKET: "ROCKET PARTS", GEAR: "WEAPONS & TOOLS",
	LOOKS: "AVATAR & BUDDY", DECOR: "DECORATIONS"}
const SHELF_ABOUT := {
	LESSONS: "New lessons beyond your grade. Your grade's own lessons are always free!",
	ROCKET: "Parts to build your rocket and fly to new planets.",
	GEAR: "Weapons and tools wait in your backpack for your next Survivor world.",
	LOOKS: "Things to wear and show.",
	DECOR: "Things for your dome, your base and your crew's wall.",
}
const COMING_WORDS := {ROCKET: "Rocket parts arrive with the Launch Site.",
	DECOR: "Decorations for your dome are on their way.", LESSONS: "Professor Hoot is writing the first Explorer lessons."}

const LESSON_PRICE := 200
const LESSON_PRICE_MIN := 50
const LESSON_PRICE_MAX := 2000
const MAX_BOUGHT := 1024
## For the missions' prices (EarnRules: a day of learning is about 275 gold). Owner #98: the dearest part (a crew
## capsule) and Mission Control's plans for one astronaut (RocketPlan.gold; test_rocket_plan keeps them equal).
const GUIDE := {"first_part": 40, "moon_rocket": 450, "mars_rocket": 615}

## Hooks: shelf -> [{"id", "name", "price", "picture"?, "grant": Callable(profile, id)}] (register()).
static var _extra := {}


## Hangs a thing on a shelf (the missions' rocket parts, later decorations). `grant(profile, id)` gives it.
static func register(shelf: StringName, item: Dictionary, grant: Callable) -> void:
	if not SHELVES.has(shelf) or str(item.get("id", "")) == "" or int(item.get("price", 0)) <= 0:
		return
	var list: Array = _extra.get(shelf, [])
	for it: Dictionary in list:
		if it.id == item.id:
			return
	var copy := item.duplicate()
	copy.grant = grant
	list.append(copy)
	_extra[shelf] = list


## Tests: forget registered things.
static func clear_extra() -> void:
	_extra.clear()


# --- Explorer lessons ------------------------------------------------------------------------------------------------

static func is_bonus(unit: Dictionary) -> bool:
	var b: Variant = unit.get("bonus")
	return b is bool and bool(b)


static func lesson_price(unit: Dictionary) -> int:
	var p: Variant = unit.get("price")
	if typeof(p) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(p)):
		return clampi(int(p), LESSON_PRICE_MIN, LESSON_PRICE_MAX)
	return LESSON_PRICE


## A unit a child may learn now: every grade's own unit; an Explorer lesson once bought.
static func lesson_open(profile: ProfileData, unit_id: String) -> bool:
	var u := Curriculum.unit(unit_id)
	return not is_bonus(u) or profile.bought.has("lesson:" + unit_id)


## Every grade's Explorer lessons, in grade and subject order.
static func bonus_units() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for g in Curriculum.grades():
		for s in Curriculum.subjects(g):
			for u in Curriculum.units(g, str(s.get("id", ""))):
				if is_bonus(u):
					out.append(Curriculum.unit(str(u.get("id", ""))))
	return out


# --- The shelves -----------------------------------------------------------------------------------------------------

## What a shelf holds now: [{"id", "name", "price", "owned", "picture"?}].
static func items(shelf: StringName, profile: ProfileData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	match shelf:
		LESSONS:
			for u in bonus_units():
				var id := "lesson:" + str(u.id)
				out.append({"id": id, "name": str(u.get("title", "")), "price": lesson_price(u),
					"owned": profile.bought.has(id), "about": ", ".join(PackedStringArray(u.get("goals", [])))})
		GEAR:
			for item in gear_ids():
				var id := "gear:%d" % item
				out.append({"id": id, "name": ItemIds.display_name(item), "price": price(id, profile),
					"owned": profile.backpack.has(item), "item": item})
		LOOKS:
			for look: String in AvatarCatalog.ITEMS:
				if AvatarCatalog.ITEMS[look].kind == AvatarCatalog.GOLD:
					out.append({"id": "look:" + look, "name": AvatarCatalog.display_name(look),
						"price": AvatarCatalog.price(look), "owned": AvatarUnlocks.is_owned(look, profile.cosmetics)})
	for it: Dictionary in _extra.get(shelf, []):
		out.append({"id": it.id, "name": str(it.get("name", "")), "price": int(it.price), "owned": profile.bought.has(it.id),
			"picture": it.get("picture")})
	return out


## Weapons and tools Tilly sells (every tier of every line, then the other tools).
static func gear_ids() -> Array[int]:
	var out: Array[int] = []
	for line: Array in ShopRules.tool_lines():
		for id: int in line:
			if ShopRules.price(id, 1) > 0 and Inventory.ownable(id):
				out.append(id)
	for id: int in ShopRules.OTHER_TOOL_PRICES:
		out.append(id)
	return out


## The price of one thing now (0: not sold here).
static func price(id: String, profile: ProfileData) -> int:
	if id.begins_with("lesson:"):
		var u := Curriculum.unit(id.trim_prefix("lesson:"))
		return lesson_price(u) if is_bonus(u) else 0
	if id.begins_with("gear:"):
		var item := int(id.trim_prefix("gear:"))
		return ShopRules.price(item, maxi(profile.universe_unlocked, 1)) if gear_ids().has(item) else 0
	if id.begins_with("look:"):
		var look := id.trim_prefix("look:")
		var known: bool = AvatarCatalog.ITEMS.has(look) and AvatarCatalog.ITEMS[look].kind == AvatarCatalog.GOLD
		return AvatarCatalog.price(look) if known else 0
	var extra := _extra_item(id)
	return int(extra.price) if not extra.is_empty() else 0


static func owned(profile: ProfileData, id: String) -> bool:
	if bool(_extra_item(id).get("repeat", false)):   # a rocket part: bought again and again, never owned once
		return false
	if id.begins_with("gear:"):
		return profile.backpack.has(int(id.trim_prefix("gear:")))
	if id.begins_with("look:"):
		return AvatarUnlocks.is_owned(id.trim_prefix("look:"), profile.cosmetics)
	return profile.bought.has(id)


## Buys `id` with the profile's Survivor gold: OK, OWNED, NOT_ENOUGH or UNKNOWN. The caller saves.
static func buy(profile: ProfileData, id: String) -> StringName:
	var cost := price(id, profile)
	if cost <= 0:
		return UNKNOWN
	if owned(profile, id):
		return OWNED
	if id.begins_with("look:"):
		var r := AvatarUnlocks.buy(profile, id.trim_prefix("look:"))
		return OK if r == AvatarUnlocks.OK else OWNED if r == AvatarUnlocks.OWNED else NOT_ENOUGH if r == AvatarUnlocks.NOT_ENOUGH \
			else UNKNOWN
	var wallet := Wallet.new(profile.survivor_gold)
	if not wallet.spend(cost):
		return NOT_ENOUGH
	profile.survivor_gold = wallet.balance
	if id.begins_with("gear:"):
		profile.backpack[int(id.trim_prefix("gear:"))] = 1
		return OK
	var extra := _extra_item(id)
	if not bool(extra.get("repeat", false)) and profile.bought.size() < MAX_BOUGHT:
		profile.bought.append(id)
	if not extra.is_empty() and (extra.grant as Callable).is_valid():
		(extra.grant as Callable).call(profile, id)
	return OK


static func _extra_item(id: String) -> Dictionary:
	for shelf: StringName in _extra:
		for it: Dictionary in _extra[shelf]:
			if it.id == id:
				return it
	return {}


# --- The backpack (Gold Shop -> the next Survivor world) ---------------------------------------------------------------

## Puts the backpack's things into a Survivor world's bag and empties it; how many things went in.
static func unpack_backpack(profile: ProfileData, inv: Inventory) -> int:
	var n := 0
	for item: int in profile.backpack.keys():
		n += inv.add(item, int(profile.backpack[item]))
	profile.backpack.clear()
	return n


# --- Saved data --------------------------------------------------------------------------------------------------------

static func clean_bought(v: Variant) -> Array[String]:
	var out: Array[String] = []
	if not v is Array:
		return out
	for id: Variant in v:
		if id is String and (id as String).contains(":") and (id as String).length() <= 96 and not out.has(id) \
				and out.size() < MAX_BOUGHT:
			out.append(id)
	return out


static func clean_backpack(v: Variant) -> Dictionary:
	var out := {}
	if not v is Dictionary:
		return out
	for k: Variant in v:
		var n: Variant = v[k]
		if str(k).is_valid_int() and typeof(n) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(n)) and float(n) >= 1.0 \
				and Inventory.ownable(int(str(k))):
			out[int(str(k))] = mini(int(n), Inventory.MAX_COUNT)
	return out
