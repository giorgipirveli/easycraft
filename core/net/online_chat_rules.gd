class_name OnlineChatRules
extends RefCounted
## Online chat as pure rules (M4 Wave 2, Agent E; spec §5.13, §17.2, §17.4): friends' direct
## messages and a team room per online match, over Nakama channels. The server's hooks decide what
## may be sent (server/modules/src/server/chat.ts: DMs between friends, the room of a match the
## player is in, the strictest chat level of the channel's players); these rules decide what a child
## sees and may try. Content is {"text"} or {"emote"}, as the server takes it.
## - The quick-chat wheel: eight picture phrases from the server's quick phrases (everyone may use
##   it; under-13 players only have the wheel and emotes).
## - Messages from the network are read carefully: only Nakama's plain chat messages, exactly one
##   field, a real emote id, a name that is a username, and never free text for an under-13 reader.
## - History: 13+ only, the last HISTORY_DAYS; nothing is kept for under-13.

const TYPE_ROOM := 1                 # Nakama's channel types
const TYPE_DM := 2
const HISTORY_DAYS := 30
const HISTORY_COUNT := 50            # messages read back when a DM opens (13+)
const SOMEONE := "A friend"          # a sender name that is not a username
## The quick-chat wheel, clockwise from the top: each one of ChatRules.QUICK_PHRASES (the server's).
const WHEEL: Array[String] = ["Hi!", "Follow me!", "Look!", "Help!", "Thanks!", "Good job!", "Let's build!", "Bye!"]
## The picture on each wheel slot (ChatPictures).
const PICTURES := {
	"Hi!": &"hi", "Follow me!": &"follow", "Look!": &"look", "Help!": &"help", "Thanks!": &"thanks",
	"Good job!": &"star", "Let's build!": &"build", "Bye!": &"bye",
}

const _MESSAGES := {
	"chat_off": "A grown-up turned chat off.",
	"friend_chat_off": "Your friend can't chat right now.",
	"not_friends": "You can chat with your friends only.",
	"room_not_allowed": "Team chat opens when you play together.",
	"not_in_channel": "This chat is closed now.",
	"bad_message": "That message can't be sent. Try another one!",
	"not_ready": "Chat is not ready yet. Try again soon!",
	# M4 Task 10 review B: online, the team room is not open (typed words wait for it; quick phrases still go)
	"chat_resting": "Chat is resting for now. Quick phrases still work!",
}

static var _emote_re := RegEx.create_from_string("^[a-z0-9_]{1,32}$")
static var _time_re := RegEx.create_from_string("^(\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2})")


## The chat an account may use now (the server's AccountRules.chatLevel): off unless it may play
## online with friends (OnlineRules.social_allowed) and chat is on; never above quick for under-13.
static func chat_level(acct: Dictionary) -> String:
	if not OnlineRules.social_allowed(acct):
		return OnlineRules.CHAT_OFF
	var chat := str(acct.get("chat", OnlineRules.CHAT_OFF))
	if chat not in [OnlineRules.CHAT_QUICK, OnlineRules.CHAT_FILTERED]:
		return OnlineRules.CHAT_OFF
	if acct.get("age_band") != AgeBand.TEEN_PLUS:
		return OnlineRules.CHAT_QUICK
	return chat


## Free text (a keyboard) only at the filtered level: 13+ with a grown-up's text setting. Everyone
## else has the quick-chat wheel and emotes.
static func can_type(acct: Dictionary) -> bool:
	return chat_level(acct) == OnlineRules.CHAT_FILTERED


## Chat history is kept for 13+ only (§17.2): an under-13 player's messages are never stored.
static func keeps_history(band: StringName) -> bool:
	return band == AgeBand.TEEN_PLUS


## What this player may send at `level`: {"content": {"text"}} or {"error": code}. The server checks
## the channel's level again (the strictest of its players').
static func check_send(text: String, level: String) -> Dictionary:
	if level not in [OnlineRules.CHAT_QUICK, OnlineRules.CHAT_FILTERED]:
		return {"error": "chat_off"}
	var r := ChatRules.check(text, AgeBand.TEEN_PLUS if level == OnlineRules.CHAT_FILTERED else AgeBand.UNDER_13)
	return {"error": r.error} if r.has("error") else {"content": {"text": r.text}}


## An emote as channel content, or {} when it is not one of the game's emotes.
static func emote_content(emote: StringName) -> Dictionary:
	return {"emote": String(emote)} if is_emote(String(emote)) else {}


static func is_emote(id: String) -> bool:
	return _emote_re.search(id) != null and AvatarCatalog.has_item(AvatarCatalog.EMOTE, id)


## A message from the server (Nakama's channel message fields: channel_id, message_id, sender_id,
## username, content (JSON text), create_time, code) as {id, channel_id, from_id, from, text, emote,
## mine, time}, or {} when it is not a plain chat message this reader may see.
static func parse(raw: Dictionary, my_id: String, reader_band: StringName) -> Dictionary:
	if int(raw.get("code", 0)) != 0:
		return {}
	var json := JSON.new()   # JSON.parse_string logs an engine error for bad input
	var content: Variant = raw.get("content", "")
	if not (content is String) or json.parse(content) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	var d: Dictionary = json.data
	if d.size() != 1:
		return {}
	var text := ""
	var emote: StringName = &""
	if d.get("text") is String:
		text = ChatRules.clean(d.text)
		if text == "" or not ChatRules.can_receive(text, ChatRules.effective_band(reader_band)):
			return {}
	elif d.get("emote") is String and is_emote(d.emote):
		emote = StringName(d.emote)
	else:
		return {}
	var sender := str(raw.get("sender_id", ""))
	var name := str(raw.get("username", ""))
	return {"id": str(raw.get("message_id", "")), "channel_id": str(raw.get("channel_id", "")), "from_id": sender,
		"from": name if UsernameRules.validate(name) == "" else SOMEONE, "text": text, "emote": emote,
		"mine": sender != "" and sender == my_id, "time": unix_time(str(raw.get("create_time", "")))}


## The line a message shows as: "Pip: Hi!" or "Pip: *Wave*".
static func line(msg: Dictionary) -> String:
	var what: String = msg.get("text", "")
	if msg.get("emote", &"") != &"":
		what = "*%s*" % AvatarCatalog.display_name(AvatarCatalog.item_id(AvatarCatalog.EMOTE, msg.emote))
	return "%s: %s" % [msg.get("from", SOMEONE), what]


## Messages from the last HISTORY_DAYS.
static func recent(messages: Array[Dictionary], now_unix: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for m in messages:
		if now_unix - int(m.get("time", 0)) <= HISTORY_DAYS * 86400:
			out.append(m)
	return out


## Nakama's time ("2026-09-24T12:00:00Z", maybe with fractions) as unix seconds; 0 if unreadable.
static func unix_time(text: String) -> int:
	var m := _time_re.search(text)
	return int(Time.get_unix_time_from_datetime_string(m.get_string(1))) if m else 0


## The team room of an online match: the relayed match id itself ("<uuid>.", the server's rule), or "".
static func team_room(match_id: String) -> String:
	var id := OnlineConfig.normalize_match_id(match_id)
	return id if id.ends_with(".") and id.count(".") == 1 else ""


## Plain, kind words for a chat refusal (the chat filter's own words first).
static func message(code: String) -> String:
	var own := ChatRules.message(code)
	if own != "":
		return own
	if _MESSAGES.has(code):
		return _MESSAGES[code]
	return OnlineRules.message(code)
