class_name MissionRules
extends RefCounted
## Missions (spec §21d; owner #78: "we have to have a mission to mars, mission to moon and etc. where you must build a
## ship, rocket to get into planets"). The Mission Board's missions in the real order people did or plan them: the
## Moon, Mars, then every real planet world that exists (SpaceRules.WORLDS: Venus's is its cloud city, where a rocket's
## heat shield and parachute let the thick air do the braking; Saturn's are its rings, where a rocket must race round
## Saturn as fast as the ring chunks: dips through Saturn's thin upper air slow it first, as spacecraft did at Mars and
## Venus; Pluto, which a spacecraft only flew past, 14 km every second too fast to stop: a giant drag balloon slows the
## lander in Pluto's thin, tall air, as a real study planned; Triton, which a spacecraft flew past after 12 years, about
## 10 km every second too fast to stay: the rocket skims Triton's thin air behind a blow-up heat shield to stay at
## Neptune, as a real study planned, then lands on its engines; Ganymede, the way a real spacecraft goes there now:
## swinging past the Moon, Venus and Earth to save fuel, then past Jupiter's moons again and again to slow down, almost
## 12 years), each with where it is, how long the real
## trip takes, one line of its real trip and what its rocket needs (the speed changes of its legs, km/s, rounded from a
## delta-v map of the solar system: sources in docs/devlog/parts/missions.md). A rocket carries its crew there and lands
## (ruling: the way home is the explorers' lander on the planet's pad, the portal home of §21.1; real plans make fuel
## for the way home on Mars).
##
## The route (§21d.5): a planet reached once, by a mission (MissionData.flown) or by a landing before missions (the
## Space Book's LANDED, WonderData), is on the child's route: the Star Map's LAND works for it. One not reached needs a
## mission (StarMap.MISSION). The game's own planets (Boing, Rainbow) have no mission: flying up reaches them. Pure.

const NOT_READY := "not_ready"
const GUEST := "guest"
const _MESSAGES := {
	NOT_READY: "Not yet: the check has lines to fix first.",
	GUEST: "This pad is your friend's: they launch from here. Build one at your own Launch Site to fly it yourself!",
}
const LAUNCHED := "%s launched to %s!"
const COMPLETE := "Mission complete! "

## Each mission: id, world, body (StarMap), name, place, distance and trip (words), days (the trip's length for the
## crew's air and water), air (a heat shield and a parachute to land through it), skim (cosmos, Triton: a heat shield to
## skim a thin air that slows the rocket, no parachute: that air is far too thin to land with), legs ([name, km/s], from
## the ground first) and a real fact.
const MISSIONS: Array[Dictionary] = [
	{"id": &"moon", "world": 16, "body": &"moon", "name": "Mission to the Moon", "place": "the Moon",
		"distance": "384,400 km away", "trip": "about 3 days", "days": 3, "air": false,
		"legs": [["Earth orbit", 9.4], ["to the Moon", 3.3], ["into orbit round it and down", 2.6]],
		"fact": "In 1969 the first people flew to the Moon. The trip took about 3 days."},
	{"id": &"mars", "world": 19, "body": &"mars", "name": "Mission to Mars", "place": "Mars",
		"distance": "55 to 400 million km away", "trip": "about 7 months", "days": 210, "air": true,
		"legs": [["Earth orbit", 9.4], ["to Mars", 3.6], ["into orbit round Mars", 2.1], ["down through its air", 1.0]],
		"fact": "Earth and Mars line up for the trip once every 26 months. No person has been there yet."},
	{"id": &"europa", "world": 20, "body": &"europa", "name": "Mission to Europa", "place": "Europa",
		"distance": "600 to 970 million km away", "trip": "about 2 years and 9 months", "days": 1000, "air": false,
		"legs": [["Earth orbit", 9.4], ["to Jupiter", 6.3], ["past Jupiter's moons and down", 3.5]],
		"fact": "Robot probes took 5 or 6 years to reach Jupiter, swinging past planets to save fuel."},
	{"id": &"io", "world": 21, "body": &"io", "name": "Mission to Io", "place": "Io",
		"distance": "600 to 970 million km away", "trip": "about 2 years and 9 months", "days": 1000, "air": false,
		"legs": [["Earth orbit", 9.4], ["to Jupiter", 6.3], ["deep into Jupiter's pull and down", 4.0]],
		"fact": "Io goes round Jupiter closest of its big moons: getting down there takes the most braking."},
	{"id": &"titan", "world": 22, "body": &"titan", "name": "Mission to Titan", "place": "Titan",
		"distance": "1.2 to 1.7 billion km away", "trip": "about 6 years", "days": 2200, "air": true,
		"legs": [["Earth orbit", 9.4], ["to Saturn", 7.3], ["into orbit and down through the air", 0.8]],
		"fact": "In 2005 a probe floated down to Titan under parachutes: its thick air did the braking."},
	{"id": &"mercury", "world": 23, "body": &"mercury", "name": "Mission to Mercury", "place": "Mercury",
		"distance": "80 to 220 million km away", "trip": "about 4 months", "days": 105, "air": false,
		"legs": [["Earth orbit", 9.4], ["to Mercury", 5.5], ["braking against the Sun's pull, and down", 9.4]],
		"fact": "Mercury is close, but the hardest to land on: you fall toward the Sun and must brake hard."},
	{"id": &"venus", "world": 24, "body": &"venus", "name": "Mission to Venus", "place": "Venus's cloud city",
		"distance": "38 to 261 million km away", "trip": "about 5 months", "days": 146, "air": true,
		"legs": [["Earth orbit", 9.4], ["to Venus", 3.5], ["down through its thick air to the cloud city", 0.5]],
		"fact": "Venus comes closer to Earth than any other planet, and its thick air does the braking."},
	{"id": &"rings", "world": 25, "body": &"saturn", "name": "Mission to Saturn's rings", "place": "Saturn's rings",
		"distance": "1.2 to 1.7 billion km away", "trip": "about 6 years", "days": 2200, "air": false,
		"legs": [["Earth orbit", 9.4], ["to Saturn", 7.3], ["into orbit round Saturn", 0.6],
			["braking in Saturn's thin upper air, then keeping up with the chunks", 2.7]],
		"fact": "The ring chunks race round Saturn at about 20 km every second: your rocket must keep up!"},
	{"id": &"pluto", "world": 26, "body": &"pluto", "name": "Mission to Pluto", "place": "Pluto",
		"distance": "4.3 to 7.5 billion km away", "trip": "about 9 and a half years", "days": 3470, "air": true,
		"legs": [["Earth orbit", 9.4], ["to Pluto, swinging past Jupiter", 8.9],
			["slowing in Pluto's thin air under a giant balloon, then down", 0.3]],
		"fact": "A spacecraft reached Pluto in 2015 after 9 and a half years and flew past. To land, a giant balloon slows you!"},
	{"id": &"triton", "world": 27, "body": &"triton", "name": "Mission to Triton", "place": "Triton",
		"distance": "4.3 to 4.7 billion km away", "trip": "about 12 years", "days": 4380, "air": false, "skim": true,
		"legs": [["Earth orbit", 9.4], ["to Neptune, swinging past Jupiter", 7.4],
			["skimming Triton's thin air behind a blow-up heat shield, to stay", 0.3],
			["down onto Triton's ice on the engines", 1.4]],
		"fact": "A spacecraft flew past Triton in 1989, 12 years after launch. To stay, skim its air behind a heat shield!"},
	{"id": &"ganymede", "world": 28, "body": &"ganymede", "name": "Mission to Ganymede", "place": "Ganymede",
		"distance": "600 to 970 million km away", "trip": "almost 12 years", "days": 4260, "air": false,
		"legs": [["Earth orbit", 9.4], ["to Jupiter, swinging past the Moon, Venus and Earth", 3.5],
			["into orbit round Jupiter, then past its moons again and again to slow down", 2.1],
			["into orbit round Ganymede and down onto its ice", 2.5]],
		"fact": "A spacecraft launched in 2023 swings past Venus and Earth to save fuel. It will circle Ganymede in 2034!"},
]


static func for_world(u: int) -> Dictionary:
	for m in MISSIONS:
		if int(m.world) == u:
			return m
	return {}


static func has_mission(u: int) -> bool:
	return not for_world(u).is_empty()


## km/s from the ground to landing there: the legs' sum.
static func need(m: Dictionary) -> float:
	var total := 0.0
	for leg: Array in m.get("legs", []):
		total += float(leg[1])
	return total


## The missions whose worlds exist here (a world not built yet has no mission on the board).
static func open_missions(available: Array[int]) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for m in MISSIONS:
		if available.has(int(m.world)):
			out.append(m)
	return out


## What a mission's rocket needs, in plain words (the board's card). Owner #98: every line the check asks for, so a
## child building by hand meets no surprise line.
static func needs_words(m: Dictionary) -> Array[String]:
	var legs: Array[String] = []
	for leg: Array in m.get("legs", []):
		legs.append("%s %.1f" % [leg[0], float(leg[1])])
	var out: Array[String] = [
		"Speed: %.1f km/s (%s)" % [need(m), ", ".join(legs)],
		"Rocket engines at the bottom with %d fins round them" % RocketCheck.FINS_NEEDED,
		"Stages that drop away: a stage separator under each new stage, with space engines at its bottom",
		"A crew capsule and a service module for each astronaut (air, water and food for the whole trip)",
		"On the top stage: an engine and fuel to land, %d landing legs and a solar array" % RocketCheck.LEGS_NEEDED,
		"A pointed top: a nose cone",
	]
	if bool(m.get("air", false)):
		out.append("A heat shield and a parachute for its air")
	elif bool(m.get("skim", false)):   # cosmos: Triton
		out.append("A heat shield to skim its thin air")
	return out


static func days_words(days: int) -> String:
	return "1 day" if days == 1 else "%d days" % days


## The worlds on the child's route: flown to by a mission, or landed on before (the Space Book's LANDED).
static func route(wonder: WonderData, flown: Array[int]) -> Array[int]:
	var out: Array[int] = []
	for m in MISSIONS:
		var u := int(m.world)
		var marks := int(wonder.bodies.get(str(m.body), 0)) if wonder != null else 0
		if flown.has(u) or marks & WonderData.LANDED:
			out.append(u)
	return out


## Landing on world u from the Star Map needs a mission first.
static func needs_mission(u: int, on_route: Array[int]) -> bool:
	return has_mission(u) and not on_route.has(u)


## Why LAUNCH can't fly ("" = it flies): the check not passed, or a friend's pad (the world's owner launches; travel is
## solo today, spec §21d.6 phase 1). `peers` (friends here) never stops the owner: they are told.
static func launch_refusal(check_ok: bool, is_client: bool, _peers: int) -> String:
	if not check_ok:
		return NOT_READY
	if is_client:
		return GUEST
	return ""


static func message(key: String) -> String:
	return _MESSAGES.get(key, "")


## What the others in a shared world hear.
static func launched_words(who: String, m: Dictionary) -> String:
	return LAUNCHED % [who, str(m.get("place", "space"))]
