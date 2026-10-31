class_name AnimalRules
extends RefCounted
## Animals, as pure rules: the species table, deterministic spawning per 32×32 area (herds on
## grass, schools of fish in water at least 2 deep), the per-player cap, despawning far-away wild
## animals, taming dogs and cats (3 pets within 4 s), safe steps (land animals never walk into
## water or off a cliff; fish never leave the water) and fleeing from a player rushing at them.
## Owner feedback #26 (it overrules M1b's "nobody can hurt animals"): health by kind, who can be hurt,
## what a defeated animal leaves in Survivor, and how slowly herds refill (the section at the end).

const CELL := 32
const SPAWN_CHANCE := 0.45        # chance that an area has a herd
const MAX_PER_PLAYER := 20
const SPAWN_RADIUS := 48.0        # areas this close to a player get their animals
const DESPAWN_DISTANCE := 80.0    # wild animals farther than this from every player leave
const MAX_PETS := 3               # per player
const TAME_TAPS := 3
const TAME_WINDOW := 4.0          # seconds
const FLEE_DISTANCE := 4.5
const FLEE_SPEED := 4.5           # a player moving faster than this towards an animal scares it
const MAX_DROP := 2               # a land animal never steps down more than this
const SUMMON_CAP := MAX_PER_PLAYER + 10   # wild herds fill up to MAX_PER_PLAYER; /summon adds a few
const CROWDED_MESSAGE := "Lots of animals here already!"
const NO_WATER_MESSAGE := "Fish need water nearby!"
const WATER_SEARCH := 3           # /summon fish looks this far around the player for water
const SUMMON_SIDES: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1), Vector2i(1, -1)]
const LOOK_DISTANCE := 6.0        # a standing animal turns to look at a player this close
## Only animals this close to a player are simulated; farther wild animals rest where they are
## (M1b acceptance: ~20 animals simulated every physics step made frames of up to 150 ms).
const ACTIVE_DISTANCE := 32.0
## Pet collars: each player's pets wear one of these (by peer id; the host is peer 1).
const COLLAR_COLORS: Array[Color] = [Color("e8413c"), Color("2f7fe0"), Color("f2c230"), Color("3cbf5a"),
	Color("a05be0"), Color("f08a2c"), Color("e05ba8"), Color("34c6c9")]

## habitat, size (x, y, z blocks), walk speed, hop height, sound, spawn weight (land), herd size,
## colours (body, detail) and whether players can tame it as a pet.
const SPECIES := {
	&"dog": {"habitat": &"land", "size": Vector3(0.6, 0.75, 1.05), "speed": 3.4, "hop": 1.1, "sound": &"bark",
		"weight": 10, "herd": Vector2i(1, 2), "colors": [Color("c8924e"), Color("f3e3c3")], "tameable": true},
	&"cat": {"habitat": &"land", "size": Vector3(0.45, 0.6, 0.85), "speed": 3.0, "hop": 1.2, "sound": &"meow",
		"weight": 10, "herd": Vector2i(1, 1), "colors": [Color("e8a24a"), Color("fbe9d0")], "tameable": true},
	&"pig": {"habitat": &"land", "size": Vector3(0.85, 0.8, 1.2), "speed": 2.0, "hop": 1.0, "sound": &"oink",
		"weight": 15, "herd": Vector2i(2, 4), "colors": [Color("f3a5b5"), Color("e27c93")], "tameable": false},
	&"cow": {"habitat": &"land", "size": Vector3(1.0, 1.3, 1.7), "speed": 1.6, "hop": 1.0, "sound": &"moo",
		"weight": 14, "herd": Vector2i(2, 4), "colors": [Color("f4f1ea"), Color("3b2f2a")], "tameable": false},
	&"sheep": {"habitat": &"land", "size": Vector3(0.9, 1.05, 1.3), "speed": 1.8, "hop": 1.0, "sound": &"baa",
		"weight": 18, "herd": Vector2i(2, 5), "colors": [Color("f7f5ef"), Color("5a4a44")], "tameable": false},
	&"chicken": {"habitat": &"land", "size": Vector3(0.45, 0.65, 0.5), "speed": 2.2, "hop": 1.0, "sound": &"cluck",
		"weight": 15, "herd": Vector2i(2, 5), "colors": [Color("fdfbf5"), Color("f2b632")], "tameable": false},
	&"rabbit": {"habitat": &"land", "size": Vector3(0.4, 0.5, 0.55), "speed": 3.6, "hop": 1.3, "sound": &"squeak",
		"weight": 14, "herd": Vector2i(1, 3), "colors": [Color("b89a7c"), Color("fff7ee")], "tameable": false},
	&"fish": {"habitat": &"water", "size": Vector3(0.3, 0.3, 0.65), "speed": 2.4, "hop": 0.0, "sound": &"blub",
		"weight": 0, "herd": Vector2i(3, 6), "colors": [Color("ff8a3d"), Color("ffe08a")], "tameable": false},
	# M3 Task 11 (PetRules): the fox (by the woods) and the parrot (by the water) are never picked by weight:
	# wild_pet_at puts them where they live; Pip the robot is only ever given (never wild).
	&"fox": {"habitat": &"land", "size": Vector3(0.45, 0.6, 0.95), "speed": 3.6, "hop": 1.2, "sound": &"yip",
		"weight": 0, "herd": Vector2i(1, 1), "colors": [Color("e0712c"), Color("fbf3e6")], "tameable": true},
	&"parrot": {"habitat": &"land", "size": Vector3(0.4, 0.6, 0.45), "speed": 3.4, "hop": 1.4, "sound": &"squawk",
		"weight": 0, "herd": Vector2i(1, 2), "colors": [Color("e23b3b"), Color("3fae4b")], "tameable": true},
	&"pip": {"habitat": &"land", "size": Vector3(0.5, 0.85, 0.5), "speed": 3.8, "hop": 1.2, "sound": &"beep",
		"weight": 0, "herd": Vector2i(1, 1), "colors": [Color("b9c3cf"), Color("3ab0ff")], "tameable": false},
	# owner 39: the pet dragon (hatched or given, never wild; "tameable" so a hatched one is saved with the world's
	# pets); it flies beside its child in the air (PetRules.glides)
	&"dragon": {"habitat": &"land", "size": Vector3(0.5, 0.6, 0.85), "speed": 3.8, "hop": 1.4, "sound": &"dragon_chirp",
		"weight": 0, "herd": Vector2i(1, 1), "colors": [Color("3fbf9f"), Color("c38bff")], "tameable": true,
		"flies": true},
	# Owner feedback #41: more animals (spec §14.19). Weight 0: AnimalHomes places them. Optional keys: "swims"
	# (floats on the water's top), "walk_hop" and "hop_every" (its walking hops), "climb" (blocks it hops up),
	# "shy" (runs from anyone walking up within this many blocks), "curls" (curls up instead of running),
	# "slides" (belly-slides on ice), "trees" (runs up tree trunks), "nocturnal" (awake at night), "lays" (eggs).
	&"horse": {"habitat": &"land", "size": Vector3(0.8, 1.6, 1.7), "speed": 2.4, "hop": 1.1, "sound": &"neigh",
		"weight": 0, "herd": Vector2i(1, 3), "colors": [Color("8b5a2b"), Color("3b2a20")], "tameable": true},
	&"donkey": {"habitat": &"land", "size": Vector3(0.65, 1.3, 1.3), "speed": 1.9, "hop": 1.0, "sound": &"bray",
		"weight": 0, "herd": Vector2i(1, 2), "colors": [Color("8e8a86"), Color("dcd6cc")], "tameable": true},
	&"goat": {"habitat": &"land", "size": Vector3(0.5, 0.85, 0.85), "speed": 2.4, "hop": 2.3, "sound": &"bleat",
		"weight": 0, "herd": Vector2i(2, 3), "colors": [Color("efe9df"), Color("8a7a66")], "tameable": false, "climb": 2},
	&"deer": {"habitat": &"land", "size": Vector3(0.5, 1.25, 1.1), "speed": 3.0, "hop": 1.3, "sound": &"deer_call",
		"weight": 0, "herd": Vector2i(1, 3), "colors": [Color("b5773f"), Color("f6ead2")], "tameable": false, "shy": 9.0},
	&"duck": {"habitat": &"land", "size": Vector3(0.35, 0.5, 0.5), "speed": 1.6, "hop": 1.0, "sound": &"quack",
		"weight": 0, "herd": Vector2i(2, 4), "colors": [Color("7a5c3e"), Color("2e7d32")], "tameable": false, "swims": true},
	&"frog": {"habitat": &"land", "size": Vector3(0.3, 0.25, 0.35), "speed": 2.2, "hop": 1.0, "sound": &"croak",
		"weight": 0, "herd": Vector2i(1, 3), "colors": [Color("4caf50"), Color("d6eeb0")], "tameable": false, "swims": true,
		"walk_hop": 0.75, "hop_every": 0.8},
	&"turtle": {"habitat": &"land", "size": Vector3(0.55, 0.35, 0.7), "speed": 0.6, "hop": 0.9, "sound": &"turtle",
		"weight": 0, "herd": Vector2i(1, 2), "colors": [Color("4e6b2e"), Color("9ccc65")], "tameable": false, "swims": true,
		"walk_hop": 0.08, "lays": true},
	&"squirrel": {"habitat": &"land", "size": Vector3(0.3, 0.45, 0.55), "speed": 3.4, "hop": 1.2, "sound": &"chatter",
		"weight": 0, "herd": Vector2i(1, 2), "colors": [Color("c0602a"), Color("f3e3c3")], "tameable": false, "trees": true},
	&"owl": {"habitat": &"land", "size": Vector3(0.4, 0.65, 0.4), "speed": 2.0, "hop": 1.2, "sound": &"hoot",
		"weight": 0, "herd": Vector2i(1, 1), "colors": [Color("8d6e4f"), Color("eadcbc")], "tameable": false, "nocturnal": true},
	&"hedgehog": {"habitat": &"land", "size": Vector3(0.35, 0.3, 0.5), "speed": 1.2, "hop": 0.8, "sound": &"snuffle",
		"weight": 0, "herd": Vector2i(1, 2), "colors": [Color("6d5a4a"), Color("dcbd9e")], "tameable": false, "curls": true},
	&"camel": {"habitat": &"land", "size": Vector3(0.8, 1.9, 1.7), "speed": 1.6, "hop": 1.0, "sound": &"camel_grunt",
		"weight": 0, "herd": Vector2i(1, 3), "colors": [Color("d2a86a"), Color("9c7442")], "tameable": true},
	&"lizard": {"habitat": &"land", "size": Vector3(0.25, 0.18, 0.55), "speed": 4.0, "hop": 1.0, "sound": &"gecko",
		"weight": 0, "herd": Vector2i(1, 2), "colors": [Color("3aa37a"), Color("f2c14e")], "tameable": false, "walk_hop": 0.1},
	&"fennec": {"habitat": &"land", "size": Vector3(0.35, 0.5, 0.6), "speed": 3.4, "hop": 1.2, "sound": &"fennec",
		"weight": 0, "herd": Vector2i(1, 2), "colors": [Color("efcf98"), Color("fff7ea")], "tameable": true},
	&"penguin": {"habitat": &"land", "size": Vector3(0.4, 0.75, 0.4), "speed": 1.2, "hop": 0.9, "sound": &"penguin",
		"weight": 0, "herd": Vector2i(2, 4), "colors": [Color("22252b"), Color("f7f7f7")], "tameable": false, "swims": true,
		"slides": true},
	&"polar_bear": {"habitat": &"land", "size": Vector3(1.0, 1.35, 1.9), "speed": 1.6, "hop": 1.0, "sound": &"bear_huff",
		"weight": 0, "herd": Vector2i(1, 1), "colors": [Color("f4f1e6"), Color("2a2a2a")], "tameable": false, "swims": true},
	&"arctic_fox": {"habitat": &"land", "size": Vector3(0.4, 0.55, 0.9), "speed": 3.6, "hop": 1.2, "sound": &"arctic_yip",
		"weight": 0, "herd": Vector2i(1, 2), "colors": [Color("f5f7fa"), Color("b6c2ce")], "tameable": true},
	&"seal": {"habitat": &"land", "size": Vector3(0.55, 0.5, 1.3), "speed": 0.8, "hop": 0.6, "sound": &"seal_bark",
		"weight": 0, "herd": Vector2i(1, 3), "colors": [Color("8c939c"), Color("5e646c")], "tameable": false, "swims": true,
		"slides": true, "walk_hop": 0.12},
	&"gummy_bunny": {"habitat": &"land", "size": Vector3(0.4, 0.5, 0.5), "speed": 3.0, "hop": 1.6, "sound": &"gummy_squeak",
		"weight": 0, "herd": Vector2i(2, 4), "colors": [Color("ff4f7b"), Color("ffd1dc")], "tameable": false,
		"walk_hop": 0.9, "hop_every": 0.55},
	&"candy_bird": {"habitat": &"land", "size": Vector3(0.3, 0.4, 0.4), "speed": 3.0, "hop": 1.4, "sound": &"chirp",
		"weight": 0, "herd": Vector2i(2, 3), "colors": [Color("7fd3ff"), Color("ff8fc8")], "tameable": false,
		"walk_hop": 0.45},
	# Owner #55 (spec §21.2): the Moon's own animal, silver-white with pale blue ears, in big floaty hops
	&"moon_bunny": {"habitat": &"land", "size": Vector3(0.4, 0.5, 0.55), "speed": 3.2, "hop": 2.2, "sound": &"squeak",
		"weight": 0, "herd": Vector2i(2, 4), "colors": [Color("eef1f8"), Color("9fdcff")], "tameable": false,
		"walk_hop": 1.3, "hop_every": 0.95},
	# M3 Task 20b (buddy magic): a monster befriended with the wand (BefriendRules; its monster kind is the animal's
	# variant; saved with the world's pets) and a boss's mini-buddy (MiniRules; the boss kind; it lives in the profile
	# like Pip). Only ever pets, never wild; their looks are MagicPetModels' (shared meshes).
	&"monster_friend": {"habitat": &"land", "size": Vector3(0.6, 0.8, 0.6), "speed": 3.6, "hop": 1.2, "sound": &"gummy_squeak",
		"weight": 0, "herd": Vector2i(1, 1), "colors": [Color("009e73"), Color("fbfbfb")], "tameable": true},
	&"mini_boss": {"habitat": &"land", "size": Vector3(0.6, 0.8, 0.6), "speed": 3.8, "hop": 1.2, "sound": &"dragon_chirp",
		"weight": 0, "herd": Vector2i(1, 1), "colors": [Color("8d9199"), Color("5d8f3a")], "tameable": false},
}


## Green Meadows' animals (its descriptor's `animals`): the kinds a world grows when nobody names others.
const MEADOWS_KINDS: Array[StringName] = [&"dog", &"cat", &"pig", &"cow", &"sheep", &"chicken", &"rabbit", &"fish",
	&"fox", &"parrot", &"horse", &"donkey", &"goat", &"deer", &"duck", &"frog", &"turtle", &"squirrel", &"owl", &"hedgehog"]


## The animals of area `cell` (x, z / 32): [{"species", "pos": Vector3, "id": String}]. `kinds`: the animals
## this world's universe names (owner #41; empty: Green Meadows'). Green Meadows' farm herds come from the
## species weights (M1b), then foxes and parrots (M3 Task 11), then the new kinds (AnimalHomes.pack_at); a
## universe without farm animals picks its own kinds by where they live (AnimalHomes.pick_at).
static func spawns_for_cell(shape: MeadowsShape, cell: Vector2i, kinds: Array = []) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if kinds.is_empty():
		kinds = MEADOWS_KINDS
	var rng := RandomNumberGenerator.new()
	rng.seed = _mix(shape.seed, cell.x, cell.y)
	if rng.randf() >= SPAWN_CHANCE:
		return out
	var center := cell * CELL + Vector2i(rng.randi_range(4, CELL - 5), rng.randi_range(4, CELL - 5))
	var species := _species_at(shape, center.x, center.y, rng, kinds)
	if species == &"" and not _has_farm(kinds):
		if _spot(shape, &"sheep", center.x, center.y).is_finite() or AnimalHomes.on_ice(shape, center.x, center.y):
			species = AnimalHomes.pick_at(shape, center, kinds, rng)   # owner #41: the universe's own kinds
	elif species != &"":
		if kinds.has(&"fox") or kinds.has(&"parrot"):
			species = wild_pet_at(shape, cell, center, species)   # M3 Task 11: foxes by the woods, parrots by the water
		species = AnimalHomes.pack_at(shape, cell, center, species, kinds)   # owner #41: the new kinds
	if species == &"" or not kinds.has(species):
		return out
	var herd: Vector2i = SPECIES[species].herd
	var count := rng.randi_range(herd.x, herd.y)
	for i in count:
		var x := center.x + (0 if i == 0 else rng.randi_range(-4, 4))
		var z := center.y + (0 if i == 0 else rng.randi_range(-4, 4))
		var pos := _spot(shape, species, x, z)
		if pos.is_finite():
			out.append({"species": species, "pos": pos, "id": "a%d_%d_%d" % [cell.x, cell.y, i]})
	return out


## The farm herd of column (x, z) by the species weights (M1b), among `kinds`: fish in deep water, &"" where
## no land animal stands or when `kinds` has no farm animals (owner #41: AnimalHomes picks those).
static func _species_at(shape: MeadowsShape, x: int, z: int, rng: RandomNumberGenerator, kinds: Array = MEADOWS_KINDS) -> StringName:
	if kinds.has(&"fish") and _spot(shape, &"fish", x, z).is_finite():
		return &"fish"
	if not _spot(shape, &"sheep", x, z).is_finite():
		return &""
	if not _has_farm(kinds):
		return &""
	var total := 0
	for sp: StringName in SPECIES:
		if kinds.has(sp):
			total += SPECIES[sp].weight
	var pick := rng.randi_range(0, total - 1)
	for sp: StringName in SPECIES:
		if kinds.has(sp):
			pick -= SPECIES[sp].weight
			if pick < 0:
				return sp
	return &"sheep"


## Does `kinds` hold any of M1b's farm animals (picked by their weights)?
static func _has_farm(kinds: Array) -> bool:
	for sp: StringName in kinds:
		if SPECIES.has(sp) and int(SPECIES[sp].weight) > 0:
			return true
	return false


## Where an animal of this habitat stands or swims in column (x, z), or Vector3.INF if it can't. Owner #41:
## a kind that lives on the ice lies on a frozen lake's ice (Frostpeak).
static func _spot(shape: MeadowsShape, species: StringName, x: int, z: int) -> Vector3:
	var h := shape.height_at(x, z)
	if AnimalHomes.biomes(species).has(AnimalHomes.ICE) and AnimalHomes.on_ice(shape, x, z):
		return Vector3(x + 0.5, MeadowsShape.SEA_LEVEL, z + 0.5)
	if SPECIES[species].habitat == &"water":
		if MeadowsShape.SEA_LEVEL - h < 2:
			return Vector3.INF
		return Vector3(x + 0.5, (h + MeadowsShape.SEA_LEVEL) * 0.5, z + 0.5)
	if h <= MeadowsShape.SEA_LEVEL + 1 or shape.is_river(x, z) or shape.tree_at(x, z):
		return Vector3.INF
	return Vector3(x + 0.5, h, z + 0.5)


## How many more animals may spawn around a player who has `nearby` already.
static func spawn_budget(nearby: int) -> int:
	return maxi(MAX_PER_PLAYER - nearby, 0)


## Why /summon can't bring a `species` to a player standing at `near` ("" = it can). `animals`:
## where every animal is; `spot`: where this one would appear (Vector3.INF: no place for it).
static func summon_refusal(species: StringName, near: Vector3, animals: Array[Vector3], spot: Vector3) -> String:
	if not spot.is_finite():
		return NO_WATER_MESSAGE if SPECIES[species].habitat == &"water" else CROWDED_MESSAGE
	var nearby := 0
	for pos in animals:
		if Vector2(pos.x - near.x, pos.z - near.z).length() <= SPAWN_RADIUS * 1.5:
			nearby += 1
	return CROWDED_MESSAGE if nearby >= SUMMON_CAP else ""


## Where a summoned land animal appears: standing on the ground of a column next to the player,
## never inside a block (beside a 1-block rise it used to start inside the block and fall out of the
## world; found by the acceptance tour). Searches near the feet, not the surface, so it works in
## caves too. start: which neighbour to try first (varies between summons). At the player's feet when
## no neighbour has room.
static func summon_spot(near: Vector3, block_at: Callable, start: int) -> Vector3:
	var feet := Vector3i(near.floor())
	for i in SUMMON_SIDES.size():
		var side: Vector2i = SUMMON_SIDES[(start + i) % SUMMON_SIDES.size()]
		for dy in [0, 1, -1, 2, -2]:
			var cell := feet + Vector3i(side.x, dy, side.y)
			if BlockIds.is_solid(block_at.call(cell + Vector3i.DOWN)) and not BlockIds.is_solid(block_at.call(cell)) \
					and not BlockIds.is_solid(block_at.call(cell + Vector3i.UP)):
				return Vector3(cell.x + 0.5, cell.y, cell.z + 0.5)
	return Vector3(near.x, feet.y, near.z)


## The middle of the water cell nearest to `near` (within WATER_SEARCH blocks), or Vector3.INF.
static func water_spot(near: Vector3, block_at: Callable) -> Vector3:
	var feet := Vector3i(near.floor())
	var best := Vector3.INF
	var best_d := INF
	for dy in range(-WATER_SEARCH, 2):
		for dz in range(-WATER_SEARCH, WATER_SEARCH + 1):
			for dx in range(-WATER_SEARCH, WATER_SEARCH + 1):
				var cell := feet + Vector3i(dx, dy, dz)
				if block_at.call(cell) != BlockIds.WATER:
					continue
				var center := Vector3(cell) + Vector3(0.5, 0.5, 0.5)
				var d := center.distance_squared_to(near)
				if d < best_d:
					best_d = d
					best = center
	return best


## True when the animal at `pos` should be simulated: a pet (it follows its owner anywhere), or a
## wild animal within ACTIVE_DISTANCE (sideways) of a player.
static func is_active(pos: Vector3, players: Array[Vector3], is_pet: bool) -> bool:
	if is_pet:
		return true
	for p in players:
		if Vector2(p.x - pos.x, p.z - pos.z).length_squared() <= ACTIVE_DISTANCE * ACTIVE_DISTANCE:
			return true
	return false


## The yaw that turns an animal at `pos` to face the nearest player within LOOK_DISTANCE (models
## face -Z), or NAN when nobody is that close.
static func look_yaw(pos: Vector3, players: Array[Vector3]) -> float:
	var best := LOOK_DISTANCE
	var yaw := NAN
	for p in players:
		var to := Vector2(p.x - pos.x, p.z - pos.z)
		var d := to.length()
		if d <= best and d > 0.01:
			best = d
			yaw = atan2(-to.x, -to.y)
	return yaw


## The collar colour of `owner_peer`'s pets: the same on every device (owner_peer is synced).
static func collar_color(owner_peer: int) -> Color:
	return COLLAR_COLORS[posmod(owner_peer - 1, COLLAR_COLORS.size())]


static func should_despawn(pos: Vector3, players: Array[Vector3], is_pet: bool) -> bool:
	if is_pet or players.is_empty():   # nobody around for a moment (a knock-out's getting up): stay
		return false
	for p in players:
		if Vector2(pos.x - p.x, pos.z - p.z).length() <= DESPAWN_DISTANCE:
			return false
	return true


## Adds a pet (tap) at time `now`. Returns {"taps": recent taps, "tamed": bool}.
static func tame_tap(taps: Array[float], now: float) -> Dictionary:
	var recent: Array[float] = []
	for t in taps:
		if now - t <= TAME_WINDOW:
			recent.append(t)
	recent.append(now)
	return {"taps": recent, "tamed": recent.size() >= TAME_TAPS}


static func can_tame(species: StringName, pets_owned: int) -> bool:
	return SPECIES.has(species) and SPECIES[species].tameable and pets_owned < MAX_PETS


## May an animal move into the cell `target` (at its feet)? block_at(pos) -> block id.
static func can_step(species: StringName, target: Vector3i, block_at: Callable) -> bool:
	var at_feet: int = block_at.call(target)
	if SPECIES[species].habitat == &"water":
		return at_feet == BlockIds.WATER
	if at_feet == BlockIds.WATER:
		return swims(species)          # owner #41: ducks, frogs, turtles, penguins, seals and polar bears swim
	if swims(species) and block_at.call(target + Vector3i.DOWN) == BlockIds.WATER:
		return true                    # onto the water's top
	for d in range(1, MAX_DROP + 2):
		var below: int = block_at.call(target - Vector3i(0, d, 0))
		if below == BlockIds.WATER:
			return false
		if below != BlockIds.AIR:
			return true            # ground within reach: flat, or a 1-2 block dip
	return false                   # a deeper drop


## Direction to run when a player rushes at the animal, or ZERO when it is calm.
static func flee_direction(animal: Vector3, player: Vector3, player_velocity: Vector3) -> Vector3:
	var away := Vector3(animal.x - player.x, 0.0, animal.z - player.z)
	var dist := away.length()
	if dist > FLEE_DISTANCE or dist < 0.001:
		return Vector3.ZERO
	var toward := Vector3(player_velocity.x, 0.0, player_velocity.z).dot(away / dist)
	if toward < FLEE_SPEED:
		return Vector3.ZERO
	return away / dist


# --- Owner feedback #26: animals can be defeated (it overrules M1b's "never hurt") ---------------

## Health by kind: small animals, medium ones, and the big cow (a wooden sword hits for 4, fists for 1).
const HEALTH := {&"chicken": 3, &"rabbit": 3, &"fish": 3, &"pig": 6, &"sheep": 6, &"dog": 6, &"cat": 6, &"cow": 9,
	&"parrot": 3, &"fox": 6, &"pip": 6, &"dragon": 6,   # M3 Task 11; owner 39
	# owner #41: small 3, medium 6, big 9, the polar bear 12
	&"horse": 9, &"donkey": 9, &"goat": 6, &"deer": 6, &"duck": 3, &"frog": 3, &"turtle": 6, &"squirrel": 3, &"owl": 3,
	&"hedgehog": 3, &"camel": 9, &"lizard": 3, &"fennec": 6, &"penguin": 6, &"polar_bear": 12, &"arctic_fox": 6,
	&"seal": 9, &"gummy_bunny": 3, &"candy_bird": 3, &"moon_bunny": 3,   # owner #55
	&"monster_friend": 6, &"mini_boss": 6}   # M3 Task 20b (pets: only ever pushed)
## Seconds before a defeated herd animal comes back to its area (AnimalDirector): slowly, so a hunt
## thins a herd for a while, but a world never runs empty.
const REFILL_TIME := 180.0
## What a defeated animal leaves in Survivor, in its defeater's bag: a little of a building block, never
## gold nor anything Tilly buys (ShopRules.SELL_PRICES), so herds that refill are never a gold farm.
## Dogs and cats (the pets-to-be) leave nothing. Sheep leave "wool": a colour block of their own.
const DROPS := {&"chicken": [[BlockIds.YELLOW, 1]], &"rabbit": [[BlockIds.GRASS, 1]], &"fish": [[BlockIds.BLUE, 1]],
	&"pig": [[BlockIds.DIRT, 2]], &"cow": [[BlockIds.BED, 1]], &"dog": [], &"cat": [],
	&"fox": [], &"parrot": [], &"pip": [], &"dragon": [],   # M3 Task 11: the pets-to-be leave nothing; owner 39
	# owner #41: a little of a block of its place; the pets-to-be (horse, donkey, camel, fennec, arctic fox) nothing
	&"horse": [], &"donkey": [], &"camel": [], &"fennec": [], &"arctic_fox": [],
	&"goat": [[BlockIds.DIRT, 1]], &"deer": [[BlockIds.LEAVES, 1]], &"duck": [[BlockIds.YELLOW, 1]],
	&"frog": [[BlockIds.GREEN, 1]], &"turtle": [[BlockIds.SAND, 2]], &"squirrel": [[BlockIds.LEAVES, 1]],
	&"owl": [[BlockIds.PLANKS, 1]], &"hedgehog": [[BlockIds.DIRT, 1]], &"lizard": [[BlockIds.SAND, 1]],
	&"penguin": [[BlockIds.SNOW, 1]], &"polar_bear": [[BlockIds.SNOW, 2]], &"seal": [[BlockIds.SNOW, 1]],
	&"gummy_bunny": [[BlockIds.GUMDROP, 1]], &"candy_bird": [[BlockIds.SPRINKLES, 1]],
	&"moon_bunny": [[BlockIds.MOON_DUST, 1]],   # owner #55
	&"monster_friend": [], &"mini_boss": []}   # M3 Task 20b: pets, never defeated
const WOOL: Array[int] = [BlockIds.RED, BlockIds.YELLOW, BlockIds.GREEN, BlockIds.BLUE, BlockIds.PURPLE]
const WOOL_COUNT := 2


static func max_hp(species: StringName) -> int:
	return int(HEALTH.get(species, 6))


## Pets are never hurt, by anyone (their owner, the owner's friends or any other player), and golden
## animals are never hurt either (they are caught with a tap, M2 Task 16): a hit only pushes them.
static func can_be_hurt(is_pet: bool, golden: bool) -> bool:
	return not is_pet and not golden


## [[block id, count], ...] a defeated animal of `species` with id `animal_id` leaves (Survivor).
static func drops(species: StringName, animal_id: String) -> Array:
	if species == &"sheep":
		return [[WOOL[absi(hash(animal_id)) % WOOL.size()], WOOL_COUNT]]
	return (DROPS.get(species, []) as Array).duplicate(true)


## The toast for the one who got the drops: "You got 2 Blue!" ("" for nothing).
static func drop_text(items: Array) -> String:
	var parts: Array[String] = []
	for e: Array in items:
		parts.append("%d %s" % [int(e[1]), BlockIds.display_name(int(e[0]))])
	return "" if parts.is_empty() else Lang.t("You got %s!") % " and ".join(parts)


static func _mix(seed: int, x: int, z: int) -> int:
	var h := x * 73856093 ^ z * 19349663 ^ seed * 83492791 ^ 0x5bd1e995
	h = (h ^ (h >> 13)) * 1274126177
	return (h ^ (h >> 16)) & 0x7fffffffffffffff

# --- M3 Task 11: where wild foxes and parrots live ------------------------------------------------------

const WILD_PET_CHANCE := 0.35     # an area's herd by the woods is a fox, by the water a parrot, this often
const WOODS_LOOK := 3             # a tree this close to the herd's centre: by the woods
const WATER_LOOK := 5             # sea level or a river this close: by the water
const _AROUND: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]


## The species of area `cell`'s herd at `center`, given what the weights picked: now and then a fox by the
## woods or a parrot by the water (from the seed alone, a hash of its own, so the other herds and their
## spots stay as they were).
static func wild_pet_at(shape: MeadowsShape, cell: Vector2i, center: Vector2i, picked: StringName) -> StringName:
	if SPECIES[picked].habitat != &"land":
		return picked
	var roll := float(_mix(shape.seed ^ 0x2f6b, cell.x, cell.y) % 10000) / 10000.0
	if roll >= WILD_PET_CHANCE:
		return picked
	if _near(shape, center, WATER_LOOK, func(x: int, z: int) -> bool:
			return shape.height_at(x, z) <= MeadowsShape.SEA_LEVEL or shape.is_river(x, z)):
		return &"parrot"
	if _near(shape, center, WOODS_LOOK, func(x: int, z: int) -> bool: return shape.tree_at(x, z)):
		return &"fox"
	return picked


static func _near(shape: MeadowsShape, center: Vector2i, reach: int, test: Callable) -> bool:
	for r in range(1, reach + 1):
		for d in _AROUND:
			if test.call(center.x + d.x * r, center.y + d.y * r):
				return true
	return false

# --- Owner feedback #41: more animals (spec §14.19) -----------------------------------------------------

## No animal ever attacks anyone: the polar bear is gentle, big and fluffy (spec §14.19). A rule so a test pins it.
static func attacks(_species: StringName) -> bool:
	return false

## M1b's walking hop (height, and seconds between hops) for every kind without its own.
const WALK_HOP := 0.35
const HOP_EVERY := 0.42
## A shy animal (a deer) runs from anyone within its "shy" distance who walks towards it faster than this, and
## from anyone at all this close.
const SHY_SPEED := 0.8
const SHY_NEAR := 4.0
## A hedgehog stays curled up this long after a scare (never running).
const CURL_TIME := 4.0
## A slider (penguin, seal) on ice (a grip under SLIDE_GRIP) belly-slides this much faster.
const SLIDE_GRIP := 0.5
const SLIDE_FACTOR := 2.2
## A turtle lays an egg on sand at most once every EGG_EVERY seconds, with this chance at each look (the host's
## AnimalDirector looks once a second); a child within HATCH_NEAR blocks makes it hatch into a baby turtle.
const EGG_EVERY := 150.0
const EGG_CHANCE := 0.1
const HATCH_NEAR := 2.0
const TRUNKS: Array[int] = [BlockIds.LOG, BlockIds.PINE_LOG, BlockIds.PALM_LOG]


## How many blocks it hops up (a goat 2, everyone else 1).
static func climb_height(species: StringName) -> int:
	return int(SPECIES.get(species, NO_SPECIES).get("climb", 1))


static func walk_hop(species: StringName) -> float:
	return float(SPECIES.get(species, NO_SPECIES).get("walk_hop", WALK_HOP))


static func hop_every(species: StringName) -> float:
	return float(SPECIES.get(species, NO_SPECIES).get("hop_every", HOP_EVERY))


static func swims(species: StringName) -> bool:
	return bool(SPECIES.get(species, NO_SPECIES).get("swims", false))


static func curls_up(species: StringName) -> bool:
	return bool(SPECIES.get(species, NO_SPECIES).get("curls", false))


static func climbs_trees(species: StringName) -> bool:
	return bool(SPECIES.get(species, NO_SPECIES).get("trees", false))


static func is_trunk(id: int) -> bool:
	return TRUNKS.has(id)


static func nocturnal(species: StringName) -> bool:
	return bool(SPECIES.get(species, NO_SPECIES).get("nocturnal", false))


## Whether its mind feels "night" (time to sleep): an owl's night is the day.
static func feels_night(species: StringName, night: bool) -> bool:
	return night != nocturnal(species)


## M5 Task 3: the default of a lookup made every physics tick (a `{}` there is a new Dictionary each call).
const NO_SPECIES := {}


static func slides_on(species: StringName, grip: float) -> bool:
	return grip < SLIDE_GRIP and bool(SPECIES.get(species, NO_SPECIES).get("slides", false))   # every tick: no new {}


## × its speed on this grip (FrostRules.grip_at): a slider belly-slides on ice.
static func slide_factor(species: StringName, grip: float) -> float:
	return SLIDE_FACTOR if slides_on(species, grip) else 1.0


## The way to run from `player` (at `player_velocity`), or ZERO: a shy animal runs from anyone walking up within
## its "shy" distance (or standing very close); every other animal only from a rush (flee_direction, M1b).
static func flee_from(species: StringName, animal: Vector3, player: Vector3, player_velocity: Vector3) -> Vector3:
	var shy := float(SPECIES.get(species, NO_SPECIES).get("shy", 0.0))
	if shy <= 0.0:
		return flee_direction(animal, player, player_velocity)
	var away := Vector3(animal.x - player.x, 0.0, animal.z - player.z)
	var dist := away.length()
	if dist > shy or dist < 0.001:
		return Vector3.ZERO
	var toward := Vector3(player_velocity.x, 0.0, player_velocity.z).dot(away / dist)
	if dist > SHY_NEAR and toward < SHY_SPEED:
		return Vector3.ZERO
	return away / dist


## Does a turtle standing on `under` lay an egg now? (no egg of its own yet, EGG_EVERY since the last, a roll.)
static func lays_egg(species: StringName, under: int, has_egg: bool, since_last: float, roll: float) -> bool:
	return bool(SPECIES.get(species, NO_SPECIES).get("lays", false)) and under == BlockIds.SAND and not has_egg \
		and since_last >= EGG_EVERY and roll < EGG_CHANCE


## The index of the player within HATCH_NEAR of the egg (who found it), or -1.
static func hatch_by(egg: Vector3, players: Array[Vector3]) -> int:
	if not egg.is_finite():
		return -1
	for i in players.size():
		if Vector2(players[i].x - egg.x, players[i].z - egg.z).length() <= HATCH_NEAR and absf(players[i].y - egg.y) < 3.0:
			return i
	return -1
