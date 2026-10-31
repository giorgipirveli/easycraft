class_name InviteSender
extends RefCounted
## Owner #79 (spec §25.2): tells the server what this child's profile says and it has not heard yet (the first unit
## mastered, a first Moon landing: InviteData.events_to_send), through the game's online service when it is signed in
## now. Otherwise the next sign-in sends it (OnlineService, section "Owner #79"): nothing waits for the network.

static func send_soon() -> void:
	var s: OnlineService = Session.online_service_or_null()
	if s != null and s.status == OnlineService.ONLINE:
		s.send_invite_events()
