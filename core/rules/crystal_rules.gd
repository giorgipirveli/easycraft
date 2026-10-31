class_name CrystalRules
extends RefCounted
## Universe crystals and universe portal cores (owner feedback #39, spec §14.2a), as pure rules. One crystal per
## universe (items 480-489: 480 Green Meadows ... 484 the Dragon Realm; 485-489 kept for universes 6-10). A crystal
## is earned by reaching its universe: every universe a profile opened gives its crystal once (and a gift, like the
## Sky Dragon's Dragon Crystal, one more), handed into the child's bag in their own Survivor world; Tilly sells
## copies of the crystals up to the universe she stands in at a fixed price (scaled like all her prices); the
## Sandbox palette has the crystals of the universes reached. Placing a crystal in a portal frame's core slot puts
## its universe's portal core (blocks 212-215, 222 on page 10), and breaking the core gives the crystal back.

const FIRST := 480
const LAST := 489                 # 485-489: universes 6-10, when they come
const PRICE := 50                 # Tilly's price in Green Meadows gold (× 2^(u-1), like all her prices)
const MAX_GIFTS := 20

## The universe portal core of each universe (page 10: two tiles per id at index 2 × (id - 208)).
const CORES := {1: BlockIds.CORE_MEADOWS, 2: BlockIds.CORE_DESERT, 3: BlockIds.CORE_FROST, 4: BlockIds.CORE_CANDY,
	5: BlockIds.CORE_DRAGON, 6: BlockIds.CORE_GLOW}

## [deep, bright, rim] of each universe's swirl (0: a plain linked portal's gold, with rainbow arms: PortalSwirl) and
## its crystal's gem ([deep, bright] reused). Owner #43: never purple (spec §3c).
const SWIRLS := {
	0: [Color(0.72, 0.42, 0.08), Color(1.0, 0.93, 0.62), Color(1.0, 0.78, 0.25)],
	1: [Color("14521f"), Color("a8ff9e"), Color("6fe36f")],   # green meadows
	2: [Color("7a3a0a"), Color("ffd27a"), Color("ffb347")],   # desert gold
	3: [Color("173c78"), Color("c6efff"), Color("8fd8ff")],   # frost blue
	4: [Color("7a1f5a"), Color("ffc2e5"), Color("ff8fc8")],   # candy pink
	5: [Color("d9546e"), Color("ffe7b8"), Color("ffa36c")],   # the Dragon Realm's sunrise (owner #43)
	6: [Color("0f4c5c"), Color("8ff7e8"), Color("3fd9b8")],   # the Glow Caves' teal glow (never purple)
}


## The crystal item of universe u (-1 for a universe without one).
static func crystal_of(u: int) -> int:
	return FIRST + u - 1 if CORES.has(u) else -1


## The universe of crystal `id` (0 for anything else).
static func universe_of(id: int) -> int:
	var u := id - FIRST + 1
	return u if id >= FIRST and id <= LAST and CORES.has(u) else 0


static func is_crystal(id: int) -> bool:
	return universe_of(id) > 0


## Every crystal that exists, in ladder order.
static func all() -> Array[int]:
	var out: Array[int] = []
	for u: int in CORES:
		out.append(crystal_of(u))
	out.sort()
	return out


## The portal core block of universe u (-1 for a universe without one).
static func core_of(u: int) -> int:
	return int(CORES.get(u, -1))


## The universe whose portal core block `id` is (0 for anything else: the linking PORTAL_CORE too).
static func universe_of_core(id: int) -> int:
	for u: int in CORES:
		if CORES[u] == id:
			return u
	return 0


static func is_universe_core(id: int) -> bool:
	return universe_of_core(id) > 0


## The block a crystal places (its universe's core), -1 for anything that is not a crystal.
static func core_for_item(id: int) -> int:
	return core_of(universe_of(id))


## The crystal a universe core breaks into (and costs to place); the id itself for anything else.
static func item_for_core(id: int) -> int:
	var u := universe_of_core(id)
	return crystal_of(u) if u > 0 else id


## Universe u counts as reached by a profile that opened `unlocked` universes.
static func earned(u: int, unlocked: int) -> bool:
	return u >= UniverseRules.FIRST and u <= UniverseRules.valid(unlocked)


## The crystals a profile still has to be handed (universes, in order): every universe it reached above the
## highest one given so far (`given`), then its gifts. Only universes that have a crystal.
static func owed(unlocked: int, given: int, gifts: Array) -> Array[int]:
	var out: Array[int] = []
	for u in range(maxi(given, 0) + 1, UniverseRules.valid(unlocked) + 1):
		if CORES.has(u):
			out.append(u)
	out.append_array(clean_gifts(gifts))
	return out


## The highest universe whose crystal was given, after handing out up to `unlocked` (never lowered).
static func given_after(unlocked: int, given: int) -> int:
	return maxi(UniverseRules.valid(unlocked), given)


## Gifts as saved: universes that have a crystal, at most MAX_GIFTS.
static func clean_gifts(v: Variant) -> Array[int]:
	var out: Array[int] = []
	if not v is Array:
		return out
	for e: Variant in v:
		if typeof(e) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(e)) and CORES.has(int(e)) and out.size() < MAX_GIFTS:
			out.append(int(e))
	return out


## The crystals Tilly sells in universe u: those of universes 1..u.
static func for_sale_in(u: int) -> Array[int]:
	var out: Array[int] = []
	for c in all():
		if universe_of(c) <= UniverseRules.valid(u):
			out.append(c)
	return out


## Tilly's base price for `id` in universe u (0: she doesn't sell it there).
static func base_price(id: int, u: int) -> int:
	var cu := universe_of(id)
	return PRICE if cu > 0 and cu <= UniverseRules.valid(u) else 0


## The crystals in the Sandbox palette: every universe reached.
static func sandbox_crystals(unlocked: int) -> Array[int]:
	var out: Array[int] = []
	for c in all():
		if earned(universe_of(c), unlocked):
			out.append(c)
	return out


## [deep, bright, rim] of universe u's swirl (the plain purple for 0 and anything unknown).
static func swirl_colors(u: int) -> Array:
	return SWIRLS.get(u, SWIRLS[0])
