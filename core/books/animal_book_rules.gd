class_name AnimalBookRules
extends RefCounted
## The Animal Book (M3 Task 21b; research C1): a page for every animal kind of the game — the species table
## (AnimalRules.SPECIES) is read, never copied, so a new animal gets its page by itself. A kind shows as a
## silhouette with "???" until the child has met it (been close to one), then its picture (drawn from its own
## box model, AnimalPortrait), its name and a fun fact; FED and FRIEND marks fill in as the child feeds it
## and makes it a pet. Every mark comes once, and only by playing (nothing to buy, no rare "limited" kinds).
## Kept in the profile (WonderData.animals).

## An animal this close to the child's player is met.
const MEET_DISTANCE := 8.0
## Names that are more than the species' own word.
const NAMES := {&"pip": "Pip the Robot", &"dragon": "Baby Dragon", &"fennec": "Fennec Fox"}
## One short, true, friendly fact per kind; a kind without one gets DEFAULT_FACT (a new animal added to the
## species table needs no line here to have its page).
const FACTS := {
	&"dog": "A dog's nose print is as special as your fingerprint!",
	&"cat": "Cats sleep for about 13 hours every day.",
	&"pig": "Pigs are very clever. They can learn their names!",
	&"cow": "Cows have best friends and like to stay close to them.",
	&"sheep": "Sheep can remember the faces of their friends for years.",
	&"chicken": "Chickens can tell more than 100 faces apart!",
	&"rabbit": "A happy rabbit jumps and twists in the air. It's called a binky!",
	&"fish": "Some fish can change their colours!",
	&"fox": "Foxes curl their bushy tails round them like a warm blanket.",
	&"parrot": "Parrots can learn to copy the words they hear.",
	&"pip": "Pip is a little robot. He beeps when he is happy!",
	&"dragon": "Baby dragons love to fly right next to their friends.",
	# owner #41's kinds
	&"horse": "Horses can sleep standing up!",
	&"donkey": "Donkeys have huge ears to hear friends far away.",
	&"goat": "Goats are super climbers. They love high places!",
	&"deer": "Baby deer have white spots to hide in the woods.",
	&"duck": "A duck's feathers stay dry, even under water!",
	&"frog": "Frogs drink water through their skin.",
	&"turtle": "Baby turtles hatch from eggs buried in the sand.",
	&"squirrel": "Squirrels hide nuts and dig them up later.",
	&"owl": "Owls stay awake at night and sleep in the day.",
	&"hedgehog": "A hedgehog rolls into a spiky ball to feel safe.",
	&"camel": "A camel's hump stores fat, so it can walk a long way.",
	&"lizard": "Lizards warm up by lying in the sun.",
	&"fennec": "Fennec foxes have the biggest ears of any fox!",
	&"penguin": "Penguins can't fly, but they swim really fast!",
	&"polar_bear": "Under its white fur, a polar bear's skin is black!",
	&"arctic_fox": "Arctic foxes turn white in winter to hide in the snow.",
	&"seal": "Seals can hold their breath for a very long time.",
	&"gummy_bunny": "Gummy bunnies bounce because they are made of jelly!",
	&"candy_bird": "Candy birds sing sweet songs in the candy cane woods.",
	&"moon_bunny": "Moon bunnies hop so high because the Moon pulls on them only gently!",   # owner #55
}
const DEFAULT_FACT := "A new friend to get to know!"


## Every kind, in the species table's order.
static func species() -> Array[StringName]:
	var out: Array[StringName] = []
	for sp: StringName in AnimalRules.SPECIES:
		out.append(sp)
	return out


## The kind's name in the game's language (M3 Task 21a: the English is the key).
static func name_of(sp: StringName) -> String:
	return Lang.t(str(NAMES.get(sp, String(sp).capitalize())))


static func fact_of(sp: StringName) -> String:
	return Lang.t(str(FACTS.get(sp, DEFAULT_FACT)))


## Whether this kind can become a pet (its page has a FRIEND mark).
static func can_befriend(sp: StringName) -> bool:
	return PetRules.is_pet_kind(sp) or bool((AnimalRules.SPECIES.get(sp, {}) as Dictionary).get("tameable", false))


static func flags(d: WonderData, sp: StringName) -> int:
	return int(d.animals.get(String(sp), 0))


static func knows(d: WonderData, sp: StringName) -> bool:
	return flags(d, sp) & WonderData.MET != 0


## Marks `sp` with `flag` (FED and FRIEND mark it met too); true when that is new.
static func record(d: WonderData, sp: StringName, flag: int) -> bool:
	if not AnimalRules.SPECIES.has(sp) or flag & WonderData.ALL_MARKS == 0:
		return false
	var marks := (flag & WonderData.ALL_MARKS) | WonderData.MET
	var before := flags(d, sp)
	if before | marks == before:
		return false
	if before == 0 and d.animals.size() >= WonderData.MAX_SPECIES:
		return false
	d.animals[String(sp)] = before | marks
	return true


## A counted event (Progress.counted) that fills the book: "pet_fed/<kind>" (FED) or "animal_tamed/<kind>"
## (FRIEND). Returns the kind when it marked something new, else &"".
static func from_event(d: WonderData, kind: StringName) -> StringName:
	var s := String(kind)
	var slash := s.find("/")
	if slash < 0:
		return &""
	var family := StringName(s.substr(0, slash))
	var sp := StringName(s.substr(slash + 1))
	var flag := WonderData.FED if family == LevelRules.FED else (WonderData.FRIEND if family == LevelRules.TAMED else 0)
	return sp if flag != 0 and record(d, sp, flag) else &""


## Earlier play the book didn't see (a profile from before it): the progress counts of pets tamed and fed,
## and the child's own Pip and baby dragon. True when something new was marked.
static func catch_up(d: WonderData, progress: ProgressData, profile: ProfileData) -> bool:
	var changed := false
	for key: String in progress.counts:
		if int(progress.counts[key]) > 0 and from_event(d, StringName(key)) != &"":
			changed = true
	if profile != null:
		if not profile.pip.is_empty():
			changed = record(d, PetRules.PIP, WonderData.FRIEND) or changed
		if not profile.baby_dragon.is_empty():
			changed = record(d, PetRules.DRAGON, WonderData.FRIEND) or changed
	return changed


## The kinds met for the first time among `near` ([species, position] pairs) within MEET_DISTANCE of `from`:
## marked here, each once, in the order they came.
static func newly_met(d: WonderData, near: Array, from: Vector3) -> Array[StringName]:
	var out: Array[StringName] = []
	for pair: Variant in near:
		if not (pair is Array and (pair as Array).size() >= 2 and pair[1] is Vector3):
			continue
		var sp := StringName(str(pair[0]))
		if (pair[1] as Vector3).distance_to(from) <= MEET_DISTANCE and record(d, sp, WonderData.MET):
			out.append(sp)
	return out


static func met_count(d: WonderData) -> int:
	var n := 0
	for sp in species():
		if knows(d, sp):
			n += 1
	return n


## Where to look for a kind not met yet (the page's clue): the first universe whose animals it is among.
static func home_words(sp: StringName) -> String:
	for u in range(1, UniverseRegistry.size() + 1):
		if UniverseRegistry.animals(u).has(sp):
			return Lang.t("Its home: %s") % Lang.t(UniverseRegistry.display_name(u))
	return Lang.t("A very special friend!")


## "5 of 12 animals".
static func count_words(d: WonderData) -> String:
	return Lang.t("%d of %d animals") % [met_count(d), AnimalRules.SPECIES.size()]
