extends SceneTree
## Owner #94 (the lesson-quality audit's Godot half): every written unit's data checked in seconds, without the
## generators' long run: the loader's problems (Curriculum.content_problems), every lesson card's size, picture and
## sound, and every hand-written exercise's own answer by its own checker (and the other choices and the other truth
## not right), its pictures and its choices' pictures. Run it after editing units, before the School's tests:
##   godot --headless --path . --script res://tools/school_check.gd [-- g4.maths.angles g6.english.poetry …]
## With unit ids, only those; without, every written unit of every grade. Prints SCHOOL_CHECK lines and a summary, and
## exits 1 when something is wrong (tests/unit/test_school_content.gd stays the authority). The steps are a Node
## (tools/school_check_steps.gd) so the School's classes compile after the autoloads.


func _initialize() -> void:
	var steps: Node = load("res://tools/school_check_steps.gd").new()
	root.add_child.call_deferred(steps)
