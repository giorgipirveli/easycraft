class_name WaterRoom
extends LifeRoom
## Owner #118 (docs/design/life-skills.md §14, the catalogue's row 2: water; Life L3a): Water Safety's practice places,
## built for the track: the practice pool (Little and Middle: the deck, Gus the lifeguard in his tall chair, the float on
## its post, the long reaching pole, the bench where a buddy puts on a life jacket, friends in the water), the practice
## beach (Middle: the red and yellow flags, the waves breaking except over a calm-looking rip channel, its arrows drifting
## out to sea) and the practice pond in winter (Big: snowy banks, the ice with a hole the child practises getting out of,
## a second hole where Mo falls in, a long branch, a blanket). Calm: cartoon buddies with friendly faces (a worried face
## at most), soft blue see-through water, never a struggle shown. The safe mistakes' gentle pictures (on_mistake): a
## second figure in the water beside the friend (two need help), a tired swimmer in the rip's arrows, cracks spreading
## round a figure standing on the ice. "More real" (a grown-up's choice, Big): darker cold water and more cracks.

const DECK := Color("e9e4d8")
const TILE := Color("8fd0f0")
const POOL_WATER := Color(0.35, 0.72, 0.95, 0.5)
const SEA := Color(0.25, 0.6, 0.85, 0.55)
const RIP := Color(0.18, 0.45, 0.7, 0.6)
const SAND := Color("ecd9a8")
const SNOW := Color("f4f8fc")
const ICE := Color("b6d3e8")
const COLD_WATER := Color(0.15, 0.32, 0.55, 0.7)
const FOAM := Color(1, 1, 1, 0.85)
const ORANGE := Color("ff7a2e")
const CRACK := Color("37506b")
## The pool's swimmers' places (x, z); the seed shuffles who is where.
const SWIM_SPOTS: Array[Vector2] = [Vector2(-1.8, -2.8), Vector2(1.7, -3.9), Vector2(-0.7, -4.6), Vector2(0.9, -2.2)]
const WATER_Y := -0.15
const BEACH_X := 40.0
const POND_X := -40.0
const RIP_X := 44.75

var gus: LifeBuddy
var bench_buddy: LifeBuddy
var jacket: Node3D
var swimmers := {}
var pip_in: LifeBuddy
var ring_post: Node3D
var ring_water: Node3D
var rope: MeshInstance3D
var pole: Node3D
var pole_held: Node3D
var arrows: Array[Node3D] = []
var mo_ice: LifeBuddy
var hole_b_lid: MeshInstance3D
var branch: Node3D
var branch_held: Node3D
var rip_on := false
var _arrow_t := 0.0


func build() -> void:
	name = "WaterRoom"
	env = LifeRoomKit.environment(Color("9fd3f2"), Color("eaf6fd"), 0.7)
	if track == "big":
		start_view = "bank"
		_pond()
	else:
		start_view = "deck"
		_pool()
		if track == "middle":
			_beach()
	_views()
	_people_look()


# --- The practice pool -------------------------------------------------------------------------------------------------

func _pool() -> void:
	var d := decor()   # the rooms' look (2026-10-17): the deck and the pool in tiles
	for k: Array in [[Vector3(10, 0.1, 4), Vector3(0, -0.05, 1)], [Vector3(10, 0.1, 2), Vector3(0, -0.05, -7)],
			[Vector3(2, 0.1, 5), Vector3(-4, -0.05, -3.5)], [Vector3(2, 0.1, 5), Vector3(4, -0.05, -3.5)]]:
		d.tiled("Deck", LifeRoomDecor.SLABS, k[0], k[1], Color("efe0c6"), 0.6)
	d.tiled("PoolFloor", LifeRoomDecor.TILE, Vector3(6, 0.1, 5), Vector3(0, -1.65, -3.5), Color("8fd0f0"), 0.5, 0.0,
		LifeRoomDecor.BAKED)
	for w: Array in [[Vector3(6, 1.6, 0.05), Vector3(0, -0.85, -1.0)], [Vector3(6, 1.6, 0.05), Vector3(0, -0.85, -6.0)],
			[Vector3(0.05, 1.6, 5), Vector3(-3.0, -0.85, -3.5)], [Vector3(0.05, 1.6, 5), Vector3(3.0, -0.85, -3.5)]]:
		d.tiled("PoolSide", LifeRoomDecor.TILE, w[0], w[1], Color("82c4e6"), 0.5, 0.0, LifeRoomDecor.BAKED)
	d.box("PoolEdge", Vector3(6.3, 0.05, 0.16), Vector3(0, 0.025, -0.93), Color("fdfdf8"), 0.0, LifeRoomDecor.SHELL)
	d.box("PoolEdge", Vector3(6.3, 0.05, 0.16), Vector3(0, 0.025, -6.07), Color("fdfdf8"), 0.0, LifeRoomDecor.SHELL)
	_pool_garden()
	LifeRoomKit.box(self, "PoolWater", Vector3(6, 1.45, 5), Vector3(0, WATER_Y - 0.725, -3.5), POOL_WATER)
	LifeRoomKit.sign(self, "PoolSign", "PRACTICE POOL", Vector3(-1.5, 2.4, -7.2), 0.006, Color("1f6fa8"))
	LifeRoomKit.sign(self, "DeepSign", "DEEP END", Vector3(1.6, 0.25, -0.75), 0.003, Color("1f2a4a"))
	# on a board by the far fence (at the deck's edge the first view cut it)
	var walk := LifeRoomKit.sign(self, "WalkSign", "PLEASE WALK", Vector3(-2.2, 1.45, -7.62), 0.0034, Color("2fae4e"))
	walk.billboard = BaseMaterial3D.BILLBOARD_DISABLED   # painted on its board (turned to the eye, it sank into the board)
	LifeRoomKit.light(self, Vector3(0, 3.5, -2.0), 0.6, 12.0)
	_lifeguard()
	_ring_and_pole()
	_bench()
	_swimmers()


func _lifeguard() -> void:
	var chair := Node3D.new()
	chair.name = "LifeguardChair"
	chair.position = Vector3(3.4, 0, -2.6)
	add_child(chair)
	# a practice pool's chair, lower than a beach's: Gus's head stays in the first view, under the coach's bar
	for x: float in [-0.3, 0.3]:
		LifeRoomKit.box(chair, "Leg", Vector3(0.06, 0.72, 0.06), Vector3(x, 0.36, 0), Color("f4f6f8"))
		LifeRoomKit.box(chair, "Rung", Vector3(0.06, 0.04, 0.5), Vector3(x, 0.35, 0), Color("f4f6f8"))
	LifeRoomKit.box(chair, "Seat", Vector3(0.7, 0.06, 0.5), Vector3(0, 0.72, 0), Color("e8544e"))
	LifeRoomKit.box(chair, "Back", Vector3(0.7, 0.5, 0.05), Vector3(0, 1.0, 0.24), Color("e8544e"))
	gus = LifeBuddy.new(Color("7b5cd6"), "Gus")
	gus.scale = Vector3.ONE * 1.55   # a grown-up
	gus.position = Vector3(3.4, 0.01, -2.6)
	gus.rotation.y = -PI / 2 - 0.4
	add_child(gus)
	gus.pose("sit")
	add_spot_target("lifeguard", self, Vector3(3.4, 1.6, -2.6), 0.5)


func _ring_and_pole() -> void:
	ring_post = Node3D.new()
	ring_post.name = "RingPost"
	ring_post.position = Vector3(-1.0, 0, -0.55)
	add_child(ring_post)
	LifeRoomKit.box(ring_post, "Post", Vector3(0.06, 1.2, 0.06), Vector3(0, 0.6, 0), Color("f4f6f8"))
	_ring(ring_post, Vector3(0, 1.05, 0.05))
	ring_water = Node3D.new()
	ring_water.name = "RingInWater"
	ring_water.position = Vector3(0.75, WATER_Y + 0.02, -2.1)
	ring_water.visible = false
	add_child(ring_water)
	_ring(ring_water, Vector3.ZERO, true)
	rope = LifeRoomKit.box(self, "Rope", Vector3(0.02, 0.02, 1.0), Vector3.ZERO, Color("f2e4c0"))
	rope.visible = false
	var rope_end := add_spot_target("rope", self, Vector3(0.35, 0.8, -0.65), 0.14)
	rope_end.visible = false
	pole = Node3D.new()
	pole.name = "Pole"
	pole.position = Vector3(1.5, 0, -0.5)
	add_child(pole)
	# leaning to the right, its top on a hook on the lifeguard's side (leaning left it crossed the first view's middle)
	var stick := LifeRoomKit.box(pole, "Stick", Vector3(0.05, 2.4, 0.05), Vector3(0, 1.1, 0), Color("ffd23f"))
	stick.rotation.z = -0.25
	LifeRoomKit.box(stick, "Hook", Vector3(0.25, 0.05, 0.05), Vector3(0.12, 1.12, 0), Color("ffd23f"))
	add_spot_target("reach_pole", pole, Vector3(0, 0.95, 0), 0.25)
	pole_held = Node3D.new()
	pole_held.name = "PoleHeld"
	pole_held.visible = false
	add_child(pole_held)
	var held := LifeRoomKit.box(pole_held, "Stick", Vector3(0.05, 0.05, 1.6), Vector3(0.3, 0.35, -1.35), Color("ffd23f"))
	held.rotation.x = 0.28
	add_spot_target("pole_end", pole_held, Vector3(0.35, 0.55, -0.75), 0.16)
	add_spot_target("pole_grip", pole_held, Vector3(0.2, 0.6, -0.55), 0.16)
	add_spot_target("jump_in", self, Vector3(0.0, WATER_Y + 0.03, -1.5), 0.35)


## A float (a lifebuoy): orange and white blocks in a ring, standing (on its post) or lying on the water.
func _ring(parent: Node3D, at: Vector3, lying: bool = false) -> void:
	var r := Node3D.new()
	r.name = "Ring"
	r.position = at
	if lying:
		r.rotation.x = -PI / 2
	parent.add_child(r)
	for i in 8:
		var a := TAU * i / 8.0
		var bit := LifeRoomKit.box(r, "Bit", Vector3(0.1, 0.1, 0.07), Vector3(cos(a) * 0.17, sin(a) * 0.17, 0),
			ORANGE if i % 2 == 0 else Color.WHITE)
		bit.rotation.z = a


func _bench() -> void:
	LifeRoomKit.box(self, "Bench", Vector3(0.5, 0.45, 1.4), Vector3(-3.5, 0.225, 1.0), Color("a8642a"))
	bench_buddy = LifeBuddy.new(Color("1fa6a0") if track == "little" else Color("e85a9a"), "BenchBuddy")
	bench_buddy.position = Vector3(-3.4, 0, 1.0)
	bench_buddy.rotation.y = PI / 2
	bench_buddy.visible = track == "little"   # Middle: Pip-pop comes to the bench after her swim
	add_child(bench_buddy)
	bench_buddy.pose("sit")
	LifeRoomPeople.feel(bench_buddy, "happy")
	jacket = Node3D.new()
	jacket.name = "LifeJacket"
	jacket.position = Vector3(-3.55, 0.47, 1.55)   # lying on the bench until it goes on
	add_child(jacket)
	LifeRoomKit.box(jacket, "Vest", Vector3(0.3, 0.06, 0.34), Vector3.ZERO, ORANGE)
	add_spot_target("jacket_on", self, Vector3(-3.4, 0.67, 1.0), 0.26)
	add_spot_target("jacket_buckle", self, Vector3(-3.27, 0.6, 1.0), 0.11)
	add_spot_target("jacket_shoulders", self, Vector3(-3.4, 0.88, 1.0), 0.15)


func _swimmers() -> void:
	var order: Array = range(SWIM_SPOTS.size())
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(["water", int(vars.get("seed", 0))])
	GenKit.shuffle(rng, order)
	var who := [["mo_quiet", Color("ffb347"), "Mo"], ["pip_wave", Color("e85a9a"), "PipPop"],
		["bobo_splash", Color("1fa6a0"), "Bobo"], ["kiki_float", Color("5aa8e6"), "Kiki"]]
	for i in who.size():
		var b := LifeBuddy.new(who[i][1], who[i][2])
		var spot: Vector2 = SWIM_SPOTS[int(order[i])]
		b.position = Vector3(spot.x, WATER_Y - 0.87, spot.y)
		b.visible = false
		add_child(b)
		swimmers[who[i][0]] = b
		add_spot_target(str(who[i][0]), self, Vector3(spot.x, 0.0, spot.y), 0.36)
		(targets[who[i][0]].node as Node3D).visible = false
	var mo: LifeBuddy = swimmers.mo_quiet
	mo.position.y = WATER_Y - 0.93   # low in the water, mouth at the surface
	mo.head.rotation.x = -0.45   # head tilted back
	mo.arm_near.rotation.z = -1.3   # arms out on the water, not waving
	mo.arm_far.rotation.z = 1.3
	LifeRoomPeople.feel(mo, "worried")
	var pip: LifeBuddy = swimmers.pip_wave
	pip.arm_far.rotation.z = 2.7   # waving
	LifeRoomPeople.feel(pip, "happy")
	var bobo: LifeBuddy = swimmers.bobo_splash
	bobo.arm_near.rotation.z = -2.6
	bobo.arm_far.rotation.z = 2.6
	LifeRoomPeople.feel(bobo, "happy")
	for k in 4:
		LifeRoomKit.sphere(bobo, "Splash", 0.07, Vector3(-0.3 + k * 0.2, 0.87, 0.2 - (k % 2) * 0.35), FOAM)
	var kiki: LifeBuddy = swimmers.kiki_float
	kiki.position.y = WATER_Y - 0.45
	kiki.rotation.x = -1.2   # floating on her back
	LifeRoomPeople.feel(kiki, "happy")
	pip_in = LifeBuddy.new(Color("e85a9a"), "PipInWater")
	pip_in.position = Vector3(1.0, WATER_Y - 0.9, -2.3)
	pip_in.visible = false
	add_child(pip_in)
	LifeRoomPeople.feel(pip_in, "worried")
	add_spot_target("pip_in_water", self, Vector3(1.0, -0.05, -2.3), 0.38)


# --- The practice beach ------------------------------------------------------------------------------------------------

func _beach() -> void:
	var beach := Node3D.new()
	beach.name = "Beach"
	add_child(beach)
	_beach_look(beach)   # the rooms' look: the sand in its picture, palms, parasols, dunes
	LifeRoomKit.box(beach, "Sea", Vector3(24, 1.5, 29), Vector3(BEACH_X, -0.75, -15.5), SEA)
	LifeRoomKit.box(beach, "SeaBed", Vector3(24, 0.1, 29), Vector3(BEACH_X, -1.55, -15.5), SAND.darkened(0.25))
	LifeRoomKit.box(beach, "Rip", Vector3(1.6, 0.04, 16), Vector3(RIP_X, 0.01, -9.0), RIP)
	for z: float in [-3.5, -6.5, -11.0]:   # the waves break everywhere but over the rip: a real clue
		LifeRoomKit.box(beach, "Foam", Vector3(RIP_X - 0.9 - 28.0, 0.06, 0.35), Vector3((28.0 + RIP_X - 0.9) * 0.5, 0.03, z), FOAM)
		LifeRoomKit.box(beach, "Foam", Vector3(52.0 - RIP_X - 0.9, 0.06, 0.35), Vector3((52.0 + RIP_X + 0.9) * 0.5, 0.03, z), FOAM)
	for i in 6:
		var arrow := Node3D.new()
		arrow.name = "RipArrow"
		arrow.position = Vector3(RIP_X, 0.06, -3.0 - i * 2.2)
		beach.add_child(arrow)
		for side: int in [-1, 1]:
			var bar := LifeRoomKit.box(arrow, "Bar", Vector3(0.06, 0.03, 0.55), Vector3(side * 0.18, 0, 0.0), Color(1, 1, 1, 0.9))
			bar.rotation.y = side * 0.6
		arrow.visible = false
		arrows.append(arrow)
	for x: float in [BEACH_X - 3.5, BEACH_X + 1.5]:
		LifeRoomKit.box(beach, "FlagPole", Vector3(0.06, 2.2, 0.06), Vector3(x, 1.1, -0.6), Color("f4f6f8"))
		LifeRoomKit.box(beach, "FlagRed", Vector3(0.6, 0.25, 0.02), Vector3(x + 0.33, 2.05, -0.6), Color("e8544e"))
		LifeRoomKit.box(beach, "FlagYellow", Vector3(0.6, 0.25, 0.02), Vector3(x + 0.33, 1.8, -0.6), Color("ffd23f"))
	LifeRoomKit.sign(beach, "BeachSign", "PRACTICE BEACH", Vector3(BEACH_X, 2.8, 6.5), 0.006, Color("1f6fa8"))
	LifeRoomKit.box(beach, "LifeguardHut", Vector3(1.6, 1.8, 1.4), Vector3(BEACH_X - 6, 0.9, 5.0), Color("e8544e"))
	add_spot_target("between_flags", beach, Vector3(BEACH_X - 1.0, 0.05, -2.2), 0.6)
	add_spot_target("rip_water", beach, Vector3(RIP_X, 0.05, -2.5), 0.6)
	add_spot_target("swim_back", beach, Vector3(RIP_X, 0.1, -4.0), 0.6)
	add_spot_target("swim_along", beach, Vector3(RIP_X - 5.0, 0.1, -9.0), 0.6)
	add_spot_target("swim_along_r", beach, Vector3(RIP_X + 5.0, 0.1, -9.0), 0.6)
	add_spot_target("shore", beach, Vector3(BEACH_X, 0.1, -2.5), 0.7)
	add_spot_target("shore_r", beach, Vector3(49.5, 0.1, -2.5), 0.7)
	for t: String in ["swim_along", "swim_along_r", "shore", "shore_r"]:   # a buoy marks where to swim
		LifeRoomKit.sphere(target_node(t), "Buoy", 0.14, Vector3.ZERO, Color("ffd23f"))


# --- The practice pond in winter ---------------------------------------------------------------------------------------

func _pond() -> void:
	var pond := Node3D.new()
	pond.name = "Pond"
	add_child(pond)
	env = LifeRoomKit.environment(Color("c9dcef"), Color("eef4fa"), 0.75)
	decor().box("Bank", Vector3(24, 0.4, 8.5), Vector3(POND_X, -0.2, 3.75), SNOW, 0.0, LifeRoomDecor.SHELL)
	_pond_look()
	var water := COLD_WATER.darkened(0.2) if more_real() else COLD_WATER
	LifeRoomKit.box(pond, "Water", Vector3(24, 1.9, 19.5), Vector3(POND_X, -1.03, -10.25), water)
	# the ice, with hole A (x -41..-39, z -5..-3) and hole B (x -37..-35.5, z -2.2..-1.2: covered until Mo falls in)
	for p: Array in [[-52.0, -41.0, -20.0, -0.5], [-41.0, -39.0, -20.0, -5.0], [-41.0, -39.0, -3.0, -0.5], [-39.0, -37.0, -20.0, -0.5],
			[-37.0, -35.5, -20.0, -2.2], [-37.0, -35.5, -1.2, -0.5], [-35.5, -28.0, -20.0, -0.5]]:
		LifeRoomKit.box(pond, "Ice", Vector3(p[1] - p[0], 0.08, p[3] - p[2]), Vector3((p[0] + p[1]) * 0.5, -0.04, (p[2] + p[3]) * 0.5),
			ICE)
	hole_b_lid = LifeRoomKit.box(pond, "IceLid", Vector3(1.5, 0.08, 1.0), Vector3(-36.25, -0.04, -1.7), ICE)
	var ice := LifeRoomKit.sign(pond, "IceSign", "DANGER: THIN ICE", Vector3(POND_X - 3.0, 1.6, 0.2), 0.005, Color("e8544e"))
	ice.billboard = BaseMaterial3D.BILLBOARD_DISABLED   # painted on its board (turned to the eye, it sank into the board)
	LifeRoomKit.box(pond, "SignPost", Vector3(0.06, 1.3, 0.06), Vector3(POND_X - 3.0, 0.65, 0.2), Color("8a5a34"))
	LifeRoomKit.sign(pond, "PondSign", "PRACTICE POND", Vector3(POND_X, 2.6, 6.5), 0.006, Color("1f6fa8"))
	for t: Vector3 in [Vector3(-46, 0, 4), Vector3(-33, 0, 5), Vector3(-49, 0, 1.5)]:
		LifeRoomKit.box(pond, "Trunk", Vector3(0.25, 1.4, 0.25), t + Vector3(0, 0.7, 0), Color("8a5a34"))
		LifeRoomKit.sphere(pond, "Snowy", 0.8, t + Vector3(0, 1.9, 0), Color("dfeee6"))
	add_spot_target("ice_edge", pond, Vector3(POND_X, 0.03, -3.1), 0.36)
	add_spot_target("bank_edge", pond, Vector3(-38.9, 0.12, -0.3), 0.45)
	LifeRoomKit.box(pond, "BlanketBench", Vector3(0.9, 0.35, 0.4), Vector3(-38.4, 0.175, 1.0), Color("a8642a"))
	var blanket := LifeRoomKit.box(pond, "Blanket", Vector3(0.6, 0.12, 0.35), Vector3(-38.4, 0.41, 1.0), Color("e8544e"))
	add_target("blanket", blanket, 0.32)
	mo_ice = LifeBuddy.new(Color("ffb347"), "MoInIce")
	mo_ice.position = Vector3(-36.25, -0.95, -1.75)
	mo_ice.rotation.y = 0.0
	mo_ice.visible = false
	add_child(mo_ice)
	LifeRoomPeople.feel(mo_ice, "worried")
	mo_ice.arm_near.rotation.x = -1.4   # arms out on the ice
	mo_ice.arm_far.rotation.x = -1.4
	branch = Node3D.new()
	branch.name = "Branch"
	add_child(branch)
	var stick := LifeRoomKit.box(branch, "Stick", Vector3(0.07, 0.07, 2.4), Vector3(-35.6, 0.05, 0.9), Color("8a5a34"))
	stick.rotation.y = 0.3
	add_spot_target("branch", branch, Vector3(-35.6, 0.1, 0.45), 0.32)
	add_spot_target("ice_walk", pond, Vector3(-36.25, 0.03, -0.9), 0.42)
	branch_held = Node3D.new()
	branch_held.name = "BranchHeld"
	branch_held.visible = false
	add_child(branch_held)
	var held := LifeRoomKit.box(branch_held, "Stick", Vector3(0.07, 0.07, 2.4), Vector3(-36.2, 0.15, -0.75), Color("8a5a34"))
	held.rotation.x = 0.12
	add_spot_target("branch_end", branch_held, Vector3(-36.25, 0.35, 0.0), 0.16)
	add_spot_target("branch_grip", branch_held, Vector3(-36.05, 0.4, 0.25), 0.16)


# --- Views -------------------------------------------------------------------------------------------------------------

func _views() -> void:
	add_view("deck", Vector3(0, 1.55, 2.6), Vector3(0.4, 0.2, -2.2), Vector3(0, 0, 1.4), 0.0)
	add_view("jacket", Vector3(-1.9, 1.25, 1.6), Vector3(-3.4, 0.7, 1.0), Vector3(-2.6, 0, 1.25), 1.28)
	add_view("pool_side", Vector3(0.3, 1.5, 1.2), Vector3(0.7, -0.1, -1.8), Vector3(0.3, 0, -0.35), 0.0)
	add_view("pool_watch", Vector3(0, 1.7, 1.6), Vector3(0, -0.2, -3.2), Vector3(0, 0, 0.6), 0.0)
	add_view("edge", Vector3(0.6, 1.4, 0.9), Vector3(0.2, -0.2, -2.0), Vector3(0.3, 0, -0.3), 0.0)
	add_view("beach", Vector3(BEACH_X, 1.6, 4.5), Vector3(BEACH_X + 2.0, 0, -3), Vector3(BEACH_X, 0, 3.0), 0.0)
	# in the sea the child's eye is just over the water (the feet below the surface), facing the shore at a slant
	add_view("sea", Vector3(RIP_X, 0.55, -9.4), Vector3(RIP_X - 3.55, 0.0, -5.46), Vector3(RIP_X, -0.85, -9.0), PI * 0.75)
	add_view("sea_r", Vector3(RIP_X, 0.55, -9.4), Vector3(RIP_X + 3.55, 0.0, -5.46), Vector3(RIP_X, -0.85, -9.0), -PI * 0.75)
	add_view("along", Vector3(BEACH_X, 0.55, -9.0), Vector3(BEACH_X, 0, -2.0), Vector3(BEACH_X, -0.85, -8.5), PI)
	add_view("along_r", Vector3(49.5, 0.55, -9.0), Vector3(49.5, 0, -2.0), Vector3(49.5, -0.85, -8.5), PI)
	add_view("shore", Vector3(BEACH_X + 2.0, 1.55, 2.4), Vector3(BEACH_X + 2.5, 0.3, -3.0), Vector3(BEACH_X + 2.0, 0, 1.0), 0.0)
	add_view("bank", Vector3(POND_X, 1.6, 4.0), Vector3(POND_X, 0, -4), Vector3(POND_X, 0, 2.5), 0.0)
	add_view("hole", Vector3(POND_X, 0.75, -4.4), Vector3(POND_X, 0, -2.0), Vector3(POND_X, -0.65, -3.55), PI)
	add_view("on_ice", Vector3(POND_X, 1.0, -3.0), Vector3(POND_X, 0, 0.2), Vector3(POND_X, 0, -2.3), PI)
	add_view("rolled", Vector3(-38.9, 1.0, -2.8), Vector3(-38.9, 0, 0.5), Vector3(-38.9, 0, -1.9), PI)
	add_view("back", Vector3(-38.9, 1.6, 2.8), Vector3(-38.6, 0.3, 0.2), Vector3(-38.9, 0, 1.8), 0.0)
	add_view("rescue", Vector3(-36.25, 1.55, 1.9), Vector3(-36.1, 0, -1.4), Vector3(-36.25, 0, 0.7), 0.0)


# --- Events ------------------------------------------------------------------------------------------------------------

func on_event(event: String) -> void:
	match event:
		"pip_in_water":
			pip_in.visible = true
		"lifeguard_comes":
			gus.pose("stand")
			gus.position = Vector3(2.6, 0, -0.5)
		"ring_lands":
			(ring_post.get_node("Ring") as Node3D).visible = false
			ring_water.visible = true
			target_node("rope").visible = true
			_rope_to(ring_water.global_position)
		"pip_to_side":
			pip_in.position = Vector3(0.55, WATER_Y - 0.9, -1.25)
			ring_water.position = Vector3(0.45, WATER_Y + 0.02, -1.15)
			_rope_to(ring_water.global_position)
			LifeRoomPeople.feel(pip_in, "happy")
		"pip_out":
			pip_in.position = Vector3(1.4, 0, -0.4)
			ring_water.visible = false
			rope.visible = false
			(ring_post.get_node("Ring") as Node3D).visible = true
		"ball_away":
			var ball := LifeRoomKit.sphere(self, "Ball", 0.15, Vector3(-0.8, WATER_Y + 0.08, -4.2), Color("ffb02e"))
			ball.name = "Ball"
		"four_swimmers":
			for t: String in swimmers:
				(swimmers[t] as Node3D).visible = true
				target_node(t).visible = true
		"mo_near_side":
			for t: String in swimmers:
				if t != "mo_quiet":
					(swimmers[t] as Node3D).visible = false
					target_node(t).visible = false
			var mo: LifeBuddy = swimmers.mo_quiet
			mo.visible = true
			mo.position = Vector3(0.4, WATER_Y - 0.93, -1.9)
		"mo_holds":
			var mo: LifeBuddy = mo_ice if track == "big" else swimmers.get("mo_quiet")
			mo.arm_far.rotation = Vector3(-1.6, 0, 0.3)
			mo.head.rotation.x = 0.0
		"mo_to_side":
			var mo: LifeBuddy = swimmers.mo_quiet
			mo.position = Vector3(0.3, WATER_Y - 0.9, -1.2)
			LifeRoomPeople.feel(mo, "happy")
		"pip_on_bench":
			bench_buddy.visible = true
		"rip_on", "rip_other_side":
			rip_on = true
			for a in arrows:
				a.visible = true
		"fall_in", "slide_out":
			pass
		"mo_falls":
			hole_b_lid.visible = false
			mo_ice.visible = true
		"mo_out":
			mo_ice.position = Vector3(-36.25, 0.0, -0.3)
			mo_ice.arm_near.rotation = Vector3.ZERO
			mo_ice.arm_far.rotation = Vector3.ZERO
			LifeRoomPeople.feel(mo_ice, "calm")
			branch_held.visible = false


func _rope_to(to: Vector3) -> void:
	var from := target_position("rope")
	rope.visible = true
	rope.global_transform = Transform3D(Basis.looking_at(to - from, Vector3.UP), (from + to) * 0.5)
	rope.scale = Vector3(1, 1, from.distance_to(to))


func step_started(step: Dictionary) -> void:
	if str(step.get("id", "")) == "jacket":
		bench_buddy.visible = true


func step_done(step: Dictionary) -> void:
	match str(step.get("id", "")):
		"jacket":   # the life jacket goes on the buddy (and its own target goes: a hand at the buckle presses the buckle)
			jacket.position = Vector3(-3.4, 0.67, 1.0)
			(jacket.get_node("Vest") as Node3D).scale = Vector3(1.0, 5.0, 0.8)
			target_node("jacket_on").visible = false
		"reach":
			if is_instance_valid(pole) and track == "middle":
				(pole.get_node("Stick") as Node3D).visible = false
				pole_held.visible = true
			if track == "big":
				(branch.get_node("Stick") as Node3D).visible = false
				branch_held.visible = true
		"ball":
			var ball := get_node_or_null("Ball")
			if ball:
				ball.queue_free()


func _process(delta: float) -> void:
	super(delta)
	if not rip_on:
		return
	_arrow_t += sim_delta(delta) * (1.4 if more_real() else 1.0)
	for i in arrows.size():   # the rip's arrows drift out to sea (at the room's own time: slow on the first tries)
		arrows[i].position.z = -3.0 - fmod(i * 2.2 + _arrow_t * 0.9, 13.2)


# --- The safe mistakes' gentle pictures --------------------------------------------------------------------------------

func on_mistake(event: String, on: bool) -> void:
	if not on:
		return
	var holder := mistake_holder()
	match event:
		"two_in_water":   # the helper in the water too, beside the friend: now two need help
			var helper := LifeBuddy.new(Color("2f7f6a"), "HelperInWater")
			helper.position = Vector3(-0.2, WATER_Y - 0.9, -1.85)
			holder.add_child(helper)
			LifeRoomPeople.feel(helper, "worried")
			LifeRoomKit.sign(holder, "Two", "NOW TWO NEED HELP", Vector3(0.1, 0.9, -1.9), 0.004, Color("ffd23f"))
		"rip_tired":   # a swimmer heading straight back, held in the rip's arrows, tired
			var swimmer := LifeBuddy.new(Color("2f7f6a"), "TiredSwimmer")
			swimmer.position = Vector3(RIP_X, -0.95, -6.5)
			swimmer.rotation.y = PI
			holder.add_child(swimmer)
			LifeRoomPeople.feel(swimmer, "calm")   # eyes half shut: tired
			for i in 3:
				var arrow := LifeRoomKit.box(holder, "PullOut", Vector3(0.08, 0.03, 0.9), Vector3(RIP_X, 0.08, -7.4 - i * 1.1),
					Color(1, 0.86, 0.3, 0.9))
				arrow.name = "PullOut%d" % i
			LifeRoomKit.sign(holder, "TooStrong", "THE RIP IS FASTER THAN YOU", Vector3(RIP_X, 1.0, -6.0), 0.004, Color("ffd23f"))
		"ice_cracks", "ice_cracks_helper":   # cracks spreading round a figure standing on the ice
			var at := Vector3(POND_X, 0.0, -2.0) if event == "ice_cracks" else Vector3(-36.25, 0.0, -0.9)
			var figure := LifeBuddy.new(Color(0.18, 0.5, 0.42, 1.0), "Standing")
			figure.position = at
			figure.rotation.y = PI if event == "ice_cracks" else 0.0
			holder.add_child(figure)
			LifeRoomPeople.feel(figure, "worried")
			var n := 10 if more_real() else 7
			for i in n:
				var a := TAU * i / n
				var crack := LifeRoomKit.box(holder, "Crack", Vector3(0.03, 0.02, 0.9), at + Vector3(sin(a) * 0.55, 0.01, cos(a) * 0.55),
					CRACK)
				crack.rotation.y = a


# --- The rooms' look (2026-10-17, docs/devlog/parts/rooms-look.md) -------------------------------------------------------

## The pool's garden: a lawn round the tiled deck, a white fence with the PLEASE WALK board, sun loungers and a parasol
## on the far deck, bushes, trees and the changing hut; a summer sky.
func _pool_garden() -> void:
	var d := decor()
	d.sky(Color("5fa8ea"), Color("d8eefc"), Color("8cc56a"))
	d.ground_around("Lawn", Rect2(-5, -8, 10, 11), 56.0, -0.08, Color("8cc56a"))   # round the deck: the pool stays open
	d.fence("Fence", Vector3(-5.05, 0, -8.05), Vector3(5.05, 0, -8.05), Color("cfe0ee"), 1.0)
	d.fence("Fence", Vector3(-5.05, 0, -8.05), Vector3(-5.05, 0, 3.0), Color("cfe0ee"), 1.0)
	d.fence("Fence", Vector3(5.05, 0, -8.05), Vector3(5.05, 0, 3.0), Color("cfe0ee"), 1.0)
	d.box("WalkBoard", Vector3(1.5, 0.36, 0.04), Vector3(-2.2, 1.45, -7.66), Color("fdfdf8"))
	d.box("WalkBoardPost", Vector3(0.06, 1.3, 0.06), Vector3(-2.2, 0.65, -7.72), Color("f6f2ea"))
	for x: float in [-3.6, 3.4]:
		d.box("Lounger", Vector3(1.7, 0.08, 0.6), Vector3(x, 0.3, -7.1), Color("3a7be8") if x < 0 else Color("e8544e"))
		d.box_basis("LoungerBack", Vector3(0.5, 0.06, 0.6), Transform3D(Basis(Vector3.FORWARD, 0.7), Vector3(x - 0.72, 0.48, -7.1)),
			Color("3a7be8") if x < 0 else Color("e8544e"))
		for k: float in [-0.7, 0.7]:
			d.box("LoungerLeg", Vector3(0.05, 0.28, 0.5), Vector3(x + k, 0.14, -7.1), Color("dfe3e8"))
	d.cylinder("ParasolPole", 0.03, 2.1, Vector3(1.4, 1.05, -7.2), Color("f6f2ea"))
	d.cylinder("Parasol", 1.0, 0.45, Vector3(1.4, 2.2, -7.2), Color("ffd23f"), 0.05, 12)
	for at: Vector3 in [Vector3(-6.0, 0, -6.5), Vector3(-6.0, 0, -2.5), Vector3(6.0, 0, -6.0), Vector3(6.0, 0, -1.5), Vector3(-6.0, 0, 1.6)]:
		d.bush("Bush", at, 1.1, Color("5aa548"), Color("e85a9a") if at.x < 0 else Color("ffc93c"))
	d.tree("Tree", Vector3(-8.0, 0, -9.5), 1.2)
	d.tree("Tree", Vector3(8.5, 0, -8.0), 1.0, Color("5aa548"))
	d.tree("Tree", Vector3(-8.5, 0, 2.0), 1.0)
	d.house("ChangingHut", Vector3(8.4, 0, -6.8), Vector3(2.4, 2.3, 2.0), -PI * 0.62, Color("d6e4f6"), Color("3a7be8"), Color("1f6fa8"), 1)
	d.bush("Hedge", Vector3(-2.5, 0, 5.0), 1.6)
	d.bush("Hedge", Vector3(2.5, 0, 5.0), 1.6)


## The beach's dressing: the sand in its picture, palms and parasols on it, towels, a sandcastle, dunes with grass and a
## roof on the lifeguard's hut; never on the way to the water.
func _beach_look(_beach: Node3D) -> void:
	var d := decor()
	d.tiled("Sand", LifeRoomDecor.SAND, Vector3(24, 0.2, 9), Vector3(BEACH_X, -0.1, 3.5), Color("fff3d2"), 1.0)
	for at: Vector3 in [Vector3(29.5, 0, 6.5), Vector3(50.5, 0, 6.0), Vector3(31.5, 0, 7.6)]:
		d.cylinder("PalmTrunk", 0.14, 3.2, at + Vector3(0, 1.6, 0), Color("b98450"), 0.1, 7)
		for k in 5:
			var a := TAU * k / 5.0
			d.box_basis("PalmLeaf", Vector3(1.4, 0.05, 0.35), Transform3D(Basis(Vector3.UP, a) * Basis(Vector3.FORWARD, -0.35),
				at + Vector3(cos(a) * 0.6, 3.15, -sin(a) * 0.6)), Color("4f9a3e"))
	for p: Array in [[Vector3(33.0, 0, 3.4), Color("e8544e")], [Vector3(49.0, 0, 3.0), Color("3a7be8")]]:
		var at: Vector3 = p[0]
		d.cylinder("UmbrellaPole", 0.03, 1.9, at + Vector3(0, 0.95, 0), Color("f6f2ea"))
		d.cylinder("Umbrella", 1.0, 0.4, at + Vector3(0, 2.0, 0), p[1], 0.05, 12)
		d.box("Towel", Vector3(0.7, 0.02, 1.5), at + Vector3(0.6, 0.01, 0.4), Color("ffd23f") if p[1] == Color("e8544e") else Color("e85a9a"))
	for b: Array in [[Vector3(0.5, 0.25, 0.5), Vector3(0, 0.125, 0)], [Vector3(0.18, 0.2, 0.18), Vector3(-0.2, 0.35, -0.2)],
			[Vector3(0.18, 0.2, 0.18), Vector3(0.2, 0.35, 0.2)], [Vector3(0.18, 0.28, 0.18), Vector3(0.2, 0.39, -0.2)]]:
		d.box("Sandcastle", b[0], Vector3(35.0, 0, 1.6) + (b[1] as Vector3), Color("e9cf92"))
	for x in range(29, 52, 3):
		d.ball("Dune", 1.4, Vector3(x + 0.7 * (x % 2), -0.9, 8.6), Color("efdcae"), Vector3(1.6, 1.0, 1.0), LifeRoomDecor.SHELL)
		d.bush("DuneGrass", Vector3(x + 1.2, 0.05, 7.4), 0.7, Color("9cbf5a"))
	d.box_basis("HutRoof", Vector3(2.0, 0.12, 1.8), Transform3D(Basis(Vector3.RIGHT, 0.12), Vector3(BEACH_X - 6, 1.86, 5.0)), Color("fdfdf8"))
	d.glow_box("HutWindow", Vector3(0.7, 0.45, 0.02), Vector3(BEACH_X - 6, 1.2, 4.29), Color("dff0fb"))


## The pond's winter: snowy pines round the banks, a snowman, a little hut, a fence, a pale winter sky.
func _pond_look() -> void:
	var d := decor()
	d.sky(Color("a8c8e8"), Color("eef4fa"), Color("e6edf3"))
	d.ground_around("Snowfield", Rect2(-52, -20, 24, 28), 70.0, -0.02, Color("eef3f8"))   # round the pond and its banks
	var pines := [[Vector3(-50.5, 0, 6.8), 1.2], [Vector3(-47.0, 0, 7.6), 1.0], [Vector3(-31.5, 0, 7.0), 1.1], [Vector3(-29.5, 0, 3.8), 0.9],
			[Vector3(-51.0, 0, 2.5), 0.9], [Vector3(-43.0, 0, 7.8), 0.8]]
	for i in 9:   # the far bank, across the ice
		pines.append([Vector3(-50.0 + i * 2.6 + (0.6 if i % 2 else 0.0), 0, -22.0 - (1.2 if i % 3 == 0 else 0.0)), 1.3 + 0.25 * (i % 3)])
	for p: Array in pines:
		var at: Vector3 = p[0]
		var k: float = p[1]
		d.cylinder("PineTrunk", 0.12 * k, 0.7 * k, at + Vector3(0, 0.35 * k, 0), Color("6b4a32"))
		for t in 3:
			var y := (0.6 + t * 0.55) * k
			d.cylinder("Pine", (0.95 - t * 0.25) * k, 0.8 * k, at + Vector3(0, y + 0.4 * k, 0), Color("2f6b45"), 0.0, 9)
			d.cylinder("PineSnow", (0.55 - t * 0.15) * k, 0.3 * k, at + Vector3(0, y + 0.72 * k, 0), Color("f4f8fc"), 0.0, 9)
	d.ball("Snowman", 0.4, Vector3(-44.5, 0.35, 2.6), Color("fafcff"))
	d.ball("Snowman", 0.28, Vector3(-44.5, 0.92, 2.6), Color("fafcff"))
	d.ball("Snowman", 0.2, Vector3(-44.5, 1.32, 2.6), Color("fafcff"))
	d.cylinder("SnowmanNose", 0.04, 0.16, Vector3(-44.5, 1.32, 2.78), Color("ff7a2e"), 0.0, 6)
	d.box("SnowmanScarf", Vector3(0.5, 0.08, 0.5), Vector3(-44.5, 1.13, 2.6), Color("e8544e"))
	d.house("Hut", Vector3(-30.5, 0, 6.6), Vector3(2.6, 2.3, 2.2), -PI * 0.75, Color("b07a46"), Color("f4f8fc"), Color("6b4a32"), 1)
	d.fence("Fence", Vector3(-52.0, 0, 8.2), Vector3(-34.0, 0, 8.2), Color("8a5a34"), 0.9)
	d.box("IceBoard", Vector3(1.95, 0.42, 0.04), Vector3(POND_X - 3.0, 1.6, 0.16), Color("fdfdf8"))
	d.box("IceBoardEdge", Vector3(2.05, 0.5, 0.03), Vector3(POND_X - 3.0, 1.6, 0.14), Color("e8544e"))


## The pool's, the beach's and the pond's people in few meshes (the Quest's draws): Gus stands up and Mo holds on, so their
## arms and legs keep their own parts; the others never change pose once there. The floats' eight bits in one.
func _people_look() -> void:
	for b: LifeBuddy in [gus, swimmers.get("mo_quiet"), mo_ice]:
		if b != null:
			LifeRoomPeople.merge_person(b)
	for b: LifeBuddy in [bench_buddy, pip_in, swimmers.get("pip_wave"), swimmers.get("bobo_splash"), swimmers.get("kiki_float")]:
		if b != null:
			LifeRoomPeople.merge_person(b, true)
	for ring: Node3D in [ring_post.get_node_or_null("Ring") if ring_post else null, ring_water.get_node_or_null("Ring") if ring_water else null]:
		if ring != null:
			LifeRoomPeople.merge_parts(self, ring)
