class_name MarketPlaza
extends RefCounted
## Owner #115 (docs/design/success-skills.md §2.1, §2.2; the S3 brief: "Life Town is full ... so the shop and the Market
## Square are a second plaza, the Market Square itself, placed near Life Town by the same search; keep 'walking up to one
## never opens another'"): the Market Square's plaza in a home world, beside Life Town. Two places on it: the bakery (My
## Business's shop) and the market stalls with the Price Board (the Market Square). It is found by Life Town's own search
## (LifeTown.pick with this LAYOUT and the town's site: the same rings round the spawn, the same dry, near-level ground
## with no tree near (or trees cleared once by the host), the same distances from the spawn, never on the Theater or the
## Launch Site nor hidden behind them), started from the town's own direction so it lands next to it, never on the town's
## plaza (CLEAR blocks off) and at least LifeTown.TOWN_GAP round from it seen from the spawn (beside it, never behind
## it). Like the town, nothing is stamped: the buildings are models (MarketPlazaBuildings); the save keeps the site with
## the town's (LifeTown.to_save: site.market). A world without room has no Market Square: Life's tab still opens both.
## Local cells: +Z towards the spawn, turned by `facing` (LaunchSite's frame).

const PLAZA_MIN := Vector2i(-8, -4)
const PLAZA_MAX := Vector2i(8, 3)
## Each place: its Experience, its walk-up spot (local, from the middle cell's centre: its door), the words on its sign,
## its footprint (local cells, min and max). The doors are 8.5 m apart (walking up to one never opens the other).
const SPOTS := {
	"bakery": {"experience": "my_shop", "door": Vector2(-4.5, 2.2), "sign": "MY SHOP", "min": Vector2i(-7, -3),
		"max": Vector2i(-2, 1)},
	"square": {"experience": "market_square", "door": Vector2(4.0, 2.2), "sign": "THE MARKET SQUARE", "min": Vector2i(1, -3),
		"max": Vector2i(7, 1)},
}
const LAYOUT := {"min": PLAZA_MIN, "max": PLAZA_MAX, "spots": SPOTS}


## The Market Square's site near `town` ({} for none): LifeTown.pick with this layout.
static func pick(spawn: Vector2i, world_seed: int, height_at: Callable, is_dry: Callable, has_tree: Callable,
		town: Dictionary, theater: Dictionary = {}, launch: Dictionary = {}, rejected: Array = []) -> Dictionary:
	if town.is_empty():
		return {}
	return LifeTown.pick(spawn, world_seed, height_at, is_dry, has_tree, theater, launch, rejected, LAYOUT, _town_only(town))


## pick() with a home world's terrain (as the town's own pick_for).
static func pick_for(shape: MeadowsShape, town: Dictionary, theater: Dictionary = {}, launch: Dictionary = {},
		rejected: Array = []) -> Dictionary:
	if town.is_empty():
		return {}
	return LifeTown.pick_for(shape, theater, launch, rejected, LAYOUT, _town_only(town))


static func door_position(site: Dictionary, spot: String, ground: Callable = Callable()) -> Vector3:
	return LifeTown.door_position(site, spot, ground, LAYOUT)


## The place whose door feet at `feet` stand at ("" for none).
static func near(site: Dictionary, feet: Vector3, ground: Callable = Callable()) -> String:
	return LifeTown.near(site, feet, ground, LAYOUT)


static func experience_at(site: Dictionary, feet: Vector3, ground: Callable = Callable()) -> String:
	return LifeTown.experience_at(site, feet, ground, LAYOUT)


static func natural_box(site: Dictionary) -> Array:
	return LifeTown.natural_box(site, LAYOUT)


static func natural(site: Dictionary, read: Callable) -> bool:
	return LifeTown.natural(site, read, LAYOUT)


static func clear_changes(site: Dictionary, read: Callable) -> Array:
	return LifeTown.clear_changes(site, read, LAYOUT)


static func to_world(site: Dictionary, local: Vector2i) -> Vector2i:
	return LifeTown.to_world(site, local)


## The town's own site (without its Market Square), for the search.
static func _town_only(town: Dictionary) -> Dictionary:
	return {"pos": town.pos, "facing": town.facing}
