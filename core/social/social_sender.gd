class_name SocialSender
extends RefCounted
## Owner #81, #82, #85: tells the server (module 0.2.18) what friends should hear, from wherever it happens: this child
## learned today (a School round finished, the Daily Mission done: friendship days, study buddies, the crew's week),
## mastered a unit, or had a proud moment friends can cheer (PostcardRules' moments). The profile keeps it
## (SocialData) until the game's online service is signed in; nothing waits for the network. The caller saves.

static func learned(unit: String = "", profile: ProfileData = null) -> void:
	var p := profile if profile != null else Profile.data
	p.social.note_learned(DailyMission.today(), unit)
	send_soon()


## A proud moment (PostcardRules.moment) for friends to cheer.
static func moment(m: Dictionary, profile: ProfileData = null) -> void:
	var p := profile if profile != null else Profile.data
	if p.social.note_moment(str(m.get("kind", "")), str(m.get("place", ""))):
		send_soon()


static func send_soon() -> void:
	var s: OnlineService = Session.online_service_or_null()
	if s != null and s.status == OnlineService.ONLINE:
		s.send_social_events()
