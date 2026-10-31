class_name AlienRules
extends RefCounted
## The planets' friendly aliens as pure rules (owner #86, spec §21f).
## - Where they are: on the real bodies (the Moon, Mars, Europa, Io, Titan, Mercury; Venus's cloud city: on its camp
##   deck; Saturn's rings: on their camp chunk; Pluto; Triton; Ganymede) a travelling explorers' camp, on the playful planets (Planet Boing, Rainbow Planet) a village; each a short
##   walk from the landing pad and seen from
##   it (site: a ring RADII from the pad, the seed picks where round it; level, safe ground: the planet's plains, never
##   lava, methane, a well, a vent, a crater or a cliff; away from the landmark and the sights).
## - Friendship (the buddy system): an explorer asks for a sample of its planet (the rover digs one), a chief for a game
##   of Echo; then it is the child's friend (CreatureData.friends), gives a present (a souvenir) and asks to come along.
##   The one who comes along is a mini-buddy like a boss's (BuddyMagicData.minis: it follows its child into every
##   world, never takes a pet place, never fights); one alien at a time (CreatureData.buddy), the others stay friends.
## - Souvenirs: make-believe treasures sold by a camp's trader for Survivor gold, on the Gold Shop's DECORATIONS shelf
##   too (SpendRules.register, ids "alien:<souvenir>"); a new friend's present is a souvenir of its own (never sold).

const RADII: Array[int] = [34, 30, 38, 42, 27, 46, 50]
const ANGLE_STEPS := 32
## A camp's ground: (2 × CAMP_HALF + 1)² cells, looked at every SAMPLE_STEP, within STEP_MAX of its middle's height.
const CAMP_HALF := 4
const SAMPLE_STEP := 2
const STEP_MAX := 1
## Kept this far from the world's landmark (the rover, the landers, the Moon Base: SpaceSecretRules.landmark).
const LANDMARK_CLEAR := 22.0
## Walking this close to a camp's or village's middle visits it.
const VISIT_R := 9.0
## A village's layout round its square's middle (its front, -Z, towards the pad): four homes on HOME_RING, four drum
## pads round the middle, the chief beside them. A village stands among Planet Boing's giant mushrooms and Rainbow
## Planet's spires: none may grow out of a home (HOME_CLEAR), the square (SQUARE_CLEAR) or the chief's spot; their caps
## overhang higher than a home's roof.
const HOME_RING := 7.5
const HOME_ANGLES: Array[float] = [PI / 4.0, 3.0 * PI / 4.0, 5.0 * PI / 4.0, 7.0 * PI / 4.0]
const PAD_SPOTS: Array[Vector3] = [Vector3(0, 0, -1.7), Vector3(1.7, 0, 0), Vector3(0, 0, 1.7), Vector3(-1.7, 0, 0)]
const CHIEF_SPOT := Vector3(2.8, 0, -2.4)
const HOME_CLEAR := 2.0
const SQUARE_CLEAR := 3.2
const SQUARE_HALF := 3

## An alien's friendship with this child.
const NEW := &"new"               # not met yet
const WANTS := &"wants"           # met: it asks for a sample (an explorer) or a game of Echo (a chief)
const CAN_GIVE := &"can_give"     # an explorer, and the rover dug a sample in this world: GIVE A SAMPLE
const FRIEND := &"friend"         # a friend (it may come along)
const BUDDY := &"buddy"           # the friend who comes along

const MINI_PREFIX := "alien_"
const SHOP_PREFIX := "alien:"


static func has_camp(u: int) -> bool:
	return CreatureWords.CAMPS.has(u)


static func has_village(u: int) -> bool:
	return CreatureWords.VILLAGES.has(u)


## The aliens of world u who can become friends (a camp's explorer, a village's chief).
static func befriendable(u: int) -> StringName:
	if has_camp(u):
		return CreatureWords.CAMPS[u].explorer
	if has_village(u):
		return CreatureWords.VILLAGES[u].chief
	return &""


static func can_befriend(id: StringName) -> bool:
	var role: StringName = CreatureWords.alien(id).get("role", &"")
	return role == &"explorer" or role == &"chief"


# --- Where: the camp or the village ---------------------------------------------------------------------------------

## A camp's middle on a space world (half: its ground's half size): {pos: Vector3 (on the ground), yaw (its front,
## -Z, towards the pad)}. avoid: [{at: Vector2, r}] (the landmark, …). Every game finds the same spot from the seed.
static func site(shape: SpaceShape, world_seed: int, avoid: Array = [], half: int = CAMP_HALF) -> Dictionary:
	var spawn := shape.spawn_column()
	var start := absi(world_seed * 83492791 ^ 29717) % ANGLE_STEPS
	for r in RADII:
		for i in ANGLE_STEPS:
			var c := _ring_cell(spawn, r, start + i)
			if _clear(c, avoid) and _good(shape, c, half):
				return _spot(shape, c, spawn)
	return _spot(shape, _ring_cell(spawn, RADII[0], start), spawn)


## A village's middle on a playful planet (site's, with its own ground rules: level under its square, homes and chief,
## no mushroom or spire growing out of them: village_clear).
static func village_site(shape: SpaceShape, world_seed: int, avoid: Array = []) -> Dictionary:
	var spawn := shape.spawn_column()
	var start := absi(world_seed * 83492791 ^ 29717) % ANGLE_STEPS
	for r in RADII:
		for i in ANGLE_STEPS:
			var c := _ring_cell(spawn, r, start + i)
			if not _clear(c, avoid) or not _good(shape, c, SQUARE_HALF, false):
				continue
			var spot := _spot(shape, c, spawn)
			if village_clear(shape, spot.pos, float(spot.yaw)):
				return spot
	return _spot(shape, _ring_cell(spawn, RADII[0], start), spawn)


## Where a village's homes stand round its middle `at` turned by `yaw` (x, z in the world).
static func home_spots(at: Vector3, yaw: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for a in HOME_ANGLES:
		var p := Vector3(cos(a), 0, sin(a)).rotated(Vector3.UP, yaw) * HOME_RING
		out.append(Vector2(at.x + p.x, at.z + p.z))
	return out


## No mushroom stem or spire grows out of the village's homes, its square or its chief's spot; the homes stand on safe
## ground within two blocks of the square's height.
static func village_clear(shape: SpaceShape, at: Vector3, yaw: float) -> bool:
	var spots: Array = [[Vector2(at.x, at.z), SQUARE_CLEAR]]
	var chief := CHIEF_SPOT.rotated(Vector3.UP, yaw)
	spots.append([Vector2(at.x + chief.x, at.z + chief.z), 1.2])
	for h in home_spots(at, yaw):
		spots.append([h, HOME_CLEAR])
		if absi(shape.height_at(floori(h.x), floori(h.y)) - int(at.y)) > 2 or not safe_ground(shape, floori(h.x), floori(h.y)):
			return false
	for e: Array in spots:
		var middle: Vector2 = e[0]
		var r: float = e[1]
		for dz in range(floori(middle.y - r), ceili(middle.y + r) + 1):
			for dx in range(floori(middle.x - r), ceili(middle.x + r) + 1):
				if Vector2(dx + 0.5, dz + 0.5).distance_to(middle) <= r + 0.71 and shape.tree_at(dx, dz):
					return false
	return true


## Safe, calm ground for a camp: the planet's plains (never lava, methane, a well, a vent, a crater's bowl, a cliff, a
## cap's edge, a jelly pool), no feature growing there, no sight.
static func safe_ground(shape: SpaceShape, x: int, z: int) -> bool:
	if shape.venus != null and not shape.venus.camp_spot(x, z):   # cosmos: Venus's aliens camp on their own deck
		return false
	if shape.rings != null and not shape.rings.camp_spot(x, z):   # cosmos: the rings' aliens camp on their own chunk
		return false
	if shape.is_river(x, z) or shape.tree_at(x, z) or shape.sight_at(x, z) != &"":
		return false
	match shape.planet:
		SpaceShape.MOON:
			return shape.crater_depth(x, z) > -1.0
		SpaceShape.BOING:
			return shape.ground_at(x, z) > SpaceShape.JELLY_LEVEL + 1 and not shape.near_pool(x, z)
		SpaceShape.MARS:
			return shape.mars_kind(x, z) in [MarsTerrain.PLAINS, MarsTerrain.FROST_N, MarsTerrain.FROST_S]
		SpaceShape.EUROPA:
			return shape.europa_kind(x, z) == EuropaTerrain.PLAINS
		SpaceShape.IO:
			return IoTerrain.is_plains(shape.io_kind(x, z))
		SpaceShape.TITAN:
			return TitanTerrain.is_plains(shape.titan_kind(x, z))
		SpaceShape.MERCURY:
			return MercuryTerrain.is_plains(shape.mercury_kind(x, z))
		SpaceShape.VENUS:   # the camp deck (above): its cream deck, never its rim
			return shape.venus_kind(x, z) == VenusTerrain.DECK
		SpaceShape.RINGS:   # the camp chunk (above): its frosty top
			return shape.rings_kind(x, z) == RingsTerrain.ICE_FLAT
		SpaceShape.PLUTO:   # the peach-tan uplands (never the plain's ice, the mountains or the lookout)
			return PlutoTerrain.is_plains(shape.pluto_kind(x, z))
		SpaceShape.TRITON:   # the band of frost (never the cap's geysers, the lake, the crater or the lookout)
			return TritonTerrain.is_plains(shape.triton_kind(x, z))
		SpaceShape.GANYMEDE:   # the smooth plain (never the grooves, the crater, the frost or a built part)
			return GanymedeTerrain.is_plains(shape.ganymede_kind(x, z)) and not shape.ganymede.on_part(x, z, 2)
	return true


static func _good(shape: SpaceShape, c: Vector2i, half: int, features := true) -> bool:
	var h := shape.height_at(c.x, c.y)
	for dz in range(-half, half + 1, SAMPLE_STEP):   # level, safe ground (the cheaper look first)
		for dx in range(-half, half + 1, SAMPLE_STEP):
			var x := c.x + dx
			var z := c.y + dz
			if absi(shape.height_at(x, z) - h) > STEP_MAX or not safe_ground(shape, x, z):
				return false
	var trees := half + shape.feature_reach() + 2
	for dz in range(-trees, trees + 1):   # no feature on it or leaning over it (a boulder, a crystal): every cell
		for dx in range(-trees, trees + 1):
			if features and shape.tree_at(c.x + dx, c.y + dz):
				return false
	return true


static func _clear(c: Vector2i, avoid: Array) -> bool:
	for o: Dictionary in avoid:
		var at: Vector2 = o.get("at", Vector2.INF)
		if at.is_finite() and Vector2(c).distance_to(at) < float(o.get("r", 0.0)):
			return false
	return true


static func _ring_cell(spawn: Vector2i, r: int, step: int) -> Vector2i:
	var a := TAU * (step % ANGLE_STEPS) / ANGLE_STEPS
	return spawn + Vector2i(roundi(cos(a) * r), roundi(sin(a) * r))


static func _spot(shape: SpaceShape, c: Vector2i, spawn: Vector2i) -> Dictionary:
	var d := Vector2(spawn - c)
	return {"pos": Vector3(c.x + 0.5, float(shape.height_at(c.x, c.y)), c.y + 0.5), "yaw": atan2(-d.x, -d.y)}


# --- Friendship: the buddy system -------------------------------------------------------------------------------------

## What alien `id` and this child are now. has_sample: the rover dug a sample in this world (RobotRules.SAMPLE).
static func state(data: CreatureData, id: StringName, has_sample: bool) -> StringName:
	if data.is_friend(id):
		return BUDDY if data.buddy == String(id) else FRIEND
	if not data.has_met(id):
		return NEW
	if CreatureWords.alien(id).get("role", &"") == &"explorer" and has_sample:
		return CAN_GIVE
	return WANTS


## `id` becomes this child's friend: its present (a souvenir) is theirs, and its mini-buddy's record waits in the
## profile (BuddyMagicData.minis) to come along. The present's id, or "" when it was a friend already.
static func befriend(profile: ProfileData, id: StringName) -> String:
	if not can_befriend(id) or not profile.creatures.befriend(id):
		return ""
	var kind := mini_kind(id)
	if not profile.buddy_magic.minis.has(String(kind)):
		profile.buddy_magic.minis[String(kind)] = MiniRules.record(kind)
	var gift := str(CreatureWords.alien(id).get("gift", ""))
	profile.creatures.add_souvenir(gift)
	return gift


## Friend `id` comes along (into every world): the one before it goes back to its camp (its id, "" for none). Nothing
## changes for an alien that is not a friend.
static func come_along(profile: ProfileData, id: StringName) -> String:
	var data := profile.creatures
	if not data.is_friend(id) or data.buddy == String(id):
		return ""
	var before := data.buddy
	data.buddy = String(id)
	var kind := String(mini_kind(id))
	if not profile.buddy_magic.minis.has(kind):
		profile.buddy_magic.minis[kind] = MiniRules.record(mini_kind(id))
	return before


## The buddy goes back to its camp (a friend still).
static func stay_home(profile: ProfileData) -> String:
	var before := profile.creatures.buddy
	profile.creatures.buddy = ""
	return before


## Alien `id`'s mini-buddy kind (MiniRules.MINIS): "alien_<id>".
static func mini_kind(id: StringName) -> StringName:
	return StringName(MINI_PREFIX + String(id))


static func is_alien_kind(kind: StringName) -> bool:
	return String(kind).begins_with(MINI_PREFIX) and can_befriend(alien_of_kind(kind))


static func alien_of_kind(kind: StringName) -> StringName:
	return StringName(String(kind).trim_prefix(MINI_PREFIX))


## Does a mini of `kind` come into this world with its child (BuddyMagicDirector.bring_minis)? A boss's always; an
## alien only while it is the buddy.
static func comes_along(profile: ProfileData, kind: StringName) -> bool:
	if not is_alien_kind(kind):
		return true
	return profile.creatures.buddy == String(alien_of_kind(kind))


# --- Souvenirs --------------------------------------------------------------------------------------------------------

## The souvenirs a camp's trader sells.
static func stock(trader: StringName) -> Array[String]:
	var out: Array[String] = []
	for id: Variant in CreatureWords.alien(trader).get("souvenirs", []):
		out.append(str(id))
	return out


static func price(id: String) -> int:
	var s := CreatureWords.souvenir(id)
	return 0 if s.is_empty() or bool(s.get("gift", false)) else int(s.get("price", 0))


## Hangs every sold souvenir on the Gold Shop's DECORATIONS shelf (once; SpendRules.register ignores a repeat).
static func register_shelf() -> void:
	for id: String in CreatureWords.SOUVENIRS:
		if price(id) > 0:
			SpendRules.register(SpendRules.DECOR, {"id": SHOP_PREFIX + id, "name": str(CreatureWords.SOUVENIRS[id].name),
				"price": price(id)},
				func(profile: ProfileData, shop_id: String) -> void: profile.creatures.add_souvenir(shop_id.trim_prefix(SHOP_PREFIX)))


## Buys souvenir `id` with the profile's Survivor gold (SpendRules.buy: OK, OWNED, NOT_ENOUGH, UNKNOWN). The caller
## saves.
static func buy(profile: ProfileData, id: String) -> StringName:
	if price(id) <= 0:
		return SpendRules.UNKNOWN
	if profile.creatures.owns(id):
		return SpendRules.OWNED
	register_shelf()
	return SpendRules.buy(profile, SHOP_PREFIX + id)
