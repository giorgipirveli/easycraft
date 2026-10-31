class_name InviteRules
extends RefCounted
## Owner #79, #81, #82, #85 (spec §25.2; the world game plan §2, §2b): the game's side of "invite a friend".
## "Bringing a friend brings a friend to school": the server decides everything (module 0.2.16,
## server/modules/src/rules/referral_rules.ts: codes, a new account only, never your own, once, the rewards when the
## friend learns, the monthly caps, the Explorer Tree); the game shows the code, the links, a QR code, the tree and the
## ranks, and says it all in a child's words. A friend is named by their in-game name only. Nothing pushes: no timers,
## no "invite or lose", no ranking of children; the game is whole for a child who has no one to invite.
## Safety: a link carries only the code; the game never reads contacts and never asks for a friend's name, e-mail or
## number (docs/store/refer-a-friend-note.md).

## The server's numbers (ReferralRules): the game only says them.
const WELCOME_GOLD := 100
const INVITER_GOLD := 250
const LEARNER_GOLD := 50
const TREE_GOLD := 25
const LANDED_GOLD := 150
const MAX_TYPED := 40

const PLAY_URL := "https://178-104-20-64.sslip.io/play/"
const PAGES_URL := "https://giorgipirveli.github.io/easycraft/"
const STORE_URL := "https://play.google.com/store/apps/details?id=com.giorgi.easycraft"

## The Explorer ranks (§2b): friends who learned. Things to show, never power.
const RANKS: Array[Dictionary] = [
	{"at": 1, "title": "Mentor", "reward": "a Mentor star and a crew badge", "id": "mentor"},
	{"at": 3, "title": "Trail Guide", "reward": "a golden rocket paint", "id": "trail_guide"},
	{"at": 5, "title": "Mentor of 5", "reward": "a buddy of your own", "id": "mentor_5"},
	{"at": 10, "title": "Ambassador", "reward": "your own explorers' club", "id": "ambassador"},
	{"at": 25, "title": "Star Guide", "reward": "a star on the Star Map with your name", "id": "star_guide"},
	{"at": 50, "title": "Great Guide", "reward": "your statue in the colony dome", "id": "great_guide"},
	{"at": 100, "title": "Wonder Maker", "reward": "a wonder named after your crew", "id": "wonder_maker"},
]

const WHY := "Bring a friend to school! When your friend learns a whole unit, you both get gold."
const GROWN_UP_LINE := "For grown-ups: invite links carry no personal information. EasyCraft never reads contacts " \
	+ "and never asks for a friend's name, e-mail or phone number."
const NO_ONE_LINE := "No one to invite? That's fine: every lesson, rocket and world is yours to play."
const SHARE_WORDS := "Come and learn with me in EasyCraft! My invite code: %s"
const TYPE_CODE_WORDS := "Did a friend give you an invite code?"

const ERRORS := {
	"unknown": "We couldn't find that code. Check the words and the number.",
	"bad_code": "We couldn't find that code. Check the words and the number.",
	"own_code": "That's your own code! Give it to a friend.",
	"already_used": "You already joined with a friend's code.",
	"not_new": "Codes are for new explorers. You can still play with your friend!",
	"already_in": "You're already in a group like that one.",
	"group_full": "That group is full.",
	"locked": "Let's take a little break before trying another code.",
	"not_claimed": "Pick your online name first.",
}


## The code's key: capitals and digits only ("" when it can't be a code), as the server reads it.
static func canonical(text: String) -> String:
	if text.length() > MAX_TYPED:
		return ""
	var out := ""
	for c in text.to_upper():
		if (c >= "A" and c <= "Z") or (c >= "0" and c <= "9"):
			out += c
		elif not c in [" ", "-", "_", "\t"]:
			return ""
	return out


## Typed text that could be a code: letters first, then its number at the end.
static func looks_like_code(text: String) -> bool:
	var c := canonical(text)
	if c.length() < 5:
		return false
	var first := c[0]
	var last := c[c.length() - 1]
	return first >= "A" and first <= "Z" and last >= "0" and last <= "9"


## Typed text as it will be read out: capitals, one dash between words and the number.
static func shown(text: String) -> String:
	var words := text.to_upper().replace("_", " ").replace("-", " ").split(" ", false)
	return "-".join(words)


static func link(code: String) -> String:
	return PLAY_URL + "?invite=" + code


static func pages_link(code: String) -> String:
	return PAGES_URL + "?invite=" + code


## The Play Store's page with the install referrer (the game reads it later: typed for now, the notes' ruling).
static func store_link(code: String) -> String:
	return STORE_URL + "&referrer=invite%3D" + code


static func share_text(code: String) -> String:
	return (SHARE_WORDS % code) + "\n" + link(code)


## The code in a web page's address (web/shell.html passes location.search), shown as typed; "" for none.
static func code_from_query(query: String) -> String:
	for part in query.trim_prefix("?").split("&", false):
		var kv := part.split("=", true, 1)
		if kv.size() == 2 and kv[0] == "invite":
			var raw := kv[1].uri_decode()
			return shown(raw) if canonical(raw) != "" and looks_like_code(raw) else ""
	return ""


# --- Ranks -------------------------------------------------------------------------------------------------------

## The highest rank reached with `learned` friends who learned ({} for none yet).
static func rank_for(learned: int) -> Dictionary:
	var out := {}
	for r in RANKS:
		if learned >= int(r.at):
			out = r
	return out


static func next_rank(learned: int) -> Dictionary:
	for r in RANKS:
		if learned < int(r.at):
			return r
	return {}


## The world game plan §1: the inviter is the friend's mentor (Mentor, Mentor of 5, of 10).
static func mentor_title(learned: int) -> String:
	if learned >= 10:
		return "Mentor of 10"
	if learned >= 5:
		return "Mentor of 5"
	return "Mentor" if learned >= 1 else ""


# --- Words ---------------------------------------------------------------------------------------------------------

## One piece of news from the server ({"what", "name", "gold"}).
static func news_words(n: Dictionary) -> String:
	var name := str(n.get("name", ""))
	var gold := int(n.get("gold", 0))
	match str(n.get("what", "")):
		"joined":
			return "Your friend %s joined with your code!" % name if name != "" else "A new friend joined with your code!"
		"learned":
			var who := "Your friend %s" % name if name != "" else "Your new friend"
			if gold > 0:
				return "%s joined and learned! +%d gold" % [who, gold]
			return "%s joined and learned! This month's friend gold is used up, but it still counts in your tree." % who
		"tree":
			return "A friend of your friend learned! Your tree grows." + (" +%d gold" % gold if gold > 0 else "")
		"landed":
			var who := "Your friend %s" % name if name != "" else "Your friend"
			return "%s landed on the Moon!" % who + (" +%d gold" % gold if gold > 0 else "")
		"learner":
			return learner_words(name, gold)
		"code":
			return str(n.get("text", ""))   # a code kept on this device, answered by the server now
		"text":
			return str(n.get("text", ""))   # owner #81, #85: friends' news, in FriendshipRules' words already
	return ""


static func welcome_words(guide: String, gold: int) -> String:
	if gold <= 0:
		return "You joined! Have fun learning together."
	if guide == "":
		return "Welcome, explorer! Your friend's code brought you +%d gold." % gold
	return "Welcome, explorer! %s's code brought you +%d gold." % [guide, gold]


static func learner_words(guide: String, gold: int) -> String:
	if guide == "":
		return "You learned a whole unit: +%d gold!" % gold
	return "You learned a whole unit with your guide %s: +%d gold!" % [guide, gold]


static func tree_words(children: int) -> String:
	return "Your tree: %d child%s learning" % [children, "" if children == 1 else "ren"]


static func error_words(code: String) -> String:
	return str(ERRORS.get(code, OnlineRules.message(code)))


# --- The hook for the missions ---------------------------------------------------------------------------------------

## The world game plan §2: the missions call this when this child lands on the Moon (a friend's landing is the bonus of
## whoever invited them). Kept in the profile and sent to the server now or at the next sign-in. The caller saves.
static func friend_landed(where: String = "moon", profile: ProfileData = null) -> void:
	var p := profile if profile != null else Profile.data
	if p.invite.note_landed(where):
		InviteSender.send_soon()
