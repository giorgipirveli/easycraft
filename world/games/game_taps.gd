class_name GameTaps
extends RefCounted
## A seeker's tap on a hiding spot in hide-and-seek (M4 Wave 3, agent H): checked by BlockInteractor
## before hiding in it, whatever is in the hand. While this game's player seeks, a tap on a barrel,
## closet or bush looks inside (the host decides: Session.games_request_spot) instead of hiding in it,
## building on it or breaking it. Returns true when the tap was used.

static func tap(interactor: BlockInteractor, screen_pos: Vector2) -> bool:
	var player := interactor.player
	if player == null or not player.is_spawned() or player.world == null:
		return false
	var games := interactor.get_tree().get_first_node_in_group(&"games_director") as GamesDirector
	if games == null or not games.seeking_here():
		return false
	var hit := interactor.ray_at(screen_pos)
	if hit == null or not BotGamePlans.HIDING_SPOTS.has(player.world.get_block(hit.position)):
		return false
	Session.games_request_spot(hit.position)
	return true
