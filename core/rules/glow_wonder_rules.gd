class_name GlowWonderRules
extends RefCounted
## Universe 6, the Glow Caves' Cave Wonders as pure rules (owner #122, docs/design/learning-is-play.md §3: the concept is
## the move that wins; play first, words after; the world answers). Each wonder is a small play in a place of the caves
## (GlowWonders puts them there, GlowWondersDirector runs them); its real fact (FACTS, sources in
## docs/devlog/parts/glow-caves.md) comes only after the try, and the Cave Book (the Secret Book's page) keeps it:
## - GROTTO (bioluminescence): the glow-worms brighten while a child in the grotto is dark and still and dim when the
##   child is noisy or bright (real glow-worms dim when disturbed); held bright, their threads show the way.
## - DRIP (how stalactites grow): a drop falls from the stalactite every DROP_EVERY; a tap as it lands catches its calcite
##   (CATCH); every DROPS_PER_STEP caught drops grow a flowstone step towards a ledge; the drops' years are counted.
## - ECHO (echolocation): a click's echo returns from each tunnel after twice its length over the speed of sound, slowed
##   SLOWED times so a child hears it; the latest echo is the long, open tunnel.
## - RAIN (how caves form): rainwater carries carbonic acid: it dissolves limestone, never granite.
## - LAKE (why cave fish are blind): a lamp means nothing to fish without eyes; ripples bring them (they feel the water).
## - CRYSTALS and LONGEST are sights: the first crystal hall, and the caves walked (Mammoth Cave's length).
## Rewards are fixed (REWARD_GOLD × 2^(u-1) in Survivor), once per wonder: never random.

const GROTTO := &"grotto"
const DRIP := &"drip"
const ECHO := &"echo"
const RAIN := &"rain"
const LAKE := &"lake"
const CRYSTALS := &"crystals"
const LONGEST := &"longest"
## The plays the generator places (one per 128 x 128 area, in turn), and the Cave Book's pages (the plays, then the sights).
const KINDS: Array[StringName] = [GROTTO, DRIP, ECHO, RAIN, LAKE]
const BOOK: Array[StringName] = [GROTTO, DRIP, ECHO, RAIN, LAKE, CRYSTALS, LONGEST]
const NAMES := {GROTTO: "Glow-worm Grotto", DRIP: "Drip Stone", ECHO: "Echo Fork", RAIN: "Rain Carver",
	LAKE: "Blind Fish Lake", CRYSTALS: "Crystal Hall", LONGEST: "The Longest Cave"}
## The problem each play shows first (said when the child comes near), never its answer.
const HOOKS := {
	GROTTO: "Shh... the glow-worms are shy. Can you make them shine?",
	DRIP: "Drip... drip... Tap the stone as each drop lands. Can you grow steps to the pearls?",
	ECHO: "Three dark tunnels. Only one goes all the way. Tap the bat roost and listen!",
	RAIN: "Rain seeps into this cave. Scoop some rainwater and find a way through the wall!",
	LAKE: "Pale fish guard a pearl in the dark water. How do you call fish that have no eyes?",
}
## The see-why line after the play (real facts: sources in the notes).
const FACTS := {
	GROTTO: "Glow-worms make cold light (almost no heat) to lure insects into sticky threads. They dim when disturbed.",
	DRIP: "Each drop leaves a thin ring of calcite. Real stalactites grow about a centimetre in a hundred years.",
	ECHO: "Bats click and listen: the later the echo comes back, the farther the wall. Real echoes take a split second.",
	RAIN: "Rainwater is a weak acid. Over thousands of years it dissolves limestone and carves caves, not granite.",
	LAKE: "Cave fish live in total darkness, so eyes don't help. They feel the water move along their sides.",
	CRYSTALS: "Mexico's Cave of Crystals holds gypsum crystals up to 12 metres long, grown in warm water.",
	LONGEST: "Mammoth Cave in the USA is the longest cave known: more than 680 kilometres of mapped passages.",
}
## The world's cheer for the move that won (said with the fact after it).
const WINS := {
	GROTTO: "The glow-worms shine for you!",
	DRIP: "Your steps reached the pearls!",
	ECHO: "The long tunnel opens!",
	RAIN: "The limestone dissolved!",
	LAKE: "The fish brought you the pearl!",
}
## A short line per page of the Cave Book (a slot).
const BOOK_LINES := {
	GROTTO: "Cold light that catches insects",
	DRIP: "A centimetre in a hundred years",
	ECHO: "Late echo, far wall",
	RAIN: "Acid rain carves limestone",
	LAKE: "No eyes: they feel the water",
	CRYSTALS: "Crystals 12 metres long",
	LONGEST: "Over 680 km of passages",
}
const REWARD_GOLD := 15

# --- The glow-worm grotto ---------------------------------------------------------------------------------------
const GROTTO_R := 5.0             # standing this close to its listening stone is being in the grotto
const WORM_REST := 0.35           # their glow with nobody in the grotto
const WORM_DIM := 0.15            # ... and with a noisy or bright child in it
const WORM_RISE := 0.25           # brightening per second towards their target
const WORM_FALL := 1.0            # dimming per second
const WORM_SHOW := 0.95           # this bright ...
const WORM_HOLD := 1.5            # ... this long: their threads show the way

# --- The drip stone ---------------------------------------------------------------------------------------------
const DROP_EVERY := 2.4           # seconds between drops
const DROP_FALL := 0.9            # a drop's fall from the tip to the stone
const CATCH := 0.35               # a tap this close to its landing catches it
const DROPS_PER_STEP := 3
const YEARS_PER_DROP := 40        # a drop's thin ring stands for decades of real dripping (play time is short)
const STEPS := 5                  # steps to the ledge (at most)

# --- The echo fork ----------------------------------------------------------------------------------------------
const SOUND := 343.0              # metres a second in air
const SLOWED := 40.0              # the game slows echoes so the difference is heard (real: a few hundredths of a second)
const ECHO_LENGTHS: Array[float] = [3.0, 6.0, 11.0]   # the tunnels' lengths (blocks: metres)

# --- The blind fish lake ----------------------------------------------------------------------------------------
const RIPPLE := &"ripple"
const LIGHT := &"light"
const RIPPLES_NEEDED := 3

# --- The rain carver -------------------------------------------------------------------------------------------
const POURS_TO_OPEN := 3          # handfuls of rainwater that dissolve the limestone door (real: thousands of years)

# --- The longest cave -------------------------------------------------------------------------------------------
const LONGEST_WALK := 400.0       # blocks walked under the caves' roof in one visit
const STEP_MAX := 12.0            # a move longer than this between two looks is a teleport, a respawn or a ride
const STEP_RISE := 1.5            # a move more up or down than sideways is a fall or a climb


static func name_of(kind: StringName) -> String:
	return str(NAMES.get(kind, ""))


## What the world says when a play is won: the cheer on one line, the see-why fact under it.
static func win_words(kind: StringName) -> String:
	return "%s\n%s" % [str(WINS.get(kind, "")), str(FACTS.get(kind, ""))]


static func reward_gold(universe: int) -> int:
	return UniverseRules.gold(REWARD_GOLD, universe)


## The glow the worms head for: bright while a child in the grotto is dark and still (no noise beyond a crouch, no lamp
## in hand), dim while the child is noisy or bright, resting with nobody in it.
static func worm_target(inside: bool, noise: float, holds_light: bool) -> float:
	if not inside:
		return WORM_REST
	if holds_light or noise > StealthRules.NOISE_CROUCH:
		return WORM_DIM
	return 1.0


static func worm_step(glow: float, target: float, delta: float) -> float:
	var rate := WORM_RISE if target > glow else WORM_FALL
	return move_toward(glow, target, rate * maxf(delta, 0.0))


## Held at WORM_SHOW for WORM_HOLD: the way shows.
static func worms_solved(glow: float, held: float) -> bool:
	return glow >= WORM_SHOW and held >= WORM_HOLD


## Which drop it is at `t` seconds of the drip (0: the first).
static func drop_number(t: float) -> int:
	return floori(maxf(t, 0.0) / DROP_EVERY)


## Does a tap at `t` catch a drop (within CATCH of a drop's landing: DROP_FALL after it left the tip)?
static func caught(t: float) -> bool:
	var into := fposmod(t, DROP_EVERY)
	return absf(into - DROP_FALL) <= CATCH


static func steps_for(drops: int) -> int:
	return mini(maxi(drops, 0) / DROPS_PER_STEP, STEPS)


static func years(drops: int) -> int:
	return maxi(drops, 0) * YEARS_PER_DROP


## Seconds until a click's echo comes back from a tunnel `length` metres long (there and back, slowed down).
static func echo_delay(length: float) -> float:
	return 2.0 * maxf(length, 0.0) / SOUND * SLOWED


## The tunnel whose echo comes back last: the longest.
static func longest(lengths: Array) -> int:
	var best := 0
	for i in lengths.size():
		if float(lengths[i]) > float(lengths[best]):
			best = i
	return best


## The tunnels' lengths left to right for a fork drawn with bits `v` (the long one moves from fork to fork).
static func echo_order(v: int) -> Array[float]:
	var pool: Array[float] = ECHO_LENGTHS.duplicate()
	var out: Array[float] = []
	var k := absi(v)
	for i in range(pool.size(), 0, -1):
		out.append(pool.pop_at(k % i))
		k /= i
	return out


## Rainwater (a weak acid) dissolves limestone: the caves' cave stone and the wonders' limestone; never granite.
static func dissolves(id: int) -> bool:
	return id == BlockIds.CAVE_STONE or id == BlockIds.LIMESTONE or id == BlockIds.FAKE_CAVE_STONE


static func pours_left(pours: int) -> int:
	return maxi(POURS_TO_OPEN - maxi(pours, 0), 0)


## The sideways walk between two looks (0 for a fall, a climb or a jump across the world).
static func walk_step(from: Vector3, to: Vector3) -> float:
	var d := Vector2(to.x - from.x, to.z - from.z).length()
	if d > STEP_MAX or absf(to.y - from.y) > maxf(d, 0.01) * STEP_RISE:
		return 0.0
	return d


static func walked_far(walked: float) -> bool:
	return walked >= LONGEST_WALK


static func fish_come(stimulus: StringName) -> bool:
	return stimulus == RIPPLE


static func ripples_left(ripples: int) -> int:
	return maxi(RIPPLES_NEEDED - maxi(ripples, 0), 0)
