class_name DiscoveryCrystalRules
extends RefCounted
## Owner #132 (W1), stage 2: the discovery crystal (docs/devlog/parts/play-w1.md). While a child plays a home world (not
## Monster Wave's arena, not space; not in a fight, a race, a round, riding, flying or a menu: the sandbox says busy),
## after FIRST_SECONDS of play and then EVERY_SECONDS after the last one went, a glowing crystal rises a few metres from
## the child, in front when it can, on ground the child can walk to, never in water or a wall. Touching it starts a short
## play (DiscoveryPlays: real play, no reading); an untouched one waits WAIT_SECONDS and fades, and nothing is lost. At
## most one at a time. A grown-up's switch (settings SETTING, the grown-ups' PLAY & PHOTOS page) turns them off.

## The profile setting (a grown-up's; on unless turned off).
const SETTING := "discovery_crystals"
## Seconds of play before the first crystal in a world, and between one crystal going and the next.
const FIRST_SECONDS := 150.0
const EVERY_SECONDS := 300.0
## An untouched crystal waits this long, then fades.
const WAIT_SECONDS := 120.0
## Where it rises: this far from the child's feet (metres), and how far up or down the child can walk to it.
const NEAR := 3.0
const FAR := 5.0
const CLIMB := 2
## How close the child (or a hand in a headset) must come to touch it.
const TOUCH := 1.3
const HAND_TOUCH := 0.35
## The play ends quietly when the child walks this far away from the crystal (nothing lost).
const LEAVE := 14.0

## Spoken as the crystal rises (owner #133: heard, not read), and Hoot's line the first time a child meets one.
const ARRIVE_LINE := "A discovery crystal! Touch it to play!"
const HOOT_CRYSTAL_LINE := "Hoo! Touch the crystal to play!"


## A crystal may come in `mode`'s world of `universe` with the grown-up's switch `on`.
static func here(mode: StringName, universe: int, on: bool) -> bool:
	return on and DiscoveryRules.hoot_here(mode, universe)


## The grown-up's switch in a profile's settings.
static func switched_on(settings: Dictionary) -> bool:
	return bool(settings.get(SETTING, true))


## A crystal is due after `seconds` of play (since the world started: `first`; else since the last one went).
static func due(seconds: float, first: bool) -> bool:
	return seconds >= (FIRST_SECONDS if first else EVERY_SECONDS)


## Where a crystal rises near `feet` (the child facing `yaw`), on ground the child can walk to: the cell above a solid,
## dry block, with room above it; a few metres away, in front first (a little to one side, so the avatar does not hide it
## from a camera behind the child), then to the sides, then behind. `block_at`:
## (Vector3i) -> int. Vector3.INF when there is no such ground near (water all round, walls, a cliff): no crystal now.
static func spot_near(feet: Vector3, yaw: float, block_at: Callable) -> Vector3:
	var fy := floori(feet.y + 0.01)
	for turn: float in [0.45, -0.45, 0.0, 0.9, -0.9, 1.5, -1.5, 2.0, -2.0, 2.6, -2.6, PI]:
		for r: float in [FAR - 0.5, FAR, NEAR + 0.5, NEAR]:
			var a := yaw + turn
			var at := feet + Vector3(-sin(a), 0.0, -cos(a)) * r
			var x := floori(at.x)
			var z := floori(at.z)
			for dy in range(CLIMB, -CLIMB - 1, -1):
				var y := fy + dy
				if stands_at(block_at, Vector3i(x, y, z)):
					return Vector3(x + 0.5, y, z + 0.5)
	return Vector3.INF


## The cell `c` can hold a crystal: open itself and twice above, on a solid, dry block.
static func stands_at(block_at: Callable, c: Vector3i) -> bool:
	var below := int(block_at.call(c + Vector3i.DOWN))
	if not BlockIds.is_solid(below) or below == BlockIds.LEAVES or below == BlockIds.HOT_LAVA:
		return false
	for up in 3:
		if not _open(int(block_at.call(c + Vector3i(0, up, 0)))):
			return false
	return true


static func _open(id: int) -> bool:
	return id == BlockIds.AIR or (not BlockIds.is_solid(id) and id != BlockIds.WATER and id != BlockIds.SPRAY
		and id != BlockIds.CLOUD)
