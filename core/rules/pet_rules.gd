class_name PetRules
extends RefCounted
## Pets with perks (M3 Task 11, spec §14.7, §5.9), as pure rules: the kinds of pet, how each becomes a
## pet, their perks and favourite treats; the happiness heart (it rises with pats and treats and falls
## slowly while the world is played; never needed, never punishing: a pet with a small heart still
## follows, obeys and helps, it only plays a little less); names (a list for everyone, a typed name
## through the username filter for 13+ only); collars (8 colours); Pip the robot, who lives in the
## profile and follows the child between worlds. Perk ranges and timing are in PetPerks.

const DOG := &"dog"
const CAT := &"cat"
const FOX := &"fox"
const PARROT := &"parrot"
const PIP := &"pip"
const DRAGON := &"dragon"         # owner 39: hatched from a dragon egg, or the Sky Dragon's baby dragon

## How a kind becomes a pet.
const BY_PETS := &"pets"          # three quick pets (M1b: AnimalRules.tame_tap)
const BY_TREATS := &"treats"      # TREATS_TO_TAME treats from the same child
const GIVEN := &"given"           # a gift, never wild (Pip, from the tutorial)
const BY_WAND := &"wand"          # M3 Task 20b: a calm monster befriended with the Magic Wand (BefriendRules)

## Perks (what they do: PetPerks).
const GLOW := &"glow"             # a soft light in caves and at night (one shared light: PetGlow)
const COINS := &"coins"           # pulls coins within PetPerks.COIN_PULL to its owner
const BARK := &"bark"             # barks when a monster comes within PetPerks.BARK_RANGE
const SNIFF := &"sniff"           # leads the way to buried treasure (TreasureSniff)
const ECHO := &"echo"             # repeats its own child's lines (PetEcho; this device only)
const POINT := &"point"           # points its beak at the nearest secret nobody found
const GLIDE := &"glide"           # owner 39: flies beside its child when they are up in the air (glides)
const RIDE := &"ride"             # owner #41: with a SADDLE it is ridden (AnimalRideRules)
const CHEST := &"chest"           # owner #41: carries a chest of 9 slots (DonkeyChest)
const PERKS: Array[StringName] = [GLOW, COINS, BARK, SNIFF, ECHO, POINT, GLIDE, RIDE, CHEST]

## Every kind of pet. Its body is the AnimalRules species of the same name (size, speed, voice), its look
## BlockyAnimal's boxes (and COLLAR), its mind AnimalSpecies.TRAITS. A new kind (owner #39's baby dragon)
## is one row here plus those three. Keys: tame (BY_*), perks, favourite (treat id); sniff_every (s between
## treasure trips), sniff_pace (× its speed on a trip) and digs (a dirt puff over the treasure) for SNIFF;
## cap (false: never counts toward AnimalRules.MAX_PETS).
const KINDS := {
	DOG: {"tame": BY_PETS, "perks": [COINS, BARK, SNIFF], "favourite": ItemIds.TREAT_BISCUIT,
		"sniff_every": TreasureSniff.EVERY, "sniff_pace": 1.0, "digs": false},
	CAT: {"tame": BY_PETS, "perks": [GLOW], "favourite": ItemIds.TREAT_FISH},
	FOX: {"tame": BY_TREATS, "perks": [SNIFF], "favourite": ItemIds.TREAT_BERRIES,
		"sniff_every": 10.0, "sniff_pace": 1.4, "digs": true},
	PARROT: {"tame": BY_TREATS, "perks": [ECHO, POINT], "favourite": ItemIds.TREAT_SEEDS},
	PIP: {"tame": GIVEN, "perks": [GLOW], "favourite": ItemIds.TREAT_BOLT, "cap": false},
	# owner 39: a gift (an egg that hatches, the Sky Dragon's baby dragon), never wild; never fights anyone
	DRAGON: {"tame": GIVEN, "perks": [GLIDE], "favourite": ItemIds.TREAT_FISH, "cap": false},
	# Owner #41 (spec §14.19): the horse's apple is the berries, the camel's grain the seed cracker; the fennec and the
	# arctic fox are foxes of their own universes (the same nose as Green Meadows' fox).
	&"horse": {"tame": BY_TREATS, "perks": [RIDE], "favourite": ItemIds.TREAT_BERRIES},
	&"camel": {"tame": BY_TREATS, "perks": [RIDE], "favourite": ItemIds.TREAT_SEEDS},
	&"donkey": {"tame": BY_TREATS, "perks": [CHEST], "favourite": ItemIds.TREAT_BERRIES},
	&"fennec": {"tame": BY_TREATS, "perks": [SNIFF], "favourite": ItemIds.TREAT_BERRIES,
		"sniff_every": 10.0, "sniff_pace": 1.4, "digs": true},
	&"arctic_fox": {"tame": BY_TREATS, "perks": [SNIFF], "favourite": ItemIds.TREAT_FISH,
		"sniff_every": 10.0, "sniff_pace": 1.4, "digs": true},
	# M3 Task 20b: a befriended monster (BefriendRules.SPECIES; it counts toward the cap) and a boss's mini-buddy
	# (MiniRules.SPECIES; a gift like Pip). Creatures of the night and of the bosses' glowing eyes: they glow softly in
	# the dark (the one shared PetGlow); they never fight anyone.
	&"monster_friend": {"tame": BY_WAND, "perks": [GLOW], "favourite": ItemIds.TREAT_BERRIES},
	&"mini_boss": {"tame": GIVEN, "perks": [GLOW], "favourite": ItemIds.TREAT_BOLT, "cap": false},
}

const TREATS_TO_TAME := 2
const TREAT_PRICE := 2            # Tilly's price per treat (Survivor, × 2^(u-1)); free in Sandbox


static func is_pet_kind(species: StringName) -> bool:
	return KINDS.has(species)


static func perks(species: StringName) -> Array:
	return KINDS[species].perks if KINDS.has(species) else []


static func has_perk(species: StringName, perk: StringName) -> bool:
	return perks(species).has(perk)


static func tames_by_petting(species: StringName) -> bool:
	return KINDS.has(species) and KINDS[species].tame == BY_PETS


static func tames_by_treats(species: StringName) -> bool:
	return KINDS.has(species) and KINDS[species].tame == BY_TREATS


## Pip is a gift: he never takes one of a child's AnimalRules.MAX_PETS places.
static func counts_toward_cap(species: StringName) -> bool:
	return bool(KINDS.get(species, {}).get("cap", true))


static func favourite(species: StringName) -> int:
	return int(KINDS.get(species, {}).get("favourite", -1))


## Seconds between treasure trips (INF: this kind doesn't sniff).
static func sniff_every(species: StringName) -> float:
	return float(KINDS[species].sniff_every) if has_perk(species, SNIFF) else INF


static func sniff_pace(species: StringName) -> float:
	return float(KINDS[species].get("sniff_pace", 1.0)) if has_perk(species, SNIFF) else 1.0


static func digs(species: StringName) -> bool:
	return has_perk(species, SNIFF) and bool(KINDS[species].get("digs", false))


## A treat from `peer` for a wild animal that is tamed with treats: `fed` (peer -> treats so far, kept by
## the animal) counts it; true when this one tames it.
static func treat_tames(fed: Dictionary, peer: int) -> bool:
	fed[peer] = int(fed.get(peer, 0)) + 1
	return int(fed[peer]) >= TREATS_TO_TAME


static func is_treat(id: int) -> bool:
	return ItemIds.TREATS.has(id)

# --- The happiness heart ---

const HAPPY_START := 0.7
const HAPPY_FLOOR := 0.25         # never lower: a smaller heart, never an empty one
const PAT_UP := 0.05
const PAT_GAP := 0.6              # seconds between pats that count (tapping fast is no faster)
const TREAT_UP := 0.15
const FAVOURITE_UP := 0.3
const FALL_PER_MINUTE := 0.01     # only while its world is played; never while the game is closed
const STEPS := 20                 # synced in steps of 1/20 (a change every few minutes, not every tick)


static func after_pat(h: float) -> float:
	return minf(h + PAT_UP, 1.0)


static func after_treat(h: float, species: StringName, item: int) -> float:
	return minf(h + (FAVOURITE_UP if item == favourite(species) else TREAT_UP), 1.0)


## After `seconds` of play: a little lower, never below HAPPY_FLOOR.
static func after_time(h: float, seconds: float) -> float:
	if seconds <= 0.0:
		return h
	return maxf(h - FALL_PER_MINUTE * seconds / 60.0, HAPPY_FLOOR)


## How big the heart is drawn (of its full size).
static func heart_scale(h: float) -> float:
	return lerpf(0.55, 1.0, clampf(h, 0.0, 1.0))


## How playful it is: a happier pet wags faster and jumps with its child more often.
static func play_factor(h: float) -> float:
	return lerpf(0.6, 1.0, clampf(h, 0.0, 1.0))


## Never needed, never punishing (spec §5.9): at any happiness a pet follows its child, does what they
## ask and keeps its perk. These say so, so a test pins them.
static func follows(_h: float) -> bool:
	return true


static func obeys(_h: float) -> bool:
	return true


static func perks_work(_h: float) -> bool:
	return true


## The value synced and saved: steps of 1/STEPS, never below the floor.
static func synced(h: float) -> float:
	return maxf(roundf(clampf(h, 0.0, 1.0) * STEPS) / STEPS, HAPPY_FLOOR)


static func clean_happiness(v: Variant) -> float:
	if not typeof(v) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(v)):
		return HAPPY_START
	return synced(float(v))

# --- Names ---

const MAX_NAME := UsernameRules.MAX_LEN
## Names any child can pick (every one passes the username filter).
const FUN_NAMES: Array[String] = ["Biscuit", "Luna", "Max", "Bella", "Coco", "Milo", "Daisy", "Rocky",
	"Pepper", "Sunny", "Ziggy", "Nugget", "Pickle", "Waffles", "Mochi", "Peanut", "Bubbles", "Muffin",
	"Pumpkin", "Noodle", "Maple", "Toffee", "Honey", "Button", "Twinkle", "Jelly", "Clover", "Snowy",
	"Rusty", "Kiwi", "Taco", "Ginger"]   # never a bot friend's name (BotRules.NAMES)
const PIP_NAME := "Pip"
const _NAME_MESSAGES := {"list_only": "Pick a name from the list!"}


## A new pet's name: Pip is Pip; the others get a fun name from their id (the same animal, the same name).
static func first_name(species: StringName, id: String) -> String:
	if species == PIP:
		return PIP_NAME
	return FUN_NAMES[absi(hash(id)) % FUN_NAMES.size()]


static func clean_name(text: String) -> String:
	return UsernameRules.normalize(text)


## Why a player of `band` can't give a pet this name ("" = they can): names on the list always work;
## under-13 players (or players who never said) pick from the list only; 13+ may type one, which must
## pass the username filter (UsernameRules codes).
static func name_refusal(text: String, band: StringName) -> String:
	var n := clean_name(text)
	if FUN_NAMES.has(n) or n == PIP_NAME:
		return ""
	if ChatRules.effective_band(band) != AgeBand.TEEN_PLUS:
		return "list_only"
	return UsernameRules.validate(n)


static func name_message(code: String) -> String:
	return _NAME_MESSAGES.get(code, UsernameRules.message(code))


## A name from a save: kept when it passes the filter, else a fun name (a hand-edited save).
static func saved_name(text: String, species: StringName, id: String) -> String:
	var n := clean_name(text)
	if n != "" and name_refusal(n, AgeBand.TEEN_PLUS) == "":
		return n
	return first_name(species, id)

# --- Collars ---

const COLLARS: Array[Color] = AnimalRules.COLLAR_COLORS
const OWNER_COLOUR := -1          # not chosen yet: the owner's colour (M1b)


static func valid_collar(i: int) -> bool:
	return i >= 0 and i < COLLARS.size()


static func collar_color(i: int, owner_peer: int) -> Color:
	return COLLARS[i] if valid_collar(i) else AnimalRules.collar_color(owner_peer)


static func clean_collar(v: Variant) -> int:
	if not typeof(v) in [TYPE_INT, TYPE_FLOAT] or not is_finite(float(v)):
		return OWNER_COLOUR
	var i := int(v)
	return i if valid_collar(i) else OWNER_COLOUR

# --- Pip the robot ---
# Ruling (M3 Task 11): Pip lives in the profile (ProfileData.pip), not in a world, so he follows the child
# into every world they play (Sandbox, Survivor, every universe, a friend's LAN world). His name, collar and
# heart are kept there; worlds never save him.

## Gives the child Pip (M3 Task 15's tutorial reward; /summon pip in Sandbox): true the first time.
static func give_pip(profile: ProfileData) -> bool:
	if not profile.pip.is_empty():
		return false
	profile.pip = pip_record(PIP_NAME, OWNER_COLOUR, HAPPY_START)
	return true


static func pip_record(pet_name: String, collar: int, happiness: float) -> Dictionary:
	return {"name": saved_name(pet_name, PIP, "pip"), "collar": clean_collar(collar), "happiness": clean_happiness(happiness)}


## The profile's Pip from a save: {} (no Pip) or a clean record.
static func clean_pip(v: Variant) -> Dictionary:
	if not v is Dictionary or (v as Dictionary).is_empty():
		return {}
	var d: Dictionary = v
	return pip_record(str(d.get("name", "")), clean_collar(d.get("collar")), clean_happiness(d.get("happiness")))

# --- Owner feedback #39: the pet dragon -------------------------------------------------------------------------
# A little dragon that follows its child on the ground like any pet and, when the child is up in the air (flying,
# gliding, a big jump), flies beside them; it lands when they land. It never fights: no perk hurts anyone.

const BABY_DRAGON_NAME := "Ember"
const GLIDE_SPEED := 14.0         # m/s at most (the player's Fly is 11; a glider falls a little faster)
const GLIDE_TAKE_OFF := 1.5       # the child this high above it, in the air: it takes off
const GLIDE_SIDE := 1.6           # beside the child, to their right ...
const GLIDE_UP := 0.8             # ... a little higher ...
const GLIDE_BACK := 0.4           # ... and a little behind
const GLIDE_EASE := 3.0           # its speed towards the spot: this × the distance, up to GLIDE_SPEED


## Does the dragon fly now? Flying already: while its child is in the air; on the ground: when its child is up in
## the air more than GLIDE_TAKE_OFF above it.
static func glides(on_floor: bool, owner_on_floor: bool, owner_above: float) -> bool:
	if owner_on_floor:
		return false
	return not on_floor or owner_above > GLIDE_TAKE_OFF


## Where it flies: beside its child (to their right, a little higher, a little behind), turning with them.
static func glide_spot(owner_pos: Vector3, owner_yaw: float) -> Vector3:
	var right := Vector3(cos(owner_yaw), 0.0, -sin(owner_yaw))
	var back := Vector3(sin(owner_yaw), 0.0, cos(owner_yaw))
	return owner_pos + right * GLIDE_SIDE + back * GLIDE_BACK + Vector3(0, GLIDE_UP, 0)


## Its velocity towards `spot`: faster the further it is, never above GLIDE_SPEED.
static func glide_velocity(from: Vector3, spot: Vector3) -> Vector3:
	var to := spot - from
	return to.normalized() * minf(to.length() * GLIDE_EASE, GLIDE_SPEED) if to.length() > 0.001 else Vector3.ZERO


static func baby_dragon_record() -> Dictionary:
	return {"name": saved_name(BABY_DRAGON_NAME, DRAGON, "babydragon"), "collar": OWNER_COLOUR, "happiness": HAPPY_START}


## The Sky Dragon's baby dragon for this profile (true the first time; a named one is never renamed).
static func give_baby_dragon(profile: ProfileData) -> bool:
	if not profile.baby_dragon.is_empty():
		return false
	profile.baby_dragon = baby_dragon_record()
	return true
