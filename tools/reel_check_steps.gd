extends Node
## The steps of tools/reel_check.gd: ShortCheck's and ReelCheck's findings on each Short asked for.


func _ready() -> void:
	var ids: Array[String] = []
	for a in OS.get_cmdline_user_args():
		if a == "--all":
			ids.append_array(ShortLibrary.hand_ids())
		elif a.begins_with("--short="):
			ids.append_array(a.trim_prefix("--short=").split(",", false))
	var bad := 0
	for id in ids:
		var s := ShortLibrary.get_short(id)
		if s.is_empty():
			print("CHECK %s missing" % id)
			bad += 1
			continue
		var found: Array[String] = ShortCheck.problems(s)
		found.append_array(ReelCheck.problems(s))
		var cells := 0
		if s.get("stage") is Dictionary:
			for m: Variant in s.stage.get("models", []):
				if m is Dictionary and str(m.get("model")) == "blocks" and not m.has("build"):
					cells += StudioShapes.cells(m).size()
		print("CHECK %s %.1f s, %d cells: %s" % [id, ShortTimeline.length(s), cells, "ok" if found.is_empty() else ""])
		for f in found:
			print("CHECK %s   %s" % [id, f])
		bad += found.size()
	get_tree().quit(1 if bad > 0 else 0)
