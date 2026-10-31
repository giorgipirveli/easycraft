class_name MyShortFacts
extends RefCounted
## MAKE MY SHORT (spec §5.12b "As built (My Shorts)"): what "3 facts about…" can be about, with the game's own facts and
## pictures. Three kinds of subject:
## - PLANET: the Sun, the planets, Pluto and the moons of the Star Map (its facts, its colours; LEARN IT: the Star Map);
## - WONDER: the Wonders Passport's 21 wonders (WonderFacts' facts, their stamps; LEARN IT: the Star Map, where the
##   Wonders of the World are world 41);
## - ANIMAL: the game's real animals (the Animal Book's fact first, then two more kept here for the Shorts: short, true
##   and checked, their sources in docs/devlog/parts/my-shorts.md; their portraits). The game's fantasy friends (Pip,
##   the dragon, the candy and Moon animals) stay out: a child's Short about facts teaches true things.
## Only facts that fit a caption are offered (MyShortRules.MAX_FACT letters), and only things with at least three.
## Pure: the maker reads it, the maker's screen lists it.

const PLANET := "planet"
const WONDER := "wonder"
const ANIMAL := "animal"
const KINDS: Array[String] = [PLANET, WONDER, ANIMAL]
const KIND_WORDS := {PLANET: "PLANETS", WONDER: "WONDERS", ANIMAL: "ANIMALS"}

## Two more true facts for each real animal of the game (the Animal Book has one). Plain words a child reads alone.
const ANIMAL_FACTS := {
	&"dog": ["Dogs can hear high sounds that people can't hear.", "A dog wags its tail to show how it feels."],
	&"cat": ["A cat's whiskers help it feel if it fits through a gap.", "Cats can't taste sweet things."],
	&"pig": ["Pigs roll in mud to cool down: they can hardly sweat.", "A pig digs in the ground with its strong snout."],
	&"cow": ["A cow's stomach has four parts.", "A cow chews its food a second time: it chews the cud."],
	&"sheep": ["Sheep can see almost all the way round without turning their heads.",
		"Most sheep's wool keeps growing until it is cut."],
	&"chicken": ["A chicken has no teeth: it swallows tiny stones to grind its food.",
		"Chickens bathe in dust to keep their feathers clean."],
	&"rabbit": ["A rabbit's teeth never stop growing.", "A rabbit can turn each long ear on its own to listen."],
	&"fish": ["Fish breathe with gills that take oxygen from the water.",
		"Many fish swim together in big groups called schools."],
	&"fox": ["A fox can hear a mouse moving under the snow.", "A baby fox is called a cub or a kit."],
	&"parrot": ["A parrot has two toes pointing forward and two pointing back.",
		"Some parrots live for more than 50 years."],
	&"horse": ["Horses have the biggest eyes of any land mammal.", "A baby horse can stand up soon after it is born."],
	&"donkey": ["A donkey's loud call is called a bray.", "Donkeys remember places and friends for many years."],
	&"goat": ["Goats have pupils shaped like rectangles.", "A baby goat is called a kid."],
	&"deer": ["Most male deer grow new antlers every year.", "A baby deer is called a fawn."],
	&"duck": ["Ducks have webbed feet that work like paddles.",
		"Ducklings follow the first moving thing they see: their mum."],
	&"frog": ["A frog starts life as a tadpole that lives in water.",
		"Many frogs catch insects with a long, sticky tongue."],
	&"turtle": ["A turtle's shell is part of its skeleton.", "Sea turtles can rest under water for hours."],
	&"squirrel": ["A squirrel's bushy tail helps it balance when it jumps.", "A squirrel's front teeth never stop growing."],
	&"owl": ["An owl can turn its head much further round than we can.",
		"Owls fly almost without a sound, thanks to soft feathers."],
	&"hedgehog": ["A hedgehog has about 5,000 to 7,000 spines.", "Many hedgehogs sleep through the winter."],
	&"camel": ["Camels have two rows of long eyelashes that keep out the sand.",
		"A thirsty camel can drink a lot of water very quickly."],
	&"lizard": ["Some lizards can drop their tail to escape and grow a new one.",
		"Many lizards flick their tongues to smell the air."],
	&"fennec": ["Fennec foxes live in the Sahara desert.", "Their big ears help them lose heat and stay cool."],
	&"penguin": ["Almost all penguins live in the south half of the world.",
		"Emperor penguins huddle together to keep warm."],
	&"polar_bear": ["Polar bears are great swimmers.", "Polar bears live in the Arctic, near the North Pole."],
	&"arctic_fox": ["An arctic fox has fur under its feet to keep them warm.", "Arctic foxes live in the cold far north."],
	&"seal": ["Seals keep warm with a thick layer of fat called blubber.", "A baby seal is called a pup."],
}
## Animals' names as a title says them ("3 facts about polar bears").
const ANIMAL_PLURALS := {&"sheep": "sheep", &"fish": "fish", &"deer": "deer", &"fox": "foxes", &"fennec": "fennec foxes",
	&"arctic_fox": "arctic foxes", &"polar_bear": "polar bears", &"donkey": "donkeys"}

static var _cache := {}


static func kind_words(kind: String) -> String:
	return str(KIND_WORDS.get(kind, ""))


## The ids a child can pick for `kind`, in the game's order (the Star Map's, the Passport's tours, the animal table's).
static func things(kind: String) -> Array[String]:
	var key := "things:" + kind
	if _cache.has(key):
		return _cache[key]
	var out: Array[String] = []
	match kind:
		PLANET:
			for b: Dictionary in StarMap.SOLAR:
				if str(b.kind) in ["star", "planet", "dwarf", "moon"] and _fitting(b.get("facts", [])).size() >= MyShortRules.FACT_COUNT:
					out.append(String(b.id))
		WONDER:
			for tour: StringName in WonderFacts.TOUR_IDS:
				for id: StringName in WonderFacts.tour_ids(tour):
					if _fitting(WonderFacts.of(id).get("facts", [])).size() >= MyShortRules.FACT_COUNT:
						out.append(String(id))
		ANIMAL:
			for sp: StringName in AnimalRules.SPECIES:
				if ANIMAL_FACTS.has(sp):
					out.append(String(sp))
	_cache[key] = out
	return out


static func has(kind: String, id: String) -> bool:
	return things(kind).has(id)


## The facts a child can pick about `id` (each fits a caption), in their own order; [] for an unknown thing.
static func facts(kind: String, id: String) -> Array[String]:
	if not has(kind, id):
		return [] as Array[String]
	match kind:
		PLANET:
			return _fitting(StarMap.body(StringName(id)).get("facts", []))
		WONDER:
			return _fitting(WonderFacts.of(StringName(id)).get("facts", []))
		ANIMAL:
			var list: Array = [AnimalBookRules.fact_of(StringName(id))]
			list.append_array(ANIMAL_FACTS[StringName(id)])
			return _fitting(list)
	return [] as Array[String]


## Its name as a child reads it on a card: "Mars", "The Moon", "Great Pyramid", "Polar Bear".
static func name_of(kind: String, id: String) -> String:
	match kind:
		PLANET:
			return str(StarMap.body(StringName(id)).get("name", ""))
		WONDER:
			var w := WonderFacts.of(StringName(id))
			return str(w.get("short", w.get("name", "")))
		ANIMAL:
			return AnimalBookRules.name_of(StringName(id))
	return ""


## The Short's title: "3 facts about Mars", "3 facts about the Moon", "3 facts about the Great Pyramid", "3 facts about
## polar bears".
static func title_for(kind: String, id: String) -> String:
	var name := name_of(kind, id)
	match kind:
		PLANET:
			name = "the " + name.trim_prefix("The ") if name.begins_with("The ") else name
		WONDER:
			name = name if WonderFacts.NO_THE.has(StringName(id)) else "the " + name
		ANIMAL:
			name = str(ANIMAL_PLURALS.get(StringName(id), name.to_lower() + "s"))
	var title := "3 facts about " + name
	return title if title.length() <= ShortRules.MAX_TITLE else name_of(kind, id).left(ShortRules.MAX_TITLE)


## What LEARN IT opens: the Star Map for the sky and for the wonders (world 41 on it); nothing for an animal.
static func link_of(kind: String, _id: String) -> Dictionary:
	return {ShortRules.LINK_STAR_MAP: true} if kind in [PLANET, WONDER] else {}


static func _fitting(list: Variant) -> Array[String]:
	var out: Array[String] = []
	if list is Array:
		for f: Variant in list:
			if f is String and (f as String).length() <= MyShortRules.MAX_FACT \
					and ShortRules.speech_seconds(f) <= ShortRules.SCENE_MAX - 2.0:
				out.append(f)
	return out
