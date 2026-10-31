class_name GiftRules
extends RefCounted
## The game's side of friends apart (M4 Wave 3, agent I; spec §17.5, research T3, T4, D5): blueprint
## gifts, showcases with guestbook stickers and bottle mail. The server decides everything
## (server/modules/src/server/gifts.ts, module 0.2.4); these rules only read its answers carefully
## (a name must be a username, a build must decode, a sticker or phrase must be on its list) and turn
## every answer into plain, kind words for a child.

## Notification codes (not persistent: the lists are the mailbox).
const NOTE_GIFT := 104
const NOTE_BOTTLE := 105
const NOTE_STICKER := 106
## The server's limits (tests/unit/test_gift_rules.gd reads them from gift_rules.ts).
const GIFTS_PER_FRIEND := 10
const BOTTLES_PER_FRIEND := 5
const GUESTBOOK_MAX := 30
const KEEP_DAYS := 60
## Guestbook stickers: the server's list, in order; a picture each (ui/gifts/sticker_pictures.gd).
const STICKERS: Array[String] = ["star", "heart", "smile", "wow", "thumbs_up", "rainbow", "trophy", "flower"]
const _STICKER_WORDS := {"star": "Star", "heart": "Heart", "smile": "Smile", "wow": "Wow", "thumbs_up": "Thumbs up",
	"rainbow": "Rainbow", "trophy": "Trophy", "flower": "Flower"}
const MAX_ID := 64

const _MESSAGES := {
	"too_many_gifts": "Your friend has lots of presents from you already. Wait until they open some!",
	"too_many_bottles": "Your friend has lots of bottles from you already. Wait until they find some!",
	"inbox_full": "Your friend's present box is full right now. Try again another day!",
	"too_fast": "Wow, that was fast! Wait a little and try again.",
	"bad_build": "That build can't be sent. Try another one!",
	"too_big": "That is too big to send. Try something smaller!",
	"empty_build": "There is nothing to send yet. Build something first!",
	"no_showcase": "Your friend has no showcase yet.",
	"bad_sticker": "Pick one of the stickers.",
	"bad_phrase": "Pick one of the words.",
	"bad_buddy": "Your buddy can't wait there. Try again!",
	"cannot_gift_self": "That's you! Pick a friend.",
	"cannot_sign_own": "That's your own showcase!",
	"not_friends": "You can only send things to your friends.",
	"not_found": "That friend can't get presents right now.",
	"gift_gone": "That present is not there any more.",
	"book_full": "Your GIFTS page is full. Delete a gift stamp first!",
	"not_allowed_online": "Ask a grown-up to say yes first.",
	"network": "Can't reach the game. Check the internet and try again.",
}


static func is_sticker(value: Variant) -> bool:
	return value is String and STICKERS.has(value)


static func sticker_word(sticker: String) -> String:
	return _STICKER_WORDS.get(sticker, "")


## Plain words for a server's code (or a network problem); OnlineRules' words for anything else.
static func message(code: String) -> String:
	var c := code.strip_edges()
	if _MESSAGES.has(c):
		return _MESSAGES[c]
	var online := OnlineRules.message(c)
	return online


## The gifts waiting on the server: [{"id", "from_id", "from", "count", "at" (unix seconds)}], well-formed only.
static func gift_list(value: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not (value is Array):
		return out
	for g: Variant in value:
		if g is Dictionary and _id(g.get("gift_id")) and _id(g.get("from_user_id")) and _name(g.get("from_username")):
			out.append({"id": g.gift_id, "from_id": g.from_user_id, "from": g.from_username,
				"count": _int(g.get("count")), "at": _seconds(g.get("created_ms")),
				"ghost": g.get("ghost") is bool and g.ghost})   # M4 ghost races: a race comes with it
	return out


## The bottles waiting on the server: [{"id", "from_id", "from", "at"}].
static func bottle_list(value: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not (value is Array):
		return out
	for b: Variant in value:
		if b is Dictionary and _id(b.get("bottle_id")) and _id(b.get("from_user_id")) and _name(b.get("from_username")):
			out.append({"id": b.bottle_id, "from_id": b.from_user_id, "from": b.from_username, "at": _seconds(b.get("created_ms"))})
	return out


## An opened gift: {"id", "from_id", "from", "build", "ghost": RaceGhost or null (M4 ghost races: the sender's
## race on a course in the build)} or {} (a broken one is never kept; a broken ghost is left out).
static func opened(g: Variant) -> Dictionary:
	if not (g is Dictionary) or not _id(g.get("gift_id")) or not _id(g.get("from_user_id")) or not _name(g.get("from_username")):
		return {}
	var build: Variant = g.get("build")
	if not (build is String) or BuildCodec.decode(build, BuildCodec.GIFT).is_empty():
		return {}
	return {"id": g.gift_id, "from_id": g.from_user_id, "from": g.from_username, "build": build,
		"ghost": RaceGhost.from_wire(g.get("ghost")) if g.get("ghost") is Dictionary else null}


## An opened bottle: {"id", "from_id", "from", "phrase", "build" ("" for none)} or {} (a phrase off the
## quick-chat list is never shown). A build bigger than a bottle's is left out.
static func opened_bottle(b: Variant) -> Dictionary:
	if not (b is Dictionary) or not _id(b.get("bottle_id")) or not _id(b.get("from_user_id")) or not _name(b.get("from_username")):
		return {}
	if not (b.get("phrase") is String) or not ChatRules.is_quick_phrase(b.phrase):
		return {}
	var build: Variant = b.get("build", "")
	var ok_build: bool = build is String and not BuildCodec.decode(build, BuildCodec.BOTTLE).is_empty()
	return {"id": b.bottle_id, "from_id": b.from_user_id, "from": b.from_username, "phrase": b.phrase,
		"build": build if ok_build else ""}


## A showcase: {"owner_id", "owner", "build", "size", "buddy": {"build", "at"} or {}, "guestbook": [...]}
## or {} when it is broken.
static func showcase(s: Variant) -> Dictionary:
	if not (s is Dictionary) or not _id(s.get("owner_id")) or not _name(s.get("owner_username")):
		return {}
	var build: Variant = s.get("build")
	if not (build is String) or BuildCodec.decode(build, BuildCodec.SHOWCASE).is_empty():
		return {}
	var size := BuildCodec.size_of(build)
	var buddy := {}
	var raw: Variant = s.get("buddy")
	if raw is Dictionary and raw.get("build") is String and raw.get("at") is Array and (raw.at as Array).size() == 3:
		var at := Vector3i(_int(raw.at[0]), _int(raw.at[1]), _int(raw.at[2]))
		var inside := at.x >= 0 and at.y >= 0 and at.z >= 0 and at.x < size.x and at.y < size.y and at.z < size.z
		if inside and not BuildCodec.decode(raw.build, BuildCodec.BUDDY).is_empty():
			buddy = {"build": raw.build, "at": at}
	return {"owner_id": s.owner_id, "owner": s.owner_username, "build": build, "size": size, "buddy": buddy,
		"guestbook": guestbook(s.get("guestbook", []))}


## Guestbook entries: [{"id", "from_id", "from", "sticker", "at"}], well-formed ones only.
static func guestbook(value: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not (value is Array):
		return out
	for e: Variant in value:
		if e is Dictionary and _id(e.get("entry_id")) and _id(e.get("from_user_id")) and _name(e.get("from_username")) \
				and is_sticker(e.get("sticker")):
			out.append({"id": e.entry_id, "from_id": e.from_user_id, "from": e.from_username, "sticker": e.sticker,
				"at": _seconds(e.get("at_ms"))})
	return out


static func _id(v: Variant) -> bool:
	return v is String and v != "" and (v as String).length() <= MAX_ID


static func _name(v: Variant) -> bool:
	return v is String and UsernameRules.validate(v) == ""


## Server milliseconds as unix seconds.
static func _seconds(v: Variant) -> int:
	return floori(_int(v) / 1000.0)


static func _int(v: Variant) -> int:
	return int(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v)) else 0
