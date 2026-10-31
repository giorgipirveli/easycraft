class_name AgeBand
extends RefCounted
## Neutral age gate: only the band is kept, never the birth year. With only a year we
## cannot know whether the birthday has passed, so the boundary year counts as under 13.

const UNDER_13 := &"under_13"
const TEEN_PLUS := &"13_plus"

## The owner (2026-09-29): "who told you to add age restrictions into game and edult confirmations??? remove all such
## restrictions … this is not a priority for now". Off: no age question, every player counts as 13+ (no chat, online,
## trade or pet limits by age) and every grown-up gate passes at once (GrownUpGate, the Theater's). The rules stay
## behind this switch (a store's child-safety rules may ask for them later); the tests switch it on (tests/pre_run.gd).
static var restrictions := false


## The band a player counts as: their own while restrictions are on (unknown or broken: the strictest); 13+ while off.
static func effective(band: StringName) -> StringName:
	if not restrictions:
		return TEEN_PLUS
	return band if is_valid(band) else UNDER_13


## The band to assume for a player whose band is not known yet (a peer before the server answers).
static func unknown() -> StringName:
	return UNDER_13 if restrictions else TEEN_PLUS


static func from_birth_year(birth_year: int, current_year: int) -> StringName:
	var guaranteed_age := current_year - birth_year - 1
	return TEEN_PLUS if guaranteed_age >= 13 else UNDER_13


static func is_valid(band: StringName) -> bool:
	return band == UNDER_13 or band == TEEN_PLUS


## Owner #57: the first question asks the age as a number. Only the band is kept, never the age; nonsense (0 or less)
## counts as a child, the safe side.
static func from_age(age: int) -> StringName:
	return TEEN_PLUS if age >= 13 else UNDER_13
