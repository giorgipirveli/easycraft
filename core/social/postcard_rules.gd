class_name PostcardRules
extends RefCounted
## Owner #81, #82 (brief docs/superpowers/plans/2026-09-30-daily-mission-brief.md item 2; the world game plan §1 "Pride
## and showing"): postcards at proud moments. A moment is {kind, place, key, words}: a first landing ("I landed on the
## Moon!"), a mission complete, a unit or a grade mastered, a wonder's stamp, a deposit found. The game offers a
## postcard once per moment (SocialData.postcards: never nagging); the postcard is a picture (photo mode's camera in a
## world, a drawn one in the School), a frame, the words and the invite link (InviteRules). The same moment is told to
## friends to cheer (SocialSender.moment: the kind and the place, ids only). Pure: no nodes.
##
## Hooks for the lead (the flight is merged after this): `PostcardOffer.offer(parent, PostcardRules.landed("moon"))` at
## RocketFlight.landed / sandbox.mission_arrive for a first landing; `PostcardRules.stamp(...)` for a wonder's stamp and
## `PostcardRules.deposit(...)` for a deposit found (the wonders' and the prospecting agents' moments).

const KINDS: Array[String] = ["landed", "mission", "unit", "grade", "stamp", "deposit"]
## A place is an id the server takes (SocialRules.PLACE_RE): small letters, digits, dots and underscores.
static var PLACE_RE := RegEx.create_from_string("^[a-z0-9_.]{1,48}$")
const MAX_OFFERED := 400

## Places with their own names (the rest: the id in words).
const PLACE_NAMES := {"moon": "the Moon", "mars": "Mars", "europa": "Europa", "io": "Io", "titan": "Titan",
	"mercury": "Mercury", "venus": "Venus", "jupiter": "Jupiter", "saturn": "Saturn", "earth": "Earth", "iss": "the ISS"}
const SUBJECT_NAMES := {"maths": "maths", "science": "science", "english": "English", "history": "history",
	"geography": "geography", "citizenship": "citizenship", "computing": "computing", "art": "art", "music": "music",
	"health_pe": "health & PE", "design_tech": "design & technology", "projects": "projects"}

const OFFER_WORDS := "What a moment! Make a postcard?"
const GROWN_UPS_LINE := "Grown-ups: a postcard carries only its picture, its words and the invite link."
const SAVED_WORDS := "Your postcard is saved!"
const PLAY_WORDS := "Play and learn with me!"


static func moment(kind: String, place: String, words: String) -> Dictionary:
	return {"kind": kind, "place": place, "key": "%s:%s" % [kind, place], "words": words}


static func landed(place: String) -> Dictionary:
	return moment("landed", place, "I landed on %s!" % place_name("landed", place))


## A landing on world `u` (the lead's wiring, the flight merged): a mission's postcard, or a plain landing's; {} when `u`
## is no body of the Star Map (a home world).
static func for_landing(u: int, by_mission: bool) -> Dictionary:
	var place := String(StarMap.body_for_world(u))
	if place == "" or not SpaceRules.is_space(u):
		return {}
	return mission(place) if by_mission else landed(place)


static func mission(place: String) -> Dictionary:
	return moment("mission", place, "Mission complete: %s!" % place_name("mission", place))


static func unit(unit_id: String, title: String) -> Dictionary:
	return moment("unit", unit_id, "I mastered %s!" % title)


static func grade(g: int, subject: String) -> Dictionary:
	var place := "g%d.%s" % [g, subject]
	return moment("grade", place, "I mastered %s!" % place_name("grade", place))


static func stamp(wonder_id: String, name: String) -> Dictionary:
	return moment("stamp", wonder_id, "I visited %s!" % name)


static func deposit(resource_id: String) -> Dictionary:
	return moment("deposit", resource_id, "I found %s!" % place_name("deposit", resource_id))


## A place in words, for the postcard and for friends' cheers ("the Moon", "grade 4 maths", a unit's title).
static func place_name(kind: String, place: String) -> String:
	match kind:
		"landed", "mission":
			return str(PLACE_NAMES.get(place, place.replace("_", " ").capitalize()))
		"unit":
			var title := str(Curriculum.unit(place).get("title", ""))
			return title if title != "" else "a new unit"
		"grade":
			var parts := place.split(".")
			if parts.size() == 2 and parts[0].begins_with("g"):
				return "grade %s %s" % [parts[0].substr(1), SUBJECT_NAMES.get(parts[1], parts[1].replace("_", " "))]
		"stamp":
			return place.replace("_", " ").capitalize()
	return place.replace("_", " ")


static func due(profile: ProfileData, m: Dictionary) -> bool:
	return not profile.social.postcards.has(str(m.get("key", "")))


## The postcard of `m` was offered now: true the first time (the caller saves).
static func note_offered(profile: ProfileData, m: Dictionary) -> bool:
	var key := str(m.get("key", ""))
	if key == "" or profile.social.postcards.has(key):
		return false
	profile.social.postcards.append(key)
	while profile.social.postcards.size() > MAX_OFFERED:
		profile.social.postcards.pop_front()
	return true


static func share_text(words: String, code: String) -> String:
	if code != "":
		return words + "\n" + InviteRules.share_text(code)
	return words + "\nCome and learn with me in EasyCraft!\n" + InviteRules.PLAY_URL
