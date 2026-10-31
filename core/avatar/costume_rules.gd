class_name CostumeRules
extends RefCounted
## Owner feedback #36 (spec §14.6b): the Storybook costume pack. Public-domain storybook heroes drawn our own way
## from the books (never a film's look) and our own genre costumes. A costume is a whole look made of catalogue
## parts: the CLOTHES cuts, hair, hats, faces, colours, outfits, capes, wings and trails (AvatarCatalog), in both
## graphics styles (AvatarParts). It is the avatar item "costume.<id>" (AvatarCatalog.ITEMS), earned by playing in
## one fixed way ("earn": a boss, a story, a level, a title, a badge, a Secret Book find, a code); earning it gives
## everything it wears (AvatarUnlocks.is_owned asks `gives`). Never random, never for gold or money, never a boy's
## or a girl's: wearing one keeps the child's skin tone, first choice and dance wheel.
##
## Most ways are read from the profile (`met`), so `sync` can give a costume whenever the play behind it is done:
## in a world (Session's owner-36 section, on Progress.changed) and when the editor opens (a profile from before
## the pack gets what it already earned). Bosses give theirs with their win (AvatarCatalog.BOSS_EARNS), the code
## through CodeRules (a cosmetic reward of "costume.cube_hero").

## Costume id -> its whole look (AvatarLook fields; never the skin tone, the first choice or the dance wheel).
const COSTUMES := {
	# Storybook heroes, drawn from the books
	&"alice": {"hair": "long", "hair_color": "blond", "face": "sweet", "hat": "alice_band", "clothes": "pinafore",
		"shirt": "yellow", "pants": "sky"},
	&"dorothy": {"hair": "pigtails", "hair_color": "brown", "face": "sweet", "hat": "sunbonnet", "clothes": "gingham",
		"shirt": "sky", "pants": "white"},
	&"pinocchio": {"hair": "short", "hair_color": "brown", "face": "long_nose", "hat": "puppet_cap",
		"clothes": "paper_suit", "shirt": "white", "pants": "white"},
	&"robin_hood": {"hair": "short", "hair_color": "brown", "face": "smile", "hat": "feather_cap", "clothes": "archer",
		"shirt": "green", "pants": "brown"},
	&"hatter": {"hair": "curly", "hair_color": "brown", "face": "grin", "hat": "hatter", "clothes": "tailcoat",
		"shirt": "purple", "pants": "grey"},
	&"tin_woodman": {"hair": "short", "hair_color": "brown", "face": "smile", "outfit": "tin_woodman"},
	&"sherlock": {"hair": "short", "hair_color": "black", "face": "smile", "hat": "deerstalker", "clothes": "inverness",
		"shirt": "grey", "pants": "black"},
	&"king_arthur": {"hair": "short", "hair_color": "blond", "face": "smile", "hat": "crown", "clothes": "tabard",
		"shirt": "blue", "pants": "grey", "cape": "royal"},
	&"merlin": {"hair": "long", "hair_color": "white", "face": "beard", "hat": "merlin_hat", "clothes": "robe",
		"shirt": "green", "pants": "green"},
	&"aladdin": {"hair": "short", "hair_color": "black", "face": "smile", "hat": "turban", "clothes": "kaftan",
		"shirt": "teal", "pants": "red"},
	&"hercules": {"hair": "curly", "hair_color": "brown", "face": "smile", "hat": "lion_hood", "clothes": "chiton",
		"shirt": "white", "pants": "brown"},
	&"nemo": {"hair": "short", "hair_color": "black", "face": "smile", "hat": "nautilus_cap", "clothes": "captain_coat",
		"shirt": "jeans", "pants": "black"},
	# Our own genre costumes
	&"fairy": {"hair": "bangs", "hair_color": "platinum", "face": "lovely", "hat": "flower_crown",
		"clothes": "petal_dress", "shirt": "lilac", "pants": "white", "wings": "fairy", "trail": "sparkles"},
	&"wizard": {"hair": "bob", "hair_color": "brown", "face": "smile", "hat": "wizard_hat", "clothes": "robe",
		"shirt": "purple", "pants": "purple", "trail": "sparkles"},
	&"cube_hero": {"hair": "spiky", "hair_color": "black", "face": "grin", "clothes": "hero_suit", "shirt": "teal",
		"pants": "teal", "cape": "cube"},
	&"pirate": {"hair": "long", "hair_color": "black", "face": "grin", "hat": "tricorn", "clothes": "captain_coat",
		"shirt": "brown", "pants": "black", "cape": "parrot"},
	&"knight": {"hair": "short", "hair_color": "brown", "face": "smile", "outfit": "knight", "cape": "royal"},
	&"ninja": {"hair": "short", "hair_color": "black", "face": "smile", "outfit": "ninja", "trail": "smoke"},
	&"astronaut": {"hair": "short", "hair_color": "brown", "face": "smile", "outfit": "astronaut", "trail": "rocket"},
	&"robot": {"hair": "short", "hair_color": "brown", "face": "smile", "outfit": "robot", "trail": "sparks"},
	&"dragon": {"hair": "short", "hair_color": "brown", "face": "smile", "outfit": "dragon", "wings": "dragon"},
}
## The COSTUME tab's order: girls' and boys' heroes mixed, the storybook first.
const ORDER: Array[StringName] = [&"alice", &"dorothy", &"pinocchio", &"robin_hood", &"hatter", &"tin_woodman",
	&"sherlock", &"king_arthur", &"merlin", &"aladdin", &"hercules", &"nemo", &"fairy", &"wizard", &"cube_hero",
	&"pirate", &"knight", &"ninja", &"astronaut", &"robot", &"dragon"]
## Where each costume comes from (for the legal check, docs/devlog/parts/owner-36-costumes.md): the work, the year
## it (or the drawings we follow) came out, the year its last maker died (0: no known maker), our own design or not.
const SOURCES := {
	&"alice": {"work": "Lewis Carroll, Alice's Adventures in Wonderland; John Tenniel's drawings", "year": 1865,
		"died": 1914, "own": false},
	&"hatter": {"work": "Lewis Carroll, Alice's Adventures in Wonderland; John Tenniel's drawings", "year": 1865,
		"died": 1914, "own": false},
	&"dorothy": {"work": "L. Frank Baum, The Wonderful Wizard of Oz; W. W. Denslow's drawings", "year": 1900,
		"died": 1919, "own": false},
	&"tin_woodman": {"work": "L. Frank Baum, The Wonderful Wizard of Oz; W. W. Denslow's drawings", "year": 1900,
		"died": 1919, "own": false},
	&"pinocchio": {"work": "Carlo Collodi, The Adventures of Pinocchio; Enrico Mazzanti's drawings", "year": 1883,
		"died": 1910, "own": false},
	&"robin_hood": {"work": "the Robin Hood ballads; Howard Pyle, The Merry Adventures of Robin Hood", "year": 1883,
		"died": 1911, "own": false},
	&"king_arthur": {"work": "the legends of King Arthur (Geoffrey of Monmouth, Thomas Malory); Howard Pyle's drawings",
		"year": 1903, "died": 1911, "own": false},
	&"merlin": {"work": "the legends of King Arthur (Geoffrey of Monmouth, Thomas Malory); Howard Pyle's drawings",
		"year": 1903, "died": 1911, "own": false},
	&"sherlock": {"work": "Arthur Conan Doyle's Sherlock Holmes stories; Sidney Paget's drawings", "year": 1891,
		"died": 1930, "own": false},
	&"aladdin": {"work": "Aladdin and the Wonderful Lamp, One Thousand and One Nights (Antoine Galland's edition)",
		"year": 1712, "died": 1715, "own": false},
	&"hercules": {"work": "Greek myth: Heracles and the Nemean lion (Hesiod's Theogony)", "year": -700, "died": 0,
		"own": false},
	&"nemo": {"work": "Jules Verne, Twenty Thousand Leagues Under the Seas; Alphonse de Neuville's drawings",
		"year": 1870, "died": 1905, "own": false},
	&"fairy": {"work": "our own design", "year": 2026, "died": 0, "own": true},
	&"wizard": {"work": "our own design", "year": 2026, "died": 0, "own": true},
	&"cube_hero": {"work": "our own design", "year": 2026, "died": 0, "own": true},
	&"pirate": {"work": "our own design (the parrot: Treasure Island, 1883)", "year": 2026, "died": 0, "own": true},
	&"knight": {"work": "our own design (M3 Task 9's knight)", "year": 2026, "died": 0, "own": true},
	&"ninja": {"work": "our own design (M3 Task 9's ninja)", "year": 2026, "died": 0, "own": true},
	&"astronaut": {"work": "our own design (M3 Task 9's astronaut)", "year": 2026, "died": 0, "own": true},
	&"robot": {"work": "our own design (M3 Task 9's robot)", "year": 2026, "died": 0, "own": true},
	&"dragon": {"work": "our own design", "year": 2026, "died": 0, "own": true},
}
## The way of a costume a secret code gives (AvatarCatalog.CODE).
const CODE_WAY := &"code"
## Ways read from the profile ("<kind>/<detail>"), and the Secret Book page (AvatarCatalog.EARN_SECRET_PAGE).
const DERIVED: Array[String] = ["level", "title", "quest", "badge", "count", "secret"]

static var _parts := {}     # costume id -> Array[String] of the item ids it wears
static var _special := {}   # costume id -> the ones of those that aren't free (what owning it is about)
static var _givers := {}    # item id -> Array[StringName] of the costumes that wear it
static var _earned_by := {} # earn event -> Array[String] of the items it gives


static func item_id(id: StringName) -> String:
	return AvatarCatalog.item_id(AvatarCatalog.COSTUME, id)


static func has(id: Variant) -> bool:
	return (id is StringName or id is String) and COSTUMES.has(StringName(id))


## Every catalogue item the costume wears ("hat.alice_band", "shirt.yellow"...), colours too.
static func parts(id: StringName) -> Array[String]:
	if not _parts.has(id):
		var out: Array[String] = []
		var recipe: Dictionary = COSTUMES.get(id, {})
		for field: String in recipe:
			out.append(AvatarCatalog.item_id(AvatarLook.FIELDS[field], StringName(recipe[field])))
		_parts[id] = out
	return _parts[id]


## The costume on the child: its whole look, keeping `keep`'s skin tone, first choice and dance wheel.
static func wear(id: StringName, keep: AvatarLook = null) -> AvatarLook:
	var look := AvatarLook.from_dict(COSTUMES.get(id, {}))
	if keep:
		look.skin = keep.skin
		look.base = keep.base
		look.emotes = keep.emotes.duplicate()
	return look


## Everything in it is the child's (earned whole, or piece by piece).
static func is_complete(id: StringName, owned: Array) -> bool:
	if not COSTUMES.has(id):
		return false
	if owned.has(item_id(id)):
		return true
	if not _special.has(id):   # the free parts (colours, hair...) are everyone's: checked once
		_special[id] = parts(id).filter(func(p: String) -> bool: return not AvatarCatalog.is_free(p))
	for p: String in _special[id]:
		if not (owned.has(p) or gives(p, owned)):
			return false
	return true


## Whether an earned costume in `owned` wears `item` (so the child owns it).
static func gives(item: String, owned: Array) -> bool:
	if _givers.is_empty():
		for c: StringName in COSTUMES:
			for p in parts(c):
				if not _givers.has(p):
					_givers[p] = []
				(_givers[p] as Array).append(c)
	for c: StringName in _givers.get(item, []):
		if owned.has(item_id(c)):
			return true
	return false


## How the costume is earned: its avatar item's earn event, or CODE_WAY.
static func way(id: StringName) -> StringName:
	var item: Dictionary = AvatarCatalog.ITEMS.get(item_id(id), {})
	if item.get("kind", &"") == AvatarCatalog.CODE:
		return CODE_WAY
	return StringName(item.get("earn", &""))


## A way the profile itself shows (a level, a title, a story, a badge, a count, a find, a Secret Book page).
static func is_derived(event: StringName) -> bool:
	return event == AvatarCatalog.EARN_SECRET_PAGE or DERIVED.has(String(event).get_slice("/", 0)) and String(event).contains("/")


## Whether the profile's play has done `event` (false for a boss's or a code's: those give theirs themselves).
static func met(profile: ProfileData, event: StringName) -> bool:
	if profile == null:
		return false
	if event == AvatarCatalog.EARN_SECRET_PAGE:
		return _page_done(profile, SecretRules.KINDS) or _page_done(profile, TreasurePlaces.KINDS)
	var s := String(event)
	var slash := s.find("/")
	if slash < 0:
		return false
	var arg := s.substr(slash + 1)
	var d := profile.progress
	match s.substr(0, slash):
		"level":
			return arg.is_valid_int() and d.level() >= arg.to_int()
		"title":
			return LevelRules.earned_titles(d.style_xp).has(StringName(arg))
		"quest":
			return QuestRules.is_done(d, StringName(arg))
		"badge":
			return d.achievements.has(arg)
		"count":
			return d.count(StringName(arg)) >= 1
		"secret":
			return int(profile.secret_book.get(arg, 0)) >= 1
	return false


## Gives the profile every item of a way its play has done and it doesn't have yet (costumes, and the Secret Book
## page's Fairy Wings); returns them (for a "New!" message). Fixed and idempotent: the same profile gets the same.
## The caller saves.
static func sync(profile: ProfileData) -> Array[String]:
	var got: Array[String] = []
	if profile == null:
		return got
	for event: StringName in _events():
		if is_derived(event) and _waiting(event, profile.cosmetics) and met(profile, event):
			got.append_array(AvatarUnlocks.earn(profile, event))
	return got


## The avatar event a boss's win earns (AvatarCatalog.BOSS_EARNS), or &"".
static func boss_event(kind: StringName) -> StringName:
	return AvatarCatalog.BOSS_EARNS.get(kind, &"")


## "Alice: Reach level 3 to get it!": the costume and how it is earned (the editor's line, a part's lock reason), in
## the game's language (M3 Task 21a).
static func line(id: StringName) -> String:
	var costume := item_id(id)
	return Lang.t("%s: %s") % [Lang.t(AvatarCatalog.display_name(costume)), Lang.t(AvatarUnlocks.lock_reason(costume))]


## The costumes' names among newly earned items ("Alice", "Dorothy"), in English (callers translate them).
static func names_in(items: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for id in items:
		if AvatarCatalog.slot_of(id) == AvatarCatalog.COSTUME:
			out.append(AvatarCatalog.display_name(id))
	return out


static func _page_done(profile: ProfileData, kinds: Array[StringName]) -> bool:
	for k in kinds:
		if int(profile.secret_book.get(String(k), 0)) < 1:
			return false
	return true


## Every earn event of the catalogue, once.
static func _events() -> Array:
	if _earned_by.is_empty():
		for id: String in AvatarCatalog.ITEMS:
			var e: Variant = AvatarCatalog.ITEMS[id].get("earn")
			if e == null:
				continue
			if not _earned_by.has(e):
				_earned_by[e] = []
			(_earned_by[e] as Array).append(id)
	return _earned_by.keys()


## Whether an item of `event` isn't owned yet (so checking it can give something). Earned items are never free, so
## this is a list lookup (it runs every frame something is counted in a world).
static func _waiting(event: StringName, owned: Array) -> bool:
	for id: String in _earned_by.get(event, []):
		if not (owned.has(id) or gives(id, owned)):
			return true
	return false
