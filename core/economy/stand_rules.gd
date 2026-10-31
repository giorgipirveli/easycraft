class_name StandRules
extends RefCounted
## The helpers' stands (owner #37, spec §14.23). Pure. In a Survivor world of a universe with a helper (§14.17:
## Zara, Bram, Mimi, Nell; not Tilly, whose stall is Green Meadows' stand), the helper keeps a small stand beside them
## selling the universe's own things (its descriptor's trader_stock) at Tilly's prices of that universe
## (ShopRules.price). Every game places it from the helper's spot (nothing is sent), on the ground beside them.

## The stand's candidate spots in the helper's own frame (x to their side, z behind), nearest first.
const SPOTS: Array[Vector2] = [Vector2(2.5, 0), Vector2(-2.5, 0), Vector2(2.5, 1), Vector2(-2.5, 1), Vector2(3, 0),
	Vector2(-3, 0), Vector2(2, 1.5), Vector2(-2, 1.5)]


## The helper who keeps universe u's stand (&"" = none).
static func giver_in(u: int) -> StringName:
	var id := QuestRules.giver_in(u)
	return id if id != &"tilly" else &""


static func has_stand(u: int) -> bool:
	return giver_in(u) != &"" and not stock(u).is_empty()


## What the stand sells: the universe's own things Tilly would sell there.
static func stock(u: int) -> Array[int]:
	var ids: Array[int] = []
	for id: int in UniverseRegistry.trader_stock(u):
		if ShopRules.for_sale(id, u):
			ids.append(id)
	return ids


## "Zara's stand".
static func title(u: int) -> String:
	return Lang.t("%s's stand") % str(QuestRules.giver(giver_in(u)).get("name", "Tilly"))


## Where the stand stands: beside the helper (their feet at `helper`, facing `yaw`), on dry ground at most a block
## above or below theirs, no tree trunk in the way; else the first spot beside them anyway. {pos (feet), yaw}.
static func stand_spot(helper: Vector3, yaw: float, height_at: Callable, ground_ok: Callable, tree_at: Callable) -> Dictionary:
	var h := int(height_at.call(floori(helper.x), floori(helper.z)))
	var first := Vector2i.MAX
	for s in SPOTS:
		var off := Vector3(s.x, 0.0, s.y).rotated(Vector3.UP, yaw)
		var c := Vector2i(floori(helper.x + off.x), floori(helper.z + off.z))
		if first == Vector2i.MAX:
			first = c
		if _good(c, h, height_at, ground_ok, tree_at):
			return _spot(c, yaw, height_at)
	return _spot(first, yaw, height_at)


static func _good(c: Vector2i, h: int, height_at: Callable, ground_ok: Callable, tree_at: Callable) -> bool:
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			if absi(int(height_at.call(c.x + dx, c.y + dz)) - h) > 1 or not ground_ok.call(c.x + dx, c.y + dz) \
					or tree_at.call(c.x + dx, c.y + dz):
				return false
	return true


static func _spot(c: Vector2i, yaw: float, height_at: Callable) -> Dictionary:
	return {"pos": Vector3(c.x + 0.5, float(height_at.call(c.x, c.y)), c.y + 0.5), "yaw": yaw}
