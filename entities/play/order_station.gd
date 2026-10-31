class_name OrderStation
extends PlacingStation
## Owner #122 (G0), Order it (design §5.1): a bridge over a little stream behind the table is missing its planks. Each
## plank carries one of the things to order; the child lays them into the bridge's numbered gaps from the near bank to
## the far one (flat: tap a plank, tap a gap, or drag it; VR: carry it), then the buddy walks across: right, the buddy
## reaches the far bank and hops; not yet, the planks float back to the table (as the School's order answer cleared).

const GAP := 0.3
const DECK := SHELF_TOP + 0.04

var buddy: LifeBuddy
var buddy_home := Vector3.ZERO


func build_place() -> void:
	spot_prefix = "slot"
	PlayKit.table(self, TABLE_AT, TABLE_SIZE, TABLE_TOP)
	var n := (ex.get("items", []) as Array).size()
	var xs := spread(n, GAP)
	var span := xs[-1] - xs[0] + GAP
	LifeRoomKit.box(self, "Stream", Vector3(span + 0.1, 0.06, 0.42), Vector3(0, DECK - 0.3, BACK_Z), Color("5ab0e8"))
	LifeRoomKit.box(self, "NearBank", Vector3(0.28, DECK, 0.42), Vector3(xs[0] - GAP * 0.5 - 0.14, DECK * 0.5, BACK_Z),
		PlayArena.GRASS)
	LifeRoomKit.box(self, "FarBank", Vector3(0.28, DECK, 0.42), Vector3(xs[-1] + GAP * 0.5 + 0.14, DECK * 0.5, BACK_Z),
		PlayArena.GRASS)
	for s in n:
		var gap := Node3D.new()
		gap.name = "Gap%d" % s
		gap.position = Vector3(xs[s], DECK, BACK_Z)
		add_child(gap)
		LifeRoomKit.box(gap, "Mark", Vector3(GAP - 0.03, 0.01, 0.3), Vector3(0, -0.02, 0), Color(1, 1, 1, 0.35))
		PlayKit.words(gap, "Number", str(s + 1), Vector3(0, -0.12, 0.2), 0.0013, 48, Color("fff4b0"))
		add_spot(gap, 0.14)
	buddy = LifeBuddy.new(PlayChoose.buddy(seed).colour, "Walker")
	buddy.scale = Vector3.ONE * 0.4
	buddy_home = Vector3(xs[0] - GAP * 0.5 - 0.14, DECK, BACK_Z)
	buddy.position = buddy_home
	buddy.rotation.y = PI * 0.5
	add_child(buddy)


func make_thing(i: int) -> Node3D:
	var items: Array = ex.get("items", [])
	var item: Variant = items[i]
	var d: Dictionary = item if item is Dictionary else {"text": str(item)}
	return PlayKit.card(self, "Plank%d" % i, d, things_at(items.size())[i], PlayKit.WOOD)


func placed_scale() -> float:
	return 0.64   # a plank in its gap: the bridge's width


func at_spot(_i: int, p: int, _k: int) -> Vector3:
	return spots[p].position + Vector3(0, 0.05, 0.02)


func celebrate() -> void:
	if not is_instance_valid(buddy):
		return
	var far := Vector3(spots[-1].position.x + GAP * 0.5 + 0.14, DECK, BACK_Z)
	if UiMotion.calm() or not is_inside_tree():
		buddy.position = far
		return
	var tw := create_tween()
	for s in spots:
		tw.tween_property(buddy, "position", s.position + Vector3(0, 0.06, 0), 0.35)
	tw.tween_property(buddy, "position", far, 0.35)
	tw.tween_callback(func() -> void: hop(buddy))


func react(outcome: String) -> void:
	if outcome != PlayLoop.RIGHT and is_instance_valid(buddy):
		buddy.position = buddy_home
		shake(buddy)
	super(outcome)
