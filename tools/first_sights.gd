extends Node
## First sights (2026-09-30, the frame spikes: docs/devlog/parts/frame-spikes.md): where the OpenGL renderer (a browser,
## the emulator) compiles a material's shader the first time it is drawn, a draw the shader warm-up has not reached yet
## costs a phone a long frame (~0.1-1.5 s) at its first sight. This node looks every EVERY seconds at what the game's
## camera sees (a node visible in the tree, in the camera's frustum and far plane, within its visibility range; the
## warm-up's own little world left out) and prints each draw (ShaderWarmup's census keys) the first time it is seen in
## the run, with its tier in the census (FIRST, WORLD, SOON, LATER, or NEW: not in the census at all), so a probe run
## says which first sights would compile in play and when. Used by tools/frame_probe_steps.gd (--sights).
## Headless: nothing is drawn, so it reads the nodes; the blocks (the terrain draws them itself) are the warm-up's first
## tier anyway.

const EVERY := 0.25
const TIER_NAMES := ["FIRST", "WORLD", "SOON", "LATER"]

## (text) -> void: where the lines go (print by default).
var out: Callable = func(line: String) -> void: print(line)
## () -> String: the phase (and anything else) to say with each first sight.
var context: Callable = func() -> String: return ""
## The style the census tiers are read in.
var style := "blocky"
## Every first sight: [{key, tier ("NEW" when not in the census), at, context}].
var sights: Array[Dictionary] = []

var _seen := {}
var _census := {}   # key -> census entry
var _t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for d: Dictionary in ShaderWarmup.census_draws():
		_census[census_key(d)] = d


## A census entry's key without its notes (the key ShaderWarmup gives a draw).
static func census_key(d: Dictionary) -> String:
	var e := d.duplicate()
	for note: String in ["styles", "phases", "shown", "at"]:
		e.erase(note)
	return ShaderWarmup.key(e)


func _process(delta: float) -> void:
	_t -= delta
	if _t > 0.0:
		return
	_t = EVERY
	look()


## One look at what the camera sees: prints (and keeps) the draws never seen before.
func look() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var planes := cam.get_frustum()
	var lamps: Array[OmniLight3D] = []   # lit by one, a material draws with another shader (the warm-up's lantern draws)
	for n: Node in get_tree().root.find_children("*", "OmniLight3D", true, false):
		var l := n as OmniLight3D
		if l.is_visible_in_tree() and l.light_energy > 0.0 and not l.is_in_group(ShaderWarmup.GROUP) \
				and not ShaderWarmup._in_own_world(l, get_tree().root):
			lamps.append(l)
	for n: Node in get_tree().root.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if g.is_in_group(ShaderWarmup.GROUP) or not g.is_visible_in_tree() or not on_screen(g, cam, planes):
			continue
		if ShaderWarmup._in_own_world(g, get_tree().root):
			continue
		var lit := lit_by(g, lamps)
		for d: Dictionary in ShaderWarmup._draws(g):
			var k := ShaderWarmup.key(d)
			var seen_as := k + (" lit" if lit else "")
			if _seen.has(seen_as):
				continue
			_seen[seen_as] = true
			var entry: Variant = _census.get(k)
			var tier: String = "NEW" if entry == null else TIER_NAMES[ShaderWarmup.tier(entry, style)]
			if lit:
				tier += " lit"
			var at := _where(g)
			var said := str(context.call())
			var warm := warm_by_now(entry, lit, Game.universe, style)
			sights.append({"key": k, "tier": tier, "lit": lit, "at": at, "context": said, "warm_before": warm[0],
				"warm_after": warm[1]})
			out.call("PROBE sight %s %s (a quick child's warm-up: before %s, now %s): %s at %s" % [said, tier,
				"warm" if warm[0] else "COMPILES", "warm" if warm[1] else "COMPILES", k.left(220), at])


## For a child who went straight from the menu to this world (the lead's autopilot runs; a returning child's
## CONTINUE): whether the warm-up had drawn a draw by the time the world's loading card lifted, [before, now]. Before
## the frame spikes' fix a card waited for the first world's part only (FIRST, WORLD); now for what this world shows
## round its landing (ShaderWarmup.world_part). The rest (SOON, LATER, the lanterns) waits for an idle menu or a card.
static func warm_by_now(entry: Variant, lit: bool, u: int, style: String) -> Array[bool]:
	if entry == null:
		return [false, false] as Array[bool]
	var d: Dictionary = entry
	var t := ShaderWarmup.tier(d, style)
	var at := str(d.get("at", ""))
	var look: bool = d.has("material") and not d.get("instanced", false) \
		and (ShaderWarmup.player_look_keys().has(ShaderWarmup.key(d.material)) or d.get("skinned", false))
	var e := {"lit": lit, "draw": {"tier": t, "shown_in": d.get("shown", []), "player_look": look,
		"feedback": ShaderWarmup.PLAYER_FEEDBACK.any(func(s: String) -> bool: return at.ends_with(s))}}
	return [not lit and t <= ShaderWarmup.WORLD, ShaderWarmup.in_world_part(e, u)] as Array[bool]


## Per phase (the context's first word): how many first sights compiled in it, before the fix and now.
func summary() -> Array[String]:
	var by := {}
	var order: Array[String] = []
	for s: Dictionary in sights:
		var ph := str(s.context).get_slice(" ", 0)
		if not by.has(ph):
			by[ph] = [0, 0, 0]
			order.append(ph)
		by[ph][0] += 1
		by[ph][1] += 0 if s.warm_before else 1
		by[ph][2] += 0 if s.warm_after else 1
	var lines: Array[String] = []
	for ph in order:
		lines.append("PROBE sights %-22s first sights %2d, compiling before %2d, now %2d" % [ph, by[ph][0], by[ph][1],
			by[ph][2]])
	return lines


## Whether `g` is drawn by `cam`: its box in the frustum (`planes`: Camera3D.get_frustum, normals out) and within the far
## plane and its visibility range.
static func on_screen(g: GeometryInstance3D, cam: Camera3D, planes: Array[Plane]) -> bool:
	var box := g.global_transform * g.get_aabb()
	var d := box.get_center().distance_to(cam.global_position)
	if g.visibility_range_end > 0.0 and d > g.visibility_range_end + g.visibility_range_end_margin:
		return false
	if g.visibility_range_begin > 0.0 and d < g.visibility_range_begin:
		return false
	if d - box.size.length() * 0.5 > cam.far:
		return false
	for p: Plane in planes:
		var outside := true
		for i in 8:
			if not p.is_point_over(box.get_endpoint(i)):
				outside = false
				break
		if outside:
			return false
	return true


## Whether a lamp's light reaches `g`'s box (its range from the box's nearest point).
static func lit_by(g: GeometryInstance3D, lamps: Array[OmniLight3D]) -> bool:
	var box := g.global_transform * g.get_aabb()
	for l in lamps:
		var at := l.global_position
		var nearest := at.clamp(box.position, box.end)
		if nearest.distance_to(at) <= l.omni_range:
			return true
	return false


static func _where(n: Node) -> String:
	var parts := str(n.get_path()).split("/", false)
	var script := ""
	var p := n
	while p and script == "":
		var s: Script = p.get_script()
		script = s.resource_path.get_file() if s else ""
		p = p.get_parent()
	return "%s (%s)" % ["/".join(parts.slice(maxi(parts.size() - 4, 0))), script]
