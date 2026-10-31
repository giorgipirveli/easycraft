class_name OnlineFlow
extends RefCounted
## From PLAY ONLINE into a world (M4 Wave 1, Agent C): HOST MY WORLD hosts this mode's own saved
## world (a new one when there is none) as a relayed match; JOIN (an invite) saves the world being
## played, leaves it and joins the friend's match. Session's spike path does the rest, exactly as
## for LAN (Game.host_lan_game / join_lan_game with Session.online_config set).


static func host(world_mode: StringName) -> void:
	Session.prepare_online_host()
	Game.mode = ModeRules.valid(world_mode)
	var fresh := not WorldSaves.exists(ModeRules.slot(Game.mode))
	Game.host_lan_game()
	Game.start_new_world = fresh   # read when the world scene starts (the scene change is deferred)


## False when `match_id` is not a match id (nothing changes then). In a world, the world scene saves
## and leaves first (sandbox.leave_for_online).
static func join(match_id: String) -> bool:
	if OnlineConfig.normalize_match_id(match_id) == "":
		return false
	var scene := Session.get_tree().current_scene
	if scene and scene.has_method("leave_for_online"):
		scene.call("leave_for_online", match_id)
	else:
		join_now(match_id)
	return true


## Leaves whatever game runs (Session.close) and joins the match in a new world scene.
static func join_now(match_id: String) -> void:
	Session.close()
	Session.prepare_online_join(match_id)
	Game.join_lan_game("")
