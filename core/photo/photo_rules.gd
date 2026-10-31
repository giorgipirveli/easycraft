class_name PhotoRules
extends RefCounted
## Photo mode and the rest of the game (M3 Task 16 rulings, docs/devlog/parts/m3-task-16.md).


## Solo play freezes the world while you frame a picture (monsters wait, nothing can hurt you).
## On LAN the world belongs to everyone, so nothing pauses.
static func pauses_world(net_mode: StringName) -> bool:
	return net_mode == &"solo"


## On LAN a hit drops you out of photo mode so you can react. Healing (hearts coming back) doesn't;
## hp_before < 0 means the hearts aren't known yet.
static func exits_on_hurt(hp_before: int, hp_after: int) -> bool:
	return hp_before >= 0 and hp_after < hp_before


# --- M5 store readiness F1 (spec §5.9, §5.14): photo sharing is a grown-up's switch --------------------------

## SHARE sends a photo out of the game through the phone's share sheet. ProfileData.photo_share: AUTO = on for
## 13+, off for children (and a profile without a valid band) until a grown-up picks ON or OFF, which then holds.
const SHARE_AUTO := &"auto"
const SHARE_ON := &"on"
const SHARE_OFF := &"off"
const SHARE_SWITCHES: Array[StringName] = [SHARE_AUTO, SHARE_ON, SHARE_OFF]


static func valid_share_switch(s: StringName) -> StringName:
	return s if SHARE_SWITCHES.has(s) else SHARE_AUTO


## Whether photo mode may offer SHARE to a player of `band` with this switch.
static func may_share(band: StringName, switch: StringName) -> bool:
	match valid_share_switch(switch):
		SHARE_ON:
			return true
		SHARE_OFF:
			return false
	return band == AgeBand.TEEN_PLUS
