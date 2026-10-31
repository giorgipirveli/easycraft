class_name OnlineService
extends Node
## Online play with friends on this device (M4 Wave 1, Agent C; spec §17.1-17.3): signing in, the
## account and its PLAY ONLINE screen, the username claim, verified parental consent for under-13,
## friends with online dots, block / mute / report, and invites (notifications 101/102, 103 when a
## grown-up approved something). The match itself stays Session's (host_online / join_online).
##
## The server is behind an OnlineBackend: NakamaOnlineBackend in the game (Session loads it by path,
## so solo and LAN games never load the Nakama client), an in-memory fake in tests. Every action
## answers "" when it worked, else plain, kind words (OnlineRules.message). Nothing social happens
## unless OnlineRules.social_allowed: the client never shows it, and the server refuses it again.

signal status_changed(status: StringName)
signal account_changed
signal friends_changed
## A friend invites this player into their world ({match_id, from_username, from_id, world_name}).
signal invite_received(invite: Dictionary)
signal invite_cancelled(match_id: String)
## The host of `match_id` took this player out of its world (spec §17.3 "Safety in the world").
signal removed_from_world(match_id: String)

const OFFLINE := &"offline"
const CONNECTING := &"connecting"
const ONLINE := &"online"

## Report reasons (big buttons; report_user's "reason", the server's reason codes).
const REPORT_MEAN := "mean_words"
const REPORT_SCARY := "scary"
const REPORT_SECRETS := "personal_info"   # asked for a real name, home, school...
const REPORT_OTHER := "other"
const REPORT_REASONS: Array[String] = [REPORT_MEAN, REPORT_SCARY, REPORT_SECRETS, REPORT_OTHER]
## An invite nobody answered goes away quietly (the friends list shows JOIN meanwhile).
const INVITE_SECONDS := 600

var backend: OnlineBackend
var server := OnlineConfig.parse_server("")
var device_id := ""                      # "" = this install's DeviceId (tests set one)
var device_id_path := DeviceId.PATH
var prefs_path := OnlinePrefs.PATH
var profile: ProfileData                 # default: Profile.data
var save_profile := Callable()           # default: Profile.save
var clock := Callable()                  # () -> unix seconds; default: the system clock

var status := OFFLINE
var account: Dictionary = {}             # OnlineRules.account; {} until signed in
var friends: Array[Dictionary] = []      # {id, username, state (OnlineRules), online}, sorted for the list
var prefs: OnlinePrefs

## Owner #99 (the second review's medium 4): which player's session this is. forget_session bumps it (another player
## plays on this device now); every coroutine that writes the profile, the account or the wallet files after an await
## checks it first (_stale), so the last player's late answers never land in the new player's files.
var session := 0
var _invites := {}                       # match id -> invite, with "at" (unix seconds)
var _blocked: Array[String] = []
var _connected_backend: OnlineBackend


func _init() -> void:
	prefs = OnlinePrefs.new()


func _ready() -> void:
	if profile == null:
		profile = Profile.data
	if not save_profile.is_valid():
		save_profile = Profile.save
	prefs = OnlinePrefs.load_from(prefs_path)
	if backend and backend.get_parent() == null:
		add_child(backend)
	_f_ready()   # M4 F: the profile backup, the economy online, age signals


# --- Signing in and the account ---

## Signs in (once; a second call waits for the first) and reads the account. "" or plain words.
func sign_in() -> String:
	if status == ONLINE:
		return ""
	if status == CONNECTING:
		await status_changed
		if is_inside_tree():
			await get_tree().process_frame   # not inside the first call's signal: the caller may free things
		return "" if status == ONLINE else OnlineRules.message("network")
	if backend == null:
		return OnlineRules.message("not_signed_in")
	if not has_server():
		return OnlineRules.message("no_server")   # never tries to connect
	if logged_out:
		return PasswordRules.LOGGED_OUT   # owner #105: another device logged in; only LOG IN brings this device back
	_watch_backend()
	_set_status(CONNECTING)
	var s := session   # owner #99: another player may come while this one signs in (forget_session)
	# Owner #105: a device that had an account signs in with create=false: it never makes a new account by itself
	var known := device_id == "" and (FileAccess.file_exists(device_id_path) or FileAccess.file_exists(device_id_path + ".bak"))
	var id := device_id if device_id != "" else DeviceId.load_or_create(device_id_path)
	var r: Dictionary = await backend.sign_in(server, id, not known)
	if _stale(s):
		return OnlineRules.message("not_signed_in")
	if not r.get("ok", false) and str(r.get("error", "")) == "device_logged_out":
		# Owner #105 (the third review's N3/D): the server refuses a device unlinked from a CLAIMED account (logged out or
		# deleted elsewhere) with its own code; that is the logged-out case whatever this device's prefs say (a profile
		# from before this build kept no account name). It never makes a new account.
		_set_status(OFFLINE)
		_pw_logged_out()
		return PasswordRules.LOGGED_OUT
	if not r.get("ok", false) and str(r.get("error", "")) == "account_gone":
		# A plain 404 with a name kept here is logged out too; with no name at all, a never-claimed account went (the
		# clean-up, which leaves no tombstone): this player starts online anew.
		if prefs.account_name != "":
			_set_status(OFFLINE)
			_pw_logged_out()   # logged out, or the account was deleted, on another device: LOG IN (or NEW PLAYER)
			return PasswordRules.LOGGED_OUT
		# An empty, never-named account went (the retention clean-up): this player starts online anew, as a new device
		id = DeviceId.generate()
		if _o67_keep_device_id(id) != "":
			_set_status(OFFLINE)
			return OnlineRules.message("")
		r = await backend.sign_in(server, id, true)
		if _stale(s):
			return OnlineRules.message("not_signed_in")
	if not r.get("ok", false):
		_set_status(OFFLINE)
		return OnlineRules.message(str(r.get("error", "")))
	logged_out = false
	var err := await refresh_account()
	if _stale(s):
		return OnlineRules.message("not_signed_in")
	if err != "":
		backend.sign_out()
		_set_status(OFFLINE)
		return err
	_set_status(ONLINE)
	await _f_signed_in()   # M4 F: the profile backup, codes used offline
	if _stale(s):
		return ""
	if social_allowed():
		await refresh_friends()
	await _i_signed_in()   # M4 I: presents, bottles and new stickers waiting
	if _stale(s):
		return ""
	await _inv_signed_in()   # owner #79: a friend's code kept on this device, what learning the server has not heard
	if _stale(s):
		return ""
	await _soc_signed_in()   # owner #81, #85: learning days, units and moments friends have not heard; friends' news
	if _stale(s):
		return ""
	await _mv_signed_in()   # owner #99: asks from other devices to play as this account (the card)
	if _stale(s):
		return ""
	await _pw_signed_in()   # owner #105: the account's name kept with this player; whether it has a password
	return ""


## Owner #99 (the second review's medium 4): the session `s` is not this device's any more (another player came:
## forget_session). A sign-in of that session still on its way lets its link go, unless a newer one started.
func _stale(s: int) -> bool:
	if s == session:
		return false
	if status == OFFLINE and backend != null:
		backend.sign_out()
	return true


## Owner #99 (the second review's medium 4): online work of this player is on its way (a sign-in, a wallet sync, a paid
## code, a gold report, the profile backup): LOG IN and LOG OUT wait (they refuse with DeviceMoveRules.SWITCH_BUSY).
func busy() -> bool:
	return status == CONNECTING or _f_syncing or _f_paying > 0 or _f_sending or (profile_sync != null and profile_sync.busy())


## False in a build that has no server address yet (OnlineConfig.default_server: a release build
## before the owner's server exists).
func has_server() -> bool:
	return not server.has("error")


func sign_out() -> void:
	if backend:
		backend.sign_out()
	_went_offline()


func refresh_account() -> String:
	var moves := _f_moves if _f_paying == 0 else -1   # the gold-double bug: was the wallet read in the clear?
	var s := session
	var r: Dictionary = await backend.call_rpc("get_account_state", {})
	if s != session:
		return OnlineRules.message("not_signed_in")   # owner #99: another player plays now
	if not r.get("ok", false):
		return OnlineRules.message(str(r.get("error", "")))
	r = await _stricter_band_to_server(r)   # M4 Task 10 review
	account = OnlineRules.account(r, profile.age_band)
	_f_gold_read_at = moves if moves == _f_moves and _f_paying == 0 else -1
	account_changed.emit()
	return ""


## M4 Task 10 review: the phone's band is stricter than the account's (the store's age signal said under 13
## after a 13+ claim). The server hears it (set_parent_settings {"age_band"}: a stricter band needs no
## grown-up) and answers with the account under under-13's rules; until it has heard, the phone keeps
## under-13's rules itself (no friends, invites or chat without consent). The server never lifts a band.
func _stricter_band_to_server(reply: Dictionary) -> Dictionary:
	if not AgeBand.restrictions or profile.age_band != AgeBand.UNDER_13 or str(reply.get("age_band", "")) != String(AgeBand.TEEN_PLUS):
		return reply
	var r: Dictionary = await backend.call_rpc("set_parent_settings", {"age_band": String(AgeBand.UNDER_13)})
	if r.get("ok", false) and str(r.get("age_band", "")) == String(AgeBand.UNDER_13):
		return r
	var safe := reply.duplicate()
	safe.age_band = String(AgeBand.UNDER_13)
	return safe


func social_allowed() -> bool:
	return status == ONLINE and OnlineRules.social_allowed(account)


## Which PLAY ONLINE screen shows now (OnlineRules.screen).
func screen() -> StringName:
	return OnlineRules.screen(account, claimed(), card_due())


func claimed() -> bool:
	return OnlineRules.is_claimed(str(account.get("username", "")), profile.username, account.get("claimed"))


func card_due() -> bool:
	return OnlineRules.safe_card_due(prefs.safe_card_seen, _now())


func mark_card_seen() -> void:
	prefs.safe_card_seen = _now()
	prefs.save_to(prefs_path)


## Claims `username` on the server (unique, case-insensitive; the §5.13 rules). It becomes the
## profile's name too, so the player has one name everywhere. The first claim tells the server the
## age band; an under-13 player's name stays unfindable until a grown-up's consent (server hooks).
func claim_username(username: String) -> String:
	var name := UsernameRules.normalize(username)
	var code := UsernameRules.validate(name)
	if code != "":
		return OnlineRules.message(code)
	var s := session
	var r: Dictionary = await backend.call_rpc("claim_username", {"username": name, "age_band": String(_band())})
	if s != session:
		return OnlineRules.message("not_signed_in")   # owner #99: another player plays now
	if not r.get("ok", false):
		return OnlineRules.message(str(r.get("error", "")))
	if r.has("age_band") or r.has("claimed"):
		account = OnlineRules.account(r, profile.age_band)   # the server answers with the account
		_f_gold_read_at = -1   # the gold-double bug: sync_wallet reads the wallet itself
	var claimed_name: Variant = r.get("username", name)
	account.username = claimed_name if claimed_name is String and claimed_name != "" else name
	account.claimed = true
	if profile.username != account.username:
		profile.username = account.username
		save_profile.call()
	_pw_note_name()   # owner #105: this player has an online name here now
	account_changed.emit()
	await _f_claimed()   # M4 F: the first backup
	return ""


# --- Consent and parent settings (§17.2) ---

## Starts verifiable parental consent: {"text": "" or plain words, "url": the provider's page for
## the grown-up ("" for the fake provider)}.
func start_consent() -> Dictionary:
	var r: Dictionary = await backend.call_rpc("consent_start", {"age_band": String(_band())})
	if not r.get("ok", false):
		return {"text": OnlineRules.message(str(r.get("error", ""))), "url": ""}
	_take_consent(r, OnlineRules.CONSENT_PENDING)
	return {"text": "", "url": consent_url(r)}


## Asks whether the grown-up has finished; the account is read again once verified.
func check_consent() -> String:
	var r: Dictionary = await backend.call_rpc("consent_status", {})
	if not r.get("ok", false):
		return OnlineRules.message(str(r.get("error", "")))
	_take_consent(r, str(account.get("consent", OnlineRules.CONSENT_NONE)))
	if account.consent == OnlineRules.CONSENT_VERIFIED:
		return await refresh_account()
	return ""


## The provider's page from a consent_start answer: only an https address, else "".
static func consent_url(reply: Dictionary) -> String:
	var url: Variant = reply.get("url", "")
	return url if url is String and url.begins_with("https://") and url.length() < 2048 else ""


## Online play on/off and the chat setting (a grown-up, behind ParentGate).
func set_parent_settings(online_allowed: bool, chat: String) -> String:
	var r: Dictionary = await backend.call_rpc("set_parent_settings", {"online_allowed": online_allowed, "chat": chat})
	if not r.get("ok", false):
		return OnlineRules.message(str(r.get("error", "")))
	return await refresh_account()


func _take_consent(reply: Dictionary, fallback: String) -> void:
	var c := str(reply.get("consent", fallback))
	account.consent = c if c in [OnlineRules.CONSENT_NONE, OnlineRules.CONSENT_PENDING, OnlineRules.CONSENT_VERIFIED] else fallback
	account_changed.emit()


# --- Friends (Nakama's friends API) ---

func refresh_friends() -> String:
	if not social_allowed():
		_set_friends([])
		return OnlineRules.message("consent_needed" if status == ONLINE else "not_signed_in")
	var r: Dictionary = await backend.list_friends()
	if not r.get("ok", false):
		return OnlineRules.message(str(r.get("error", "")))
	var list: Array[Dictionary] = []
	_blocked.clear()
	var ids: Array[String] = []
	for f: Variant in r.get("friends", []):
		if not (f is Dictionary):
			continue
		var state := OnlineRules.friend_state(int(f.get("state", -1)))
		var id := str(f.get("id", ""))
		if state == OnlineRules.BLOCKED:
			_blocked.append(id)
		elif state != &"" and id != "":
			list.append({"id": id, "username": str(f.get("username", "")), "state": state, "online": bool(f.get("online", false))})
			ids.append(id)
	_set_friends(list)
	backend.follow(ids)
	return ""


## A friend request by exact username (§17.3).
func add_friend(typed: String) -> String:
	if not social_allowed():
		return OnlineRules.message("consent_needed")
	var code := OnlineRules.check_friend_name(typed, profile.username)
	if code != "":
		return OnlineRules.message(code)
	return await _friend_call(backend.add_friend_by_name.bind(typed.strip_edges()))


func accept(id: String) -> String:
	return await _friend_call(backend.add_friend_by_id.bind(id))


func decline(id: String) -> String:
	return await _friend_call(backend.remove_friend.bind(id))


## Block removes and blocks (§5.13): gone from the list, can't ask again, no invites.
func block(id: String) -> String:
	return await _friend_call(backend.block.bind(id))


func mute(id: String) -> void:
	if prefs.mute(id):
		prefs.save_to(prefs_path)
	_drop_messages_from(id)   # M4 E: what they said goes too
	friends_changed.emit()


func unmute(id: String) -> void:
	prefs.unmute(id)
	prefs.save_to(prefs_path)
	friends_changed.emit()


func is_muted(id: String) -> bool:
	return prefs.is_muted(id)


## Reports a player for a person to review in the Nakama console (§5.14); they are muted here too.
func report(id: String, reason: String) -> String:
	var r: Dictionary = await backend.call_rpc("report_user",
		{"user_id": id, "reason": reason if REPORT_REASONS.has(reason) else REPORT_OTHER})
	if not r.get("ok", false):
		return OnlineRules.message(str(r.get("error", "")))
	mute(id)
	return ""


func _friend_call(call: Callable) -> String:
	if not social_allowed():
		return OnlineRules.message("consent_needed")
	var r: Dictionary = await call.call()
	if not r.get("ok", false):
		return OnlineRules.message(str(r.get("error", "")))
	return await refresh_friends()


func _set_friends(list: Array[Dictionary]) -> void:
	list.sort_custom(_friend_before)
	friends = list
	friends_changed.emit()


## Requests first, then friends online, friends away, and requests this player sent; by name.
static func _friend_before(a: Dictionary, b: Dictionary) -> bool:
	var ra := _rank(a)
	var rb := _rank(b)
	if ra != rb:
		return ra < rb
	return str(a.username).to_lower() < str(b.username).to_lower()


static func _rank(f: Dictionary) -> int:
	match f.state:
		OnlineRules.RECEIVED:
			return 0
		OnlineRules.FRIEND:
			return 1 if f.online else 2
	return 3


func friends_online() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for f in friends:
		if f.state == OnlineRules.FRIEND and f.online:
			out.append(f)
	return out


# --- Invites (§17.3) ---

## The host invites a friend into its relayed match (the server checks friendship, consent, the
## 4-player cap, and lets only invited players join).
func invite(friend_id: String, match_id: String, world_name: String) -> String:
	if not social_allowed():
		return OnlineRules.message("consent_needed")
	var username := ""
	for f in friends:
		if f.id == friend_id:
			username = f.username
	var r: Dictionary = await backend.call_rpc("invite_friend",
		{"user_id": friend_id, "username": username, "match_id": match_id, "world_name": world_name})
	if not r.get("ok", false):
		return OnlineRules.message(str(r.get("error", "")))
	return ""


## The host takes a player out of its relayed match and off its invite list (spec §17.3); their game is told.
## "" or plain words.
func remove_guest(user_id: String, match_id: String) -> String:
	var r: Dictionary = await backend.call_rpc("remove_guest", {"user_id": user_id, "match_id": match_id})
	if not r.get("ok", false):
		return OnlineRules.message(str(r.get("error", "")))
	return ""


## Invites still open, newest first.
func pending_invites() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for m: String in _invites.keys():
		if _now() - int(_invites[m].at) > INVITE_SECONDS or _now() < int(_invites[m].at):
			_invites.erase(m)
		else:
			out.append(_invites[m])
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a.at) > int(b.at))
	return out


## The open invite from this friend, or {}.
func invite_from(user_id: String) -> Dictionary:
	for inv in pending_invites():
		if inv.from_id == user_id:
			return inv
	return {}


func forget_invite(match_id: String) -> void:
	_invites.erase(match_id)


# --- From the backend ---

func _watch_backend() -> void:
	if _connected_backend == backend:
		return
	_connected_backend = backend
	backend.notified.connect(_on_notified)
	backend.presence_changed.connect(_on_presence)
	backend.closed.connect(_went_offline)
	backend.chat_message.connect(_on_chat_message)   # M4 E


func _on_notified(code: int, content: String, sender_id: String) -> void:
	match code:
		OnlineRules.INVITE:
			var inv := OnlineRules.parse_invite(content, sender_id)
			if inv.is_empty() or not social_allowed() or is_muted(sender_id) or _blocked.has(sender_id):
				return
			inv.at = _now()
			_invites[inv.match_id] = inv
			invite_received.emit(inv)
		OnlineRules.INVITE_CANCELLED:
			var match_id := OnlineRules.cancelled_match(content)
			if _invites.has(match_id):
				_invites.erase(match_id)
				invite_cancelled.emit(match_id)
		OnlineRules.PARENT_APPROVED:
			refresh_account()
		OnlineRules.REMOVED:
			var removed := OnlineRules.cancelled_match(content)   # the same {"match_id"} shape
			if removed != "":
				removed_from_world.emit(removed)
		OnlineRules.FRIEND_REQUEST, OnlineRules.FRIEND_ACCEPTED:
			if social_allowed():
				refresh_friends()


func _on_presence(user_id: String, online: bool) -> void:
	for f in friends:
		if f.id == user_id and f.online != online:
			f.online = online
			friends.sort_custom(_friend_before)
			friends_changed.emit()
			return


func _went_offline() -> void:
	friends.clear()
	_invites.clear()
	chats.clear()   # M4 E: the server closed every channel
	_set_status(OFFLINE)


func _set_status(s: StringName) -> void:
	if status == s:
		return
	status = s
	status_changed.emit(s)


func _band() -> StringName:
	var b: StringName = account.get("age_band", &"")
	if AgeBand.is_valid(b):
		return b
	return AgeBand.effective(profile.age_band)


func _now() -> int:
	return int(clock.call()) if clock.is_valid() else int(Time.get_unix_time_from_system())


# --- M4 E: chat (friends' DMs and the team room of an online match; spec §5.13, §17.4) ---
# Channels on the server (Nakama chat): a DM with a friend, and the room named after the relayed
# match (the server lets only its players in). The server's hooks check every message at the
# channel's strictest level; this side only offers what the child may send (OnlineChatRules), reads
# every message carefully, hides muted players and keeps a 13+ player's DMs for 30 days.

## A message for this player (OnlineChatRules.parse: {id, channel_id, from_id, from, text, emote, mine,
## time}); muted and blocked players' never come.
signal chat_message(msg: Dictionary)

const CHAT_DM := &"dm"
const CHAT_TEAM := &"team"
const KEEP_MESSAGES := 100          # per open chat on this device

## Open chats: channel id -> {"kind": CHAT_DM or CHAT_TEAM, "target": friend id or match id, "messages": [...]}.
var chats := {}
var _chat_limiter := ChatRules.RateLimiter.new()


## This player's chat level now (OnlineChatRules.chat_level); off while not signed in.
func chat_level() -> String:
	return OnlineChatRules.chat_level(account) if status == ONLINE else OnlineRules.CHAT_OFF


## A keyboard only for 13+ with text chat; everyone else has the quick-chat wheel.
func can_type() -> bool:
	return status == ONLINE and OnlineChatRules.can_type(account)


## Opens a DM with a friend: {"channel_id"} or {"error": plain words}. A 13+ player's DM brings back
## the last 30 days (the server keeps nothing with an under-13 player in it).
func open_dm(friend_id: String) -> Dictionary:
	var why := _chat_refusal()
	if why != "":
		return {"error": why}
	var is_friend := false
	for f in friends:
		if f.id == friend_id and f.state == OnlineRules.FRIEND:
			is_friend = true
	if not is_friend:
		return {"error": OnlineChatRules.message("not_friends")}
	var keep := OnlineChatRules.keeps_history(_band())
	var r: Dictionary = await backend.join_chat(friend_id, OnlineChatRules.TYPE_DM, keep)
	if not r.get("ok", false):
		var code := _chat_code(r)
		return {"error": OnlineChatRules.message("friend_chat_off" if code == "chat_off" else code)}
	var id := str(r.get("channel_id", ""))
	chats[id] = {"kind": CHAT_DM, "target": friend_id, "messages": [] as Array[Dictionary]}
	if keep:
		await _load_history(id)
	return {"channel_id": id}


## Joins the team room of the online match this game plays in: {"channel_id"} or {"error"}.
func open_team(match_id: String) -> Dictionary:
	var why := _chat_refusal()
	if why != "":
		return {"error": why}
	var room := OnlineChatRules.team_room(match_id)
	if room == "":
		return {"error": OnlineChatRules.message("room_not_allowed")}
	var r: Dictionary = await backend.join_chat(room, OnlineChatRules.TYPE_ROOM, false)   # team rooms keep nothing
	if not r.get("ok", false):
		return {"error": OnlineChatRules.message(_chat_code(r))}
	var id := str(r.get("channel_id", ""))
	chats[id] = {"kind": CHAT_TEAM, "target": room, "messages": [] as Array[Dictionary]}
	return {"channel_id": id}


## The open team room ("" when none).
func team_channel() -> String:
	for id: String in chats:
		if chats[id].kind == CHAT_TEAM:
			return id
	return ""


func close_chat(channel_id: String) -> void:
	if not chats.has(channel_id):
		return
	chats.erase(channel_id)
	if backend and backend.is_signed_in():
		backend.leave_chat(channel_id)


## The messages of an open chat, oldest first.
func messages(channel_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if chats.has(channel_id):
		out.assign(chats[channel_id].messages)
	return out


## Free text (13+ with text chat); "" or plain words.
func send_text(channel_id: String, text: String) -> String:
	var check := OnlineChatRules.check_send(text, chat_level())
	if check.has("error"):
		return OnlineChatRules.message(check.error)
	return await _send(channel_id, check.content)


## A quick-chat phrase (the wheel; everyone).
func send_phrase(channel_id: String, phrase: String) -> String:
	if not ChatRules.is_quick_phrase(phrase):
		return OnlineChatRules.message("quick_chat_only")
	return await send_text(channel_id, phrase)


func send_emote(channel_id: String, emote: StringName) -> String:
	if chat_level() == OnlineRules.CHAT_OFF:
		return OnlineChatRules.message("chat_off")
	var content := OnlineChatRules.emote_content(emote)
	if content.is_empty():
		return OnlineChatRules.message("bad_message")
	return await _send(channel_id, content)


## Whether a message offers MUTE and REPORT: someone else's.
func can_report(msg: Dictionary) -> bool:
	return str(msg.get("from_id", "")) != "" and not msg.get("mine", false)


## Mutes whoever sent this message (on this device): their messages go, and no more come.
func mute_sender(msg: Dictionary) -> void:
	if can_report(msg):
		mute(str(msg.from_id))


## Reports the player who sent this message, naming the message for the person who reviews it
## (report_user: user_id, reason, channel_id, message_id); they are muted here too.
func report_message(msg: Dictionary, reason: String) -> String:
	if str(msg.get("from_id", "")) == "":
		return OnlineChatRules.message("bad_message")
	if msg.get("mine", false):
		return OnlineRules.message("self")
	var r: Dictionary = await backend.call_rpc("report_user", {"user_id": msg.from_id,
		"reason": reason if REPORT_REASONS.has(reason) else REPORT_OTHER,
		"channel_id": str(msg.get("channel_id", "")), "message_id": str(msg.get("id", "")),
		"message": shown_message(msg)})   # M4 G: the server keeps it if it has no copy of its own
	if not r.get("ok", false):
		return OnlineRules.message(str(r.get("error", "")))
	mute(str(msg.from_id))
	return ""


func _chat_refusal() -> String:
	if status != ONLINE or backend == null:
		return OnlineChatRules.message("not_signed_in")
	if not social_allowed():
		return OnlineRules.message("consent_needed")
	if chat_level() == OnlineRules.CHAT_OFF:
		return OnlineChatRules.message("chat_off")
	return ""


func _send(channel_id: String, content: Dictionary) -> String:
	if not chats.has(channel_id):
		return OnlineChatRules.message("not_in_channel")
	if not _chat_limiter.allow(0, float(_now())):
		return OnlineChatRules.message("too_fast")
	var r: Dictionary = await backend.send_chat(channel_id, content)
	return "" if r.get("ok", false) else OnlineChatRules.message(_chat_code(r))


## The server's refusal as a chat code (Nakama gives the hook's code as the error's message).
static func _chat_code(reply: Dictionary) -> String:
	var e := str(reply.get("error", "")).strip_edges().to_lower()
	for code: String in ["quick_chat_only", "personal_info", "blocked_word", "empty", "chat_off", "not_friends",
			"room_not_allowed", "not_in_channel", "bad_message", "not_available"]:
		if e == code or e.ends_with(": " + code):
			return code
	return e


func _load_history(channel_id: String) -> void:
	var r: Dictionary = await backend.chat_history(channel_id, OnlineChatRules.HISTORY_COUNT)
	if not r.get("ok", false) or not chats.has(channel_id):
		return
	var list: Array[Dictionary] = []
	var raw: Array = r.get("messages", [])
	for i in range(raw.size() - 1, -1, -1):   # newest first from the server: oldest first here
		if raw[i] is Dictionary:
			var msg := _readable(raw[i])
			if not msg.is_empty():
				list.append(msg)
	var kept: Array[Dictionary] = OnlineChatRules.recent(list, _now())
	chats[channel_id].messages = kept.slice(maxi(kept.size() - KEEP_MESSAGES, 0))


## A message this player may see, or {}: readable, from someone not muted or blocked.
func _readable(raw: Dictionary) -> Dictionary:
	var msg := OnlineChatRules.parse(raw, backend.user_id() if backend else "", _band())
	if msg.is_empty() or (not msg.mine and (is_muted(msg.from_id) or _blocked.has(msg.from_id))):
		return {}
	# Nakama's socket keeps the random name it gave until the next sign-in: a name claimed in this
	# session comes from the account (mine) or the friends list.
	var known := str(account.get("username", "")) if msg.mine else ""
	for f in friends:
		if not msg.mine and f.id == msg.from_id:
			known = str(f.username)
	if known != "" and UsernameRules.validate(known) == "":
		msg.from = known
	return msg


func _on_chat_message(raw: Dictionary) -> void:
	var msg := _readable(raw)
	if msg.is_empty() or not chats.has(msg.channel_id):
		return
	var list: Array = chats[msg.channel_id].messages
	list.append(msg)
	while list.size() > KEEP_MESSAGES:
		list.pop_front()
	chat_message.emit(msg)


func _drop_messages_from(user_id: String) -> void:
	for id: String in chats:
		var list: Array = chats[id].messages
		for m: Dictionary in list.duplicate():
			if m.from_id == user_id and not m.mine:
				list.erase(m)

# --- M4 Wave 2, agent F: the profile backup, the economy online, parent controls, age signals ---
# ProfileSync (a child) backs the profile up to the server (spec §7.4, §17.1). When signed in, codes
# are redeemed by the server and codes used offline are recorded there at sign-in (§17.6). Survivor
# gold: an online host reports every player's changes to the server's wallet ledger (report_gold,
# batched per player: WalletReport; OnlineWallets reads a guest's starting gold, gold_of), and the
# phone's own gold is reconciled with the ledger when signed in (sync_wallet: WalletSync, never
# backwards for the child). The Gold Farm's clock is farm_start / farm_peek / farm_collect (for M3
# Task 10). A grown-up approves an under-13 player's friends (approve_friend). The store's age signal
# only makes the band stricter.

## A grown-up said yes to a friend (notification 103 {"what": "friend"}).
signal friend_approved(user_id: String)

## Gold reasons wallet_award knows (server WalletRules.REASONS); anything else is "other".
const WALLET_REASON := "other"
## The gold-double bug: reads of the server's wallet a sync makes while payments keep crossing them, before it leaves
## the sync to the next change or sign-in.
const WALLET_READ_TRIES := 4
## The gold-double bug's leftover (module 0.2.19): how long a guest's sync after an online world waits for the server
## to hear the host's last batch for it (the host sends it at once when the guest leaves; its 5 s batch, the network),
## and how often it looks again. Past it, the host's game never told the server: the server's word stands.
const HOST_WAIT_MSEC := 15_000
const HOST_POLL_SEC := 0.5

var profile_sync: ProfileSync
var age_signals: AgeSignals          # default: AgeSignals.for_platform() (a no-op off Android)
var msec_clock := Callable()         # () -> int msec; default Time.get_ticks_msec
var wallet_path := ""                # this device's wallet markers; "" = beside prefs_path
var wallet_reported := 0             # gold the server credited from this game's reports
var in_online_world := Callable()    # owner #67: () -> bool; default Session.is_online() (_f_in_online_world)
var _f_reports := {}                 # user id ("" = this player) -> WalletReport
var _f_report_match := {}            # user id -> the match it was reported from (a guest's)
var _f_sending := false
var _f_syncing := false
var _f_sync_again := false
# The gold-double bug (2026-10-01, docs/devlog/parts/gold-double.md): gold the server pays and then this phone (a code,
# a farm collected) must never be on its way while a wallet sync reads the server's wallet. When the server read the
# wallet before it paid but the payment reached the phone first, the sync took that gold for the phone's own and sent
# it again (2000 for a 1000 code); in the other order the phone got it twice, or lost it until the next sync.
var _f_paying := 0           # such calls on their way (sync_wallet waits for them before it reads the wallet)
var _f_moves := 0            # gold moves the server has (or its host reports) that reached this phone: a count...
var _f_moved_gold := 0       # ...and their sum
var _f_gold_read_at := -1    # _f_moves when account.gold was read with no paying call on its way; -1: read it again
# The gold-double bug's leftovers (module 0.2.19): a guest's game after an online world waits for the server to have
# heard the host's last count for it: {"match": id, "seq": n, "since": msec it started waiting, or -1}; {} none.
var _f_host_wait := {}
var _f_send_again := false   # a batch came while send_wallet_report ran (a guest's, flushed on its leave): again

## No call that pays gold on the server and then on this phone is on its way any more.
signal _f_all_paid
## send_wallet_report finished (nothing of it on its way any more).
signal _f_reports_sent


func _f_ready() -> void:
	if profile_sync == null:
		profile_sync = ProfileSync.new()
		profile_sync.name = "ProfileSync"
	profile_sync.service = self
	if profile_sync.get_parent() == null:
		add_child(profile_sync)
	if age_signals == null:
		age_signals = AgeSignals.for_platform()
	age_signals.answered.connect(_f_on_age_signal)
	age_signals.request()
	profile_sync.uploaded.connect(sync_wallet)   # changes while signed in (the menu's shop, a solo world)
	if profile == Profile.data:   # the game's own service (tests give their own profile)
		Profile.saved.connect(profile_sync.mark_changed)
		Session.own_gold_moved_online.connect(_f_on_own_gold_moved_online)
		Session.hosted_gold_seq.connect(_f_on_host_seq)   # module 0.2.19: the host's count with each move


## After signing in: the backup, codes used offline, and approvals' notifications.
func _f_signed_in() -> void:
	if not backend.notified.is_connected(_f_on_notified):
		backend.notified.connect(_f_on_notified)
	profile_sync.forget_server_copy()   # owner #67: maybe another account than before
	_o67_take_account_name()
	await profile_sync.sync()
	await record_offline_codes()
	await sync_wallet(false)


## The first claim makes the account restorable: its first backup goes up now.
func _f_claimed() -> void:
	await profile_sync.sync()


func _process(_delta: float) -> void:
	_mv_prune()   # owner #99: asks whose code is over leave the card
	for uid: String in _f_reports:
		if (_f_reports[uid] as WalletReport).due(_msec()):
			send_wallet_report()
			return


## The store's age signal (§17.2) only ever makes the phone's band stricter: under-13 stays under-13,
## and a store that says under 13 makes it so (the first username claim then tells the server).
func _f_on_age_signal(band: StringName) -> void:
	var stricter := AgeSignalsRules.stricter(profile.age_band, band)
	if AgeBand.is_valid(profile.age_band) and stricter != profile.age_band:
		profile.age_band = stricter
		save_profile.call()
		if status == ONLINE and backend != null:
			await refresh_account()   # M4 Task 10 review: a claimed account hears it now, not at the next sign-in


func _f_on_notified(code: int, content: String, _sender_id: String) -> void:
	if code != OnlineRules.PARENT_APPROVED:
		return
	var json := JSON.new()
	if json.parse(content) != OK or typeof(json.data) != TYPE_DICTIONARY or (json.data as Dictionary).get("what") != "friend":
		return
	var id: Variant = (json.data as Dictionary).get("user_id", "")
	if social_allowed():
		await refresh_friends()
	friend_approved.emit(str(id))


# --- Codes (§5.11, §17.6) ---

## Redeems a code: by the server when signed in (once per account; codes the server adds work
## without an app update), else on the phone (CodeRules: once per profile). Answers like
## CodeRules.redeem: {"status", "reward", "wait", "message"}; the reward is given to the profile
## (the caller saves it). A network failure falls back to the phone's own check.
## The gold-double bug's leftover (module 0.2.19): with no answer the phone pays by its own check, and that gold waits
## in profile.codes_unsettled for the server's word (it may have paid the code before its answer was lost): the next
## sync or sign-in asks first (_f_settle_codes, record_offline_codes), and asking again answers "already used, the
## server paid N gold": the phone then never reports that gold as its own.
func redeem_code(code: String, tries: CodeTries, now_msec: int, rewards: Dictionary = CodeRules.REWARDS) -> Dictionary:
	var norm := CodeRules.normalize(code)
	if status != ONLINE or norm == "" or tries.is_locked(now_msec):
		return CodeRules.redeem(profile, code, tries, now_msec, rewards)
	_f_paying += 1   # the gold-double bug: no wallet sync reads the server until the code's gold is on the phone
	var r: Dictionary = await backend.call_rpc("redeem_code", {"code": norm})
	var result := _f_code_answer(r, code, norm, tries, now_msec, rewards)
	_f_paid()   # the code's gold (the server's, or the phone's own with no answer) is on the phone now
	return result


func _f_code_answer(r: Dictionary, code: String, norm: String, tries: CodeTries, now_msec: int,
		rewards: Dictionary) -> Dictionary:
	var result := {"status": CodeRules.UNKNOWN, "reward": {}, "wait": 0}
	var h := CodeRules.hash_code(norm)
	if r.get("ok", false):
		var reward := server_reward(r.get("reward"))
		if profile.codes_redeemed.has(h):
			result.status = CodeRules.ALREADY_USED   # paid on this phone before (offline, or an answer that was lost)
			_f_code_settled(h, int(reward.amount) if reward.get("kind") == CodeRules.KIND_GOLD else 0)   # the server's now
		elif not reward.is_empty() and CodeRules.give(profile, reward):
			if profile.codes_redeemed.size() < CodeRules.MAX_REDEEMED:
				profile.codes_redeemed.append(h)
			if reward.kind == CodeRules.KIND_GOLD:   # the server paid it into its ledger too
				_f_move_marker(int(reward.amount))
			tries.record_right()
			result.status = CodeRules.ACCEPTED
			result.reward = reward
	else:
		var err := str(r.get("error", ""))
		match err:
			"already_used":
				result.status = CodeRules.ALREADY_USED
				_f_code_settled(h, _f_paid_gold(r.get("paid")))   # 0.2.19: "paid" when the server paid it itself
				if not profile.codes_redeemed.has(h) and profile.codes_redeemed.size() < CodeRules.MAX_REDEEMED:
					profile.codes_redeemed.append(h)   # used on this account (another device): the phone's check knows
					save_profile.call()
			"locked":
				result.status = CodeRules.LOCKED
				result.wait = clampi(int(r.get("wait", 30)), 1, 3600)
			"empty":
				result.status = CodeRules.EMPTY
			"unknown":
				tries.record_wrong(now_msec)   # the phone's lock follows the server's
			"network", "not_signed_in", "not_yet", "server_error", "busy":
				return CodeRules.redeem(profile, code, tries, now_msec, rewards)   # its gold: codes_unsettled
	result.message = CodeRules.message(result)
	return result


## The server's word on a gold code this phone paid by its own check (profile.codes_unsettled): it paid `gold` itself
## (a lost answer, another device: the code is the account's once, so that gold on the phone is the server's and the
## marker moves with it), or 0: it did not (the phone's own gold; the sync reports it, as for any code used offline).
func _f_code_settled(h: String, gold: int) -> void:
	if not profile.codes_unsettled.has(h):
		return
	profile.codes_unsettled.erase(h)
	if gold > 0:
		_f_move_marker(gold)
	save_profile.call()


## The gold of a module 0.2.19 "paid" ({"gold", "at_ms"} or a record's {"hash", "gold", "at_ms"}); 0 when none.
static func _f_paid_gold(paid: Variant) -> int:
	if paid is Dictionary:
		var gold: Variant = (paid as Dictionary).get("gold")
		if typeof(gold) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(gold)) and float(gold) > 0.0 and float(gold) <= 1_000_000.0:
			return int(gold)
	return 0


## A reward from the server as CodeRules gives it: {"kind": gold, "amount": int} or a cosmetic; {} if odd.
static func server_reward(reward: Variant) -> Dictionary:
	if not (reward is Dictionary):
		return {}
	var kind := StringName(str(reward.get("kind", "")))
	if kind == CodeRules.KIND_GOLD:
		var amount: Variant = reward.get("amount")
		if typeof(amount) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(amount)) and float(amount) >= 1.0 \
				and float(amount) <= 1_000_000.0:
			return {"kind": CodeRules.KIND_GOLD, "amount": int(amount)}
	elif kind == CodeRules.KIND_COSMETIC and reward.get("item") is String:
		return {"kind": CodeRules.KIND_COSMETIC, "item": reward.item}
	return {}


## Codes this phone used (maybe offline) are recorded on the server, so they can't pay twice there.
## Module 0.2.19: the answer says which the server had paid itself (codes_unsettled settles: _f_code_settled).
func record_offline_codes() -> String:
	if status != ONLINE or profile.codes_redeemed.is_empty():
		return ""
	return await _f_record_codes(profile.codes_redeemed.duplicate())


## The gold-double bug's leftover: before a sync reads the wallet, the server's word on the gold codes this phone paid
## itself (else the sync would report that gold as the phone's own while the server may hold it already). "" or words.
func _f_settle_codes() -> String:
	if status != ONLINE or profile.codes_unsettled.is_empty():
		return ""
	return await _f_record_codes(profile.codes_unsettled.keys())


func _f_record_codes(hashes: Array) -> String:
	while not hashes.is_empty():
		var chunk := hashes.slice(0, CodeRules.RECORD_CHUNK)
		hashes = hashes.slice(CodeRules.RECORD_CHUNK)
		var r: Dictionary = await backend.call_rpc("redeem_code", {"hashes": chunk})
		if not r.get("ok", false):
			return OnlineRules.message(str(r.get("error", "")))
		var paid := {}   # an older server says nothing: every code is the phone's own, as before
		if r.get("paid") is Array:
			for e: Variant in r.paid:
				if e is Dictionary:
					paid[str((e as Dictionary).get("hash", ""))] = _f_paid_gold(e)
		for h: Variant in chunk:
			_f_code_settled(str(h), int(paid.get(str(h), 0)))
	return ""


# --- Survivor gold and the server's wallet ledger (§17.1, §17.6, §6) ---

## The host reports a player's Survivor gold change (+ earned, − spent) to the server's ledger:
## `user_id` "" is this player, else a guest in the match `match_id` this game hosts. Batched per player.
func report_gold(amount: int, user_id: String = "", match_id: String = "") -> void:
	if status != ONLINE or amount == 0:
		return
	if not _f_reports.has(user_id):
		_f_reports[user_id] = WalletReport.new()
	(_f_reports[user_id] as WalletReport).add(amount, _msec())
	if user_id != "":
		_f_report_match[user_id] = match_id


## Gold waiting to be reported (all players; tests).
func pending_reports() -> int:
	var n := 0
	for uid: String in _f_reports:
		n += (_f_reports[uid] as WalletReport).pending
	return n


## The gold-double bug's leftover (module 0.2.19): the count of the gold moves reported for a player so far (its
## WalletReport.seq; 0 none). An online host tells a guest's game each move with this count (Session._store_gold).
func report_seq(user_id: String) -> int:
	return (_f_reports[user_id] as WalletReport).seq if _f_reports.has(user_id) else 0


## Sends every player's batch now (_process sends them when due; Session when a guest leaves or the host closes its
## world). A call while one runs sends again right after it.
func send_wallet_report() -> void:
	if status != ONLINE:
		return
	if _f_sending:
		_f_send_again = true
		return
	_f_sending = true
	var again := true
	while again and status == ONLINE:
		_f_send_again = false
		await _f_send_reports()
		again = _f_send_again
	_f_sending = false
	_f_reports_sent.emit()


## Module 0.2.19: a guest's batch carries the host's count of its moves on its last piece ("seq"; a batch that netted
## to nothing goes as a piece of 0 with the count): the server keeps it, and takes the batch even after the guest
## left. A piece the network lost goes again with the rest of its batch and the count; a refused one is dropped.
func _f_send_reports() -> void:
	var universe := clampi(profile.universe_unlocked, 1, WalletReport.MAX_UNIVERSE)
	for uid: String in _f_reports.keys():
		var report: WalletReport = _f_reports[uid]
		var seq := report.seq
		var pieces := report.take(universe)
		if uid != "" and pieces.is_empty() and seq > report.sent_seq:
			pieces.append(0)
		var lost := false
		for i in pieces.size():
			var payload := {"amount": pieces[i], "reason": WALLET_REASON, "universe": universe}
			if uid != "":
				payload.merge({"user_id": uid, "match_id": _f_report_match.get(uid, "")})
				if i == pieces.size() - 1:
					payload.seq = seq   # the last piece: the server has heard every move up to it
			var r: Dictionary = await backend.call_rpc("wallet_award", payload)
			if r.get("ok", false):
				wallet_reported += int(r.get("credited", 0))
			elif str(r.get("error", "")) in ["network", "not_signed_in", "server_error", "busy"]:
				var rest := 0
				for j in range(i, pieces.size()):
					rest += pieces[j]
				report.give_back(rest, _msec())   # tried again with the next batch, with the count
				lost = true
				break
			# too_much / limit / not_enough_gold / not_host: the server's rules say no
		if not lost:
			report.sent_seq = maxi(report.sent_seq, seq)


## The M4 Task 10 review B (module 0.2.11): the players in the relayed match this game hosts, as the server knows
## them: {"ok", "players": [{"user_id", "username", "age_band", "chat_level"}]} or {"ok": false, "error"}
## (MatchRoster reads it carefully).
func match_players(match_id: String) -> Dictionary:
	if status != ONLINE:
		return {"ok": false, "error": "not_signed_in"}
	return await backend.call_rpc("match_players", {"match_id": match_id})


## A player's Survivor gold on the server: this player's, or a guest's in the match this game hosts.
## {"ok", "gold"} or {"ok": false, "error"}.
func gold_of(user_id: String, match_id: String) -> Dictionary:
	if status != ONLINE:
		return {"ok": false, "error": "not_signed_in"}
	return await backend.call_rpc("get_gold_of", {"user_id": user_id, "match_id": match_id})


## Brings the server's ledger up to date with what changed on this phone off its watch (solo play,
## LAN, codes used offline, the menu's shop), from this device's marker (WalletSync). A first sync
## sends only what the server lacks, and a server with more gives it to the phone: the child's gold
## never goes backwards (§6). `fresh`: read the server's gold again first. "" or plain words.
func sync_wallet(fresh: bool = true) -> String:
	if status != ONLINE or not claimed():
		return ""
	if _f_in_online_world():
		return ""   # owner #67: the host reports every change there, batched: the server is seconds behind the phone
	if _f_syncing:
		_f_sync_again = true   # a change came while one ran: once more after it
		return ""
	_f_syncing = true
	var s := session
	var err := await _f_read_wallet(fresh)
	if s != session:
		_f_syncing = false
		return ""   # owner #99: another player plays now: nothing of this sync lands in their files
	if err == "" and not _f_host_reported():   # module 0.2.19: a guest back from an online world
		_f_sync_after_host()   # in the background: a sign-in or an invite's welcome never waits for the host
		return ""
	return await _f_sync_read(err)


## Module 0.2.19: a guest's sync after an online world finishes once the server has the host's last count for it (a
## read every HOST_POLL_SEC; _f_host_reported says when to stop waiting).
func _f_sync_after_host() -> void:
	var err := ""
	while err == "" and not _f_host_reported():
		await _f_pause(HOST_POLL_SEC)
		if _f_in_online_world() or status != ONLINE:
			_f_syncing = false
			return   # playing online again: the host reports; or signed out: the sign-in syncs
		err = await _f_read_wallet(true)
	await _f_sync_read(err)


## The rest of sync_wallet, with the wallet read (`err` its outcome).
func _f_sync_read(err: String) -> String:
	if err == "busy":   # payments kept crossing every read: the next change or sign-in syncs
		_f_syncing = false
		return ""
	var server_gold := int(account.get("gold", -1))
	var uid := backend.user_id()
	if err != "" or server_gold < 0 or uid == "":
		_f_syncing = false
		return err   # an older server without a wallet in its answer: nothing to reconcile
	var marker := WalletSync.marker_of(_f_wallet_path(), uid)
	if _adopt_server_gold and marker < 0:
		_adopt_server_gold = false   # a fresh player from LOG IN: the account's gold, nothing reported
		WalletSync.set_marker(_f_wallet_path(), uid, server_gold)
		marker = server_gold
		if profile.survivor_gold != server_gold:
			profile.survivor_gold = server_gold
			save_profile.call()
	var phone := profile.survivor_gold
	var moved_before := _f_moved_gold
	var planned := WalletSync.plan(phone, marker, server_gold)
	var s := session
	var credited := await _f_report_now(int(planned.report))
	if s != session:
		_f_syncing = false
		return ""   # owner #99: another player plays now: the marker and the gold are theirs to keep
	var out := WalletSync.settle(phone, marker, server_gold, planned, credited)
	# A code or a farm paid meanwhile, or an online world, moved the gold: keep those moves (counted here, not by the
	# marker file: a first sync has none to move).
	var moved := _f_moved_gold - moved_before
	WalletSync.set_marker(_f_wallet_path(), uid, int(out.marker) + moved)
	account.gold = int(out.marker) + moved   # owner #67: the server's balance now (a later sync(false) must not see the old)
	_f_gold_read_at = _f_moves if _f_paying == 0 else -1
	if int(out.phone) != phone:
		profile.survivor_gold += int(out.phone) - phone
		save_profile.call()
		if profile == Profile.data:
			Session.gold_changed.emit(profile.survivor_gold)   # owner #67: the gold counter shows it arriving
	_f_syncing = false
	if _f_sync_again:
		_f_sync_again = false
		return await sync_wallet()
	return ""


## The gold-double bug: the server's wallet into account.gold, read while no payment is on its way to this phone and
## none started or arrived during the read (else read again). `fresh` false: the account's gold as last read is kept
## when nothing moved since. "" or plain words; "busy" after WALLET_READ_TRIES crossed reads.
## The gold-double bug's leftovers (module 0.2.19): first the server's word on gold codes this phone paid itself
## (_f_settle_codes), and this game's own last batch from an online world it hosted (_f_flush_own_report).
func _f_read_wallet(fresh: bool) -> String:
	for i in WALLET_READ_TRIES:
		while _f_paying > 0:
			await _f_all_paid   # its gold reaches the phone first
		var err := await _f_settle_codes()
		if err == "":
			err = await _f_flush_own_report()
		if err != "":
			return err
		if not fresh and _f_wallet_read_clean():
			return ""
		if _f_paying > 0:
			continue   # a payment started meanwhile: its gold first
		err = await refresh_account()
		if err != "":
			return err
		fresh = false
	return "" if _f_wallet_read_clean() else "busy"


## account.gold was read while no payment was on its way, and none reached the phone since (nor a code the phone
## paid itself and the server has not spoken of yet).
func _f_wallet_read_clean() -> bool:
	return _f_paying == 0 and _f_gold_read_at >= 0 and _f_gold_read_at == _f_moves and profile.codes_unsettled.is_empty()


## The gold-double bug's leftover: this game's own changes in the online world it hosted are reported in 5 s batches
## and the marker moved with each at once: the server must have the last batch before a sync reads the wallet.
## "" or plain words (the network kept it: no sync now).
func _f_flush_own_report() -> String:
	var own: WalletReport = _f_reports.get("")
	if own == null:
		return ""
	if own.pending != 0:
		send_wallet_report()   # (or, while one runs, once more right after it)
	var waited := false
	while _f_sending:   # a batch taken is on its way until its answer: it may carry this game's own piece
		await _f_reports_sent
		waited = true
	if waited and is_inside_tree():
		await get_tree().process_frame   # not inside the sender's signal: the caller may free things
	return "" if own.pending == 0 else OnlineRules.message("network")


## Module 0.2.19: the host told this guest's game a gold move with its count (Session.hosted_gold_seq).
func _f_on_host_seq(match_id: String, seq: int) -> void:
	if match_id == "" or seq <= 0:
		return
	if _f_host_wait.get("match", "") == match_id and int(_f_host_wait.seq) >= seq:
		return
	_f_host_wait = {"match": match_id, "seq": seq, "since": -1}


## Whether the wallet just read has every gold move the host of this player's last online world told it: the server's
## `hosted` (module 0.2.19) names that match with that count or more. An older server can't say (no wait, as before);
## a record of another match means the server takes no more late batches for that one (it saw this player elsewhere
## since, or never in it): nothing to wait for; after HOST_WAIT_MSEC of waiting the host's game never told the server
## (it closed first): the server's word stands.
func _f_host_reported() -> bool:
	if _f_host_wait.is_empty():
		return true
	var h: Variant = account.get("hosted")
	if not (h is Dictionary) or not is_inside_tree() or (h as Dictionary).match_id != _f_host_wait.match \
			or int((h as Dictionary).seq) >= int(_f_host_wait.seq):
		_f_host_wait = {}
		return true
	if int(_f_host_wait.since) < 0:
		_f_host_wait.since = _msec()
	elif _msec() - int(_f_host_wait.since) >= HOST_WAIT_MSEC:
		_f_host_wait = {}
		return true
	return false


func _f_pause(seconds: float) -> void:
	if is_inside_tree():
		await get_tree().create_timer(seconds).timeout


## A paying call ended (its gold, if any, is on the phone now).
func _f_paid() -> void:
	_f_paying = maxi(_f_paying - 1, 0)
	if _f_paying == 0:
		_f_all_paid.emit()


## Reports this player's change at once (gains in the pieces the server takes); what was credited.
func _f_report_now(amount: int) -> int:
	var credited := 0
	_f_report_capped = false
	var universe := clampi(profile.universe_unlocked, 1, WalletReport.MAX_UNIVERSE)
	var batch := WalletReport.new()
	batch.add(amount, 0)
	for piece in batch.take(universe):
		var r: Dictionary = await backend.call_rpc("wallet_award", {"amount": piece, "reason": WALLET_REASON, "universe": universe})
		if not r.get("ok", false) and str(r.get("error", "")) == "not_enough_gold" and int(r.get("gold", 0)) > 0:
			r = await backend.call_rpc("wallet_award", {"amount": -int(r.gold), "reason": WALLET_REASON})   # all it has
		if r.get("capped", false) == true or str(r.get("error", "")) == "limit":
			_f_report_capped = true   # the server's hourly gold cap took less (LOG OUT says so)
		if not r.get("ok", false):
			break   # the rest goes up at a later sync
		credited += int(r.get("credited", 0))
	return credited


## The last gold report met the server's hourly cap (some gold is still on this phone, on its way).
var _f_report_capped := false
## A fresh player made by LOG IN (_become) takes the account's gold as the server has it, never reports its start gold.
var _adopt_server_gold := false


## This game's own gold changed in an online world: the host reports it, so the marker moves too.
func _f_on_own_gold_moved_online(delta: int) -> void:
	_f_move_marker(delta)


func _f_move_marker(delta: int) -> void:
	_f_moves += 1
	_f_moved_gold += delta
	var uid := backend.user_id() if backend else ""
	var marker := WalletSync.marker_of(_f_wallet_path(), uid)
	if uid != "" and marker >= 0 and delta != 0:
		WalletSync.set_marker(_f_wallet_path(), uid, marker + delta)


## Owner #67: whether this game plays in an online world now (the phone's gold then follows the host's reports,
## not a sync). Default: Session.is_online() for the game's own service; tests set `in_online_world`.
func _f_in_online_world() -> bool:
	if in_online_world.is_valid():
		return bool(in_online_world.call())
	return profile == Profile.data and Session.is_online()


func _f_wallet_path() -> String:
	return wallet_path if wallet_path != "" else prefs_path.get_base_dir().path_join("wallet_sync.json")


# --- The Gold Farm's clock (§5.6, §17.6), ready for M3 Task 10 ---

## The player leaves inside the farm of `world` (a save slot id): the server notes its own time.
func farm_start(world: String, rate_per_hour: int, universe: int = 1, cap_hours: int = 12) -> Dictionary:
	return await _farm({"action": "start", "world": world, "rate_per_hour": rate_per_hour, "universe": universe,
		"cap_hours": cap_hours})


## What the farm made so far by the server's clock: {"ok", "earned", "away_ms", "capped"}.
func farm_peek(world: String) -> Dictionary:
	return await _farm({"action": "peek", "world": world})


## Pays it into the server wallet: {"ok", "earned", "away_ms", "capped", "gold"}.
func farm_collect(world: String) -> Dictionary:
	return await _farm({"action": "collect", "world": world})


## M3 Task 10: farm gold the server paid into its wallet (farm_collect) reached this phone's gold outside an
## online world: the wallet marker moves with it, so the wallet sync never sends it again.
func farm_paid_on_phone(amount: int) -> void:
	_f_move_marker(amount)


func _farm(payload: Dictionary) -> Dictionary:
	if status != ONLINE:
		return {"ok": false, "error": "not_signed_in", "text": OnlineRules.message("not_signed_in")}
	var paying: bool = payload.get("action") == "collect"
	if paying:
		_f_paying += 1   # the gold-double bug: a collect pays the server's wallet, then the caller pays the phone
	var r: Dictionary = await backend.call_rpc("farm_collect", payload)
	if paying:
		_f_paid.call_deferred()   # after the caller has put the gold on the phone (farm_paid_on_phone)
	if not r.get("ok", false):
		r.text = OnlineRules.message(str(r.get("error", "")))
	return r


# --- A grown-up approves an under-13 player's friends (§17.2) ---

## Friend requests waiting for a grown-up: {"text": "" or words, "requests": [{"user_id",
## "username", "direction": "in" | "out"}]}.
func friend_approvals() -> Dictionary:
	if status != ONLINE:
		return {"text": OnlineRules.message("not_signed_in"), "requests": []}
	var r: Dictionary = await backend.call_rpc("approve_friend", {})
	if not r.get("ok", false):
		return {"text": OnlineRules.message(str(r.get("error", ""))), "requests": []}
	return {"text": "", "requests": approval_list(r.get("requests"))}


## Yes or no to one request. "" or words.
func approve_friend(user_id: String, yes: bool) -> String:
	if status != ONLINE:
		return OnlineRules.message("not_signed_in")
	var r: Dictionary = await backend.call_rpc("approve_friend", {"user_id": user_id, "approve": yes})
	if not r.get("ok", false):
		return OnlineRules.message(str(r.get("error", "")))
	if social_allowed():
		await refresh_friends()
	return ""


## The server's list, checked: only well-formed requests with a valid username.
static func approval_list(value: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not (value is Array):
		return out
	for r: Variant in value:
		if r is Dictionary and r.get("user_id") is String and r.user_id != "" and r.get("username") is String \
				and UsernameRules.validate(r.username) == "" and r.get("direction") in ["in", "out"]:
			out.append({"user_id": r.user_id, "username": r.username, "direction": r.direction})
	return out


func _msec() -> int:
	return int(msec_clock.call()) if msec_clock.is_valid() else Time.get_ticks_msec()

# --- M4 Task 8b, agent G: delete my online account (spec §5.14, §17.2) ---
# From the grown-up area, behind the parent gate: the server's delete_account in two calls (a
# confirmation first, so one stray call can't delete), then this device forgets its online link: the
# device id (the next PLAY ONLINE starts a new account), the online prefs (the stay-safe card, mutes)
# and the wallet markers. Worlds, the profile, gold and play time on the device stay: offline play
# (Sandbox, Survivor, LAN, bot friends) never needed any of it.

## The online account was deleted and this device forgot its online link.
signal account_deleted


## Whether this device has an online account at all (it signed in once: its device id is kept).
func has_online_link() -> bool:
	return device_id != "" or FileAccess.file_exists(device_id_path) or FileAccess.file_exists(device_id_path + ".bak")


## The first call: {"text": "" or plain words, "confirm": the server's confirmation, "username"}.
func delete_account_start() -> Dictionary:
	if status != ONLINE:
		return {"text": OnlineRules.message("not_signed_in"), "confirm": ""}
	var r: Dictionary = await backend.call_rpc("delete_account", {})
	if not r.get("ok", false) or not (r.get("confirm") is String) or r.confirm == "":
		return {"text": OnlineRules.message(str(r.get("error", ""))), "confirm": ""}
	return {"text": "", "confirm": r.confirm, "username": str(r.get("username", ""))}


## The second call, with the confirmation: the account is deleted, then this device forgets its
## online link. "" or plain words (a late confirmation: "confirm_expired"; ask for a new one).
func delete_account(confirm: String, password: String = "") -> String:
	if status != ONLINE:
		return OnlineRules.message("not_signed_in")
	var payload := {"confirm": confirm}
	if password != "":
		payload.password = password   # owner #105: the server needs it once the account has one
	var r: Dictionary = await backend.call_rpc("delete_account", payload)
	if not r.get("ok", false) or r.get("deleted") != true:
		var code := str(r.get("error", ""))
		if code in ["wrong_password", "password_needed", "locked"]:
			return PasswordRules.error_text(code, int(r.get("wait", 0)), true)
		return OnlineRules.message(code)
	forget_online()
	account_deleted.emit()
	return ""


## The files this device keeps about its online account (each with JsonStore's .bak and .tmp).
func online_files() -> Array[String]:
	return [device_id_path, prefs_path, _f_wallet_path(), _i_book_path(), _gh_path()]   # M4 I: gift stamps; ghosts


## Forgets everything this device kept about its online account (never the profile or worlds).
func forget_online() -> void:
	if backend:
		backend.sign_out()
	_went_offline()
	for path in online_files():
		for p: String in [path, path + ".bak", path + ".tmp"]:
			if FileAccess.file_exists(p) and DirAccess.remove_absolute(p) != OK:
				push_warning("OnlineService: could not forget %s" % p)
	device_id = ""
	account = {}
	_blocked.clear()
	prefs = OnlinePrefs.new()
	has_password = -1   # owner #105
	logged_out = false
	_f_reports.clear()
	_f_report_match.clear()
	wallet_reported = 0
	_i_forget()   # M4 I
	_gh_forget()   # M4 ghost races
	account_changed.emit()
	friends_changed.emit()


## A chat message as this game showed it, for a report ({"text"} or {"emote"}, "at_ms"): the server
## keeps it only when it has no copy of its own (then marked "as shown by the reporter").
static func shown_message(msg: Dictionary) -> Dictionary:
	var out := {}
	var emote := str(msg.get("emote", ""))
	if str(msg.get("text", "")) != "":
		out.text = str(msg.text)
	elif emote != "":
		out.emote = emote
	else:
		return {}
	var t: Variant = msg.get("time", 0)
	if typeof(t) in [TYPE_INT, TYPE_FLOAT] and int(t) > 0:
		out.at_ms = int(t) * 1000
	return out

# --- M4 I: gifts and visits (M4 Wave 3, agent I; spec §17.5, research T3, T4, D5) ---
# Friends when they are not online together, over the server's module 0.2.4
# (server/modules/src/server/gifts.ts): a picked build sent as a present (send_gift) that the friend
# opens into a stamp (list_gifts, open_gift -> GiftStampBook); one showcase area friends visit while the
# child is away (publish_showcase, get_showcase), with preset guestbook stickers (sign_guestbook,
# remove_sticker); a quick phrase and maybe a tiny build in a bottle (send_bottle, list_bottles,
# open_bottle); REPORT on everything received (report_build). The server checks everything again
# (friends only, consent first, sizes, lists); this side reads its answers carefully (GiftRules), hides
# what muted or blocked players sent, and answers "" or plain words.

## The presents or bottles waiting on the server changed (a list was read, one was opened, a nudge came).
signal gifts_changed
## A friend left a sticker on this player's showcase (notification 106; the owner reads them next time).
signal sticker_received(from: String, sticker: String)

## Waiting on the server, from friends who are not muted or blocked: GiftRules.gift_list / bottle_list.
var gifts: Array[Dictionary] = []
var bottles: Array[Dictionary] = []
## Stickers this session heard of (notification 106), for the "new stickers" dot.
var new_stickers := 0
## The device's stamp book (tests give their own; default GiftStampBook.current()).
var gift_book: GiftStampBook
var gift_book_path := ""          # "" = GiftStampBook.PATH (tests give their own)


func _i_book() -> GiftStampBook:
	if gift_book == null:
		gift_book = GiftStampBook.current()
	return gift_book


func _i_book_path() -> String:
	return gift_book_path if gift_book_path != "" else GiftStampBook.PATH


func _i_save_book() -> void:
	_i_book().save_to(_i_book_path())


## After signing in: what waits for this player (the menu's FRIENDS button counts it).
func _i_signed_in() -> void:
	if not backend.notified.is_connected(_i_on_notified):
		backend.notified.connect(_i_on_notified)
	if social_allowed():
		await refresh_gifts()
		await refresh_bottles()


func _i_on_notified(code: int, content: String, _sender_id: String) -> void:
	match code:
		GiftRules.NOTE_GIFT, GiftRules.NOTE_BOTTLE:
			if social_allowed():
				if code == GiftRules.NOTE_GIFT:
					await refresh_gifts()
				else:
					await refresh_bottles()
		GiftRules.NOTE_STICKER:
			var json := JSON.new()
			if json.parse(content) != OK or typeof(json.data) != TYPE_DICTIONARY:
				return
			var d: Dictionary = json.data
			var from: Variant = d.get("from_username", "")
			if from is String and UsernameRules.validate(from) == "" and GiftRules.is_sticker(d.get("sticker")) \
					and not _i_hidden(str(d.get("from_user_id", ""))):   # M4 Task 10 review G: muted or blocked
				new_stickers += 1
				sticker_received.emit(from, d.sticker)


func _i_refusal() -> String:
	if status != ONLINE or backend == null:
		return OnlineRules.message("not_signed_in")
	if not social_allowed():
		return OnlineRules.message("consent_needed")
	return ""


func _i_hidden(from_id: String) -> bool:
	return is_muted(from_id) or _blocked.has(from_id)


# --- Blueprint gifts ---

## Sends a build (BuildCodec text, a gift's size) to a friend; with `ghost` (M4 ghost races: a course in the
## build and the child's best run on it) the race comes along. "" or plain words.
func send_gift(friend_id: String, build: String, ghost: RaceGhost = null) -> String:
	var why := _i_refusal()
	if why != "":
		return why
	if BuildCodec.decode(build, BuildCodec.GIFT).is_empty():
		return GiftRules.message("too_big" if BuildCodec.count_of(build) > BuildPicker.MAX_BLOCKS else "bad_build")
	var r: Dictionary = await backend.call_rpc("send_gift", {"user_id": friend_id, "build": build}) if ghost == null \
		else await backend.call_rpc("share_ghost", {"to": "gift", "user_id": friend_id, "build": build, "ghost": ghost.to_wire()})
	if not r.get("ok", false):
		return GiftRules.message(str(r.get("error", "")))
	_i_book().keep_mine(build)   # the child's own shelf: send it again later from PLAY ONLINE
	_i_save_book()
	return ""


## Reads the presents waiting on the server. "" or plain words.
func refresh_gifts() -> String:
	var why := _i_refusal()
	if why != "":
		return why
	var r: Dictionary = await backend.call_rpc("list_gifts", {})
	if not r.get("ok", false):
		return GiftRules.message(str(r.get("error", "")))
	gifts.assign(GiftRules.gift_list(r.get("gifts")).filter(func(g: Dictionary) -> bool: return not _i_hidden(g.from_id)))
	gifts_changed.emit()
	return ""


## Opens a present: it becomes a stamp in the GIFTS page. {"text": "" or words, "slot": its slot or -1}.
func open_gift(gift_id: String) -> Dictionary:
	var why := _i_refusal()
	if why != "":
		return {"text": why, "slot": -1}
	if _i_book().is_full():
		return {"text": GiftRules.message("book_full"), "slot": -1}
	var r: Dictionary = await backend.call_rpc("open_gift", {"gift_id": gift_id})
	_i_drop(gifts, gift_id)
	if not r.get("ok", false):
		return {"text": GiftRules.message("gift_gone" if str(r.get("error", "")) == "not_found" else str(r.get("error", ""))), "slot": -1}
	var g := GiftRules.opened(r.get("gift"))
	var slot := _i_book().add(g.build, g.from, g.from_id, GiftStampBook.KIND_GIFT, _now()) if not g.is_empty() else -1
	if slot < 0:
		return {"text": GiftRules.message("bad_build"), "slot": -1}
	_i_save_book()
	_gh_keep_gift(slot, g)   # M4 ghost races: the sender's race came with it
	return {"text": "", "slot": slot}


## Deletes a present without opening it (the server forgets it). "" or plain words.
func discard_gift(gift_id: String) -> String:
	return await _i_discard("open_gift", "gift_id", gift_id, gifts)


## Deletes a gift stamp from this device.
func delete_stamp(slot: int) -> void:
	_gh_forget_slot(slot)   # M4 ghost races: its race goes with it
	if _i_book().remove(slot):
		_i_save_book()
		gifts_changed.emit()


func _i_discard(rpc_id: String, key: String, id: String, list: Array[Dictionary]) -> String:
	var why := _i_refusal()
	if why != "":
		return why
	var r: Dictionary = await backend.call_rpc(rpc_id, {key: id, "discard": true})
	_i_drop(list, id)
	return "" if r.get("ok", false) or str(r.get("error", "")) == "not_found" else GiftRules.message(str(r.get("error", "")))


func _i_drop(list: Array[Dictionary], id: String) -> void:
	for x in list.duplicate():
		if x.id == id:
			list.erase(x)
	gifts_changed.emit()


# --- Showcases and the guestbook ---

## Puts this player's showcase up (an area's BuildCodec text; a buddy {"build", "at": [x, y, z]} waving
## in it, or {}). "" or plain words.
func publish_showcase(build: String, buddy: Dictionary = {}) -> String:
	var why := _i_refusal()
	if why != "":
		return why
	var problem := ShowcaseArea.problem(build)
	if problem != "":
		return ShowcaseArea.message(problem)
	var payload := {"build": build}
	if not buddy.is_empty():
		payload.buddy = buddy
	var r: Dictionary = await backend.call_rpc("publish_showcase", payload)
	return "" if r.get("ok", false) else GiftRules.message(str(r.get("error", "")))


## Takes this player's showcase down (its stickers go too). "" or plain words.
func remove_showcase() -> String:
	var why := _i_refusal()
	if why != "":
		return why
	var r: Dictionary = await backend.call_rpc("publish_showcase", {"remove": true})
	return "" if r.get("ok", false) else GiftRules.message(str(r.get("error", "")))


## A friend's showcase to visit: {"text": "" or words, "showcase": GiftRules.showcase or {}}.
func showcase_of(friend_id: String) -> Dictionary:
	var why := _i_refusal()
	if why != "":
		return {"text": why, "showcase": {}}
	var r: Dictionary = await backend.call_rpc("get_showcase", {"user_id": friend_id})
	if not r.get("ok", false):
		return {"text": GiftRules.message(str(r.get("error", ""))), "showcase": {}}
	var shown := GiftRules.showcase(r)
	if not shown.is_empty():
		shown.ghosts = await _gh_fetch(shown)   # M4 ghost races: its races come along (and stay on the device)
	return {"text": "" if not shown.is_empty() else GiftRules.message("bad_build"), "showcase": shown}


## This player's own showcase and its guestbook (muted players' stickers left out): {"text", "showcase",
## "guestbook"}; no showcase is {"text": "", "showcase": {}, "guestbook": []}.
func my_showcase() -> Dictionary:
	var why := _i_refusal()
	if why != "":
		return {"text": why, "showcase": {}, "guestbook": []}
	var r: Dictionary = await backend.call_rpc("get_showcase", {})
	if not r.get("ok", false):
		var err := str(r.get("error", ""))
		return {"text": "" if err == "no_showcase" else GiftRules.message(err), "showcase": {}, "guestbook": []}
	var shown := GiftRules.showcase(r)
	new_stickers = 0
	return {"text": "", "showcase": shown, "guestbook": _i_visible_book(shown.get("guestbook", []))}


func _i_visible_book(book: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e: Dictionary in book:
		if not _i_hidden(e.from_id):
			out.append(e)
	return out


## Leaves a preset sticker in a friend's guestbook. "" or plain words.
func sign_guestbook(friend_id: String, sticker: String) -> String:
	var why := _i_refusal()
	if why != "":
		return why
	if not GiftRules.is_sticker(sticker):
		return GiftRules.message("bad_sticker")
	var r: Dictionary = await backend.call_rpc("sign_guestbook", {"user_id": friend_id, "sticker": sticker})
	return "" if r.get("ok", false) else GiftRules.message(str(r.get("error", "")))


## Deletes one sticker of this player's guestbook: {"text", "guestbook"}.
func remove_sticker(entry_id: String) -> Dictionary:
	var why := _i_refusal()
	if why != "":
		return {"text": why, "guestbook": []}
	var r: Dictionary = await backend.call_rpc("remove_sticker", {"entry_id": entry_id})
	if not r.get("ok", false):
		return {"text": GiftRules.message(str(r.get("error", ""))), "guestbook": []}
	return {"text": "", "guestbook": _i_visible_book(GiftRules.guestbook(r.get("guestbook")))}


# --- Bottle mail ---

## A quick-chat phrase and maybe a tiny build (BuildCodec text, 4 x 4 x 4 at most; "" for none) in a
## bottle to a friend. "" or plain words.
func send_bottle(friend_id: String, phrase: String, build: String = "") -> String:
	var why := _i_refusal()
	if why != "":
		return why
	if not ChatRules.is_quick_phrase(phrase):
		return GiftRules.message("bad_phrase")
	var payload := {"user_id": friend_id, "phrase": phrase}
	if build != "":
		if BuildCodec.decode(build, BuildCodec.BOTTLE).is_empty():
			return GiftRules.message("too_big")
		payload.build = build
	var r: Dictionary = await backend.call_rpc("send_bottle", payload)
	return "" if r.get("ok", false) else GiftRules.message(str(r.get("error", "")))


## Reads the bottles waiting for this player. "" or plain words.
func refresh_bottles() -> String:
	var why := _i_refusal()
	if why != "":
		return why
	var r: Dictionary = await backend.call_rpc("list_bottles", {})
	if not r.get("ok", false):
		return GiftRules.message(str(r.get("error", "")))
	bottles.assign(GiftRules.bottle_list(r.get("bottles")).filter(func(b: Dictionary) -> bool: return not _i_hidden(b.from_id)))
	gifts_changed.emit()
	return ""


## Opens a bottle: {"text", "bottle": GiftRules.opened_bottle or {}, "slot": its tiny build's stamp or -1}.
func open_bottle(bottle_id: String) -> Dictionary:
	var why := _i_refusal()
	if why != "":
		return {"text": why, "bottle": {}, "slot": -1}
	var r: Dictionary = await backend.call_rpc("open_bottle", {"bottle_id": bottle_id})
	_i_drop(bottles, bottle_id)
	if not r.get("ok", false):
		return {"text": GiftRules.message("gift_gone" if str(r.get("error", "")) == "not_found" else str(r.get("error", ""))),
			"bottle": {}, "slot": -1}
	var b := GiftRules.opened_bottle(r.get("bottle"))
	if b.is_empty():
		return {"text": GiftRules.message("gift_gone"), "bottle": {}, "slot": -1}
	var slot := -1
	if b.build != "":
		slot = _i_book().add(b.build, b.from, b.from_id, GiftStampBook.KIND_BOTTLE, _now())
		if slot >= 0:
			_i_save_book()
	return {"text": "", "bottle": b, "slot": slot}


func discard_bottle(bottle_id: String) -> String:
	return await _i_discard("open_bottle", "bottle_id", bottle_id, bottles)


# --- REPORT on everything received ---

## Reports a build (what: "showcase", "gift" or "bottle"; the build as this game has it, for the person
## who reviews it); the player is muted here too, and a reported gift stamp (slot) is deleted.
func report_build(user_id: String, what: String, build: String = "", slot: int = -1, reason: String = "bad_build") -> String:
	if status != ONLINE or backend == null:
		return OnlineRules.message("not_signed_in")
	var payload := {"user_id": user_id, "what": what, "reason": reason if reason in ["bad_build", "scary", "other"] else "bad_build"}
	if build != "":
		payload.build = build
	_gh_report_payload(slot, payload)   # M4 ghost races: a gift stamp's race, for the reviewer
	var r: Dictionary = await backend.call_rpc("report_build", payload)
	if not r.get("ok", false):
		return OnlineRules.message(str(r.get("error", "")))
	_gh_forget_player(user_id)   # M4 ghost races: every race of that player goes from this device
	mute(user_id)
	if slot >= 0:
		delete_stamp(slot)
	gifts.assign(gifts.filter(func(g: Dictionary) -> bool: return g.from_id != user_id))
	bottles.assign(bottles.filter(func(b: Dictionary) -> bool: return b.from_id != user_id))
	gifts_changed.emit()
	return ""


## Deleting the online account forgets friends' gift stamps on this device too (online_files).
func _i_forget() -> void:
	gifts.clear()
	bottles.clear()
	new_stickers = 0
	gift_book = GiftStampBook.new()
	if gift_book_path == "":
		GiftStampBook.use(gift_book)
	gifts_changed.emit()

# --- M4 ghost races (spec §17.5, research T2; server module 0.2.6: share_ghost, list_ghosts) ---
# The child's best runs on courses they built go on their showcase (share_showcase_ghosts when SHOW IT puts it
# up; share_ghost when a new best replaces one) or with a gift that holds a whole course (send_gift's `ghost`).
# A friend's showcase comes with its ghosts (showcase_of) and they stay on this device with the showcase's
# build (GhostBook, user://ghosts.json), so a visit races them even offline; a gift's ghost stays with its stamp.
# The server checks everything again (friends only, consent first, the run against its course); a report
# covers ghosts and forgets that player's here; deleting the online account forgets the book.

## Ghosts kept on this device changed (a visit brought some, a stamp or a report took some away).
signal ghosts_changed

## The device's ghost book (tests give their own; default GhostBook.current()).
var ghost_book: GhostBook
var ghost_book_path := ""          # "" = GhostBook.PATH (tests give their own)


func _gh_book() -> GhostBook:
	if ghost_book == null:
		ghost_book = GhostBook.current()
	return ghost_book


func _gh_path() -> String:
	return ghost_book_path if ghost_book_path != "" else GhostBook.PATH


func _gh_save() -> void:
	_gh_book().save_to(_gh_path())
	ghosts_changed.emit()


## Whether friends' names show on their ghosts (13+, or under 13 with a grown-up's verified consent); offline, the
## last answer this device knew.
func ghost_names_shown() -> bool:
	if status == ONLINE and not account.is_empty():
		var ok := GhostRaceRules.shows_names(account.get("age_band", &""), str(account.get("consent", "")))
		if ok != _gh_book().names_ok:
			_gh_book().names_ok = ok
			_gh_save()
		return ok
	return _gh_book().names_ok


## My showcase just went up in `world` (Game.slot and the seed) at `origin` of `size`: my best runs inside it go
## on it ([{"start": world cell, "ghost": RaceGhost}], GhostShare.showcase_ghosts). {"text": "" or the first
## refusal's words, "shared": how many}.
func share_showcase_ghosts(list: Array[Dictionary], world: String, origin: Vector3i, size: Vector3i) -> Dictionary:
	var why := _i_refusal()
	if why != "":
		return {"text": why, "shared": 0}
	_gh_book().set_mine(world, origin, size)
	var shared := 0
	var text := ""
	for e in list:
		var err := await share_ghost(e.ghost, world, e.start)
		if err == "":
			shared += 1
		elif text == "":
			text = err
	_gh_save()
	return {"text": text, "shared": shared}


## My showcase went up without any of my races on it (the server took the old area's down).
func ghost_book_note_showcase(world: String, origin: Vector3i, size: Vector3i) -> void:
	_gh_book().set_mine(world, origin, size)
	_gh_save()


## One of my best runs on my showcase (the course whose START is `world_start` in `world`); a run of the same
## course replaces the one there. "" or plain words.
func share_ghost(g: RaceGhost, world: String, world_start: Vector3i) -> String:
	var why := _i_refusal()
	if why != "":
		return why
	var r: Dictionary = await backend.call_rpc("share_ghost", {"to": "showcase", "ghost": g.to_wire()})
	if not r.get("ok", false):
		return GhostRaceRules.message(str(r.get("error", "")))
	_gh_book().note_shared(world, world_start, str(r.get("ghost_id", "")), g.ms)
	_gh_save()
	return ""


## A friend's showcase ghosts: {"text": "" or words, "ghosts": Array[RaceGhost]}.
func ghosts_of(friend_id: String) -> Dictionary:
	var why := _i_refusal()
	if why != "":
		return {"text": why, "ghosts": [] as Array[RaceGhost]}
	var r: Dictionary = await backend.call_rpc("list_ghosts", {"user_id": friend_id})
	if not r.get("ok", false):
		return {"text": GiftRules.message(str(r.get("error", ""))), "ghosts": [] as Array[RaceGhost]}
	var owner := str(r.get("owner_username", ""))
	return {"text": "", "ghosts": GhostRaceRules.ghosts_of(r.get("ghosts"), str(r.get("owner_id", friend_id)), owner)}


## A visited showcase's ghosts, kept on this device with its build (none: nothing kept, and an old copy goes).
func _gh_fetch(shown: Dictionary) -> Array[RaceGhost]:
	var got := await ghosts_of(str(shown.owner_id))
	var list: Array[RaceGhost] = got.ghosts
	for g in list:
		g.owner = str(shown.owner)
	if got.text == "":
		ghost_names_shown()   # remembered for offline races
		_gh_book().keep_showcase(str(shown.owner_id), str(shown.owner), str(shown.build), list, _now())
		_gh_save()
	return list


## Friends' showcases whose races are on this device (offline too), muted and blocked players' left out.
func kept_showcases() -> Array[Dictionary]:
	return _gh_book().showcase_owners().filter(func(s: Dictionary) -> bool: return not _i_hidden(str(s.owner_id)))


## One kept showcase, as a visit reads it ({} when none).
func kept_showcase(owner_id: String) -> Dictionary:
	return {} if _i_hidden(owner_id) else _gh_book().showcase_for(owner_id)


## Whether the gift stamp in `slot` has its sender's race with it.
func ghost_race_in_slot(slot: int) -> bool:
	return slot >= 0 and not _gh_book().gift_entry(slot).is_empty()


func _gh_keep_gift(slot: int, g: Dictionary) -> void:
	var ghost: Variant = g.get("ghost")
	if ghost is RaceGhost:
		_gh_book().keep_gift(slot, str(g.from_id), str(g.from), ghost, _now())
		_gh_save()


func _gh_forget_slot(slot: int) -> void:
	if not _gh_book().gift_entry(slot).is_empty():
		_gh_book().forget_slot(slot)
		_gh_save()


func _gh_report_payload(slot: int, payload: Dictionary) -> void:
	var e := _gh_book().gift_entry(slot) if slot >= 0 else {}
	if not e.is_empty():
		payload.ghost = (e.ghost as RaceGhost).to_wire()


func _gh_forget_player(user_id: String) -> void:
	if _gh_book().remove_owner(user_id) > 0:
		_gh_save()


## A finished race against the ghost `key` (GhostBook.showcase_key or gift_key) in `ms`: true for this
## child's new best against it (kept on the device).
func note_ghost_result(key: String, ms: int) -> bool:
	var best := _gh_book().note_result(key, ms, _now())
	_gh_save()
	return best


## Deleting the online account forgets friends' ghosts on this device too (online_files).
func _gh_forget() -> void:
	ghost_book = GhostBook.new()
	if ghost_book_path == "":
		GhostBook.use(ghost_book)
	ghosts_changed.emit()

# --- Owner #67: the account on every device (spec §5.13, §17.1) ---
# An account is reached by device ids (no password, no e-mail). A grown-up makes a sign-in key on a device where the
# child plays (GROWN-UPS -> ONLINE PLAY -> OTHER DEVICES: make_account_key); on a new phone, a tablet or a browser
# whose storage was wiped, PLAY ONLINE -> I HAVE AN ACCOUNT (behind the parent gate) takes the name and the key
# (sign_in_with_key): the server links a new id of this device to that account, this device keeps the new id and
# signs in again, and the account's profile (ProfileSync), gold (sync_wallet) and friends come back. The device's own
# never-claimed account is deleted by the server. sign_out_other_devices is for a lost phone.

## A claimed account's profile has the account's name (a reinstall's first-launch screen may have given another).
func _o67_take_account_name() -> void:
	var name := str(account.get("username", ""))
	if account.get("claimed") == true and UsernameRules.validate(name) == "" and profile.username != name:
		profile.username = name
		save_profile.call()


## The resting move's last step (owner #99): its one-time key is handed to THIS device's own account (the one that made
## the move_request), so it asks on the main connection; then this device plays as the account like any LOG IN. "" or
## plain words.
func move_sign_in(username: String, key: String) -> String:
	if status != ONLINE:
		var signed := await sign_in()
		if signed != "":
			return signed
	var new_id := DeviceId.generate()
	var s := session
	var r: Dictionary = await backend.call_rpc("sign_in_with_key", {"username": UsernameRules.normalize(username),
		"key": key.strip_edges(), "device_id": new_id})
	if s != session:
		return OnlineRules.message("not_signed_in")
	if not r.get("ok", false):
		var code := str(r.get("error", ""))
		return OnlineRules.key_locked_message(int(r.get("wait", 60))) if code == "locked" else OnlineRules.message(code)
	if str(r.get("left", "")) == "same":
		return await refresh_account()
	return await _become(new_id, str(r.get("username", username)), str(r.get("user_id", "")))


## LOG IN with a grown-up's key (typed any way: KeyRules on the server). Owner #105 (the final review's 3): it asks with
## this device's own asking account, as LOG IN with the password does, so it works from a logged-out device too; the
## server logs the account's other devices out. "" or plain words.
func sign_in_with_key(username: String, key: String) -> String:
	var r := await _ask_to_log_in("sign_in_with_key", {"username": UsernameRules.normalize(username), "key": key.strip_edges()})
	if str(r.get("text", "")) != "":
		return str(r.text)
	var answer: Dictionary = r.answer
	if not answer.get("ok", false):
		var code := str(answer.get("error", ""))
		if code == "locked":
			return OnlineRules.key_locked_message(int(answer.get("wait", 60)))
		return OnlineRules.message(code)
	return await _become(str(r.device_id), str(answer.get("username", username)), str(answer.get("user_id", "")))


## This device signs in with `id` from now on (tests: the `device_id` they set; else the id file). "" or words.
func _o67_keep_device_id(id: String) -> String:
	if device_id != "":
		device_id = id
		return ""
	DirAccess.make_dir_recursive_absolute(device_id_path.get_base_dir())
	if JsonStore.write_atomic(device_id_path, JSON.stringify({"device_id": id})) != OK:
		return OnlineRules.message("")
	WebStorage.sync()   # M7: in a browser the rename reaches its storage now
	return ""


## The account's sign-in key: {"text": "" or words, "has_key", "made_ms", "devices", "username"}.
func account_key_state() -> Dictionary:
	return await _o67_key_call({"action": "state"})


## A new key for the account (the one before stops working): {"text": "" or words, "key": "XXXX-XXXX", "username",
## "devices"}. A grown-up's (the area behind the parent gate asks).
func make_account_key() -> Dictionary:
	return await _o67_key_call({"action": "new"})


## Every other device of the account stops signing in to it (a lost phone); every session ends, so this device
## signs in again. "" or plain words.
func sign_out_other_devices() -> String:
	var mine := device_id if device_id != "" else DeviceId.load_or_create(device_id_path)
	var r: Dictionary = await _o67_key_call({"action": "sign_out_others", "device_id": mine})
	if r.text != "":
		return r.text
	if backend:
		backend.sign_out()
	_went_offline()
	return await sign_in()


func _o67_key_call(payload: Dictionary) -> Dictionary:
	if status != ONLINE or backend == null:
		return {"text": OnlineRules.message("not_signed_in"), "has_key": false, "key": ""}
	var r: Dictionary = await backend.call_rpc("account_key", payload)
	if not r.get("ok", false):
		return {"text": OnlineRules.message(str(r.get("error", ""))), "has_key": false, "key": ""}
	r.text = ""
	r.erase("ok")
	return r

# --- Owner #79: invite a friend (spec §25.2; module 0.2.16: server/modules/src/server/referrals.ts) ---
# Every claimed account has an invite code (invite_info). A new player types a friend's code at the start or in SETTINGS,
# or comes with the web page's ?invite=: the profile keeps it until the server takes it (InviteData.pending_code; the
# next sign-in sends it), and the server gives the welcome gift at once. The first School unit mastered and a first Moon
# landing go up once (InviteData.events_to_send): the server pays the friend who invited, both of them, and the tree.
# News wait on the server ("Your friend Sam_22 joined and learned! +250 gold"); note 108 nudges an open game. Gold given
# on the server reaches the phone by the wallet sync. Nothing personal is sent: codes and the account's own ids only.

const INVITE_NOTE := 108
## The server's answers that are about the code itself (anything else is the network: the code keeps waiting).
const INVITE_REFUSALS: Array[String] = ["unknown", "bad_code", "own_code", "already_used", "not_new", "already_in",
	"group_full", "locked", "bad_request"]

## News arrived for the child (take_invite_news gives them): the menu shows them on a card.
signal invite_news_arrived
## A code the profile kept was tried at a sign-in: {"ok", "text" (for the child), ...} (use_invite's answer).
signal invite_code_result(result: Dictionary)

## News not shown yet: [{"what" (joined, learned, tree, landed, learner), "name", "gold"}].
var invite_news: Array[Dictionary] = []
## The last invite_info answer ({} until read): what the INVITE A FRIEND page shows.
var invite_state := {}


func _inv_signed_in() -> void:
	if not backend.notified.is_connected(_inv_on_notified):
		backend.notified.connect(_inv_on_notified)
	if profile.invite.pending_code != "":
		var r := await use_invite(profile.invite.pending_code)
		if not r.get("waiting", false):
			invite_code_result.emit(r)
	await send_invite_events()
	if profile.invite.code != "":   # this child has a code a friend may have used: any news?
		await refresh_invite_news()


func _inv_on_notified(code: int, _content: String, _sender_id: String) -> void:
	if code == INVITE_NOTE:
		await refresh_invite_news()


## The INVITE A FRIEND page's data from the server: {"text": "" or words, "code", "claimed", "can_use_code", "guide",
## "friends", "counts", "month", "caps", "earned", "groups", "made", "news", "world", "rewards"}. `seen`: its news are
## shown now (the server forgets them). The code is kept in the profile for offline pages.
func invite_info(seen: bool = false) -> Dictionary:
	if status != ONLINE or backend == null:
		return {"text": OnlineRules.message("not_signed_in")}
	var r: Dictionary = await backend.call_rpc("invite_info", {"seen": true} if seen else {})
	if not r.get("ok", false):
		return {"text": OnlineRules.message(str(r.get("error", "")))}
	r.erase("ok")
	r.text = ""
	invite_state = r
	var mine := str(r.get("code", ""))
	var guide := str(r.get("guide", ""))
	var changed := false
	if InviteRules.looks_like_code(mine) and profile.invite.code != mine:
		profile.invite.code = mine
		changed = true
	if guide != "" and UsernameRules.validate(guide) == "" and profile.invite.guide != guide:
		profile.invite.guide = guide
		changed = true
	if changed:
		save_profile.call()
	return r


## Uses a friend's, a class or a family code now, or keeps it for the next sign-in when this device can't reach the
## server: {"ok", "text" (for the child), "welcome" (gold), "guide", "kind", "group", "waiting" (kept for later)}.
func use_invite(typed: String) -> Dictionary:
	var code := InviteRules.shown(typed)
	if not InviteRules.looks_like_code(code):
		return {"ok": false, "text": InviteRules.error_words("unknown")}
	if status != ONLINE or backend == null:
		return _inv_keep(code)
	var s := session
	var r: Dictionary = await backend.call_rpc("invite_use", {"code": code})
	if s != session:
		return {"ok": false, "text": OnlineRules.message("not_signed_in")}   # owner #99: another player plays now
	if not r.get("ok", false):
		var err := str(r.get("error", ""))
		if not INVITE_REFUSALS.has(err):
			return _inv_keep(code)
		profile.invite.pending_code = ""   # the server said no: nothing waits
		save_profile.call()
		var words := InviteRules.error_words(err)
		return {"ok": false, "text": words, "error": err}
	var welcome := int(r.get("welcome", 0))
	var guide := str(r.get("guide", ""))
	var kind := str(r.get("kind", ""))
	var group := str(r.get("group", ""))
	profile.invite.pending_code = ""
	if kind == "friend" or welcome > 0:
		profile.invite.used = true
	if guide != "" and UsernameRules.validate(guide) == "":
		profile.invite.guide = guide
	save_profile.call()
	if welcome > 0:
		await sync_wallet()
	var text := InviteRules.welcome_words(guide, welcome)
	if group != "":
		text = ("Welcome to the class!" if group == "class" else "Welcome to the family!") \
			+ (" +%d gold." % welcome if welcome > 0 else "")
	return {"ok": true, "text": text, "welcome": welcome, "guide": guide, "kind": kind, "group": group}


func _inv_keep(code: String) -> Dictionary:
	profile.invite.pending_code = code
	save_profile.call()
	return {"ok": false, "waiting": true, "text": "We'll check the code the next time you're online."}


## Tells the server what it has not heard (the first unit mastered, a first Moon landing), once each.
func send_invite_events() -> void:
	if status != ONLINE or backend == null:
		return
	for e in profile.invite.events_to_send():
		var r: Dictionary = await backend.call_rpc("invite_progress", e)
		if not r.get("ok", false):
			if str(r.get("error", "")) == "bad_request":
				profile.invite.mark_sent(InviteData.key_of(e))   # never again: the server doesn't take it
			continue
		profile.invite.mark_sent(InviteData.key_of(e))
		save_profile.call()
		var gold := int(r.get("gold", 0))
		if gold > 0:
			invite_news.append({"what": "learner", "name": str(r.get("guide", "")), "gold": gold})
			invite_news_arrived.emit()
			await sync_wallet()


## Reads the news the server kept for this player (shown now: the server forgets them).
func refresh_invite_news() -> void:
	var r := await invite_info(true)
	if r.text != "":
		return
	var gold := 0
	var got := false
	for n: Variant in r.get("news", []):
		if n is Dictionary and InviteRules.news_words(n) != "":
			var d: Dictionary = n
			var name: Variant = d.get("name", "")
			var paid := maxi(int(d.get("gold", 0)), 0)
			invite_news.append({"what": str(d.what), "name": name if name is String and UsernameRules.validate(name) == "" \
				else "", "gold": paid})
			gold += paid
			got = true
	if gold > 0:
		await sync_wallet()
	if got:
		invite_news_arrived.emit()


## The news not shown yet (and forgets them).
func take_invite_news() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.assign(invite_news)
	invite_news.clear()
	return out


## A grown-up's class or family code (behind the parent gate): "make", "leave" or "remove", with kind "class" or
## "family". {"text": "" or words, "code"}.
func invite_group(action: String, kind: String) -> Dictionary:
	if status != ONLINE or backend == null:
		return {"text": OnlineRules.message("not_signed_in"), "code": ""}
	var r: Dictionary = await backend.call_rpc("invite_group", {"action": action, "kind": kind})
	if not r.get("ok", false):
		return {"text": InviteRules.error_words(str(r.get("error", ""))), "code": ""}
	return {"text": "", "code": str(r.get("code", ""))}

# --- Owner #81, #82, #85: better together (module 0.2.18: server/modules/src/server/together.ts) ---
# Friends' side of learning: the days this child learned and the units mastered go up (social_learned: friendship days,
# study buddies, the crew's week), proud moments go to friends to cheer (social_moment), and the FRIENDS page reads and
# does the rest (social_info, social_cheer, presents, study buddies, crews). What the profile keeps for the server
# (SocialData) goes at the next sign-in; news arrive with note 109 and show on the main menu's card once (invite_news,
# "what": "text"). Only ids and kinds are sent: nothing personal.

const SOCIAL_NOTE := 109
## The server's answers about the thing itself (anything else is the network: it keeps waiting).
const SOCIAL_REFUSALS: Array[String] = ["bad_request", "too_many_today", "not_allowed_online", "not_found"]

## The FRIENDS page's data changed on the server (a nudge came, or a call changed it).
signal social_changed

## The last social_info answer ({} until read).
var social_state := {}


func _soc_signed_in() -> void:
	if not backend.notified.is_connected(_soc_on_notified):
		backend.notified.connect(_soc_on_notified)
	if not social_allowed():
		return
	await send_social_events()
	await refresh_social_news()


func _soc_on_notified(code: int, _content: String, _sender_id: String) -> void:
	if code == SOCIAL_NOTE and social_allowed():
		social_changed.emit()
		await refresh_social_news()


## The FRIENDS page's data: {"text": "" or words, "allowed", "friends", "feed", "presents", "link_gifts", "news",
## "crew", "crew_invites", "sends_left", "cheers_left", "rules"} (together.ts documents each). `seen`: the news are
## shown now (the server forgets them).
func social_info(seen: bool = false) -> Dictionary:
	if status != ONLINE or backend == null:
		return {"text": OnlineRules.message("not_signed_in")}
	var r: Dictionary = await backend.call_rpc("social_info", {"seen": true} if seen else {})
	if not r.get("ok", false):
		return {"text": OnlineRules.message(str(r.get("error", "")))}
	r.erase("ok")
	r.text = ""
	social_state = r
	return r


## Tells the server what it has not heard: the days learned and units mastered, then the moments for friends.
func send_social_events() -> void:
	if status != ONLINE or backend == null or not social_allowed():
		return
	var changed := false
	for payload in profile.social.learned_to_send():
		var r: Dictionary = await backend.call_rpc("social_learned", payload)
		if not r.get("ok", false) and not SOCIAL_REFUSALS.has(str(r.get("error", ""))):
			break   # the network: it waits for the next sign-in
		profile.social.mark_learned_sent(payload)
		changed = true
	for m: Dictionary in profile.social.moments.duplicate(true):
		var r: Dictionary = await backend.call_rpc("social_moment", m)
		if not r.get("ok", false) and not SOCIAL_REFUSALS.has(str(r.get("error", ""))):
			break
		profile.social.mark_moment_sent(m)
		changed = true
	if changed:
		save_profile.call()


## Reads the friends' news the server kept (shown now: the server forgets them) onto the main menu's card.
func refresh_social_news() -> void:
	var r := await social_info(true)
	if r.text != "":
		return
	var gold := 0
	var got := false
	for n: Variant in r.get("news", []):
		if not n is Dictionary:
			continue
		var words := FriendshipRules.news_words(n)
		if words == "":
			continue
		var paid := maxi(int((n as Dictionary).get("gold", 0)), 0)
		invite_news.append({"what": "text", "text": words, "gold": paid})
		gold += paid
		got = true
	if gold > 0:
		await sync_wallet()
	if got:
		invite_news_arrived.emit()


## A kind word for a friend's moment (FriendshipRules.CHEERS). "" or plain words.
func send_cheer(moment_id: String, cheer: String) -> String:
	var r := await _soc_call("social_cheer", {"moment_id": moment_id, "cheer": cheer})
	return str(r.text)


## A present for a friend: {"text", "sends_left"}.
func send_present(friend_id: String, kind: String) -> Dictionary:
	return await _soc_call("present_send", {"user_id": friend_id, "kind": kind})


## A present that waits on this child's invite code for the next new friend: {"text", "waiting", "sends_left"}.
func send_link_present(kind: String) -> Dictionary:
	return await _soc_call("present_send", {"link": true, "kind": kind})


## Opens a present into the profile (FriendPresents.open; saved): {"text", "kind", "name", "gave" (what it gave, in words)}.
func open_present(present_id: String) -> Dictionary:
	var r := await _soc_call("present_open", {"id": present_id})
	if r.text != "":
		return r
	r.gave = FriendPresents.open(profile, str(r.get("kind", "")))
	save_profile.call()
	return r


## THANK YOU for an opened present: the sender gets a small gift (the server's gold). "" or plain words.
func thank_present(present_id: String) -> String:
	var r := await _soc_call("present_thank", {"id": present_id})
	return str(r.text)


## "ask", "yes", "no" or "stop" with a friend: {"text", "state"}.
func study_buddy(action: String, friend_id: String) -> Dictionary:
	return await _soc_call("study_buddy", {"action": action, "user_id": friend_id})


## A crew action ("make" {adjective, noun, badge}, "invite" {user_id}, "join" {crew}, "decline" {crew}, "leave"): this
## child's look goes with make and join. {"text", "crew"?}.
func crew_action(action: String, payload: Dictionary = {}) -> Dictionary:
	var p := payload.duplicate()
	p.action = action
	if action in ["make", "join", "look"]:
		p.look = crew_look(profile.avatar)
	return await _soc_call("crew", p)


## The parts of a look a crew page draws (never the boy / girl choice, owner #48).
static func crew_look(look: AvatarLook) -> Dictionary:
	var d := look.to_dict()
	var out := {}
	for field: String in AvatarLook.FIELDS:
		out[field] = d.get(field, "")
	return out


func _soc_call(rpc_id: String, payload: Dictionary) -> Dictionary:
	if status != ONLINE or backend == null:
		return {"text": OnlineRules.message("not_signed_in")}
	var r: Dictionary = await backend.call_rpc(rpc_id, payload)
	if not r.get("ok", false):
		var code := str(r.get("error", ""))
		return {"text": CrewRules.error_words(code) if rpc_id == "crew" else FriendPresents.error_words(code), "error": code}
	r.erase("ok")
	r.text = ""
	social_changed.emit()
	return r

# --- Owner #99: the same name on a new device, with proof; LOG OUT and LOG IN (spec §5.13 "As built (owner #99)"; module
# 0.2.20: server/modules/src/server/moves.ts) ---
# A taken name asks whether it is the child's own, from another device (UsernameClaim); YES opens MOVE YOUR GAME HERE
# (MoveGamePage): this device asks the server for that account (move_start) and shows the 6-digit code it gets. On the
# account's own devices the card "Someone wants to play as Anna on a computer." (MoveAskCard over every scene, from
# move_asks) lets a grown-up type that code (move_approve, behind the parent gate). The approved ask hands this device a
# one-time key (move_status) and move_sign_in does the rest (this device plays as the account; the move rests). The old
# device is logged out (one device at a time) after it hears "Your game is on a computer now too." (move_news). LOG OUT
# first saves everything to the account (save_for_log_out).
# The lead's security review (2026-10-15): this device is never told whether the account's devices are online or what
# they did; it waits until the code's 5 minutes are over.

## The asks for this account from other devices changed (move_asks).
signal move_asks_changed
## This account's game is on another device now too: the words for the card ("Your game is on a computer now too.").
signal move_news(text: String)
## The server changed this device's own ask (notification 110 "approved"): look at it now (move_status).
signal move_nudged(what: String)

## Asks for this account from other devices, open now: [{"id", "kind", "left_s", "until_msec"}] (DeviceMoveRules.asks_from).
var move_asks: Array[Dictionary] = []
## The card over every scene for move_asks and move_news (MoveAskCard; tests: false).
var move_card := true
var _mv_layer: CanvasLayer


## After signing in: the asks for this account waiting on the server (an old device that comes online sees them).
func _mv_signed_in() -> void:
	if not backend.notified.is_connected(_mv_on_notified):
		backend.notified.connect(_mv_on_notified)
	await refresh_move_asks()


func _mv_on_notified(code: int, content: String, _sender_id: String) -> void:
	if code != DeviceMoveRules.NOTE or not DeviceMoveRules.enabled:
		return
	var n := DeviceMoveRules.note(content)
	match n.what:
		"asked":
			await refresh_move_asks()
		"moved":
			_mv_show_card()
			move_news.emit(DeviceMoveRules.moved_text(n.kind))
		"approved":
			move_nudged.emit(n.what)


func _mv_online() -> String:
	if status == ONLINE and backend != null:
		return ""
	var err := await sign_in()
	return err if err != "" else ("" if status == ONLINE else OnlineRules.message("not_signed_in"))


## The new device: asks the server for the account named. {"text": "" or words, "id", "code" (6 digits), "valid_s"}.
func move_start(username: String, kind: String = "") -> Dictionary:
	if not DeviceMoveRules.enabled:
		return {"text": DeviceMoveRules.MOVE_OFF}   # the quick-ship round: off for now
	var err := await _mv_online()
	if err != "":
		return {"text": err}
	var r: Dictionary = await backend.call_rpc("move_request", {"action": "start",
		"username": UsernameRules.normalize(username), "kind": kind if kind != "" else DeviceMoveRules.this_device_kind()})
	if not r.get("ok", false):
		return {"text": DeviceMoveRules.error_text(str(r.get("error", "")), int(r.get("wait", 0)))}
	var code := DeviceMoveRules.normalize_code(str(r.get("code", "")))
	var id: Variant = r.get("id", "")
	if code == "" or not (id is String) or (id as String) == "":
		return {"text": OnlineRules.message("")}
	return {"text": "", "id": id, "code": code, "valid_s": clampi(int(r.get("valid_s", DeviceMoveRules.CODE_SECONDS)), 1,
		DeviceMoveRules.CODE_SECONDS)}


## The new device: how its ask stands. {"text": "" or words (the network: keep waiting), "state": "waiting" | "approved" |
## "ended" | "done" | "", "left_s", "why", and when approved "key" (one-time) and "username" (the account's own)}.
func move_status(id: String) -> Dictionary:
	if status != ONLINE or backend == null:
		return {"text": OnlineRules.message("not_signed_in"), "state": ""}
	var r: Dictionary = await backend.call_rpc("move_request", {"action": "status", "id": id})
	if not r.get("ok", false):
		if str(r.get("error", "")) == "not_found":
			return {"text": "", "state": "ended", "why": "replaced"}
		return {"text": OnlineRules.message(str(r.get("error", ""))), "state": ""}
	var state := str(r.get("state", ""))
	var out := {"text": "", "state": state if state in ["waiting", "approved", "ended", "done"] else "",
		"left_s": int(r.get("left_s", 0)), "why": str(r.get("why", ""))}
	if state == "approved":
		out.key = str(r.get("key", ""))
		var named := str(r.get("username", ""))
		out.username = named if UsernameRules.validate(named) == "" else ""
	return out


## The new device: BACK (the ask ends; the account's card goes).
func move_cancel(id: String) -> void:
	if status == ONLINE and backend != null and id != "":
		await backend.call_rpc("move_request", {"action": "cancel", "id": id})


## The account's device: the asks waiting for it (only with an online name). "" or plain words.
func refresh_move_asks() -> String:
	if not DeviceMoveRules.enabled or status != ONLINE or backend == null or not claimed():
		_mv_set_asks([] as Array[Dictionary])
		return ""
	var r: Dictionary = await backend.call_rpc("move_approve", {"action": "list"})
	if not r.get("ok", false):
		return OnlineRules.message(str(r.get("error", "")))
	_mv_set_asks(DeviceMoveRules.asks_from(r.get("asks"), _msec()))
	return ""


## The account's device: the code a grown-up typed from the other screen. {"text": "" or words, "done" (approved: the
## game goes there now), "over" (the ask ended: the card goes), "tries_left"}.
func move_approve(id: String, code: String) -> Dictionary:
	if status != ONLINE or backend == null:
		return {"text": OnlineRules.message("not_signed_in"), "done": false, "over": false}
	var typed := DeviceMoveRules.normalize_code(code)
	var r: Dictionary = await backend.call_rpc("move_approve", {"action": "approve", "id": id, "code": typed})
	if r.get("ok", false):
		_mv_drop_ask(id)
		return {"text": DeviceMoveRules.APPROVED_HERE, "done": true, "over": true}
	match str(r.get("error", "")):
		"wrong_code":
			var left := int(r.get("tries_left", 0))
			return {"text": DeviceMoveRules.wrong_text(left), "done": false, "over": false, "tries_left": left}
		"ended", "not_found":
			_mv_drop_ask(id)
			return {"text": DeviceMoveRules.ENDED_HERE, "done": false, "over": true}
	return {"text": OnlineRules.message(str(r.get("error", ""))), "done": false, "over": false}


## The account's device: NOT ME (the ask ends). "" or plain words.
func move_decline(id: String) -> String:
	if status != ONLINE or backend == null:
		return OnlineRules.message("not_signed_in")
	var r: Dictionary = await backend.call_rpc("move_approve", {"action": "decline", "id": id})
	if not r.get("ok", false) and str(r.get("error", "")) != "not_found":
		return OnlineRules.message(str(r.get("error", "")))
	_mv_drop_ask(id)
	return ""


func _mv_set_asks(list: Array[Dictionary]) -> void:
	if list == move_asks:
		return
	move_asks = list
	if not move_asks.is_empty():
		_mv_show_card()
	move_asks_changed.emit()


func _mv_drop_ask(id: String) -> void:
	var kept: Array[Dictionary] = []
	for a in move_asks:
		if a.id != id:
			kept.append(a)
	_mv_set_asks(kept)


## Asks whose code is over go from the list (each frame; nothing to do most of the time).
func _mv_prune() -> void:
	if move_asks.is_empty():
		return
	var now := _msec()
	var kept: Array[Dictionary] = []
	for a in move_asks:
		if int(a.until_msec) > now:
			kept.append(a)
	if kept.size() != move_asks.size():
		_mv_set_asks(kept)


## The card over every scene, made the first time it is needed (MoveAskCard follows move_asks and move_news itself).
func _mv_show_card() -> void:
	if not DeviceMoveRules.enabled or not move_card or _mv_layer != null or not is_inside_tree():
		return
	_mv_layer = CanvasLayer.new()
	_mv_layer.name = "MoveAskLayer"
	_mv_layer.layer = 92   # over every menu, the HUD and the invite toast
	_mv_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	UiLayers.route(_mv_layer, self)   # owner #101: in VR on the panel (the VR canvas)
	var card := MoveAskCard.new()
	card.service = self
	_mv_layer.add_child(card)


## LOG OUT's first step: everything of this player is on the server (the profile backup written, the gold synced and
## equal to what the server took, no gold report or code waiting), because LOG OUT then forgets the player on this device.
## "" when it is (or when there is no online account to save to); else the words, and LOG OUT stops: offline
## (DeviceMoveRules.OFFLINE), the server's hourly gold cap took less (DeviceMoveRules.GOLD_ON_ITS_WAY: try again in an
## hour), anything else not saved, a refused backup too (DeviceMoveRules.NOT_SAVED).
func save_for_log_out() -> String:
	if status != ONLINE:
		if not has_online_link():
			return ""
		if await sign_in() != "" or status != ONLINE:
			return DeviceMoveRules.OFFLINE
	if not claimed():
		return ""
	await send_wallet_report()
	while (_f_paying > 0 or _f_syncing) and status == ONLINE:
		await _f_pause(0.1)
	var err := await profile_sync.save_now()
	if err != "":   # the final review's 1: a refused backup (too_big, bad_profile, not_allowed) is NOT saved either
		return DeviceMoveRules.OFFLINE if status != ONLINE else DeviceMoveRules.NOT_SAVED
	err = await sync_wallet(true)
	while (_f_paying > 0 or _f_syncing) and status == ONLINE:
		await _f_pause(0.1)   # a sync already on its way, or a guest's wait for its host's last batch
	if status != ONLINE:
		return DeviceMoveRules.OFFLINE
	if err != "" or pending_reports() > 0 or not profile.codes_unsettled.is_empty():
		return DeviceMoveRules.NOT_SAVED
	# Every coin is on the server only when the phone's gold equals what the server took (the wallet marker)
	var marker := WalletSync.marker_of(_f_wallet_path(), backend.user_id())
	if profile.survivor_gold != marker:
		return DeviceMoveRules.GOLD_ON_ITS_WAY if _f_report_capped and profile.survivor_gold > marker \
			else DeviceMoveRules.NOT_SAVED
	return ""


## Another session is this device's now (LOG IN, LOG OUT, DELETE: forget_player, _become): nothing of the last
## player stays in memory, and the next sign_in is the new player's (its own device id file, its own prefs and books).
func forget_session() -> void:
	session += 1   # every coroutine of the last player's session stops before it writes (_stale)
	has_password = -1   # owner #105
	logged_out = false
	_lo_hide_card()
	if backend:
		backend.sign_out()
	_went_offline()
	account = {}
	_blocked.clear()
	prefs = OnlinePrefs.load_from(prefs_path)
	_f_reports.clear()
	_f_report_match.clear()
	_f_host_wait = {}
	_f_gold_read_at = -1
	wallet_reported = 0
	profile_sync.reset()
	gifts.clear()
	bottles.clear()
	new_stickers = 0
	gift_book = null
	if gift_book_path == "":
		GiftStampBook.use(null)   # read again from the new player's file
	ghost_book = null
	if ghost_book_path == "":
		GhostBook.use(null)
	invite_news.clear()
	invite_state = {}
	social_state = {}
	move_asks.clear()
	account_changed.emit()
	friends_changed.emit()
	gifts_changed.emit()
	ghosts_changed.emit()
	move_asks_changed.emit()

# --- Owner #105: the password, LOG IN with it, one device at a time (spec §5.13 "As built (owner #99, #105)"; module
# 0.2.20: server/modules/src/server/passwords.ts) ---
# "when starting playing create a password. so when logging in another device you can use password and username again to
# login, but if you login another device you should logout automatically from old device". The password is made right
# after the name is claimed (make_password), asked once of an account that has none (needs_password), changed with the
# old one or a grown-up's key (change_password). LOG IN (log_in_with_password) asks the server with this device's own
# asking credential (login_device_path, never a player's), and the server links a new id of this device to the account
# and logs every other device out. A device whose link went that way hears it at its next sign-in (create=false: no
# account with its id): logged_out, "You logged in on another device. LOG IN to play here."; it never makes a new
# account by itself, and everything played here stays in its files for the next log-in's merge.

## This player's account was logged in on another device (this device's link is gone): LOG IN to play here.
signal logged_out_elsewhere
## A new device tried this account's password (the server says it at most once an hour): the words to show.
signal tried_note(text: String)

## The server's notification of a new device's wrong try (Passwords.NOTE).
const PASSWORD_NOTE := 112

## This player's link is gone (another device logged in), until the next LOG IN here.
var logged_out := false
## Whether the account has a password (password_state at every sign-in; -1 unknown).
var has_password := -1
## This device's own credential for asking the server to LOG IN (a device file, never an account's: LOG OUT leaves it);
## "" = beside prefs_path (user://login_device.json in the game).
var login_device_path := ""
## The card over every scene for logged_out (LoggedOutCard; tests: false).
var logged_out_card := true
var _lo_layer: CanvasLayer
var _pw_preparing := false   # prepare_log_in's asking account is being made (a LOG IN waits for it: one sign-in per id)


func _pw_signed_in() -> void:
	_pw_note_name()
	if not backend.notified.is_connected(_pw_on_notified):
		backend.notified.connect(_pw_on_notified)
	await _pw_read_state()


## The account's password state: whether it has one, and a new device's wrong try it has not told this player of yet.
func _pw_read_state() -> void:
	if not claimed():
		return
	var s := session
	var r := await password_state()
	if s != session or str(r.get("text", "")) != "":
		return
	has_password = 1 if r.get("has_password", false) else 0
	var tried := int(r.get("tried_ms", 0))
	if tried > prefs.tried_seen:
		prefs.tried_seen = tried
		prefs.save_to(prefs_path)
		tried_note.emit(PasswordRules.TRIED)
		_lo_show_card(PasswordRules.TRIED)


func _pw_on_notified(code: int, _content: String, _sender_id: String) -> void:
	if code == PASSWORD_NOTE:
		await _pw_read_state()


## This player has an online name here: kept in its prefs, so a gone link is "logged out", never a new account.
func _pw_note_name() -> void:
	var name := str(account.get("username", ""))
	var uid := backend.user_id() if backend else ""
	if claimed() and UsernameRules.validate(name) == "" and (prefs.account_name != name or prefs.account_id != uid):
		prefs.account_name = name
		prefs.account_id = uid   # the final review's 7: "the same account" is known by its id
		prefs.save_to(prefs_path)


func _pw_logged_out() -> void:
	logged_out = true
	if prefs.account_name == "" and profile.username != "":
		prefs.account_name = profile.username   # an old profile (no kept name): LOG IN prefills it from the profile
		prefs.save_to(prefs_path)
	if backend:
		backend.sign_out()
	logged_out_elsewhere.emit()
	_lo_show_card()


## Whether PLAY ONLINE asks this player to make a password now (an account with a name and none; asked once).
func needs_password() -> bool:
	return status == ONLINE and claimed() and has_password == 0 and prefs.password_asked <= 0


func mark_password_asked() -> void:
	prefs.password_asked = _now()
	prefs.save_to(prefs_path)


## {"text": "" or words, "has_password"}.
func password_state() -> Dictionary:
	if status != ONLINE or backend == null:
		return {"text": OnlineRules.message("not_signed_in"), "has_password": false}
	var r: Dictionary = await backend.call_rpc("password", {"action": "state"})
	if not r.get("ok", false):
		return {"text": OnlineRules.message(str(r.get("error", ""))), "has_password": false}
	return {"text": "", "has_password": r.get("has_password") == true, "tried_ms": int(r.get("tried_ms", 0))}


## The account's first password (typed twice; the rules checked here and again on the server). "" or plain words.
func make_password(text: String, again: String) -> String:
	var problem := PasswordRules.problem_twice(text, again, str(account.get("username", profile.username)))
	if problem != "":
		return PasswordRules.message(problem)
	if status != ONLINE or backend == null:
		return OnlineRules.message("not_signed_in")
	var r: Dictionary = await backend.call_rpc("password", {"action": "set", "password": text})
	if not r.get("ok", false):
		return PasswordRules.error_text(str(r.get("error", "")), int(r.get("wait", 0)))
	has_password = 1
	return ""


## A new password, with the old one or a grown-up's key (FORGOT PASSWORD: `use_new_key` makes a NEW key on this device, a
## grown-up's step on a device still signed in, and uses it to prove it). Returns {"text": "" or plain words, "new_key":
## the key it made, when it made one}. Owner #105 (the second review's finding 7): making a new key stops the old
## written-down one, so the grown-up is shown the new key (never a silent swap).
func change_password(text: String, again: String, old: String = "", use_new_key: bool = false) -> Dictionary:
	var problem := PasswordRules.problem_twice(text, again, str(account.get("username", profile.username)))
	if problem != "":
		return {"text": PasswordRules.message(problem)}
	if status != ONLINE or backend == null:
		return {"text": OnlineRules.message("not_signed_in")}
	var payload := {"action": "change", "password": text}
	var new_key := ""
	if use_new_key:
		var made: Dictionary = await make_account_key()
		if str(made.get("text", "")) != "":
			return {"text": str(made.text)}
		new_key = str(made.get("key", ""))
		payload.key = new_key
	else:
		payload.old = old
	var r: Dictionary = await backend.call_rpc("password", payload)
	if not r.get("ok", false):
		return {"text": PasswordRules.error_text(str(r.get("error", "")), int(r.get("wait", 0)), true)}
	has_password = 1
	return {"text": "", "new_key": new_key}


## LOG IN: asks the server with this device's own asking credential (the player playing now signs out first); the
## server links a NEW id of this device to the account named and logs its other devices out. {"text": "" or words,
## "device_id" (the credential this device plays as that account with: _become keeps it),
## "username"}. Never a new account for anyone: the asking one is this device's own, and the server deletes it.
func log_in_with_password(username: String, password: String) -> Dictionary:
	var known_device := device_id if device_id != "" else _pw_read_id(device_id_path)
	var r := await _ask_to_log_in("sign_in_with_password", {"username": UsernameRules.normalize(username),
		"password": password, "known_device": known_device})
	if str(r.get("text", "")) != "":
		return r
	var answer: Dictionary = r.answer
	if not answer.get("ok", false):
		return {"text": PasswordRules.error_text(str(answer.get("error", "")), int(answer.get("wait", 0)))}
	return {"text": "", "device_id": r.device_id, "username": str(answer.get("username", username)),
		"user_id": str(answer.get("user_id", ""))}


## LOG IN's ask (`rpc_name` with `payload`: the password, or a grown-up's key), on a second connection with this device's
## own asking credential (login_device.json), so it works whatever this device's own account state is (logged out
## too). {"text": words} when it could not ask; else {"text": "", "answer": the server's answer, "device_id": the NEW id
## the server links when the answer is ok}.
func _ask_to_log_in(rpc_name: String, payload: Dictionary) -> Dictionary:
	if backend == null or not has_server():
		return {"text": OnlineRules.message("no_server")}
	while _pw_preparing and is_inside_tree():   # LOG IN opened a moment ago: its asking account is on its way
		await get_tree().process_frame
	var twin := _pw_twin()   # its own connection: the player playing now plays on until the log-in worked
	var spare := DeviceId.load_or_create(_login_path())
	var s := session
	var signed: Dictionary = await twin.sign_in(server, spare, true)
	var gone := str(signed.get("error", "")) in ["account_gone", "device_logged_out"]
	if s == session and not signed.get("ok", false) and twin != backend and gone:
		# The asking id's account is gone (a 404 or a 403, never another failure: the final review's 6). Remake
		# login_device.json with a fresh id and try once more, so LOG IN never stays broken.
		DirAccess.remove_absolute(_login_path())
		spare = DeviceId.load_or_create(_login_path())
		signed = await twin.sign_in(server, spare, true)
	if s != session or not signed.get("ok", false):
		_pw_drop(twin)
		return {"text": OnlineRules.message("not_signed_in" if s != session else str(signed.get("error", "")))}
	var new_id := DeviceId.generate()
	var ask := payload.duplicate()
	ask.device_id = new_id
	var r: Dictionary = await twin.call_rpc(rpc_name, ask)
	for _wait in 2:   # a brand-new asking account waits a moment (prepare_log_in makes it early)
		if str(r.get("error", "")) != "too_new" or not is_inside_tree():
			break
		await get_tree().create_timer(clampf(float(r.get("wait", 5)), 1.0, 30.0)).timeout
		if s != session:
			break
		r = await twin.call_rpc(rpc_name, ask)
	_pw_drop(twin)
	if s != session:
		return {"text": OnlineRules.message("not_signed_in")}
	return {"text": "", "answer": r, "device_id": new_id}


## Another connection for asking on the side (the backend's twin), or this one when it has none (tests' own backends).
func _pw_twin() -> OnlineBackend:
	var t := backend.make_twin()
	if t == null:
		return backend
	t.name = "AskingLink"
	add_child(t)
	return t


func _pw_drop(t: OnlineBackend) -> void:
	t.sign_out()
	if t != backend:
		t.queue_free()


## LOG IN opened: this device's asking account is made now (if it has none yet), so it is old enough by the time the
## name and the password are typed (the server makes a brand-new one wait a moment). Nothing else happens.
func prepare_log_in() -> void:
	if backend == null or not has_server() or FileAccess.file_exists(_login_path()) or _pw_preparing:
		return
	var twin := _pw_twin()
	if twin == backend:
		return   # no second connection here: the log-in waits its moment instead
	_pw_preparing = true
	await twin.sign_in(server, DeviceId.load_or_create(_login_path()), true)
	_pw_drop(twin)
	_pw_preparing = false


## LOG IN with the name and the password (the start screen, PLAY ONLINE's I HAVE AN ACCOUNT, a taken name's "Is it you?",
## a logged-out device). The server links a new id of this device and logs every other device out; this device plays as
## the account from now on. "" or plain words.
func log_in(username: String, password: String) -> String:
	if busy():
		return DeviceMoveRules.SWITCH_BUSY
	var r := await log_in_with_password(username, password)
	if str(r.get("text", "")) != "":
		return str(r.text)
	return await _become(str(r.device_id), str(r.get("username", username)), str(r.get("user_id", "")))


## The final review's 2: whose gold and progress on this device LOG IN as `typed` would make go — this device's player
## when it is a guest with progress (never claimed: nothing of it is on a server) or a player logged out of another
## account (what was played here since) — or "" (nothing goes: a new player, or the same account as before, which keeps
## what was played here: _become). LOG IN and the key's SIGN IN ask first then: GUEST_GOES, YES / NO.
func progress_goes(typed: String) -> String:
	var name := UsernameRules.normalize(typed)
	if prefs.account_id != "" and prefs.account_name != "" and name.to_lower() == prefs.account_name.to_lower():
		return ""   # the same account (by its name here; _become checks its id)
	if not DeviceMoveRules.has_progress(profile):
		return ""
	var who := prefs.account_name if prefs.account_name != "" else profile.username
	return who if who != "" else "This player"


## This device plays as the account LOG IN linked (`id`). The same account it played as before (logged out by another
## device) keeps what was played here; any other account (or none: a new player) starts from a fresh player — this
## device's account files are forgotten and the profile is a new player's that takes the account's gold as the server
## has it (_adopt_server_gold: its start gold is never reported; the worlds stay) — so nothing of this device's player
## ever merges into that account and gold can't double. The LOG IN page asked first when this player had progress
## (progress_goes). Then it signs in: the
## account's profile backup comes down (name, progress, looks, gold). "" or plain words.
func _become(id: String, named: String, user_id: String = "") -> String:
	# The same account as before is known by its user id (the final review's 7), never by a name another account may
	# have claimed since; prefs from before this build have no id: a fresh start (nothing ever merges by mistake).
	var same := user_id != "" and prefs.account_id != "" and user_id == prefs.account_id
	var by_var := device_id != ""   # tests give their service its id (no file)
	if same:
		forget_session()
	else:
		var card := prefs.safe_card_seen
		forget_online()
		_fresh_profile()
		forget_session()
		if card > 0:
			prefs.safe_card_seen = card   # the stay-safe card was seen on this device already
			prefs.save_to(prefs_path)
		_adopt_server_gold = true   # the final review's 4: the fresh player's start gold is not reported as earned
	if by_var:
		device_id = id
	var err := keep_device_id(id)
	if err != "":
		return err
	if not same and UsernameRules.validate(named) == "":
		profile.username = named   # the account's name at once (its backup brings the rest)
		save_profile.call()
	return await sign_in()


## LOG OUT (the final review's simple model; no grown-up's step). The game is saved to the account first (offline: the
## words to connect); the account must have a password ("password_needed": make one first, so you can log back in);
## then this device is unlinked on the server, and this device forgets the account (its device id, online prefs, wallet
## markers, friends' presents and races) and the player (a fresh new-player profile; the worlds stay). The account is safe
## on the server: LOG IN brings it back. "", "password_needed", or plain words.
func log_out() -> String:
	if busy():
		return DeviceMoveRules.SWITCH_BUSY
	var saved := await save_for_log_out()
	if saved != "":
		return saved
	if status != ONLINE or not claimed():
		return DeviceMoveRules.NO_ACCOUNT
	if has_password != 1:
		var st := await password_state()
		if str(st.get("text", "")) != "":
			return str(st.text)
		if not st.get("has_password", false):
			return LOG_OUT_NEEDS_PASSWORD
	var mine := device_id if device_id != "" else _pw_read_id(device_id_path)
	var r: Dictionary = await backend.call_rpc("log_out", {"device_id": mine})
	if not r.get("ok", false):
		var code := str(r.get("error", ""))
		return LOG_OUT_NEEDS_PASSWORD if code == "password_needed" else OnlineRules.message(code)
	forget_player()
	return ""


const LOG_OUT_NEEDS_PASSWORD := "password_needed"


## This device forgets the account and the player (LOG OUT, DELETE, NEW PLAYER on a logged-out device): its account files
## go and the profile is a fresh new player's (the worlds stay: they belong to the device).
func forget_player() -> void:
	_adopt_server_gold = false   # a new player claims its own account: its first sync reports as ever
	forget_online()
	_fresh_profile()
	forget_session()


## Makes the profile a fresh new player's (tests: `reset_profile`; the game: the profile file goes and Profile.reload()
## reads a new player into the same object every screen holds, keeping this device's own settings).
var reset_profile := Callable()


func _fresh_profile() -> void:
	if reset_profile.is_valid():
		reset_profile.call()
		return
	if profile != Profile.data:
		ProfileBackup.copy_into(profile, ProfileData.new())
		save_profile.call()
		return
	for c: String in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(Profile.path + c):
			DirAccess.remove_absolute(Profile.path + c)
	Profile.reload()


## The player playing now plays as the account its LOG IN linked (`id`): its credential from now on. "" or words.
func keep_device_id(id: String) -> String:
	var err := _o67_keep_device_id(id)
	if err == "":
		logged_out = false
		_lo_hide_card()
	return err


func _login_path() -> String:
	return login_device_path if login_device_path != "" else prefs_path.get_base_dir().path_join("login_device.json")


static func _pw_read_id(path: String) -> String:
	var json := JSON.new()
	var text := JsonStore.read_text(path)
	if text == "" or json.parse(text) != OK or not (json.data is Dictionary):
		return ""
	var id := str((json.data as Dictionary).get("device_id", ""))
	return id if DeviceId.is_valid(id) else ""


## The card over every scene, made the first time it is needed: LOGGED_OUT (LOG IN) or another note (OK).
func _lo_show_card(text: String = PasswordRules.LOGGED_OUT) -> void:
	if not logged_out_card or not is_inside_tree():
		return
	if _lo_layer == null:
		_lo_layer = CanvasLayer.new()
		_lo_layer.name = "LoggedOutLayer"
		_lo_layer.layer = 93
		_lo_layer.process_mode = Node.PROCESS_MODE_ALWAYS
		UiLayers.route(_lo_layer, self)   # owner #101: in VR on the panel (the VR canvas)
		var card := LoggedOutCard.new()
		card.service = self
		_lo_layer.add_child(card)
	(_lo_layer.get_child(0) as LoggedOutCard).show_text(text)
	_lo_layer.visible = true


func _lo_hide_card() -> void:
	if _lo_layer != null:
		_lo_layer.visible = false
