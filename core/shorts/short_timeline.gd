class_name ShortTimeline
extends RefCounted
## EasyCraft Shorts (owner #94, spec §5.12b): where every actor is, how big, turned, see-through and drawn, at any
## moment of its scene: a pure function of the time, so the player seeks, loops and snaps to any frame exactly (and
## a frame played to is the frame sought to). Moves (ShortRules.MOVES) apply in the order they start; a move that has
## not started yet changes nothing, a finished one holds its end. Entrances hide the actor until the first of them.
## Reduce motion (research A2): no overshoot, hop, throb or shake; a pop and a drop become a fade; moves still move.

const EASES: Array[String] = ["linear", "smooth", "out", "in", "back", "bounce", "elastic"]
const LIVELY: Array[String] = ["back", "bounce", "elastic"]
## A new scene's first moment: the scene before it fades away over it.
const TRANSITION := 0.25


## `p` (0..1) eased: linear, smooth (in and out), out (fast then gentle), in, back (overshoots a little, then settles:
## a pop), bounce (lands, bounces twice, rests: an arrival), elastic (springs past and back).
static func ease_value(kind: String, p: float) -> float:
	p = clampf(p, 0.0, 1.0)
	match kind:
		"linear":
			return p
		"out":
			return 1.0 - pow(1.0 - p, 3.0)
		"in":
			return p * p * p
		"back":
			var c1 := 1.70158
			return 1.0 + (c1 + 1.0) * pow(p - 1.0, 3.0) + c1 * pow(p - 1.0, 2.0)
		"bounce":
			return _bounce(p)
		"elastic":
			if p <= 0.0 or p >= 1.0:
				return p
			return pow(2.0, -10.0 * p) * sin((p * 10.0 - 0.75) * TAU / 3.0) + 1.0
	return 4.0 * p * p * p if p < 0.5 else 1.0 - pow(-2.0 * p + 2.0, 3.0) * 0.5


static func _bounce(p: float) -> float:
	const N := 7.5625
	const D := 2.75
	if p < 1.0 / D:
		return N * p * p
	if p < 2.0 / D:
		p -= 1.5 / D
		return N * p * p + 0.75
	if p < 2.5 / D:
		p -= 2.25 / D
		return N * p * p + 0.9375
	p -= 2.625 / D
	return N * p * p + 0.984375


## A move's seconds (its own, else ShortRules.DURATIONS).
static func duration(m: Dictionary) -> float:
	var kind := str(m.get("do", ""))
	var d: Variant = m.get("dur", ShortRules.DURATIONS.get(kind, 0.5))
	return maxf(float(d), 0.0) if typeof(d) in [TYPE_INT, TYPE_FLOAT] else float(ShortRules.DURATIONS.get(kind, 0.5))


## The actor's moves in the order they start (moves starting together keep their written order).
static func sorted_moves(actor: Dictionary) -> Array:
	var moves: Array = []
	var list: Variant = actor.get("moves", [])
	if list is Array:
		for m: Variant in list:
			if m is Dictionary and typeof((m as Dictionary).get("at")) in [TYPE_INT, TYPE_FLOAT]:
				moves.append(m)
	var order := range(moves.size())
	order.sort_custom(func(a: int, b: int) -> bool:
		var ta := float(moves[a].at)
		var tb := float(moves[b].at)
		return ta < tb or (ta == tb and a < b))
	var out: Array = []
	for i: int in order:
		out.append(moves[i])
	return out


## When the actor first shows: its first entrance's start (0 without one).
static func enters_at(actor: Dictionary) -> float:
	for m: Dictionary in sorted_moves(actor):
		if ShortRules.ENTRANCES.has(str(m.do)):
			return float(m.at)
	return 0.0


## The actor at `t` seconds into its scene: {visible, pos (stage units, its middle), scale, rot (radians), alpha
## (0..1), draw (0..1: how much of a line, a ring or a text is drawn), value (a count, a phase, a fill)}.
static func actor_state(actor: Dictionary, t: float, reduce_motion: bool = false) -> Dictionary:
	var pos := ShortRules.anchor(actor)
	var scale := _num(actor, "scale", 1.0)
	var rot := deg_to_rad(_num(actor, "rot", 0.0))
	var alpha := clampf(_num(actor, "alpha", 1.0), 0.0, 1.0)
	var value := _num(actor, "value", _num(actor, "from", 0.0))   # a count starts at its `from`
	var draw := 1.0
	var mul := 1.0          # pop, pulse, out: on top of the scale
	var shown := 1.0        # entrances' and out's see-through: on top of the alpha
	var offset := Vector2.ZERO
	var visible := true
	var moves := sorted_moves(actor)
	for m: Dictionary in moves:
		if ShortRules.ENTRANCES.has(str(m.do)):
			visible = t >= float(m.at)
			break
	for m: Dictionary in moves:
		if str(m.do) == "draw":
			draw = 0.0
			break
	for m: Dictionary in moves:
		var kind := str(m.do)
		var at := float(m.at)
		if t < at:
			continue
		var dur := duration(m)
		var p := 1.0 if dur <= 0.0 else clampf((t - at) / dur, 0.0, 1.0)
		var how := str(m.get("ease", ShortRules.MOVE_EASES.get(kind, "smooth")))
		if reduce_motion and LIVELY.has(how):
			how = "out"
		var e := ease_value(how, p)
		match kind:
			"pop":
				if reduce_motion:
					shown *= ease_value("out", p)
				else:
					mul *= e
					shown *= clampf(p / 0.3, 0.0, 1.0)
			"fade":
				alpha = lerpf(alpha, clampf(_num(m, "to", 1.0), 0.0, 1.0), e)
			"slide":
				pos = ShortRules.point(m.get("from")).lerp(pos, e)
				shown *= clampf(p / 0.2, 0.0, 1.0)
			"drop":
				if reduce_motion:
					shown *= ease_value("out", p)
				else:
					pos.y -= _num(m, "height", 240.0) * (1.0 - e)
					shown *= clampf(p / 0.15, 0.0, 1.0)
			"draw":
				draw = e
			"move":
				pos = pos.lerp(ShortRules.point(m.get("to")), e)
			"grow":
				scale = lerpf(scale, _num(m, "to", 1.0), e)
			"spin":
				rot += TAU * _num(m, "turns", 1.0) * e
			"bounce":
				if not reduce_motion and p < 1.0:
					offset.y -= _num(m, "height", 30.0) * absf(sin(p * PI * _num(m, "times", 2.0))) * (1.0 - p)
			"pulse":
				if not reduce_motion and p < 1.0:
					mul *= 1.0 + _num(m, "amount", 0.15) * absf(sin(p * PI * _num(m, "times", 1.0)))
			"shake":
				if not reduce_motion and p < 1.0:
					offset.x += _num(m, "amount", 8.0) * sin(p * TAU * _num(m, "times", 4.0)) * (1.0 - p)
			"orbit":
				pos = _orbit(pos, m, p * dur)
			"out":
				if reduce_motion:
					shown *= 1.0 - p
				else:
					mul *= 1.0 - ease_value("in", p)
					shown *= 1.0 - p
				if p >= 1.0:
					visible = false
			"value":
				value = lerpf(value, _num(m, "to", value), e)
	return {"visible": visible, "pos": pos + offset, "scale": scale * mul, "rot": rot,
		"alpha": clampf(alpha * shown, 0.0, 1.0), "draw": draw, "value": value}


## Round `around` (a circle, or an ellipse `squash` as tall as wide) at one turn a `period`; `dir` -1 turns the other
## way (on the screen, where y grows downwards, -1 is anticlockwise: the planets seen from above the Sun's north).
static func _orbit(pos: Vector2, m: Dictionary, elapsed: float) -> Vector2:
	var around := ShortRules.point(m.get("around"))
	var period := maxf(_num(m, "period", 1.0), 0.01)
	var squash := maxf(_num(m, "squash", 1.0), 0.01)
	var theta := signf(_num(m, "dir", 1.0)) * TAU * elapsed / period
	var rel := pos - around
	var flat := Vector2(rel.x, rel.y / squash)
	var r := flat.length()
	var phi := atan2(flat.y, flat.x) + theta
	return around + Vector2(cos(phi) * r, sin(phi) * r * squash)


# --- Scenes ---------------------------------------------------------------------------------------------------------

static func scenes(short: Dictionary) -> Array:
	var s: Variant = short.get("scenes", [])
	return s if s is Array else []


static func seconds_of(scene: Variant) -> float:
	if scene is Dictionary and typeof((scene as Dictionary).get("seconds")) in [TYPE_INT, TYPE_FLOAT]:
		return maxf(float(scene.seconds), 0.0)
	return 0.0


## The whole Short's seconds.
static func length(short: Dictionary) -> float:
	var total := 0.0
	for s: Variant in scenes(short):
		total += seconds_of(s)
	return total


## When scene `i` starts.
static func scene_start(short: Dictionary, i: int) -> float:
	var start := 0.0
	var list := scenes(short)
	for k in mini(i, list.size()):
		start += seconds_of(list[k])
	return start


## The scene at `t` (0 .. length; past the end, the last scene's end) and how far into it: {scene, local}.
static func at(short: Dictionary, t: float) -> Dictionary:
	var list := scenes(short)
	var start := 0.0
	for i in list.size():
		var s := seconds_of(list[i])
		if t < start + s or i == list.size() - 1:
			return {"scene": i, "local": clampf(t - start, 0.0, s)}
		start += s
	return {"scene": 0, "local": 0.0}


static func _num(d: Dictionary, key: String, default: float) -> float:
	var v: Variant = d.get(key, default)
	return float(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) else default
