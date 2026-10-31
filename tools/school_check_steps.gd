extends Node
## The steps of tools/school_check.gd (a Node, so it may use the autoloads and the School's classes).

const LESSON_W := 560.0     # SchoolScreen.show_lesson's picture
const EXERCISE_W := 580.0   # ExercisePanel.PICTURE
const READABLE := 17         # a table cell's words smaller than this are hard to read on a phone


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	var only := OS.get_cmdline_user_args()
	var problems: Array[String] = []
	var units := 0
	var exercises := 0
	for g in Curriculum.grades():
		for s: Dictionary in Curriculum.subjects(g):
			for u: Dictionary in Curriculum.units(g, str(s.id)):
				var id := str(u.id)
				if not Curriculum.has_content(id) or (not only.is_empty() and not only.has(id)):
					continue
				units += 1
				problems.append_array(Curriculum.content_problems(id))
				var c := Curriculum.content(id)
				for i in (c.lesson as Array).size():
					var card: Dictionary = c.lesson[i]
					if str(card.get("text", "")).length() > 260:
						problems.append("%s card %d: %d letters (260 at most)" % [id, i, str(card.text).length()])
					if card.has("picture") and SchoolPicture.problem(card.picture) != "":
						problems.append("%s card %d's picture: %s" % [id, i, SchoolPicture.problem(card.picture)])
					if card.has("picture"):
						problems.append_array(_table_cells(card.picture, LESSON_W, "%s card %d" % [id, i]))
					if card.has("sound") and SchoolSound.problem(card.sound) != "":
						problems.append("%s card %d's sound: %s" % [id, i, SchoolSound.problem(card.sound)])
				for ex: Dictionary in c.exercises:
					exercises += 1
					problems.append_array(_exercise(ex))
	for p in problems:
		print("SCHOOL_CHECK %s" % p)
	print("SCHOOL_CHECK %d units, %d hand-written exercises, %d problems" % [units, exercises, problems.size()])
	get_tree().quit(1 if not problems.is_empty() else 0)


func _exercise(ex: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if ExerciseCheck.problem(ex) != "":
		return out   # content_problems has said it
	if not ExerciseCheck.is_right(ex, ExerciseCheck.answer_of(ex)):
		out.append("%s: its own answer is not right" % ex.id)
	match str(ex.type):
		"choice":
			for i in (ex.choices as Array).size():
				if i != int(ex.answer) and ExerciseCheck.is_right(ex, i):
					out.append("%s: choice %d is right too" % [ex.id, i])
		"truefalse":
			if ExerciseCheck.is_right(ex, not ex.answer):
				out.append("%s: both truths are right" % ex.id)
	var pictures: Array = []
	if ex.has("picture"):
		pictures.append(ex.picture)
	for ch: Variant in ex.get("choices", []):
		if ch is Dictionary and (ch as Dictionary).has("picture"):
			pictures.append(ch.picture)
	for p: Variant in pictures:
		if SchoolPicture.problem(p) != "":
			out.append("%s's picture: %s" % [ex.id, SchoolPicture.problem(p)])
	if ex.has("picture"):
		out.append_array(_table_cells(ex.picture, EXERCISE_W, str(ex.id)))
	return out


## A table picture's cells whose words must shrink below READABLE to fit their cell (SchoolPicture.table_font_size),
## measured with the game's font: the lesson card's picture is 560 px wide, an exercise's 580.
func _table_cells(picture: Variant, width: float, where: String) -> Array[String]:
	var out: Array[String] = []
	if not picture is Dictionary or str((picture as Dictionary).get("kind", "")) != "table":
		return out
	var rows: Array = picture.get("rows", [])
	var cols := 1
	for r: Variant in rows:
		cols = maxi(cols, (r as Array).size())
	var cell := minf((width - 2 * SchoolPicture.MARGIN) / cols, 190.0) - 6.0
	var font := ThemeDB.fallback_font
	for r: Variant in rows:
		for c: Variant in r:
			var fs := SchoolPicture.table_font_size(font, str(c), cell)
			if fs < READABLE:
				out.append("%s: the table cell '%s' shrinks to %d px to fit" % [where, c, fs])
	return out
