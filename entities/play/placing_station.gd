class_name PlacingStation
extends PlayStation
## Owner #122 (G0): the stations whose things go into places (PlayPlacing): Sort it, Order it, Connect it, Fix it. The
## things ("thing_<i>") wait on the table; the places ("<spot>_<p>") are the subclass's (bins, a bridge's slots, sockets,
## pins). A miss sends every thing home (as the School's sort, order, match and label answers cleared).

var placing: PlayPlacing
var spot_prefix := "spot"
var spots: Array[Node3D] = []


func build() -> void:
	placing = PlayPlacing.for_exercise(ex)
	build_place()
	for i in placing.things:
		var n := make_thing(i)
		add_thing("thing_%d" % i, n, thing_radius())
	add(GO, PlayKit.go_button(self, go_words(), GO_AT), 0.11)


## Subclasses: the places (each added with add_spot) and the look of thing `i` (a node under this station).
func build_place() -> void:
	pass


func make_thing(_i: int) -> Node3D:
	return Node3D.new()


func thing_radius() -> float:
	return 0.13


func add_spot(node: Node3D, radius: float) -> void:
	spots.append(node)
	add("%s_%d" % [spot_prefix, spots.size() - 1], node, radius)


func spot_names() -> Array[String]:
	var out: Array[String] = []
	for p in spots.size():
		out.append("%s_%d" % [spot_prefix, p])
	return out


func put(thing: String, spot: String) -> void:
	placing.put(_index(thing), int(spot.get_slice("_", 1)))
	layout()


func take(thing: String) -> void:
	placing.take(_index(thing))
	layout()


## Where thing `i` sits in place `p` (local), the `k`-th thing in that place (bins hold many).
func at_spot(_i: int, p: int, k: int) -> Vector3:
	return spots[p].position + Vector3(0, 0.12 + 0.04 * k, 0)


## Every thing where it belongs now (home, or its place); the carried one stays lifted.
func layout() -> void:
	var counts := {}
	for i in placing.things:
		var t := "thing_%d" % i
		if t == carried:
			continue
		var p := placing.at[i]
		(things[t] as Node3D).scale = Vector3.ONE * (placed_scale() if p >= 0 else 1.0)
		if p < 0:
			move(things[t], homes[t])
			continue
		var k := int(counts.get(p, 0))
		counts[p] = k + 1
		move(things[t], at_spot(i, p, k))
	placed_changed()


## How big a thing is once in its place (smaller in a bin or a bridge's gap, so the place shows round it).
func placed_scale() -> float:
	return 1.0


## Subclasses: something was placed or taken (wires, the bridge's planks).
func placed_changed() -> void:
	pass


func is_ready() -> bool:
	return placing.complete()


func response() -> Variant:
	return placing.response()


## Several things still to place: the ghost places one and the child the rest (one thing left: it only shows it).
func demo_kind() -> String:
	var wrong := 0
	for i in placing.things:
		if placing.right_place(ex, i) != placing.at[i]:
			wrong += 1
	return DEMO_DO if wrong >= 2 else DEMO_SHOW


## A thing says its card's words; a place its name (a bin, a partner), where it has one.
func spoken_name(t: String) -> String:
	var list: Array = []
	var tail := t.get_slice("_", 1)
	var i := int(tail) if tail.is_valid_int() else -1
	if t.begins_with("thing_"):
		list = ex.get("labels" if placing.kind == "label" else "items", [])
	elif t.begins_with(spot_prefix + "_") and placing.kind == "sort":
		list = ex.get("groups", [])
	elif t.begins_with(spot_prefix + "_") and placing.kind == "match":
		list = ex.get("matches", [])
	if i < 0 or i >= list.size():
		return ""
	var v: Variant = list[i]
	return str((v as Dictionary).get("text", "")) if v is Dictionary else str(v)


func ghost() -> Array[String]:
	var g := placing.ghost_step(ex)
	if g.is_empty():
		return [] as Array[String]
	var t := "thing_%d" % int(g.thing)
	if int(g.place) < 0:
		return [t, t] as Array[String]   # lift the wrong one and put it back home
	return [t, "%s_%d" % [spot_prefix, int(g.place)]] as Array[String]


func show_answer() -> void:
	if carried != "":
		put_home()
	placing.show_answer(ex)
	layout()


func react(outcome: String) -> void:
	match outcome:
		PlayLoop.RIGHT:
			celebrate()
		PlayLoop.NOT_YET, PlayLoop.GHOST:
			if carried != "":
				put_home()
			placing.clear()
			layout()
		PlayLoop.SHOWN:
			show_answer()


## Subclasses: the world's happy answer (lamps light, the buddy walks).
func celebrate() -> void:
	for n: Node3D in spots:
		hop(n)


func _index(thing: String) -> int:
	return int(thing.get_slice("_", 1))
