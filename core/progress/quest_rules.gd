class_name QuestRules
extends RefCounted
## Quest givers and their picture-story chains (owner #45a, spec §14.17). Pure: the content, the steps and
## their checks, the rewards, and where a helper stands. The world's glue is QuestDirector; the saved state
## is QuestData (in ProgressData.quests).
##
## Tilly (Green Meadows) and a helper in each other universe tell short stories of 3-5 steps made of what
## the world has. A step is DO (count an event: its kind, how many; counted in the chain's universe from the
## moment the step starts), REACH (walk to the nearest place of a secret kind; the arrow shows the way) or
## GO (come back to the giver). A chain ends with a keepsake, a title, fixed gold (Survivor: base × 2^(u−1))
## and the place it led to. Fair fun (§6): no timers, nothing expires, a chain can be stopped and picked up
## later where it was, nothing is taken away, rewards are fixed and come once.

const DO := &"do"
const REACH := &"reach"
const GO := &"go"
const TITLE_PREFIX := "q_"

const GIVERS := {
	&"tilly": {"name": "Tilly", "universe": 1, "picture": &"tilly", "what": "the trader",
		"hello": "Hello, friend! I have a story for you."},
	&"zara": {"name": "Zara", "universe": 2, "picture": &"zara", "what": "the explorer",
		"hello": "Hi! I explore the sand. Will you help me?"},
	&"bram": {"name": "Bram", "universe": 3, "picture": &"bram", "what": "the ranger",
		"hello": "Brr, hello! I look after the snowy hills."},
	&"mimi": {"name": "Mimi", "universe": 4, "picture": &"mimi", "what": "the baker",
		"hello": "Hello, sweetie! I bake the yummiest cakes."},
	# Owner #39's Dragon Realm (universe 5, merged 2026-09-25): the lead added its helper.
	&"nell": {"name": "Nell", "universe": 5, "picture": &"nell", "what": "the dragon keeper",
		"hello": "Hello! I look after the baby dragons up here."},
	# Universe 6, the Glow Caves: their helper, a cave guide who maps the caves.
	&"mira": {"name": "Mira", "universe": 6, "picture": &"mira", "what": "the cave guide",
		"hello": "Hi! I map these glowing caves. Shh, the glow-worms are shy."},
}

## Every chain, in the order its giver tells them (the next one comes after the one before is done).
## "place": the step whose spot becomes the chain's new place. "find": the secret kind the arrow shows.
const CHAINS: Array[Dictionary] = [
	{"id": &"tilly_map", "giver": &"tilly", "title": "Tilly's lost map", "picture": &"map", "gold": 100,
		"story": "The wind blew my old map away! Help me find where it leads.",
		"keepsake": {"id": &"old_key", "words": "Tilly's old key", "picture": &"key"}, "earns": "Map Reader",
		"steps": [
			{"type": DO, "kind": &"secret_found/treasure", "need": 1, "words": "Dig up buried treasure",
				"picture": &"chest", "find": &"treasure"},
			{"type": DO, "kind": &"secret_found/ruins", "need": 1, "words": "Find the old ruins on the map",
				"picture": &"ruins", "find": &"ruins", "place": true},
			{"type": GO, "words": "Bring the old key to Tilly", "picture": &"key"},
		]},
	{"id": &"tilly_pets", "giver": &"tilly", "title": "A home for animals", "picture": &"dog", "gold": 120,
		"story": "Slimes scare my animal friends at night. Will you help them?",
		"keepsake": {"id": &"bell", "words": "A golden bell", "picture": &"bell"}, "earns": "Animal Hero",
		"steps": [
			{"type": DO, "kind": &"animal_tamed", "need": 1, "words": "Make friends with a dog or cat", "picture": &"dog"},
			{"type": DO, "kind": &"monster_defeated/slime", "need": 3, "words": "Chase away 3 slimes",
				"picture": &"monster"},
			{"type": DO, "kind": &"secret_found/hollowtree", "need": 1, "words": "Find a hollow tree for them",
				"picture": &"hollow", "find": &"hollowtree", "place": true},
			{"type": GO, "words": "Tell Tilly they are safe", "picture": &"tilly"},
		]},
	{"id": &"tilly_star", "giver": &"tilly", "title": "Catch a falling star", "picture": &"star", "gold": 150,
		"story": "Stars fall here at night! Wake a buddy and catch one with me.",
		"keepsake": {"id": &"star_jar", "words": "Star in a jar", "picture": &"star_jar"}, "earns": "Star Catcher",
		"steps": [
			{"type": DO, "kind": &"buddy_woken", "need": 1, "words": "Wake a buddy with the magic wand", "picture": &"wand"},
			{"type": DO, "kind": &"secret_found/star", "need": 1, "words": "Catch a shooting star at night",
				"picture": &"star"},
			{"type": DO, "kind": &"secret_found/geode", "need": 1, "words": "Find a crystal geode deep down",
				"picture": &"geode", "find": &"geode", "place": true},
			{"type": GO, "words": "Show Tilly the star dust", "picture": &"tilly"},
		]},
	{"id": &"zara_scarab", "giver": &"zara", "title": "The golden scarab", "picture": &"scarab", "gold": 100,
		"story": "I lost a piece of my map in the sand. It shows the way to a pyramid!",
		"keepsake": {"id": &"scarab", "words": "A golden scarab", "picture": &"scarab"}, "earns": "Pyramid Pal",
		"steps": [
			{"type": DO, "kind": &"secret_found/treasure", "need": 1, "words": "Find my lost map piece",
				"picture": &"chest", "find": &"treasure"},
			{"type": REACH, "kind": &"temple", "words": "Follow it to the pyramid", "picture": &"temple"},
			{"type": DO, "kind": &"secret_found/temple", "need": 1, "words": "Open the hidden door",
				"picture": &"temple", "find": &"temple", "place": true},
			{"type": GO, "words": "Bring the golden scarab to Zara", "picture": &"zara"},
		]},
	{"id": &"zara_oasis", "giver": &"zara", "title": "Safe desert paths", "picture": &"compass", "gold": 120,
		"story": "Scorpions are on my path, and my tent needs a window.",
		"keepsake": {"id": &"compass", "words": "Zara's compass", "picture": &"compass"}, "earns": "Desert Guard",
		"steps": [
			{"type": DO, "kind": &"monster_defeated/scorpion", "need": 3, "words": "Chase away 3 scorpions",
				"picture": &"scorpion"},
			{"type": DO, "kind": &"item_crafted/glass", "need": 1, "words": "Make glass from sand in an oven",
				"picture": &"glass"},
			{"type": DO, "kind": &"secret_found/mineshaft", "need": 1, "words": "Find the old mineshaft",
				"picture": &"mineshaft", "find": &"mineshaft", "place": true},
			{"type": GO, "words": "Tell Zara the way is safe", "picture": &"zara"},
		]},
	{"id": &"bram_lantern", "giver": &"bram", "title": "Light up the camp", "picture": &"lantern", "gold": 100,
		"story": "Brr! My snowy camp is dark and cold. Can you help me?",
		"keepsake": {"id": &"snow_globe", "words": "A snow globe", "picture": &"snow_globe"}, "earns": "Frost Friend",
		"steps": [
			{"type": DO, "kind": &"secret_found/camp", "need": 1, "words": "Find the snowy camp", "picture": &"camp",
				"find": &"camp", "place": true},
			{"type": DO, "kind": &"item_crafted/lantern", "need": 1, "words": "Make a lantern at a table",
				"picture": &"lantern"},
			{"type": DO, "kind": &"monster_defeated/yeti", "need": 2, "words": "Chase away 2 yetis", "picture": &"yeti"},
			{"type": GO, "words": "Bring the light to Bram", "picture": &"bram"},
		]},
	{"id": &"bram_temple", "giver": &"bram", "title": "The ice temple", "picture": &"temple", "gold": 120,
		"story": "Ice bats guard an old temple in the snow. Let's find it together!",
		"keepsake": {"id": &"ice_crown", "words": "An ice crown", "picture": &"ice_crown"}, "earns": "Ice Explorer",
		"steps": [
			{"type": DO, "kind": &"monster_defeated/bat", "need": 3, "words": "Chase away 3 ice bats", "picture": &"bat"},
			{"type": REACH, "kind": &"temple", "words": "Follow the arrow to the ice temple", "picture": &"temple"},
			{"type": DO, "kind": &"secret_found/temple", "need": 1, "words": "Step on the plates in order",
				"picture": &"temple", "find": &"temple", "place": true},
			{"type": GO, "words": "Come back to Bram", "picture": &"bram"},
		]},
	{"id": &"mimi_cupcake", "giver": &"mimi", "title": "The big cake party", "picture": &"cupcake", "gold": 100,
		"story": "I'm baking the biggest cake! I need sprinkles and a gingerbread house.",
		"keepsake": {"id": &"cupcake", "words": "A cherry cupcake", "picture": &"cupcake"}, "earns": "Sweet Helper",
		"steps": [
			{"type": DO, "kind": &"monster_defeated/gummy", "need": 3, "words": "Chase away 3 gummy bears",
				"picture": &"gummy"},
			{"type": DO, "kind": &"secret_found/geode", "need": 1, "words": "Find a rock-candy geode", "picture": &"geode",
				"find": &"geode"},
			{"type": DO, "kind": &"secret_found/temple", "need": 1, "words": "Find the gingerbread house's treasure",
				"picture": &"house", "find": &"temple", "place": true},
			{"type": GO, "words": "Bring the sprinkles to Mimi", "picture": &"mimi"},
		]},
	{"id": &"mimi_recipe", "giver": &"mimi", "title": "The hidden recipe", "picture": &"recipe", "gold": 120,
		"story": "Candy sneakers took my recipe book! It must be hidden somewhere.",
		"keepsake": {"id": &"recipe", "words": "Mimi's recipe book", "picture": &"recipe"}, "earns": "Candy Chef",
		"steps": [
			{"type": DO, "kind": &"monster_defeated/sneaker", "need": 2, "words": "Chase away 2 candy sneakers",
				"picture": &"sneaker"},
			{"type": DO, "kind": &"secret_found/room", "need": 1, "words": "Find the hidden room in the cake",
				"picture": &"room", "find": &"room"},
			{"type": DO, "kind": &"secret_found/haunted", "need": 1, "words": "Visit the haunted house",
				"picture": &"haunted", "find": &"haunted", "place": true},
			{"type": GO, "words": "Bring the recipe book to Mimi", "picture": &"mimi"},
		]},
	{"id": &"nell_egg", "giver": &"nell", "title": "The lost dragon egg", "picture": &"dragon", "gold": 100,
		"story": "Shadow bats chased a mother dragon from her nest. Help me find it!",
		"keepsake": {"id": &"dragon_scale", "words": "A shiny dragon scale", "picture": &"dragon"}, "earns": "Dragon Friend",
		"steps": [
			{"type": DO, "kind": &"monster_defeated/shadow_bat", "need": 3, "words": "Chase away 3 shadow bats",
				"picture": &"bat"},
			{"type": DO, "kind": &"secret_found/island", "need": 1, "words": "Find the dragon nest", "picture": &"island",
				"find": &"island", "place": true},
			{"type": GO, "words": "Tell Nell the nest is safe", "picture": &"nell"},
		]},
	{"id": &"nell_shrine", "giver": &"nell", "title": "The sky shrine", "picture": &"temple", "gold": 120,
		"story": "Wisps glow by an old sky shrine. Its treasure helps dragons fly!",
		"keepsake": {"id": &"moon_stone", "words": "A glowing moon stone", "picture": &"geode"}, "earns": "Sky Explorer",
		"steps": [
			{"type": DO, "kind": &"monster_defeated/wisp", "need": 2, "words": "Chase away 2 wisps", "picture": &"star"},
			{"type": DO, "kind": &"secret_found/geode", "need": 1, "words": "Find a sun crystal geode", "picture": &"geode",
				"find": &"geode"},
			{"type": REACH, "kind": &"temple", "words": "Follow the arrow to the shrine", "picture": &"temple"},
			{"type": DO, "kind": &"secret_found/temple", "need": 1, "words": "Open the sky shrine", "picture": &"temple",
				"find": &"temple", "place": true},
			{"type": GO, "words": "Come back to Nell", "picture": &"nell"},
		]},
	{"id": &"mira_lamp", "giver": &"mira", "title": "The lost spore lamp", "picture": &"spore_lamp", "gold": 100,
		"story": "Spore puffs rolled my lamp into a hidden grotto. Help me find it!",
		"keepsake": {"id": &"cave_pearl", "words": "A round cave pearl", "picture": &"pearl"}, "earns": "Cave Explorer",
		"steps": [
			{"type": DO, "kind": &"monster_defeated/spore_puff", "need": 3, "words": "Puff away 3 spore puffs",
				"picture": &"spore_lamp"},
			{"type": DO, "kind": &"secret_found/island", "need": 1, "words": "Find a hidden grotto", "picture": &"island",
				"find": &"island", "place": true},
			{"type": GO, "words": "Bring the lamp back to Mira", "picture": &"mira"},
		]},
	{"id": &"mira_crystal", "giver": &"mira", "title": "The crystal temple", "picture": &"temple", "gold": 120,
		"story": "Blind cave crawlers hear every step near an old flowstone temple. Tiptoe!",
		"keepsake": {"id": &"selenite_shard", "words": "A shining selenite crystal", "picture": &"selenite"},
		"earns": "Crystal Finder",
		"steps": [
			{"type": DO, "kind": &"monster_defeated/crawler", "need": 2, "words": "Chase away 2 cave crawlers",
				"picture": &"monster"},
			{"type": DO, "kind": &"secret_found/geode", "need": 1, "words": "Find a selenite geode", "picture": &"geode",
				"find": &"geode"},
			{"type": REACH, "kind": &"temple", "words": "Follow the arrow to the temple", "picture": &"temple"},
			{"type": DO, "kind": &"secret_found/temple", "need": 1, "words": "Open the flowstone temple", "picture": &"temple",
				"find": &"temple", "place": true},
			{"type": GO, "words": "Come back to Mira", "picture": &"mira"},
		]},
]


## "in the Sandstorm Desert", "in Frostpeak": where something is, in words (universes whose name wants "the").
const _THE := {2: true, 4: true, 5: true, 6: true}


static func in_universe(u: int) -> String:
	return Lang.t("in %s%s") % ["the " if _THE.has(u) else "", Lang.t(UniverseRegistry.display_name(u))]


static func chain(id: StringName) -> Dictionary:
	for c: Dictionary in CHAINS:
		if c.id == id:
			return c
	return {}


static func giver(id: StringName) -> Dictionary:
	return GIVERS.get(id, {})


## The giver of universe u (&"" for none).
static func giver_in(u: int) -> StringName:
	for id: StringName in GIVERS:
		if int(GIVERS[id].universe) == u:
			return id
	return &""


static func chains_of(giver_id: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	for c: Dictionary in CHAINS:
		if c.giver == giver_id:
			out.append(c.id)
	return out


static func universe_of(chain_id: StringName) -> int:
	var c := chain(chain_id)
	return int(giver(c.giver).universe) if not c.is_empty() else 0


static func steps_of(chain_id: StringName) -> Array:
	return chain(chain_id).get("steps", [])


static func keepsake(chain_id: StringName) -> Dictionary:
	return chain(chain_id).get("keepsake", {})


## A chain's title for the name tag: "q_<chain>".
static func title_id(chain_id: StringName) -> StringName:
	return StringName(TITLE_PREFIX + String(chain_id))


static func is_title(id: StringName) -> bool:
	var s := String(id)
	return s.begins_with(TITLE_PREFIX) and not chain(StringName(s.substr(TITLE_PREFIX.length()))).is_empty()


static func title_words(id: StringName) -> String:
	if not is_title(id):
		return ""
	return str(chain(StringName(String(id).substr(TITLE_PREFIX.length()))).earns)


## A chain's fixed Survivor gold: its base × 2^(u−1) (spec §5.1).
static func gold_for(chain_id: StringName) -> int:
	var c := chain(chain_id)
	return UniverseRules.gold(int(c.gold), universe_of(chain_id)) if not c.is_empty() else 0


## A chain with a step only Survivor has (crafting) is told only in Survivor.
static func needs_survivor(chain_id: StringName) -> bool:
	for s: Dictionary in steps_of(chain_id):
		if s.type == DO and LevelRules.family(s.kind) == LevelRules.CRAFTED:
			return true
	return false


## Stories are told in Sandbox and Survivor worlds (the Sandbox: those with nothing Survivor-only), never in
## the Monster Wave arena.
static func allowed_in(chain_id: StringName, mode: StringName) -> bool:
	match mode:
		ModeRules.SURVIVOR:
			return true
		ModeRules.SANDBOX:
			return not needs_survivor(chain_id)
	return false


## The story `giver_id` tells this child now in `mode`: the first not done (in order), &"" when every story
## is done or the next one can't be done here.
static func offered(d: ProgressData, giver_id: StringName, mode: StringName) -> StringName:
	for id in chains_of(giver_id):
		if is_done(d, id):
			continue
		return id if allowed_in(id, mode) else &""
	return &""


static func is_done(d: ProgressData, chain_id: StringName) -> bool:
	return d.quests.done.has(String(chain_id))


static func is_started(d: ProgressData, chain_id: StringName) -> bool:
	return d.quests.chains.has(String(chain_id))


## The step being done (-1: not started).
static func step_index(d: ProgressData, chain_id: StringName) -> int:
	var e: Variant = d.quests.chains.get(String(chain_id))
	return int(e.step) if e is Dictionary else -1


## The step being done, or {} (not started, or every step done: the rewards wait).
static func current_step(d: ProgressData, chain_id: StringName) -> Dictionary:
	var i := step_index(d, chain_id)
	var steps := steps_of(chain_id)
	return steps[i] if i >= 0 and i < steps.size() else {}


static func is_ready_to_finish(d: ProgressData, chain_id: StringName) -> bool:
	return is_started(d, chain_id) and step_index(d, chain_id) >= steps_of(chain_id).size()


## Starts a story (or goes on with it when it was started before); the one being followed waits where it was.
static func start(d: ProgressData, chain_id: StringName) -> bool:
	if chain(chain_id).is_empty() or is_done(d, chain_id):
		return false
	if is_started(d, chain_id):
		return resume(d, chain_id)
	stop(d)
	d.quests.chains[String(chain_id)] = {"step": 0, "start": -1, "extra": 0}
	d.quests.active = chain_id
	_begin_counting(d, chain_id)
	return true


## Stops the story being followed; it waits with what it counted so far.
static func stop(d: ProgressData) -> void:
	var id := d.quests.active
	if id == &"":
		return
	var e: Variant = d.quests.chains.get(String(id))
	if e is Dictionary:
		e.extra = _counted(d, id)
		e.start = -1
	d.quests.active = &""


## Picks a waiting story up again at the step where it was.
static func resume(d: ProgressData, chain_id: StringName) -> bool:
	if not is_started(d, chain_id):
		return false
	if d.quests.active == chain_id:
		return true
	stop(d)
	d.quests.active = chain_id
	_begin_counting(d, chain_id)
	return true


## (counted, needed) for the step being done; a REACH or GO step is (0, 1) until arrived.
static func step_progress(d: ProgressData, chain_id: StringName) -> Vector2i:
	var s := current_step(d, chain_id)
	if s.is_empty():
		return Vector2i.ZERO
	if s.type != DO:
		return Vector2i(0, 1)
	var need := int(s.need)
	return Vector2i(clampi(_counted(d, chain_id), 0, need), need)


## Moves the story being followed on past every counting step that is done; returns what happened, each
## {chain, step (the step done), finished (it was the last)}.
static func check(d: ProgressData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var id := d.quests.active
	for guard in 8:
		var s := current_step(d, id)
		if s.is_empty():
			break
		var done := false
		if s.type == DO:
			done = _counted(d, id) >= int(s.need)
		elif s.type == REACH:
			done = _counting_kind(id, step_index(d, id)) != &"" and _counted(d, id) > 0   # found on the way
		if not done:
			break
		out.append(_advance(d, id))
	return out


## A REACH or GO step of the story being followed was arrived at. True when it moved on.
static func arrive(d: ProgressData, chain_id: StringName, type: StringName) -> bool:
	if d.quests.active != chain_id or type == DO:
		return false
	var s := current_step(d, chain_id)
	if s.is_empty() or s.type != type:
		return false
	_advance(d, chain_id)
	return true


## A friend's `amount` of `kind` for the step being done (co-op): true when it counted.
static func help(d: ProgressData, chain_id: StringName, kind: StringName, amount: int) -> bool:
	if d.quests.active != chain_id or amount <= 0:
		return false
	var s := current_step(d, chain_id)
	if s.is_empty() or s.type != DO or not matches(s.kind, kind):
		return false
	var e: Dictionary = d.quests.chains[String(chain_id)]
	e.extra = mini(int(e.extra) + amount, LevelRules.MAX_AMOUNT)
	return true


## Whether an event of `event_kind` counts for a step asking for `step_kind` (a detail, or its family).
static func matches(step_kind: StringName, event_kind: StringName) -> bool:
	return step_kind == event_kind or (not String(step_kind).contains("/") and LevelRules.family(event_kind) == step_kind)


## The story is done: its keepsake and title (from `done`), and its place. False when it was done before.
static func finish(d: ProgressData, chain_id: StringName, place: Dictionary = {}) -> bool:
	if chain(chain_id).is_empty() or is_done(d, chain_id):
		return false
	d.quests.done.append(String(chain_id))
	d.quests.chains.erase(String(chain_id))
	if d.quests.active == chain_id:
		d.quests.active = &""
	if not place.is_empty():
		var p := place.duplicate()
		p.chain = String(chain_id)
		p = QuestData.clean_place(p)
		if not p.is_empty() and not d.quests.has_place(chain_id) and d.quests.places.size() < QuestData.MAX_PLACES:
			d.quests.places.append(p)
	return true


static func keepsakes(d: ProgressData) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in d.quests.done:
		out.append(StringName(keepsake(StringName(id)).get("id", &"")))
	return out


static func titles(d: ProgressData) -> Array[StringName]:
	var out: Array[StringName] = []
	for id in d.quests.done:
		out.append(title_id(StringName(id)))
	return out


## The kind the step counts: a DO step's own; a REACH step's next DO step's (a find on the way counts for it).
static func _counting_kind(chain_id: StringName, i: int) -> StringName:
	var steps := steps_of(chain_id)
	if i < 0 or i >= steps.size():
		return &""
	var s: Dictionary = steps[i]
	if s.type == DO:
		return s.kind
	if s.type == REACH and i + 1 < steps.size() and steps[i + 1].type == DO:
		return steps[i + 1].kind
	return &""


static func _counted(d: ProgressData, chain_id: StringName) -> int:
	var e: Variant = d.quests.chains.get(String(chain_id))
	if not e is Dictionary:
		return 0
	var n := int(e.extra)
	var kind := _counting_kind(chain_id, int(e.step))
	if kind != &"" and int(e.start) >= 0:
		n += d.count_in(kind, universe_of(chain_id)) - int(e.start)
	return maxi(n, 0)


static func _begin_counting(d: ProgressData, chain_id: StringName) -> void:
	var e: Dictionary = d.quests.chains[String(chain_id)]
	var kind := _counting_kind(chain_id, int(e.step))
	e.start = d.count_in(kind, universe_of(chain_id)) if kind != &"" else 0


static func _advance(d: ProgressData, chain_id: StringName) -> Dictionary:
	var e: Dictionary = d.quests.chains[String(chain_id)]
	var i := int(e.step)
	var steps := steps_of(chain_id)
	var carried: bool = steps[i].type == REACH and _counting_kind(chain_id, i) != &""
	e.step = i + 1
	if not carried:   # a REACH step's count goes on for the DO step after it
		e.extra = 0
		if d.quests.active == chain_id:
			_begin_counting(d, chain_id)
		else:
			e.start = -1
	return {"chain": chain_id, "step": i, "finished": i + 1 >= steps.size()}


# --- Where a helper stands (the universes' helpers; Tilly has her stall) -------------------------------------

## Rings tried, nearest first: past Tilly's stall (12) and the hub circle (4-11), inside the Totem (20).
const RADII: Array[int] = [16, 15, 17, 14, 18, 13, 19]
const ANGLE_STEPS := 48
const DRY_RADIUS := 1            # the 3 x 3 under a helper is dry, at most a block up or down
const TREE_CLEAR := 2            # no tree trunk this close (in columns)
const CLEAR_OF := 6.0            # this far from Tilly's stall, the Totem, the hub circle and the Theater
const WAY_CLEAR := 3.0           # this far off the straight way from the spawn to each of them


## {pos: Vector3 (feet, on the ground), yaw (facing the spawn)} on the first good ring cell; with none, the
## first ring cell clear of the landmarks and their ways. height_at(x, z) -> int, ground_ok(x, z) -> bool,
## tree_at(x, z) -> bool; landmarks: spots to stand clear of and off the way to.
static func giver_spot(world_seed: int, spawn: Vector2i, height_at: Callable, ground_ok: Callable, tree_at: Callable,
		landmarks_here: Array[Vector3]) -> Dictionary:
	var start := absi(world_seed * 40503 ^ 7919) % ANGLE_STEPS
	for r in RADII:
		for i in ANGLE_STEPS:
			var c := _ring_cell(spawn, r, start + i)
			if _clear(c, spawn, landmarks_here) and _good(c, height_at, ground_ok, tree_at):
				return _spot(c, spawn, height_at)
	for r in RADII:
		for i in ANGLE_STEPS:
			var c := _ring_cell(spawn, r, start + i)
			if _clear(c, spawn, landmarks_here):
				return _spot(c, spawn, height_at)
	return _spot(_ring_cell(spawn, RADII[0], start), spawn, height_at)


## The landmarks by a world's spawn, from the seed alone: Tilly's stall, the Totem, the hub circle and the
## Theater (where they are or would be).
static func landmarks(world_seed: int, shape: MeadowsShape, spawn: Vector2i) -> Array[Vector3]:
	var stall: Vector3 = TraderRules.stall_for_world(world_seed, shape, spawn).pos
	var totem: Vector3 = WaveRules.totem_for_world(world_seed, shape, spawn, stall).pos
	var circle: Vector3 = HubRules.circle_for_world(world_seed, shape, spawn).pos
	var out: Array[Vector3] = [stall, totem, circle]
	var theater := TheaterSite.pick_for(shape)
	if not theater.is_empty():
		out.append(Vector3(theater.pos as Vector3i) + Vector3(0.5, 0.0, 0.5))
	return out


## A helper's spot in a real world (the same on every game: seed and terrain rules only).
static func giver_for_world(world_seed: int, shape: MeadowsShape, spawn: Vector2i) -> Dictionary:
	var caves := CaveShape.new(world_seed)
	var ground_ok := func(x: int, z: int) -> bool:
		return shape.height_at(x, z) > MeadowsShape.SEA_LEVEL + 1 and not shape.is_river(x, z) and not caves.entrance_open(x, z)
	return giver_spot(world_seed, spawn, shape.height_at, ground_ok, shape.tree_at, landmarks(world_seed, shape, spawn))


## How far p is from the straight way from a to b.
static func way_distance(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var t := clampf((p - a).dot(ab) / maxf(ab.length_squared(), 0.0001), 0.0, 1.0)
	return p.distance_to(a + ab * t)


static func _ring_cell(spawn: Vector2i, r: int, step: int) -> Vector2i:
	var a := TAU * (step % ANGLE_STEPS) / ANGLE_STEPS
	return spawn + Vector2i(roundi(cos(a) * r), roundi(sin(a) * r))


static func _clear(c: Vector2i, spawn: Vector2i, marks: Array[Vector3]) -> bool:
	var p := Vector2(c.x + 0.5, c.y + 0.5)
	var from := Vector2(spawn.x + 0.5, spawn.y + 0.5)
	for m in marks:
		if not m.is_finite():
			continue
		var at := Vector2(m.x, m.z)
		if p.distance_to(at) < CLEAR_OF or way_distance(p, from, at) < WAY_CLEAR:
			return false
	return true


static func _good(c: Vector2i, height_at: Callable, ground_ok: Callable, tree_at: Callable) -> bool:
	var h := int(height_at.call(c.x, c.y))
	for dx in range(-DRY_RADIUS, DRY_RADIUS + 1):
		for dz in range(-DRY_RADIUS, DRY_RADIUS + 1):
			if absi(int(height_at.call(c.x + dx, c.y + dz)) - h) > 1 or not ground_ok.call(c.x + dx, c.y + dz):
				return false
	for dx in range(-TREE_CLEAR, TREE_CLEAR + 1):
		for dz in range(-TREE_CLEAR, TREE_CLEAR + 1):
			if tree_at.call(c.x + dx, c.y + dz):
				return false
	return true


static func _spot(c: Vector2i, spawn: Vector2i, height_at: Callable) -> Dictionary:
	var d := Vector2(spawn - c)
	return {"pos": Vector3(c.x + 0.5, float(height_at.call(c.x, c.y)), c.y + 0.5), "yaw": atan2(-d.x, -d.y)}
