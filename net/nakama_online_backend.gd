class_name NakamaOnlineBackend
extends OnlineBackend
## OnlineService's backend on the Nakama server (M4 Wave 1, Agent C): a NakamaLink of its own
## (sign-in by device id, the realtime socket), the game's RPCs (server/modules, Agent B), Nakama's
## friends API, notifications and friends' online status. It is loaded by path (Session), never by
## name from game code, so solo and LAN games never load the Nakama client.
##
## Nakama's errors become the short codes OnlineRules.message knows. This connection appears online
## (update_status) so friends see a green dot; the match itself runs on Session's own link.

const LINK_SCRIPT := "res://net/nakama_link.gd"

var _link: NakamaLink


func sign_in(server: Dictionary, device_id: String, create: bool = true) -> Dictionary:
	sign_out()
	_link = (load(LINK_SCRIPT) as GDScript).new()
	_link.name = "Link"
	add_child(_link)
	var link := _link
	var err: String = await link.sign_in(server, device_id, create)
	if link != _link:
		return {"ok": false, "error": "not_signed_in"}   # signed out meanwhile
	if err != "":
		var gone := not create and link.sign_in_status == 404   # owner #105: no account has this device id any more
		# The third review's D: the server refuses a device unlinked from a claimed account with its own code
		var logged_out := link.sign_in_status == 403 and err.contains("device_logged_out")
		_drop_link()
		return {"ok": false, "error": "device_logged_out" if logged_out else ("account_gone" if gone else err)}
	link.socket.received_notification.connect(_on_notification)
	link.socket.received_status_presence.connect(_on_status_presence)
	link.socket.received_channel_message.connect(_on_channel_message)   # M4 E
	link.closed.connect(_on_closed)
	await link.socket.update_status_async("online")   # friends see this player online
	await _settle()
	return {"ok": true, "user_id": link.session.user_id, "username": link.session.username}


## Owner #105: another connection to the server, its own link (LOG IN asks with it).
func make_twin() -> OnlineBackend:
	return get_script().new()


func is_signed_in() -> bool:
	return _link != null and _link.session != null and _link.socket != null and _link.socket.is_connected_to_host()


func user_id() -> String:
	return _link.session.user_id if _link and _link.session else ""


func call_rpc(id: String, payload: Dictionary = {}) -> Dictionary:
	if not is_signed_in():
		return NOT_SIGNED_IN
	var r: NakamaAPI.ApiRpc = await _link.client.rpc_async(_link.session, id, JSON.stringify(payload))
	await _settle()
	if r.is_exception():
		return {"ok": false, "error": rpc_error(r.get_exception())}
	var json := JSON.new()
	if json.parse(r.payload) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {"ok": false, "error": "server"}
	var d: Dictionary = json.data
	if not d.has("ok"):
		d.ok = not d.has("error")
	return d


func list_friends() -> Dictionary:
	if not is_signed_in():
		return NOT_SIGNED_IN
	var r = await _link.client.list_friends_async(_link.session, null, 1000)   # ApiFriendList
	await _settle()
	if r.is_exception():
		return {"ok": false, "error": friend_error(r.get_exception())}
	var out: Array = []
	for f: NakamaAPI.ApiFriend in r.friends:
		if f.user:
			out.append({"id": f.user.id, "username": f.user.username, "state": f.state, "online": f.user.online})
	return {"ok": true, "friends": out}


func add_friend_by_name(username: String) -> Dictionary:
	if not is_signed_in():
		return NOT_SIGNED_IN
	return await _friends(_link.client.add_friends_async.bind(_link.session, null, PackedStringArray([username])))


func add_friend_by_id(id: String) -> Dictionary:
	if not is_signed_in():
		return NOT_SIGNED_IN
	return await _friends(_link.client.add_friends_async.bind(_link.session, PackedStringArray([id]), null))


func remove_friend(id: String) -> Dictionary:
	if not is_signed_in():
		return NOT_SIGNED_IN
	return await _friends(_link.client.delete_friends_async.bind(_link.session, PackedStringArray([id])))


func block(id: String) -> Dictionary:
	if not is_signed_in():
		return NOT_SIGNED_IN
	return await _friends(_link.client.block_friends_async.bind(_link.session, PackedStringArray([id])))


## Friends' online status: who is online now, then every change (presence_changed).
func follow(ids: Array[String]) -> void:
	if not is_signed_in() or ids.is_empty():
		return
	var status = await _link.socket.follow_users_async(PackedStringArray(ids), PackedStringArray())
	await _settle()
	if status == null or status.is_exception():
		return
	for p in status.presences:
		presence_changed.emit(str(p.user_id), true)


## M4 Wave 2, agent F: this player's own storage (the profile backup, collection "profiles").
func read_storage(collection: String, key: String) -> Dictionary:
	if not is_signed_in():
		return NOT_SIGNED_IN
	var r = await _link.client.read_storage_objects_async(_link.session,   # ApiStorageObjects
		[NakamaStorageObjectId.new(collection, key, _link.session.user_id)])
	await _settle()
	if r.is_exception():
		return {"ok": false, "error": _common_error(r.get_exception())}
	for o: NakamaAPI.ApiStorageObject in r.objects:
		return {"ok": true, "value": o.value, "version": o.version}
	return {"ok": true, "value": "", "version": ""}


## Owner read (1) and owner write (1): private, as the server's guard requires for "profiles".
func write_storage(collection: String, key: String, value: String, version: String = "") -> Dictionary:
	if not is_signed_in():
		return NOT_SIGNED_IN
	var r = await _link.client.write_storage_objects_async(_link.session,   # ApiStorageObjectAcks
		[NakamaWriteStorageObject.new(collection, key, 1, 1, value, version)])
	await _settle()
	if r.is_exception():
		var e: NakamaException = r.get_exception()
		return {"ok": false, "error": storage_error(e)}
	var written := ""
	for a: NakamaAPI.ApiStorageObjectAck in r.acks:
		written = a.version
	return {"ok": true, "version": written}


func sign_out() -> void:
	if _link == null:
		return
	_drop_link()
	closed.emit()


## A storage write's error as a code: the server module's own refusals (not_allowed, bad_profile, too_big) as they
## are, Nakama's "Storage write rejected - version check failed." as "version_clash" (owner #67: another device of
## the account wrote first).
static func storage_error(e: NakamaException) -> String:
	if e.message.to_lower().contains("version check"):
		return "version_clash"
	return e.message if e.status_code in [400, 403] else _common_error(e)


## An RPC error as a code: a missing RPC is "not_yet" (the server module is older than the game).
static func rpc_error(e: NakamaException) -> String:
	if e.status_code == 404 or e.grpc_status_code == 5:
		return "not_yet"
	return _common_error(e)


## A friends-API error as a code (Nakama answers "No valid ID or username was provided." when the
## username does not exist, and "Cannot add self as friend.").
static func friend_error(e: NakamaException) -> String:
	var m := e.message.to_lower()
	if m.contains("self"):
		return "self"
	if m.contains("no valid id or username") or e.status_code == 404 or e.grpc_status_code == 5:
		return "no_such_player"
	return _common_error(e)


static func _common_error(e: NakamaException) -> String:
	if e.status_code == 429 or e.grpc_status_code == 8:
		return "rate_limited"
	if e.status_code == 401 or e.grpc_status_code == 16:
		return "unauthorized"
	if e.status_code <= 0 or e.status_code >= 500 or e.grpc_status_code == 14:
		return "network"
	return e.message


func _friends(call: Callable) -> Dictionary:
	var r: NakamaAsyncResult = await call.call()
	await _settle()
	if r.is_exception():
		return {"ok": false, "error": friend_error(r.get_exception())}
	return {"ok": true}


func _on_notification(n: NakamaAPI.ApiNotification) -> void:
	notified.emit(n.code, n.content, n.sender_id)


func _on_status_presence(e: NakamaRTAPI.StatusPresenceEvent) -> void:
	for p in e.leaves:
		presence_changed.emit(str(p.user_id), false)
	for p in e.joins:
		presence_changed.emit(str(p.user_id), true)


func _on_closed() -> void:
	if _link != null:
		_drop_link()   # the socket is already closed: leave() only frees the link
		closed.emit()


func _drop_link() -> void:
	var link := _link
	_link = null
	if link.closed.is_connected(_on_closed):
		link.closed.disconnect(_on_closed)
	link.leave()


## The client's awaits resume inside its HTTPRequest's or socket's signal; one frame later the
## caller may free things at once.
func _settle() -> void:
	if is_inside_tree():
		await get_tree().process_frame

# --- M4 E: chat channels (friends' DMs and a match's team room; spec §17.4) ---
# The server's hooks (server/modules/src/server/chat.ts) refuse with their code as the error's
# message: chat_error keeps those codes for OnlineChatRules.message.

const CHAT_CODES: Array[String] = ["quick_chat_only", "personal_info", "blocked_word", "empty", "chat_off",
	"not_friends", "room_not_allowed", "not_in_channel", "bad_message", "not_available"]


func join_chat(target: String, type: int, persist: bool) -> Dictionary:
	if not is_signed_in():
		return NOT_SIGNED_IN
	var ch: NakamaRTAPI.Channel = await _link.socket.join_chat_async(target, type, persist, false)
	await _settle()
	if ch.is_exception():
		return {"ok": false, "error": chat_error(ch.get_exception())}
	return {"ok": true, "channel_id": ch.id}


func leave_chat(channel_id: String) -> Dictionary:
	if not is_signed_in():
		return NOT_SIGNED_IN
	var r: NakamaAsyncResult = await _link.socket.leave_chat_async(channel_id)
	await _settle()
	if r.is_exception():
		return {"ok": false, "error": chat_error(r.get_exception())}
	return {"ok": true}


func send_chat(channel_id: String, content: Dictionary) -> Dictionary:
	if not is_signed_in():
		return NOT_SIGNED_IN
	var ack = await _link.socket.write_chat_message_async(channel_id, content)   # ChannelMessageAck
	await _settle()
	if ack.is_exception():
		return {"ok": false, "error": chat_error(ack.get_exception())}
	return {"ok": true, "message_id": str(ack.message_id)}


func chat_history(channel_id: String, limit: int) -> Dictionary:
	if not is_signed_in():
		return NOT_SIGNED_IN
	var list = await _link.client.list_channel_messages_async(_link.session, channel_id, limit, false)   # ApiChannelMessageList
	await _settle()
	if list.is_exception():
		return {"ok": false, "error": chat_error(list.get_exception())}
	var out: Array = []
	for m: NakamaAPI.ApiChannelMessage in list.messages:
		out.append(message_fields(m))
	return {"ok": true, "messages": out}


## A chat refusal as a code: the hook's own code, else the common ones.
static func chat_error(e: NakamaException) -> String:
	var m := e.message.strip_edges().to_lower()
	for code in CHAT_CODES:
		if m == code or m.ends_with(": " + code):
			return code
	return _common_error(e)


static func message_fields(m: NakamaAPI.ApiChannelMessage) -> Dictionary:
	return {"channel_id": m.channel_id, "message_id": m.message_id, "sender_id": m.sender_id, "username": m.username,
		"content": m.content, "create_time": m.create_time, "code": m.code}


func _on_channel_message(m: NakamaAPI.ApiChannelMessage) -> void:
	chat_message.emit(message_fields(m))
