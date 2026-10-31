class_name MakeStation
extends PlayStation
## Owner #122 (G0), Make it (design §5.1): the number is made with the world's things (PlayMake's makers). The sources
## wait along the table's front ("src_<i>": a cube pile, base-ten blocks, coins, cups, weights, fraction bars, a frog's
## jumps); a tap on a source (VR: the hand squeezing at it) puts one more on the build at the back, a tap on a piece of
## the build takes that one off ("piece_<k>"), TAKE ONE BACK ("back") the last one. The machine's sign reads what is made
## (the child's own build, never the answer). TEST IT (GO) asks the world: right, the sign lights green and the build
## hops; not yet, the world says whether it is not enough yet or a little too much (the scale tips that way); the build
## stays to be changed (as the School's pad kept the number). For a number no maker can build within PlayMake.MAX_PIECES
## the counting machine's keys type it ("key_<k>", the dial).

const BUILD_Z := 0.22
const SIGN_AT := Vector3(0.56, TABLE_TOP + 0.3, BUILD_Z)
const SOURCE_Y := TABLE_TOP + 0.06
const GOOD := Color("8dff8a")
const SAY := Color("fff4b0")
const PLACE_COLOURS := {"1": Color("f7d117"), "10": Color("2fae4e"), "100": Color("3a7be8"), "1000": Color("d6475a"),
	"0.1": Color("17b6c4"), "0.01": Color("8b6fd6"), "0.001": Color("e0a325")}
const SOURCES_A_ROW := 5
const SOURCE_GAP := 0.2
const MORE := "Not enough yet."
const LESS := "A little too much."

var maker := ""
var offered: Array[String] = []
var placed: Array[String] = []
var typed := ""
var keys: Array[String] = []
var unit := ""
var sign: Label3D
var pieces_node: Node3D
var beam: Node3D
var water: MeshInstance3D
var frog: Node3D
var line_range := 10.0
var ticks: Array[Label3D] = []
var world_says := ""
var _piece_nodes: Array[Node3D] = []


func build() -> void:
	maker = PlayMake.maker(ex, str(params.get("maker", "")))
	offered = PlayMake.pieces(ex, maker)
	unit = PlayMake.unit_word(ex, maker)
	PlayKit.table(self, TABLE_AT, TABLE_SIZE, TABLE_TOP)
	pieces_node = Node3D.new()
	pieces_node.name = "Build"
	add_child(pieces_node)
	sign = PlayKit.words(self, "Made", "", SIGN_AT, 0.0013, 54, SAY)
	sign.width = 440
	if maker == "dial":
		_build_keys()
	else:
		_build_sources()
		_build_place()
		var back := PlayKit.card(self, "Back", {"text": "TAKE ONE BACK"}, UTILITY_AT, Color("6b7a99"), UTILITY)
		add("back", back, 0.1)
	add(GO, PlayKit.go_button(self, go_words(), GO_AT), 0.11)
	_refresh()


# --- Building ------------------------------------------------------------------------------------------------------

## The sources along the table's front: up to SOURCES_A_ROW a row (a second row just behind), biggest first.
func _build_sources() -> void:
	var rows := ceili(offered.size() / float(SOURCES_A_ROW))
	var per_row := ceili(offered.size() / float(maxi(rows, 1)))
	for i in offered.size():
		var v := offered[i]
		var r := i / per_row
		var xs := spread(mini(per_row, offered.size() - r * per_row), SOURCE_GAP)
		var src := Node3D.new()
		src.name = "Source%d" % i
		src.position = Vector3(xs[i - r * per_row], SOURCE_Y, FRONT_Z + 0.04 - r * 0.17)
		add_child(src)
		var size := _piece_size(v)
		var pile := Node3D.new()   # a little pile (there are always more), never wider than its place in the row
		pile.name = "Pile"
		pile.scale.x = minf(1.0, SOURCE_GAP * 0.85 / maxf(size.x, 0.001))
		src.add_child(pile)
		for k in 3:
			_piece_mesh(pile, v, Vector3(0, size.y * 0.5 + k * (size.y + 0.004), 0))
		PlayKit.words(src, "Value", _label(v), Vector3(0, maxf(size.y * 3.2, 0.05) + 0.06, 0.02), 0.0011, 48, Color.WHITE)
		add("src_%d" % i, src, 0.09)


func _build_place() -> void:
	match maker:
		"jug":
			var cap := _capacity()
			LifeRoomKit.cylinder(self, "Jug", 0.13, 0.42, Vector3(0, TABLE_TOP + 0.21, BUILD_Z - 0.05), Color(0.85, 0.95, 1.0, 0.35))
			water = LifeRoomKit.cylinder(self, "Water", 0.12, 0.4, Vector3(0, TABLE_TOP, BUILD_Z - 0.05), Color("5ab0e8"))
			for k in 5:   # the jug's marks, each a fifth of what it holds
				LifeRoomKit.box(self, "Mark", Vector3(0.05, 0.006, 0.01), Vector3(0.12, TABLE_TOP + 0.08 * (k + 1), BUILD_Z + 0.07),
					Color("1f2a4a"))
			PlayKit.words(self, "Holds", "%s %s" % [NumberPad.group(str(int(cap))), unit], Vector3(0.24, TABLE_TOP + 0.42, BUILD_Z - 0.05),
				0.001, 44, Color.WHITE)
		"scale":
			beam = Node3D.new()
			beam.name = "Beam"
			beam.position = Vector3(0, TABLE_TOP + 0.36, BUILD_Z - 0.08)
			add_child(beam)
			LifeRoomKit.box(self, "Stand", Vector3(0.05, 0.36, 0.05), Vector3(0, TABLE_TOP + 0.18, BUILD_Z - 0.08), Color("6b7a99"))
			LifeRoomKit.box(beam, "Bar", Vector3(0.8, 0.03, 0.03), Vector3.ZERO, Color("39445e"))
			LifeRoomKit.box(beam, "PanLeft", Vector3(0.26, 0.02, 0.2), Vector3(-0.36, -0.12, 0), Color("c0c6d4"))
			LifeRoomKit.box(beam, "PanRight", Vector3(0.26, 0.02, 0.2), Vector3(0.36, -0.12, 0), Color("c0c6d4"))
			LifeRoomKit.box(beam, "Sack", Vector3(0.16, 0.14, 0.14), Vector3(-0.36, -0.04, 0), Color("c98d4f"))
			PlayKit.words(beam, "What", "?", Vector3(-0.36, 0.1, 0.08), 0.0016, 60, Color.WHITE)
		"frog":
			LifeRoomKit.box(self, "Water", Vector3(0.66, 0.02, 0.16), Vector3(-0.33, TABLE_TOP + 0.01, BUILD_Z), Color("5ab0e8"))
			LifeRoomKit.box(self, "Grass", Vector3(0.66, 0.02, 0.16), Vector3(0.33, TABLE_TOP + 0.01, BUILD_Z), PlayArena.GRASS)
			LifeRoomKit.box(self, "Line", Vector3(1.32, 0.01, 0.02), Vector3(0, TABLE_TOP + 0.03, BUILD_Z), Color.WHITE)
			frog = Node3D.new()
			frog.name = "Frog"
			add_child(frog)
			LifeRoomKit.box(frog, "Body", Vector3(0.07, 0.05, 0.08), Vector3(0, 0.025, 0), Color("3f9d5a"))
			for x: float in [-0.02, 0.02]:
				LifeRoomKit.box(frog, "Eye", Vector3(0.015, 0.015, 0.015), Vector3(x, 0.06, 0.03), Color.WHITE)
	if maker == "fraction":   # three wholes' frames, one above the other (the parts fill them in turn)
		for b in 3:
			LifeRoomKit.box(self, "Whole%d" % b, Vector3(0.62, 0.005, 0.08), Vector3(0, TABLE_TOP + 0.02 + b * 0.09, BUILD_Z - 0.05),
				Color(1, 1, 1, 0.3))
	if maker == "frog":
		for k: int in [-1, 0, 1]:
			ticks.append(PlayKit.words(self, "Tick", "", Vector3(k * 0.62, TABLE_TOP + 0.08, BUILD_Z + 0.09), 0.0011, 44,
				Color.WHITE))


func _build_keys() -> void:
	keys = PlayMake.keys(ex)
	LifeRoomKit.box(self, "Machine", Vector3(0.9, 0.36, 0.08), Vector3(0, TABLE_TOP + 0.3, BUILD_Z - 0.12), Color("39445e"))
	LifeRoomKit.box(self, "Screen", Vector3(0.7, 0.16, 0.01), Vector3(0, TABLE_TOP + 0.33, BUILD_Z - 0.075), Color("9fd8ff"))
	sign.position = Vector3(0, TABLE_TOP + 0.33, BUILD_Z - 0.04)   # the machine's own screen shows what is typed
	sign.modulate = Color("1f2a4a")
	sign.outline_size = 0
	var per_row := 5
	for k in keys.size():
		var col := k % per_row
		var row := k / per_row
		var key := PlayKit.card(self, "Key%d" % k, {"text": "DEL" if keys[k] == NumberPad.DELETE else keys[k]},
			Vector3(-0.44 + col * 0.22, ON_TABLE - 0.02, FRONT_Z - 0.16 + row * 0.12), Color("f6f2ea"), Vector3(0.16, 0.05, 0.1))
		add("key_%d" % k, key, 0.075)


# --- Acting --------------------------------------------------------------------------------------------------------

func press(t: String) -> void:
	world_says = ""
	if t.begins_with("src_"):
		add_piece(offered[int(t.get_slice("_", 1))])
	elif t.begins_with("piece_"):
		var k := int(t.get_slice("_", 1))
		if k >= 0 and k < placed.size():
			placed.remove_at(k)
	elif t == "back":
		if not placed.is_empty():
			placed.pop_back()
	elif t.begins_with("key_"):
		typed = PlayMake.type_key(typed, keys[int(t.get_slice("_", 1))], ex)
	else:
		return
	_refresh()
	changed.emit()


## One more piece on the build (at most MAX_PIECES; fraction bars hold at most three wholes).
func add_piece(v: String) -> void:
	if placed.size() >= PlayMake.MAX_PIECES:
		return
	if maker == "fraction" and NumberAnswer.value(PlayMake.total(placed + [v])) > 3.0 + 1e-9:
		return
	placed.append(v)


func is_ready() -> bool:
	return typed != "" if maker == "dial" else true


func response() -> Variant:
	return typed if maker == "dial" else PlayMake.total(placed)


func readout() -> String:
	if maker == "dial":
		return NumberPad.shown(typed, ExerciseCheck.grouped(ex))
	var made := PlayMake.total(placed)
	var shown := made if made.contains("/") else NumberPad.shown(made, ExerciseCheck.grouped(ex))
	return ("Made: %s %s" % [shown, unit]).strip_edges()


func world_words() -> String:
	return world_says


func ghost() -> Array[String]:
	var answer := str(ex.get("answer", "")).replace(",", "")
	if maker == "dial":
		if ExerciseCheck.is_right(ex, typed) and typed == answer:
			return [] as Array[String]
		var key := answer.substr(typed.length(), 1) if answer.begins_with(typed) else NumberPad.DELETE
		if key == "." and typed == "":
			key = "0"
		return ["key_%d" % keys.find(key)] as Array[String]
	var g := PlayMake.ghost_step(answer, offered, placed)
	if g.has("add"):
		return ["src_%d" % offered.find(str(g.add))] as Array[String]
	if g.has("remove"):
		return ["piece_%d" % placed.rfind(str(g.remove))] as Array[String]
	return [] as Array[String]


func show_answer() -> void:
	var answer := str(ex.get("answer", "")).replace(",", "")
	if maker == "dial":
		typed = answer
	else:
		placed = PlayMake.decompose(answer, offered)
	world_says = ""
	_refresh()


func react(outcome: String) -> void:
	match outcome:
		PlayLoop.RIGHT:
			sign.modulate = GOOD
			_tilt(0)
			hop(pieces_node)
		PlayLoop.NOT_YET, PlayLoop.GHOST:
			var c := PlayMake.compare(placed, ex) if maker != "dial" else 0
			world_says = MORE if c < 0 else (LESS if c > 0 else "")
			_tilt(c)
			shake(pieces_node)
			_refresh()
		PlayLoop.SHOWN:
			show_answer()
			sign.modulate = GOOD
			_tilt(0)


# --- Showing the build ---------------------------------------------------------------------------------------------

func _refresh() -> void:
	for c in _piece_nodes:
		if is_instance_valid(c):
			c.get_parent().remove_child(c)
			c.queue_free()
	_piece_nodes.clear()
	for t in _owned.duplicate():
		if t.begins_with("piece_"):
			arena.targets.erase(t)
			_owned.erase(t)
	var counts := {}
	var fraction_at := 0.0
	for k in placed.size():
		var v := placed[k]
		var n := counts.get(v, 0) as int
		counts[v] = n + 1
		var node := Node3D.new()
		node.name = "Piece%d" % k
		(beam if maker == "scale" and beam != null else pieces_node).add_child(node)   # weights ride the scale's pan
		_piece_nodes.append(node)
		if maker == "fraction":
			var len := NumberAnswer.value(v)
			var bar := floori(fraction_at + 1e-9)
			if floori(fraction_at + len - 1e-9) > bar:   # it doesn't fit in this bar: the next one
				fraction_at = float(bar + 1)
				bar += 1
			node.position = Vector3(-0.3 + (fraction_at - bar + len * 0.5) * 0.6, TABLE_TOP + 0.05 + bar * 0.09, BUILD_Z)
			fraction_at += len
		else:
			node.position = _piece_at(v, n, k)
		_piece_mesh(node, v, Vector3.ZERO)
		if maker in ["tower", "base_ten", "coins", "scale", "fraction"]:
			add("piece_%d" % k, node, maxf(_piece_size(v).x * 0.6, 0.04))
	if maker == "jug" and water != null:
		var level := clampf(NumberAnswer.value(PlayMake.total(placed)) / _capacity(), 0.0, 1.0)
		water.scale = Vector3(1, maxf(level, 0.001), 1)
		water.position.y = TABLE_TOP + 0.2 * level
	if maker == "frog" and frog != null:   # the line's ends follow the frog (never the answer): 10, 20, 50, 100 …
		var at := NumberAnswer.value(PlayMake.total(placed))
		line_range = 10.0
		for r: float in [10.0, 20.0, 50.0, 100.0, 200.0, 500.0, 1000.0, 2000.0, 5000.0, 10000.0]:
			line_range = r
			if r >= absf(at):
				break
		for k in ticks.size():
			ticks[k].text = NumberPad.shown(str(int((k - 1) * line_range)), true)
		move(frog, Vector3(clampf(at / line_range, -1.0, 1.0) * 0.62, TABLE_TOP + 0.03, BUILD_Z))
	sign.text = readout() if world_says == "" else "%s\n%s" % [readout(), world_says]


## Where the n-th piece of value v (the k-th on the build) sits (local): a column per kind, biggest on the left.
func _piece_at(v: String, n: int, k: int) -> Vector3:
	var cols := offered.size()
	var xs := spread(cols, minf(0.24, 1.2 / maxf(cols, 1.0)))
	var c := offered.find(v)
	var size := _piece_size(v)
	match maker:
		"tower":
			return Vector3(-0.2 + (n / 10) * 0.07, TABLE_TOP + size.y * 0.5 + (n % 10) * (size.y + 0.003), BUILD_Z)
		"scale":   # on the right pan (the beam's own frame), a little stack per kind of weight
			return Vector3(0.36 + (c % 3 - 1) * 0.075, -0.11 + size.y * 0.5 + n * (size.y + 0.002), (c / 3 % 2) * 0.07 - 0.035)
		"jug":   # the cups poured so far, in a row beside the jug
			return Vector3(0.24 + (k % 8) * 0.045, TABLE_TOP + 0.02 + (k / 8) * 0.035, BUILD_Z + 0.12)
		"frog":   # the jumps made so far, in a row on the table (the frog shows where they lead)
			return Vector3(-0.5 + (k % 16) * 0.065, TABLE_TOP + 0.02 + (k / 16) * 0.035, 0.42)
	var per_row := 1 if size.y < 0.05 and size.x >= 0.1 else (2 if size.x >= 0.1 else 3)
	var layer := n / per_row
	var i := n % per_row
	return Vector3(xs[c] + (i - (per_row - 1) * 0.5) * (size.x + 0.008), TABLE_TOP + size.y * 0.5 + layer * (size.y + 0.004),
		BUILD_Z)


func _piece_size(v: String) -> Vector3:
	var x := absf(NumberAnswer.value(v))
	match maker:
		"tower":
			return Vector3(0.05, 0.05, 0.05)
		"coins":
			return Vector3(0.075 + 0.006 * log(maxf(x, 1.0)), 0.014, 0.0)
		"scale":
			return Vector3(0.05 + 0.005 * log(maxf(x, 1.0)), 0.02 + 0.004 * log(maxf(x, 1.0)), 0.0)
		"jug":
			return Vector3(0.035, 0.03, 0.035)
		"frog":
			return Vector3(0.07, 0.03, 0.03)
		"fraction":
			return Vector3(0.6 * x, 0.06, 0.06)
	if x >= 10000.0:
		return Vector3(0.13, 0.13, 0.13)
	if x >= 1000.0:
		return Vector3(0.12, 0.12, 0.12)
	if x >= 100.0:
		return Vector3(0.12, 0.022, 0.12)
	if x >= 10.0:
		return Vector3(0.12, 0.022, 0.022)
	if x >= 1.0:
		return Vector3(0.024, 0.024, 0.024)
	if x >= 0.1:
		return Vector3(0.08, 0.01, 0.08)
	if x >= 0.01:
		return Vector3(0.04, 0.01, 0.04)
	return Vector3(0.016, 0.016, 0.016)


## A piece's look (under `parent` at `at`): blocks by place value, coins and weights as round things, a jump as an arrow.
func _piece_mesh(parent: Node3D, v: String, at: Vector3) -> void:
	var size := _piece_size(v)
	var x := NumberAnswer.value(v)
	match maker:
		"coins":
			LifeRoomKit.cylinder(parent, "Coin", size.x * 0.5, size.y, at, Color("ffd23f"))
		"scale":
			LifeRoomKit.cylinder(parent, "Weight", size.x * 0.5, size.y, at, Color("8a93a6"))
		"jug":
			LifeRoomKit.cylinder(parent, "Cup", size.x * 0.5, size.y, at, Color("5ab0e8"))
		"frog":
			LifeRoomKit.box(parent, "Jump", size, at, Color("3f9d5a") if x > 0.0 else Color("17b6c4"))
		"fraction":
			var den := int(NumberAnswer.parse(v)[1])
			var colours := [Color("d6475a"), Color("f08a1c"), Color("f7d117"), Color("2fae4e"), Color("17b6c4"), Color("3a7be8"),
				Color("8b6fd6"), Color("d9437a")]
			LifeRoomKit.box(parent, "Part", size - Vector3(0.006, 0, 0), at, colours[posmod(den, colours.size())])
		_:
			var key := v if PLACE_COLOURS.has(v) else ("1000" if x >= 1000.0 else "1")
			LifeRoomKit.box(parent, "Block", size, at, PLACE_COLOURS[key])


## What a source says: its value and unit ("+10" for a jump, "1/4", "100 g").
func _label(v: String) -> String:
	var shown := v if v.contains("/") else NumberPad.shown(v, true)
	match maker:
		"frog":
			return ("+" if not v.begins_with("-") else "") + shown
		"coins", "jug", "scale":
			return "%s %s" % [shown, unit]
	return shown


## What the jug holds: a round amount at least the biggest cup's double (never the answer).
func _capacity() -> float:
	var biggest := 1.0
	for v in offered:
		biggest = maxf(biggest, NumberAnswer.value(v))
	for c: float in [100.0, 200.0, 500.0, 1000.0, 2000.0, 5000.0, 10000.0]:
		if c >= biggest * 2.0:
			return c
	return biggest * 2.0


## The scale tips to the heavier side (only after a test: never while building).
func _tilt(c: int) -> void:
	if beam == null:
		return
	var to := -0.18 * c
	if UiMotion.calm() or not is_inside_tree():
		beam.rotation.z = to
		return
	create_tween().tween_property(beam, "rotation:z", to, 0.4)
