class_name SpaceDepositSites
extends RefCounted
## Where the Moon's and Mars's rich deposits are (spec §26.5, owner #80): DepositRules' sites for the planets' kinds,
## as pure rules of the seed and SpaceShape (read-only; they run on the generator's threads through DepositRules'
## cache). A region's candidates are its craters (SpaceShape.crater_in_cell) or its coarse samples, in an order
## scrambled by the seed; the first that fits (clear of the spawn, the colony's ground, the secrets and the region's
## other deposits: DepositRules._fits) is the region's deposit of that kind. Real geology:
## - the Moon's ice: the floor of a deep crater (a bowl at least 0.3 × its radius deep), where the Sun never shines near
##   the poles (the game's Moon is the land by its south pole, where the colony is): icy regolith 3 deep; the quest
##   starts on its rim;
## - ilmenite: a dark sea (mare): low, flat ground with no crater, mare dust 2 deep with black ilmenite crystals glinting
##   at the top and a lens of ilmenite under it;
## - helium-3: the widest, oldest sea (no crater within two samples): mare dust 3 deep, the helium in the dust itself;
## - KREEP: pale KREEP rock thrown onto a big crater's raised rim (an arc of it) with a body of it under the rim;
## - a Moon meteorite: a lump of iron in a small crater's floor (no crystal growing by it), its top layer standing out
##   of the dust, and a few pieces round it;
## - Mars's ice: a small fresh crater on the plains in the mid-latitudes (DepositRules.MARS_ICE_LATITUDE from the
##   equator's canyon): bright ice in its floor and a sheet of ice under the dust round it;
## - hematite: blueberry soil on flat plains with an old river bed near (water was there), hematite rock under it;
## - dark sand: the floor of a big crater on the plains (dark dunes gather in craters);
## - Mars salt: a low, level basin (an old lake's bed) on the plains or a river bed's end: a pale crust 2 deep;
## - a Mars meteorite: an iron lump lying on flat plains (2 × 2, half sunk) and two pieces near it.

## Kinds whose places are craters; the others' are the region's samples.
const CRATER_KINDS: Array[StringName] = [DepositKinds.MOON_ICE, DepositKinds.KREEP, DepositKinds.MOON_METEORITE,
	DepositKinds.MARS_ICE, DepositKinds.DARK_SAND]
const ICE_MIN_R := 10.0           # the Moon's ice: a deep crater (its bowl ~4.5 deep and more)
const KREEP_MIN_R := 8.0
const MOON_METEORITE_MAX_R := 9.0
const MARS_ICE_MAX_R := 10.0      # a small, fresh crater
const SAND_MIN_R := 8.0
const MOON_LOW := 44              # a sea's ground at most this high (SpaceShape.MOON_BASE: the seas are low plains)
const MARS_LOW := 53              # a salt basin's ground under this (MarsTerrain.BASE is 54)


## The region's deposit of `kind` ({} when none fits): DepositRules._site's for the planets.
static func site(r: DepositRules, kind: StringName, region: Vector2i, samples: Array, by: Dictionary,
		taken: Array[Vector2i], cols: Cols) -> Dictionary:
	var list: Array = r._order(craters(r, region) if CRATER_KINDS.has(kind) else samples, region, kind)
	for c: Array in list:
		var x: int = c[0]
		var z: int = c[1]
		if not r._far_from_spawn(x, z) or not r._far_from(taken, x, z):
			continue
		var d := {}
		match kind:
			DepositKinds.MOON_ICE:
				d = _moon_ice(r, c, cols)
			DepositKinds.ILMENITE:
				d = _ilmenite(r, c, by, cols)
			DepositKinds.HELIUM_3:
				d = _helium_3(r, c, by, cols)
			DepositKinds.KREEP:
				d = _kreep(r, c, cols)
			DepositKinds.MOON_METEORITE:
				d = _moon_meteorite(r, c, cols)
			DepositKinds.MARS_ICE:
				d = _mars_ice(r, c, cols)
			DepositKinds.HEMATITE:
				d = _hematite(r, c, by, cols)
			DepositKinds.DARK_SAND:
				d = _dark_sand(r, c, cols)
			DepositKinds.MARS_SALT:
				d = _mars_salt(r, c, by, cols)
			DepositKinds.MARS_METEORITE:
				d = _mars_meteorite(r, c, by, cols)
		if d.is_empty():
			continue
		var box := DepositRules._bounds(d.raw)
		if r._fits(box[0], box[1], d.anchor, region):
			r._finish(d, kind, region)
			return d
	return {}


## The craters whose middle is inside the region's margin: [[x, z, radius], …] (cell by cell).
static func craters(r: DepositRules, region: Vector2i) -> Array:
	var sp := r.space
	var size := float(SpaceShape.MARS_CRATER_CELL if sp.planet == SpaceShape.MARS else SpaceShape.CRATER_CELL)
	var lo := region * DepositRules.REGION + Vector2i(DepositRules.MARGIN, DepositRules.MARGIN)
	var hi := region * DepositRules.REGION + Vector2i(DepositRules.REGION - DepositRules.MARGIN,
		DepositRules.REGION - DepositRules.MARGIN)
	var out: Array = []
	for cz in range(floori(lo.y / size), floori((hi.y - 1) / size) + 1):
		for cx in range(floori(lo.x / size), floori((hi.x - 1) / size) + 1):
			var c := sp.crater_in_cell(Vector2i(cx, cz))
			if c.is_empty():
				continue
			var at: Vector2i = c.center
			if at.x >= lo.x and at.y >= lo.y and at.x < hi.x and at.y < hi.y:
				out.append([at.x, at.y, float(c.radius)])
	return out


# --- The Moon --------------------------------------------------------------------------------------------------------

## Ice on a deep crater's floor: icy regolith 3 deep where the bowl is deepest; the quest's first place is its rim.
static func _moon_ice(r: DepositRules, c: Array, cols: Cols) -> Dictionary:
	var cx: int = c[0]
	var cz: int = c[1]
	var rad: float = c[2]
	if rad < ICE_MIN_R or cols.crater(cx, cz) > -rad * 0.3:
		return {}
	var raw := {}
	var ice := _floor(cols, cx, cz, rad * 0.55, -1.5, BlockIds.ICY_REGOLITH, 3, raw)
	if ice.size() < 40:
		return {}
	var rim := _rim(r, cols, cx, cz, rad, DepositKinds.MOON_ICE)
	return {"anchor": ice[0], "spots": [rim, ice[0]], "signs": [[] as Array[Vector3i], ice], "raw": raw}


## A dark sea: mare dust 2 deep on low, flat, crater-free ground, black ilmenite crystals glinting at its top (1 in 9),
## a lens of ilmenite under it.
static func _ilmenite(r: DepositRules, s: Array, by: Dictionary, cols: Cols) -> Dictionary:
	var x: int = s[0]
	var z: int = s[1]
	var h: int = s[2]
	if int(s[4]) != 0 or h > MOON_LOW or not _flat_round(r, s, by, 1, 2) or cols.crater_near(x, z, 9.0):
		return {}
	var raw := {}
	var tops: Array[Vector3i] = []
	for col in r._blob(x, z, 9.0, x * 5 + z):
		var g := cols.ground(col.x, col.y)
		if absi(g - h) > 2 or absf(cols.crater(col.x, col.y)) >= 0.5:
			continue
		var top := Vector3i(col.x, g - 1, col.y)
		if r._roll(col, DepositKinds.ILMENITE, 3) % 9 == 0:
			raw[top] = BlockIds.ILMENITE
		else:
			raw[top] = BlockIds.MARE_DUST
			tops.append(top)
		raw[Vector3i(col.x, g - 2, col.y)] = BlockIds.MARE_DUST
	if tops.size() < 80:
		return {}
	_lens(cols, Vector3i(x, h - 6, z), Vector3i(4, 2, 4), BlockIds.ILMENITE, 2, raw)
	var a := Vector3i(x, h - 1, z)
	_first(tops, a)
	return {"anchor": a, "spots": [a], "signs": [tops], "raw": raw}


## The widest, oldest sea: no crater in the samples round it (two out), mare dust 3 deep.
static func _helium_3(r: DepositRules, s: Array, by: Dictionary, cols: Cols) -> Dictionary:
	var x: int = s[0]
	var z: int = s[1]
	var h: int = s[2]
	if int(s[4]) != 0 or h > MOON_LOW + 1 or not _flat_round(r, s, by, 2, 3) or cols.crater_near(x, z, 11.0):
		return {}
	var raw := {}
	var tops: Array[Vector3i] = []
	for col in r._blob(x, z, 11.0, x - 3 * z):
		var g := cols.ground(col.x, col.y)
		if absi(g - h) > 2 or absf(cols.crater(col.x, col.y)) >= 0.5:
			continue
		for y in range(g - 3, g):
			raw[Vector3i(col.x, y, col.y)] = BlockIds.MARE_DUST
		tops.append(Vector3i(col.x, g - 1, col.y))
	if tops.size() < 150:
		return {}
	var a := Vector3i(x, h - 1, z)
	_first(tops, a)
	return {"anchor": a, "spots": [a], "signs": [tops], "raw": raw}


## KREEP rock thrown onto a big crater's raised rim: an arc of it on the rim's top facing the roll's way, and a body of
## it under the arc's middle.
static func _kreep(r: DepositRules, c: Array, cols: Cols) -> Dictionary:
	var cx: int = c[0]
	var cz: int = c[1]
	var rad: float = c[2]
	if rad < KREEP_MIN_R or cols.crater(cx, cz) > -rad * 0.25:
		return {}
	var ang := float(r._roll(Vector2i(cx, cz), DepositKinds.KREEP, 5) % 360) * PI / 180.0
	var raw := {}
	var tops: Array[Vector3i] = []
	var reach := ceili(rad * 1.4)
	for dz in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var k := Vector2(dx, dz).length() / rad
			if k < 0.95 or k > 1.35 or absf(angle_difference(atan2(float(dz), float(dx)), ang)) > 1.0:
				continue
			var x := cx + dx
			var z := cz + dz
			if cols.crater(x, z) <= 0.0:
				continue   # only the raised rim
			var g := cols.ground(x, z)
			raw[Vector3i(x, g - 1, z)] = BlockIds.KREEP_ROCK
			tops.append(Vector3i(x, g - 1, z))
	if tops.size() < 20:
		return {}
	var mid := Vector2i(roundi(cx + cos(ang) * rad * 1.15), roundi(cz + sin(ang) * rad * 1.15))
	var gm := cols.ground(mid.x, mid.y)
	_lens(cols, Vector3i(mid.x, gm - 6, mid.y), Vector3i(4, 2, 4), BlockIds.KREEP_ROCK, 2, raw)
	var a := Vector3i(mid.x, gm - 1, mid.y)
	_first(tops, a)
	return {"anchor": tops[0], "spots": [tops[0]], "signs": [tops], "raw": raw}


## An iron meteorite in a small crater's floor with no crystal growing by it: a 2 × 2 lump sunk 2 deep with its top
## layer standing out of the dust, and three pieces round it; the quest's first place is the crater's rim.
static func _moon_meteorite(r: DepositRules, c: Array, cols: Cols) -> Dictionary:
	var cx: int = c[0]
	var cz: int = c[1]
	var rad: float = c[2]
	if rad > MOON_METEORITE_MAX_R or cols.crater(cx, cz) > -1.5:
		return {}
	for dz in range(-2, 4):
		for dx in range(-2, 4):
			if r.space.tree_at(cx + dx, cz + dz):
				return {}   # a crystal by the lump would hide it
	var raw := {}
	var tops := _lump(cols, cx, cz, 4, raw)
	for i in 3:   # pieces round it
		var roll := r._roll(Vector2i(cx, cz), DepositKinds.MOON_METEORITE, 11 + i)
		var a := float(roll % 360) * PI / 180.0
		var d := 3.0 + float((roll >> 9) % 3)
		var p := Vector2i(roundi(cx + 0.5 + cos(a) * d), roundi(cz + 0.5 + sin(a) * d))
		var g := cols.ground(p.x, p.y)
		var at := Vector3i(p.x, g - 1, p.y)
		if not raw.has(at):
			raw[at] = BlockIds.IRON_METEORITE
			tops.append(at)
	var rim := _rim(r, cols, cx, cz, rad, DepositKinds.MOON_METEORITE)
	return {"anchor": tops[0], "spots": [rim, tops[0]], "signs": [[] as Array[Vector3i], tops], "raw": raw}


# --- Mars ------------------------------------------------------------------------------------------------------------

## Ice under the dust in the mid-latitudes, shown by a small fresh crater: bright ice in its floor (3 deep), a sheet of
## ice under the dust round it out to 1.2 × its radius (the dust stays on top).
static func _mars_ice(r: DepositRules, c: Array, cols: Cols) -> Dictionary:
	var sp := r.space
	var cx: int = c[0]
	var cz: int = c[1]
	var rad: float = c[2]
	if rad > MARS_ICE_MAX_R or absf(cz - sp.mars.canyon_z(cx)) < DepositRules.MARS_ICE_LATITUDE:
		return {}
	if cols.crater(cx, cz) > -1.5 or not _plains_round(cols, cx, cz, rad * 1.5):
		return {}
	var raw := {}
	var ice := _floor(cols, cx, cz, rad * 0.5, -0.5, BlockIds.GROUND_ICE, 3, raw)
	if ice.size() < 8:
		return {}
	var reach := ceili(rad * 1.2)
	for dz in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var x := cx + dx
			var z := cz + dz
			var g := cols.ground(x, z)
			if Vector2(dx, dz).length() > rad * 1.2 or raw.has(Vector3i(x, g - 1, z)):
				continue
			raw[Vector3i(x, g - 2, z)] = BlockIds.GROUND_ICE
	var rim := _rim(r, cols, cx, cz, rad, DepositKinds.MARS_ICE)
	return {"anchor": ice[0], "spots": [rim, ice[0]], "signs": [[] as Array[Vector3i], ice], "raw": raw}


## Blueberries: flat, crater-free plains with an old river bed within three samples; blueberry soil at the top, hematite
## rock under it.
static func _hematite(r: DepositRules, s: Array, by: Dictionary, cols: Cols) -> Dictionary:
	var x: int = s[0]
	var z: int = s[1]
	var h: int = s[2]
	if int(s[3]) != MarsTerrain.PLAINS or int(s[4]) != 0 or not _flat_round(r, s, by, 1, 2):
		return {}
	var wet := false
	for dz in range(-3, 4):
		for dx in range(-3, 4):
			var o: Variant = by.get(Vector2i(x + dx * DepositRules.STEP, z + dz * DepositRules.STEP))
			wet = wet or (o != null and int(o[3]) == MarsTerrain.VALLEY)
	if not wet:
		return {}
	var raw := {}
	var tops: Array[Vector3i] = []
	for col in r._blob(x, z, 9.0, x + 7 * z):
		var g := cols.ground(col.x, col.y)
		if absi(g - h) > 2 or cols.kind(col.x, col.y) != MarsTerrain.PLAINS or absf(cols.crater(col.x, col.y)) >= 0.5:
			continue
		raw[Vector3i(col.x, g - 1, col.y)] = BlockIds.BLUEBERRY_SOIL
		raw[Vector3i(col.x, g - 2, col.y)] = BlockIds.HEMATITE
		tops.append(Vector3i(col.x, g - 1, col.y))
	if tops.size() < 60:
		return {}
	var a := Vector3i(x, h - 1, z)
	_first(tops, a)
	return {"anchor": a, "spots": [a], "signs": [tops], "raw": raw}


## Dark iron-rich sand on a big crater's floor (2 deep); the quest's first place is its rim.
static func _dark_sand(r: DepositRules, c: Array, cols: Cols) -> Dictionary:
	var cx: int = c[0]
	var cz: int = c[1]
	var rad: float = c[2]
	if rad < SAND_MIN_R or cols.crater(cx, cz) > -1.5 or not _plains_round(cols, cx, cz, rad * 1.2):
		return {}
	var raw := {}
	var sand := _floor(cols, cx, cz, rad * 0.7, -0.5, BlockIds.DARK_SAND, 2, raw)
	if sand.size() < 20:
		return {}
	var rim := _rim(r, cols, cx, cz, rad, DepositKinds.DARK_SAND)
	return {"anchor": sand[0], "spots": [rim, sand[0]], "signs": [[] as Array[Vector3i], sand], "raw": raw}


## Salt where an old lake dried: a low, level basin on the plains or a river bed's end; a pale crust 2 deep.
static func _mars_salt(r: DepositRules, s: Array, by: Dictionary, cols: Cols) -> Dictionary:
	var x: int = s[0]
	var z: int = s[1]
	var h: int = s[2]
	var kind := int(s[3])
	if (kind != MarsTerrain.PLAINS and kind != MarsTerrain.VALLEY) or int(s[4]) != 0 or h >= MARS_LOW:
		return {}
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var o: Variant = by.get(Vector2i(x + d.x * DepositRules.STEP, z + d.y * DepositRules.STEP))
		if o == null or not int(o[3]) in [MarsTerrain.PLAINS, MarsTerrain.VALLEY] or absi(int(o[2]) - h) > 1:
			return {}
	var raw := {}
	var tops: Array[Vector3i] = []
	for col in r._blob(x, z, 10.0, 3 * x - z):
		var g := cols.ground(col.x, col.y)
		var k := cols.kind(col.x, col.y)
		if absi(g - h) > 1 or (k != MarsTerrain.PLAINS and k != MarsTerrain.VALLEY) \
				or absf(cols.crater(col.x, col.y)) >= 0.5:
			continue
		raw[Vector3i(col.x, g - 1, col.y)] = BlockIds.MARS_SALT
		raw[Vector3i(col.x, g - 2, col.y)] = BlockIds.MARS_SALT
		tops.append(Vector3i(col.x, g - 1, col.y))
	if tops.size() < 160:
		return {}
	var a := Vector3i(x, h - 1, z)
	_first(tops, a)
	return {"anchor": a, "spots": [a], "signs": [tops], "raw": raw}


## An iron meteorite lying on flat plains: a 2 × 2 lump, half sunk (its top layer stands in the air), two pieces near.
static func _mars_meteorite(r: DepositRules, s: Array, by: Dictionary, cols: Cols) -> Dictionary:
	var x: int = s[0]
	var z: int = s[1]
	if int(s[3]) != MarsTerrain.PLAINS or int(s[4]) != 0 or not _flat_round(r, s, by, 1, 2):
		return {}
	for dz in range(-2, 4):
		for dx in range(-2, 4):
			if cols.kind(x + dx, z + dz) != MarsTerrain.PLAINS:
				return {}
	var raw := {}
	var tops := _lump(cols, x, z, 4, raw)
	for i in 2:
		var roll := r._roll(Vector2i(x, z), DepositKinds.MARS_METEORITE, 21 + i)
		var a := float(roll % 360) * PI / 180.0
		var p := Vector2i(roundi(x + 0.5 + cos(a) * 4.0), roundi(z + 0.5 + sin(a) * 4.0))
		var g := cols.ground(p.x, p.y)
		var at := Vector3i(p.x, g - 1, p.y)
		if not raw.has(at):
			raw[at] = BlockIds.IRON_METEORITE
			tops.append(at)
	return {"anchor": tops[0], "spots": [tops[0]], "signs": [tops], "raw": raw}


# --- Shapes ----------------------------------------------------------------------------------------------------------

## A crater's floor within `radius` of (cx, cz) where its bowl is deeper than `deeper` (crater_depth under it): `id`
## `depth` deep; the tops, the middle first.
static func _floor(cols: Cols, cx: int, cz: int, radius: float, deeper: float, id: int, depth: int,
		raw: Dictionary) -> Array[Vector3i]:
	var tops: Array[Vector3i] = []
	var reach := ceili(radius)
	for dz in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			if Vector2(dx, dz).length() > radius:
				continue
			var x := cx + dx
			var z := cz + dz
			if cols.crater(x, z) > deeper:
				continue
			var g := cols.ground(x, z)
			for y in range(g - depth, g):
				raw[Vector3i(x, y, z)] = id
			tops.append(Vector3i(x, g - 1, z))
	if not tops.is_empty():
		_first(tops, Vector3i(cx, cols.ground(cx, cz) - 1, cz))
	return tops


## A 2 × 2 iron lump at (x, z): its top layer sunk in the ground (the tops returned), one more under it, and `stand` of
## its columns with a block standing out of the ground (negative ids: into the air only).
static func _lump(cols: Cols, x: int, z: int, stand: int, raw: Dictionary) -> Array[Vector3i]:
	var tops: Array[Vector3i] = []
	var i := 0
	for d: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1)]:
		var g := cols.ground(x + d.x, z + d.y)
		raw[Vector3i(x + d.x, g - 1, z + d.y)] = BlockIds.IRON_METEORITE
		raw[Vector3i(x + d.x, g - 2, z + d.y)] = BlockIds.IRON_METEORITE
		if i < stand:
			raw[Vector3i(x + d.x, g, z + d.y)] = -BlockIds.IRON_METEORITE
		tops.append(Vector3i(x + d.x, g - 1, z + d.y))
		i += 1
	return tops


## An ellipsoid of `id` round `mid` (radii), only `under` or more blocks under the ground and where nothing is yet.
static func _lens(cols: Cols, mid: Vector3i, radii: Vector3i, id: int, under: int, raw: Dictionary) -> void:
	for dy in range(-radii.y, radii.y + 1):
		for dz in range(-radii.z, radii.z + 1):
			for dx in range(-radii.x, radii.x + 1):
				if Vector3(float(dx) / radii.x, float(dy) / radii.y, float(dz) / radii.z).length() > 1.0:
					continue
				var p := mid + Vector3i(dx, dy, dz)
				if not raw.has(p) and p.y < cols.ground(p.x, p.z) - under:
					raw[p] = id


## The crater's rim at the roll's angle: the first column walking out from its middle that is no longer in its bowl.
static func _rim(r: DepositRules, cols: Cols, cx: int, cz: int, rad: float, kind: StringName) -> Vector3i:
	var ang := float(r._roll(Vector2i(cx, cz), kind, 9) % 360) * PI / 180.0
	var at := Vector2i(roundi(cx + cos(ang) * rad * 1.1), roundi(cz + sin(ang) * rad * 1.1))
	for i in range(floori(rad * 0.8), ceili(rad * 1.5) + 1):
		var p := Vector2i(roundi(cx + cos(ang) * i), roundi(cz + sin(ang) * i))
		if cols.crater(p.x, p.y) > -0.3:
			at = p
			break
	return Vector3i(at.x, cols.ground(at.x, at.y) - 1, at.y)


## Flat ground round a sample: every sample `rings` out (the 8 ways) is there, crater-free and within `slope` of it.
static func _flat_round(r: DepositRules, s: Array, by: Dictionary, rings: int, slope: int) -> bool:
	for dz in range(-rings, rings + 1):
		for dx in range(-rings, rings + 1):
			if dx == 0 and dz == 0:
				continue
			var o: Variant = by.get(Vector2i(int(s[0]) + dx * DepositRules.STEP, int(s[1]) + dz * DepositRules.STEP))
			if o == null or int(o[4]) != 0 or absi(int(o[2]) - int(s[2])) > slope:
				return false
			if r.space.mars != null and int(o[3]) != MarsTerrain.PLAINS and int(o[3]) != MarsTerrain.VALLEY:
				return false
	return true


## Mars: plains all round a crater (its rim and past it, looked at every 4 blocks): no canyon, cap, frost or volcano.
static func _plains_round(cols: Cols, cx: int, cz: int, reach: float) -> bool:
	var n := ceili(reach)
	for dz in range(-n, n + 1, 4):
		for dx in range(-n, n + 1, 4):
			if Vector2(dx, dz).length() <= reach and cols.kind(cx + dx, cz + dz) != MarsTerrain.PLAINS:
				return false
	return true


## Puts `first` (when it is in the list) at the list's front: a quest's sign step points at it.
static func _first(list: Array[Vector3i], first: Vector3i) -> void:
	var i := list.find(first)
	if i > 0:
		list.remove_at(i)
		list.push_front(first)


## A planet's columns for one region's placing (made by DepositRules._place, used by one thread only, then dropped): the
## ground, the craters' change and Mars's region of each column looked at, each worked out once, exactly as SpaceShape
## does (ground_at, crater_depth, mars_kind) but with the craters' cells drawn once (a region's survey and sites look at
## thousands of columns).
class Cols:
	extends RefCounted

	var sp: SpaceShape
	var _size := 40.0
	var _cells := {}              # Vector2i cell -> [cx, cz, r] or [] (no crater)
	var _cols := {}               # Vector2i column -> Vector3(ground, kind, crater)

	func _init(shape: SpaceShape) -> void:
		sp = shape
		_size = float(SpaceShape.MARS_CRATER_CELL if sp.planet == SpaceShape.MARS else SpaceShape.CRATER_CELL)

	## The solid ground at (x, z) (SpaceShape.ground_at).
	func ground(x: int, z: int) -> int:
		return int(_col(x, z).x)

	## Mars's region at (x, z) (SpaceShape.mars_kind; 0 on the Moon).
	func kind(x: int, z: int) -> int:
		return int(_col(x, z).y)

	## The craters' change to the ground at (x, z) (SpaceShape.crater_depth).
	func crater(x: int, z: int) -> float:
		return _col(x, z).z

	## Some crater's bowl or rim reaches within `reach` of (x, z) (its cells looked at, no column worked out).
	func crater_near(x: int, z: int, reach: float) -> bool:
		var n := ceili((reach + SpaceShape.CRATER_MAX * SpaceShape.RIM_OUT) / _size)
		var cell := Vector2i(floori(x / _size), floori(z / _size))
		for dz in range(-n, n + 1):
			for dx in range(-n, n + 1):
				var c := _cell(cell + Vector2i(dx, dz))
				if not c.is_empty() and Vector2(float(c[0]) - x, float(c[1]) - z).length() < reach + float(c[2]) * SpaceShape.RIM_OUT:
					return true
		return false

	## The craters' change at (x, z) without keeping the column (a quest map's colours: only the cells are kept).
	func crater_only(x: int, z: int) -> float:
		return _crater(x, z)

	## How many crater cells are kept.
	func cells() -> int:
		return _cells.size()

	## A coarse sample of the survey: (ground, kind, 1 in a crater's bowl or on its rim else 0).
	func sample(x: int, z: int) -> Vector3i:
		var c := _col(x, z)
		return Vector3i(int(c.x), int(c.y), 1 if absf(c.z) > 0.3 else 0)

	func _col(x: int, z: int) -> Vector3:
		var key := Vector2i(x, z)
		var got: Variant = _cols.get(key)
		if got != null:
			return got
		var crater := _crater(x, z)
		var h := 0
		var k := 0
		var sx := x - sp.spawn_column().x
		var sz := z - sp.spawn_column().y
		if sx * sx + sz * sz <= (SpaceShape.BLEND_RADIUS + 1) * (SpaceShape.BLEND_RADIUS + 1):
			h = sp.ground_at(x, z)   # the landing pad's flat ground and its blend
			k = maxi(sp.mars_kind(x, z), 0)
		elif sp.mars != null:
			var c := sp.mars.column(x, z, crater)
			h = c >> 4
			k = c & 15
			if sp.colony != null:
				h = sp.colony.flatten(x, z, h)
				if sp.colony.covers(x, z):
					k = MarsTerrain.PLAINS
		else:
			h = sp._height_from(x, z, crater)
		var out := Vector3(h, k, crater)
		_cols[key] = out
		return out

	## SpaceShape.crater_depth with the cells' craters drawn once, summed in the same order (the same floats).
	func _crater(x: int, z: int) -> float:
		var cell := Vector2i(floori(x / _size), floori(z / _size))
		var total := 0.0
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				var c := _cell(cell + Vector2i(dx, dz))
				if not c.is_empty():
					total = SpaceShape._crater_add(total, x, z, int(c[0]), int(c[1]), float(c[2]))
		return total

	## The crater of a cell ([cx, cz, r], or [] for none), drawn once.
	func _cell(at: Vector2i) -> Array:
		var c: Variant = _cells.get(at)
		if c == null:
			var got := sp.crater_in_cell(at)
			c = [] if got.is_empty() else [(got.center as Vector2i).x, (got.center as Vector2i).y, float(got.radius)]
			_cells[at] = c
		return c
