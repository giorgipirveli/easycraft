extends RefCounted
## An in-memory stand-in for the Nakama server with Agent B's RPCs and hooks (M4 Wave 1, Agent C's
## tests): accounts by device id, Nakama's friend edges (0 friends, 1 asked, 2 asked me, 3 blocked)
## and presence, notifications, and the RPCs named in the plan's Wave 1 table, answering as Agent B's
## module does (server/modules/src/server/accounts.ts and social.ts: every account RPC answers with
## the account's state; the claim comes first and sets the band; consent needs a claimed under-13
## account; a child without consent is not findable). Several FakeOnlineBackends share one server,
## so two players can befriend and invite each other in one test.

const Backend := preload("res://tests/fakes/fake_online_backend.gd")

var accounts := {}             # user id -> {id, device, username, age_band, consent, online_allowed, chat}
var edges := {}                # user id -> {other user id -> Nakama friend state}
var clients := {}              # user id -> Array of signed-in backends
var removed: Array = []        # remove_guest calls: {from, user_id, match_id}
var reports: Array[Dictionary] = []
var invites: Array[Dictionary] = []
var match_players := {}        # match id -> players in it (for "full")
var down := false              # nothing answers (sign-in and every call)
var provider_missing := false  # consent_start: no verification provider (a release server)
var consent_auto_verify := true   # the fake provider: verified at the next consent_status
var fail_next := {}            # call name -> error code, answered once
var calls: Array[String] = []  # every call by name, in order
var linked := {}               # owner #67: device id -> user id (a device linked by a key)
var sign_in_fails := 0         # owner #105: this many next sign-ins answer account_gone (a cleaned-up asking account)
var removed_devices := {}      # owner #105: device ids unlinked from a claimed account (the module's tombstones)
var log_outs: Array[String] = []   # owner #105: the accounts a device logged out of (log_out)
var _next := 1


## A test player who has already been through the flow.
func make_account(device: String, username: String, band: StringName = AgeBand.TEEN_PLUS,
		consent: String = OnlineRules.CONSENT_NONE, online_allowed: bool = true, password: String = FAKE_PASSWORD) -> String:
	var id := _new_account(device)
	accounts[id].merge({"username": username, "age_band": String(band), "consent": consent,
		"online_allowed": online_allowed, "chat": OnlineRules.CHAT_FILTERED if band == AgeBand.TEEN_PLUS else OnlineRules.CHAT_QUICK}, true)
	if password != "":
		passwords[id] = password   # owner #105: accounts are made with a password now ("" for one from before)
	return id


func befriend(a: String, b: String) -> void:
	_edges(a)[b] = 0
	_edges(b)[a] = 0


func id_of(username: String) -> String:
	for id: String in accounts:
		if accounts[id].username == username:
			return id
	return ""


func is_online(id: String) -> bool:
	return not (clients.get(id, []) as Array).is_empty()


func notify(to: String, code: int, content: Dictionary, sender: String = "") -> void:
	for b: Backend in (clients.get(to, []) as Array).duplicate():
		b.notified.emit(code, JSON.stringify(content), sender)


# --- Called by the fake backends ---

func sign_in(b: Backend, device: String, create: bool = true) -> Dictionary:
	calls.append("sign_in")
	if down:
		return {"ok": false, "error": "sign-in: connection refused"}
	if sign_in_fails > 0:   # owner #105 (the third review's N2): the next sign-ins fail, once each
		sign_in_fails -= 1
		return {"ok": false, "error": "account_gone"}
	if removed_devices.has(device):   # the module's beforeAuthenticateDevice: a tombstoned id is refused
		return {"ok": false, "error": "device_logged_out"}
	var id := str(linked.get(device, ""))   # owner #67: a device linked by a key
	for uid: String in accounts:
		if accounts[uid].device == device:
			id = uid
	if id == "" and not create:
		return {"ok": false, "error": "account_gone"}   # owner #105: Nakama's 404 with create=false
	if id == "":
		id = _new_account(device)
	var was_online := is_online(id)
	if not clients.has(id):
		clients[id] = []
	(clients[id] as Array).append(b)
	if not was_online:
		_presence(id, true)
	return {"ok": true, "user_id": id, "username": accounts[id].username}


func sign_out(b: Backend, id: String) -> void:
	_leave_all(b)   # M4 E
	if not clients.has(id):
		return
	(clients[id] as Array).erase(b)
	if not is_online(id):
		clients.erase(id)
		_presence(id, false)


func call_named(name: String, me: String, payload: Dictionary) -> Dictionary:
	calls.append(name)
	if down:
		return {"ok": false, "error": "socket: connection closed"}
	if fail_next.has(name):
		var code: String = fail_next[name]
		fail_next.erase(name)
		return {"ok": false, "error": code}
	match name:
		"claim_username":
			return _claim(me, payload)
		"get_account_state":
			return _state(me)
		"set_parent_settings":
			return _parent_settings(me, payload)
		"consent_start":
			return _consent_start(me, payload)
		"consent_status":
			return _consent_status(me)
		"invite_friend":
			return _invite(me, payload)
		"remove_guest":   # spec §17.3: the host takes a guest out of its world; their game is told
			var guest := str(payload.get("user_id", ""))
			removed.append({"from": me, "user_id": guest, "match_id": str(payload.get("match_id", ""))})
			notify(guest, OnlineRules.REMOVED, {"match_id": str(payload.get("match_id", ""))}, me)
			return {"ok": true, "in_match": true}
		"report_user":
			reports.append({"from": me, "user_id": str(payload.get("user_id", "")), "reason": str(payload.get("reason", "")),
				"channel_id": str(payload.get("channel_id", "")), "message_id": str(payload.get("message_id", "")),
				"message": payload.get("message", {})})   # M4 G: the message as the reporter's game showed it
			return {"ok": true}
		"list_friends":
			return _list(me)
		"add_friend_by_name":
			return _add(me, _id_of_any_case(str(payload.username)))
		"add_friend_by_id":
			return _add(me, str(payload.id) if accounts.has(str(payload.id)) else "")
		"remove_friend":
			_edges(me).erase(str(payload.id))
			_edges(str(payload.id)).erase(me)
			return {"ok": true}
		"block":
			var other := str(payload.id)
			_edges(me)[other] = 3
			_edges(other).erase(me)
			return {"ok": true}
	if name in F_CALLS:   # M4 Wave 2, agent F
		return _as_json(call("_f_" + name, me, payload))
	if name == "delete_account":   # M4 Task 8b, agent G
		return _as_json(_g_delete_account(me, payload))
	if name in I_CALLS:   # M4 Wave 3, agent I
		return _as_json(call("_i_" + name, me, payload))
	if name in GH_CALLS:   # M4 ghost races
		return _as_json(call("_gh_" + name, me, payload))
	if name == "match_players":   # module 0.2.11 (the M4 Task 10 review's B)
		return _as_json(_b_match_players(me, payload))
	if name in O67_CALLS:   # owner #67 (module 0.2.12)
		return _as_json(call("_o67_" + name, me, payload))
	if name in INV_CALLS:   # owner #79 (module 0.2.16)
		return _as_json(call("_inv_" + name, me, payload))
	if name in SOC_CALLS:   # owner #81, #82, #85 (module 0.2.18)
		return _as_json(call("_soc_" + name, me, payload))
	if name in O99_CALLS:   # owner #99 (module 0.2.20)
		return _as_json(call("_o99_" + name, me, payload))
	if name in O105_CALLS:   # owner #105 (module 0.2.20)
		return _as_json(call("_o105_" + name, me, payload))
	return {"ok": false, "error": "not_found"}


## match_players {"match_id"} as social.ts answers it: only the host of that match (the `hosted` record, host_match),
## each player's username, band (strictly read) and chat level from the account.
func _b_match_players(me: String, p: Dictionary) -> Dictionary:
	var mid := str(p.get("match_id", ""))
	if mid == "" or OnlineChatRules.team_room(mid) != mid:
		return {"ok": false, "error": "bad_request"}
	var m: Dictionary = hosted.get(mid, {})
	if m.is_empty() or m.host != me:
		return {"ok": false, "error": "not_host"}
	var players: Array = []
	for uid: String in m.players:
		if accounts.has(uid):
			var a: Dictionary = accounts[uid]
			players.append({"user_id": uid, "username": a.username,
				"age_band": "13_plus" if a.age_band == "13_plus" else "under_13", "chat_level": OnlineChatRules.chat_level(a)})
	return {"ok": true, "players": players}


# --- The RPCs (what Agent B's module is expected to do) ---

## claim_username {"username", "age_band"}: the first claim sets the band and its defaults (under-13:
## online off, quick chat); no consent needed, the name just stays unfindable (can_play).
func _claim(me: String, p: Dictionary) -> Dictionary:
	var a: Dictionary = accounts[me]
	var name := str(p.get("username", ""))
	var code := UsernameRules.validate(name)
	if code != "":
		return {"ok": false, "error": code}
	if a.age_band == "":
		var band := StringName(str(p.get("age_band", "")))
		if not AgeBand.is_valid(band):
			return {"ok": false, "error": "bad_age_band"}
		a.age_band = String(band)
		a.online_allowed = band == AgeBand.TEEN_PLUS
		a.chat = OnlineRules.CHAT_FILTERED if band == AgeBand.TEEN_PLUS else OnlineRules.CHAT_QUICK
	if _id_of_any_case(name) not in ["", me]:
		return {"ok": false, "error": "taken"}
	a.username = name
	if claims_make_password and not passwords.has(me):
		passwords[me] = FAKE_PASSWORD   # owner #105: as if the claim page made it (tests of that step set this false)
	return _state(me)


## Every account RPC answers with this (Agent B's Accounts.stateReply).
func _state(me: String) -> Dictionary:
	var a: Dictionary = accounts[me]
	var out := {"ok": true, "user_id": me, "username": a.username, "claimed": a.age_band != "", "age_band": a.age_band,
		"consent": a.consent, "online_allowed": a.online_allowed == true, "chat": a.chat if a.chat != "" else "off",
		"can_play_online": can_play(me), "consent_available": not provider_missing,
		"gold": int(wallets.get(me, 0))}   # M4 F: the server's wallet
	if not old_module:   # module 0.2.19: the host's last word on this player's gold (accounts.ts stateReply)
		var h: Dictionary = wallet_hosted.get(me, {})
		out.hosted = null if h.is_empty() else {"match_id": h.match_id, "seq": h.seq}
	return out


## Friends, invites and being found: a claimed account with online on (and consent for under-13).
func can_play(id: String) -> bool:
	var a: Dictionary = accounts[id]
	if a.age_band == "" or a.online_allowed != true:
		return false
	return a.age_band == String(AgeBand.TEEN_PLUS) or a.consent == OnlineRules.CONSENT_VERIFIED


func _parent_settings(me: String, p: Dictionary) -> Dictionary:
	var a: Dictionary = accounts[me]
	if a.age_band == "":
		return {"ok": false, "error": "not_claimed"}
	var band := StringName(a.age_band)
	if p.has("age_band"):   # M4 Task 10 review (module 0.2.8): only ever stricter; a band change starts from its defaults
		var wanted := StringName(str(p.age_band))
		if not AgeBand.is_valid(wanted):
			return {"ok": false, "error": "bad_request"}
		if wanted == AgeBand.TEEN_PLUS and band != AgeBand.TEEN_PLUS:
			return {"ok": false, "error": "age_band_locked"}
		if wanted != band:
			band = wanted
			a.age_band = String(band)
			a.online_allowed = false
			a.chat = OnlineRules.CHAT_QUICK
	if p.has("online_allowed"):
		if bool(p.online_allowed) and band != AgeBand.TEEN_PLUS and a.consent != OnlineRules.CONSENT_VERIFIED:
			return {"ok": false, "error": "consent_needed"}
		a.online_allowed = bool(p.online_allowed)
	if p.has("chat"):
		if str(p.chat) not in OnlineRules.chat_choices(band):
			return {"ok": false, "error": "chat_not_allowed"}
		a.chat = str(p.chat)
	return _state(me)


## consent_start {}: under-13 with a claimed name, and a provider (the fake one here).
func _consent_start(me: String, _p: Dictionary) -> Dictionary:
	var a: Dictionary = accounts[me]
	if a.age_band == "":
		return {"ok": false, "error": "not_claimed"}
	if a.age_band == String(AgeBand.TEEN_PLUS):
		return {"ok": false, "error": "not_needed"}
	if a.consent == OnlineRules.CONSENT_VERIFIED:
		return _state(me)
	if provider_missing:
		return {"ok": false, "error": "consent_unavailable"}
	a.consent = OnlineRules.CONSENT_PENDING
	return _state(me)


## consent_status {}: the fake provider says yes (online on, quick chat) and sends notification 103.
func _consent_status(me: String) -> Dictionary:
	var a: Dictionary = accounts[me]
	if a.consent == OnlineRules.CONSENT_PENDING and consent_auto_verify:
		a.consent = OnlineRules.CONSENT_VERIFIED
		a.online_allowed = true
		a.chat = OnlineRules.CHAT_QUICK
		notify(me, OnlineRules.PARENT_APPROVED, {"what": "consent"})
	return _state(me)


## invite_friend {"user_id" | "username", "match_id", "world_name"}.
func _invite(me: String, p: Dictionary) -> Dictionary:
	var a: Dictionary = accounts[me]
	if not can_play(me):
		return {"ok": false, "error": "not_allowed_online"}
	var to := str(p.get("user_id", "")) if str(p.get("user_id", "")) != "" else _id_of_any_case(str(p.get("username", "")))
	if _edges(me).get(to) != 0 or _edges(to).get(me) != 0:
		return {"ok": false, "error": "not_friends"}
	if not is_online(to):
		return {"ok": false, "error": "offline"}
	var match_id := str(p.get("match_id", ""))
	if not OnlineConfig.is_match_id(match_id):
		return {"ok": false, "error": "bad_request"}
	if int(match_players.get(match_id, 1)) >= OnlineRules.MAX_PLAYERS:
		return {"ok": false, "error": "full"}
	invites.append({"from": me, "to": to, "match_id": match_id})
	notify(to, OnlineRules.INVITE, {"match_id": match_id, "from_username": a.username, "from_user_id": me,
		"world_name": str(p.get("world_name", ""))}, me)
	return {"ok": true, "user_id": to, "username": accounts[to].username}


# --- Nakama's friends API ---

func _list(me: String) -> Dictionary:
	var out: Array = []
	for other: String in _edges(me):
		out.append({"id": other, "username": accounts[other].username, "state": _edges(me)[other], "online": is_online(other)})
	return {"ok": true, "friends": out}


## Nakama's add friend, behind Agent B's hook: only players who may be online, and a child who may
## not is "not found", like nobody.
func _add(me: String, other: String) -> Dictionary:
	if not can_play(me):
		return {"ok": false, "error": "not_allowed_online"}
	if other == "" or not can_play(other):
		return {"ok": false, "error": "no_such_player"}
	if other == me:
		return {"ok": false, "error": "self"}
	var mine: Variant = _edges(me).get(other)
	var theirs: Variant = _edges(other).get(me)
	if accounts[me].age_band != String(AgeBand.TEEN_PLUS) and mine != 0:   # M4 F: a grown-up's yes first
		_f_hold(me, other, "in" if mine == 2 else "out")
		return {"ok": false, "error": "needs_grown_up"}
	return _befriend_or_ask(me, other, mine, theirs)


## Nakama's own add (also what approve_friend does for the child, as the server's friendsAdd).
func _befriend_or_ask(me: String, other: String, mine: Variant, theirs: Variant) -> Dictionary:
	if theirs == 3 or mine == 0:
		return {"ok": true}   # Nakama says nothing when they blocked you
	if theirs == 1:
		befriend(me, other)
		notify(other, OnlineRules.FRIEND_ACCEPTED, {}, me)
	else:
		_edges(me)[other] = 1
		_edges(other)[me] = 2
		notify(other, OnlineRules.FRIEND_REQUEST, {}, me)
	return {"ok": true}


func _id_of_any_case(username: String) -> String:
	for id: String in accounts:
		if str(accounts[id].username).to_lower() == username.strip_edges().to_lower():
			return id
	return ""


func _edges(id: String) -> Dictionary:
	if not edges.has(id):
		edges[id] = {}
	return edges[id]


func _new_account(device: String) -> String:
	var id := "00000000-0000-4000-8000-%012d" % _next
	_next += 1
	accounts[id] = {"id": id, "device": device, "username": "Rnd%07d" % (1000 + _next * 7919 % 9000000),
		"age_band": "", "consent": OnlineRules.CONSENT_NONE, "online_allowed": null, "chat": ""}
	return id


func _presence(id: String, online: bool) -> void:
	for other: String in edges.get(id, {}):
		for b: Backend in (clients.get(other, []) as Array).duplicate():
			b.presence_changed.emit(id, online)


# --- M4 E: chat channels, as Agent B's hooks answer them (server/modules/src/server/chat.ts) ---
# Friends' DMs and the team room of a match the player is in; nothing else. A channel's level is
# the strictest of its players' (an under-13 player makes it quick phrases and emotes only). History
# is kept only for a DM between two 13+ players with text chat (Agent E's persistence rule).

var channels := {}              # channel id -> {type, users: [ids], joined: [{b, uid, keep}], history: [messages]}
var match_members := {}         # match id -> user ids in that relayed match (the team room's rule)
var chat_delivered: Array[Dictionary] = []   # every message sent out: {channel_id, sender_id, content}
var now_unix := 0               # the server's clock for message times (0 = the system's)
var _next_message := 1


## B's AccountRules.chatLevel: off unless the account may play online and chat is on; quick for under-13.
func chat_level(id: String) -> String:
	if not accounts.has(id) or not can_play(id):
		return OnlineRules.CHAT_OFF
	var chat := str(accounts[id].chat)
	if chat not in [OnlineRules.CHAT_QUICK, OnlineRules.CHAT_FILTERED]:
		return OnlineRules.CHAT_OFF
	return OnlineRules.CHAT_QUICK if accounts[id].age_band != String(AgeBand.TEEN_PLUS) else chat


static func dm_channel(a: String, b: String) -> String:
	return "4.%s.%s." % ([a, b] if a < b else [b, a])


static func room_channel(match_id: String) -> String:
	return "2...%s" % match_id


func chat_named(b: Backend, name: String, me: String, payload: Dictionary) -> Dictionary:
	calls.append(name)
	if down:
		return {"ok": false, "error": "socket: connection closed"}
	if fail_next.has(name):
		var code: String = fail_next[name]
		fail_next.erase(name)
		return {"ok": false, "error": code}
	match name:
		"join_chat":
			return _join_chat(b, me, str(payload.target), int(payload.type), bool(payload.persist))
		"leave_chat":
			_leave_chat(b, str(payload.channel_id))
			return {"ok": true}
		"send_chat":
			return _send_chat(me, str(payload.channel_id), payload.content)
		"chat_history":
			var ch: Dictionary = channels.get(str(payload.channel_id), {})
			if ch.is_empty() or not (ch.users as Array).has(me):
				return {"ok": false, "error": "not_in_channel"}
			var out: Array = (ch.history as Array).duplicate()
			out.reverse()   # newest first, as Nakama lists them backwards
			return {"ok": true, "messages": out.slice(0, int(payload.limit))}
	return {"ok": false, "error": "not_found"}


func _join_chat(b: Backend, me: String, target: String, type: int, persist: bool) -> Dictionary:
	if chat_level(me) == OnlineRules.CHAT_OFF:
		return {"ok": false, "error": "chat_off"}
	var id := ""
	var users: Array = []
	var keep := false
	if type == OnlineChatRules.TYPE_DM:
		if not accounts.has(target) or _edges(me).get(target) != 0 or _edges(target).get(me) != 0:
			return {"ok": false, "error": "not_friends"}
		if chat_level(target) == OnlineRules.CHAT_OFF:
			return {"ok": false, "error": "chat_off"}
		id = dm_channel(me, target)
		users = [me, target]
		keep = persist and chat_level(me) == OnlineRules.CHAT_FILTERED and chat_level(target) == OnlineRules.CHAT_FILTERED
	elif type == OnlineChatRules.TYPE_ROOM:
		if OnlineChatRules.team_room(target) != target or not (match_members.get(target, []) as Array).has(me):
			return {"ok": false, "error": "room_not_allowed"}
		id = room_channel(target)
	else:
		return {"ok": false, "error": "not_available"}
	if not channels.has(id):
		channels[id] = {"type": type, "users": users, "joined": [], "history": []}
	var ch: Dictionary = channels[id]
	if type == OnlineChatRules.TYPE_ROOM and not (ch.users as Array).has(me):
		(ch.users as Array).append(me)
	for j: Dictionary in ch.joined:
		if j.b == b:
			j.keep = keep
			return {"ok": true, "channel_id": id}
	(ch.joined as Array).append({"b": b, "uid": me, "keep": keep})
	return {"ok": true, "channel_id": id}


func _leave_chat(b: Backend, channel_id: String) -> void:
	var ch: Dictionary = channels.get(channel_id, {})
	if ch.is_empty():
		return
	for j: Dictionary in (ch.joined as Array).duplicate():
		if j.b == b:
			(ch.joined as Array).erase(j)


## B's before-send hook: {"text"} or {"emote"}, at the channel's strictest level; the cleaned text goes out.
func _send_chat(me: String, channel_id: String, content: Variant) -> Dictionary:
	var ch: Dictionary = channels.get(channel_id, {})
	var sender: Dictionary = {}
	for j: Dictionary in ch.get("joined", []):
		if j.uid == me:
			sender = j
	if sender.is_empty():
		return {"ok": false, "error": "not_in_channel"}
	if not (content is Dictionary) or (content as Dictionary).size() != 1:
		return {"ok": false, "error": "bad_message"}
	var level := OnlineRules.CHAT_FILTERED
	for uid: String in ch.users:
		var l := chat_level(uid)
		if l == OnlineRules.CHAT_OFF:
			level = l
			break
		if l == OnlineRules.CHAT_QUICK:
			level = l
	if level == OnlineRules.CHAT_OFF:
		return {"ok": false, "error": "chat_off"}
	var out := {}
	if content.has("emote"):
		if not (content.emote is String) or RegEx.create_from_string("^[a-z0-9_]{1,32}$").search(content.emote) == null:
			return {"ok": false, "error": "bad_message"}
		out = {"emote": content.emote}
	elif content.get("text") is String:
		var r := ChatRules.check(content.text, AgeBand.TEEN_PLUS if level == OnlineRules.CHAT_FILTERED else AgeBand.UNDER_13)
		if r.has("error"):
			return {"ok": false, "error": r.error}
		out = {"text": r.text}
	else:
		return {"ok": false, "error": "bad_message"}
	var at := now_unix if now_unix > 0 else int(Time.get_unix_time_from_system())
	var msg := {"channel_id": channel_id, "message_id": "msg-%d" % _next_message, "sender_id": me,
		"username": accounts[me].username, "content": JSON.stringify(out),
		"create_time": Time.get_datetime_string_from_unix_time(at) + "Z", "code": 0}
	_next_message += 1
	if sender.keep:
		(ch.history as Array).append(msg)
	chat_delivered.append({"channel_id": channel_id, "sender_id": me, "content": out})
	for j: Dictionary in (ch.joined as Array).duplicate():
		(j.b as Backend).chat_message.emit(msg.duplicate())
	return {"ok": true, "message_id": msg.message_id}


## A connection went away: it leaves every channel.
func _leave_all(b: Backend) -> void:
	for id: String in channels:
		_leave_chat(b, id)

# --- M4 Wave 2, agent F: storage (the profile backup), codes, the wallet, the farm, approvals ---
# As server/modules answers them (economy.ts, parents.ts, guards.ts). Answers go through JSON, as
# over the network (every number comes back a float).

const F_CALLS: Array[String] = ["read_storage", "write_storage", "redeem_code", "wallet_award", "farm_collect",
	"approve_friend", "get_gold_of"]
const WALLET_AWARD_MAX := 2000     # WalletRules.AWARD_MAX_BASE (universe 1)

var storage := {}          # user id -> {"<collection>/<key>": {"value": JSON text, "version": String}}
var server_codes := {}     # user id -> Array of redeemed hashes
var server_paid := {}      # module 0.2.19: user id -> {hash -> {"gold", "at_ms"}}: gold codes the server paid itself
var wallet_hosted := {}    # module 0.2.19: user id -> {"match_id", "host_id", "seq", "seen_ms"} (limits/wallet_hosted)
var old_module := false    # answer as module 0.2.18 does: no "paid", no "seq" or late batches, no "hosted"
const LATE_MS := 24 * 3_600_000   # WalletRules.LATE_MS
var wallets := {}          # user id -> Survivor gold on the server
var ledger: Array[Dictionary] = []
var awarded_this_hour := {}   # user id -> gold credited by wallet_award (no clock: tests reset it)
var hour_limit := 20000       # WalletRules.HOUR_MAX_BASE (universe 1)
var spent_this_hour := {}     # user id -> gold another player's reports spent (module 0.2.10; no clock: tests reset it)
var spend_limit := 20000      # WalletRules.SPEND_HOUR_MAX_BASE (universe 1)
const MAX_FARMS := 20         # FarmRules.MAX_FARMS (module 0.2.10)
var hosted := {}              # match id -> {"host": user id, "players": [user ids]} (the invites record, presences)
var farms := {}            # user id -> {world -> {"rate_per_hour", "started_ms"}}
var clock_ms := 1_000_000  # the server's clock (farm)
var held_friends := {}     # user id -> Array of {"user_id", "username", "direction", "at_ms"} (approvals)
var _version := 0


## The backup stored for a player ("" = none).
func backup_of(id: String) -> String:
	return str(((storage.get(id, {}) as Dictionary).get("profiles/profile", {}) as Dictionary).get("value", ""))


func _as_json(d: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(d))


func _f_read_storage(me: String, p: Dictionary) -> Dictionary:
	var o: Dictionary = (storage.get(me, {}) as Dictionary).get("%s/%s" % [p.collection, p.key], {})
	return {"ok": true, "value": o.get("value", ""), "version": o.get("version", "")}


## Owner #67 (module 0.2.12): one object ("profiles/profile"), by version ("*" = only if new; Nakama's refusal
## reaches the game as "version_clash"), cleaned as ProfileRules cleans it: no gold, nothing that fits one device,
## the account's own name and band.
func _f_write_storage(me: String, p: Dictionary) -> Dictionary:
	if str(p.collection) != "profiles" or str(p.key) != "profile":
		return {"ok": false, "error": "not_allowed"}
	if str(p.value).length() > 64 * 1024:
		return {"ok": false, "error": "too_big"}
	var json := JSON.new()
	if json.parse(str(p.value)) != OK or typeof(json.data) != TYPE_DICTIONARY or not (json.data as Dictionary).has("version"):
		return {"ok": false, "error": "bad_profile"}
	if not storage.has(me):
		storage[me] = {}
	var k := "%s/%s" % [p.collection, p.key]
	var existing: Dictionary = storage[me].get(k, {})
	var v := str(p.get("version", ""))
	if (v == "*" and not existing.is_empty()) or (v != "" and v != "*" and existing.get("version", "") != v):
		return {"ok": false, "error": "version_clash"}
	var d: Dictionary = json.data
	for field in ProfileBackup.DEVICE_ONLY_FIELDS:
		d.erase(field)
	if d.get("settings") is Dictionary:
		for key in ProfileBackup.DEVICE_ONLY_SETTINGS:
			(d.settings as Dictionary).erase(key)
	if d.get("avatar") is Dictionary:
		(d.avatar as Dictionary).erase("base")
	d.username = accounts[me].username
	if AgeBand.is_valid(StringName(str(accounts[me].age_band))):
		d.age_band = accounts[me].age_band
	_version += 1
	storage[me][k] = {"value": JSON.stringify(d), "version": "v%d" % _version}
	return {"ok": true, "version": "v%d" % _version}


## Owner #67: another device id that signs in to this account (sign_in_with_key links one).
func link_device(id: String, device: String) -> void:
	linked[device] = id


## Module 0.2.19 (economy.ts): the server remembers the gold codes it paid itself (`server_paid`); asking again answers
## already_used + "paid" {"gold", "at_ms"}, and a record of hashes answers "paid" [{"hash", "gold", "at_ms"}] for those.
func _f_redeem_code(me: String, p: Dictionary) -> Dictionary:
	var used: Array = server_codes.get(me, [])
	server_codes[me] = used
	var paid: Dictionary = server_paid.get(me, {})
	server_paid[me] = paid
	if p.has("hashes"):
		var recorded := 0
		var already := 0
		var paid_list: Array = []
		for h: Variant in p.hashes:
			if not CodeRules.REWARDS.has(h):
				continue
			if used.has(h):
				already += 1
			else:
				used.append(h)
				recorded += 1
			if paid.has(h) and not paid_list.any(func(e: Dictionary) -> bool: return e.hash == h):
				paid_list.append({"hash": h, "gold": paid[h].gold, "at_ms": paid[h].at_ms})
		var out := {"ok": true, "status": "recorded", "recorded": recorded, "already": already, "gold": wallets.get(me, 0)}
		if not old_module:
			out.paid = paid_list
		return out
	var code := CodeRules.normalize(str(p.get("code", "")))
	if code == "":
		return {"ok": false, "error": "empty"}
	var h := CodeRules.hash_code(code)
	if not CodeRules.REWARDS.has(h):
		return {"ok": false, "error": "unknown"}
	if used.has(h):
		if paid.has(h) and not old_module:
			return {"ok": false, "error": "already_used", "paid": paid[h].duplicate()}
		return {"ok": false, "error": "already_used"}
	used.append(h)
	var reward: Dictionary = CodeRules.REWARDS[h]
	if reward.kind == CodeRules.KIND_GOLD:
		wallets[me] = int(wallets.get(me, 0)) + int(reward.amount)
		ledger.append({"user_id": me, "source": "code", "amount": reward.amount})
		paid[h] = {"gold": int(reward.amount), "at_ms": clock_ms}
	return {"ok": true, "status": "accepted", "reward": {"kind": String(reward.kind), "amount": reward.get("amount", 0)},
		"gold": wallets.get(me, 0)}


## A test host hosting `match_id` with these guests in it.
func host_match(match_id: String, host: String, guests: Array) -> void:
	hosted[match_id] = {"host": host, "players": [host] + guests}


## A player leaves a hosted match (its presence goes; the host's record stays).
func leave_match(match_id: String, id: String) -> void:
	((hosted.get(match_id, {}) as Dictionary).get("players", []) as Array).erase(id)


## Whose gold a wallet call is about: the caller's, or a guest's in the match it hosts (economy.ts). `late` (module
## 0.2.19, a report with a seq): also a guest who left, or after the host left, for the match the server saw it in.
func _f_target(me: String, p: Dictionary, late: bool = false) -> Dictionary:
	if not p.has("user_id") or str(p.user_id) == me:
		return {"uid": me}
	var mid := str(p.get("match_id", ""))
	var m: Dictionary = hosted.get(mid, {})
	var hosts_it: bool = not m.is_empty() and m.host == me
	var guest := str(p.user_id)
	if hosts_it and (m.players as Array).has(me) and (m.players as Array).has(guest):
		return {"uid": guest, "match": mid, "present": true}
	var rec: Dictionary = wallet_hosted.get(guest, {})
	if late and hosts_it and rec.get("match_id") == mid and rec.get("host_id") == me and clock_ms - int(rec.seen_ms) <= LATE_MS:
		return {"uid": guest, "match": mid, "present": false}
	if not hosts_it or not (m.players as Array).has(me):
		return {"error": "not_host"}
	return {"error": "not_in_match"}


## Module 0.2.19 (WalletRules.hostedNext): the server saw the guest in this host's match, or heard a seq for it.
func _f_note_hosted(guest: String, match_id: String, host: String, seq: int, present: bool) -> void:
	var old: Dictionary = wallet_hosted.get(guest, {})
	var same: bool = old.get("match_id") == match_id and old.get("host_id") == host
	wallet_hosted[guest] = {"match_id": match_id, "host_id": host, "seq": maxi(int(old.seq), seq) if same else seq,
		"seen_ms": clock_ms if present or not same else int(old.seen_ms)}


func _f_get_gold_of(me: String, p: Dictionary) -> Dictionary:
	var t := _f_target(me, p)
	if t.has("error"):
		return {"ok": false, "error": t.error}
	if t.uid != me and not old_module:
		_f_note_hosted(t.uid, t.match, me, 0, true)
	return {"ok": true, "user_id": t.uid, "gold": wallets.get(t.uid, 0)}


## wallet_award; module 0.2.19: an optional "seq" (1, 2, ...: the host's count of that guest's gold moves) on the last
## piece of a batch: kept per guest also when the rules refuse the piece, answered back; amount 0 + seq reports the seq
## alone; a seq batch is taken late (_f_target). `old_module`: the seq is ignored, as 0.2.18 does.
func _f_wallet_award(me: String, p: Dictionary) -> Dictionary:
	var has_seq := p.has("seq") and not old_module
	var seq: Variant = p.get("seq")
	if has_seq and (typeof(seq) not in [TYPE_INT, TYPE_FLOAT] or float(seq) != floorf(float(seq)) or float(seq) < 1.0):
		return {"ok": false, "error": "bad_request"}
	var t := _f_target(me, p, has_seq)
	if t.has("error"):
		return {"ok": false, "error": t.error}
	var answer: Dictionary
	if has_seq and typeof(p.get("amount")) in [TYPE_INT, TYPE_FLOAT] and float(p.amount) == 0.0:
		answer = {"ok": true, "credited": 0, "capped": false, "gold": wallets.get(t.uid, 0)}
	else:
		answer = _f_award(me, t.uid, p)
	if has_seq and t.uid != me:
		_f_note_hosted(t.uid, t.match, me, int(seq), t.present)
	if has_seq and answer.ok:
		answer.seq = int(seq)
	return answer


func _f_award(me: String, who: String, p: Dictionary) -> Dictionary:
	var amount: Variant = p.get("amount")
	if typeof(amount) != TYPE_INT and not (typeof(amount) == TYPE_FLOAT and float(amount) == floorf(float(amount))):
		return {"ok": false, "error": "bad_request"}
	var n := int(amount)
	if n == 0:
		return {"ok": false, "error": "bad_request"}
	if n < 0:
		# Module 0.2.10 (WalletRules.spend): another player's spends for this one are limited per hour, refused whole.
		var spend_mult := 1 << (clampi(int(p.get("universe", 1)), 1, 12) - 1)
		if who != me and int(spent_this_hour.get(who, 0)) - n > spend_limit * spend_mult:
			return {"ok": false, "error": "spend_limit"}
		if int(wallets.get(who, 0)) + n < 0:
			return {"ok": false, "error": "not_enough_gold", "gold": wallets.get(who, 0)}
		if who != me:
			spent_this_hour[who] = int(spent_this_hour.get(who, 0)) - n
		wallets[who] = int(wallets.get(who, 0)) + n
		ledger.append({"user_id": who, "source": "award", "amount": n, "reason": str(p.get("reason", "")), "by": me})
		return {"ok": true, "credited": n, "capped": false, "gold": wallets[who]}
	var mult := 1 << (clampi(int(p.get("universe", 1)), 1, 12) - 1)
	if n > WALLET_AWARD_MAX * mult:
		return {"ok": false, "error": "too_much"}
	var room := hour_limit * mult - int(awarded_this_hour.get(who, 0))
	if room <= 0:
		return {"ok": false, "error": "limit"}
	var credit := mini(n, room)
	awarded_this_hour[who] = int(awarded_this_hour.get(who, 0)) + credit
	wallets[who] = int(wallets.get(who, 0)) + credit
	ledger.append({"user_id": who, "source": "award", "amount": credit, "reason": str(p.get("reason", "")), "by": me})
	return {"ok": true, "credited": credit, "capped": credit < n, "gold": wallets[who]}


func _f_farm_collect(me: String, p: Dictionary) -> Dictionary:
	var world := str(p.get("world", ""))
	if world == "":
		return {"ok": false, "error": "bad_request"}
	if not farms.has(me):
		farms[me] = {}
	match str(p.get("action", "")):
		"start":
			# As FarmRules.start (farm_rules.ts): the rate, universe and cap clamped; the server's time (M3 Task 10).
			if not (farms[me] as Dictionary).has(world) and (farms[me] as Dictionary).size() >= MAX_FARMS:
				return {"ok": false, "error": "too_many_farms"}   # module 0.2.10
			var rate := mini(int(p.get("rate_per_hour", 0)), 1000)
			var u := clampi(int(p.get("universe", 1)), 1, 12)
			var cap := clampi(int(p.get("cap_hours", 12)), 1, 24)
			farms[me][world] = {"rate_per_hour": rate, "universe": u, "cap_hours": cap, "started_ms": clock_ms}
			return {"ok": true, "started_ms": clock_ms, "rate_per_hour": rate, "universe": u, "cap_hours": cap}
		"peek", "collect":
			if not (farms[me] as Dictionary).has(world):
				return {"ok": false, "error": "not_started"}
			var f: Dictionary = farms[me][world]
			var away := maxi(clock_ms - int(f.started_ms), 0)
			var cap_ms := int(f.cap_hours) * 3_600_000
			var earned := int(f.rate_per_hour) * (1 << (int(f.universe) - 1)) * mini(away, cap_ms) / 3_600_000
			if p.action == "peek":
				return {"ok": true, "earned": earned, "away_ms": away, "capped": away > cap_ms}
			(farms[me] as Dictionary).erase(world)
			wallets[me] = int(wallets.get(me, 0)) + earned
			return {"ok": true, "earned": earned, "away_ms": away, "capped": away > cap_ms, "gold": wallets[me]}
	return {"ok": false, "error": "bad_request"}


func _f_hold(me: String, other: String, direction: String) -> void:
	var list: Array = held_friends.get(me, [])
	for r: Dictionary in list.duplicate():
		if r.user_id == other:
			list.erase(r)
	list.append({"user_id": other, "username": accounts[other].username, "direction": direction, "at_ms": clock_ms})
	held_friends[me] = list


func _f_approve_friend(me: String, p: Dictionary) -> Dictionary:
	var list: Array = held_friends.get(me, [])
	if not p.has("user_id"):
		return {"ok": true, "requests": list}
	var wanted: Dictionary = {}
	for r: Dictionary in list:
		if r.user_id == str(p.user_id):
			wanted = r
	if wanted.is_empty():
		return {"ok": false, "error": "not_found"}
	if bool(p.get("approve", false)) and not can_play(me):
		return {"ok": false, "error": "consent_needed"}
	list.erase(wanted)
	var other: String = wanted.user_id
	if not bool(p.get("approve", false)):
		if wanted.direction == "in":
			_edges(me).erase(other)
			_edges(other).erase(me)
		return {"ok": true, "requests": list}
	if not can_play(other):
		return {"ok": false, "error": "not_found", "requests": list}
	_befriend_or_ask(me, other, _edges(me).get(other), _edges(other).get(me))
	notify(me, OnlineRules.PARENT_APPROVED, {"what": "friend", "user_id": other})
	return {"ok": true, "requests": list, "friend": {"user_id": other, "username": accounts[other].username,
		"state": "friend" if wanted.direction == "in" else "asked"}}

# --- M4 Task 8b, agent G: delete_account, as server/modules/src/server/deletion.ts answers it ---
# The first call hands out a confirmation; the second (with it) deletes the account and everything of
# it: friends both ways, storage, the wallet, codes, the farm, requests waiting for a grown-up (its
# own and other children's that name it); reports it made lose its id, reports about it stay. Nakama
# then closes the player's connections.

var confirms := {}                  # user id -> the confirmation handed out
var deleted: Array[String] = []     # deleted accounts, in order
var _confirm_next := 1


func _g_delete_account(me: String, p: Dictionary) -> Dictionary:
	if not p.has("confirm"):
		confirms[me] = "confirm-%d" % _confirm_next
		_confirm_next += 1
		return {"ok": true, "confirm": confirms[me], "expires_ms": clock_ms + 600_000, "user_id": me,
			"username": accounts[me].username}
	if not confirms.has(me):
		return {"ok": false, "error": "confirm_expired"}
	if str(p.confirm) != confirms[me]:
		return {"ok": false, "error": "confirm_wrong"}
	if passwords.has(me):   # owner #105: the password once there is one
		if not p.has("password"):
			return {"ok": false, "error": "password_needed"}
		if str(p.password) != passwords[me]:
			return {"ok": false, "error": "wrong_password"}
	_forget_account(me)
	return {"ok": true, "deleted": true, "user_id": me}


## Deletion.run: the account and everything of it; its connections close.
func _forget_account(me: String) -> void:
	for other: String in _edges(me).keys():
		_edges(other).erase(me)
	edges.erase(me)
	for id: String in held_friends:
		var kept: Array = (held_friends[id] as Array).filter(func(r: Dictionary) -> bool: return r.user_id != me)
		held_friends[id] = kept
	for map: Dictionary in [storage, server_codes, wallets, farms, held_friends, confirms, awarded_this_hour]:
		map.erase(me)
	move_asks.erase(me)   # owner #99: the account collection goes with it
	move_asked.erase(me)
	passwords.erase(me)   # owner #105
	_i_forget(me)   # M4 I: its gifts, bottles, showcase, guestbook; what it sent; its stickers
	for r: Dictionary in reports:
		if r.from == me:
			r.from = ""
	if str(accounts[me].get("age_band", "")) != "":   # a claimed account's devices are tombstoned (the module's N2 rule)
		if str(accounts[me].device) != "":
			removed_devices[str(accounts[me].device)] = true
		for d: String in linked.keys():
			if linked[d] == me:
				removed_devices[d] = true
	accounts.erase(me)
	deleted.append(me)
	for device: String in linked.keys():
		if linked[device] == me:
			linked.erase(device)
	keys.erase(me)
	for b: Backend in (clients.get(me, []) as Array).duplicate():
		b.drop()   # Nakama logs the player out and closes the socket

# --- Owner #67: the sign-in key (module 0.2.12: server/modules/src/server/keys.ts) ---
# account_key {"action": "state" | "new" | "sign_out_others"} and sign_in_with_key {"username", "key", "device_id"}:
# the same answers; the key checked as typed (KeyRules.normalize), wrong keys counted per name (5 lock it, 900 s),
# the asking account deleted when it never claimed a name, sign_out_others unlinks the rest and ends every session.

const O67_CALLS: Array[String] = ["account_key", "sign_in_with_key"]
const KEY_ALPHABET := "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
var keys := {}          # user id -> the key (as normalize gives it)
var key_tries := {}     # lower-case name -> wrong keys
var _key_next := 1


static func normalize_key(text: String) -> String:
	var plain := text.to_upper().replace(" ", "").replace("-", "").replace("O", "0").replace("I", "1").replace("L", "1")
	if plain.length() != 8:
		return ""
	for c in plain:
		if not KEY_ALPHABET.contains(c):
			return ""
	return plain


func devices_of(id: String) -> Array:
	var out: Array = []
	if accounts.has(id) and str(accounts[id].device) != "":
		out.append(accounts[id].device)
	for device: String in linked:
		if linked[device] == id:
			out.append(device)
	return out


func _o67_account_key(me: String, p: Dictionary) -> Dictionary:
	var a: Dictionary = accounts[me]
	match str(p.get("action", "")):
		"state":
			return {"ok": true, "has_key": keys.has(me), "made_ms": clock_ms if keys.has(me) else 0,
				"devices": devices_of(me).size(), "username": a.username}
		"new":
			if a.age_band == "":
				return {"ok": false, "error": "not_claimed"}
			var k := ""
			for i in 8:
				k += KEY_ALPHABET[(_key_next * 7 + i * 13) % 32]
			_key_next += 1
			keys[me] = k
			return {"ok": true, "key": k.substr(0, 4) + "-" + k.substr(4), "username": a.username, "made_ms": clock_ms,
				"devices": devices_of(me).size()}
		"sign_out_others":
			if a.age_band == "":
				return {"ok": false, "error": "not_claimed"}
			var keep := str(p.get("device_id", ""))
			var mine := devices_of(me)
			if not mine.has(keep):
				return {"ok": false, "error": "not_allowed"}
			if a.device != keep:
				a.device = ""
			for device: String in linked.keys():
				if linked[device] == me and device != keep:
					linked.erase(device)
			for b: Backend in (clients.get(me, []) as Array).duplicate():
				b.drop()   # nk.sessionLogout: every session ends (the asking game signs in again)
			return {"ok": true, "removed": mine.size() - 1, "devices": 1}
	return {"ok": false, "error": "bad_request"}


func _o67_sign_in_with_key(me: String, p: Dictionary) -> Dictionary:
	var device := str(p.get("device_id", ""))
	if not DeviceId.is_valid(device):
		return {"ok": false, "error": "bad_request"}
	var name := str(p.get("username", "")).strip_edges().to_lower()
	if int(key_tries.get(me, 0)) >= 10:   # the module: wrong keys are counted per asking account, never per name
		return {"ok": false, "error": "locked", "wait": 3600}
	var target := _id_of_any_case(name) if name != "" else ""
	var key := normalize_key(str(p.get("key", "")))
	var grown_ups: bool = target != "" and accounts[target].age_band != "" and key != "" and keys.get(target, "") == key
	var move: Dictionary = _o99_consume(me, target, key) if target != "" and not grown_ups and key != "" else {}   # owner #99
	if not grown_ups and move.is_empty():
		key_tries[me] = int(key_tries.get(me, 0)) + 1
		return {"ok": false, "error": "wrong_key"}
	if not move.is_empty():
		notify(target, 110, {"what": "moved", "kind": move.kind})
		move_asked.erase(me)
	key_tries.erase(me)
	if target == me:
		return {"ok": true, "user_id": target, "username": accounts[target].username, "left": "same"}
	if linked.has(device) or _id_of_device(device) != "":
		return {"ok": false, "error": "bad_request"}
	linked[device] = target
	log_out_others(target, device)   # owner #105 (the final review): one device at a time with a key too
	var left := "kept"
	if accounts[me].age_band == "":
		_forget_account(me)
		left = "deleted"
	return {"ok": true, "user_id": target, "username": accounts[target].username, "left": left}


func _id_of_device(device: String) -> String:
	for uid: String in accounts:
		if accounts[uid].device == device:
			return uid
	return ""

# --- M4 Wave 3, agent I: gifts, showcases and guestbooks, bottles, build reports ---
# As server/modules/src/server/gifts.ts answers them (module 0.2.4): friends only, consent first (a child
# who may not be online is "not_found"), builds decoded and size-checked (the game's BuildCodec, the
# server's limits), preset stickers and quick phrases only, at most 10 unopened gifts and 5 bottles per
# friend, the notes 104 (gift), 105 (bottle), 106 (sticker). No send windows here.

const I_CALLS: Array[String] = ["send_gift", "list_gifts", "open_gift", "publish_showcase", "get_showcase",
	"sign_guestbook", "remove_sticker", "send_bottle", "list_bottles", "open_bottle", "report_build"]

var gifts := {}          # user id -> Array of {gift_id, from_id, from_username, build, count, size, created_ms}
var bottles := {}        # user id -> Array of {bottle_id, from_id, from_username, phrase, build?, created_ms}
var showcases := {}      # user id -> {build, size, count, buddy?, updated_ms}
var guestbooks := {}     # user id -> Array of {entry_id, from_id, from_username, sticker, at_ms}
var build_reports: Array[Dictionary] = []
var _i_next := 1


## {"uid"} of the friend a request names, or {"error"} (not_allowed_online, not_found, self, not_friends).
func _i_friend(me: String, p: Dictionary) -> Dictionary:
	if not can_play(me):
		return {"error": "not_allowed_online"}
	var uid := str(p.get("user_id", "")) if str(p.get("user_id", "")) != "" else _id_of_any_case(str(p.get("username", "")))
	if uid == "" or not accounts.has(uid) or not can_play(uid):
		return {"error": "not_found"}
	if uid == me:
		return {"error": "self"}
	if _edges(me).get(uid) != 0:
		return {"error": "not_friends"}
	return {"uid": uid}


func _i_fail(error: String, self_code: String = "cannot_gift_self") -> Dictionary:
	return {"ok": false, "error": self_code if error == "self" else error}


## A build's code when it is refused under `limits` ("" when it is fine).
func _i_build_problem(build: Variant, limits: Dictionary) -> String:
	if not (build is String) or build == "":
		return "bad_build"
	if (build as String).length() > int(limits.max_text) or BuildCodec.size_of(build) != Vector3i.ZERO \
			and maxi(BuildCodec.size_of(build).x, maxi(BuildCodec.size_of(build).y, BuildCodec.size_of(build).z)) > int(limits.max_dim):
		return "too_big"
	if BuildCodec.decode(build, limits).is_empty():
		return "empty_build" if BuildCodec.size_of(build) != Vector3i.ZERO and BuildCodec.count_of(build) == 0 else "bad_build"
	return ""


func _i_size(build: String) -> Array:
	var v := BuildCodec.size_of(build)
	return [v.x, v.y, v.z]


func _i_deliver(me: String, uid: String, box: Dictionary, per_friend: int, too_many: String, value: Dictionary, code: int,
		kind: String) -> Dictionary:
	var list: Array = box.get(uid, [])
	box[uid] = list
	if list.filter(func(x: Dictionary) -> bool: return x.from_id == me).size() >= per_friend:
		return {"ok": false, "error": too_many}
	var id := "%s%d_%012d" % [kind.substr(0, 1), clock_ms, _i_next]
	_i_next += 1
	value.merge({"from_id": me, "from_username": accounts[me].username, "created_ms": clock_ms}, true)
	value[kind + "_id"] = id
	list.append(value)
	notify(uid, code, {"from_username": accounts[me].username, "from_user_id": me, "kind": kind}, me)
	return {"ok": true, kind + "_id": id}


func _i_send_gift(me: String, p: Dictionary) -> Dictionary:
	var f := _i_friend(me, p)
	if f.has("error"):
		return _i_fail(f.error)
	var problem := _i_build_problem(p.get("build"), BuildCodec.GIFT)
	if problem != "":
		return {"ok": false, "error": problem}
	return _i_deliver(me, f.uid, gifts, GiftRules.GIFTS_PER_FRIEND, "too_many_gifts",
		{"build": p.build, "count": BuildCodec.count_of(p.build), "size": _i_size(p.build)}, GiftRules.NOTE_GIFT, "gift")


## The friends of `me` (both ways state 0).
func _i_friends(me: String) -> Array:
	return _edges(me).keys().filter(func(o: String) -> bool: return _edges(me)[o] == 0)


func _i_list(me: String, box: Dictionary) -> Array:
	var friends := _i_friends(me)
	var list: Array = box.get(me, [])
	box[me] = list.filter(func(x: Dictionary) -> bool: return friends.has(x.from_id))   # not friends any more: deleted
	return box[me]


func _i_list_gifts(me: String, _p: Dictionary) -> Dictionary:
	if not can_play(me):
		return {"ok": false, "error": "not_allowed_online"}
	var out: Array = []
	for g: Dictionary in _i_list(me, gifts):
		out.append({"gift_id": g.gift_id, "from_user_id": g.from_id, "from_username": g.from_username, "count": g.count,
			"size": g.size, "created_ms": g.created_ms})
		if g.has("ghost"):
			out.back().ghost = true   # M4 ghost races
	return {"ok": true, "gifts": out}


func _i_open(me: String, box: Dictionary, id_key: String, p: Dictionary) -> Dictionary:
	var list: Array = box.get(me, [])
	for x: Dictionary in list:
		if x[id_key] == str(p.get(id_key, "")):
			list.erase(x)
			if bool(p.get("discard", false)):
				return {"ok": true, "discarded": true}
			if not _i_friends(me).has(x.from_id):
				return {"ok": false, "error": "not_found"}
			var out := x.duplicate()
			out.from_user_id = out.from_id
			out.erase("from_id")
			return {"ok": true, id_key.trim_suffix("_id"): out}
	return {"ok": false, "error": "not_found"}


func _i_open_gift(me: String, p: Dictionary) -> Dictionary:
	return _i_open(me, gifts, "gift_id", p)


func _i_publish_showcase(me: String, p: Dictionary) -> Dictionary:
	if not can_play(me):
		return {"ok": false, "error": "not_allowed_online"}
	if p.get("remove") == true:
		showcases.erase(me)
		guestbooks.erase(me)
		showcase_ghosts.erase(me)   # M4 ghost races
		return {"ok": true, "removed": true}
	var problem := _i_build_problem(p.get("build"), BuildCodec.SHOWCASE)
	if problem != "":
		return {"ok": false, "error": problem}
	var value := {"build": p.build, "size": _i_size(p.build), "count": BuildCodec.count_of(p.build), "updated_ms": clock_ms}
	if p.get("buddy") is Dictionary:
		var b: Dictionary = p.buddy
		var at: Variant = b.get("at")
		var size := BuildCodec.size_of(p.build)
		if _i_build_problem(b.get("build"), BuildCodec.BUDDY) != "" or not (at is Array) or (at as Array).size() != 3 \
				or int(at[0]) < 0 or int(at[1]) < 0 or int(at[2]) < 0 or int(at[0]) >= size.x or int(at[1]) >= size.y or int(at[2]) >= size.z:
			return {"ok": false, "error": "bad_buddy"}
		value.buddy = {"build": b.build, "at": [int(at[0]), int(at[1]), int(at[2])]}
	showcases[me] = value
	showcase_ghosts.erase(me)   # M4 ghost races: a new area
	return {"ok": true, "count": value.count, "size": value.size, "updated_ms": clock_ms}


func _i_get_showcase(me: String, p: Dictionary) -> Dictionary:
	var owner := me
	if p.has("user_id") or p.has("username"):
		var f := _i_friend(me, p)
		if f.has("error") and f.error != "self":
			return {"ok": false, "error": f.error}
		owner = f.get("uid", me)
	elif not can_play(me):
		return {"ok": false, "error": "not_allowed_online"}
	if not showcases.has(owner):
		return {"ok": false, "error": "no_showcase"}
	var s: Dictionary = showcases[owner]
	var out := {"ok": true, "owner_id": owner, "owner_username": accounts[owner].username, "build": s.build, "size": s.size,
		"updated_ms": s.updated_ms}
	if s.has("buddy"):
		out.buddy = s.buddy
	if owner == me:
		out.guestbook = _i_book_out(me)
	return out


func _i_book_out(owner: String) -> Array:
	var out: Array = []
	for e: Dictionary in guestbooks.get(owner, []):
		out.append({"entry_id": e.entry_id, "from_user_id": e.from_id, "from_username": e.from_username, "sticker": e.sticker,
			"at_ms": e.at_ms})
	return out


func _i_sign_guestbook(me: String, p: Dictionary) -> Dictionary:
	var f := _i_friend(me, p)
	if f.has("error"):
		return _i_fail(f.error, "cannot_sign_own")
	if not GiftRules.is_sticker(p.get("sticker")):
		return {"ok": false, "error": "bad_sticker"}
	if not showcases.has(f.uid):
		return {"ok": false, "error": "no_showcase"}
	var book: Array = guestbooks.get(f.uid, [])
	guestbooks[f.uid] = book
	for e: Dictionary in book:
		if e.from_id == me and clock_ms - int(e.at_ms) < 600_000:
			return {"ok": false, "error": "too_fast"}
	book.append({"entry_id": "e%d" % _i_next, "from_id": me, "from_username": accounts[me].username, "sticker": p.sticker,
		"at_ms": clock_ms})
	_i_next += 1
	while book.size() > GiftRules.GUESTBOOK_MAX:
		book.pop_front()
	notify(f.uid, GiftRules.NOTE_STICKER, {"from_username": accounts[me].username, "from_user_id": me, "sticker": p.sticker}, me)
	return {"ok": true}


func _i_remove_sticker(me: String, p: Dictionary) -> Dictionary:
	var book: Array = guestbooks.get(me, [])
	for e: Dictionary in book:
		if e.entry_id == str(p.get("entry_id", "")):
			book.erase(e)
			return {"ok": true, "guestbook": _i_book_out(me)}
	return {"ok": false, "error": "not_found"}


func _i_send_bottle(me: String, p: Dictionary) -> Dictionary:
	var f := _i_friend(me, p)
	if f.has("error"):
		return _i_fail(f.error)
	if not (p.get("phrase") is String) or not ChatRules.is_quick_phrase(p.phrase):
		return {"ok": false, "error": "bad_phrase"}
	var value := {"phrase": p.phrase}
	if p.get("build") != null and p.has("build"):
		var problem := _i_build_problem(p.build, BuildCodec.BOTTLE)
		if problem != "":
			return {"ok": false, "error": problem}
		value.merge({"build": p.build, "size": _i_size(p.build), "count": BuildCodec.count_of(p.build)})
	return _i_deliver(me, f.uid, bottles, GiftRules.BOTTLES_PER_FRIEND, "too_many_bottles", value, GiftRules.NOTE_BOTTLE, "bottle")


func _i_list_bottles(me: String, _p: Dictionary) -> Dictionary:
	if not can_play(me):
		return {"ok": false, "error": "not_allowed_online"}
	var out: Array = []
	for b: Dictionary in _i_list(me, bottles):
		out.append({"bottle_id": b.bottle_id, "from_user_id": b.from_id, "from_username": b.from_username,
			"created_ms": b.created_ms})
	return {"ok": true, "bottles": out}


func _i_open_bottle(me: String, p: Dictionary) -> Dictionary:
	return _i_open(me, bottles, "bottle_id", p)


func _i_report_build(me: String, p: Dictionary) -> Dictionary:
	if not (p.get("what") in ["showcase", "gift", "bottle", "ghost"]):
		return {"ok": false, "error": "bad_request"}
	var uid := str(p.get("user_id", "")) if str(p.get("user_id", "")) != "" else _id_of_any_case(str(p.get("username", "")))
	if not accounts.has(uid):
		return {"ok": false, "error": "not_found"}
	if uid == me:
		return {"ok": false, "error": "cannot_report_self"}
	var build: Variant = null
	if p.what == "showcase" and showcases.has(uid):
		build = {"build": showcases[uid].build, "source": "server"}
	elif p.get("build") is String and not BuildCodec.decode(p.build, BuildCodec.SHOWCASE).is_empty():
		build = {"build": p.build, "source": "reporter"}
	build_reports.append({"from": me, "user_id": uid, "what": p.what, "reason": str(p.get("reason", "bad_build")),
		"build": build})
	_gh_report(uid, p, build_reports.back())   # M4 ghost races
	return {"ok": true}


## delete_account: everything of the player, what it sent (still unopened) and the stickers it left.
func _i_forget(me: String) -> void:
	showcase_ghosts.erase(me)   # M4 ghost races
	for box: Dictionary in [gifts, bottles, showcases, guestbooks]:
		box.erase(me)
	for box: Dictionary in [gifts, bottles, guestbooks]:
		for uid: String in box:
			box[uid] = (box[uid] as Array).filter(func(x: Dictionary) -> bool: return x.from_id != me)


# --- M4 ghost races: share_ghost, list_ghosts (server/modules/src/server/ghosts.ts, module 0.2.6) ---
# A ghost on the showcase is checked against the showcase's build, one per course (a new run of the same START
# replaces it), at most 3; with a gift it is checked against the gift's build and delivered like send_gift. The
# checks are the game's RaceGhost.check (the same rules as GhostRules.check). No share windows here.

const GH_CALLS: Array[String] = ["share_ghost", "list_ghosts"]
var showcase_ghosts := {}   # user id -> Array of {ghost_id, start, finish, ms, path, look, updated_ms}


## The ghost of a request checked against a build's cells: {"ghost": the wire dictionary} or {"error"}.
func _gh_check(raw: Variant, build: String) -> Dictionary:
	var g := RaceGhost.from_wire(raw)
	if g == null or (raw as Dictionary).has("ghost_id"):
		return {"error": RaceGhost.BAD}
	var blocks := BuildCodec.decode(build, BuildCodec.SHOWCASE)
	var err := g.check(BuildCodec.size_of(build), func(c: Vector3i) -> int: return int(blocks.get(c, BlockIds.AIR)))
	return {"error": err} if err != "" else {"ghost": g.to_wire()}


func _gh_share_ghost(me: String, p: Dictionary) -> Dictionary:
	if p.has("remove"):
		var list: Array = showcase_ghosts.get(me, [])
		for g: Dictionary in list:
			if g.ghost_id == p.remove:
				list.erase(g)
				return {"ok": true, "removed": true}
		return {"ok": false, "error": "not_found"}
	if p.get("to") == "gift":
		var f := _i_friend(me, p)
		if f.has("error"):
			return _i_fail(f.error)
		var problem := _i_build_problem(p.get("build"), BuildCodec.GIFT)
		if problem != "":
			return {"ok": false, "error": problem}
		var c := _gh_check(p.get("ghost"), p.build)
		if c.has("error"):
			return {"ok": false, "error": c.error}
		return _i_deliver(me, f.uid, gifts, GiftRules.GIFTS_PER_FRIEND, "too_many_gifts",
			{"build": p.build, "count": BuildCodec.count_of(p.build), "size": _i_size(p.build), "ghost": c.ghost},
			GiftRules.NOTE_GIFT, "gift")
	if p.get("to") != "showcase":
		return {"ok": false, "error": "bad_request"}
	if not can_play(me):
		return {"ok": false, "error": "not_allowed_online"}
	if not showcases.has(me):
		return {"ok": false, "error": "no_showcase"}
	var checked := _gh_check(p.get("ghost"), showcases[me].build)
	if checked.has("error"):
		return {"ok": false, "error": checked.error}
	var g: Dictionary = checked.ghost
	var kept: Array = (showcase_ghosts.get(me, []) as Array).filter(func(x: Dictionary) -> bool: return x.start != g.start)
	if kept.size() >= GhostRaceRules.PER_SHOWCASE:
		return {"ok": false, "error": "too_many_ghosts"}
	g.ghost_id = "h%d_%012d" % [clock_ms, _i_next]
	_i_next += 1
	g.updated_ms = clock_ms
	kept.append(g)
	showcase_ghosts[me] = kept
	return {"ok": true, "ghost_id": g.ghost_id, "ms": g.ms}


func _gh_list_ghosts(me: String, p: Dictionary) -> Dictionary:
	var owner := me
	if p.has("user_id") or p.has("username"):
		var f := _i_friend(me, p)
		if f.has("error") and f.error != "self":
			return {"ok": false, "error": f.error}
		owner = f.get("uid", me)
	elif not can_play(me):
		return {"ok": false, "error": "not_allowed_online"}
	return {"ok": true, "owner_id": owner, "owner_username": accounts[owner].username,
		"ghosts": (showcase_ghosts.get(owner, []) as Array).duplicate(true)}


func _gh_report(uid: String, p: Dictionary, report: Dictionary) -> void:
	if p.what == "showcase":
		if not (showcase_ghosts.get(uid, []) as Array).is_empty():
			report.ghosts = (showcase_ghosts[uid] as Array).duplicate(true)
		return
	var ghost: Variant = null
	if p.what == "ghost":
		for g: Dictionary in showcase_ghosts.get(uid, []):
			if g.ghost_id == p.get("ghost_id"):
				ghost = g.merged({"source": "server"})
	if ghost == null and p.get("ghost") is Dictionary and p.ghost.get("path") is String:
		ghost = (p.ghost as Dictionary).merged({"source": "reporter"})
	if p.what == "ghost" or ghost != null:
		report.ghost = ghost

# --- Owner #79: invite a friend (module 0.2.16: server/modules/src/server/referrals.ts), the game's side's needs ---
# invite_info (a claimed account's code; friends by name, counts, news, groups), invite_use (a new account only, never
# your own, once; the welcome gift into the server's wallet), invite_progress (learned: the inviter +250, the friend +50,
# the inviter's inviter +25; landed on the Moon: +150), invite_group (a class or family code). No caps or clock here: the
# Node tests prove those.

const INV_CALLS: Array[String] = ["invite_info", "invite_use", "invite_progress", "invite_group"]
var inv := {}          # user id -> {"code", "by", "friends": [ids], "learned", "landed", "news": [], "groups": {}, "made": {}}
var inv_codes := {}    # canonical code -> {"user_id", "kind", "code"}
var inv_groups := {}   # canonical code -> [member ids]
var inv_old := {}      # user id -> true: an account too old for a friend's code (NEW_ACCOUNT_MS)
var _inv_next := 10


func _inv(me: String) -> Dictionary:
	if not inv.has(me):
		inv[me] = {"code": "", "by": "", "friends": [], "learned": false, "landed": false, "news": [], "groups": {}, "made": {}, "earned": 0}
	return inv[me]


func _inv_new_code(me: String, kind: String) -> String:
	var words: String = ["BLUE-OTTER", "RED-FOX", "JADE-OWL", "MINT-YAK"][_inv_next % 4]
	var code := ("" if kind == "friend" else kind.to_upper() + "-") + "%s-%d" % [words, _inv_next]
	_inv_next += 1
	inv_codes[InviteRules.canonical(code)] = {"user_id": me, "kind": kind, "code": code}
	return code


func _inv_name(id: String) -> String:
	return str(accounts[id].username) if accounts.has(id) and accounts[id].age_band != "" else ""


func _inv_pay(id: String, gold: int) -> void:
	if gold > 0 and accounts.has(id):
		wallets[id] = int(wallets.get(id, 0)) + gold


func _inv_invite_info(me: String, p: Dictionary) -> Dictionary:
	var r := _inv(me)
	var claimed: bool = accounts[me].age_band != ""
	if claimed and r.code == "":
		r.code = _inv_new_code(me, "friend")
	var friends: Array = []
	var learned := 0
	var tree_friends := 0
	var tree_learned := 0
	for i in range((r.friends as Array).size() - 1, -1, -1):
		var f: String = r.friends[i]
		var fr := _inv(f)
		var theirs := 0
		for g: String in fr.friends:
			theirs += 1 if _inv(g).learned else 0
		tree_friends += (fr.friends as Array).size()
		tree_learned += theirs
		learned += 1 if fr.learned else 0
		friends.append({"name": _inv_name(f), "learned": fr.learned, "joined_ms": clock_ms, "friends": (fr.friends as Array).size(),
			"learned_friends": theirs})
	var news: Array = []
	for n: Dictionary in r.news:
		news.append({"what": n.what, "name": _inv_name(n.id) if n.id != "" else "", "gold": n.gold, "at_ms": clock_ms})
	if p.get("seen") == true:
		r.news = []
	var groups := {}
	for kind: String in r.groups:
		var members: Array = inv_groups.get(InviteRules.canonical(r.groups[kind]), [])
		var done := 0
		for m: String in members:
			done += 1 if _inv(m).learned else 0
		groups[kind] = {"code": r.groups[kind], "members": members.size(), "learned": done, "mine": r.made.get(kind, "") == r.groups[kind]}
	return {"ok": true, "claimed": claimed, "code": r.code, "can_use_code": r.by == "" and not inv_old.has(me),
		"guide": _inv_name(r.by) if r.by != "" else "", "friends": friends,
		"counts": {"friends": (r.friends as Array).size(), "learned": learned, "tree_friends": tree_friends,
			"tree_learned": tree_learned, "children_learning": learned + tree_learned},
		"month": {"learned": learned, "tree": 0, "landed": 0}, "caps": {"learned": 10, "tree": 20, "landed": 10}, "earned": r.earned,
		"groups": groups, "made": r.made, "news": news, "world": {"joined": 0, "learned": 0},
		"rewards": {"welcome": 100, "inviter": 250, "learner": 50, "tree": 25, "landed": 150}}


func _inv_invite_use(me: String, p: Dictionary) -> Dictionary:
	var found: Dictionary = inv_codes.get(InviteRules.canonical(str(p.get("code", ""))), {})
	if found.is_empty():
		return {"ok": false, "error": "unknown"}
	if found.user_id == me:
		return {"ok": false, "error": "own_code"}
	var r := _inv(me)
	var referral := false
	var group := ""
	if found.kind == "friend":
		if r.by != "":
			return {"ok": false, "error": "already_used"}
		if inv_old.has(me):
			return {"ok": false, "error": "not_new"}
		referral = true
	else:
		if r.groups.has(found.kind):
			return {"ok": false, "error": "already_in"}
		group = found.kind
		r.groups[group] = found.code
		(inv_groups[InviteRules.canonical(found.code)] as Array).append(me)
		referral = r.by == "" and not inv_old.has(me)
	var welcome := 0
	if referral:
		r.by = found.user_id
		(_inv(found.user_id).friends as Array).append(me)
		(_inv(found.user_id).news as Array).append({"what": "joined", "id": me, "gold": 0})
		welcome = 100
		_inv_pay(me, welcome)
		notify(found.user_id, 108, {"what": "joined", "gold": 0})
		soc_welcome_present(found.user_id, me)   # module 0.2.18: a present that waited on the code
	return {"ok": true, "kind": found.kind, "guide": _inv_name(found.user_id), "welcome": welcome, "gold": int(wallets.get(me, 0)),
		"group": group}


func _inv_invite_progress(me: String, p: Dictionary) -> Dictionary:
	var r := _inv(me)
	var event := str(p.get("event", ""))
	if not event in ["learned", "landed"]:
		return {"ok": false, "error": "bad_request"}
	var guide := _inv_name(r.by) if r.by != "" else ""
	var landing := event == "landed"
	if (r.landed if landing else r.learned) or (landing and p.get("where") != "moon"):
		return {"ok": true, "counted": false, "gold": 0, "guide": guide}
	r[event] = true
	if r.by == "":
		return {"ok": true, "counted": true, "gold": 0, "guide": guide}
	var paid := 150 if landing else 250
	_inv_pay(r.by, paid)
	_inv(r.by).earned += paid
	(_inv(r.by).news as Array).append({"what": event, "id": me, "gold": paid})
	notify(r.by, 108, {"what": event, "gold": paid})
	if landing:
		return {"ok": true, "counted": true, "gold": 0, "guide": guide}
	var grand: String = _inv(r.by).by
	if grand != "":
		_inv_pay(grand, 25)
		(_inv(grand).news as Array).append({"what": "tree", "id": "", "gold": 25})
	_inv_pay(me, 50)
	return {"ok": true, "counted": true, "gold": 50, "guide": guide}


func _inv_invite_group(me: String, p: Dictionary) -> Dictionary:
	var kind := str(p.get("kind", ""))
	if not kind in ["class", "family"]:
		return {"ok": false, "error": "bad_request"}
	var r := _inv(me)
	match str(p.get("action", "")):
		"make":
			if accounts[me].age_band == "":
				return {"ok": false, "error": "not_claimed"}
			if not r.made.has(kind):
				var code := _inv_new_code(me, kind)
				r.made[kind] = code
				inv_groups[InviteRules.canonical(code)] = [] if r.groups.has(kind) else [me]
				if not r.groups.has(kind):
					r.groups[kind] = code
			return {"ok": true, "code": r.made[kind]}
		"leave":
			if r.groups.has(kind):
				(inv_groups.get(InviteRules.canonical(r.groups[kind]), []) as Array).erase(me)
				r.groups.erase(kind)
			return {"ok": true}
		"remove":
			if r.made.has(kind):
				inv_codes.erase(InviteRules.canonical(r.made[kind]))
				inv_groups.erase(InviteRules.canonical(r.made[kind]))
				r.made.erase(kind)
			return {"ok": true}
	return {"ok": false, "error": "bad_request"}


# --- Owner #81, #82, #85: better together (module 0.2.18: server/modules/src/server/together.ts), the game's side's needs
# social_info, social_learned (a day together with friends who learned the same day; study buddies' shared days; the
# week), social_moment / social_cheer, present_send / present_open / present_thank (one can wait on the invite code),
# study_buddy, crew. The day is soc_day (tests move it); caps beyond "one a day to each friend" are the Node tests'.

const SOC_CALLS: Array[String] = ["social_info", "social_learned", "social_moment", "social_cheer", "present_send",
	"present_open", "present_thank", "study_buddy", "crew"]
const SOC_LEVELS: Array[int] = [1, 7, 30]
## user id -> {"friends": {id: {"days", "last"}}, "learned": [days], "week": {"days", "units"}, "buddies": {id: {"state",
## "days", "last"}}, "feed": [], "presents": [], "link_gifts": [], "news": [], "crew": "", "crew_invites": [], "sent": {}}
var soc := {}
var soc_crews := {}    # crew id -> {"id", "adjective", "noun", "badge", "maker", "members": [ids], "looks": {id: look}}
var soc_day := 20_726  # the server's UTC day
var _soc_next := 1


func _soc(me: String) -> Dictionary:
	if not soc.has(me):
		soc[me] = {"friends": {}, "learned": [], "week": {"days": 0, "units": []}, "buddies": {}, "feed": [], "presents": [],
			"link_gifts": [], "news": [], "crew": "", "crew_invites": [], "sent": {}}
	return soc[me]


func _soc_level(days: int) -> int:
	var out := 0
	for i in SOC_LEVELS.size():
		out = i + 1 if days >= SOC_LEVELS[i] else out
	return out


func _soc_news(to: String, what: String, from: String, kind: String = "", gold: int = 0, place: String = "") -> void:
	var list: Array = _soc(to).news
	list.append({"what": what, "id": from, "kind": kind, "gold": gold, "place": place})
	notify(to, 109, {"what": what})


func _soc_pair_day(a: String, b: String) -> void:
	for pair: Array in [[a, b], [b, a]]:
		var f: Dictionary = _soc(pair[0]).friends.get(pair[1], {"days": 0, "last": -1})
		if int(f.last) >= soc_day:
			continue
		var before := _soc_level(int(f.days))
		f.days = int(f.days) + 1
		f.last = soc_day
		_soc(pair[0]).friends[pair[1]] = f
		if _soc_level(int(f.days)) > before:
			_soc_news(pair[0], "level", pair[1], ["good", "great", "best"][_soc_level(int(f.days)) - 1])


func _soc_crew_out(c: Dictionary, me: String) -> Dictionary:
	var members: Array = []
	var done := 0
	for id: String in c.members:
		var w: Dictionary = _soc(id).week
		done += mini(int(w.days), 7)
		members.append({"name": accounts[id].username, "me": id == me, "look": c.looks.get(id, {}),
			"week": {"days": int(w.days), "units": (w.units as Array).duplicate()}})
	return {"id": c.id, "name": "%s %s" % [c.adjective, c.noun], "adjective": c.adjective, "noun": c.noun, "badge": c.badge,
		"mine": c.maker == me, "members": members, "goal": {"done": done, "target": 3 * maxi(members.size(), 2)},
		"full": members.size() >= 6}


func _soc_social_info(me: String, p: Dictionary) -> Dictionary:
	var r := _soc(me)
	var friends: Array = []
	for id: String in _i_friends(me):
		if not can_play(id):
			continue
		var f: Dictionary = r.friends.get(id, {"days": 0, "last": -1})
		var b: Dictionary = r.buddies.get(id, {})
		var row: Array = [0, 0, 0, 0, 0, 0, 0]
		if b.get("state", "") == "yes":
			for i in 7:
				var d := soc_day - 6 + i
				if d >= int(b.get("since", 0)):
					row[i] = (1 if (r.learned as Array).has(d) else 0) + (1 if (_soc(id).learned as Array).has(d) else 0)
		friends.append({"id": id, "name": accounts[id].username, "days": int(f.days), "level": _soc_level(int(f.days)),
			"today": int(f.last) == soc_day, "buddy": {"state": str(b.get("state", "")), "days": int(b.get("days", 0)), "row": row}})
	friends.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return str(x.name).to_lower() < str(y.name).to_lower())
	var feed: Array = []
	for m: Dictionary in r.feed:
		if _i_friends(me).has(m.from):
			feed.append({"id": m.id, "name": accounts[m.from].username, "kind": m.kind, "place": m.place, "at_ms": clock_ms})
	var presents: Array = []
	for g: Dictionary in r.presents:
		if accounts.has(g.from) and (g.link or _i_friends(me).has(g.from)):
			presents.append({"id": g.id, "name": accounts[g.from].username, "kind": g.kind, "at_ms": clock_ms, "opened": g.opened,
				"thanked": g.thanked, "link": g.link})
	var news: Array = []
	for n: Dictionary in r.news:
		if accounts.has(n.id):
			news.append({"what": n.what, "name": accounts[n.id].username, "kind": n.kind, "gold": n.gold, "place": n.place,
				"at_ms": clock_ms})
	if p.get("seen") == true:
		r.news = []
	var invites: Array = []
	for v: Dictionary in r.crew_invites:
		if soc_crews.has(v.crew):
			var c: Dictionary = soc_crews[v.crew]
			invites.append({"crew": v.crew, "name": "%s %s" % [c.adjective, c.noun], "badge": c.badge,
				"from": accounts[v.from].username, "members": (c.members as Array).size(), "full": (c.members as Array).size() >= 6})
	var crew_out: Variant = null
	if soc_crews.has(r.crew) and (soc_crews[r.crew].members as Array).has(me):
		crew_out = _soc_crew_out(soc_crews[r.crew], me)
	var sent: Array = r.sent.get(soc_day, [])
	return {"ok": true, "allowed": can_play(me), "friends": friends, "feed": feed, "presents": presents,
		"link_gifts": (r.link_gifts as Array).duplicate(), "news": news, "crew": crew_out, "crew_invites": invites,
		"sends_left": 5 - sent.size(), "cheers_left": 30,
		"rules": {"levels": SOC_LEVELS, "sends_per_day": 5, "link_gifts_max": 3, "thank_gold": 10, "buddies_max": 3,
			"crew_min": 2, "crew_max": 6, "crew_goal_per_member": 3}}


func _soc_social_learned(me: String, p: Dictionary) -> Dictionary:
	var r := _soc(me)
	var unit := str(p.get("unit", ""))
	if unit != "" and SchoolData.valid_id(unit) and not (r.week.units as Array).has(unit):
		(r.week.units as Array).append(unit)
	if (r.learned as Array).has(soc_day):
		return {"ok": true, "first": false, "together": 0}
	(r.learned as Array).append(soc_day)
	r.week.days = int(r.week.days) + 1
	var together := 0
	for id: String in _i_friends(me):
		if not (_soc(id).learned as Array).has(soc_day):
			continue
		together += 1
		_soc_pair_day(me, id)
		var mine: Dictionary = r.buddies.get(id, {})
		var theirs: Dictionary = _soc(id).buddies.get(me, {})
		if mine.get("state", "") == "yes" and theirs.get("state", "") == "yes":
			for b: Dictionary in [mine, theirs]:
				if int(b.get("last", -1)) < soc_day:
					b.days = int(b.get("days", 0)) + 1
					b.last = soc_day
	return {"ok": true, "first": true, "together": together}


func _soc_social_moment(me: String, p: Dictionary) -> Dictionary:
	if not can_play(me):
		return {"ok": false, "error": "not_allowed_online"}
	if not PostcardRules.KINDS.has(str(p.get("kind", ""))) or PostcardRules.PLACE_RE.search(str(p.get("place", ""))) == null:
		return {"ok": false, "error": "bad_request"}
	var id := "m%d_%d" % [clock_ms, _soc_next]
	_soc_next += 1
	var told := 0
	for f: String in _i_friends(me):
		(_soc(f).feed as Array).append({"id": id, "from": me, "kind": p.kind, "place": p.place})
		notify(f, 109, {"what": "moment"})
		told += 1
	return {"ok": true, "told": told}


func _soc_social_cheer(me: String, p: Dictionary) -> Dictionary:
	if not FriendshipRules.CHEER_IDS.has(str(p.get("cheer", ""))):
		return {"ok": false, "error": "bad_request"}
	var r := _soc(me)
	for m: Dictionary in r.feed:
		if m.id == str(p.get("moment_id", "")):
			r.feed.erase(m)
			if not _i_friends(me).has(m.from):
				return {"ok": false, "error": "not_found"}
			_soc_news(m.from, "cheer", me, str(p.cheer), 0, "%s:%s" % [m.kind, m.place])
			_soc_pair_day(me, m.from)
			return {"ok": true}
	return {"ok": false, "error": "not_found"}


func _soc_present_send(me: String, p: Dictionary) -> Dictionary:
	var kind := str(p.get("kind", ""))
	if not FriendPresents.KINDS.has(kind):
		return {"ok": false, "error": "bad_request"}
	if not can_play(me):
		return {"ok": false, "error": "not_allowed_online"}
	var r := _soc(me)
	var sent: Array = r.sent.get(soc_day, [])
	r.sent[soc_day] = sent
	if p.get("link") == true:
		if (r.link_gifts as Array).size() >= 3:
			return {"ok": false, "error": "too_many_waiting"}
		(r.link_gifts as Array).append(kind)
		sent.append("")
		return {"ok": true, "waiting": (r.link_gifts as Array).size(), "sends_left": 5 - sent.size()}
	var f := _i_friend(me, p)
	if f.has("error"):
		return {"ok": false, "error": f.error}
	if sent.has(f.uid):
		return {"ok": false, "error": "sent_today"}
	if sent.size() >= 5:
		return {"ok": false, "error": "too_many_today"}
	sent.append(f.uid)
	var id := "p%d_%d" % [clock_ms, _soc_next]
	_soc_next += 1
	(_soc(f.uid).presents as Array).append({"id": id, "from": me, "kind": kind, "opened": false, "thanked": false, "link": false})
	_soc_news(f.uid, "present", me, kind)
	_soc_pair_day(me, f.uid)
	return {"ok": true, "sends_left": 5 - sent.size()}


## invite_use's part (Together.welcomePresent): the first present waiting on the guide's code goes to the new friend.
func soc_welcome_present(guide: String, newcomer: String) -> void:
	var waiting: Array = _soc(guide).link_gifts
	if waiting.is_empty():
		return
	var kind: String = waiting.pop_front()
	(_soc(newcomer).presents as Array).append({"id": "p%d_%d" % [clock_ms, _soc_next], "from": guide, "kind": kind,
		"opened": false, "thanked": false, "link": true})
	_soc_next += 1
	_soc_news(guide, "link_present", newcomer, kind)


func _soc_present_open(me: String, p: Dictionary) -> Dictionary:
	for g: Dictionary in _soc(me).presents:
		if g.id == str(p.get("id", "")) and not g.opened:
			g.opened = true
			return {"ok": true, "kind": g.kind, "name": accounts[g.from].username, "link": g.link}
	return {"ok": false, "error": "not_found"}


func _soc_present_thank(me: String, p: Dictionary) -> Dictionary:
	for g: Dictionary in _soc(me).presents:
		if g.id == str(p.get("id", "")):
			if not g.opened:
				return {"ok": false, "error": "not_opened"}
			if g.thanked:
				return {"ok": false, "error": "already_thanked"}
			g.thanked = true
			_inv_pay(g.from, 10)
			_soc_news(g.from, "thanks", me, g.kind, 10)
			return {"ok": true, "gold": 10}
	return {"ok": false, "error": "not_found"}


func _soc_study_buddy(me: String, p: Dictionary) -> Dictionary:
	var action := str(p.get("action", ""))
	var other := str(p.get("user_id", ""))
	if action in ["no", "stop"]:
		_soc(me).buddies.erase(other)
		if accounts.has(other):
			_soc(other).buddies.erase(me)
		return {"ok": true, "state": ""}
	if not action in ["ask", "yes"]:
		return {"ok": false, "error": "bad_request"}
	var f := _i_friend(me, p)
	if f.has("error"):
		return {"ok": false, "error": f.error}
	var mine: Dictionary = _soc(me).buddies.get(other, {})
	if action == "yes" or mine.get("state", "") == "asking":
		if mine.get("state", "") != "asking":
			return {"ok": false, "error": "not_found"}
		var both := 1 if (_soc(me).learned as Array).has(soc_day) and (_soc(other).learned as Array).has(soc_day) else 0
		_soc(me).buddies[other] = {"state": "yes", "days": both, "last": soc_day if both > 0 else -1, "since": soc_day}
		_soc(other).buddies[me] = {"state": "yes", "days": both, "last": soc_day if both > 0 else -1, "since": soc_day}
		_soc_news(other, "buddy_yes", me)
		return {"ok": true, "state": "yes"}
	if (_soc(me).buddies as Dictionary).size() >= 3:
		return {"ok": false, "error": "too_many_buddies"}
	_soc(me).buddies[other] = {"state": "asked", "days": 0, "last": -1}
	_soc(other).buddies[me] = {"state": "asking", "days": 0, "last": -1}
	_soc_news(other, "buddy_ask", me)
	return {"ok": true, "state": "asked"}


func _soc_crew(me: String, p: Dictionary) -> Dictionary:
	if not can_play(me):
		return {"ok": false, "error": "not_allowed_online"}
	var r := _soc(me)
	var mine: Dictionary = soc_crews.get(r.crew, {})
	match str(p.get("action", "")):
		"make":
			if not mine.is_empty():
				return {"ok": false, "error": "in_a_crew"}
			if not CrewRules.ADJECTIVES.has(str(p.get("adjective", ""))) or not CrewRules.NOUNS.has(str(p.get("noun", ""))):
				return {"ok": false, "error": "bad_name"}
			if not CrewRules.BADGES.has(str(p.get("badge", ""))):
				return {"ok": false, "error": "bad_badge"}
			var id := "c%d_%d" % [clock_ms, _soc_next]
			_soc_next += 1
			soc_crews[id] = {"id": id, "adjective": p.adjective, "noun": p.noun, "badge": p.badge, "maker": me, "members": [me],
				"looks": {me: p.get("look", {})}}
			r.crew = id
			return {"ok": true, "crew": _soc_crew_out(soc_crews[id], me)}
		"invite":
			if mine.is_empty():
				return {"ok": false, "error": "no_crew"}
			var f := _i_friend(me, p)
			if f.has("error"):
				return {"ok": false, "error": f.error}
			if (mine.members as Array).has(f.uid):
				return {"ok": false, "error": "already_in"}
			if (mine.members as Array).size() >= 6:
				return {"ok": false, "error": "crew_full"}
			(_soc(f.uid).crew_invites as Array).append({"crew": mine.id, "from": me})
			_soc_news(f.uid, "crew_invite", me, mine.id)
			return {"ok": true}
		"join":
			var crew_id := str(p.get("crew", ""))
			var invited := (r.crew_invites as Array).filter(func(v: Dictionary) -> bool: return v.crew == crew_id)
			if invited.is_empty():
				return {"ok": false, "error": "not_invited"}
			if not mine.is_empty():
				return {"ok": false, "error": "in_a_crew"}
			if not soc_crews.has(crew_id):
				return {"ok": false, "error": "not_found"}
			var c: Dictionary = soc_crews[crew_id]
			if (c.members as Array).size() >= 6:
				return {"ok": false, "error": "crew_full"}
			for m: String in c.members:
				_soc_news(m, "crew_join", me, crew_id)
			(c.members as Array).append(me)
			c.looks[me] = p.get("look", {})
			r.crew = crew_id
			r.crew_invites = (r.crew_invites as Array).filter(func(v: Dictionary) -> bool: return v.crew != crew_id)
			return {"ok": true, "crew": _soc_crew_out(c, me)}
		"decline":
			r.crew_invites = (r.crew_invites as Array).filter(func(v: Dictionary) -> bool: return v.crew != str(p.get("crew", "")))
			return {"ok": true}
		"leave":
			if not mine.is_empty():
				(mine.members as Array).erase(me)
				if (mine.members as Array).is_empty():
					soc_crews.erase(mine.id)
			r.crew = ""
			return {"ok": true}
		"look":
			if mine.is_empty():
				return {"ok": false, "error": "no_crew"}
			mine.looks[me] = p.get("look", {})
			return {"ok": true, "crew": _soc_crew_out(mine, me)}
	return {"ok": false, "error": "bad_request"}

# --- Owner #99: the same name on a new device, with proof (module 0.2.20: server/modules/src/server/moves.ts) ---
# move_request {"action": "start" | "status" | "cancel"} on the new device and move_approve {"action": "list" | "approve" |
# "decline"} on the account's own devices, with the module's answers: a 6-digit code for 5 minutes, three wrong codes end
# an ask, the asker sees "waiting" whatever the account's side did (the lead's security review) until its code is over;
# an approved ask hands its asker a one-time key that sign_in_with_key takes once (_o99_consume). Notification 110:
# {"what": "asked" | "moved", "kind"} to the account, {"what": "approved"} to the asker. Times: clock_ms.

const O99_CALLS: Array[String] = ["move_request", "move_approve"]
const MOVE_CODE_MS := 300_000
var move_asks := {}    # account id -> Array of {id, from, kind, code, made_ms, state, wrong, why, approved_ms, key}
var move_asked := {}   # asking account id -> {"target", "id"}
var _move_next := 1


## The ask with this id among the account's, as the module's tidy leaves it ({} when none).
func _o99_ask(target: String, id: String) -> Dictionary:
	for a: Dictionary in move_asks.get(target, []):
		if a.id == id:
			if a.state == "open" and clock_ms - int(a.made_ms) >= MOVE_CODE_MS:
				a.state = "ended"
				a.why = "expired"
			if a.state == "approved" and clock_ms - int(a.approved_ms) >= MOVE_CODE_MS:
				a.state = "ended"
				a.why = "expired"
			return a
	return {}


func _o99_quiet(made_ms: int) -> Dictionary:
	var left := ceili((made_ms + MOVE_CODE_MS - clock_ms) / 1000.0)
	return {"ok": true, "state": "waiting", "left_s": left} if left > 0 else {"ok": true, "state": "ended", "why": "expired"}


func _o99_move_request(me: String, p: Dictionary) -> Dictionary:
	match str(p.get("action", "")):
		"start":
			var target := _id_of_any_case(str(p.get("username", "")).strip_edges())
			if target == "" or accounts[target].age_band == "":
				return {"ok": false, "error": "no_such_player"}
			if target == me:
				return {"ok": false, "error": "self"}
			var before: Dictionary = move_asked.get(me, {})
			if not before.is_empty():
				var old := _o99_ask(before.target, before.id)
				if old.get("state") in ["open", "approved"]:
					old.state = "ended"
					old.why = "replaced"
			var id := "ask-%d" % _move_next
			var code := "%06d" % ((_move_next * 7919 + 123) % 1_000_000)
			_move_next += 1
			var kind := str(p.get("kind", ""))
			if kind not in ["phone", "tablet", "computer"]:
				kind = "device"
			if not move_asks.has(target):
				move_asks[target] = []
			(move_asks[target] as Array).append({"id": id, "from": me, "kind": kind, "code": code, "made_ms": clock_ms,
				"state": "open", "wrong": 0, "why": "", "approved_ms": 0, "key": ""})
			move_asked[me] = {"target": target, "id": id}
			notify(target, 110, {"what": "asked", "kind": kind})
			return {"ok": true, "id": id, "code": code, "valid_s": MOVE_CODE_MS / 1000}
		"status":
			var mine: Dictionary = move_asked.get(me, {})
			if mine.is_empty() or mine.id != str(p.get("id", "")):
				return {"ok": false, "error": "not_found"}
			var a := _o99_ask(mine.target, mine.id)
			if a.is_empty():
				return {"ok": false, "error": "not_found"}
			match str(a.state):
				"approved":
					var k := ""
					for i in 8:
						k += KEY_ALPHABET[(_move_next * 11 + i * 5) % 32]
					_move_next += 1
					a.key = k
					return {"ok": true, "state": "approved", "key": k.substr(0, 4) + "-" + k.substr(4),
						"username": accounts[mine.target].username}
				"done":
					return {"ok": true, "state": "done"}
			if a.state == "ended" and a.why == "cancelled":
				return {"ok": true, "state": "ended", "why": "cancelled"}
			return _o99_quiet(int(a.made_ms))
		"cancel":
			var mine: Dictionary = move_asked.get(me, {})
			if mine.is_empty() or mine.id != str(p.get("id", "")):
				return {"ok": false, "error": "not_found"}
			var a := _o99_ask(mine.target, mine.id)
			if a.get("state") in ["open", "approved"]:
				a.state = "ended"
				a.why = "cancelled"
			move_asked.erase(me)
			return {"ok": true}
	return {"ok": false, "error": "bad_request"}


func _o99_move_approve(me: String, p: Dictionary) -> Dictionary:
	match str(p.get("action", "")):
		"list":
			var out: Array = []
			for a: Dictionary in move_asks.get(me, []):
				if _o99_ask(me, a.id).state == "open":
					out.append({"id": a.id, "kind": a.kind, "left_s": ceili((int(a.made_ms) + MOVE_CODE_MS - clock_ms) / 1000.0)})
			return {"ok": true, "username": accounts[me].username, "asks": out}
		"approve":
			var a := _o99_ask(me, str(p.get("id", "")))
			if a.is_empty():
				return {"ok": false, "error": "not_found"}
			if a.state != "open":
				return {"ok": false, "error": "ended", "why": a.why}
			if str(p.get("code", "")) == a.code:
				a.state = "approved"
				a.approved_ms = clock_ms
				notify(str(a.from), 110, {"what": "approved"})
				return {"ok": true}
			a.wrong = int(a.wrong) + 1
			if int(a.wrong) >= 3:
				a.state = "ended"
				a.why = "wrong_code"
				return {"ok": false, "error": "ended", "why": "wrong_code"}
			return {"ok": false, "error": "wrong_code", "tries_left": 3 - int(a.wrong)}
		"decline":
			var a := _o99_ask(me, str(p.get("id", "")))
			if a.is_empty():
				return {"ok": false, "error": "not_found"}
			if a.state in ["open", "approved"]:
				a.state = "ended"
				a.why = "declined"
			return {"ok": true}
	return {"ok": false, "error": "bad_request"}


## sign_in_with_key: the one-time key an approved ask of `me` got for `target`, used up now ({} when it is not that key).
func _o99_consume(me: String, target: String, key: String) -> Dictionary:
	var mine: Dictionary = move_asked.get(me, {})
	if mine.is_empty() or mine.target != target:
		return {}
	var a := _o99_ask(target, mine.id)
	if a.is_empty() or a.state != "approved" or a.from != me or a.key == "" or a.key != key:
		return {}
	a.state = "done"
	a.key = ""
	return a

# --- Owner #105: the account's password, LOG IN with it, one device at a time (module 0.2.20: passwords.ts) ---
# password {"action": "state" | "set" | "change"} and sign_in_with_password {"username", "password", "device_id"} with the
# module's answers: the rules (PasswordRules), one answer for a wrong name or password, 5 wrong per name lock it 900 s;
# a log-in links the new id and logs every other device of the account out (unlinked, their connections closed).

const O105_CALLS: Array[String] = ["password", "sign_in_with_password", "log_out"]
## The password test accounts get (make_account, and a claim while claims_make_password).
const FAKE_PASSWORD := "made-with-the-name-7"
## A claim also makes the account's password, as the game's claim page goes on to do (false: test that step itself).
var claims_make_password := true
var passwords := {}       # user id -> the password (the fake keeps it plain; the module keeps a bcrypt hash)
var password_tries := {}  # "lower-case name|asking account" -> wrong tries (the pair: the module's main lock)
var password_tried := {}  # user id -> clock_ms of the last wrong try the account was told of (at most once an hour)


func _o105_password(me: String, p: Dictionary) -> Dictionary:
	var a: Dictionary = accounts[me]
	match str(p.get("action", "")):
		"state":
			return {"ok": true, "has_password": passwords.has(me), "tried_ms": int(password_tried.get(me, 0))}
		"set", "change":
			if a.age_band == "":
				return {"ok": false, "error": "not_claimed"}
			if p.action == "set" and passwords.has(me):
				return {"ok": false, "error": "has_password"}
			if p.action == "change" and passwords.has(me):
				var by_key: bool = normalize_key(str(p.get("key", ""))) != "" and keys.get(me, "") == normalize_key(str(p.get("key", "")))
				if str(p.get("old", "")) != passwords[me] and not by_key:
					return {"ok": false, "error": "wrong_password"}
			var problem := PasswordRules.problem(str(p.get("password", "")), str(a.username))
			if problem != "":
				return {"ok": false, "error": problem}
			passwords[me] = str(p.password)
			return {"ok": true}
	return {"ok": false, "error": "bad_request"}


func _o105_sign_in_with_password(me: String, p: Dictionary) -> Dictionary:
	var device := str(p.get("device_id", ""))
	if not DeviceId.is_valid(device):
		return {"ok": false, "error": "bad_request"}
	var name := str(p.get("username", "")).strip_edges().to_lower()
	if int(password_tries.get(name + "|" + me, 0)) >= 5:
		return {"ok": false, "error": "locked", "wait": 900}
	var target := _id_of_any_case(name) if name != "" else ""
	if target == "" or accounts[target].age_band == "" or not passwords.has(target) or str(p.get("password", "")) != passwords[target]:
		password_tries[name + "|" + me] = int(password_tries.get(name + "|" + me, 0)) + 1
		if target != "" and target != me and passwords.has(target) \
				and clock_ms - int(password_tried.get(target, -3_600_000)) >= 3_600_000:
			password_tried[target] = clock_ms   # the module's note 112 (password_tried), at most once an hour
			notify(target, 112, {"what": "tried"})
		return {"ok": false, "error": "wrong_password"}
	password_tries.erase(name + "|" + me)
	if target == me:
		return {"ok": true, "user_id": target, "username": accounts[target].username, "left": "same"}
	if linked.has(device) or _id_of_device(device) != "":
		return {"ok": false, "error": "bad_request"}
	linked[device] = target
	log_out_others(target, device)
	return {"ok": true, "user_id": target, "username": accounts[target].username, "left": "kept"}   # the asker stays


## Keys.signOutOthers: every device of the account but `keep` is unlinked and its connections close.
func log_out_others(id: String, keep: String) -> void:
	if str(accounts[id].device) != keep:
		if str(accounts[id].device) != "":
			removed_devices[str(accounts[id].device)] = true   # tombstoned: it never signs in or makes an account again
		accounts[id].device = ""
	for d: String in linked.keys():
		if linked[d] == id and d != keep:
			linked.erase(d)
			removed_devices[d] = true
	for b: Backend in (clients.get(id, []) as Array).duplicate():
		b.drop()


## The module's log_out: a claimed account with a password unlinks THIS device (tombstoned), its sessions end.
func _o105_log_out(me: String, p: Dictionary) -> Dictionary:
	if accounts[me].age_band == "":
		return {"ok": false, "error": "not_claimed"}
	if not passwords.has(me):
		return {"ok": false, "error": "password_needed"}
	var device := str(p.get("device_id", ""))
	var mine: bool = str(accounts[me].device) == device or str(linked.get(device, "")) == me
	if device == "" or not mine:
		return {"ok": false, "error": "not_allowed"}
	if str(accounts[me].device) == device:
		accounts[me].device = ""
	linked.erase(device)
	removed_devices[device] = true
	log_outs.append(me)
	return {"ok": true}
