class_name BeatStation
extends PlayStation
## Owner #122 (G0), Beat it (design §5.1): a row of drums, one for each beat box of the rhythm to copy. LISTEN (the
## speaker) plays the rhythm; a tap on a drum (VR: a hand hitting it, or the laser) makes it a clap or a rest again; MY
## RHYTHM plays the drums as set. PLAY IT: right, the drums light up together; not yet, they stay to be changed. The
## pattern is checked, never the speed (as the School's rhythm answer).

const CLAP := Color("d6475a")
const REST := Color("8a93a6")

var pattern := ""
var target := ""
var drums: Array[MeshInstance3D] = []
var player: AudioStreamPlayer


func build() -> void:
	target = str((ex.get("sound", {}) as Dictionary).get("pattern", ""))
	pattern = "-".repeat(target.length())
	PlayKit.table(self, TABLE_AT, TABLE_SIZE, TABLE_TOP)
	var xs := spread(target.length(), minf(0.18, 1.3 / maxf(target.length(), 1.0)))
	for i in target.length():
		var drum := Node3D.new()
		drum.name = "Drum%d" % i
		drum.position = Vector3(xs[i], TABLE_TOP + 0.06, FRONT_Z - 0.05)
		add_child(drum)
		LifeRoomKit.cylinder(drum, "Shell", 0.065, 0.1, Vector3.ZERO, Color("39445e"))
		drums.append(LifeRoomKit.cylinder(drum, "Skin", 0.06, 0.01, Vector3(0, 0.055, 0), REST))
		PlayKit.words(drum, "Beat", str(i + 1), Vector3(0, 0.13, 0.03), 0.0009, 40, Color.WHITE)
		add("beat_%d" % i, drum, 0.075)
	player = AudioStreamPlayer.new()
	player.bus = Audio.BUS
	add_child(player)
	shelf()
	var listen := PlayKit.card(self, "Listen", {"text": "LISTEN"}, Vector3(-0.35, SHELF_TOP + 0.1, BACK_Z), Color("9b59d0"),
		Vector3(0.34, 0.14, 0.12))
	add("listen", listen, 0.12)
	var mine := PlayKit.card(self, "Mine", {"text": "MY RHYTHM"}, Vector3(0.35, SHELF_TOP + 0.1, BACK_Z), Color("3f51b5"),
		Vector3(0.34, 0.14, 0.12))
	add("mine", mine, 0.12)
	add(GO, PlayKit.go_button(self, go_words(), GO_AT), 0.11)
	_refresh()


func press(t: String) -> void:
	if t == "listen":
		_play(ex.get("sound", {}))
		return
	if t == "mine":
		_play({"kind": "rhythm", "pattern": pattern, "tempo": int((ex.get("sound", {}) as Dictionary).get("tempo", 90))})
		return
	if not t.begins_with("beat_"):
		return
	var i := int(t.get_slice("_", 1))
	pattern = pattern.substr(0, i) + ("-" if pattern[i] == "x" else "x") + pattern.substr(i + 1)
	_refresh()
	changed.emit()


func _play(sound: Variant) -> void:
	if not is_inside_tree() or SchoolSound.problem(sound) != "":
		return
	player.stream = SchoolSound.stream(sound)
	player.stop()
	player.play()


func response() -> Variant:
	return pattern


func ghost() -> Array[String]:
	for i in target.length():
		if pattern[i] != target[i]:
			return ["beat_%d" % i] as Array[String]
	return [] as Array[String]


func show_answer() -> void:
	pattern = target
	_refresh()


func react(outcome: String) -> void:
	match outcome:
		PlayLoop.RIGHT:
			for d in drums:
				hop(d.get_parent() as Node3D)
		PlayLoop.SHOWN:
			show_answer()


func _refresh() -> void:
	for i in drums.size():
		drums[i].material_override = LifeRoomKit.material(CLAP if pattern[i] == "x" else REST)
