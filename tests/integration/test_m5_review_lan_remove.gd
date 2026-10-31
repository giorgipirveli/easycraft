extends GutTest
## M5 Task 6 (the whole-game review), spec §17.3 "Safety in the world": online, a player the host removes is struck off
## the invite list and can't come back; on LAN the host only dropped the connection, so the removed player could join
## again at once (JOIN on the same Wi-Fi) and REMOVE meant nothing. Now a LAN host remembers where a removed player's
## game connected from and turns that game away (with the same kind words) for as long as it hosts.
## Real ENet on this machine: the host is Session (the root multiplayer), each guest a bare ENet client polled here.

var PORT := 45_000 + OS.get_process_id() % 1000
var guests: Array[ENetMultiplayerPeer] = []


func after_each() -> void:
	for g in guests:
		g.close()
	guests.clear()
	Session.close()


## A guest's game connecting from this machine; its peer id on the host, or 0 when it never got in.
func _join() -> int:
	var before := multiplayer.get_peers()
	var g := ENetMultiplayerPeer.new()
	assert_eq(g.create_client("127.0.0.1", PORT), OK)
	guests.append(g)
	for i in 300:
		g.poll()
		await get_tree().process_frame
		for p in multiplayer.get_peers():
			if not before.has(p):
				return p
	return 0


## Waits until `peer` is no longer on the host (true) or `frames` pass (false).
func _gone(peer: int, g: ENetMultiplayerPeer, frames: int = 120) -> bool:
	for i in frames:
		g.poll()
		await get_tree().process_frame
		if not multiplayer.get_peers().has(peer):
			return true
	return false


func test_a_player_the_host_removed_on_lan_cant_come_straight_back() -> void:
	assert_eq(Session.host_lan(PORT), OK)
	var first := await _join()
	assert_ne(first, 0, "the guest joined")
	assert_eq(await Session.host_remove_guest(first), "")
	assert_true(await _gone(first, guests[0]), "removed")
	var again := await _join()
	assert_ne(again, 0, "the same game connects again")
	assert_true(await _gone(again, guests[1]), "and is turned away: the host removed that player")
	assert_eq(guests[1].get_connection_status(), MultiplayerPeer.CONNECTION_DISCONNECTED)


func test_a_new_lan_game_forgets_whom_the_last_one_removed() -> void:
	assert_eq(Session.host_lan(PORT), OK)
	var first := await _join()
	assert_eq(await Session.host_remove_guest(first), "")
	assert_true(await _gone(first, guests[0]))
	Session.close()
	assert_eq(Session.host_lan(PORT), OK)
	var again := await _join()
	assert_ne(again, 0)
	assert_false(await _gone(again, guests[1], 40), "another hosting: everyone may join again")
