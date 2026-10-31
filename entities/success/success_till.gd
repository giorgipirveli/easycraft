class_name SuccessTill
extends RefCounted
## Owner #115 (S3): the coin tray of My Business's shop and the Market Square (like My Money Stall's, MarketRoom): pretend
## market coins of 1, 2, 5 and 10 and a 20 note (never the child's gold), each a room target "coin_<value>" (a coins
## step's "coin_<value>" adds one), "coins_back" to take one back, and the places coins go (a customer's hand, the till,
## the cash box, the flour jar, Bobo's hand, a merchant's hand) as small piles that count up. The tray moves to where the
## child stands for a step (move_to), so its coins are always in front of them, flat and in VR (the hand squeezes a coin).

const COIN := Color("ffc93c")
const NOTE := Color("8fd18a")
const ALL: Array[int] = [1, 2, 5, 10, 20]

var room: LifeRoom
var tray: Node3D
var piles := {}   # where -> Array of coin meshes
var labels := {}  # where -> Label3D (the count over the pile), when it has one


## Builds the tray at `at` (room-local) with the coins in `values` shown (the others hidden: a hidden coin is never pressed).
func build(on: LifeRoom, at: Vector3, values: Array) -> void:
	room = on
	tray = Node3D.new()
	tray.name = "Tray"
	tray.position = at
	room.add_child(tray)
	LifeRoomKit.box(tray, "TrayBase", Vector3(0.7, 0.02, 0.22), Vector3.ZERO, Color("6b4a2a"))
	for i in ALL.size():
		var v := ALL[i]
		var c_at := Vector3(-0.27 + i * 0.135, 0.02, 0)
		var coin: MeshInstance3D
		if v == 20:
			coin = LifeRoomKit.box(tray, "Note20", Vector3(0.11, 0.01, 0.07), c_at, NOTE)
		else:
			coin = LifeRoomKit.cylinder(tray, "Coin%d" % v, 0.03 + 0.004 * i, 0.012, c_at, COIN)
		LifeRoomKit.sign(coin, "Value", str(v), Vector3(0, 0.06, 0), 0.0024, Color("1f2a4a"))
		coin.visible = values.has(v)
		room.add_target("coin_%d" % v, coin, 0.06)
	room.add_spot_target("coins_back", tray, Vector3(0.0, 0.05, 0.14), 0.1)


## A place coins go: a target at `at` (room-local) with its pile, and a count over it when `counted`.
func add_place(where: String, at: Vector3, radius: float = 0.15, counted: bool = false) -> void:
	room.add_spot_target(where, room, at, radius)
	piles[where] = []
	if counted:
		labels[where] = LifeRoomKit.sign(room, "Count_" + where, "", at + Vector3(0, 0.16, 0), 0.003)


func has_place(where: String) -> bool:
	return piles.has(where)


func move_to(at: Vector3) -> void:
	if tray:
		tray.position = at


## The coins given so far (a coins step's state "given"), a little stack at their place.
func show_pile(where: String, given: Array) -> void:
	if not piles.has(where) or not room.has_target(where):
		return
	var pile: Array = piles[where]
	while pile.size() > given.size():
		(pile.pop_back() as Node3D).queue_free()
	var base := room.to_local(room.target_position(where))
	while pile.size() < given.size():
		var i := pile.size()
		var v := int(given[i])
		var c := LifeRoomKit.cylinder(room, "Given", 0.03, 0.012, base + Vector3((i % 4) * 0.05 - 0.07, 0.01 + (i / 4) * 0.014, 0),
			NOTE if v == 20 else COIN)
		pile.append(c)
	if labels.has(where):
		(labels[where] as Label3D).text = str(given.reduce(func(a: int, b: Variant) -> int: return a + int(b), 0))


func clear_pile(where: String) -> void:
	if piles.has(where):
		for c: Node3D in piles[where]:
			if is_instance_valid(c):
				c.queue_free()
		(piles[where] as Array).clear()


## How many coins the pile at `where` shows (tests).
func pile_size(where: String) -> int:
	return (piles.get(where, []) as Array).size()
