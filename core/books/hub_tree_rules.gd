class_name HubTreeRules
extends RefCounted
## The Hub Tree (M3 Task 21b; research R1): a magic tree beside the portal hub's stone circle (M3 Task 5) that
## shows the world owner's progress — a leafy crown in each universe's colours for every universe explored, a
## glowing fruit for every boss beaten, a golden star on top for every Secret Book page done (BookPages). Its
## trunk grows with all of it. It only ever grows: every part comes from lists that are only ever added to
## (WonderData.universes and pages, the boss counts), so it never withers, even after a long break. Pure: the
## state, its boxes (HubTree bakes them into one cached mesh) and where it stands.

## The state: {"u": universes explored (sorted), "b": bosses beaten (sorted kinds), "p": pages done (BookPages
## order)}. It crosses the network from the host (a guest sees the host's tree): `clean` checks it.
const MAX_BOSSES := 16
const BASE_TRUNK := 2.0
const GROW := 0.3            # trunk height per thing on the tree
const MAX_TRUNK := 6.5
const TRUNK_WIDTH := 0.8
const STAR_BOXES := 3        # a star: two crossed bars and a heart
## Where it stands: this far from the circle's middle (outside the stones and the hub's leave radius).
const DISTANCE := 4.6
const TREE_CLEAR := 2        # no tree trunk of the world within this many columns
const MAX_STEP := 2          # its ground at most this far above or below the circle's

const TRUNK := Color("7b5230")
const TRUNK_DARK := Color("5d3b1f")
const SAPLING := Color("7cc66b")
const STAR := Color("ffd23f")
const LEAVES := {1: Color("4caf50"), 2: Color("b5c42b"), 3: Color("a8dcf5"), 4: Color("f48fb1"), 5: Color("4db6ac")}
const FRUITS := {&"golem": Color("ffa726"), &"serpent": Color("ffe066"), &"giant": Color("80deea"),
	&"cake": Color("ff6fa8"), &"sky_dragon": Color("c39bff")}


static func state(w: WonderData, d: ProgressData) -> Dictionary:
	var bosses: Array = []
	var prefix := String(LevelRules.BOSS) + "/"
	for key: String in d.counts:
		if key.begins_with(prefix) and int(d.counts[key]) > 0:
			bosses.append(key.substr(prefix.length()))
	return clean({"u": w.universes.duplicate(), "b": bosses, "p": w.pages.duplicate()})


## A state from anywhere (the network, a save): real universes, boss kinds of plain letters, known pages; sorted
## and without repeats, so the same tree always has the same key.
static func clean(v: Variant) -> Dictionary:
	var src: Dictionary = v if v is Dictionary else {}
	var u: Array = []
	var b: Array = []
	var p: Array = []
	var su: Variant = src.get("u")
	if su is Array:
		for n: Variant in su:
			if typeof(n) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(n)) and float(n) == floorf(float(n)) \
					and int(n) >= 1 and int(n) <= WonderData.MAX_UNIVERSES and not u.has(int(n)):
				u.append(int(n))
	u.sort()
	var sb: Variant = src.get("b")
	if sb is Array:
		for k: Variant in sb:
			if (k is String or k is StringName) and _is_word(str(k)) and not b.has(str(k)) and b.size() < MAX_BOSSES:
				b.append(str(k))
	b.sort()
	var sp: Variant = src.get("p")
	for id in BookPages.ids():
		if sp is Array and (sp as Array).has(id):
			p.append(id)
	return {"u": u, "b": b, "p": p}


static func key(s: Dictionary) -> String:
	return "|".join(PackedStringArray(["u" + _join(s.get("u", [])), "b" + _join(s.get("b", [])), "p" + _join(s.get("p", []))]))


static func _join(list: Variant) -> String:
	var parts := PackedStringArray()
	if list is Array:
		for x: Variant in list:
			parts.append(str(x))
	return ",".join(parts)


## Everything on the tree.
static func things(s: Dictionary) -> int:
	return (s.u as Array).size() + (s.b as Array).size() + (s.p as Array).size()


## Leafy crowns: one per universe explored.
static func crowns(s: Dictionary) -> int:
	return (s.u as Array).size()


## Whether `after` has everything `before` had (the tree grows, never shrinks).
static func grows(before: Dictionary, after: Dictionary) -> bool:
	for field in ["u", "b", "p"]:
		for x: Variant in before[field]:
			if not (after[field] as Array).has(x):
				return false
	return true


static func trunk_height(s: Dictionary) -> float:
	return minf(BASE_TRUNK + GROW * things(s), MAX_TRUNK)


## The tree's boxes, [centre, size, colour] around its foot at the origin: {"lit": the trunk, roots and crowns,
## "glow": the fruits and stars (they shine)}.
static func boxes(s: Dictionary) -> Dictionary:
	var lit: Array = []
	var glow: Array = []
	var h := trunk_height(s)
	var w := TRUNK_WIDTH if things(s) > 0 else TRUNK_WIDTH * 0.5
	lit.append([Vector3(0, h * 0.5, 0), Vector3(w, h, w), TRUNK])
	for side: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		lit.append([side * w * 0.7 + Vector3(0, 0.15, 0), Vector3(w * 0.5, 0.3, w * 0.5) + side.abs() * 0.3, TRUNK_DARK])
	var universes: Array = s.u
	if universes.is_empty():
		lit.append([Vector3(0, h + 0.4, 0), Vector3(1.2, 1.0, 1.2), SAPLING])   # a sapling's first leaves
	var reach := 0.0
	for i in universes.size():
		var at := _crown_spot(i, h)
		var size := Vector3(2.2, 1.5, 2.2) if i == 0 else Vector3(1.8, 1.3, 1.8)
		lit.append([at, size, leaf_color(int(universes[i]))])
		reach = maxf(reach, Vector2(at.x, at.z).length() + size.x * 0.5)
	var bosses: Array = s.b
	for j in bosses.size():
		var a := j * 2.39996 + 0.5
		var r := maxf(reach, 1.1) + 0.05
		glow.append([Vector3(cos(a) * r, h + 0.1 + 0.35 * (j % 3), sin(a) * r), Vector3.ONE * 0.36,
			FRUITS.get(StringName(str(bosses[j])), Color("fff3a0"))])
	var pages: Array = s.p
	var top := h + (1.5 if not universes.is_empty() else 1.1)
	for k in pages.size():
		var at := Vector3((k - (pages.size() - 1) * 0.5) * 0.8, top + 0.35, 0)
		glow.append([at, Vector3(0.5, 0.12, 0.12), STAR])
		glow.append([at, Vector3(0.12, 0.5, 0.12), STAR])
		glow.append([at, Vector3(0.22, 0.22, 0.16), STAR.lightened(0.5)])
	return {"lit": lit, "glow": glow}


## Crown i: the first on top of the trunk, the next ones round it, a little lower.
static func _crown_spot(i: int, h: float) -> Vector3:
	if i == 0:
		return Vector3(0, h + 0.5, 0)
	var a := i * 2.39996
	return Vector3(cos(a) * 1.25, h - 0.1 + 0.3 * (i % 2), sin(a) * 1.25)


static func leaf_color(u: int) -> Color:
	return LEAVES.get(u, Color.from_hsv(fposmod(u * 0.17, 1.0), 0.45, 0.8))


## Where the tree stands beside the circle at `center` (whose `yaw` faces the spawn): behind it first, then round
## it; dry, nearly the circle's height, clear of the world's trees. Vector3.INF when no spot is good. height_at,
## ground_ok and tree_at as HubRules.circle_spot has them.
static func spot(center: Vector3, yaw: float, height_at: Callable, ground_ok: Callable, tree_at: Callable) -> Vector3:
	var behind := Vector2(sin(yaw), cos(yaw))
	for turn: float in [0.0, 0.7, -0.7, 1.4, -1.4, 2.1, -2.1, PI]:
		var dir := behind.rotated(turn)
		var c := Vector2i(floori(center.x + dir.x * DISTANCE), floori(center.z + dir.y * DISTANCE))
		if _good(c, center.y, height_at, ground_ok, tree_at):
			return Vector3(c.x + 0.5, float(height_at.call(c.x, c.y)), c.y + 0.5)
	return Vector3.INF


static func _good(c: Vector2i, y: float, height_at: Callable, ground_ok: Callable, tree_at: Callable) -> bool:
	for off: Vector2i in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var at := c + off
		if not ground_ok.call(at.x, at.y) or absf(float(height_at.call(at.x, at.y)) - y) > MAX_STEP:
			return false
	for dx in range(-TREE_CLEAR, TREE_CLEAR + 1):
		for dz in range(-TREE_CLEAR, TREE_CLEAR + 1):
			if tree_at.call(c.x + dx, c.y + dz):
				return false
	return true


static func _is_word(s: String) -> bool:
	if s == "" or s.length() > 24:
		return false
	for ch in s:
		if not (ch == "_" or (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9")):
			return false
	return true
