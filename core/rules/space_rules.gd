class_name SpaceRules
extends RefCounted
## Space (owner feedback #55, spec §21) as pure rules. A child who flies high enough above any world crosses the space
## line: "Where shall we land?" offers the Moon and the planets (worlds 16-18, off the universe ladder: their own
## descriptors in world/universes/, UniverseRegistry.SPACE). On the way up the sky darkens and the stars come out
## (climb, space_look). A space world remembers its home (the ladder world the trip started from, WorldMeta.space_home)
## and the portal home stands by its landing pad; the home world remembers the column the child took off from
## (WorldMeta.space_return), so coming home lands them there.

const CLIMB_FROM := 160.0        # the sky starts to darken here (the highest block is WorldService.MAX_Y, 192)
const HINT_Y := 180.0            # "Keep flying up!"
const REARM_Y := 190.0           # back under this, crossing the line again opens space again
const SPACE_Y := 200.0           # the space line (ruling 1: about 18 s of flying from the meadows' ground)
const STAY_Y := 186.0            # STAY HERE puts a flyer back under the line (and under REARM_Y)

const MOON := 16
const BOING := 17
const RAINBOW := 18
## The real solar system's worlds (spec §21b.2), each built in turn: Mars first.
const MARS := 19
const EUROPA := 20
const IO := 21
const TITAN := 22
const MERCURY := 23
const VENUS := 24
const RINGS := 25
const PLUTO := 26
const TRITON := 27
const GANYMEDE := 28
## The space worlds there are, in the picker's order (cosmos: Mars, the first real planet, then Europa, Io, Titan,
## Mercury, Venus's cloud city, Saturn's rings, Pluto, Triton and Ganymede, spec §21b.2).
const WORLDS: Array[int] = [MOON, BOING, RAINBOW, MARS, EUROPA, IO, TITAN, MERCURY, VENUS, RINGS, PLUTO, TRITON, GANYMEDE]
const FIRST := 16
const LAST := 40                 # 19-28 the real solar system (§21b.2), then more planets
const HOME := 0                  # a card's "universe" when it is the way home (never a world's number)
const COORD_LIMIT := 100000000   # a saved take-off column farther out than this is nonsense

const HINT_WORDS := "Keep flying up! Space is up there!"
const TITLE := "Where shall we land?"
const HOME_WORD := "HOME"
const STAY_WORD := "STAY HERE"
const HOME_WORDS := "Welcome home!"
const _MESSAGES := {
	"friends": "Space trips work when you play alone.",
	"coming_soon": "This planet is coming soon!",
	"here": "You are here!",
	"no_flying": "Space is closed here.",
}

## The sky of space: black at the top, deep navy at the horizon, a dark fog; the photo sky almost off.
const SPACE_TOP := Color(0.01, 0.01, 0.04)
const SPACE_HORIZON := Color(0.04, 0.05, 0.13)
const SPACE_GROUND := Color(0.03, 0.03, 0.08)
const SPACE_FOG := Color(0.07, 0.08, 0.16)
const SPACE_SKY_ENERGY := 0.06


## A space world (16-40), not on the universe ladder.
static func is_space(u: int) -> bool:
	return u >= FIRST and u <= LAST


## Owner #78 (spec §24): a world a trip goes to and comes home from, off the ladder: a space world, or one of Earth's own
## (EarthRules, 41-60: Wonders of the World). It remembers its home (WorldMeta.space_home), its portal home stands by
## where the child lands, it is never scaled and never Plus.
static func is_away(u: int) -> bool:
	return is_space(u) or EarthRules.is_earth(u)


## The universe whose scale applies in world u (ruling 3: a space world is never scaled: Green Meadows'; owner #78:
## nor an Earth world).
static func scaling(u: int) -> int:
	return UniverseRules.FIRST if is_away(u) else u


## A home a trip can start from and come back to: a ladder world (1-15).
static func is_home(u: int) -> bool:
	return u >= UniverseRules.FIRST and u < FIRST


# --- The line and the climb ---

## 0 on the ground, 1 at the space line: how far the sky has turned to space for a flyer at height y.
static func climb(y: float) -> float:
	if not is_finite(y):
		return 0.0
	return clampf((y - CLIMB_FROM) / (SPACE_Y - CLIMB_FROM), 0.0, 1.0)


## A flyer at height y crosses the line (once while `armed`).
static func crossed(y: float, armed: bool) -> bool:
	return armed and is_finite(y) and y >= SPACE_Y


## Back far enough under the line to open space again.
static func rearms(y: float) -> bool:
	return is_finite(y) and y < REARM_Y


## Space is where flying is (ruling 2: Sandbox free, Survivor paid; never Monster Wave).
static func may_launch(mode: StringName) -> bool:
	return ModeRules.allows(mode, ModeRules.FLYING)


## The home of a trip from world `here` whose own saved home is `home`: a ladder world is its own home; a space world
## goes back to where its trip started (Green Meadows when that is lost).
static func home_for(here: int, home: int) -> int:
	if not is_away(here):
		return UniverseRules.valid(here)
	return home if is_home(home) else UniverseRules.FIRST


# --- "Where shall we land?" ---

## Why landing on world `to` from `here` can't happen ("" = it can): a key for message(). peers: other players here.
static func refusal(to: int, here: int, available: Array[int], peers: int) -> String:
	if to == here:
		return "here"
	if not is_away(to) or not available.has(to):   # owner #78: Earth's worlds land from the Star Map too
		return "coming_soon"
	if peers > 0:
		return "friends"
	return ""


static func message(key: String) -> String:
	return _MESSAGES.get(key, "")


## What a child hears on landing, when the world has no words of its own.
static func landing_words(world_name: String) -> String:
	return Lang.t("Welcome to %s!") % world_name


# --- The trip's saves ---

## The space world u a child lands on: `existing` (landed on before) or a new one of `mode`; either way on the landing
## pad (the world spawn), walking, with `home` remembered and the portal home (owner #39's arrival gate) by the pad.
## A new world gets no starter kit (the bag comes along in Survivor, UniverseRules.carry).
static func arrival_meta(existing: WorldMeta, u: int, mode: StringName, difficulty: StringName, home: int) -> WorldMeta:
	var m := existing
	if m == null:
		m = WorldMeta.new_random()
		m.difficulty = KnockoutRules.valid_difficulty(difficulty)
	m.mode = ModeRules.valid(mode)
	m.universe = UniverseRules.valid(u)
	m.player_pos = Vector3.INF
	m.physics_mode = PhysicsMode.Mode.NORMAL
	m.lab_mode = LabRules.Mode.NORMAL
	m.space_home = home if is_home(home) else UniverseRules.FIRST
	m.arrival_gate = m.space_home if CrystalRules.CORES.has(m.space_home) else 0
	return m


## The world a child takes off from (saved right after): a ladder world remembers the column under them (coming home
## lands there); every world is left walking, so nobody comes back flying (Survivor's fly clock).
static func take_off(meta: WorldMeta, feet: Vector3) -> void:
	if not is_away(meta.universe):
		meta.space_return = landing_column(feet)
	meta.player_pos = Vector3.INF
	meta.physics_mode = PhysicsMode.Mode.NORMAL
	meta.lab_mode = LabRules.Mode.NORMAL


## [x, z] of the column under `feet`, or [] without a place.
static func landing_column(feet: Vector3) -> Array:
	if not feet.is_finite():
		return []
	return [floori(feet.x), floori(feet.z)]


## Where a child coming home to this world lands: [x, z] (the take-off column), or [] (as always: the saved spot or the
## spawn). A space world never has one.
static func landing_spot(meta: WorldMeta) -> Array:
	return [] if is_away(meta.universe) else clean_column(meta.space_return)


## A saved [x, z] column, or [] when it is not one.
static func clean_column(v: Variant) -> Array:
	if not v is Array or (v as Array).size() != 2:
		return []
	for n: Variant in v:
		if typeof(n) not in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(n)) or absf(float(n)) > COORD_LIMIT:
			return []
	return [int(v[0]), int(v[1])]


# --- The sky's space look ---

## A DayCycle look turned `amount` (0..1) toward space: a black starry sky, a dark fog and a dim photo sky; the sun
## shines as bright as ever.
static func space_look(look: Dictionary, amount: float) -> Dictionary:
	var k := clampf(amount, 0.0, 1.0) if is_finite(amount) else 0.0
	if k <= 0.0:
		return look
	for pair: Array in [["sky_top", SPACE_TOP], ["sky_horizon", SPACE_HORIZON], ["ground_bottom", SPACE_GROUND],
			["ground_horizon", SPACE_HORIZON], ["fog_color", SPACE_FOG]]:
		if look.get(pair[0]) is Color:
			look[pair[0]] = (look[pair[0]] as Color).lerp(pair[1], k)
	look.stars = lerpf(float(look.get("stars", 0.0)), 1.0, k)
	look.sky_energy = lerpf(float(look.get("sky_energy", 1.0)), SPACE_SKY_ENERGY, k)
	return look
