class_name EarthRules
extends RefCounted
## Earth's own worlds (owner #78, spec §24): numbers 41-60, right after space's 16-40 (SpaceRules), off the universe
## ladder. The first is 41, **Wonders of the World** (world/universes/wonders.gd): a friendly Earth world, free for
## everyone, peaceful, with Earth's gravity, sky and animals, where the wonders stand along a tour. Like a space world it
## is a trip away (SpaceRules.is_away): it remembers its home, its portal home stands by the landing spot, and the Star
## Map's HOME goes back there; unlike a space world it has air, weather and life.
##
## Getting there (spec §24): LAND on the Star Map's Earth card now; once flight is invented in Survivor (spec §21e, the
## plane), a mission with a plane from the Launch Site (way_there's hook).

const FIRST := 41
const LAST := 60
const WONDERS := 41
## Earth's worlds there are, in the Star Map's order.
const WORLDS: Array[int] = [WONDERS]

const BY_STAR_MAP := &"star_map"
const BY_PLANE := &"plane"


## One of Earth's own worlds (41-60).
static func is_earth(u: int) -> bool:
	return u >= FIRST and u <= LAST


## How a child gets to Earth world u: the Star Map's LAND today; `plane` (spec §21e: the plane invented and a mission
## for it at the Launch Site) is the hook for later; &"" for a world that is not Earth's.
static func way_there(u: int, plane: bool = false) -> StringName:
	if not is_earth(u):
		return &""
	return BY_PLANE if plane else BY_STAR_MAP
