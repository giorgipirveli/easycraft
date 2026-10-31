class_name BuddyNames
extends RefCounted
## Cute, stable names for buddies: the same build always gets the same name.

const START: Array[String] = ["Bo", "Zu", "Mi", "Ka", "Pu", "Te", "Lo", "Fi", "Ru", "Ne", "Wi", "Ga"]
const END: Array[String] = ["bble", "zzy", "mo", "nky", "ppy", "doo", "lu", "rto", "xie", "bo", "mble", "nko"]


static func name_for(blocks: Dictionary) -> String:
	var h := 17
	var keys := blocks.keys()
	keys.sort()
	for p: Vector3i in keys:
		h = (h * 31 + p.x * 73856093 + p.y * 19349663 + p.z * 83492791 + int(blocks[p]) * 2654435) & 0x7fffffff
	return START[h % START.size()] + END[(h / START.size()) % END.size()]
