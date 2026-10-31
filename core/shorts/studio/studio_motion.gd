class_name StudioMotion
extends RefCounted
## The Reel Studio (owner #96, spec §5.12b): where a 3D stage's model is, turned, how big, at any moment: a pure function
## of the time, like ShortTimeline for the 2D actors (a seek shows the frame playing reaches). Moves (StudioRules.MOVES)
## apply in the order they start; one not started changes nothing; a finished one holds its end. Entrances (appear,
## pop, drop) hide the model until the first of them.
## - A rocket's `stage` move lets its lowest stage still attached go at that moment: the stage keeps the rocket's speed,
##   gravity pulls it back and it tumbles, so from a camera riding with the rocket it falls away behind (dropped()).
## - An avatar's `emote` plays EmotePoses' emote from that moment (the pose is EmotePoses.sample at its own time); its
##   `legs` walk it (legs and arms swing, `steps` a second; or its arms `pull` a rope, `push`, or hold `up`, leaning back
##   `lean` degrees): walk_pose.
## - Round 2 (learning reels): a model with `on` rides on another model (world(): the other's place, turn and pop, not
##   its builder's size or stretch, then its own); `stretch` [x, y, z] scales it along its own axes, and a `grow` with an
##   `axis` stretches it one way (a rope winding up).

## A dropped stage: gravity (m/s², a film's: faster than real, so it reads in a few seconds), its drift to the side and
## how fast it tumbles; after FALL_SECONDS it is gone.
const FALL_G := 6.0
const DRIFT := Vector3(1.6, 0.0, 0.9)
const TUMBLE := 0.8
const TUMBLE_AXIS := Vector3(0.35, 0.1, 1.0)
const FALL_SECONDS := 9.0
## A rocket's speed is read over this long (seconds) before a stage lets go.
const SPEED_WINDOW := 0.1
## A walk: steps a second by default, how far the legs and arms swing (rad), and the arms' poses (EmotePoses' pitch).
const STEPS := 2.0
const LEG_SWING := 0.55
const ARM_SWING := 0.45
const ARM_POSES := {"pull": 1.15, "push": 1.5, "up": 2.9}


## The model at `t`: {visible, pos, rot (radians, Euler), scale, stretch (its own axes), emote ({} or {name, t}),
## walk ({} or {phase, arms, lean})}.
static func state(model: Dictionary, t: float) -> Dictionary:
	var pos := StudioRules.vec(model.get("at"))
	var rot := _degrees(model.get("turn"))
	var scale := 1.0
	var stretch := StudioRules.vec(model.get("stretch")) if StudioRules.is_vec(model.get("stretch")) else Vector3.ONE
	var mul := 1.0
	var visible := true
	var emote := {}
	var walk := {}
	var moves := sorted_moves(model)
	for m: Dictionary in moves:   # hidden before its first entrance, unless it leaves (out) before that
		if StudioRules.ENTRANCES.has(str(m.do)):
			visible = false
			break
		if str(m.do) == "out":
			break
	for m: Dictionary in moves:
		var kind := str(m.do)
		var at := float(m.at)
		if t < at:
			continue
		if StudioRules.ENTRANCES.has(kind):
			visible = true   # back again after an out, too, and at its full size (an out shrank it to nothing)
			mul = 1.0
		var dur := duration(m)
		var p := 1.0 if dur <= 0.0 else clampf((t - at) / dur, 0.0, 1.0)
		var e := ease_of(str(m.get("ease", StudioRules.MOVE_EASES.get(kind, "smooth"))), p)
		match kind:
			"pop":
				mul *= e
			"drop":
				pos.y += StudioRules.num(m, "height", 12.0) * (1.0 - e)
			"out":
				mul *= 1.0 - e
				if p >= 1.0:
					visible = false
			"move":
				pos = pos.lerp(StudioRules.vec(m.get("to")), e)
			"turn":
				rot = rot.lerp(_degrees(m.get("to")), e)
			"spin":
				var axis := _axis(str(m.get("axis", "y")))
				var turns := StudioRules.num(m, "rate", 0.0) * _elapsed(m, t) if m.has("rate") \
					else StudioRules.num(m, "turns", 1.0) * e
				rot += axis * TAU * turns
			"orbit":
				pos = _orbit(pos, m, _elapsed(m, t))
			"grow":
				var axis := str(m.get("axis", ""))
				if StudioRules.AXES.has(axis):
					var k := StudioRules.AXES.find(axis)
					stretch[k] = lerpf(stretch[k], StudioRules.num(m, "to", 1.0), e)
				else:
					scale = lerpf(scale, StudioRules.num(m, "to", 1.0), e)
			"legs":
				if p < 1.0:
					walk = {"phase": (t - at) * StudioRules.num(m, "steps", STEPS), "arms": str(m.get("arms", "swing")),
						"lean": StudioRules.num(m, "lean", 0.0)}
				else:
					walk = {}
			"emote":
				var name := StringName(str(m.get("emote", "wave")))
				var since := t - at
				if not EmotePoses.has(name) or not EmotePoses.finished(name, since):
					emote = {"name": name, "t": since}
				else:
					emote = {}
	return {"visible": visible, "pos": pos, "rot": rot, "scale": scale * mul, "stretch": stretch, "emote": emote,
		"walk": walk}


## A walk's pose at its moment (EmotePoses' pose dictionary): the legs swing opposite ways `phase` steps in (a step is
## half a stride), the arms swing against them, or reach forward to pull a rope (`pull`), push ahead or hold up; the body
## leans back `lean` degrees. {} walks nowhere: the rest pose.
static func walk_pose(walk: Dictionary) -> Dictionary:
	var p := EmotePoses.rest()
	if walk.is_empty():
		return p
	var swing := sin(float(walk.get("phase", 0.0)) * PI)
	p.l_leg = swing * LEG_SWING
	p.r_leg = -swing * LEG_SWING
	var arms := str(walk.get("arms", "swing"))
	if ARM_POSES.has(arms):
		var pitch := float(ARM_POSES[arms])
		p.l_arm = Vector2(pitch, 0.08)
		p.r_arm = Vector2(pitch, 0.08)
	else:
		p.l_arm = Vector2(-swing * ARM_SWING, 0.0)
		p.r_arm = Vector2(swing * ARM_SWING, 0.0)
	p.lean = deg_to_rad(float(walk.get("lean", 0.0)))
	return p


## `p` eased: ShortTimeline's eases, and the studio's own "accel" (a steady push: p², a rocket leaving its pad, faster
## off the mark than "in" and speeding up evenly).
static func ease_of(how: String, p: float) -> float:
	if how == "accel":
		var c := clampf(p, 0.0, 1.0)
		return c * c
	return ShortTimeline.ease_value(how, p)


## The model's transform at `t` (its size is the builder's; this is where it is, turned, scaled and stretched), in the
## space of the model it rides on (world() for the stage's).
static func transform(model: Dictionary, t: float) -> Transform3D:
	var s := state(model, t)
	return Transform3D(basis_of(s, 1.0), s.pos)


## A state's basis with a builder's `size`: turned, then scaled along its own axes (a stretched rope stays a rope as it
## turns).
static func basis_of(s: Dictionary, size: float) -> Basis:
	var k := maxf(float(s.scale) * size, 0.0001)
	var st: Vector3 = s.get("stretch", Vector3.ONE)
	return Basis.from_euler(s.rot) * Basis.from_scale(Vector3(maxf(st.x, 0.0001), maxf(st.y, 0.0001), maxf(st.z, 0.0001)) * k)


## The frame a model's own place is in at `t`: the world's, or (with `on`) its model's world place, turn and pop (not its
## builder's size or stretch: a crate on a long thin plank is not squashed).
static func frame(stage: Dictionary, model: Dictionary, t: float, depth: int = 0) -> Transform3D:
	var on := str(model.get("on", ""))
	if on == "" or depth > StudioRules.MAX_RIDE:
		return Transform3D.IDENTITY
	var up := StudioRules.model(stage, on)
	if up.is_empty() or up == model:
		return Transform3D.IDENTITY
	var s := state(up, t)
	var own := Transform3D(Basis.from_euler(s.rot).scaled(Vector3.ONE * maxf(float(s.scale), 0.0001)), s.pos)
	return frame(stage, up, t, depth + 1) * own


## The model's place in the stage at `t` (riding on its model, if any).
static func world(stage: Dictionary, model: Dictionary, t: float) -> Transform3D:
	return frame(stage, model, t) * transform(model, t)


## A rope (round 2) at `t`: {origin: its `from` model's place, dir (normalised, toward its `to`), length}: a straight
## line between two models wherever they go (a pulley's rope, a hauler's rope to a sledge); `from_at` and `to_at` are
## points in those models' own frames (a wheel's rim on its axle, a load's top, a hauler's hands).
static func rope(stage: Dictionary, model: Dictionary, t: float) -> Dictionary:
	var a := world(stage, StudioRules.model(stage, str(model.get("from", ""))), t) * StudioRules.vec(model.get("from_at"))
	var b := world(stage, StudioRules.model(stage, str(model.get("to", ""))), t) * StudioRules.vec(model.get("to_at"))
	var d := b - a
	return {"origin": a, "dir": d.normalized() if d.length() > 0.0001 else Vector3.UP, "length": d.length()}


## True when the model shows at `t`: its own entrances and exits, and the model it rides on showing.
static func shown(stage: Dictionary, model: Dictionary, t: float, depth: int = 0) -> bool:
	if not bool(state(model, t).visible):
		return false
	var on := str(model.get("on", ""))
	if on == "" or depth > StudioRules.MAX_RIDE:
		return true
	var up := StudioRules.model(stage, on)
	return up.is_empty() or up == model or shown(stage, up, t, depth + 1)


## A move's seconds (its own, else StudioRules.DURATIONS).
static func duration(m: Dictionary) -> float:
	return maxf(StudioRules.num(m, "dur", float(StudioRules.DURATIONS.get(str(m.get("do", "")), 0.5))), 0.0)


## The model's moves in the order they start (moves starting together keep their written order).
static func sorted_moves(model: Dictionary) -> Array:
	var moves: Array = []
	var list: Variant = model.get("moves", [])
	var in_order := true
	var last := -INF
	if list is Array:
		for m: Variant in list:
			if m is Dictionary and typeof((m as Dictionary).get("at")) in [TYPE_INT, TYPE_FLOAT]:
				moves.append(m)
				in_order = in_order and float(m.at) >= last
				last = float(m.at)
	if in_order:   # as written, usually: no sort (a phone poses every model every frame)
		return moves
	var order := range(moves.size())
	order.sort_custom(func(a: int, b: int) -> bool:
		var ta := float(moves[a].at)
		var tb := float(moves[b].at)
		return ta < tb or (ta == tb and a < b))
	var out: Array = []
	for i: int in order:
		out.append(moves[i])
	return out


# --- Rockets: stages letting go -------------------------------------------------------------------------------------

## When each stage lets go ({stage index: seconds}), from the rocket's `stage` moves (stage 0 is the bottom one).
static func stage_times(model: Dictionary) -> Dictionary:
	var out := {}
	for m: Dictionary in sorted_moves(model):
		if str(m.do) == "stage":
			out[int(StudioRules.num(m, "stage", out.size()))] = float(m.at)
	return out


## How many stages have let go by `t`.
static func stages_dropped(model: Dictionary, t: float) -> int:
	var n := 0
	var times := stage_times(model)
	for i: int in times:
		if t >= float(times[i]):
			n += 1
	return n


## Stage `stage`'s transform at `t` once it has let go (the rocket's own before): it keeps the rocket's speed at the
## moment it let go, falls back under gravity, drifts aside and tumbles.
static func dropped(model: Dictionary, stage: int, t: float) -> Transform3D:
	var times := stage_times(model)
	if not times.has(stage) or t < float(times[stage]):
		return transform(model, t)
	var at := float(times[stage])
	var start := transform(model, at)
	var speed := (start.origin - transform(model, at - SPEED_WINDOW).origin) / SPEED_WINDOW
	var age := t - at
	var pos := start.origin + speed * age + Vector3(0, -0.5 * FALL_G * age * age, 0) \
		+ start.basis.orthonormalized() * DRIFT * age
	var tumble := Basis(TUMBLE_AXIS.normalized(), TUMBLE * age * age * 0.5 + 0.15 * age)
	return Transform3D(start.basis * tumble, pos)


## True while stage `stage` is still to be seen after letting go.
static func dropped_shows(model: Dictionary, stage: int, t: float) -> bool:
	var times := stage_times(model)
	return not times.has(stage) or t - float(times[stage]) < FALL_SECONDS


static func _elapsed(m: Dictionary, t: float) -> float:
	var since := t - float(m.at)
	return minf(since, float(m.dur)) if typeof(m.get("dur")) in [TYPE_INT, TYPE_FLOAT] else since


## Round `around` on a flat circle (x, z) at one turn a `period`; `dir` 1 turns anticlockwise seen from above (the
## planets seen from above the Sun's north: +x toward -z), -1 the other way.
static func _orbit(pos: Vector3, m: Dictionary, elapsed: float) -> Vector3:
	var around := StudioRules.vec(m.get("around"))
	var period := maxf(StudioRules.num(m, "period", 10.0), 0.01)
	var theta := signf(StudioRules.num(m, "dir", 1.0)) * TAU * elapsed / period
	var rel := pos - around
	var turned := Vector2(rel.x, rel.z).rotated(-theta)
	return around + Vector3(turned.x, rel.y, turned.y)


static func _degrees(v: Variant) -> Vector3:
	var d := StudioRules.vec(v)
	return Vector3(deg_to_rad(d.x), deg_to_rad(d.y), deg_to_rad(d.z))


static func _axis(name: String) -> Vector3:
	match name:
		"x":
			return Vector3.RIGHT
		"z":
			return Vector3.BACK
	return Vector3.UP
