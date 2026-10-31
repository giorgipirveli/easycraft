extends Node
## The steps of tools/real_builder_smoke.gd (owner #116, #117): one run per "track.mode" (flat, expert, vr), each a whole
## try through ToolRoomHost played by tools/real_builder_driver.gd, then its checks.

const Driver := preload("res://tools/real_builder_driver.gd")
const RUNS: Array[String] = ["little.flat", "middle.flat", "big.flat", "little.vr", "middle.vr", "big.vr", "little.expert",
	"middle.expert", "big.expert"]

var _fails := 0


func _ready() -> void:
	var runs := RUNS.duplicate()
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--runs="):
			runs.assign(a.trim_prefix("--runs=").split(","))
	Profile.data.settings.reduce_motion = true
	print("REAL_BUILDER_SMOKE start runs=%d" % runs.size())
	for r: String in runs:
		var parts := r.split(".")
		await _run(parts[0], parts[1] if parts.size() > 1 else "flat")
	print("REAL_BUILDER_SMOKE done runs=%d failed=%d" % [runs.size(), _fails])
	get_tree().quit(0 if _fails == 0 else 1)


func _run(track: String, mode: String) -> void:
	var start := Time.get_ticks_msec()
	var in_vr := mode == "vr"
	if in_vr:
		Vr.simulate(true)
		await get_tree().process_frame
	var parent := Node.new()
	add_child(parent)
	var host := ToolRoomHost.new()
	host.setup(RealBuilder.ID, track, mode == "expert", 7, "ge")
	var entries: Array = []
	host.tools_used.connect(func(e: Array, _x: bool) -> void: entries.append_array(e))
	host.open(parent)
	host.set_process(false)
	var site := host.room as RealBuilderSite
	var d := Driver.new(host, in_vr)
	var ok := d.play()
	var why: Array[String] = []
	if not ok:
		why.append("stuck at %s" % (host.run.current().get("id", "?") if not host.run.finished else "the end"))
	elif int(host.outcome.get("hints", -1)) != 0:
		why.append("%d hints" % int(host.outcome.hints))
	why.append_array(_build_problems(site, track))
	var book := ToolData.new()
	book.record(entries, mode == "expert")
	for t: String in ["trowel", "spirit_level", "hard_hat", "gloves"]:
		if not book.has_stamp(t, LifeData.SELF):
			why.append("no By myself stamp for the " + t)
	var secs := (Time.get_ticks_msec() - start) / 1000.0
	var draws := 0   # the room's meshes shown at the end (each about one draw: the Quest's budget is ~100 in play)
	for g: Node in site.find_children("*", "GeometryInstance3D", true, false):
		if (g as GeometryInstance3D).is_visible_in_tree():
			draws += 1
	if why.is_empty():
		print("REAL_BUILDER_SMOKE %s.%s PASS steps=%d frames=%d bricks=%d tools=%d meshes=%d %.1fs" % [track, mode,
			host.run.steps.size(), d.ticks, site.visible_pieces().size(), book.can_use(), draws, secs])
	else:
		_fails += 1
		print("REAL_BUILDER_SMOKE %s.%s FAIL %s (steps done: %s)" % [track, mode, "; ".join(why), ",".join(d.log)])
	if is_instance_valid(host) and not host.closed:
		host.close()
	parent.queue_free()
	if in_vr:
		Vr.simulate(false)
	await get_tree().process_frame
	await get_tree().process_frame


## The build is what the track promises: the wall in bond; the shed's and the house's walls whole, lintels, roof.
func _build_problems(site: RealBuilderSite, track: String) -> Array[String]:
	var out: Array[String] = []
	var pieces := site.visible_pieces()
	if not BrickBond.straight_joints(pieces).is_empty():
		out.append("straight joints in the walls")
	if not BrickBond.floating({"bricks": pieces, "lintels": site.plan.lintels, "runs": site.plan.runs,
			"unit": site.plan.unit}).is_empty():
		out.append("a brick with nothing under it")
	if track == "little":
		if pieces.size() != 10:
			out.append("the wall has %d blocks, not 10" % pieces.size())
		return out
	if pieces.size() != (site.plan.bricks as Array).size():
		out.append("%d of %d bricks laid" % [pieces.size(), (site.plan.bricks as Array).size()])
	if site.lintels_laid.size() != (site.plan.lintels as Array).size():
		out.append("%d of %d lintels" % [site.lintels_laid.size(), (site.plan.lintels as Array).size()])
	if site.rafters_laid != site.rafter_count or site.tiles_laid != site.tile_rows:
		out.append("the roof: %d of %d rafters, %d of %d rows of tiles" % [site.rafters_laid, site.rafter_count,
			site.tiles_laid, site.tile_rows])
	return out
