class_name ChooseStation
extends PlayStation
## Owner #122 (G0), Choose by doing (design §5.1, the weakest bridge: a choice in costume, said so in the notes): a buddy
## needs something, and the choices are things to act with, never buttons on a panel (PlayChoose.costume):
## - GIVE: each choice is a crate on the table (its words or its picture); the child gives one to the buddy (flat: tap
##   the crate, tap the buddy; VR: carry it into the buddy's paws). Right: the buddy hops, happy; not yet: the buddy
##   hands it back.
## - PATH: each choice is a signpost at the start of a path; the child sends the buddy down one (a tap, the hand or the
##   laser on the sign). Right: the gate at its end opens; not yet: the buddy comes back.
## The act is the answer (`acted`): the choice's index is ExerciseCheck's response.

var costume := PlayChoose.GIVE
var options: Array[Dictionary] = []
var chosen := -1
var buddy: LifeBuddy
var buddy_home := Vector3.ZERO
var gates: Array[Node3D] = []
var path_ends: Array[Vector3] = []


func build() -> void:
	costume = PlayChoose.costume(ex, seed, str(params.get("costume", "")))
	options = PlayChoose.options(ex)
	var who := PlayChoose.buddy(seed)
	buddy = LifeBuddy.new(who.colour, str(who.name))
	add_child(buddy)
	if costume == PlayChoose.PATH:
		_build_paths()
	else:
		_build_crates()


func _build_crates() -> void:
	PlayKit.table(self, TABLE_AT, TABLE_SIZE, TABLE_TOP)
	var n := options.size()
	var pictures := options.any(func(o: Dictionary) -> bool: return o.has("picture"))
	var size := Vector3(0.36, 0.24, 0.06) if pictures else Vector3(0.36, 0.13, 0.06)
	var places := rows_of(n, 3, 0.42, FRONT_Z, 0.14, ON_TABLE + (0.06 if pictures else 0.0))
	for i in n:
		var crate := PlayKit.card(self, "Crate%d" % i, options[i], places[i], Color("c98d4f"), size)
		add_thing("thing_%d" % i, crate, 0.14)
	buddy_home = Vector3(0, 0.35, BACK_Z - 0.14)   # on a little stand behind the table, its paws at the table's height
	LifeRoomKit.box(self, "Stand", Vector3(0.5, 0.35, 0.4), Vector3(0, 0.175, buddy_home.z), Color("6b7a99"))
	buddy.position = buddy_home
	buddy.scale = Vector3.ONE * 0.85
	var paws := Node3D.new()   # where the buddy's paws reach out: the thing given lands there
	paws.name = "Paws"
	paws.position = buddy_home + Vector3(0, 0.45, 0.17)
	add_child(paws)
	add("buddy", paws, 0.26)


func _build_paths() -> void:
	var n := options.size()
	var xs := spread(n, 0.44)
	buddy_home = Vector3(-0.78 if n < 5 else -1.1, 0, 0.32)   # beside the signs, never in front of them
	buddy.position = buddy_home
	buddy.rotation.y = PI
	buddy.scale = Vector3.ONE * 0.6
	for i in n:
		var start := Vector3(xs[i], 0, 0.35)
		var end := Vector3(xs[i] * 2.2, 0, -1.7)
		path_ends.append(end + Vector3(0, 0, 0.3))
		var mid := (start + end) * 0.5
		var path := LifeRoomKit.box(self, "Path%d" % i, Vector3(0.22, 0.02, start.distance_to(end)), mid + Vector3(0, 0.02, 0),
			Color("d9c69a"))
		path.rotation.y = atan2(start.x - end.x, start.z - end.z)
		var gate := Node3D.new()
		gate.name = "Gate%d" % i
		gate.position = end
		add_child(gate)
		LifeRoomKit.box(gate, "Left", Vector3(0.06, 0.7, 0.06), Vector3(-0.22, 0.35, 0), PlayKit.WOOD_DARK)
		LifeRoomKit.box(gate, "Right", Vector3(0.06, 0.7, 0.06), Vector3(0.22, 0.35, 0), PlayKit.WOOD_DARK)
		var door := Node3D.new()
		door.name = "Door"
		door.position = Vector3(-0.2, 0, 0)
		gate.add_child(door)
		LifeRoomKit.box(door, "Board", Vector3(0.4, 0.5, 0.03), Vector3(0.2, 0.3, 0), PlayKit.WOOD)
		gates.append(door)
		var sign := Node3D.new()
		sign.name = "Sign%d" % i
		sign.position = Vector3(xs[i], 0.74, 0.45)
		add_child(sign)
		LifeRoomKit.box(sign, "Post", Vector3(0.04, 0.74, 0.04), Vector3(0, -0.37, -0.04), PlayKit.WOOD_DARK)
		PlayKit.card(sign, "Board", options[i], Vector3.ZERO, Color("c98d4f"),
			Vector3(0.38, 0.24 if options[i].has("picture") else 0.14, 0.04))
		add("sign_%d" % i, sign, 0.17)


func view_cam() -> Vector3:
	return Vector3(0, 1.6, 1.8) if costume == PlayChoose.PATH else super()


func view_look() -> Vector3:
	return Vector3(0, 0.95, -0.2) if costume == PlayChoose.PATH else super()


func answers_by_acting() -> bool:
	return true


func spot_names() -> Array[String]:
	var out: Array[String] = []
	if costume == PlayChoose.GIVE:
		out.append("buddy")
	return out


func put(thing: String, _spot: String) -> void:
	chosen = int(thing.get_slice("_", 1))
	move(things[thing], (get_node("Paws") as Node3D).position)
	acted.emit()


func take(thing: String) -> void:
	if chosen == int(thing.get_slice("_", 1)):
		chosen = -1


func press(t: String) -> void:
	if not t.begins_with("sign_"):
		return
	chosen = int(t.get_slice("_", 1))
	_walk_to(chosen)
	acted.emit()


func _walk_to(i: int) -> void:
	if i < 0 or i >= path_ends.size():
		return
	move(buddy, path_ends[i])


func is_ready() -> bool:
	return chosen >= 0


func response() -> Variant:
	return PlayChoose.response(ex, chosen)


func ghost() -> Array[String]:
	var r := PlayChoose.right_option(ex)
	if chosen == r:
		return [] as Array[String]
	if costume == PlayChoose.PATH:
		return ["sign_%d" % r] as Array[String]
	return ["thing_%d" % r, "buddy"] as Array[String]


func show_answer() -> void:
	var r := PlayChoose.right_option(ex)
	if costume == PlayChoose.PATH:
		chosen = r
		_walk_to(r)
		_open_gate(r)
		return
	_give_back()
	chosen = r
	move(things["thing_%d" % r], (get_node("Paws") as Node3D).position)


func react(outcome: String) -> void:
	match outcome:
		PlayLoop.RIGHT:
			buddy.face("happy")
			hop(buddy)
			if costume == PlayChoose.PATH:
				_open_gate(chosen)
		PlayLoop.NOT_YET, PlayLoop.GHOST:
			shake(buddy)
			if costume == PlayChoose.PATH:
				move(buddy, buddy_home)
			else:
				_give_back()
			chosen = -1
		PlayLoop.SHOWN:
			show_answer()


## The buddy hands the crate back (it goes home on the table).
func _give_back() -> void:
	if chosen >= 0 and costume == PlayChoose.GIVE:
		var t := "thing_%d" % chosen
		move(things[t], homes[t])
	chosen = -1


func _open_gate(i: int) -> void:
	if i < 0 or i >= gates.size():
		return
	if UiMotion.calm() or not is_inside_tree():
		gates[i].rotation.y = -1.6
		return
	create_tween().tween_property(gates[i], "rotation:y", -1.6, 0.5)
