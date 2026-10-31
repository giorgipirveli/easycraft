class_name MixStation
extends PlayStation
## Owner #122 (G0), Mix it (design §5.1): the painter's paint pots (red, yellow, blue, white, black) and a mixing bowl.
## A tap on a pot (VR: a hand at it, or the laser) adds a drop: the bowl takes the mix's own colour (ColourMix); EMPTY
## starts again. PAINT WITH IT: the painting on the easel takes the colour; right, the painter hops; not yet, the drops
## stay to be changed.

var drops := {}
var bowl: MeshInstance3D
var canvas: MeshInstance3D
var painter: LifeBuddy
var sign: Label3D


func build() -> void:
	PlayKit.table(self, TABLE_AT, TABLE_SIZE, TABLE_TOP)
	var xs := spread(ColourMix.PAINTS.size(), 0.24)
	for i in ColourMix.PAINTS.size():
		var paint: String = ColourMix.PAINTS[i]
		var pot := Node3D.new()
		pot.name = "Pot_" + paint
		pot.position = Vector3(xs[i], TABLE_TOP + 0.05, FRONT_Z)
		add_child(pot)
		LifeRoomKit.cylinder(pot, "Tin", 0.06, 0.1, Vector3.ZERO, Color("c0c6d4"))
		LifeRoomKit.cylinder(pot, "Paint", 0.055, 0.01, Vector3(0, 0.051, 0), ColourMix.PAINT_COLOURS[paint])
		PlayKit.words(pot, "Name", paint.to_upper(), Vector3(0, 0.13, 0.03), 0.0009, 40, Color.WHITE)
		add("pot_" + paint, pot, 0.08)
	var bowl_at := Vector3(-0.2, TABLE_TOP, 0.26)
	LifeRoomKit.cylinder(self, "Bowl", 0.13, 0.06, bowl_at + Vector3(0, 0.03, 0), Color("f6f2ea"))
	bowl = LifeRoomKit.cylinder(self, "Mix", 0.11, 0.01, bowl_at + Vector3(0, 0.065, 0), Color("f6f2ea"))
	var empty := PlayKit.card(self, "Empty", {"text": "EMPTY"}, UTILITY_AT + Vector3(-0.05, 0, 0), Color("6b7a99"), UTILITY)
	add("empty", empty, 0.1)
	shelf()
	canvas = LifeRoomKit.box(self, "Painting", Vector3(0.44, 0.32, 0.02), Vector3(0.3, SHELF_TOP + 0.2, BACK_Z), Color("fdfdf8"))
	sign = PlayKit.words(self, "Drops", "", bowl_at + Vector3(0, 0.22, 0), 0.0012, 48, Color("fff4b0"))
	sign.width = 500
	painter = LifeBuddy.new(Color("d9437a"), "Painter")
	painter.scale = Vector3.ONE * 0.45
	painter.position = Vector3(0.66, SHELF_TOP, BACK_Z)
	add_child(painter)
	add(GO, PlayKit.go_button(self, go_words(), GO_AT), 0.11)
	_refresh()


func press(t: String) -> void:
	if t == "empty":
		drops.clear()
	elif t.begins_with("pot_"):
		var paint := t.trim_prefix("pot_")
		var total := 0
		for k: String in drops:
			total += int(drops[k])
		if total >= ColourMix.MAX_DROPS:
			return
		drops[paint] = int(drops.get(paint, 0)) + 1
	else:
		return
	_refresh()
	changed.emit()


func response() -> Variant:
	return drops.duplicate()


func is_ready() -> bool:
	return not drops.is_empty()


func ghost() -> Array[String]:
	var target := str(ex.get("target", ""))
	if ColourMix.matches(target, drops):
		return [] as Array[String]
	var recipe: Dictionary = ColourMix.RECIPES.get(target, {})
	for k: String in drops:
		if int(drops[k]) > int(recipe.get(k, 0)):
			return ["empty"] as Array[String]
	for paint: String in ColourMix.PAINTS:
		if int(drops.get(paint, 0)) < int(recipe.get(paint, 0)):
			return ["pot_" + paint] as Array[String]
	return [] as Array[String]


func show_answer() -> void:
	drops = (ColourMix.RECIPES.get(str(ex.get("target", "")), {}) as Dictionary).duplicate()
	_refresh()


func react(outcome: String) -> void:
	match outcome:
		PlayLoop.RIGHT:
			canvas.material_override = LifeRoomKit.material(ColourMix.colour(drops))
			painter.face("happy")
			hop(painter)
		PlayLoop.NOT_YET, PlayLoop.GHOST:
			canvas.material_override = LifeRoomKit.material(ColourMix.colour(drops))
		PlayLoop.SHOWN:
			show_answer()
			canvas.material_override = LifeRoomKit.material(ColourMix.colour(drops))


func _refresh() -> void:
	bowl.material_override = LifeRoomKit.material(ColourMix.colour(drops) if not drops.is_empty() else Color("f6f2ea"))
	# owner #133: with the voice on, an empty bowl says nothing in words (it looks empty)
	sign.text = ColourMix.words(drops) if not drops.is_empty() else ("" if PlayVoice.on() else "The bowl is empty.")
