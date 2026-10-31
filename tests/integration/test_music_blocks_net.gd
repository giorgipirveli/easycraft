extends GutTest
## Owner #110 (VR round 4, idea 7): friends hear each other's notes as events, never audio. The host plays a friend's
## note only when a music block is there, the friend is within a tap's reach of it and inside the budget (a two-mallet
## drum roll, never a flood), at most as loud as the cap; it passes notes on only to games that said they hear them.

const XYLO := Vector3i(2, 10, 0)
const FRIEND := 7

var world: EditWorld
var music: MusicDirector
var friend_at := Vector3(3.0, 10.0, 2.0)


class EditWorld:
	extends WorldService
	var cells := {}

	func get_block(pos: Vector3i) -> int:
		return cells.get(pos, BlockIds.AIR)


func before_each() -> void:
	friend_at = Vector3(3.0, 10.0, 2.0)
	world = EditWorld.new()
	add_child_autofree(world)
	world.cells[XYLO] = BlockIds.XYLOPHONE
	music = MusicDirector.new()
	music.name = "Music"
	music.world = world
	music.peer_feet = func(peer: int) -> Vector3: return friend_at if peer == FRIEND else Vector3.INF
	add_child_autofree(music)
	music.set_process(false)


func test_the_host_plays_a_friends_note_on_a_music_block_near_them() -> void:
	assert_eq(music.host_note(FRIEND, XYLO, 3, -8.0), "")
	assert_eq(music.played, 1)
	assert_eq([music.last_voice, music.last_cell, music.last_from], [3, XYLO, FRIEND])
	assert_almost_eq(music.last_db, -8.0, 0.001)


func test_the_host_refuses_what_is_not_a_note() -> void:
	assert_eq(music.host_note(FRIEND, XYLO + Vector3i.UP, 3, -8.0), "no_instrument", "nothing there")
	assert_eq(music.host_note(FRIEND, XYLO, MusicBlockRules.VOICES, -8.0), "unknown")
	assert_eq(music.host_note(FRIEND, XYLO, -1, -8.0), "unknown")
	assert_eq(music.host_note(99, XYLO, 3, -8.0), "too_far", "a game with no player")
	friend_at = Vector3(3.0, 10.0, 2.0 + MusicBlockRules.REACH + 1.0)
	assert_eq(music.host_note(FRIEND, XYLO, 3, -8.0), "too_far")
	assert_eq(music.played, 0)


func test_a_flood_is_cut_to_the_budget_and_a_note_is_never_louder_than_the_cap() -> void:
	var played := 0
	for i in 40:
		if music.host_note(FRIEND, XYLO, i % 8, 6.0) == "":
			played += 1
	assert_eq(played, MusicBlockRules.NOTES_PER_SECOND, "a second's budget")
	assert_almost_eq(music.last_db, MusicBlockRules.MAX_DB, 0.001, "the cap")
	music.step(1.1)
	assert_eq(music.host_note(FRIEND, XYLO, 1, -6.0), "", "a second later")


func test_notes_go_only_to_games_that_hear_them() -> void:
	assert_true(music._listeners.is_empty(), "nobody said so yet: an older build never gets a call it lacks")
	music.host_listen(FRIEND)
	assert_true(music._listeners.has(FRIEND))
	music.strike(XYLO, Vector3i.UP, Vector3(0.5, 1.0, 0.5), 1.0)   # solo: nothing to send, nothing breaks
	assert_eq(music.played, 1)
