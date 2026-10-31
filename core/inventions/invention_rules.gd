class_name InventionRules
extends RefCounted
## Owner #78 (spec §21e): the gates of "invent it", pure. Where flying costs something (Survivor), flight is invented
## step by step in history's order (InventionLine): each at a Workbench, from real materials in the bag (any of a
## material's things), for a little gold, free once its School unit is mastered; one opens the next. What each opens:
## the kite a short lift on a windy hill, the balloon slow flying (free: the burner's gas), the glider the glide (never
## lost), the plane fast flying (fuel: FlyCost's price), the jet the fastest (twice the fuel), the rocket the Launch
## Site's missions. Where flying is free (the Sandbox: ModeRules.FREE_FLY) everything stays open: the book is to read
## and try, and the classic flying stays (owner #54, #75). Kites, balloons and planes need air: never on the Moon.

const EARTH := &"earth"
const THIN_AIR := &"thin"     # Mars: 1% of the Earth's air
const THICK_AIR := &"thick"   # Titan: thicker than the Earth's
const NO_AIR := &"none"

const NEED_WORDS := "Invent a way to fly first! INVENT (in MORE, or I on a PC) shows how people did it, from the kite on."
const NO_AIR_WORDS := "There is no air here: kites, balloons and planes need air to fly. Only rockets fly without it!"
const THIN_AIR_WORDS := "Mars's air is far too thin to hold up a kite, a balloon or a plane. A tiny helicopter did fly " \
	+ "here in 2021, with very long, very fast blades!"
const MISSIONS_WORDS := "Invent the rocket first! INVENT (in MORE, or I on a PC) shows how people learned to fly, from " \
	+ "the kite to the rocket."
const KITE_HILL_WORDS := "Your kite needs a windy hill: climb up high, where the wind blows freely!"

const _MESSAGES := {
	"unknown": "That's not an invention in the book.",
	"known": "You invented it already!",
	"workbench": "Stand next to a Workbench to make it!",
	"sandbox": "In the Sandbox everything is open: TRY IT!",
	"guest": "Invent in your own world: the bag here belongs to your friend's world.",
}


## The first invention of the line not invented yet (&"" when all are).
static func next(data: InventionData) -> StringName:
	for id in InventionLine.ORDER:
		if not data.has(id):
			return id
	return &""


## The one before it is invented (the first is always open).
static func may_make(id: StringName, data: InventionData) -> bool:
	var before := InventionLine.previous(id)
	return InventionLine.has(id) and (before == &"" or data.has(before))


## Why `id` can't be made now ("" = it can): unknown, known, earlier (the one before first), workbench (none near),
## missing (materials), gold. `mastered`: its School unit is mastered (free).
static func refusal(id: StringName, data: InventionData, inv: Inventory, near_workbench: bool, gold: int,
		mastered: bool) -> String:
	if not InventionLine.has(id):
		return "unknown"
	if data.has(id):
		return "known"
	if not may_make(id, data):
		return "earlier"
	if not near_workbench:
		return "workbench"
	if not missing(id, inv).is_empty():
		return "missing"
	if gold < price(id, mastered):
		return "gold"
	return ""


## A kind line for a refusal ("You need 4 more Sticks!").
static func message(key: String, id: StringName, inv: Inventory) -> String:
	match key:
		"earlier":
			return Lang.t("Invent %s first: every invention stands on the one before!") % \
				Lang.t(str(InventionLine.entry(InventionLine.previous(id)).get("name", "")))
		"missing":
			var short := missing(id, inv)
			for m: StringName in short:
				return Lang.t("You need %d more %s!") % [short[m], Lang.t(InventionLine.material_name(m))]
			return ""
		"gold":
			return Lang.t("You need %d gold to make it!") % price(id, false)
	return Lang.t(str(_MESSAGES.get(key, "")))


## How many of material `m` the bag holds (any of its things).
static func have(m: StringName, inv: Inventory) -> int:
	var n := 0
	for thing: int in (InventionLine.MATERIALS.get(m, {}) as Dictionary).get("ids", []):
		n += inv.count(thing)
	return n


## {material: how many more are needed} ({} = all there).
static func missing(id: StringName, inv: Inventory) -> Dictionary:
	var out := {}
	var needs := InventionLine.needs_of(id)
	for m: StringName in needs:
		var short := int(needs[m]) - have(m, inv)
		if short > 0:
			out[m] = short
	return out


## Takes what `id` is made of from the bag, each material's things in their order; all or nothing.
static func take(id: StringName, inv: Inventory) -> bool:
	if not InventionLine.has(id) or not missing(id, inv).is_empty():
		return false
	var needs := InventionLine.needs_of(id)
	for m: StringName in needs:
		var left := int(needs[m])
		for thing: int in InventionLine.MATERIALS[m].ids:
			var n := mini(left, inv.count(thing))
			if n > 0:
				inv.take(thing, n)
				left -= n
	return true


## Its gold: a little, or nothing once its School unit is mastered.
static func price(id: StringName, mastered: bool) -> int:
	return 0 if mastered else int(InventionLine.entry(id).get("gold", 0))


## The School unit on its science: its title ("" when unknown).
static func unit_title(id: StringName) -> String:
	return str(Curriculum.unit(str(InventionLine.entry(id).get("unit", ""))).get("title", ""))


static func unit_mastered(id: StringName, school: SchoolData) -> bool:
	var unit := str(InventionLine.entry(id).get("unit", ""))
	return school != null and unit != "" and MasteryRules.stars(school.progress(unit)) >= MasteryRules.MASTERED


## "10 gold, or free once you master Pushes, pulls and friction in the School" / "Free: you mastered …!".
static func price_words(id: StringName, mastered: bool) -> String:
	var title := unit_title(id)
	if mastered:
		return Lang.t("Free: you mastered %s!") % title
	return Lang.t("%d gold, or free once you master %s in the School") % [price(id, false), title]


# --- Flying ---

## The machine a take-off flies with: the one picked (`chosen`, where it may be flown), Survivor's saved pick, else the
## newest invented (a flyer, or the kite); NONE for the Sandbox's classic flying or when nothing is invented.
static func take_off_craft(free_fly: bool, data: InventionData, chosen: int) -> int:
	chosen = FlightCrafts.valid(chosen)
	if chosen != FlightCrafts.Craft.NONE and (free_fly or data.has(FlightCrafts.invention_of(chosen))):
		return chosen
	if free_fly:
		return FlightCrafts.Craft.NONE
	if data.craft != &"" and data.has(data.craft):
		return FlightCrafts.of_invention(data.craft)
	return newest_craft(data)


## The newest machine invented (the jet, the plane, the balloon, the kite), NONE without one.
static func newest_craft(data: InventionData) -> int:
	for id: StringName in [InventionLine.JET, InventionLine.PLANE, InventionLine.BALLOON, InventionLine.KITE]:
		if data.has(id):
			return FlightCrafts.of_invention(id)
	return FlightCrafts.Craft.NONE


## Why flying with `craft` is refused here ("" = it may): not invented (where flying costs), or no air to fly in.
static func fly_refusal(free_fly: bool, data: InventionData, craft: int, air_kind: StringName) -> String:
	craft = FlightCrafts.valid(craft)
	if craft == FlightCrafts.Craft.NONE:
		return "" if free_fly else Lang.t(NEED_WORDS)
	if not free_fly and not data.has(FlightCrafts.invention_of(craft)):
		return Lang.t(NEED_WORDS)
	return air_refusal(air_kind)


## Wings, kites and balloons need air: "" where there is enough.
static func air_refusal(air_kind: StringName) -> String:
	match air_kind:
		NO_AIR:
			return Lang.t(NO_AIR_WORDS)
		THIN_AIR:
			return Lang.t(THIN_AIR_WORDS)
	return ""


## The air of world u: the Earth's (the ladder's worlds and our own playful planets), Mars's thin air, Titan's thick
## air, or none (the Moon, Europa, Io, Mercury and the other airless bodies).
static func air(u: int) -> StringName:
	if not SpaceRules.is_space(u) or u == SpaceRules.BOING or u == SpaceRules.RAINBOW:
		return EARTH
	if u == SpaceRules.MARS:
		return THIN_AIR
	if u == SpaceRules.TITAN or u == SpaceRules.VENUS:
		return THICK_AIR
	return NO_AIR


## Fuel: × FlyCost's price a minute. The balloon's gas and the kite are free; the jet burns twice the plane's.
static func fuel_factor(craft: int) -> int:
	match FlightCrafts.valid(craft):
		FlightCrafts.Craft.KITE, FlightCrafts.Craft.BALLOON:
			return 0
		FlightCrafts.Craft.JET:
			return 2
	return 1


static func can_pay_take_off(free_fly: bool, craft: int, gold: int, universe: int) -> bool:
	var f := fuel_factor(craft)
	return free_fly or f == 0 or gold >= FlyCost.charge(universe) * f


## FlyCost's "You need gold to fly! Flying costs 10 gold a minute." (the plane's fuel), or the jet's: "You need gold
## to fly! The jet burns 20 gold a minute."
static func fuel_words(craft: int, universe: int) -> String:
	if fuel_factor(craft) <= 1:
		return FlyCost.refused_message(universe)
	return Lang.t("You need gold to fly! The jet burns %d gold a minute.") % (
		UniverseRules.price(FlyCost.GOLD_PER_MINUTE, universe) * fuel_factor(craft))


## The Launch Site's missions: open where flying is free; in Survivor once the rocket is invented.
static func missions_open(free_fly: bool, data: InventionData) -> bool:
	return free_fly or data.has(InventionLine.ROCKET)


## A "try it" pays once (EarnRules.INVENT_TRY_GOLD): what it pays now.
static func try_gold(id: StringName, data: InventionData) -> int:
	return 0 if data.was_tried(id) or not InventionLine.has(id) else EarnRules.INVENT_TRY_GOLD
