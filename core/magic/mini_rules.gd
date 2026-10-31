class_name MiniRules
extends RefCounted
## Bosses become mini-buddies (M3 Task 20b, spec §14.21, research P5 "the Golem that becomes a tiny Pebble Golem
## friend"): after a boss is beaten, a tiny version of it hops out and follows every child who was there, as a
## pet of theirs (species SPECIES, the boss kind as its variant). Like Pip it lives in the profile
## (BuddyMagicData.minis, one per boss kind, never sold), comes into every world with its child, never takes a pet
## place and never fights. Pure. The Sky Dragon's own tiny friend is owner #39's baby dragon (PetRules.DRAGON).

const SPECIES := &"mini_boss"
const ID_PREFIX := "mini_"

## Boss kind -> its mini-buddy: a name (it passes the pet-name filter) and what it is called.
const MINIS := {
	BossRules.GOLEM: {"name": "Pebble", "title": "Pebble Golem"},
	BossRules.SERPENT: {"name": "Sandy", "title": "Mini Sand Serpent"},
	BossRules.FROST_GIANT: {"name": "Flurry", "title": "Little Frost Giant"},
	BossRules.CAKE: {"name": "Cupcake", "title": "Cupcake Monster"},
	# Owner #86 (spec §21f): an alien friend is a mini-buddy too (the buddy system: AlienRules.befriend puts its record
	# here; one at a time comes along, AlienRules.comes_along). Its look: AlienModels.mini_boxes.
	&"alien_blip": {"name": "Blip", "title": "Blip the alien"},
	&"alien_zib": {"name": "Zib", "title": "Zib the alien"},
	&"alien_nuri": {"name": "Nuri", "title": "Nuri the alien"},
	&"alien_tinka": {"name": "Tinka", "title": "Tinka the alien"},
	&"alien_oolo": {"name": "Oolo", "title": "Oolo the alien"},
	&"alien_pim": {"name": "Pim", "title": "Pim the alien"},
	&"alien_nubi": {"name": "Nubi", "title": "Nubi the alien"},   # cosmos: Venus's explorer
	&"alien_frosi": {"name": "Frosi", "title": "Frosi the alien"},   # cosmos: Saturn's rings' explorer
	&"alien_wisp": {"name": "Wisp", "title": "Wisp the alien"},   # cosmos: Pluto's explorer
	&"alien_puffle": {"name": "Puffle", "title": "Puffle the alien"},   # cosmos: Triton's explorer
	&"alien_lumo": {"name": "Lumo", "title": "Lumo the alien"},   # cosmos: Ganymede's explorer
	&"alien_bopsy": {"name": "Bopsy", "title": "Bopsy the alien"},
	&"alien_iri": {"name": "Iri", "title": "Iri the alien"},
}


static func gives_mini(boss_kind: StringName) -> bool:
	return MINIS.has(boss_kind)


## Whether a child whose profile holds `minis` (BuddyMagicData.minis) gets this boss's mini now: once per kind.
static func owed(minis: Dictionary, boss_kind: StringName) -> bool:
	return gives_mini(boss_kind) and not minis.has(String(boss_kind))


## A new mini's record (name, the owner's collar colour, a happy heart), like Pip's.
static func record(boss_kind: StringName) -> Dictionary:
	var n: String = MINIS[boss_kind].name if gives_mini(boss_kind) else "Pebble"
	return {"name": PetRules.saved_name(n, SPECIES, ID_PREFIX + String(boss_kind)), "collar": PetRules.OWNER_COLOUR,
		"happiness": PetRules.HAPPY_START}


static func title(boss_kind: StringName) -> String:
	return str(MINIS[boss_kind].title) if gives_mini(boss_kind) else ""


## What the child hears when it hops out.
static func words(boss_kind: StringName) -> String:
	return Lang.t("A tiny %s hopped out! It follows you now, into every world.") % Lang.t(title(boss_kind))


## The mini's animal id in a world: "mini_<kind>_<peer>" (PetDirector.is_profile_pet: worlds never save it).
static func animal_id(boss_kind: StringName, peer: int) -> String:
	return "%s%s_%d" % [ID_PREFIX, boss_kind, peer]


## The boss kind of a mini's animal id, or &"" for any other animal.
static func kind_of_id(id: String) -> StringName:
	if not id.begins_with(ID_PREFIX):
		return &""
	var rest := id.substr(ID_PREFIX.length())
	var cut := rest.rfind("_")
	if cut <= 0 or not rest.substr(cut + 1).is_valid_int():
		return &""
	var kind := StringName(rest.substr(0, cut))
	return kind if gives_mini(kind) else &""


## The profile's trick key of a mini of `boss_kind` (BuddyMagicData.tricks).
static func trick_key(boss_kind: StringName) -> String:
	return ID_PREFIX + String(boss_kind)
