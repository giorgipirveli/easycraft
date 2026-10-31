class_name FriendshipRules
extends RefCounted
## Owner #81, #82, #85 (brief docs/superpowers/plans/2026-09-30-daily-mission-brief.md item 4; the world game plan §2b):
## friendship levels (Pokémon GO's lesson), study buddies (Duolingo's, without the loss) and cheers, in a child's words.
## The server counts (module 0.2.18, SocialRules): a day together counts once a day per pair when the two learned on the
## same day, one sent the other a present or one cheered the other; the levels at LEVELS' days; days never fall. A
## study buddy shares a daily goal (both learn something that day): their days learning together only grow, and a rest
## day is fine. Cheers are CHEERS only (never typed). The level rewards are hooks the colonies and rovers use later
## (ids: friendship_badge, two_seat_rover, dome_room).

const LEVELS: Array[Dictionary] = [
	{"at": 1, "id": "good", "reward": "friendship_badge", "title": "Good friends", "words": "a friendship badge"},
	{"at": 7, "id": "great", "reward": "two_seat_rover", "title": "Great friends",
		"words": "a two-seat rover to drive together"},
	{"at": 30, "id": "best", "reward": "dome_room", "title": "Best friends", "words": "a shared room in the colony dome"},
]
const BUDDIES_MAX := 3
const CHEER_IDS: Array[String] = ["well_done", "amazing", "star", "high_five", "so_proud", "you_did_it"]
const CHEERS := {"well_done": "Well done!", "amazing": "Amazing!", "star": "You're a star!", "high_five": "High five!",
	"so_proud": "So proud of you!", "you_did_it": "You did it!"}

const BUDDY_GOAL := "Our goal: we both learn something every day. A rest day is fine."
const NO_FRIENDS := "No friends here yet. Add friends in PLAY ONLINE, or invite a friend: learning is better together!"
const CHEER_LINE := "Cheer your friends"


static func level_of(days: int) -> int:
	var out := 0
	for i in LEVELS.size():
		if days >= int(LEVELS[i].at):
			out = i + 1
	return out


static func title(level: int) -> String:
	return str(LEVELS[level - 1].title) if level >= 1 and level <= LEVELS.size() else "Friends"


static func reward_of(level: int) -> String:
	return str(LEVELS[level - 1].words) if level >= 1 and level <= LEVELS.size() else ""


static func days_words(days: int) -> String:
	return "%d day%s together" % [days, "" if days == 1 else "s"]


## The next level and its shared reward ("4 more days together to Great friends: a two-seat rover to drive together").
static func next_words(days: int) -> String:
	for l in LEVELS:
		if days < int(l.at):
			var more := int(l.at) - days
			return "%d more day%s together to %s: %s" % [more, "" if more == 1 else "s", l.title, l.words]
	var top: Dictionary = LEVELS[-1]
	return "%s: %s is yours" % [top.title, top.words]


static func cheer_words(id: String) -> String:
	return str(CHEERS.get(id, ""))


## A friend's proud moment to cheer.
static func moment_words(name: String, kind: String, place: String) -> String:
	var what := ""
	match kind:
		"landed":
			what = "landed on %s" % PostcardRules.place_name(kind, place)
		"mission":
			what = "completed a mission to %s" % PostcardRules.place_name(kind, place)
		"unit", "grade":
			what = "mastered %s" % PostcardRules.place_name(kind, place)
		"stamp":
			what = "visited %s" % PostcardRules.place_name(kind, place)
		"deposit":
			what = "found %s" % PostcardRules.place_name(kind, place)
		_:
			what = "did something great"
	return "%s just %s! Send a cheer?" % [name, what]


## What the moment was, in "you" words ("you landed on the Moon"), from its "kind:place".
static func your_moment(kind_place: String) -> String:
	var parts := kind_place.split(":", true, 1)
	if parts.size() != 2:
		return ""
	var kind := parts[0]
	var place := parts[1]
	match kind:
		"landed":
			return "you landed on %s" % PostcardRules.place_name(kind, place)
		"mission":
			return "your mission to %s" % PostcardRules.place_name(kind, place)
		"unit", "grade":
			return "you mastered %s" % PostcardRules.place_name(kind, place)
		"stamp":
			return "you visited %s" % PostcardRules.place_name(kind, place)
		"deposit":
			return "you found %s" % PostcardRules.place_name(kind, place)
	return ""


## One piece of news from the server ({what, name, kind, gold, place}); "" for one this game doesn't know.
static func news_words(n: Dictionary) -> String:
	var name := str(n.get("name", ""))
	if name == "":
		name = "A friend"
	var kind := str(n.get("kind", ""))
	var gold := int(n.get("gold", 0))
	match str(n.get("what", "")):
		"cheer":
			var about := your_moment(str(n.get("place", "")))
			return "%s cheered: %s%s" % [name, cheer_words(kind), " (%s)" % about if about != "" else ""]
		"thanks":
			return "%s said thank you for the %s!%s" % [name, FriendPresents.name_of(kind).trim_prefix("a ").trim_prefix(
				"an "), " +%d gold" % gold if gold > 0 else ""]
		"present":
			return "%s sent you %s! Open it in FRIENDS." % [name, FriendPresents.name_of(kind)]
		"link_present":
			return "%s joined with your code and got your %s!" % [name, FriendPresents.name_of(kind).trim_prefix(
				"a ").trim_prefix("an ")]
		"buddy_ask":
			return "%s asks: study buddies? Say yes in FRIENDS." % name
		"buddy_yes":
			return "%s said yes: you're study buddies!" % name
		"crew_invite":
			return "%s asks you to join their crew! See CREW in FRIENDS." % name
		"crew_join":
			return "%s joined your crew!" % name
		"level":
			for i in LEVELS.size():
				if LEVELS[i].id == kind:
					return "You and %s are %s now: %s!" % [name, LEVELS[i].title, LEVELS[i].words]
	return ""


static func buddy_words(days: int) -> String:
	return "Study buddies: %d day%s learning together" % [days, "" if days == 1 else "s"]


## The week's row (the last 7 days: 2 both learned, 1 one of them, 0 a rest day) in words.
static func buddy_row_words(row: Array) -> String:
	var both := 0
	for v: Variant in row:
		both += 1 if int(v) == 2 else 0
	return "This week: %d day%s together" % [both, "" if both == 1 else "s"]
