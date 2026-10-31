class_name ShopGuide
extends RefCounted
## Finding Tilly (owner #37, spec §14.23). Pure. MORE → SHOP shows the nearest full shop (Tilly's stall, or a
## villager who trades with her rules) with the way and the distance; the HUD's find arrow shows the way, and the
## shop opens by itself once the child is there (within the tap reach). The first time a child plays a Survivor
## world a picture tip says where she is: once per profile (ProfileData.hints_seen).

const TIP := "shop_tip"
const TIP_TEXT := "Tilly's shop is near!\nMORE, then SHOP shows the way."
const TIP_SECONDS := 7.0
const FOLLOW := "Follow the arrow to %s!"


## The nearest of `shops` ({pos: Vector3, what: String}) to `from`; {} when there is none.
static func nearest(shops: Array, from: Vector3) -> Dictionary:
	var best := {}
	var best_d := INF
	for s: Variant in shops:
		if not (s is Dictionary) or not ((s as Dictionary).get("pos") is Vector3):
			continue
		var pos: Vector3 = s.pos
		if not pos.is_finite():
			continue
		var d := pos.distance_to(from)
		if d < best_d:
			best_d = d
			best = s
	return best


## {angle (radians from straight ahead, + right), distance (blocks, sideways)} from `from` for a camera turned `yaw`.
static func way(from: Vector3, yaw: float, to: Vector3) -> Dictionary:
	return SurpriseRules.compass(from, to, yaw)


static func distance_words(blocks: int) -> String:
	return Lang.t("%d m") % maxi(blocks, 0)


## Close enough to trade: the shop opens (the tap's reach, eye to the trader's chest).
static func there(eye: Vector3, trader_pos: Vector3) -> bool:
	return TraderRules.in_reach(eye, trader_pos, TraderRules.TAP_REACH)


## The first-time tip: Survivor only, once per profile.
static func wants_tip(hints_seen: Array[String], mode: StringName) -> bool:
	return TraderRules.wants_trader(mode) and not hints_seen.has(TIP)
