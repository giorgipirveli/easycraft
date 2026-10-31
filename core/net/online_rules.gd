class_name OnlineRules
extends RefCounted
## Pure rules of online play with friends (M4 Wave 1, Agent C; spec §5.13-5.14, §17.1-17.3): the
## account read from the server's answer, who may play with friends (verified parental consent
## first for under-13, §17.2), which PLAY ONLINE screen shows, invites (notification 101/102) and
## every error in plain, kind words. The server checks all of it again (Agent B's RPCs and hooks):
## these rules only decide what a child sees, never what the server allows.

const CONSENT_NONE := "none"
const CONSENT_PENDING := "pending"
const CONSENT_VERIFIED := "verified"
const CHAT_OFF := "off"
const CHAT_QUICK := "quick"         # the quick-chat wheel and emotes (under-13, §5.13)
const CHAT_FILTERED := "filtered"   # filtered free text (13+)

## Nakama notification codes: ours (plan Wave 1) and Nakama's own friend ones.
const INVITE := 101
const INVITE_CANCELLED := 102
const PARENT_APPROVED := 103
const REMOVED := 107            # {"match_id"}: the host took this player out of its world (spec §17.3)
const FRIEND_REQUEST := -2
const FRIEND_ACCEPTED := -3

## Nakama's friend states 0-3.
const FRIEND := &"friend"
const SENT := &"sent"          # I asked them
const RECEIVED := &"received"  # they asked me
const BLOCKED := &"blocked"

const SCREEN_ASK_GROWNUP := &"ask_grownup"     # under-13, no consent yet: "Ask a grown-up"
const SCREEN_WAIT_GROWNUP := &"wait_grownup"   # consent asked, not verified yet
const SCREEN_PARENT_OFF := &"parent_off"       # a grown-up keeps online play off
const SCREEN_SAFE_CARD := &"safe_card"         # the "stay safe online" card
const SCREEN_CLAIM := &"claim"                 # claim the profile's username on the server
const SCREEN_HOME := &"home"                   # HOST MY WORLD and FRIENDS

const MAX_PLAYERS := 4                  # host and three guests (§5.13)
const SAFE_CARD_DAYS := 30              # the card again after a long break (§17.2)
## The only world names an invite shows: never free text from the network.
const WORLD_NAMES: Array[String] = ["Sandbox", "Survivor"]

## Owner #93: without the internet, what still works on this device (after every "can't reach the game").
const PLAY_ALONE := "No internet? Play alone: SANDBOX, SURVIVOR, MONSTER WAVE and SCHOOL work without it. Your gold waits safely on this device."

const _MESSAGES := {
	"": "Something went wrong. Please try again.",
	"taken": "Someone already has that name. Try another one!",
	"bad_name": "That name isn't allowed. Try another one!",
	"consent_needed": "Ask a grown-up to say yes first.",
	"not_friends": "You can only invite your friends.",
	"full": "This world is full. Four players is the most.",
	"offline": "Your friend is not online right now.",
	"no_such_player": "No player has that name. Check the spelling!",
	"self": "That's you! Type a friend's name.",
	"empty_name": "Type your friend's name first.",
	"blocked": "You can't be friends with this player.",
	"rate_limited": "Wow, that was fast! Wait a moment and try again.",
	"online_off": "A grown-up turned online play off.",
	"network": "Can't reach the game. Check the internet and try again.",
	"not_yet": "This is coming soon!",
	"no_server": "Online play is coming soon!",   # a build without a server address yet
	"no_provider": "Playing online with friends is coming soon for you!",
	"already_friends": "You are already friends!",
	"not_signed_in": "Not connected yet. Please try again.",
	"match_gone": "That world is closed now.",
	"not_invited": "Ask your friend to invite you again.",
	"not_claimed": "Pick your online name first.",
	"chat_not_allowed": "Free text chat is for 13 and up.",
	"busy": "Busy right now. Please try again.",
	# M4 Wave 2, agent F: a grown-up approves an under-13 player's friends; the profile backup
	"needs_grown_up": "Ask a grown-up to say yes in GROWN-UPS.",
	"too_big": "Your game is too big to back up.",
	# M4 Task 8b, agent G: deleting the online account (grown-ups' words)
	"confirm_expired": "That took too long. Hold the button again to delete.",
	"use_delete_account": "Delete the online account in GROWN-UPS.",
	# M4 Task 10 review C and D (module 0.2.10): the server's economy limits
	"spend_limit": "That's a lot of shopping for one hour. The rest can wait!",
	"too_many_farms": "Your farm keeps time on this phone for now.",
	# Owner #67: the account on every device (the sign-in key; grown-ups read these too)
	"wrong_key": "That name and key don't match. Check both and try again.",
	"already_claimed": "This device already has its own online name.",
	"bad_profile": "Your game could not be saved online. It is safe on this device.",
}
## Other names the server (or Nakama) may use for the same thing.
const _ALIASES := {
	"consent_required": "consent_needed", "not_found": "no_such_player", "user_not_found": "no_such_player",
	"too_many": "rate_limited", "rate_limit": "rate_limited", "parent_off": "online_off",
	"confirm_wrong": "confirm_expired",   # M4 G
	"online_not_allowed": "online_off", "match_full": "full", "world_full": "full", "unauthorized": "network",
	"not_available": "no_provider", "is_self": "self", "bad_request": "", "server": "",
	"consent_unavailable": "no_provider", "not_allowed_online": "consent_needed", "cannot_report_self": "self",
}
const _NETWORK_WORDS: Array[String] = ["socket", "sign-in", "connect", "timeout", "timed out", "no answer", "refused",
	"resolve", "unreachable", "closed"]


## The account from the server's get_account_state answer (fields at the top or under "metadata";
## plan Wave 1: age_band, consent, online_allowed, chat). Missing or odd fields fall on the safe
## side: the phone's age band (else under-13's rules), no consent, and online play off for under-13.
static func account(reply: Dictionary, local_band: StringName) -> Dictionary:
	var meta: Dictionary = reply.metadata if reply.get("metadata") is Dictionary else {}
	var band := StringName(str(_field(reply, meta, "age_band", "")))
	if not AgeBand.is_valid(band):
		band = local_band if AgeBand.is_valid(local_band) else AgeBand.UNDER_13
	var consent := str(_field(reply, meta, "consent", ""))
	if consent not in [CONSENT_NONE, CONSENT_PENDING, CONSENT_VERIFIED]:
		consent = CONSENT_NONE
	var allowed: Variant = _field(reply, meta, "online_allowed", null)
	var chat := str(_field(reply, meta, "chat", ""))
	if chat not in chat_choices(band):
		chat = CHAT_QUICK if band == AgeBand.UNDER_13 else CHAT_FILTERED
	if not AgeBand.restrictions:   # the owner, 2026-09-29: no age limits for now: 13+, online, filtered chat
		band = AgeBand.TEEN_PLUS
		allowed = true
		chat = CHAT_FILTERED
	var username: Variant = reply.get("username", "")
	var claimed: Variant = reply.get("claimed")
	var available: Variant = reply.get("consent_available")
	var gold: Variant = reply.get("gold")   # M4 F: the server's wallet (-1: an older server)
	var out := {"username": username if username is String else "", "age_band": band, "consent": consent,
		"online_allowed": allowed if allowed is bool else band == AgeBand.TEEN_PLUS, "chat": chat,
		"claimed": claimed if claimed is bool else null, "consent_available": available if available is bool else true,
		"gold": int(gold) if typeof(gold) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(gold)) and float(gold) >= 0.0 else -1}
	if reply.has("hosted"):   # module 0.2.19 (gold-double.md): the host's last word on this player's gold; none: older
		out.hosted = hosted(reply.hosted)
	return out


## Module 0.2.19's "hosted" ({"match_id", "seq"} or null) as the game keeps it: {"match_id": "", "seq": 0} for none.
static func hosted(value: Variant) -> Dictionary:
	var out := {"match_id": "", "seq": 0}
	if value is Dictionary and (value as Dictionary).get("match_id") is String:
		var seq: Variant = value.get("seq")
		if typeof(seq) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(seq)) and float(seq) >= 0.0:
			out = {"match_id": value.match_id, "seq": int(seq)}
	return out


static func _field(reply: Dictionary, meta: Dictionary, key: String, default: Variant) -> Variant:
	return reply[key] if reply.has(key) else meta.get(key, default)


## The chat settings a grown-up may pick for this age band (under-13: never free text, §5.13).
static func chat_choices(band: StringName) -> Array[String]:
	if band == AgeBand.TEEN_PLUS:
		return [CHAT_OFF, CHAT_QUICK, CHAT_FILTERED]
	return [CHAT_OFF, CHAT_QUICK]


## Friends, invites and a findable name (§17.2): under-13 only with verified consent and a grown-up's
## yes; 13+ unless a grown-up switched online play off. No account yet: nothing.
static func social_allowed(acct: Dictionary) -> bool:
	if acct.is_empty() or not bool(acct.get("online_allowed", false)):
		return false
	return acct.get("age_band") == AgeBand.TEEN_PLUS or acct.get("consent") == CONSENT_VERIFIED


## Which PLAY ONLINE screen shows: the stay-safe card, the username claim (a child's claimed name
## is not findable before consent: the server's hooks), then consent for under-13, a grown-up's
## switch, and then the home screen. The server needs the claim first: it sets the account's band.
static func screen(acct: Dictionary, claimed: bool, card_due: bool) -> StringName:
	if card_due:
		return SCREEN_SAFE_CARD
	if not claimed:
		return SCREEN_CLAIM
	if acct.get("age_band") != AgeBand.TEEN_PLUS:
		if acct.get("consent") == CONSENT_PENDING:
			return SCREEN_WAIT_GROWNUP
		if acct.get("consent") != CONSENT_VERIFIED:
			return SCREEN_ASK_GROWNUP
	if not bool(acct.get("online_allowed", false)):
		return SCREEN_PARENT_OFF
	return SCREEN_HOME


## The "stay safe online" card: before the first online game and after SAFE_CARD_DAYS away.
static func safe_card_due(last_seen_unix: int, now_unix: int) -> bool:
	return last_seen_unix <= 0 or now_unix < last_seen_unix or now_unix - last_seen_unix > SAFE_CARD_DAYS * 86400


## The account has claimed its name: the server says so ("claimed"), or else its username is the
## profile's (Nakama gives a random one until the claim).
static func is_claimed(server_username: String, profile_username: String, server_flag: Variant = null) -> bool:
	if server_flag is bool:
		return server_flag
	return server_username != "" and server_username.to_lower() == profile_username.to_lower()


static func friend_state(nakama_state: int) -> StringName:
	match nakama_state:
		0:
			return FRIEND
		1:
			return SENT
		2:
			return RECEIVED
		3:
			return BLOCKED
	return &""


## "" when `typed` may be a friend's username (exact, §17.3), else an error code for message().
static func check_friend_name(typed: String, my_username: String) -> String:
	var t := typed.strip_edges()
	if t == "":
		return "empty_name"
	if t.to_lower() == my_username.to_lower():
		return "self"
	if UsernameRules.validate(t) != "":
		return "no_such_player"
	return ""


## An invite (notification 101: {"match_id", "from_username", "world_name"}), or {} when any part is
## not what the game sends. The world name is one of ours or "": free text never reaches the screen.
static func parse_invite(content: String, sender_id: String) -> Dictionary:
	var d := _json_object(content)
	var match_id: Variant = d.get("match_id")
	var from: Variant = d.get("from_username")
	if not (match_id is String and OnlineConfig.is_match_id(match_id)) or not (from is String) \
			or UsernameRules.validate(from) != "":
		return {}
	var world: Variant = d.get("world_name", "")
	var from_id: Variant = d.get("from_user_id", "")
	return {"match_id": match_id, "from_username": from,
		"from_id": sender_id if sender_id != "" or not (from_id is String) else from_id,
		"world_name": world if world is String and WORLD_NAMES.has(world) else ""}


## The match of a cancelled invite (notification 102), or "".
static func cancelled_match(content: String) -> String:
	var match_id: Variant = _json_object(content).get("match_id")
	return match_id if match_id is String and OnlineConfig.is_match_id(match_id) else ""


static func invite_text(invite: Dictionary) -> String:
	return Lang.t("%s invites you to their world!") % invite.get("from_username", "A friend")


## The name an invite carries for a world of `mode`.
static func world_name(mode: StringName) -> String:
	return "Survivor" if mode == ModeRules.SURVIVOR else "Sandbox"


static func can_invite(players: int) -> bool:
	return players < MAX_PLAYERS


## Plain, kind words for an error code from the server, Nakama or the client.
## Owner #67: too many wrong sign-in keys; `wait` seconds until the next try (whole minutes, at least one).
static func key_locked_message(wait: int) -> String:
	var minutes := maxi(1, ceili(wait / 60.0))
	return "Too many tries. Wait %d minute%s and try again." % [minutes, "" if minutes == 1 else "s"]


## Owner #93: the line under a "can't reach the game" (the internet's troubles only; "" for any other trouble).
static func play_alone_hint(text: String) -> String:
	var internet := [message("network"), NetWords.text(NetWords.NO_SERVER), NetWords.text(NetWords.TIMEOUT)]
	return PLAY_ALONE if text in internet else ""


static func message(code: String) -> String:
	if code in ["too_short", "too_long", "bad_chars", "must_start_with_letter", "personal_info", "blocked_word"]:
		return UsernameRules.message(code)
	code = _ALIASES.get(code, code)
	if _MESSAGES.has(code):
		return _MESSAGES[code]
	var low := code.to_lower()
	if low.begins_with("match:") or low.contains("match not found"):
		for c: String in ["match_full", "not_invited"]:
			if low.contains(c):
				return message(c)
		return _MESSAGES.match_gone
	for w in _NETWORK_WORDS:
		if low.contains(w):
			return _MESSAGES.network
	return _MESSAGES[""]


static func _json_object(text: String) -> Dictionary:
	var json := JSON.new()   # JSON.parse_string logs an engine error for bad input (a GUT failure)
	if text == "" or json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return json.data
