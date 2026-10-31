extends OnlineBackend
## One game's connection to a FakeOnlineServer (tests/fakes/fake_online_server.gd), behind the same
## interface as NakamaOnlineBackend. `latency_frames` makes every call wait like a real network
## call does (the UI must not act twice meanwhile).

var server: RefCounted   # the shared fake server
var latency_frames := 0
## Calls whose answer comes back late: name -> frames. The server has done the call at once (it reached the server
## first), only its answer is slow: two calls in flight then end in the other order than the server did them
## (the gold-double bug, 2026-10-01: docs/devlog/parts/gold-double.md).
var answer_frames := {}
## Calls whose answer the network loses: name -> how many. The server has done the call (a code paid, gold moved),
## but the game hears {"ok": false, "error": "network"} (the gold-double bug's leftover, module 0.2.19).
var lose_answers := {}
## Calls that reach the server late: name -> frames before the server does the call (its answer follows at once).
var call_frames := {}

var _uid := ""


func _init(fake_server: RefCounted = null) -> void:
	server = fake_server


func sign_in(_server: Dictionary, device_id: String, create: bool = true) -> Dictionary:
	await _wait()
	var r: Dictionary = server.sign_in(self, device_id, create)
	if r.ok:
		_uid = r.user_id
	return r


## Owner #105: another connection to the same server (LOG IN asks on its own while this one plays on).
func make_twin() -> OnlineBackend:
	return get_script().new(server)


func is_signed_in() -> bool:
	return _uid != ""


func user_id() -> String:
	return _uid


func call_rpc(id: String, payload: Dictionary = {}) -> Dictionary:
	return await _call(id, payload)


func list_friends() -> Dictionary:
	return await _call("list_friends", {})


func add_friend_by_name(username: String) -> Dictionary:
	return await _call("add_friend_by_name", {"username": username})


func add_friend_by_id(id: String) -> Dictionary:
	return await _call("add_friend_by_id", {"id": id})


func remove_friend(id: String) -> Dictionary:
	return await _call("remove_friend", {"id": id})


func block(id: String) -> Dictionary:
	return await _call("block", {"id": id})


func read_storage(collection: String, key: String) -> Dictionary:   # M4 F
	return await _call("read_storage", {"collection": collection, "key": key})


func write_storage(collection: String, key: String, value: String, version: String = "") -> Dictionary:   # M4 F; owner #67
	return await _call("write_storage", {"collection": collection, "key": key, "value": value, "version": version})


func sign_out() -> void:
	if _uid != "":
		server.sign_out(self, _uid)
		_uid = ""
		closed.emit()


## The network dropped (the server still knows the account).
func drop() -> void:
	sign_out()


# --- M4 E: chat channels ---

func join_chat(target: String, type: int, persist: bool) -> Dictionary:
	return await _chat("join_chat", {"target": target, "type": type, "persist": persist})


func leave_chat(channel_id: String) -> Dictionary:
	return await _chat("leave_chat", {"channel_id": channel_id})


func send_chat(channel_id: String, content: Dictionary) -> Dictionary:
	return await _chat("send_chat", {"channel_id": channel_id, "content": content})


func chat_history(channel_id: String, limit: int) -> Dictionary:
	return await _chat("chat_history", {"channel_id": channel_id, "limit": limit})


## Chat calls name this connection: messages come to the connections that joined a channel.
func _chat(name: String, payload: Dictionary) -> Dictionary:
	await _wait()
	if _uid == "":
		return NOT_SIGNED_IN
	return server.chat_named(self, name, _uid, payload)


func _call(name: String, payload: Dictionary) -> Dictionary:
	for i in int(call_frames.get(name, 0)):
		if is_inside_tree():
			await get_tree().process_frame
	if int(lose_answers.get(name, 0)) > 0 and _uid != "":
		lose_answers[name] = int(lose_answers[name]) - 1
		await _wait()
		server.call_named(name, _uid, payload)   # done on the server...
		return {"ok": false, "error": "network"}   # ...but its answer never arrives
	if answer_frames.has(name) and _uid != "":
		var answer: Dictionary = server.call_named(name, _uid, payload)
		for i in int(answer_frames[name]):
			if is_inside_tree():
				await get_tree().process_frame
		return answer
	await _wait()
	if _uid == "":
		return NOT_SIGNED_IN
	return server.call_named(name, _uid, payload)


func _wait() -> void:
	for i in latency_frames:
		if is_inside_tree():
			await get_tree().process_frame
