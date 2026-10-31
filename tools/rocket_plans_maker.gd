extends Node
## The work of tools/make_rocket_plans.gd (owner #98; run that one): every mission in MissionRules.MISSIONS and every
## crew of 1 to RocketPlan.MAX_CREW. For each it searches the cheapest rockets of 2 to 8 stages
## (tools/rocket_plans_search.gd, the check's own sums), lays each one out (RocketPlan.layout) and keeps the cheapest
## that the REAL RocketCheck passes with every part bought, standing in one piece on the pad inside the 9 × 9 square and
## RocketPlan.MAX_LAYERS, at least RocketPlan.MARGIN km/s over the need. Then it writes the table between the BEGIN / END
## PLANS lines of core/rules/rocket_plan.gd and prints it (mission, crew, parts, gold, the margin, layers, stages).

const OUT := "res://core/rules/rocket_plan.gd"
const BEGIN := "# BEGIN PLANS"
const END := "# END PLANS"


func _ready() -> void:
	_run()


func quit(code: int) -> void:
	get_tree().quit(code)


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var dry := args.has("--dry")
	var prices := {}
	var at := args.find("--prices")
	if at >= 0 and at + 1 < args.size():
		for pair: String in args[at + 1].split(","):
			var kv := pair.split("=")
			if kv.size() == 2 and kv[0].is_valid_int() and kv[1].is_valid_int():
				prices[int(kv[0])] = int(kv[1])
	var search: RefCounted = load("res://tools/rocket_plans_search.gd").new()
	search.set("prices", prices)
	var start := Time.get_ticks_msec()
	var rows: Array[String] = []
	var table: Array[String] = []
	var none: Array[String] = []
	for m: Dictionary in MissionRules.MISSIONS:
		var per_crew: Array[String] = []
		for crew in range(1, RocketPlan.MAX_CREW + 1):
			var t0 := Time.get_ticks_msec()
			var found := {}
			for cand: Dictionary in search.call("solve", m, crew):
				var cells := RocketPlan.layout(cand.stages, m, crew)
				if cells.is_empty():
					continue
				var why := _fails(cells, m, crew)
				if why != "":
					print("PLANS %s crew %d: a %d-stage plan fails: %s" % [m.id, crew, (cand.stages as Array).size(), why])
					continue
				found = cand
				found.cells = cells
				break
			if found.is_empty():
				none.append("%s crew %d" % [m.id, crew])
				per_crew.append("[]")
				rows.append("| %s | %d | — | — | — | — | — | no plan |" % [m.id, crew])
				print("PLANS %-8s crew %d: NO PLAN (%d ms)" % [m.id, crew, Time.get_ticks_msec() - t0])
				continue
			var cells: Dictionary = found.cells
			var r := RocketCheck.check(cells, m, crew, RocketParts.count(cells))
			var gold := 0
			for id: int in RocketParts.count(cells):
				gold += int(search.call("price", id)) * int(RocketParts.count(cells)[id])
			var st: Array = found.stages
			var words: Array[String] = []
			for s: Array in st:
				words.append("%d%s+%dT" % [int(s[1]), "E" if int(s[0]) == BlockIds.ROCKET_ENGINE else "V", int(s[2])])
			var layers := RocketPlan._height(cells)
			rows.append("| %s | %d | %d | %d | %.2f | %d | %d | %s |" % [m.id, crew, cells.size(), gold,
				float(r.dv) - float(r.need), layers, st.size(), " / ".join(words)])
			print("PLANS %-8s crew %d: %3d parts, %5d gold, +%.3f km/s, %2d layers, %d stages: %s (%d ms)" % [m.id, crew,
				cells.size(), gold, float(r.dv) - float(r.need), layers, st.size(), " / ".join(words),
				Time.get_ticks_msec() - t0])
			var parts: Array[String] = []
			for s: Array in st:
				parts.append("[%s, %d, %d]" % ["E" if int(s[0]) == BlockIds.ROCKET_ENGINE else "V", int(s[1]), int(s[2])])
			per_crew.append("[%s]" % ", ".join(parts))
		table.append("\t&\"%s\": [\n\t\t%s,\n\t]," % [m.id, ",\n\t\t".join(per_crew)])
	print("PLANS table (for the notes):")
	print("| Mission | Crew | Parts | Gold | Over the need (km/s) | Layers | Stages | Stages from the bottom |")
	print("|---|---|---|---|---|---|---|---|")
	for row in rows:
		print(row)
	print("PLANS no plan: %s" % (", ".join(none) if not none.is_empty() else "none"))
	print("PLANS took %.1f s" % ((Time.get_ticks_msec() - start) / 1000.0))
	if dry:
		print("PLANS dry run: nothing written")
		quit(0)
		return
	var text := FileAccess.get_file_as_string(OUT)
	var a := text.find(BEGIN)
	var b := text.find(END)
	if a < 0 or b < a:
		push_error("PLANS: no %s / %s lines in %s" % [BEGIN, END, OUT])
		quit(1)
		return
	var head := text.substr(0, text.find("\n", a) + 1)
	var body := "## mission id -> [crew 1, crew 2, crew 3, crew 4]: each the stages from the bottom, [engine, engines, tanks], or [] for\n" \
		+ "## no plan.\nconst PLANS := {\n%s\n}\n" % "\n".join(table)
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(head + body + text.substr(b))
	f.close()
	print("PLANS written to %s" % OUT)
	quit(0)


## Why the real check refuses this plan ("" = it passes every rule).
func _fails(cells: Dictionary, m: Dictionary, crew: int) -> String:
	var r := RocketCheck.check(cells, m, crew, RocketParts.count(cells))
	for l: Dictionary in r.lines:
		if not bool(l.ok):
			return str(l.text)
	if float(r.dv) - float(r.need) < RocketPlan.MARGIN:
		return "only %.3f km/s over the need" % (float(r.dv) - float(r.need))
	if (r.cells as Dictionary).size() != cells.size():
		return "not one piece"
	for p: Vector3i in cells:
		if not RocketCheck.in_square(p):
			return "%s off the square" % p
	if RocketPlan._height(cells) > RocketPlan.MAX_LAYERS:
		return "%d layers" % RocketPlan._height(cells)
	return ""
