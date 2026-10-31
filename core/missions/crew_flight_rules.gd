class_name CrewFlightRules
extends RefCounted
## Crew flights (spec §21d.6 phase 2; owner #78: "mission to moon … where you must build a ship, rocket to get into
## planets, which can be built by team or alone"; #79: "you just sit into it at steering wheel and fly to moon"): friends
## in a shared world fly the rocket together and land together. Pure rules: the call's time, how many friends the rocket
## carries (the check with the whole crew: a seat each, air and water for everyone), the words a child reads at every
## step, how a crew member's flight follows the pilot's, the crew badge's words. (The friends' Crews of §25.7 are
## CrewRules, core/social: another thing.)

## The call's countdown: everyone has this long to TAKE MY SEAT or STAY HERE.
const CALL_SECONDS := 10.0
## The pilot's flight goes to the crew this often (seconds): 4 small words a second.
const STATE_EVERY := 0.25
## A crew member's flight runs at most this far (seconds) past the pilot's last word, then waits (the pilot paused).
const FOLLOW_AHEAD := 1.0
## A crew member behind the pilot by more than this (seconds, in the same step) jumps to the pilot's time.
const CATCH_UP := 0.5
## Following the pilot into its new world: if the crew member does not stand there after this long, kind words and the
## menu (never a hang). As long as a rejoin may take (RejoinRules.WINDOW) and the new world's loading.
const FOLLOW_SECONDS := 75.0
## Ruling 2: a friend who has not answered when the countdown ends comes along (nobody is left behind for reading
## slowly; STAY HERE is a choice). Cost if wrong: this constant.
const UNANSWERED_TAKES := true

## Why a friend does not fly.
const STAYED := &"stayed"
const NO_SEAT := &"no_seat"

const TAKE := "TAKE MY SEAT"
const STAY := "STAY HERE"
const LAUNCH_NOW := "LAUNCH NOW"
const NOT_YET := "NOT YET"
const ADD_CAPSULES := "ADD CAPSULES FIRST"
const CALLING := "Calling your crew to %s!"
const SEAT_TAKEN := "Your seat is ready! Lift-off soon…"
const STAYING := "You stay here. When the rocket flies, %s's world goes with it: back to the menu then."
const CHOOSING := "%s is checking the seats…"
const WAITS := "The launch waits: build more crew capsules together!"
const WAITS_PILOT := "The launch waits. Add crew capsules, then LAUNCH again!"
const LANDING := "Landing with your crew…"
## Owner #106: a crew member home after the pilot's crash (the pilot rebuilds the rocket).
const CRASHED_HOME := "Home with your crew! The rocket is your pilot's to rebuild: then try again together."
const HOME := "Flying home with your crew…"
const HOME_ARRIVED := "Back home with your crew!"
const LOST := "We couldn't follow your crew this time. Back to the menu for now!"
const GUEST_HOME := "You flew home on your own. Your crew stays on %s: see you soon!"
const BADGE_NEW := "New crew badge: %s!"
const WAVE := "WAVE"
const PILOT := "PILOT"
const CREW := "CREW"
const SOMEONE := "A friend"


## "Anna is launching to the Moon! Take your seat."
static func call_words(pilot: String, dest: int) -> String:
	var who := pilot.strip_edges() if pilot.strip_edges() != "" else "Your friend"
	return "%s is launching to %s! Take your seat." % [who, place(dest)]


## Where a mission goes, in words ("the Moon", "Mars", "Venus's cloud city").
static func place(dest: int) -> String:
	var m := MissionRules.for_world(dest)
	return str(m.place) if not m.is_empty() else FlightPlan.body_name(dest)


## How many of `wanted` friends the rocket carries with its pilot (0..wanted): the whole check (RocketCheck) with the
## crew counted (a seat each, air and water for everyone). `rocket`: RocketCheck.description.
static func room(rocket: Dictionary, wanted: int) -> int:
	var mission := MissionRules.for_world(int(rocket.get("destination", 0)))
	var cells: Dictionary = rocket.get("cells", {})
	for k in range(maxi(wanted, 0), 0, -1):
		if bool(RocketCheck.check(cells, mission, 1 + k).ok):
			return k
	return 0


## Kind words when `wanted` friends don't all fit ("" when they do): the seats first, then air and water.
static func short_words(rocket: Dictionary, wanted: int) -> String:
	if wanted <= 0 or room(rocket, wanted) >= wanted:
		return ""
	var check := RocketCheck.check(rocket.get("cells", {}), MissionRules.for_world(int(rocket.get("destination", 0))),
		1 + wanted)
	var seats := int(check.seats)
	for l: Dictionary in check.lines:
		if l.key == &"seats" and not bool(l.ok):
			var friends := "1 friend wants" if wanted == 1 else "%d friends want" % wanted
			var more := "a crew capsule" if 1 + wanted - seats == 1 else "crew capsules"
			return "%s to fly and the rocket has %s: add %s!" % [friends, _seats(seats), more]
	for l: Dictionary in check.lines:
		if l.key == &"supplies" and not bool(l.ok):
			return "%d astronauts need air and water for the whole trip: add a service module!" % (1 + wanted)
	return "The rocket can't carry everyone yet: check MY ROCKET with your crew!"


static func _seats(n: int) -> String:
	return "1 seat" if n == 1 else "%d seats" % n


## The pilot's choice when not everyone fits.
static func fly_with_words(n: int) -> String:
	if n <= 0:
		return "FLY ALONE"
	return "FLY WITH 1 FRIEND" if n == 1 else "FLY WITH %d FRIENDS" % n


## A friend who does not fly: the world flies away, so back to the menu, kindly (STAYED: they chose to; NO_SEAT: the
## rocket was full).
static func left_words(why: StringName, pilot: String, dest: int) -> String:
	var whose := "%s's world" % pilot.strip_edges() if pilot.strip_edges() != "" else "Your friend's world"
	if why == NO_SEAT:
		return ("The rocket had no seat for you this time. %s is flying to %s, so back to the menu for now. Next time, "
			+ "add a crew capsule together!") % [whose, place(dest)]
	return "%s is flying to %s, so back to the menu for now. Build a rocket together next time!" % [whose, place(dest)]


## What a crew member reads at a step of the pilot's flight: the pilot does the actions and the steering; the story's
## own words (in orbit, the trip, the landing) are everyone's.
static func crew_words(step: Dictionary, pilot: String) -> String:
	var who := pilot.strip_edges() if pilot.strip_edges() != "" else "The pilot"
	if step.get("phase", &"") == FlightPlan.BOARD:
		return "Climb in and buckle up! %s is the pilot, you are the crew." % who
	match step.get("action", &""):
		FlightPlan.THROTTLE:
			return "%s pushes the throttle up. Hold on tight!" % who
		FlightPlan.STAGE:
			return "%s lets the empty stage go!" % who
		FlightPlan.BURN:
			return "%s fires the engine. Off we go!" % who
		FlightPlan.LEGS:
			return "%s puts the landing legs out!" % who
		FlightPlan.PARACHUTE:
			return "%s opens the parachute!" % who
		FlightPlan.DESCEND:   # owner #106: the pilot flies the descent
			return "%s lands us: watch the speed! Green is safe." % who
	if bool(step.get("steer", false)):
		return "%s steers. Look out of the window!" % who
	return str(step.get("words", ""))


## How far into its step a crew member's flight may be: the pilot's time `pilot_t` at its last word, plus the time
## since that word (`since`), at most FOLLOW_AHEAD (a pilot who paused holds the crew too).
static func upto(pilot_t: float, since: float) -> float:
	return pilot_t + clampf(since, 0.0, FOLLOW_AHEAD)


## The badge: "Crew of the Moon mission with Anna and Sam".
static func badge_words(dest: int, mates: Array) -> String:
	var m := MissionRules.for_world(dest)
	var what := str(m.id).capitalize() if not m.is_empty() else FlightPlan.body_name(dest)
	var names: Array[String] = []
	for n: Variant in mates:
		if str(n).strip_edges() != "":
			names.append(str(n).strip_edges())
	if names.is_empty():
		return "Crew of the %s mission" % what
	return "Crew of the %s mission with %s" % [what, and_list(names)]


## "Anna", "Anna and Sam", "Anna, Sam and Mia".
static func and_list(names: Array[String]) -> String:
	if names.size() <= 1:
		return "".join(names)
	return "%s and %s" % [", ".join(names.slice(0, names.size() - 1)), names[-1]]


## A crew member's name as the world shows it (the host's word: Session.chat_names), or "A friend".
static func shown_name(n: String) -> String:
	return n.strip_edges() if n.strip_edges() != "" else SOMEONE
