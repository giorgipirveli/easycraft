class_name TestStation
extends PlayStation
## Owner #122 (G0), Test it (design §5.1; honest limit in the notes: a claim the game can't show is a two-way choice in
## costume): the claim is tested at two gates in the hedge, TRUE (green) and FALSE (orange). The child opens one (a tap,
## a hand pushing it, or the laser): right, it swings open and the buddy runs through to the meadow beyond; not yet, it
## swings back gently. The gate opened is ExerciseCheck's response (true or false).

const AT_X := 0.42

var chosen := -1
var doors: Array[Node3D] = []
var buddy: LifeBuddy
var buddy_home := Vector3(0, 0, 0.3)


func build() -> void:
	LifeRoomKit.box(self, "Hedge", Vector3(2.4, 0.9, 0.3), Vector3(0, 0.45, -0.1), PlayArena.GRASS_DARK)
	var words := ["TRUE", "FALSE"]
	var colours := [Color("2fae4e"), Color("f08a1c")]
	for i in 2:
		var x := -AT_X if i == 0 else AT_X
		var gate := Node3D.new()
		gate.name = "Gate%d" % i
		gate.position = Vector3(x, 0, 0.1)
		add_child(gate)
		LifeRoomKit.box(gate, "Arch", Vector3(0.62, 0.08, 0.12), Vector3(0, 1.08, 0), PlayKit.WOOD_DARK)
		var door := Node3D.new()
		door.name = "Door"
		door.position = Vector3(-0.26, 0, 0)
		gate.add_child(door)
		var board := LifeRoomKit.box(door, "Board", Vector3(0.52, 0.95, 0.04), Vector3(0.26, 0.55, 0), colours[i])
		PlayKit.words(gate, "Word", words[i], Vector3(0, 1.25, 0.06), 0.0016, 64, Color.WHITE)
		doors.append(door)
		add("gate_%d" % i, board, 0.3)   # the gate's own board: a hand pushes it, it swings
	var who := PlayChoose.buddy(seed)
	buddy = LifeBuddy.new(who.colour, str(who.name))
	buddy.scale = Vector3.ONE * 0.6
	buddy.position = buddy_home
	buddy.rotation.y = PI
	add_child(buddy)


func view_cam() -> Vector3:
	return Vector3(0, 1.5, 1.85)


func view_look() -> Vector3:
	return Vector3(0, 0.85, -0.1)


func answers_by_acting() -> bool:
	return true


func press(t: String) -> void:
	if not t.begins_with("gate_"):
		return
	chosen = int(t.get_slice("_", 1))
	_swing(chosen, true)
	acted.emit()


func is_ready() -> bool:
	return chosen >= 0


func response() -> Variant:
	return PlayChoose.response(ex, chosen)


func ghost() -> Array[String]:
	var out: Array[String] = []
	var r := PlayChoose.right_option(ex)
	if chosen != r:
		out.append("gate_%d" % r)
	return out


func show_answer() -> void:
	chosen = PlayChoose.right_option(ex)
	_swing(chosen, true)
	move(buddy, Vector3(doors[chosen].get_parent().position.x, 0, -0.6))


func react(outcome: String) -> void:
	match outcome:
		PlayLoop.RIGHT:
			move(buddy, Vector3(doors[chosen].get_parent().position.x, 0, -0.6))
			hop(buddy)
		PlayLoop.NOT_YET, PlayLoop.GHOST:
			_swing(chosen, false)
			shake(buddy)
			chosen = -1
		PlayLoop.SHOWN:
			show_answer()


func _swing(i: int, open: bool) -> void:
	if i < 0 or i >= doors.size():
		return
	var to := -1.4 if open else 0.0
	if UiMotion.calm() or not is_inside_tree():
		doors[i].rotation.y = to
		return
	create_tween().tween_property(doors[i], "rotation:y", to, 0.45)
