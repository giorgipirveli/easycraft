class_name TalkSquare
extends LifeRoom
## Owner #115 (docs/design/success-skills.md §2.4: Talk & Deal): a sunny market square where the child practises talking.
## Little: the child's stall (Mo the customer comes with a cross face, listens, calms and smiles; a fresh loaf and a jar
## of jam to fix it) and Robo's play mat (Robo does EXACTLY what the child says: a muddled instruction makes him do
## something silly but harmless, a clear one puts the right box in the right place). Middle: Ana's apple cart (a deal,
## a handshake, the promised bread in her basket), Robo and his step cards (FORWARD, TURN LEFT, PICK UP), a second
## customer. Big: the meeting tent: three friendly investors at a table (in VR the child stands in front of them), the
## pitch board on a stand (the PROBLEM, IDEA, WHY YOU, WHAT YOU NEED cards), Ms Ade coming round to shake hands, Pip-pop
## with her lemonade pitch. Faces change with what the child says (LifeBuddy.face): never a scary face.

const COBBLE := Color("d8cbb0")
const COUNTER := Color("b07a46")
const STALL_AT := Vector3(0, 0, -0.9)
const FARM_AT := Vector3(3.9, 0, -2.6)
const ROBO_MAT := Vector3(-3.4, 0, -2.4)
const TENT_Z := -6.2
const BOXES := {"box_red": [Vector3(-3.8, 0.12, -2.65), Color("e8544e")], "box_blue": [Vector3(-3.35, 0.12, -2.95),
	Color("3a7be8")], "box_yellow": [Vector3(-2.95, 0.12, -2.75), Color("ffc93c")]}
const BASKET_AT := Vector3(-3.95, 0.14, -1.85)
const TABLE_TOP := Vector3(-2.65, 0.62, -3.0)
## Robo's muddle (a box on his head) lasts this long, then he is himself again.
const MUDDLE_SECONDS := 1.5

var mo: LifeBuddy
var pip: LifeBuddy
var customer: LifeBuddy
var ana: LifeBuddy
var robo: LifeBuddy
var investors := {}
var goods := {}
var boxes := {}
var robo_home := Vector3.ZERO
var crate: MeshInstance3D
var basket_bread: MeshInstance3D


func build() -> void:
	name = "TalkSquare"
	env = LifeRoomKit.environment(Color("7fbfef"), Color("f4f0e0"), 0.72)
	start_view = "tent" if track == "big" else ("farm" if track == "middle" else "stall")
	_square()   # the rooms' look (2026-10-17): the market square round the stalls
	LifeRoomKit.light(self, Vector3(0, 4, -2), 0.6, 14.0)
	_stall()
	if track != "big":
		_robo()
	if track == "middle":
		_farm()
	if track == "big":
		_tent()
	_people_look()
	add_view("stall", Vector3(0, 1.45, 0.85), Vector3(0, 0.9, -1.0), Vector3(0, 0, 0), 0.0)
	add_view("farm", Vector3(2.55, 1.5, -0.3), Vector3(3.45, 0.9, -2.2), Vector3(2.9, 0, -1.2), atan2(-0.4, 1.0))
	add_view("robo", Vector3(-2.0, 1.7, 0.1), Vector3(-3.25, 0.45, -2.4), Vector3(-2.4, 0, -0.9), atan2(1.0, 1.5))
	add_view("tent", Vector3(0, 1.55, -3.0), Vector3(0.15, 1.0, -6.0), Vector3(0, 0, -4.2), 0.0)


func _stall() -> void:
	var sc := scenery()
	decor().tiled("Counter", LifeRoomDecor.PLANKS, Vector3(2.2, 0.9, 0.7), STALL_AT + Vector3(0, 0.45, 0), Color("f6dcb4"), 0.9, 0.0,
		LifeRoomDecor.BAKED)   # a wooden counter (where the plain box stood)
	for i in 6:
		LifeRoomKit.box(sc, "Awning", Vector3(0.38, 0.06, 1.1), STALL_AT + Vector3(-0.95 + i * 0.38, 2.15, 0),
			Color("e8544e") if i % 2 == 0 else Color("fdfdf8"))
	for x: float in [-1.05, 1.05]:
		LifeRoomKit.box(sc, "Pole", Vector3(0.06, 2.15, 0.06), STALL_AT + Vector3(x, 1.07, -0.3), Color("6b4a2a"))
	# on top of the awning (the first view looks down at the counter: a sign in front of it was cut by the frame's top)
	LifeRoomKit.sign(self, "StallSign", "MY STALL", STALL_AT + Vector3(0, 2.42, 0.5), 0.0042)
	for g: Array in [["bread", Vector3(0.55, 0.97, -0.82), Vector3(0.24, 0.13, 0.14), Color("d99a4e")],
			["jam", Vector3(0.85, 0.98, -0.75), Vector3(0.09, 0.14, 0.09), Color("b0303f")],
			["cake", Vector3(-0.55, 0.97, -0.8), Vector3(0.22, 0.1, 0.22), Color("f3d2a8")]]:
		var m := LifeRoomKit.box(self, str(g[0]), g[2], g[1], g[3])
		goods[g[0]] = m
		add_target(str(g[0]), m, 0.16)
	mo = SuccessCast.person("mo", Vector3(0, 0, -1.85))
	mo.visible = false
	add_child(mo)
	add_target("mo", mo.hips, 0.35)
	customer = LifeBuddy.new(Color("8b6fd6"), "Customer")
	customer.position = Vector3(0.6, 0, -1.9)
	customer.visible = false
	add_child(customer)
	pip = LifeBuddy.new(Color("ffd23f"), "PipPop")
	pip.position = Vector3(-1.4, 0, -1.6)
	pip.rotation.y = 0.5
	pip.visible = false
	add_child(pip)
	LifeRoomKit.sign(pip, "Name", "PIP-POP", Vector3(0, 1.3, 0), SuccessCast.SIGN_PIXEL)
	LifeRoomKit.sphere(pip, "Ball", 0.12, Vector3(0.3, 0.12, 0.2), Color("e8544e"))


func _robo() -> void:
	var sc := scenery()
	LifeRoomKit.box(sc, "Mat", Vector3(2.0, 0.02, 1.8), ROBO_MAT + Vector3(0, 0.01, 0), Color("b9a6e8"))
	for id: String in BOXES:
		var m := LifeRoomKit.box(self, id, Vector3(0.24, 0.24, 0.24), BOXES[id][0], BOXES[id][1])
		boxes[id] = m
		add_target(id, m, 0.18)
	LifeRoomKit.cylinder(sc, "Basket", 0.22, 0.24, BASKET_AT, Color("c9a063"))
	add_spot_target("basket", self, BASKET_AT + Vector3(0, 0.14, 0), 0.24)
	LifeRoomKit.box(sc, "LowTable", Vector3(0.6, 0.6, 0.5), TABLE_TOP - Vector3(0, 0.31, 0), Color("a8642a"))
	robo_home = Vector3(-3.0, 0, -1.95)
	robo = SuccessCast.robo(robo_home, atan2(0.6, 1.0))
	(robo.get_node("Name") as Node3D).position.y = 1.46   # over his antenna's ball
	add_child(robo)
	add_target("robo", robo.hips, 0.35)
	if track == "middle":
		crate = LifeRoomKit.box(self, "BlueCrate", Vector3(0.4, 0.22, 0.3), TABLE_TOP + Vector3(0.0, -0.5, 0.0), Color("3a7be8"))
		LifeRoomKit.box(sc, "Stand", Vector3(0.9, 0.9, 0.3), Vector3(-2.35, 0.45, -1.6), Color("a8642a"))
		for c: Array in [["card_pick", "PICK UP", -2.65], ["card_forward", "FORWARD", -2.35], ["card_left", "TURN LEFT", -2.05]]:
			var card := LifeRoomKit.box(self, str(c[0]), Vector3(0.26, 0.16, 0.03), Vector3(float(c[2]), 1.02, -1.45), Color("fdf6e3"))
			card.rotation.x = -0.5
			var l := LifeRoomKit.sign(card, "Words", LifeRoomLook.two_lines(str(c[1])), Vector3(0, 0, 0.017), 0.0012, Color("1f2a4a"))
			l.outline_size = 0
			l.billboard = BaseMaterial3D.BILLBOARD_DISABLED   # painted on the card (a billboard's words ran over its edges)
			add_target(str(c[0]), card, 0.14)


func _farm() -> void:
	var sc := scenery()
	LifeRoomKit.box(sc, "Cart", Vector3(1.2, 0.5, 0.8), FARM_AT + Vector3(0, 0.55, 0), Color("a8642a"))
	for x: float in [-0.5, 0.5]:
		var w := LifeRoomKit.cylinder(sc, "Wheel", 0.28, 0.06, FARM_AT + Vector3(x, 0.28, 0.42), Color("6b4a2a"))
		w.rotation.x = PI / 2
	for i in 8:
		LifeRoomKit.sphere(sc, "Apple", 0.07, FARM_AT + Vector3(-0.4 + (i % 4) * 0.27, 0.86, -0.15 + (i / 4) * 0.3),
			Color("e8544e"))
	# a chalkboard on an easel beside the cart (over the cart it stood on Ana's own name tag)
	var easel := FARM_AT + Vector3(0.95, 0, 0.7)
	var facing := atan2(2.55 - easel.x, -0.3 - easel.z)
	var d := decor()
	d.box("Easel", Vector3(0.06, 1.3, 0.06), easel + Vector3(0, 0.65, -0.12), Color("8a5a34"), facing)
	d.box_basis("Chalkboard", Vector3(0.78, 0.5, 0.04), Transform3D(Basis(Vector3.UP, facing) * Basis(Vector3.RIGHT, -0.12),
		easel + Vector3(0, 1.0, 0)), Color("2f3f38"))
	var farm_sign := LifeRoomKit.sign(self, "FarmSign", "ANA'S\nAPPLES", easel + Vector3(0, 1.0, 0) + Basis(Vector3.UP, facing) * Vector3(0, 0, 0.035),
		0.0021, Color("fff6d8"))
	farm_sign.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	farm_sign.outline_size = 0
	farm_sign.rotation = Vector3(-0.12, facing, 0)
	ana = SuccessCast.person("ana", Vector3(3.3, 0, -2.2), atan2(-0.4, 1.0))
	add_child(ana)
	add_target("ana", ana.hips, 0.35)
	add_spot_target("ana_hand", self, Vector3(3.15, 0.8, -1.82), 0.16)
	var basket := LifeRoomKit.cylinder(self, "AnaBasket", 0.18, 0.2, Vector3(3.75, 0.1, -1.95), Color("c9a063"))
	add_target("ana_basket", basket, 0.24)
	basket_bread = LifeRoomKit.box(basket, "Bread", Vector3(0.2, 0.1, 0.12), Vector3(0, 0.14, 0), Color("d99a4e"))
	basket_bread.visible = false


func _tent() -> void:
	var sc := scenery()
	for x: float in [-2.0, 2.0]:
		LifeRoomKit.box(sc, "TentPole", Vector3(0.08, 2.6, 0.08), Vector3(x, 1.3, TENT_Z + 0.6), Color("6b4a2a"))
	for i in 8:
		LifeRoomKit.box(sc, "TentRoof", Vector3(0.52, 0.06, 2.0), Vector3(-1.82 + i * 0.52, 2.62, TENT_Z - 0.2),
			Color("2f7f6a") if i % 2 == 0 else Color("fdfdf8"))
	LifeRoomKit.sign(self, "TentSign", "MEETING TENT", Vector3(0, 2.35, TENT_Z + 0.62), 0.0045)
	LifeRoomKit.box(sc, "Table", Vector3(2.6, 0.75, 0.8), Vector3(0, 0.375, TENT_Z), Color("f3e1c0"))
	var ids := ["diaz", "ade", "kowalski"]
	for i in 3:
		var at := Vector3(-0.9 + i * 0.9, 0, TENT_Z - 0.6)
		LifeRoomKit.box(sc, "Chair", Vector3(0.44, 0.44, 0.44), at + Vector3(0, 0.22, -0.05), Color("6b7a99"))
		var b := SuccessCast.person(ids[i], at)
		b.pose("sit")
		add_child(b)
		investors[ids[i]] = b
		add_target(ids[i], b.head, 0.3)
		# their names a little smaller and over their heads in turn: side by side at a table they ran into each other
		var tag := b.get_node("Name") as Label3D
		tag.pixel_size = 0.0024
		tag.position.y = 1.56   # a row of names over the table, clear of the pitch board in front
	var stand := Node3D.new()
	stand.name = "PitchBoard"
	stand.position = Vector3(1.25, 0, -5.0)
	stand.rotation.y = -0.45
	sc.add_child(stand)
	LifeRoomKit.box(stand, "Leg", Vector3(0.06, 0.9, 0.06), Vector3(0, 0.45, 0), Color("3b3f4a"))
	LifeRoomKit.box(stand, "Screen", Vector3(0.9, 0.62, 0.04), Vector3(0, 1.2, 0), Color("1f2a4a"))
	LifeRoomKit.sign(stand, "Title", "MY PITCH", Vector3(0, 1.58, 0.03), 0.0028)
	for c: Array in [["card_need", "WHAT I NEED", Vector2(-0.21, 1.33)], ["card_problem", "THE PROBLEM", Vector2(0.21, 1.33)],
			["card_why", "WHY ME", Vector2(-0.21, 1.07)], ["card_idea", "MY IDEA", Vector2(0.21, 1.07)]]:
		var at: Vector2 = c[2]
		var card := LifeRoomKit.box(stand, str(c[0]), Vector3(0.38, 0.2, 0.02), Vector3(at.x, at.y, 0.03), Color("fdf6e3"))
		var l := LifeRoomKit.sign(card, "Words", LifeRoomLook.two_lines(str(c[1])), Vector3(0, 0, 0.012), 0.0013, Color("1f2a4a"))
		l.outline_size = 0
		l.billboard = BaseMaterial3D.BILLBOARD_DISABLED   # painted on the card (a billboard's words ran over its edges)
		add_target(str(c[0]), card, 0.14)
	add_spot_target("ade_hand", self, Vector3(0.2, 0.8, -4.78), 0.16)


func on_event(event: String) -> void:
	match event:
		"mo_comes":
			mo.visible = true
			LifeRoomPeople.feel(mo, "cross")
		"mo_talks":
			LifeRoomPeople.feel(mo, "worried")
		"mo_calm":
			LifeRoomPeople.feel(mo, "calm")
		"mo_happy":
			LifeRoomPeople.feel(mo, "happy")
			mo.nod()
		"give_bread":
			_give(goods.get("bread"), mo)
		"give_jam":
			_give(goods.get("jam"), mo)
		"pip_ball":
			pip.visible = true
			LifeRoomPeople.feel(pip, "happy")
		"pip_pitch":
			pip.visible = true
			pip.position = Vector3(-1.3, 0, -5.0)
			pip.rotation.y = 0.6
			LifeRoomPeople.feel(pip, "happy")
		"customer_comes":
			customer.visible = true
			LifeRoomPeople.feel(customer, "worried")
		"robo_wakes":
			robo.nod()
		"robo_muddle":
			_robo_muddle()
		"robo_red":
			_robo_carry("box_red", BASKET_AT + Vector3(0, 0.2, 0))
		"robo_blue":
			_robo_carry("box_blue", TABLE_TOP + Vector3(0, 0.12, 0))
		"robo_stack":
			_robo_carry("box_red", BASKET_AT + Vector3(0, 0.2, 0))
			_robo_carry("box_yellow", BASKET_AT + Vector3(0, 0.44, 0))
		"robo_apples":
			_robo_walk(TABLE_TOP + Vector3(0.3, -0.62, 0.35))
		"ana_comes":
			if ana:
				LifeRoomPeople.feel(ana, "happy")
				ana.nod()
		"handshake":
			for b: LifeBuddy in [ana, investors.get("ade")]:
				if b and b.is_inside_tree():
					b.nod()
		"bread_delivered":
			if basket_bread:
				basket_bread.visible = true
			if ana:
				LifeRoomPeople.feel(ana, "happy")
		"investors_in":
			for id: String in investors:
				LifeRoomPeople.feel(investors[id] as LifeBuddy, "calm")
		"ade_comes":
			var ade := investors.get("ade") as LifeBuddy
			if ade:
				ade.pose("stand")
				ade.position = Vector3(0.35, 0, -5.05)
				LifeRoomPeople.feel(ade, "happy")


func step_done(step: Dictionary) -> void:
	match str(step.get("id", "")):
		"problem", "idea", "why_you", "need", "rain", "numbers":
			if investors.has("diaz"):
				(investors.diaz as LifeBuddy).nod()
		"walk_away":
			if investors.has("kowalski"):
				LifeRoomPeople.feel(investors.kowalski as LifeBuddy, "calm")
		"feedback_in":
			if investors.has("ade"):
				LifeRoomPeople.feel(investors.ade as LifeBuddy, "happy")


func progress(step: Dictionary, state: Dictionary) -> void:
	if str(step.get("kind", "")) == "sequence" and str(step.get("id", "")) == "robo_steps":
		var i := int(state.get("i", 0))
		if i >= 1:
			_robo_walk(robo_home + Vector3(-0.4, 0, -0.5))
		if i >= 2:
			robo.rotation.y = atan2(0.6, 1.0) + PI / 2
		if i >= 3:
			_robo_carry("box_yellow", robo.position + Vector3(0, 0.75, 0.2))


func _give(item: Variant, to: LifeBuddy) -> void:
	if not item is Node3D or to == null:
		return
	var m := item as Node3D
	var at := to.position + Vector3(0.2, 0.8, 0.25)
	if UiMotion.calm() or not is_inside_tree():
		m.position = at
	else:
		create_tween().set_trans(Tween.TRANS_SINE).tween_property(m, "position", at, 0.5)
	LifeRoomPeople.feel(to, "happy")


func _robo_walk(to: Vector3) -> void:
	if robo == null:
		return
	if UiMotion.calm() or not is_inside_tree():
		robo.position = to
		return
	create_tween().set_trans(Tween.TRANS_SINE).tween_property(robo, "position", to, 0.6)


func _robo_carry(box_id: String, to: Vector3) -> void:
	var m := boxes.get(box_id) as Node3D
	if m == null:
		return
	_robo_walk(Vector3(to.x + 0.3, 0, to.z + 0.3))
	if UiMotion.calm() or not is_inside_tree():
		m.position = to
		return
	var tw := create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_interval(0.5)
	tw.tween_property(m, "position", to, 0.5)
	robo.nod()


## Robo does exactly what a muddled instruction said: a spin and a box on his head for a moment, then back. Harmless.
func _robo_muddle() -> void:
	if robo == null:
		return
	LifeRoomPeople.feel(robo, "worried")
	var hat := LifeRoomKit.box(robo.head, "MuddleBox", Vector3(0.2, 0.2, 0.2), Vector3(0, 0.45, 0), Color("ffc93c"))
	if not is_inside_tree():
		hat.free()
		LifeRoomPeople.feel(robo, "calm")
		return
	if not UiMotion.calm():   # Reduce motion: no spin, the box on his head is enough
		create_tween().tween_property(robo, "rotation:y", robo.rotation.y + TAU, 0.9)
	get_tree().create_timer(MUDDLE_SECONDS).timeout.connect(func() -> void:
		if is_instance_valid(hat):
			hat.queue_free()
		if is_instance_valid(robo):
			LifeRoomPeople.feel(robo, "calm"))


# --- The rooms' look (2026-10-17, docs/devlog/parts/rooms-look.md): a sunny market square --------------------------------

## Cobbles under the stalls, little houses round the square with their doors and windows, flags across it, street
## lamps, planters and trees: all one dressing (LifeRoomDecor), never near the stalls, the mat, the tent or a view's line.
func _square() -> void:
	var d := decor()
	d.sky(Color("6fb2ec"), Color("dcefff"), Color("8cc56a"))
	d.box("Grass", Vector3(70, 0.1, 70), Vector3(0, -0.13, -3.0), Color("8cc56a"), 0.0, LifeRoomDecor.SHELL)
	d.tiled("Square", LifeRoomDecor.SLABS, Vector3(20, 0.1, 18), Vector3(0, -0.05, -3.0), Color("f4e6cc"), 1.25)
	var fronts := [Color("f3e1c0"), Color("f6c9b4"), Color("cfe9d6"), Color("d6e4f6"), Color("f6e7a8"), Color("e8d6f2")]
	var roofs := [Color("c8553d"), Color("b5583f"), Color("8f5a4a")]
	var i := 0
	for x: float in [-7.4, -2.6, 2.6, 7.4]:
		d.house("House", Vector3(x, 0, -10.7), Vector3(4.2, 2.8 + 0.5 * (i % 2), 2.6), 0.0, fronts[i % 6], roofs[i % 3])
		i += 1
	for z: float in [-6.6, -1.6, 3.4]:
		d.house("House", Vector3(-10.7, 0, z), Vector3(4.2, 3.0 + 0.4 * (i % 2), 2.6), PI / 2, fronts[i % 6], roofs[i % 3])
		i += 1
		d.house("House", Vector3(10.7, 0, z), Vector3(4.2, 3.0 + 0.4 * (i % 2), 2.6), -PI / 2, fronts[i % 6], roofs[i % 3])
		i += 1
	d.bunting("Flags", Vector3(-9.3, 3.3, -8.6), Vector3(9.3, 3.3, -8.6), 0.5)
	d.bunting("Flags", Vector3(-9.3, 3.2, -3.9), Vector3(9.3, 3.2, -3.9), 0.45)
	for at: Vector3 in [Vector3(-6.0, 0, 1.2), Vector3(6.0, 0, 1.2), Vector3(-6.0, 0, -7.9), Vector3(6.0, 0, -7.9)]:
		d.street_lamp("Lamp", at)
	d.planter("Planter", Vector3(-2.3, 0, 2.2), Vector2(1.0, 0.5), Color("e85a9a"))
	d.planter("Planter", Vector3(2.3, 0, 2.2), Vector2(1.0, 0.5), Color("ffc93c"))
	d.planter("Planter", Vector3(-8.6, 0, -9.0), Vector2(0.9, 0.5), Color("b03cc0"))
	d.planter("Planter", Vector3(8.6, 0, -9.0), Vector2(0.9, 0.5), Color("f39a3c"))
	d.bench("Bench", Vector3(-8.7, 0, -4.2), PI / 2)
	d.bench("Bench", Vector3(8.7, 0, -4.2), -PI / 2)
	d.tree("Tree", Vector3(-7.8, 0, 5.2), 1.1)
	d.tree("Tree", Vector3(7.8, 0, 5.2), 1.0)
	d.tree("Tree", Vector3(0.6, 0, 6.6), 1.2, Color("5a9e45"))


## The square's people drawn in few meshes (the Quest's draws): the stall's and the farm's people never change pose; the
## investors sit and Ms Ade stands up, so their arms and legs keep their own parts.
func _people_look() -> void:
	for b: LifeBuddy in [mo, customer, pip, ana, robo]:
		if b != null:
			LifeRoomPeople.merge_person(b, true)
	for id: String in investors:
		LifeRoomPeople.merge_person(investors[id] as LifeBuddy)
