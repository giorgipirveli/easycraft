class_name CrewRules
extends RefCounted
## Owner #81, #82 (brief docs/superpowers/plans/2026-09-30-daily-mission-brief.md item 5; the world game plan §1
## "Belonging"): crews of 2-6 friends. The server keeps them (module 0.2.18, SocialRules): a name of two words from the
## kid-safe lists below (never typed), a badge, the members and their avatar looks, invitations to friends; the crew
## page shows each member's avatar and what each learned this week (their learning days and the units mastered), never
## a ranking; the crew's weekly goal is learning days together (GOAL_PER_MEMBER each). The crew rocket and crew flights
## come with the missions (hooks: CrewRules.ROCKET_LATER, the crew's id).

const ADJECTIVES: Array[String] = ["Brave", "Bright", "Clever", "Cosmic", "Curious", "Daring", "Friendly", "Galactic",
	"Happy", "Jolly", "Kind", "Lucky", "Mighty", "Shining", "Speedy", "Starry", "Super", "Swift", "Wise", "Golden"]
const NOUNS: Array[String] = ["Astronauts", "Comets", "Explorers", "Rockets", "Stars", "Planets", "Pioneers", "Inventors",
	"Owls", "Otters", "Foxes", "Dolphins", "Eagles", "Pandas", "Penguins", "Dragons", "Builders", "Scientists", "Voyagers",
	"Moonwalkers"]
const BADGES: Array[String] = ["rocket", "star", "moon", "planet", "comet", "owl", "fox", "whale"]
const MIN := 2
const MAX := 6
const GOAL_PER_MEMBER := 3

const ABOUT := "A crew is 2 to 6 friends who learn and explore together."
const GOAL_ABOUT := "Every learning day of every member counts towards the crew's goal."
const ROCKET_LATER := "The crew rocket and crew flights come with the missions."
const BADGE_COLORS := {"rocket": Color("d9463b"), "star": Color("f2b61d"), "moon": Color("9aa7c7"), "planet": Color("2fae4e"),
	"comet": Color("3a7be8"), "owl": Color("a8642a"), "fox": Color("f08a1c"), "whale": Color("128fa6")}

const ERRORS := {
	"in_a_crew": "You're in a crew already. Leave it first to join another.",
	"crew_full": "That crew has all 6 seats filled.",
	"not_invited": "That invitation is gone.",
	"already_in": "Your friend is in your crew already!",
	"no_crew": "Make a crew first.",
	"bad_name": "Pick a name from the lists.",
	"bad_badge": "Pick a badge.",
	"not_claimed": "Pick your online name first.",
}


static func name_of(adjective: String, noun: String) -> String:
	return "%s %s" % [adjective, noun]


static func badge_color(badge: String) -> Color:
	return BADGE_COLORS.get(badge, UiKit.BLUE)


static func error_words(code: String) -> String:
	return str(ERRORS.get(code, OnlineRules.message(code)))


static func goal_words(done: int, target: int) -> String:
	return "This week together: %d of %d learning days%s" % [done, target, ". Goal reached!" if done >= target else ""]


static func size_words(members: int) -> String:
	if members >= MAX:
		return "Every seat is filled!"
	if members < MIN:
		return "%d of %d seats filled: invite a friend to learn with you!" % [members, MAX]
	return "%d of %d seats filled" % [members, MAX]


## A member's week ({days, units}) in words: the learning days and the titles of the units mastered.
static func week_words(week: Dictionary) -> String:
	var days := int(week.get("days", 0))
	var titles: Array[String] = []
	for u: Variant in week.get("units", []):
		var t := str(Curriculum.unit(str(u)).get("title", ""))
		if t != "":
			titles.append(t)
	if days <= 0 and titles.is_empty():
		return "Resting this week"
	if titles.is_empty():
		return "%d learning day%s this week" % [days, "" if days == 1 else "s"]
	return "%d learning day%s. Mastered: %s" % [days, "" if days == 1 else "s", ", ".join(titles)]
