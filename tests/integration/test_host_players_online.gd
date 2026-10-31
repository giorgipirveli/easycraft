extends GutTest
## The M4 Task 10 review's finding B (module 0.2.11), against the fake server. Online, the host took each guest's
## name and age band from the guest's own game (chat_join): a modified guest could show another player's name (chat
## lines, name tags, trades) or claim 13+ for free text on the relay chat and trades with strangers. Now an online
## host asks the server (match_players, host only) and uses its answer: the account's username, band and chat level.
## Until it answers the guest counts as under 13 and has no name; when the server can't say, the guest is "Player"
## and under 13. Online the host's relay chat carries quick phrases only (the server-checked team room carries the
## rest) and never reaches a player whose grown-up switched chat off. LAN keeps the guest's word (spec §12.11).

const FakeServer := preload("res://tests/fakes/fake_online_server.gd")
const FakeBackend := preload("res://tests/fakes/fake_online_backend.gd")
const MATCH := "3dcf6dca-ba73-4e08-a89e-8c538234f741."
const GUEST := 5

var DIR := "user://test_host_players_online_%d/" % OS.get_process_id()
var server: RefCounted
var now := 1_800_000_000
var lines: Array[Dictionary] = []
var peers := {}   # peer id -> the guest's user id, as the relay knows it


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)
	server = FakeServer.new()
	lines.clear()
	peers.clear()
	Session.chat_reset()
	Session.chat_received.connect(_on_line)


func after_each() -> void:
	Session.chat_received.disconnect(_on_line)
	Session.use_online_roster(null, false)
	Session.chat_reset()
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


func _on_line(from: String, text: String, kind: StringName) -> void:
	lines.append({"from": from, "text": text, "kind": kind})


func _texts() -> Array[String]:
	var out: Array[String] = []
	for l in lines:
		out.append(l.text)
	return out


## This game hosts MATCH online, signed in as Hostie; the guest accounts are in the match as the server sees it.
func _hosting(guests: Array) -> OnlineService:
	server.make_account("dev-h", "Hostie")
	var s := OnlineService.new()
	s.backend = FakeBackend.new(server)
	s.device_id = "dev-h"
	s.profile = ProfileData.new()
	s.profile.username = "Hostie"
	s.profile.age_band = AgeBand.TEEN_PLUS
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + "dev-h.json"
	s.clock = func() -> int: return now
	s.prefs.safe_card_seen = now
	add_child_autofree(s)
	assert_eq(await s.sign_in(), "")
	server.host_match(MATCH, s.backend.user_id(), guests)
	var roster := MatchRoster.new()
	roster.service = s
	roster.user_of = func(peer_id: int) -> String: return str(peers.get(peer_id, ""))
	roster.match_id = func() -> String: return MATCH
	Session.use_online_roster(roster, true)
	return s


## A guest account: 13+ with text chat, or an under-13 child whose parent said yes (quick chat).
func _guest(device: String, username: String, band: StringName = AgeBand.TEEN_PLUS) -> String:
	return server.make_account(device, username, band,
		OnlineRules.CONSENT_VERIFIED if band == AgeBand.UNDER_13 else OnlineRules.CONSENT_NONE, true)


func test_online_the_host_names_a_guest_as_the_server_knows_them() -> void:
	var mia := _guest("dev-m", "Mia")
	await _hosting([mia])
	peers[GUEST] = mia
	Session._host_chat_join(GUEST, "Hostie", String(AgeBand.TEEN_PLUS))   # a guest pretending to be the host
	await wait_process_frames(3)
	assert_eq(Session.chat_names.get(GUEST), "Mia", "the account's name, not the guest's claim")
	assert_true(_texts().has("Mia joined the game."))
	assert_eq(Session._chat_bands.get(GUEST), AgeBand.TEEN_PLUS)


func test_online_a_guests_own_claim_of_13_plus_counts_for_nothing() -> void:
	var kid := _guest("dev-k", "Kiddo", AgeBand.UNDER_13)
	await _hosting([kid])
	peers[GUEST] = kid
	Session._host_chat_join(GUEST, "Kiddo", String(AgeBand.TEEN_PLUS))
	await wait_process_frames(3)
	assert_eq(Session._chat_bands.get(GUEST), AgeBand.UNDER_13, "the server's band (trades read it too: _pt_refusal)")
	assert_eq(Session.pet_band_of(GUEST), AgeBand.UNDER_13)
	var me := multiplayer.get_unique_id()
	Session._chat_bands[me] = AgeBand.TEEN_PLUS
	assert_eq(Session.chat_recipients(me, "my house is blue", [me, GUEST] as Array[int]), [me] as Array[int],
		"a 13+ player's words never reach the child")


func test_until_the_server_answers_a_guest_counts_as_under_13_without_a_name() -> void:
	var mia := _guest("dev-m", "Mia")
	var host := await _hosting([mia])
	peers[GUEST] = mia
	host.backend.latency_frames = 4
	Session._host_chat_join(GUEST, "Faker", String(AgeBand.TEEN_PLUS))
	assert_eq(Session._chat_bands.get(GUEST), AgeBand.UNDER_13, "the strictest band meanwhile")
	assert_false(Session.chat_names.has(GUEST), "and no name the guest made up")
	Session._host_chat_join(GUEST, "Faker", String(AgeBand.TEEN_PLUS))   # the first registration still wins
	await wait_process_frames(10)
	assert_eq(Session.chat_names.get(GUEST), "Mia")
	assert_eq(Session._chat_bands.get(GUEST), AgeBand.TEEN_PLUS, "the server's band once it answers")
	assert_eq(_texts().count("Mia joined the game."), 1, "one welcome")


func test_when_the_server_cant_say_the_guest_is_player_and_under_13() -> void:
	var mia := _guest("dev-m", "Mia")
	await _hosting([mia])
	peers[GUEST] = mia
	server.fail_next["match_players"] = "network"
	Session._host_chat_join(GUEST, "Mia", String(AgeBand.TEEN_PLUS))
	await wait_process_frames(3)
	assert_eq(Session.chat_names.get(GUEST), "Player", "never the guest's own word")
	assert_eq(Session._chat_bands.get(GUEST), AgeBand.UNDER_13)
	assert_true(_texts().has("Player joined the game."))


func test_a_guest_the_server_does_not_list_is_player_too() -> void:
	var mia := _guest("dev-m", "Mia")
	var stranger := _guest("dev-s", "Strngr")
	await _hosting([mia])
	peers[GUEST] = stranger   # the relay's user id is not in the server's list of this match
	Session._host_chat_join(GUEST, "Strngr", String(AgeBand.TEEN_PLUS))
	await wait_process_frames(3)
	assert_eq(Session.chat_names.get(GUEST), "Player")
	assert_eq(Session._chat_bands.get(GUEST), AgeBand.UNDER_13)


func test_a_guest_who_leaves_before_the_answer_is_forgotten() -> void:
	var mia := _guest("dev-m", "Mia")
	var host := await _hosting([mia])
	peers[GUEST] = mia
	host.backend.latency_frames = 4
	Session._host_chat_join(GUEST, "Mia", String(AgeBand.TEEN_PLUS))
	Session.peer_left.emit(GUEST)
	await wait_process_frames(10)
	assert_false(Session.chat_names.has(GUEST), "no name for a player who is gone")
	assert_false(Session._chat_bands.has(GUEST))
	assert_false(_texts().has("Mia joined the game."), "no welcome")


func test_online_the_relay_carries_quick_phrases_only() -> void:
	await _hosting([])
	Session.chat_join("Hostie", AgeBand.TEEN_PLUS)   # the host's own registration (its own game)
	Session.request_chat("anyone want to build?")
	assert_eq(lines.back().kind, &"error")
	assert_eq(lines.back().text, OnlineChatRules.message("chat_resting"), "free text waits for the team room")
	Session.request_chat("Hi!")
	assert_eq(lines.back(), {"from": "Hostie", "text": "Hi!", "kind": &"chat"}, "a quick phrase still goes")


func test_online_nobody_whose_grown_up_switched_chat_off_gets_relay_chat() -> void:
	var quiet := _guest("dev-q", "Quiet")
	server.accounts[quiet].chat = OnlineRules.CHAT_OFF
	await _hosting([quiet])
	peers[GUEST] = quiet
	Session._host_chat_join(GUEST, "Quiet", String(AgeBand.TEEN_PLUS))
	await wait_process_frames(3)
	var me := multiplayer.get_unique_id()
	assert_eq(Session.chat_recipients(me, "Hi!", [me, GUEST] as Array[int]), [me] as Array[int])


func test_lan_keeps_the_guests_word() -> void:
	Session._host_chat_join(GUEST, "Lanny", String(AgeBand.TEEN_PLUS))
	assert_eq(Session.chat_names.get(GUEST), "Lanny", "LAN: the joining device's word (spec §12.11)")
	assert_eq(Session._chat_bands.get(GUEST), AgeBand.TEEN_PLUS)
	Session.request_chat("hello")   # this game's own line (never registered: under 13)
	assert_eq(lines.back().text, ChatRules.message("quick_chat_only"), "LAN's rules as before")
