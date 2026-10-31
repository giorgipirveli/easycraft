class_name ProspectGear
extends RefCounted
## Prospecting's gear in the Gold Shop (spec §25.5: "tools for quests and mining (§26: a metal detector …)"): the Metal
## Detector hangs on the WEAPONS & TOOLS shelf (SpendRules.register; owned for good, this profile's, in every world).
## With it, walking near a deposit's metal makes it beep, faster and faster as the child comes closer (SurveyRules.beeps:
## half the distance, twice the beeps), and the HUD's compass points to it when no quest step is being followed. The
## quests never need it: Gemma lends hers for their steps (the compass points the way for everyone).
## Spec §26.5: the detector hears the Moon's and Mars's iron meteorites too, and the Ice Finder (on the same shelf) hears
## the Moon's and Mars's ice the same way: a neutron counter, like the ones spacecraft and rovers carry (the hydrogen in
## ice slows the neutrons coming out of the ground, so fewer arrive over ice).

const DETECTOR := "prospect:detector"
const DETECTOR_PRICE := 150       # about half a day of learning (EarnRules: a day is about 275)
## Kinds with metal a detector hears (oil and salt are not metal).
const METALS: Array[StringName] = [DepositKinds.GOLD, DepositKinds.COPPER, DepositKinds.IRON,
	DepositKinds.MOON_METEORITE, DepositKinds.MARS_METEORITE]
const ICE_FINDER := "prospect:ice_finder"
const ICE_FINDER_PRICE := 150
## Kinds of ice the Ice Finder hears.
const ICES: Array[StringName] = [DepositKinds.MOON_ICE, DepositKinds.MARS_ICE]


## Hangs the detector and the Ice Finder on the Gold Shop's WEAPONS & TOOLS shelf (a second call does nothing).
static func register_shelf() -> void:
	SpendRules.register(SpendRules.GEAR, {"id": DETECTOR, "name": "Metal Detector", "price": DETECTOR_PRICE},
		func(_profile: ProfileData, _id: String) -> void: pass)
	SpendRules.register(SpendRules.GEAR, {"id": ICE_FINDER, "name": "Ice Finder", "price": ICE_FINDER_PRICE},
		func(_profile: ProfileData, _id: String) -> void: pass)


static func has_detector(profile: ProfileData) -> bool:
	return profile != null and profile.bought.has(DETECTOR)


static func has_ice_finder(profile: ProfileData) -> bool:
	return profile != null and profile.bought.has(ICE_FINDER)


## The nearest metal a detector hears from `from` among `deposits` (their signs and ore at the top), within its range:
## {pos: Vector3, distance: float} or {}.
static func nearest_metal(rules: DepositRules, from: Vector3) -> Dictionary:
	return nearest_of(rules, from, METALS)


## The nearest ice the Ice Finder hears from `from` (spec §26.5), within its range: {pos, distance} or {}.
static func nearest_ice(rules: DepositRules, from: Vector3) -> Dictionary:
	return nearest_of(rules, from, ICES)


## The nearest sign cell of a deposit of `kinds` within the detector's range of `from`: {pos, distance} or {}.
static func nearest_of(rules: DepositRules, from: Vector3, kinds: Array[StringName]) -> Dictionary:
	if rules == null or not from.is_finite():
		return {}
	var best := {}
	var best_d := SurveyRules.DETECTOR_RANGE
	var reach := int(SurveyRules.DETECTOR_RANGE) + 1
	var r0 := DepositRules.region_of(floori(from.x) - reach, floori(from.z) - reach)
	var r1 := DepositRules.region_of(floori(from.x) + reach, floori(from.z) + reach)
	var list: Array = []
	for rz in range(r0.y, r1.y + 1):
		for rx in range(r0.x, r1.x + 1):
			list.append_array(rules.deposits_in_region(Vector2i(rx, rz)))
	for d: Dictionary in list:
		if not kinds.has(d.kind):
			continue
		var a: Vector3i = d.anchor
		if Vector2(a.x - from.x, a.z - from.z).length() > SurveyRules.DETECTOR_RANGE + 40.0:
			continue
		for signs: Array in d.signs:
			for c: Vector3i in signs:
				var p := Vector3(c) + Vector3(0.5, 0.5, 0.5)
				var dist := p.distance_to(from)
				if dist < best_d:
					best_d = dist
					best = {"pos": p, "distance": dist}
	return best
