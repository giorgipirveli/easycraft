class_name VillageSquare
extends LifeRoom
## Owner #115 (docs/design/success-skills.md §2.3: the Connections Book): the practice village's square. Round it, each
## person at their place (SuccessPeople's data, dressed by SuccessCast, their name over their head): Amara's bakery,
## Tomas's mill with its flour sacks, Ana's farm stall, Ivan's tool shop, Mr Okafor's library, Omar's clock shop (with a
## ramp: Omar uses a wheelchair), Sam's workshop, Grandpa Kenji's beehives, Rosa's pottery, Gemma's rock table, Mei's
## workshop from the Launch Site, and the fountain with Lina on the bench beside it. People wave when met, look worried
## when they need something and happy when helped; an introduction makes two people turn to each other and nod; the
## night falls softly for a promise kept the next morning. Nothing a child does here is kept but the book's own record.

const COBBLE := Color("dccfb6")
## id -> [where they stand, the colour of their place]
const PLACES := {
	"amara": [Vector3(-2.4, 0, -3.0), Color("f3e1c0")], "tomas": [Vector3(-4.0, 0, -1.4), Color("e6d3a8")],
	"ana": [Vector3(2.4, 0, -3.0), Color("cfe9b0")], "ivan": [Vector3(4.0, 0, -1.4), Color("c9ced6")],
	"okafor": [Vector3(-1.4, 0, -4.8), Color("d9cff2")], "omar": [Vector3(1.4, 0, -4.8), Color("f2d0c4")],
	"sam": [Vector3(3.1, 0, -4.6), Color("e8d0b0")], "kenji": [Vector3(-2.4, 0, -6.0), Color("f6e7a8")],
	"rosa": [Vector3(-1.2, 0, -6.6), Color("f6c2d6")], "gemma": [Vector3(1.2, 0, -6.6), Color("bfe3e0")],
	"mei": [Vector3(0.0, 0, -7.1), Color("c8dcf6")]}
const SHOP_SIGNS := {"amara": "BAKERY", "tomas": "MILL", "ana": "FARM STALL", "ivan": "TOOLS", "okafor": "LIBRARY",
	"omar": "CLOCKS", "sam": "WORKSHOP", "kenji": "HONEY", "rosa": "POTTERY", "gemma": "ROCKS", "mei": "LAUNCH SITE WORKSHOP"}
## The far shops whose names stand higher over their roofs (neighbours across the square alternate).
const SIGN_HIGH: Array[String] = ["kenji", "rosa", "gemma", "sam"]
const LINA_AT := Vector3(0.0, 0, -2.25)
const FOUNTAIN_AT := Vector3(0, 0, -3.5)
const FLOUR_AT := Vector3(-3.55, 0.22, -1.0)
const GIFT_AT := Vector3(0.7, 0.62, -1.75)

var people := {}
var lina: LifeBuddy
var flour: MeshInstance3D
var gift: MeshInstance3D
var night_light: OmniLight3D
var _day_env: Environment


func build() -> void:
	name = "VillageSquare"
	env = LifeRoomKit.environment(Color("8ec5f0"), Color("f4f0e0"), 0.72)
	_day_env = env
	start_view = "square"
	_village()   # the rooms' look (2026-10-17): the square, the houses round it, trees, lamps, flowers
	night_light = LifeRoomKit.light(self, Vector3(0, 4, -3), 0.6, 14.0)
	# on the arch over the lane into the village, behind the child (over the fountain it covered the far shops' names)
	LifeRoomKit.sign(self, "VillageSign", "THE VILLAGE", Vector3(0, 3.05, 4.3), 0.005, Color("2f7f6a"))
	_fountain()
	for id: String in PLACES:
		_place(id)
	_extras()
	_people_look()
	add_view("square", Vector3(0, 2.4, 2.6), Vector3(0, 0.7, -3.2), Vector3(0, 0, 0), 0.0)
	add_view("bakery", Vector3(-1.2, 1.5, -0.8), Vector3(-2.4, 0.9, -3.0), Vector3(-1.6, 0, -1.8), atan2(0.8, 1.2))
	add_view("mill", Vector3(-2.6, 1.5, -0.2), Vector3(-3.9, 0.6, -1.25), Vector3(-3.0, 0, -0.75), atan2(1.0, 0.6))
	add_view("farm", Vector3(1.2, 1.5, -0.8), Vector3(2.4, 0.9, -3.0), Vector3(1.6, 0, -1.8), atan2(-0.8, 1.2))
	add_view("bench", Vector3(0.65, 1.4, -0.55), Vector3(0.05, 0.62, -2.3), Vector3(0.35, 0, -1.25), atan2(0.3, 1.0))
	add_view("clocks", Vector3(0.6, 1.5, -2.6), Vector3(1.4, 0.7, -4.8), Vector3(0.85, 0, -3.4), atan2(-0.55, 1.4))
	add_view("workshop", Vector3(2.3, 1.5, -2.6), Vector3(3.1, 0.9, -4.6), Vector3(2.6, 0, -3.4), atan2(-0.5, 1.2))
	add_view("far", Vector3(0, 2.0, -3.0), Vector3(0, 0.8, -6.6), Vector3(0, 0, -4.3), 0.0)


func _fountain() -> void:
	var sc := scenery()
	LifeRoomKit.cylinder(sc, "Fountain", 0.6, 0.5, FOUNTAIN_AT + Vector3(0, 0.25, 0), Color("c9ced6"))
	LifeRoomKit.cylinder(self, "Water", 0.52, 0.04, FOUNTAIN_AT + Vector3(0, 0.5, 0), Color(0.55, 0.8, 1.0, 0.8))
	LifeRoomKit.cylinder(sc, "Spout", 0.08, 0.5, FOUNTAIN_AT + Vector3(0, 0.75, 0), Color("c9ced6"))
	LifeRoomKit.box(sc, "Bench", Vector3(1.0, 0.45, 0.4), LINA_AT + Vector3(0, 0.225, -0.15), Color("a8642a"))
	lina = SuccessCast.person("lina", LINA_AT)
	lina.pose("sit")
	add_child(lina)
	people.lina = lina
	add_target("lina", lina.head, 0.3)


func _place(id: String) -> void:
	var at: Vector3 = PLACES[id][0]
	var towards := Vector3(0, 0, 0) - at
	var yaw := atan2(towards.x, towards.z)
	var back := at - towards.normalized() * 0.9
	var sc := scenery()
	var shop := LifeRoomKit.box(sc, "Shop_" + id, Vector3(1.3, 2.0, 0.5), back + Vector3(0, 1.0, 0), PLACES[id][1], yaw)
	# the shop's name over its roof (an awning covers the board's front); the far shops' names a little smaller and high
	# and low in turn, so they never run together seen from across the square
	var far := at.length() > 4.5
	LifeRoomKit.sign(shop, "Sign", str(SHOP_SIGNS[id]), Vector3(0, (1.78 if SIGN_HIGH.has(id) else 1.36) if far else 1.45, 0.1),
		0.0028 if far else 0.0034, Color("1f2a4a"))
	_shop_front(back, yaw, PLACES[id][1])
	LifeRoomKit.box(sc, "Counter_" + id, Vector3(1.0, 0.7, 0.4), at - towards.normalized() * 0.35 + Vector3(0, 0.35, 0),
		Color("b07a46"), yaw)
	var b := SuccessCast.person(id, at, yaw)
	add_child(b)
	people[id] = b
	add_target(id, b.head if id != "omar" else b.hips, 0.32)


func _extras() -> void:
	flour = LifeRoomKit.box(self, "Flour", Vector3(0.34, 0.44, 0.26), FLOUR_AT, Color("f6f2ea"))
	LifeRoomKit.sign(flour, "Label", "FLOUR", Vector3(0, 0.05, 0.14), 0.0022, Color("1f2a4a"))
	add_target("flour", flour, 0.22)
	var sc := scenery()
	LifeRoomKit.box(sc, "GiftTable", Vector3(0.5, 0.6, 0.4), GIFT_AT - Vector3(0, 0.31, 0), Color("a8642a"))
	gift = LifeRoomKit.box(self, "Gift", Vector3(0.22, 0.05, 0.14), GIFT_AT + Vector3(0, 0.03, 0), Color("e85a9a"))
	add_target("gift", gift, 0.16)
	var ramp := LifeRoomKit.box(sc, "Ramp", Vector3(0.6, 0.06, 0.9), (PLACES.omar[0] as Vector3) + Vector3(0.7, 0.1, -0.2),
		Color("9aa7b5"))
	ramp.rotation.x = 0.18
	for i in 3:
		LifeRoomKit.box(sc, "Hive", Vector3(0.3, 0.36, 0.3), (PLACES.kenji[0] as Vector3) + Vector3(-0.7 + i * 0.4, 0.18, -0.6),
			Color("ffc93c"))


func person_node(id: String) -> LifeBuddy:
	return people.get(id) as LifeBuddy


func on_event(event: String) -> void:
	match event:
		"amara_wave":
			_happy("amara")
		"tomas_wave":
			_happy("tomas")
		"ana_wave", "ana_calls":
			_happy("ana")
		"amara_worried":
			_mood("amara", "worried")
		"carry_flour":
			_carry(flour, Vector3(-1.75, 0.75, -2.05))
		"flour_given":
			_carry(flour, (PLACES.amara[0] as Vector3) + Vector3(0.4, 0.8, 0.4))
			_happy("amara")
		"lina_alone":
			_mood("lina", "sad")
		"lina_happy":
			_happy("lina")
		"carry_gift":
			_carry(gift, LINA_AT + Vector3(0.45, 0.75, 0.45))
		"gift_given":
			_carry(gift, LINA_AT + Vector3(0.25, 0.55, 0.25))
			_happy("lina")
		"night":
			env = LifeRoomKit.environment(Color("2a3a66"), Color("4a5a86"), 0.4)
			LifeRoomDecor.tone(env)
			nightfall(true)
			_set_env()
		"morning", "noon":
			env = _day_env
			nightfall(false)
			_set_env()
		"ana_ivan":
			_introduce("ana", "ivan")
		"amara_tomas":
			_introduce("amara", "tomas")
		"okafor_sam":
			_introduce("okafor", "sam")
		"mei_ana":
			_introduce("mei", "ana")
		"rosa_chain":
			_introduce("rosa", "gemma")
			_introduce("rosa", "kenji")
		"omar_works":
			_mood("omar", "calm")
		"omar_nods", "sam_waves", "chance":
			_happy({"omar_nods": "omar", "sam_waves": "sam", "chance": "amara"}[event])


## The room's sky changed (the night, the next morning): every camera drawing the room follows.
func _set_env() -> void:
	var host := get_parent()
	if host is LifeRoomHost and (host as LifeRoomHost).camera:
		(host as LifeRoomHost).camera.environment = env


func progress(step: Dictionary, state: Dictionary) -> void:
	if str(step.get("kind", "")) == "find":
		for t: Variant in state.get("found", []):
			_happy(str(t))


func _happy(id: String) -> void:
	var b := person_node(id)
	if b:
		LifeRoomPeople.feel(b, "happy")
		if b.is_inside_tree():
			b.nod()


func _mood(id: String, feeling: String) -> void:
	var b := person_node(id)
	if b:
		LifeRoomPeople.feel(b, feeling)


## Two people turn a little to each other and nod: they've been introduced.
func _introduce(a: String, b: String) -> void:
	var pa := person_node(a)
	var pb := person_node(b)
	if pa == null or pb == null:
		return
	for pair: Array in [[pa, pb], [pb, pa]]:
		var me := pair[0] as LifeBuddy
		var other := pair[1] as LifeBuddy
		var d := other.position - me.position
		var face_other := atan2(d.x, d.z)
		var face_child := atan2(-me.position.x, -me.position.z)
		me.rotation.y = lerp_angle(face_child, face_other, 0.5)
		LifeRoomPeople.feel(me, "happy")
		if me.is_inside_tree():
			me.nod()


func _carry(n: Node3D, to: Vector3) -> void:
	if n == null:
		return
	if UiMotion.calm() or not is_inside_tree():
		n.position = to
		return
	create_tween().set_trans(Tween.TRANS_SINE).tween_property(n, "position", to, 0.5)


# --- The rooms' look (2026-10-17, docs/devlog/parts/rooms-look.md): a village square ------------------------------------

## Paving slabs round the fountain, cottages behind the shops, trees, street lamps and flower tubs, flags over the
## square: all one dressing (LifeRoomDecor), out of everyone's way.
func _village() -> void:
	var d := decor()
	d.sky(Color("6fb2ec"), Color("dcefff"), Color("8cc56a"))
	d.box("Grass", Vector3(70, 0.1, 70), Vector3(0, -0.13, -3.2), Color("8cc56a"), 0.0, LifeRoomDecor.SHELL)
	d.tiled("Square", LifeRoomDecor.SLABS, Vector3(14, 0.1, 13), Vector3(0, -0.05, -3.2), Color("eadcc0"), 1.25)
	d.cylinder("FountainStep", 1.05, 0.06, FOUNTAIN_AT + Vector3(0, 0.03, 0), Color("aab3c0"), -1.0, 18, LifeRoomDecor.SHELL)
	# cottages round the square, behind the shops, their fronts to the fountain
	var fronts := [Color("f3e1c0"), Color("f6c9b4"), Color("cfe9d6"), Color("d6e4f6"), Color("f6e7a8"), Color("e8d6f2")]
	var roofs := [Color("c8553d"), Color("b5583f"), Color("8f5a4a"), Color("6b7a99")]
	var n := 9
	for i in n:
		var a := PI * 0.2 + (PI * 1.6) * i / (n - 1)   # round the far side, open towards the child
		var at := Vector3(sin(a) * 10.5, 0, -3.2 - cos(a) * 9.5)
		var face := atan2(-at.x, -3.2 - at.z)
		d.house("Cottage", at, Vector3(3.6, 2.6 + 0.4 * (i % 2), 2.4), face, fronts[i % 6], roofs[i % 4])
	for i in 7:
		var a := PI * 0.32 + (PI * 1.36) * i / 6.0
		d.tree("Tree", Vector3(sin(a) * 8.3, 0, -3.2 - cos(a) * 8.0), 0.85 + 0.15 * (i % 2),
			Color("4f9a3e") if i % 2 == 0 else Color("5aa548"))
	for at: Vector3 in [Vector3(-5.6, 0, 1.6), Vector3(5.6, 0, 1.6), Vector3(-6.2, 0, -5.6), Vector3(6.2, 0, -5.6)]:
		d.street_lamp("Lamp", at)
	for x: float in [-7.6, -3.4, 3.4, 7.6]:
		d.planter("Tub", Vector3(x, 0, 3.4 if absf(x) < 5.0 else 2.4), Vector2(0.8, 0.45), Color("e85a9a") if x < 0 else Color("ffc93c"))
	d.bunting("Flags", Vector3(-6.2, 3.4, -5.6), Vector3(6.2, 3.4, -5.6), 0.45)
	d.bunting("Flags", Vector3(-5.6, 3.4, 1.6), Vector3(-6.2, 3.4, -5.6), 0.4)
	d.bunting("Flags", Vector3(5.6, 3.4, 1.6), Vector3(6.2, 3.4, -5.6), 0.4)
	# behind the child: a low hedge with a gap, and the lane out of the village
	d.tiled("Lane", LifeRoomDecor.DIRT, Vector3(2.2, 0.1, 9.0), Vector3(0, -0.08, 7.6), Color("e6d2b0"), 1.0)
	for x: float in [-4.85, 4.85]:
		d.tiled("Hedge", LifeRoomDecor.HEDGE, Vector3(6.5, 0.9, 0.7), Vector3(x, 0.45, 4.3), Color.WHITE, 0.9)
	# the arch over the lane (THE VILLAGE on it)
	for x: float in [-1.3, 1.3]:
		d.box("ArchPost", Vector3(0.18, 2.9, 0.18), Vector3(x, 1.45, 4.3), Color("8a5a34"))
	d.box("ArchBeam", Vector3(3.0, 0.22, 0.24), Vector3(0, 2.9, 4.3), Color("8a5a34"))


## A shop's front: a striped awning over its counter in the shop's colours, a little roof on its board, flowers at its
## feet.
func _shop_front(back: Vector3, yaw: float, colour: Color) -> void:
	var d := decor()
	var b := Basis(Vector3.UP, yaw)
	var tilt := b * Basis(Vector3.RIGHT, 0.32)
	for i in 5:
		var x := -0.6 + i * 0.3
		d.box_basis("Awning", Vector3(0.3, 0.04, 0.95), Transform3D(tilt, back + b * Vector3(x, 1.98, 0.6)),
			colour.darkened(0.25) if i % 2 == 0 else Color("fdfdf8"))
	d.box_basis("Roof", Vector3(1.5, 0.12, 0.75), Transform3D(b, back + b * Vector3(0, 2.06, 0.0)), colour.darkened(0.45))
	for side: int in [-1, 1]:
		d.cylinder("Pot", 0.11, 0.2, back + b * Vector3(side * 0.82, 0.1, 0.32), Color("d9774a"), 0.14)
		d.ball("Flowers", 0.15, back + b * Vector3(side * 0.82, 0.3, 0.32), Color("5aa548"))
		d.ball("Bloom", 0.06, back + b * Vector3(side * 0.82 + 0.05, 0.42, 0.36), Color("ffc93c") if side < 0 else Color("e85a9a"))


## The village's people drawn in few meshes (the Quest's draws: twelve of them stand round the square): none changes
## pose here (Lina sits and Omar's chair are set as they come), so each is a head and a body; faces change through feel.
func _people_look() -> void:
	for id: String in people:
		LifeRoomPeople.merge_person(people[id] as LifeBuddy, true)
