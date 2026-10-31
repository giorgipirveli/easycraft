extends SceneTree
## Owner #133, #134 (docs/design/future-lessons.md §6): the School's reading debt, counted by the game's own rules
## (PlayReadless): for every grade and subject, the written units, the units that are games (their page offers PLAY:
## enough of them plays without reading), the hand-written challenges that play and those that need reading (and why),
## the generators, and the Book's cards and words. tools/play_audit.py prints the same counts for the hand-written part
## (test_play_debt.gd keeps the two equal).
##   godot --headless --path . --script res://tools/play_debt.gd            # a table per grade and subject
##   godot --headless --path . --script res://tools/play_debt.gd -- --units # every unit's row
## Prints PLAY_DEBT lines.


func _initialize() -> void:
	var every := OS.get_cmdline_user_args().has("--units")
	var total := _zero()
	for g in Curriculum.grades():
		var grade_sum := _zero()
		for s: Dictionary in Curriculum.subjects(g):
			var sum := _zero()
			for u: Dictionary in Curriculum.units(g, str(s.id)):
				var id := str(u.id)
				if not Curriculum.has_content(id):
					continue
				var c := Curriculum.content(id)
				var d := PlayReadless.debt(c)
				var plays := PlayReadless.unit_plays(c)
				_add(sum, d, plays)
				if every:
					print("PLAY_DEBT unit %s plays=%s playable=%d reading=%d gens=%d/%d cards=%d words=%d why=%s" % [id,
						plays, d.playable, d.reading, d.gens_playable, d.gens_playable + d.gens_reading, d.cards,
						d.card_words, JSON.stringify(d.why)])
			if int(sum.units) > 0:
				print(_line("g%d %s" % [g, s.id], sum))
			_merge(grade_sum, sum)
		print(_line("g%d all" % g, grade_sum))
		_merge(total, grade_sum)
	print(_line("all", total))
	quit(0)


func _zero() -> Dictionary:
	return {"units": 0, "games": 0, "playable": 0, "reading": 0, "gens_playable": 0, "gens_reading": 0, "cards": 0,
		"card_words": 0, "why": {}}


func _add(sum: Dictionary, d: Dictionary, plays: bool) -> void:
	sum.units += 1
	sum.games += 1 if plays else 0
	for k in ["playable", "reading", "gens_playable", "gens_reading", "cards", "card_words"]:
		sum[k] += int(d[k])
	for r: String in d.why:
		sum.why[r] = int(sum.why.get(r, 0)) + int(d.why[r])


func _merge(into: Dictionary, sum: Dictionary) -> void:
	for k in ["units", "games", "playable", "reading", "gens_playable", "gens_reading", "cards", "card_words"]:
		into[k] += int(sum[k])
	for r: String in sum.why:
		into.why[r] = int(into.why.get(r, 0)) + int(sum.why[r])


func _line(what: String, s: Dictionary) -> String:
	var why := PackedStringArray()
	for r in PlayReadless.REASONS:
		if int(s.why.get(r, 0)) > 0:
			why.append("%s %d" % [r, int(s.why[r])])
	return "PLAY_DEBT %s units=%d games=%d playable=%d reading=%d gens=%d/%d cards=%d card_words=%d | %s" % [what,
		s.units, s.games, s.playable, s.reading, s.gens_playable, s.gens_playable + s.gens_reading, s.cards,
		s.card_words, ", ".join(why)]
