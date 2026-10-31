extends GutTest
## The gold-double bug's leftover (module 0.2.19, docs/devlog/parts/gold-double.md) end to end over the real Nakama
## client: the server pays a code, but its answer is lost on the way back (a backend that drops it); the phone pays by
## its own check, and the code's 1000 must still be the account's once: a sync, a new sign-in, asking again. Against
## EASYCRAFT_TEST_SERVER=<host:port> (default 127.0.0.1:7350), skipped when no server answers, pending when its module
## is older than 0.2.19 (an older server can't say it paid: the old double stays there until the deploy).

const FIRST_CODE := "sasa192974"   # only in tests: 1000 gold, once per account


## The real backend, but the answers of the calls named in `lose` never arrive (the server did the call).
class LossyBackend:
	extends NakamaOnlineBackend
	var lose := {}

	func call_rpc(id: String, payload: Dictionary = {}) -> Dictionary:
		var r: Dictionary = await super.call_rpc(id, payload)
		if int(lose.get(id, 0)) > 0:
			lose[id] = int(lose[id]) - 1
			return {"ok": false, "error": "network"}
		return r


var server := OnlineConfig.parse_server(OS.get_environment("EASYCRAFT_TEST_SERVER"))
var DIR := "user://test_nakama_wallet_exact_%d/" % OS.get_process_id()
var _nodes: Array[Node] = []


func should_skip_script():   # untyped like GutTest's own: "-> Variant" fails to parse in a full run
	var http := HTTPRequest.new()
	http.timeout = 5.0
	add_child(http)
	var err := http.request("http://%s:%d/healthcheck" % [server.host, server.port])
	var answer: Array = await http.request_completed if err == OK else [HTTPRequest.RESULT_CANT_CONNECT, 0]
	http.queue_free()
	if int(answer[0]) == HTTPRequest.RESULT_SUCCESS and int(answer[1]) == 200:
		return false
	return "no Nakama server at %s:%d (server/dev.sh up)" % [server.host, server.port]


func before_each() -> void:
	DirAccess.make_dir_recursive_absolute(DIR)


func after_each() -> void:
	for n in _nodes:
		if is_instance_valid(n) and n.has_method("sign_out"):
			n.call("sign_out")
	await wait_seconds(0.3)   # NakamaLink.leave frees each link after its leave message
	for n in _nodes:
		if is_instance_valid(n):
			n.free()
	_nodes.clear()
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute(DIR.path_join(f))


func after_all() -> void:
	DirAccess.remove_absolute(DIR)


## A phone signed in with a claimed name, its wallet synced (0 gold), its backend dropping answers on request.
func _phone() -> OnlineService:
	var name := "Gd"
	for i in 10:
		name += "abcdefghijklmnopqrstuvwxyz"[randi() % 26]
	var p := ProfileData.new()
	p.username = name
	p.age_band = AgeBand.TEEN_PLUS
	p.survivor_gold = 0
	var s := OnlineService.new()
	s.backend = LossyBackend.new()
	s.server = server
	s.device_id = DeviceId.generate()
	s.profile = p
	s.save_profile = func() -> void: pass
	s.prefs_path = DIR + name + "_prefs.json"
	s.wallet_path = DIR + name + "_wallet.json"
	add_child(s)
	_nodes.append(s)
	assert_eq(await s.sign_in(), "")
	return s


## The module says what it paid (0.2.19 and later).
func _new_enough(s: OnlineService) -> bool:
	var r: Dictionary = await s.backend.call_rpc("healthcheck", {})
	var v := str(r.get("version", "0.0.0")).split(".")
	var ok := v.size() == 3 and (int(v[0]) > 0 or int(v[1]) > 2 or (int(v[1]) == 2 and int(v[2]) >= 19))
	if not ok:
		pending("the server runs module %s; the lost answer's fix needs 0.2.19" % r.get("version", "?"))
	return ok


func _server_gold(s: OnlineService) -> int:
	var r: Dictionary = await s.backend.call_rpc("get_account_state", {})
	return int(r.get("gold", -1))


func test_a_code_whose_answer_was_lost_is_the_accounts_once() -> void:
	var s := await _phone()
	if not await _new_enough(s):
		return
	assert_eq(await s.claim_username(s.profile.username), "")
	assert_eq(await s.sync_wallet(), "")
	(s.backend as LossyBackend).lose = {"redeem_code": 1}
	var r: Dictionary = await s.redeem_code(FIRST_CODE, CodeTries.new(), 0)
	assert_eq(r.status, CodeRules.ACCEPTED, "no answer: the phone's own check")
	assert_eq(s.profile.survivor_gold, 1000)
	assert_eq(await _server_gold(s), 1000, "the server paid it too")
	assert_eq(await s.sync_wallet(), "")
	assert_eq(await _server_gold(s), 1000, "not 2000")
	assert_eq(s.profile.survivor_gold, 1000)
	assert_eq(s.profile.codes_unsettled, {})
	var again: Dictionary = await s.redeem_code(FIRST_CODE, CodeTries.new(), 0)
	assert_eq(again.status, CodeRules.ALREADY_USED)
	assert_eq(s.profile.survivor_gold, 1000)


func test_a_lost_code_answer_is_settled_at_the_next_sign_in() -> void:
	var s := await _phone()
	if not await _new_enough(s):
		return
	assert_eq(await s.claim_username(s.profile.username), "")
	assert_eq(await s.sync_wallet(), "")
	(s.backend as LossyBackend).lose = {"redeem_code": 1}
	await s.redeem_code(FIRST_CODE, CodeTries.new(), 0)
	s.sign_out()
	assert_eq(await s.sign_in(), "")   # records the codes, then syncs
	assert_eq(await _server_gold(s), 1000)
	assert_eq(s.profile.survivor_gold, 1000)
	assert_eq(s.profile.codes_unsettled, {})
