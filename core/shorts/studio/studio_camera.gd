class_name StudioCamera
extends RefCounted
## The Reel Studio (owner #96, spec §5.12b): a stage's camera at any moment, a pure function of the time (so a seek
## shows the frame playing reaches). Keys [{at, pos, look, fov?, roll?, ease?, path?, turns?, cut?, follow?,
## shake?}]:
## - between two keys the camera eases (the later key's `ease`, "smooth" by default): a **dolly** (pos moves toward or
##   away), a **crane** (pos rises or falls), a **push-in** (fov narrows or pos nears the look) are keys like any other;
## - `path: "orbit"` swings round the look point (its angle, distance and height eased) instead of a straight line;
##   `turns` adds whole turns (negative: the other way);
## - `cut: true` holds the key before until this one's moment, then jumps (a new shot);
## - `follow: <model id>`: the key's pos and look are from that model's place at that moment (riding with a rocket);
## - `aim: <model id>`: the key's look is from that model's place (the Moon kept in the middle as it goes round);
## - `shake: <metres>` from this key on (0 stops it): a rumble, the same at the same moment;
## - `roll: <degrees>` turns the picture round the view (a quarter turn stands a tilted orbit up in a tall frame).
## Before the first key the camera holds it, after the last it holds the last.

const DEFAULT_POS := Vector3(0, 3, 12)
const DEFAULT_LOOK := Vector3(0, 1, 0)


## {pos, look, fov} at `t`. `where(id, t) -> Vector3`: a model's place (for follow keys).
static func pose(keys_in: Array, t: float, where: Callable = Callable()) -> Dictionary:
	var keys := sorted(keys_in)
	if keys.is_empty():
		return {"pos": DEFAULT_POS, "look": DEFAULT_LOOK, "fov": StudioRules.DEFAULT_FOV, "roll": 0.0}
	var i := 0
	for k in keys.size():
		if float(keys[k].at) <= t:
			i = k
	var a := _resolve(keys[i], t, where)
	var out := a
	if i + 1 < keys.size() and t >= float(keys[i].at) and not bool(keys[i + 1].get("cut", false)):
		var nk: Dictionary = keys[i + 1]
		var b := _resolve(nk, t, where)
		var span := maxf(float(nk.at) - float(keys[i].at), 0.0001)
		var e := StudioMotion.ease_of(str(nk.get("ease", "smooth")), (t - float(keys[i].at)) / span)
		var look: Vector3 = (a.look as Vector3).lerp(b.look, e)
		var pos: Vector3
		if str(nk.get("path", "line")) == "orbit":
			pos = _orbit(a, b, e, StudioRules.num(nk, "turns", 0.0))
		else:
			pos = (a.pos as Vector3).lerp(b.pos, e)
		out = {"pos": pos, "look": look, "fov": lerpf(float(a.fov), float(b.fov), e),
			"roll": lerpf(float(a.roll), float(b.roll), e)}
	var amount := _shake(keys, t)
	if amount > 0.0:
		out.pos = (out.pos as Vector3) + _noise(t) * amount
		out.look = (out.look as Vector3) + _noise(t + 17.3) * amount * 0.5
	return out


## The camera's transform (looking from pos at look; straight up or down looks along -z's up).
static func transform(p: Dictionary) -> Transform3D:
	var pos: Vector3 = p.pos
	var look: Vector3 = p.look
	var dir := look - pos
	if dir.length() < 0.0001:
		return Transform3D(Basis.IDENTITY, pos)
	var up := Vector3.UP if absf(dir.normalized().dot(Vector3.UP)) < 0.999 else Vector3.BACK
	var basis := Basis.looking_at(dir, up)
	var roll := float(p.get("roll", 0.0))
	if roll != 0.0:
		basis = basis * Basis(Vector3.BACK, deg_to_rad(roll))
	return Transform3D(basis, pos)


## The keys in the order of their moments.
static func sorted(keys_in: Array) -> Array:
	var keys: Array = []
	for k: Variant in keys_in:
		if k is Dictionary and typeof((k as Dictionary).get("at")) in [TYPE_INT, TYPE_FLOAT]:
			keys.append(k)
	keys.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a.at) < float(b.at))
	return keys


static func _resolve(key: Dictionary, t: float, where: Callable) -> Dictionary:
	var pos := StudioRules.vec(key.get("pos")) if StudioRules.is_vec(key.get("pos")) else DEFAULT_POS
	var look := StudioRules.vec(key.get("look")) if StudioRules.is_vec(key.get("look")) else DEFAULT_LOOK
	if key.has("follow") and where.is_valid():
		var base: Vector3 = where.call(str(key.follow), t)
		pos += base
		look += base
	if key.has("aim") and where.is_valid():   # round 2: the look is that model's place (plus look): it stays in the middle
		look = (where.call(str(key.aim), t) as Vector3) + StudioRules.vec(key.get("look"))
	return {"pos": pos, "look": look, "roll": StudioRules.num(key, "roll", 0.0),
		"fov": clampf(StudioRules.num(key, "fov", StudioRules.DEFAULT_FOV),
		StudioRules.FOV.x, StudioRules.FOV.y)}


## Round the look point: the angle (the short way, plus `turns`), the distance and the height eased from a to b.
static func _orbit(a: Dictionary, b: Dictionary, e: float, turns: float) -> Vector3:
	var ra: Vector3 = (a.pos as Vector3) - (a.look as Vector3)
	var rb: Vector3 = (b.pos as Vector3) - (b.look as Vector3)
	var ta := atan2(ra.z, ra.x)
	var tb := atan2(rb.z, rb.x)
	var d := wrapf(tb - ta, -PI, PI) + TAU * turns
	var theta := ta + d * e
	var r := lerpf(Vector2(ra.x, ra.z).length(), Vector2(rb.x, rb.z).length(), e)
	var h := lerpf(ra.y, rb.y, e)
	var centre := (a.look as Vector3).lerp(b.look, e)
	return centre + Vector3(cos(theta) * r, h, sin(theta) * r)


## The shake from the last key at or before `t` that says one.
static func _shake(keys: Array, t: float) -> float:
	var amount := 0.0
	for k: Dictionary in keys:
		if float(k.at) > t:
			break
		if k.has("shake"):
			amount = maxf(StudioRules.num(k, "shake", 0.0), 0.0)
	return amount


## A smooth wobble in [-1, 1] on each axis (a few sines at unrelated rates: the same at the same moment).
static func _noise(t: float) -> Vector3:
	return Vector3(sin(t * 23.1) * 0.6 + sin(t * 37.7 + 1.3) * 0.4, sin(t * 29.3 + 0.7) * 0.6 + sin(t * 41.9 + 2.1) * 0.4,
		sin(t * 19.7 + 2.9) * 0.6 + sin(t * 33.1 + 0.4) * 0.4)
