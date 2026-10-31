class_name RhythmAnswer
extends VBoxContainer
## The research's "tap the rhythm" (docs/design/school-curriculum-research.md §5.3): the exercise's LISTEN plays claps;
## a row of beat boxes, one per beat of the pattern, each a rest (its number) until tapped (a clap: orange, an X) and
## back again.
## MINE plays the child's own pattern at the same tempo; CHECK compares the pattern, never the speed.

signal changed

const BOX := Vector2(62, 72)

var target: Dictionary
var boxes: Array[Button] = []
var mine_button: Button
var player := AudioStreamPlayer.new()
var _claps: Array[bool] = []
var _locked := false


func _init(ex: Dictionary) -> void:
	target = ex.get("sound", {})
	add_theme_constant_override("separation", 14)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var words := SchoolUi.words("Tap a box to put a clap on that beat: X is a clap.", 22, 540)
	add_child(words)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 4)
	var beats := str(target.get("pattern", "")).length()
	for i in beats:
		_claps.append(false)
		# UiKit's button, not the School's: a beat box is narrower than the School's 135 px buttons (16 fit the row)
		var b := UiKit.big_button("", Color(), Vector2(minf(BOX.x, 540.0 / maxf(beats, 1) - 4.0), BOX.y))
		b.focus_mode = Control.FOCUS_NONE
		for state: String in ["normal", "hover", "pressed", "disabled"]:
			b.add_theme_stylebox_override(state, UiKit.box(Color(0.2, 0.24, 0.36), 14, 4))
		b.name = "Beat%d" % i
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(tap.bind(i))
		boxes.append(b)
		row.add_child(b)
	add_child(row)
	player.bus = Audio.BUS
	add_child(player)
	mine_button = SchoolUi.button("PLAY MINE", Color("9b59d0"), Vector2(240, 64))
	mine_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	mine_button.pressed.connect(play_mine)
	add_child(mine_button)
	_relabel()


func tap(i: int) -> void:
	if _locked or i < 0 or i >= _claps.size():
		return
	_claps[i] = not _claps[i]
	_relabel()
	changed.emit()


## The child's pattern, at the target's tempo (nothing plays while it has no clap).
func play_mine() -> void:
	var p := response() as String
	if not p.contains("x"):
		return
	player.stream = SchoolSound.stream({"kind": "rhythm", "pattern": p, "tempo": target.get("tempo", 100)})
	player.stop()
	player.play()


func response() -> Variant:
	var out := ""
	for c in _claps:
		out += "x" if c else "-"
	return out


func is_ready() -> bool:
	return _claps.has(true)


func mark_wrong() -> void:
	pass   # the boxes stay: the child listens again and changes what differs


func mark_right() -> void:
	for b in boxes:
		b.add_theme_stylebox_override("disabled", UiKit.box(UiKit.GREEN))


func lock() -> void:
	_locked = true
	for b in boxes:
		b.disabled = true


func show_answer(answer: Variant) -> void:
	var p := str(answer)
	for i in mini(_claps.size(), p.length()):
		_claps[i] = p[i] == "x"
	_relabel()
	mark_right()


func _relabel() -> void:
	for i in boxes.size():
		boxes[i].text = "X" if _claps[i] else str(i + 1)
		if _claps[i]:
			boxes[i].add_theme_stylebox_override("normal", UiKit.box(Color("f08a1c"), 14, 4))
		else:
			boxes[i].add_theme_stylebox_override("normal", UiKit.box(Color(0.2, 0.24, 0.36), 14, 4))
		boxes[i].add_theme_font_size_override("font_size", 26)
