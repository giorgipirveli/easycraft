class_name MatchRoster
extends RefCounted
## Who plays in the relayed match this game hosts online, as the server knows them (the M4 Task 10 review's finding
## B, module 0.2.11: match_players). Online, the host's game names its players and checks its relay chat, trades and
## pets with this, never with a guest's own word (chat_join): a modified guest could show another player's name or
## claim 13+. Session uses it only as an online host; LAN keeps trusting the joining device (spec §12.11).

var service: OnlineService
var user_of := Callable()    # (peer id) -> the player's Nakama user id, "" when the relay doesn't know it
var match_id := Callable()   # () -> the relayed match this game hosts


## {"username", "age_band", "chat_level"} of the player at `peer_id` from the server, or {} when it can't say (not
## signed in, no answer, a peer the relay doesn't know, a player the server doesn't list in the match).
func lookup(peer_id: int) -> Dictionary:
	var uid := str(user_of.call(peer_id)) if user_of.is_valid() else ""
	if uid == "" or service == null or service.status != OnlineService.ONLINE:
		return {}
	var r: Dictionary = await service.match_players(str(match_id.call()) if match_id.is_valid() else "")
	return players_from(r).get(uid, {})


## The server's answer read carefully: user id -> {"username" ("" when it is not a username), "age_band" (a band
## that is not one reads as under 13), "chat_level" (one that is not one reads as off)}. {} for a failed answer.
static func players_from(r: Dictionary) -> Dictionary:
	var out := {}
	var list: Variant = r.get("players")
	if not r.get("ok", false) or not list is Array:
		return out
	for p: Variant in list:
		if not p is Dictionary or not (p as Dictionary).get("user_id") is String or str(p.user_id) == "":
			continue
		var d := p as Dictionary
		var name: Variant = d.get("username")
		var band := StringName(str(d.get("age_band", ""))) if d.get("age_band") is String else &""
		var level: Variant = d.get("chat_level")
		out[str(d.user_id)] = {
			"username": str(name) if name is String and UsernameRules.validate(str(name)) == "" else "",
			"age_band": AgeBand.effective(band),
			"chat_level": str(level) if level is String and str(level) in [OnlineRules.CHAT_OFF, OnlineRules.CHAT_QUICK,
				OnlineRules.CHAT_FILTERED] else OnlineRules.CHAT_OFF,
		}
	return out
