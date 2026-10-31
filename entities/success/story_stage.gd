class_name StoryStage
extends LifeRoom
## Owner #115 (docs/design/success-skills.md §2.7: Success Stories): the Story Theatre. A little stage with red curtains
## and a backdrop board naming each scene's place and year; the buddies act true stories of real people, and the child
## helps: Louis Braille's six dots, Wangari Maathai's tree holes, the Wright brothers' glider (it comes down, the wing
## shapes in the wind tunnel, the first flight across the stage), George Washington Carver's two fields, Florence
## Nightingale's ward (the window, the basin, the sheets), Alexander Fleming's dish, Henry Dunant's town helpers,
## Katherine Johnson's orbit board, Yuan Longping's rice field (one special plant), Mary Seacole's hotel and Savitribai
## Phule's school. Each scene's props show only for its scene; the buddies are actors, never portraits of the people.
## Calm: no battle, no injury shown (Dunant's soldiers sit and rest; helpers bring water).

const STAGE_Z := -3.7
const STAGE_TOP := 0.5
const SCENE_WORDS := {"scene_braille": "PARIS, 1824", "scene_trees": "KENYA, 1977", "scene_wright": "OHIO AND KITTY HAWK, USA, 1900-1903",
	"scene_carver": "ALABAMA, USA, ABOUT 1900", "scene_ward": "A WAR HOSPITAL, 1854", "scene_fleming": "LONDON, 1928",
	"scene_dunant": "SOLFERINO, ITALY, 1859", "scene_johnson": "NASA, USA, 1962", "scene_rice": "CHINA, THE 1960s",
	"scene_seacole": "THE CRIMEA, 1855", "scene_school": "PUNE, INDIA, 1848"}

var backdrop: Label3D
var scenes := {}
var curtains: Array[MeshInstance3D] = []
var glider: Node3D
var plane: Node3D
var seedlings := {}
var helpers := {}


func build() -> void:
	name = "StoryStage"
	env = LifeRoomKit.environment(Color("2a2f4a"), Color("3a3f5a"), 0.65)
	start_view = "stage"
	_theatre_look()   # the rooms' look (2026-10-18): the hall round the stage
	var sc := scenery()
	LifeRoomKit.box(sc, "Backdrop", Vector3(6.4, 3.2, 0.1), Vector3(0, 1.6 + STAGE_TOP, STAGE_Z - 1.7), Color("3a5aa8"))
	backdrop = LifeRoomKit.sign(self, "SceneSign", "THE STORY THEATRE", Vector3(0, 2.9, STAGE_Z - 1.6), 0.0055, Color("fff6d8"))
	for x: float in [-3.0, 3.0]:
		var c := LifeRoomKit.box(self, "Curtain", Vector3(0.8, 3.4, 0.12), Vector3(x, 1.7 + STAGE_TOP * 0.5, -2.1), Color("c0303f"))
		curtains.append(c)
	LifeRoomKit.light(self, Vector3(0, 3.4, -2.2), 1.4, 9.0, Color(1, 0.95, 0.85))
	LifeRoomKit.light(self, Vector3(0, 2.0, 1.0), 0.6, 6.0)
	for row in 2:
		for i in 5:
			LifeRoomKit.box(sc, "Seat", Vector3(0.5, 0.45, 0.45), Vector3(-2.0 + i * 1.0, 0.22, 1.4 + row * 0.9), Color("8b1e2a"))
			LifeRoomKit.box(sc, "SeatBack", Vector3(0.5, 0.5, 0.08), Vector3(-2.0 + i * 1.0, 0.62, 1.6 + row * 0.9), Color("7a1a25"))
	_braille()
	_trees()
	_wright()
	_carver()
	_ward()
	_fleming()
	_dunant()
	_johnson()
	_rice()
	_seacole()
	_school()
	for k: String in scenes:
		(scenes[k] as Node3D).visible = false
		_scene_look(scenes[k] as Node3D)
	add_view("stage", Vector3(0, 1.6, 1.0), Vector3(0, 1.0, -3.6), Vector3(0, 0, -0.6), 0.0)
	add_view("close", Vector3(0, 1.5, -0.9), Vector3(0, 1.45, -3.2), Vector3(0, 0, -1.5), 0.0)


func _scene(key: String) -> Node3D:
	var n := Node3D.new()
	n.name = key
	add_child(n)
	scenes[key] = n
	return n


func _actor(parent: Node3D, colour: Color, at: Vector3, label: String, yaw: float = 0.0) -> LifeBuddy:
	var b := LifeBuddy.new(colour, label)
	b.position = at
	b.rotation.y = yaw
	parent.add_child(b)
	LifeRoomKit.sign(b, "Name", label.to_upper(), Vector3(0, 1.3, 0), SuccessCast.SIGN_PIXEL)
	return b


func _braille() -> void:
	var s := _scene("scene_braille")
	_actor(s, Color("3a7be8"), Vector3(-1.6, STAGE_TOP, STAGE_Z), "Louis")
	LifeRoomKit.box(s, "Cell", Vector3(0.8, 1.15, 0.06), Vector3(0, 1.45, -3.2), Color("fdf6e3"))
	for r in 3:
		for c in 2:
			var n := r + 1 + c * 3   # braille numbers the dots 1-2-3 down the left, 4-5-6 down the right
			var dot := LifeRoomKit.sphere(s, "dot_%d" % n, 0.09, Vector3(-0.18 + c * 0.36, 1.8 - r * 0.33, -3.15), Color("9aa7b5"))
			add_target("dot_%d" % n, dot, 0.14)
			LifeRoomKit.sign(dot, "Number", str(n), Vector3(0.0, 0.0, 0.1), 0.0022, Color("1f2a4a"))


func _trees() -> void:
	var s := _scene("scene_trees")
	_actor(s, Color("2fae4e"), Vector3(-2.2, STAGE_TOP, STAGE_Z + 0.2), "Wangari")
	_actor(s, Color("e0a400"), Vector3(2.2, STAGE_TOP, STAGE_Z + 0.2), "Friend")
	for i in 5:
		var at := Vector3(-1.6 + i * 0.8, STAGE_TOP + 0.01, STAGE_Z + 0.4)
		var hole := LifeRoomKit.cylinder(s, "hole_%d" % (i + 1), 0.16, 0.02, at, Color("5a3a24"))
		add_target("hole_%d" % (i + 1), hole, 0.22)
		var tree := Node3D.new()
		tree.name = "Seedling"
		tree.position = at
		tree.visible = false
		s.add_child(tree)
		LifeRoomKit.cylinder(tree, "Stem", 0.02, 0.4, Vector3(0, 0.2, 0), Color("6b4a2a"))
		LifeRoomKit.sphere(tree, "Leaves", 0.14, Vector3(0, 0.45, 0), Color("4f9a3e"))
		seedlings["hole_%d" % (i + 1)] = tree


func _wright() -> void:
	var s := _scene("scene_wright")
	_actor(s, Color("7d8a99"), Vector3(-2.3, STAGE_TOP, STAGE_Z + 0.3), "Wilbur")
	_actor(s, Color("6b7a99"), Vector3(2.3, STAGE_TOP, STAGE_Z + 0.3), "Orville")
	glider = Node3D.new()
	glider.name = "Glider"
	glider.position = Vector3(-1.0, 1.1, STAGE_Z + 0.4)
	s.add_child(glider)
	for y: float in [0.0, 0.22]:
		LifeRoomKit.box(glider, "Wing", Vector3(1.2, 0.03, 0.3), Vector3(0, y, 0), Color("e8dcc0"))
	add_target("glider", glider, 0.45)
	plane = Node3D.new()
	plane.name = "Plane"
	plane.position = Vector3(-2.6, 1.0, STAGE_Z - 0.6)
	plane.visible = false
	s.add_child(plane)
	for y: float in [0.0, 0.2]:
		LifeRoomKit.box(plane, "Wing", Vector3(1.0, 0.03, 0.25), Vector3(0, y, 0), Color("e8dcc0"))
	LifeRoomKit.box(plane, "Engine", Vector3(0.12, 0.12, 0.12), Vector3(0, 0.1, 0), Color("9aa7b5"))
	var tunnel := Node3D.new()
	tunnel.name = "WindTunnel"
	tunnel.position = Vector3(1.0, STAGE_TOP, STAGE_Z - 0.4)
	tunnel.visible = track != "little"
	s.add_child(tunnel)
	LifeRoomKit.box(tunnel, "Box", Vector3(1.6, 0.5, 0.5), Vector3(0, 0.55, 0), Color("c9a063"))
	LifeRoomKit.cylinder(tunnel, "Fan", 0.2, 0.05, Vector3(0.85, 0.55, 0), Color("6b7a99"))
	LifeRoomKit.sign(tunnel, "Sign", "WIND TUNNEL", Vector3(0, 0.95, 0.2), 0.0028)
	for i in 3:
		var card := LifeRoomKit.box(s, "wing_%d" % (i + 1), Vector3(0.36, 0.05, 0.2), Vector3(0.45 + i * 0.5, 1.45, STAGE_Z + 0.5),
			Color("fdf6e3"))
		card.rotation.z = [0.0, 0.35, 0.15][i]
		card.visible = track != "little"
		add_target("wing_%d" % (i + 1), card, 0.18)


func _carver() -> void:
	var s := _scene("scene_carver")
	_actor(s, Color("6aa84f"), Vector3(0, STAGE_TOP, STAGE_Z - 0.7), "George")
	for f: Array in [["plot_peanuts", -1.3, "PEANUTS", Color("8b5a2b")], ["plot_cotton", 1.3, "COTTON", Color("8b5a2b")]]:
		var plot := LifeRoomKit.box(s, str(f[0]), Vector3(1.6, 0.06, 1.2), Vector3(float(f[1]), STAGE_TOP + 0.03, STAGE_Z + 0.3), f[3])
		LifeRoomKit.sign(plot, "Sign", str(f[2]), Vector3(0, 0.5, 0), 0.0032)
		add_target(str(f[0]), plot, 0.55)


func _ward() -> void:
	var s := _scene("scene_ward")
	_actor(s, Color("3a7be8"), Vector3(0, STAGE_TOP, STAGE_Z - 0.5), "Florence")
	for x: float in [-1.8, 1.8]:
		LifeRoomKit.box(s, "Bed", Vector3(1.0, 0.4, 0.6), Vector3(x, STAGE_TOP + 0.2, STAGE_Z + 0.2), Color("c9ced6"))
	var window := LifeRoomKit.box(s, "window", Vector3(0.9, 0.7, 0.05), Vector3(-1.2, 2.0, STAGE_Z - 1.6), Color("4a5160"))
	add_target("window", window, 0.4)
	var basin := LifeRoomKit.cylinder(s, "basin", 0.2, 0.15, Vector3(0.6, STAGE_TOP + 0.6, STAGE_Z + 0.5), Color("9aa7b5"))
	LifeRoomKit.box(s, "Stand", Vector3(0.3, 0.55, 0.3), Vector3(0.6, STAGE_TOP + 0.27, STAGE_Z + 0.5), Color("a8642a"))
	add_target("basin", basin, 0.22)
	var sheets := LifeRoomKit.box(s, "sheets", Vector3(0.9, 0.06, 0.5), Vector3(1.8, STAGE_TOP + 0.43, STAGE_Z + 0.2), Color("b8a888"))
	add_target("sheets", sheets, 0.35)


func _fleming() -> void:
	var s := _scene("scene_fleming")
	_actor(s, Color("8b6fd6"), Vector3(-1.2, STAGE_TOP, STAGE_Z), "Alexander")
	LifeRoomKit.box(s, "LabTable", Vector3(1.4, 0.8, 0.7), Vector3(0.6, STAGE_TOP + 0.4, STAGE_Z + 0.3), Color("f3e1c0"))
	var dish := LifeRoomKit.cylinder(s, "dish", 0.16, 0.03, Vector3(0.6, STAGE_TOP + 0.82, STAGE_Z + 0.3), Color(0.85, 0.94, 1.0, 0.8))
	add_target("dish", dish, 0.22)


func _dunant() -> void:
	var s := _scene("scene_dunant")
	_actor(s, Color("3b3f4a"), Vector3(-2.3, STAGE_TOP, STAGE_Z + 0.3), "Henry")
	for i in 3:
		var resting := LifeBuddy.new(Color("8b8f99"), "Resting")
		resting.position = Vector3(-0.9 + i * 0.9, STAGE_TOP, STAGE_Z - 0.6)
		resting.pose("sit_floor")
		s.add_child(resting)
	for i in 3:
		var h := _actor(s, [Color("e8544e"), Color("ffc93c"), Color("2fae4e")][i], Vector3(-0.9 + i * 0.9, STAGE_TOP, STAGE_Z + 0.6),
			"Helper")
		helpers["helper_%d" % (i + 1)] = h
		add_target("helper_%d" % (i + 1), h.head, 0.28)


func _johnson() -> void:
	var s := _scene("scene_johnson")
	_actor(s, Color("8b6fd6"), Vector3(-1.8, STAGE_TOP, STAGE_Z + 0.2), "Katherine")
	LifeRoomKit.box(s, "Blackboard", Vector3(2.2, 1.3, 0.06), Vector3(0.6, 1.6, STAGE_Z - 1.5), Color("2f4f4f"))
	LifeRoomKit.sphere(s, "Earth", 0.25, Vector3(0.6, 1.6, STAGE_Z - 1.42), Color("5aa8e6"))
	var orbit := LifeRoomKit.cylinder(s, "Orbit", 0.5, 0.01, Vector3(0.6, 1.6, STAGE_Z - 1.44), Color(1, 1, 1, 0.5))
	orbit.rotation.x = PI / 2
	LifeRoomKit.sign(s, "Sum", "90 MIN A LAP  x 3 LAPS", Vector3(0.6, 2.15, STAGE_Z - 1.4), 0.0032)


func _rice() -> void:
	var s := _scene("scene_rice")
	_actor(s, Color("6aa84f"), Vector3(-2.4, STAGE_TOP, STAGE_Z + 0.4), "Yuan")
	for r in 3:
		for c in 6:
			var at := Vector3(-1.5 + c * 0.55, STAGE_TOP, STAGE_Z - 0.6 + r * 0.5)
			var special := r == 1 and c == 4
			var plant := LifeRoomKit.cylinder(s, "special_rice" if special else "Rice", 0.03, 0.6, at + Vector3(0, 0.3, 0),
				Color("e0c34a") if special else Color("7cc46a"))
			if special:
				add_target("special_rice", plant, 0.2)


func _seacole() -> void:
	var s := _scene("scene_seacole")
	_actor(s, Color("8b4a6b"), Vector3(-1.0, STAGE_TOP, STAGE_Z + 0.3), "Mary")
	LifeRoomKit.box(s, "Hut", Vector3(2.0, 1.6, 0.8), Vector3(1.0, STAGE_TOP + 0.8, STAGE_Z - 0.6), Color("e6d3a8"))
	LifeRoomKit.sign(s, "HotelSign", "BRITISH HOTEL", Vector3(1.0, 2.1, STAGE_Z - 0.15), 0.0032, Color("1f2a4a"))


func _school() -> void:
	var s := _scene("scene_school")
	_actor(s, Color("d9437a"), Vector3(-1.2, STAGE_TOP, STAGE_Z + 0.3), "Savitribai")
	LifeRoomKit.box(s, "School", Vector3(2.4, 1.8, 0.6), Vector3(1.0, STAGE_TOP + 0.9, STAGE_Z - 0.8), Color("f3e1c0"))
	LifeRoomKit.sign(s, "SchoolSign", "SCHOOL FOR GIRLS", Vector3(1.0, 2.3, STAGE_Z - 0.45), 0.0032, Color("1f2a4a"))


func on_event(event: String) -> void:
	if scenes.has(event):
		for k: String in scenes:
			(scenes[k] as Node3D).visible = k == event
		backdrop.text = str(SCENE_WORDS.get(event, ""))
		return
	match event:
		"curtain_up":
			_curtains(true)
		"curtain_down":
			_curtains(false)
			backdrop.text = "THE END"
		"glider_falls":
			_glide(glider, glider.position + Vector3(1.2, -0.55, 0.2))
		"plane_flies":
			glider.visible = false
			plane.visible = true
			_glide(plane, Vector3(2.6, 1.9, STAGE_Z - 0.6))
		"tunnel_on":
			pass


func progress(step: Dictionary, state: Dictionary) -> void:
	match str(step.get("kind", "")):
		"find":
			for t: Variant in state.get("found", []):
				var key := str(t)
				if seedlings.has(key):
					(seedlings[key] as Node3D).visible = true
				if helpers.has(key):
					LifeRoomPeople.feel((helpers[key] as LifeBuddy), "happy")
				if has_target(key) and key in ["window", "basin", "sheets"]:
					(target_node(key) as MeshInstance3D).material_override = LifeRoomKit.material(
						{"window": Color("9fd8ff"), "basin": Color("5aa8e6"), "sheets": Color.WHITE}[key])
				if key.begins_with("wing_"):
					(target_node(key) as MeshInstance3D).material_override = LifeRoomKit.material(
						Color("7cc46a") if key == "wing_3" else Color("c9ced6"))
		"sequence":
			var list: Array = step.get("targets", [])
			for i in int(state.get("i", 0)):
				var key := str(list[i])
				if key.begins_with("dot_"):
					(target_node(key) as MeshInstance3D).material_override = LifeRoomKit.material(Color("1f2a4a"))
				elif key.begins_with("plot_"):
					(target_node(key) as MeshInstance3D).material_override = LifeRoomKit.material(Color("62b04e") if key == "plot_peanuts"
						else Color("f6f2ea"))


func step_done(step: Dictionary) -> void:
	if str(step.get("id", "")) == "search" or str(step.get("id", "")) == "fleming":
		var key := "special_rice" if str(step.id) == "search" else "dish"
		if has_target(key):
			(target_node(key) as MeshInstance3D).material_override = LifeRoomKit.material(Color("ffd23f") if key == "special_rice"
				else Color(0.55, 0.85, 0.6, 0.9))


func _curtains(open: bool) -> void:
	for i in curtains.size():
		var c := curtains[i]
		var to := Vector3((-3.0 if i == 0 else 3.0) * (1.0 if open else 0.4), c.position.y, c.position.z)
		if UiMotion.calm() or not is_inside_tree():
			c.position = to
		else:
			create_tween().set_trans(Tween.TRANS_SINE).tween_property(c, "position", to, 0.8)


func _glide(n: Node3D, to: Vector3) -> void:
	if UiMotion.calm() or not is_inside_tree():
		n.position = to
		return
	create_tween().set_trans(Tween.TRANS_SINE).tween_property(n, "position", to, 1.2)


# --- The rooms' look (2026-10-18, docs/devlog/parts/rooms-look.md) -------------------------------------------------------

## The Story Theatre's hall: a polished plank floor, the stage in wood with a golden frame over it, footlights along its
## front, deep blue walls with warm lamps, a ceiling, an aisle carpet between the seats, the door at the back.
func _theatre_look() -> void:
	var d := decor()
	d.sky(Color("2a2f4a"), Color("3a3f5a"), Color("2a2f3a"), 0, 0.0)
	d.tiled("Floor", LifeRoomDecor.PLANKS, Vector3(9, 0.1, 9), Vector3(0, -0.05, -2.0), Color("a87a5c"), 0.75)
	d.tiled("Stage", LifeRoomDecor.PLANKS, Vector3(6.4, STAGE_TOP, 3.4), Vector3(0, STAGE_TOP * 0.5, STAGE_Z), Color("dcae84"),
		0.6, 0.0, LifeRoomDecor.BAKED)
	d.box("StageEdge", Vector3(6.5, 0.06, 0.1), Vector3(0, STAGE_TOP + 0.02, STAGE_Z + 1.72), Color("8a5a34"), 0.0,
		LifeRoomDecor.SHELL)
	for i in 9:   # the footlights
		d.glow_box("Footlight", Vector3(0.18, 0.08, 0.08), Vector3(-2.8 + i * 0.7, STAGE_TOP + 0.07, STAGE_Z + 1.6), Color("ffe08a"))
	# the golden frame over the stage (over the curtains' tops, never across the view)
	d.box("FrameTop", Vector3(7.4, 0.35, 0.2), Vector3(0, 3.85, -2.1), Color("e0b44a"))
	for x: float in [-3.6, 3.6]:
		d.box("FrameSide", Vector3(0.2, 3.85, 0.2), Vector3(x, 1.93, -2.1), Color("e0b44a"))
	# the hall: walls, lamps, a ceiling, the aisle carpet, the door at the back
	for x: float in [-4.5, 4.5]:
		d.box("Wall", Vector3(0.1, 4.2, 9.0), Vector3(x, 2.1, -2.0), Color("2f3d6b"), 0.0, LifeRoomDecor.SHELL)
		d.box("WallLow", Vector3(0.12, 1.0, 9.0), Vector3(x, 0.5, -2.0), Color("5a3a2a"), 0.0, LifeRoomDecor.SHELL)
		for z: float in [-0.6, 1.6]:
			d.box("WallLamp", Vector3(0.1, 0.3, 0.2), Vector3(x * 0.98, 2.2, z), Color("e0b44a"))
			d.glow_box("WallLampGlow", Vector3(0.12, 0.2, 0.14), Vector3(x * 0.97, 2.25, z), Color("ffd98a"))
	d.box("BackWall", Vector3(9.0, 4.2, 0.1), Vector3(0, 2.1, 2.5), Color("2f3d6b"), 0.0, LifeRoomDecor.SHELL)
	d.box("HallDoor", Vector3(1.1, 2.1, 0.06), Vector3(0, 1.05, 2.44), Color("8a5a34"))
	d.box("Ceiling", Vector3(9.0, 0.1, 9.0), Vector3(0, 4.25, -2.0), Color("26304f"), 0.0, LifeRoomDecor.SHELL)
	d.box("Aisle", Vector3(0.0 + 0.7, 0.012, 3.0), Vector3(-2.5, 0.006, 1.9), Color("8b1e2a"), 0.0, LifeRoomDecor.SHELL)


## A scene's own props drawn as one mesh, its actors each a head and a body (the Quest's draws: the scenes are many).
func _scene_look(scene: Node3D) -> void:
	LifeRoomPeople.merge_parts(self, scene)
	for n: Node in scene.get_children():
		if n is LifeBuddy:
			LifeRoomPeople.merge_person(n as LifeBuddy, true)
