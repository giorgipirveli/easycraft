extends RefCounted
## The search of tools/make_rocket_plans.gd (owner #98): the cheapest rocket for a mission and crew, by the check's own
## sums (RocketCheck, RocketParts), for 2 to K_MAX stages. Stages from the top down: the lander (its payload from
## RocketPlan.lander, space engines, 1-T_TOP tanks), then each middle stage (space engines, tanks, a separator), then the
## first stage (rocket engines, tanks, 3 fins, a separator). Every stage has the fewest engines that pass its push rule
## (more only add mass and gold); upper stages use space engines only (searches with mixes never beat them: the notes).
## A state is what the stages built so far weigh, cost and add up to in speed; one lighter, cheaper and faster beats any
## other (any completion of the other would be no better), so each level keeps only that front (Pareto). The first
## stage takes the fewest tanks that reach the need. Exact float expressions of the check: push >= mass × 1.1 lifts off,
## push < carries × 0.5 is too weak.

const T_TOP := 12      # the lander's tanks
const T_MID := 160     # a middle stage's tanks
const T_BOT := 600     # the first stage's tanks (its engines run out first)
const E_MAX := 78      # the first stage's engines: one layer of the 9 × 9 square with room for the 3 fins
const V_MAX := 81      # an upper stage's engines: one layer
const V_TOP := 5       # the lander's engines (room for the legs round them)
const K_MIN := 2
const K_MAX := 8

const G0 := RocketParts.G0
const BITS := 21
const MASK := (1 << 21) - 1

## Prices to search with (id -> gold), RocketParts.PRICES unless set.
var prices := {}

var _tf := RocketParts.mass_full(BlockIds.FUEL_TANK)
var _te := RocketParts.mass_empty(BlockIds.FUEL_TANK)
var _em := RocketParts.mass_full(BlockIds.ROCKET_ENGINE)
var _vm := RocketParts.mass_full(BlockIds.SPACE_ENGINE)
var _ep := RocketParts.push(BlockIds.ROCKET_ENGINE)
var _vp := RocketParts.push(BlockIds.SPACE_ENGINE)
var _ei := RocketParts.isp(BlockIds.ROCKET_ENGINE)
var _vi := RocketParts.isp(BlockIds.SPACE_ENGINE)
var _xm := RocketParts.mass_full(BlockIds.STAGE_SEPARATOR)
var _fm := RocketParts.mass_full(BlockIds.ROCKET_FINS) * RocketCheck.FINS_NEEDED


func price(id: int) -> int:
	return int(prices.get(id, RocketParts.price(id)))


## The cheapest plan of each stage count that reaches `mission`'s need + RocketPlan.MARGIN with `crew`, cheapest first:
## [{"stages": [[engine, engines, tanks], …] bottom first, "gold"}].
func solve(mission: Dictionary, crew: int) -> Array:
	var need := MissionRules.need(mission) + RocketPlan.MARGIN + 0.001
	var pay := RocketPlan.lander(mission, crew)
	var pfull := 0.0
	var pcost := 0
	for id: int in pay:
		pfull += RocketParts.mass_full(id) * int(pay[id])
		pcost += price(id) * int(pay[id])
	var out: Array = []
	var best := 1 << 40
	for k in range(K_MIN, K_MAX + 1):
		var r := _solve_k(k, need, pfull, pcost, best)
		if r.is_empty():
			continue
		out.append(r)
		best = mini(best, int(r.gold))
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.gold) < int(b.gold))
	return out


func _solve_k(k: int, need: float, pfull: float, pcost: int, bound: int) -> Dictionary:
	var pt := price(BlockIds.FUEL_TANK)
	var pv := price(BlockIds.SPACE_ENGINE)
	var px := price(BlockIds.STAGE_SEPARATOR)
	var pe := price(BlockIds.ROCKET_ENGINE)
	var pf := price(BlockIds.ROCKET_FINS) * RocketCheck.FINS_NEEDED
	var M := PackedFloat64Array()
	var C := PackedInt64Array()
	var D := PackedFloat64Array()
	var par := PackedInt32Array()
	var tt := PackedInt32Array()
	var vv := PackedInt32Array()
	for t in range(1, T_TOP + 1):
		var base := pfull + _tf * t
		var v := _upper(base, 0.0)
		if v > V_TOP:
			break
		var f := base + _vm * v
		var e := pfull + _te * t + _vm * v
		M.append(f)
		C.append(pcost + pt * t + pv * v)
		D.append(_vi * G0 * log(f / e) / 1000.0)
		par.append(-1)
		tt.append(t)
		vv.append(v)
	var levels: Array = []
	var kept := _prune(M, C, D)
	var lv := _take(kept, M, C, D, par, tt, vv)
	levels.append(lv)
	for _mid in k - 2:
		var m0: PackedFloat64Array = lv.M
		var c0: PackedInt64Array = lv.C
		var d0: PackedFloat64Array = lv.D
		M = PackedFloat64Array()
		C = PackedInt64Array()
		D = PackedFloat64Array()
		par = PackedInt32Array()
		tt = PackedInt32Array()
		vv = PackedInt32Array()
		for i in m0.size():
			var above := m0[i]
			if c0[i] + pt + pv + px + pe + pt + pf + px >= bound:
				continue
			for t in range(1, T_MID + 1):
				var base := _tf * t + _xm
				var v := _upper(base, above)
				if v > V_MAX:
					break
				var c := c0[i] + pt * t + pv * v + px
				if c + pe + pt + pf + px >= bound:
					break
				var f := base + _vm * v
				var e := _te * t + _xm + _vm * v
				M.append(above + f)
				C.append(c)
				D.append(d0[i] + _vi * G0 * log((f + above) / (e + above)) / 1000.0)
				par.append(i)
				tt.append(t)
				vv.append(v)
		if M.is_empty():
			return {}
		kept = _prune(M, C, D)
		lv = _take(kept, M, C, D, par, tt, vv)
		levels.append(lv)
	var best := bound
	var pick := -1
	var pick_t := 0
	var pick_e := 0
	var ms: PackedFloat64Array = lv.M
	var cs: PackedInt64Array = lv.C
	var ds: PackedFloat64Array = lv.D
	for i in ms.size():
		var above := ms[i]
		if cs[i] + pe + pt + pf + px >= best:
			continue
		for t in range(1, T_BOT + 1):
			var e := _first(_tf * t + _fm + _xm, above)
			if e > E_MAX:
				break
			var c := cs[i] + pe * e + pt * t + pf + px
			if c >= best:
				break
			var full := _em * e + _tf * t + _fm + _xm
			var empty := _em * e + _te * t + _fm + _xm
			if ds[i] + _ei * G0 * log((full + above) / (empty + above)) / 1000.0 >= need:
				best = c
				pick = i
				pick_t = t
				pick_e = e
				break
	if pick < 0:
		return {}
	var stages: Array = [[BlockIds.ROCKET_ENGINE, pick_e, pick_t]]
	var j := pick
	for l in range(levels.size() - 1, -1, -1):
		var level: Dictionary = levels[l]
		stages.append([BlockIds.SPACE_ENGINE, int((level.v as PackedInt32Array)[j]), int((level.t as PackedInt32Array)[j])])
		j = int((level.par as PackedInt32Array)[j])
	return {"stages": stages, "gold": best}


## The fewest space engines an upper stage of `base` tonnes (without them) needs under `above` tonnes.
func _upper(base: float, above: float) -> int:
	var v := maxi(1, int((base + above) * 0.5 / (_vp - _vm * 0.5)) - 1)
	while _vp * v < (base + _vm * v + above) * RocketCheck.UPPER_MARGIN:
		v += 1
	while v > 1 and not (_vp * (v - 1) < (base + _vm * (v - 1) + above) * RocketCheck.UPPER_MARGIN):
		v -= 1
	return v


## The fewest rocket engines a first stage of `base` tonnes (without them) needs to lift off under `above` tonnes.
func _first(base: float, above: float) -> int:
	var e := maxi(1, int((base + above) * RocketCheck.LIFT_MARGIN / (_ep - _em * RocketCheck.LIFT_MARGIN)) - 1)
	while not (_ep * e >= (base + _em * e + above) * RocketCheck.LIFT_MARGIN):
		e += 1
	while e > 1 and _ep * (e - 1) >= (base + _em * (e - 1) + above) * RocketCheck.LIFT_MARGIN:
		e -= 1
	return e


## The states no other beats (lighter, cheaper and faster): their indices.
func _prune(M: PackedFloat64Array, C: PackedInt64Array, D: PackedFloat64Array) -> PackedInt32Array:
	var keys := PackedInt64Array()
	keys.resize(M.size())
	for i in M.size():
		keys[i] = (C[i] << (BITS * 2)) | (int(M[i] * 2.0) << BITS) | i
	keys.sort()
	var sm := PackedFloat64Array()
	var sd := PackedFloat64Array()
	var keep := PackedInt32Array()
	for key in keys:
		var i := key & MASK
		var m := M[i]
		var d := D[i]
		var j := sm.bsearch(m, false) - 1
		if j >= 0 and sd[j] >= d:
			continue
		keep.append(i)
		var pos := j + 1
		while pos > 0 and sm[pos - 1] == m:
			sm.remove_at(pos - 1)
			sd.remove_at(pos - 1)
			pos -= 1
		while pos < sm.size() and sd[pos] <= d:
			sm.remove_at(pos)
			sd.remove_at(pos)
		sm.insert(pos, m)
		sd.insert(pos, d)
	return keep


func _take(kept: PackedInt32Array, M: PackedFloat64Array, C: PackedInt64Array, D: PackedFloat64Array,
		par: PackedInt32Array, tt: PackedInt32Array, vv: PackedInt32Array) -> Dictionary:
	var m2 := PackedFloat64Array()
	var c2 := PackedInt64Array()
	var d2 := PackedFloat64Array()
	var p2 := PackedInt32Array()
	var t2 := PackedInt32Array()
	var v2 := PackedInt32Array()
	for i in kept:
		m2.append(M[i])
		c2.append(C[i])
		d2.append(D[i])
		p2.append(par[i])
		t2.append(tt[i])
		v2.append(vv[i])
	return {"M": m2, "C": c2, "D": d2, "par": p2, "t": t2, "v": v2}
