class_name WorldMeta
extends RefCounted
## Per-world save data stored next to the voxel database. from_json never fails.

const VERSION := 1
const HOTBAR_SIZE := 9
const MAX_BUDDIES := 10
const MAX_PETS := 12            # all players' pets in one world
const MAX_HOMES := 16

var seed := 0
## ModeRules.SANDBOX or ModeRules.SURVIVOR (M2); worlds saved before M2 are Sandbox worlds.
var mode: StringName = ModeRules.SANDBOX
var player_pos := Vector3.INF   # INF = never saved; spawn on the surface
var player_yaw := 0.0
var physics_mode: int = PhysicsMode.Mode.NORMAL
## The Physics Lab's mode (M3 Task 6, LabRules); its body movement is physics_mode.
var lab_mode: int = LabRules.Mode.NORMAL
var hotbar: Array[int] = _default_hotbar()
var selected_slot := 0
## Living buddies: [{blocks: [[x, y, z, id], ...], pos: [x, y, z], yaw: float, name: String}]
var buddies: Array[Dictionary] = []
## Pets (tamed dogs, cats, foxes and parrots): [{species: String, name: String, pos: [x, y, z], id: String,
## collar: int, happiness: float (M3 Task 11), mind}]. Pip is never here: he lives in the profile.
var pets: Array[Dictionary] = []
## Time of day 0..1 (DayCycle); the host owns the clock.
var time_of_day := DayCycle.START
## Each player's home, the bed they last slept in: {player name: Vector3i}.
var homes: Dictionary = {}

## Practice targets (M1b Task 11): [{item: ItemIds.DUMMY or BULLSEYE, pos: [x, y, z], yaw: float}]
var targets: Array[Dictionary] = []
## Survivor (M2 §12.2): each player's counted blocks and items, by player name (like homes):
## {name: Inventory.to_save()}.
var inventories: Dictionary = {}
## Pickup bags (M2 Task 2): the blocks knocked-out players left behind: [{owner: player name
## ("" = anyone's), pos: [x, y, z] (bottom centre), items: [[block id, count], ...], age: seconds}]
var bags: Array[Dictionary] = []

## Tilly the trader's stall (M2 Task 7, Survivor worlds): her feet and facing (INF = not placed yet),
## and whether this world's player has visited her (the one-time hint arrow over her stall).
var trader_pos := Vector3.INF
var trader_yaw := 0.0
var trader_visited := false

## Survivor difficulty (M2 Task 17, DifficultyRules): chosen for a new world, NORMAL for older worlds.
var difficulty: StringName = DifficultyRules.NORMAL
## Sandbox world setting (M2 Task 4, §12.15): night monsters come (ON, the default) or not.
var monsters_on := true

## Bot friends (M2 Task 15): [{name: String, personality: String, look: int}], at most
## BotRules.MAX_BOTS; they come back next to the player.
var bots: Array[Dictionary] = []

## Secrets and treasures (M2 Task 16): what this world's players found, opened and solved.
var secrets := SecretState.new()

## The Shorts Theater (M3 Task 17): [x, y, z, facing] (TheaterSite.to_save), or [] = not placed yet.
var theater: Array = []
## Spec §21d (missions): the Launch Site, [x, y, z, facing, stamped] (LaunchSite.to_save), or [] = not placed yet.
var launch_site: Array = []
## Owner #112, Life Town (Life L2): [x, y, z, facing] (LifeTown.to_save) once it stands, or [] = not placed yet.
var life_town: Array = []
## Owner #132 (W1): the Discovery Academy, [x, y, z, facing] (and 1 for the island over the spawn) once it stands
## (AcademyPlaza.to_save), or [] = not placed yet.
var academy: Array = []

## The Monster Totem (M2 Task 9, every world): where it stands and faces (INF = not placed yet), and
## the wave it offers next (WaveRules: a won wave raises it).
var totem_pos := Vector3.INF
var totem_yaw := 0.0
var wave_next := WaveRules.FIRST_WAVE

## The Stone Golem (M2 Task 10): honest help ({losses, best, wins}, BossRules.clean_help) and the
## portal its defeat opened (its feet; INF = not open yet).
var boss_help: Dictionary = BossRules.new_help()
var portal_pos := Vector3.INF

## Creature minds (M2 Task 18): each species' learned table in this world, {species id: saved
## TinyNet} (MindBook; at most 2 KB). Pets and bot friends keep their own minds in `pets` / `bots`.
var minds: Dictionary = {}
## Monster minds (M2 Task 18 part 2): the one-time hints this world's children were given
## ("<kind>:<tactic>", MonsterSpecies.HINTS).
var mind_hints: Array[String] = []
## The universe ladder (M3 Task 5): which universe this world is (UniverseRules; worlds saved before
## M3 are Green Meadows, 1).
var universe := 1
## Portal frames and cores (M3 Task 5): the links and frames, PortalLinks.to_save ([] = none).
var portals: Array = []
## Survivor games (owner feedback #33, spec §12.18): the game this world plays (SurvivorGames; worlds saved
## before are CLASSIC) and each player's scores, {player name: GameScores record}.
var game: StringName = SurvivorGames.CLASSIC
var game_scores: Dictionary = {}
## Monster Wave (owner feedback #44, spec §12.20): each player's best in this arena, {player name:
## ArenaRules record {best_time, best_wave}} (an arena world is one universe's).
var arena: Dictionary = {}
## Smart blocks and Game Blocks (M3 Task 7, SmartState): teleport pad pairs, courses (goals, best times, the
## best run recorded for bots) and power cells to look at again on load.
var smart: Dictionary = SmartState.clean(null)
## Surprise drops (M3 Task 14b, DropRules.clean_save): the piñata clock (seconds of play since the last one)
## and how many came.
var drops: Dictionary = DropRules.clean_save(null)

## Storm Run (M4 H): the best team score in this world (stars).
var storm_best := 0
## The Gold Farm (M3 Task 10, FarmRules): {} = none; one per world, its owner's (the host's).
var farm: Dictionary = {}

## Ziplines (M3 Task 14a): the posts and their links, ZiplineLinks.to_save ([] = none).
var ziplines: Array = []
## Owner 39: the world's universe portals (PortalGates.to_save) and, after a trip through one, the universe the
## traveller came from (0 = none): they arrive in front of this world's portal back to it (built when it has none).
var gates: Array = []
var arrival_gate := 0

## Build Rewind (M3 Task 8): this world's recording, RewindLog.to_save ({} = none).
var rewind: Dictionary = {}

## Owner #45b (spec §14.18): the terrain version the world was made with. Only edited chunks are saved, so a world
## keeps its version forever: 1 is the M1-M3 Green Meadows (every world saved before), 2 the wild meadows.
const TERRAIN_LATEST := 2
var terrain := 1
## Owner #45b: the places found in this world (MeadowsPlaces ids, the world map shows them), by anyone.
var places_found: Array[String] = []
## Spec §26 (prospecting): the quests started in this world, the deposits found here, the oil wells (ProspectState's
## dictionary).
var prospect: Dictionary = {}
## Owner #109: the cars parked in this world (Vehicle.to_save, VehicleRules.clean_save'd: kind, colour, owner, place,
## turn, the pickup's load); [] = none (every world before the cars).
var cars: Array = []
const MAX_PLACES_FOUND := 512


static func new_random() -> WorldMeta:
	var m := WorldMeta.new()
	m.seed = randi()
	m.terrain = TERRAIN_LATEST   # owner #45b: a new world is made with the newest terrain
	return m


static func from_json(text: String) -> WorldMeta:
	var m := WorldMeta.new_random()
	var json := JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return m
	var d: Dictionary = json.data
	if _num(d.get("seed")):
		m.seed = int(d.seed)
	m.mode = ModeRules.valid(StringName(str(d.get("mode", ModeRules.SANDBOX))))
	var invs: Variant = d.get("inventories")
	if invs is Dictionary:
		for key: Variant in invs:
			if str(key) != "" and invs[key] is Array:
				m.inventories[str(key)] = Inventory.from_save(invs[key]).to_save()
	var p: Variant = d.get("player_pos")
	if _nums3(p):
		m.player_pos = Vector3(float(p[0]), float(p[1]), float(p[2]))
	m.player_yaw = float(d.player_yaw) if _num(d.get("player_yaw")) else 0.0
	var mode := int(d.get("physics_mode", 0)) if typeof(d.get("physics_mode")) in [TYPE_INT, TYPE_FLOAT] else 0
	m.physics_mode = mode if mode >= 0 and mode < PhysicsMode.Mode.size() else PhysicsMode.Mode.NORMAL
	m.lab_mode = LabRules.valid(int(d.lab_mode)) if _num(d.get("lab_mode")) and absf(d.lab_mode) < 100.0 else LabRules.Mode.NORMAL
	var hb: Variant = d.get("hotbar")
	if hb is Array:
		for i in mini((hb as Array).size(), HOTBAR_SIZE):
			var v: Variant = hb[i]
			if typeof(v) in [TYPE_INT, TYPE_FLOAT] and ItemIds.is_hotbar_valid(int(v)):
				m.hotbar[i] = int(v)
	var slot := int(d.get("selected_slot", 0)) if typeof(d.get("selected_slot")) in [TYPE_INT, TYPE_FLOAT] else 0
	m.selected_slot = clampi(slot, 0, HOTBAR_SIZE - 1)
	var list: Variant = d.get("buddies")
	if list is Array:
		for entry: Variant in list:
			var buddy := _parse_buddy(entry)
			if not buddy.is_empty() and m.buddies.size() < MAX_BUDDIES:
				m.buddies.append(buddy)
	var pet_list: Variant = d.get("pets")
	if pet_list is Array:
		for entry: Variant in pet_list:
			var pet := _parse_pet(entry)
			if not pet.is_empty() and m.pets.size() < MAX_PETS:
				m.pets.append(pet)
	_parse_time_and_homes(d, m)
	var diff: Variant = d.get("difficulty")
	m.difficulty = KnockoutRules.valid_difficulty(StringName(diff)) if diff is String else DifficultyRules.NORMAL
	var monsters: Variant = d.get("monsters_on")
	m.monsters_on = monsters if monsters is bool else true

	m.theater = TheaterSite.to_save(TheaterSite.from_save(d.get("theater")))
	var launch := LaunchSite.from_save(d.get("launch_site"))   # spec §21d
	m.launch_site = LaunchSite.to_save(launch, bool(launch.get("stamped", false)))
	m.life_town = LifeTown.to_save(LifeTown.from_save(d.get("life_town")))   # owner #112
	m.academy = AcademyPlaza.to_save(AcademyPlaza.from_save(d.get("academy")))   # owner #132 (W1)
	var target_list: Variant = d.get("targets")
	if target_list is Array:
		for entry: Variant in target_list:
			var target := _parse_target(entry)
			if not target.is_empty() and m.targets.size() < WeaponRules.MAX_TARGETS:
				m.targets.append(target)
	_parse_bags(d, m)
	_parse_trader(d.get("trader"), m)
	_parse_bots(d.get("bots"), m)
	m.secrets = SecretState.from_save(d.get("secrets"))
	_parse_totem(d.get("totem"), m)
	_parse_boss(d.get("boss"), m)
	m.minds = MindBook.clean(d.get("minds"))
	m.mind_hints = MonsterMinds.clean_hints(d.get("mind_hints"))
	_parse_m3_task5(d, m)
	_parse_survivor_games(d, m)
	m.smart = SmartState.clean(d.get("smart"))   # M3 Task 7
	_parse_m4h(d, m)
	m.drops = DropRules.clean_save(d.get("drops"))   # M3 Task 14b
	m.ziplines = ZiplineLinks.from_save(d.get("ziplines")).to_save()   # M3 Task 14a
	m.farm = FarmRules.clean(d.get("farm"))   # M3 Task 10
	m.prospect = ProspectState.from_dict(d.get("prospect")).to_dict()   # spec §26
	m.rewind = RewindLog.from_save(d.get("rewind")).to_save()   # M3 Task 8
	_parse_owner39(d, m)
	_parse_own45b(d, m)
	m.market = MarketRules.clean(d.get("market"))   # owner #37: market day's count of days
	m.tutorial_props = TutorialProps.clean(d.get("tutorial_props"))   # M3 Task 15
	_parse_space(d, m)   # owner #55
	m.cars = VehicleRules.clean_save(d.get("cars"))   # owner #109
	return m


## Bot friends (M2 Task 15): an unknown personality is dropped; a name that isn't a bot name (or is
## taken) and a missing or taken look get free ones; at most BotRules.MAX_BOTS.
static func _parse_bots(list: Variant, m: WorldMeta) -> void:
	if not list is Array:
		return
	var names: Array[String] = []
	var looks: Array[int] = []
	for entry: Variant in list:
		if m.bots.size() >= BotRules.MAX_BOTS:
			return
		if not entry is Dictionary:
			continue
		var e: Dictionary = entry
		var personality := StringName(str(e.get("personality", "")))
		if not BotRules.valid_personality(personality):
			continue
		var bot_name := str(e.get("name", ""))
		if not BotRules.NAMES.has(bot_name) or names.has(bot_name):
			bot_name = BotRules.pick_name(names, 0)
		var look := int(e.look) if _num(e.get("look")) else -1
		if not BotRules.valid_look(look) or looks.has(look):
			look = BotRules.pick_look(looks)
		names.append(bot_name)
		looks.append(look)
		var bot := {"name": bot_name, "personality": String(personality), "look": look}
		_keep_mind(e, bot)
		m.bots.append(bot)


## A valid practice target entry, or {} if anything about it is broken.
static func _parse_target(entry: Variant) -> Dictionary:
	if not entry is Dictionary:
		return {}
	var e: Dictionary = entry
	var item: Variant = e.get("item")
	var pos: Variant = e.get("pos")
	if not typeof(item) in [TYPE_INT, TYPE_FLOAT] or not ItemIds.is_target(int(item)):
		return {}
	if not _nums3(pos):
		return {}
	return {"item": int(item), "pos": [float(pos[0]), float(pos[1]), float(pos[2])],
		"yaw": float(e.yaw) if _num(e.get("yaw")) else 0.0}


## A valid pet entry, or {} if anything about it is broken.
static func _parse_pet(entry: Variant) -> Dictionary:
	if not entry is Dictionary:
		return {}
	var e: Dictionary = entry
	var species := StringName(str(e.get("species", "")))
	var pos: Variant = e.get("pos")
	if not AnimalRules.SPECIES.has(species) or not AnimalRules.SPECIES[species].tameable:
		return {}
	if not _nums3(pos):
		return {}
	var pet := {"species": String(species), "name": str(e.get("name", "Pet")),
		"pos": [float(pos[0]), float(pos[1]), float(pos[2])], "id": str(e.get("id", ""))}
	_keep_mind(e, pet)
	# M3 Task 11: its collar and heart; a name the filter refuses (a hand-edited save) becomes a fun name
	pet.name = PetRules.saved_name(pet.name, species, pet.id)
	pet.collar = PetRules.clean_collar(e.get("collar"))
	pet.happiness = PetRules.clean_happiness(e.get("happiness"))
	# owner #41: a horse's or camel's saddle, a donkey's chest (cleaned: only real things, 9 slots)
	if AnimalRideRules.takes_saddle(species) and e.get("saddled") is bool and e.saddled:
		pet.saddled = true
	var chest := DonkeyChest.clean(e.get("chest"))
	if PetRules.has_perk(species, PetRules.CHEST) and not DonkeyChest.is_empty(chest):
		pet.chest = Array(chest)
	_t20b_keep(e, pet)   # M3 Task 20b: a befriended monster's kind, and tricks
	return pet


## A valid buddy entry, or {} if anything about it is broken.
static func _parse_buddy(entry: Variant) -> Dictionary:
	if not entry is Dictionary:
		return {}
	var e: Dictionary = entry
	var blocks: Variant = e.get("blocks")
	var pos: Variant = e.get("pos")
	if not blocks is Array or (blocks as Array).is_empty() or (blocks as Array).size() > CaptureRules.MAX_BLOCKS:
		return {}
	if not _nums3(pos):
		return {}
	var clean: Array = []
	for b: Variant in blocks:
		if not b is Array or (b as Array).size() != 4 or not (b as Array).all(_num) \
				or not CaptureRules.is_capturable(int(b[3])):
			return {}
		clean.append([int(b[0]), int(b[1]), int(b[2]), int(b[3])])
	var buddy := {
		"blocks": clean,
		"pos": [float(pos[0]), float(pos[1]), float(pos[2])],
		"yaw": float(e.yaw) if _num(e.get("yaw")) else 0.0,
		"name": str(e.get("name", "Buddy")),
	}
	_t20b_keep(e, buddy)   # M3 Task 20b: its tricks
	return buddy


func to_json() -> String:
	var d := {
		"version": VERSION,
		"seed": seed,
		"mode": String(mode),
		"inventories": inventories,
		"monsters_on": monsters_on,
		"difficulty": String(difficulty),
		"player_yaw": player_yaw,
		"physics_mode": physics_mode,
		"lab_mode": lab_mode,
		"hotbar": hotbar,
		"selected_slot": selected_slot,
		"buddies": buddies,
		"pets": pets,
		"time_of_day": time_of_day,
		"homes": _homes_json(),
		"targets": targets,
		"bags": bags,
		"bots": bots,
		"secrets": secrets.to_save(),
		"theater": theater,
		"launch_site": launch_site,   # spec §21d
		"life_town": life_town,   # owner #112: Life Town
		"academy": academy,   # owner #132 (W1): the Discovery Academy
		"minds": minds,
		"mind_hints": mind_hints,
	}
	if has_player_pos():
		d.player_pos = [player_pos.x, player_pos.y, player_pos.z]
	if has_trader():
		d.trader = {"pos": [trader_pos.x, trader_pos.y, trader_pos.z], "yaw": trader_yaw, "visited": trader_visited}
	if has_totem():
		d.totem = {"pos": [totem_pos.x, totem_pos.y, totem_pos.z], "yaw": totem_yaw, "wave": wave_next}
	d.boss = _boss_json()   # M2 Task 10
	_m3_task5_json(d)
	_survivor_games_json(d)
	d.smart = SmartState.to_json(smart)   # M3 Task 7
	d.storm_best = storm_best   # M4 H
	d.drops = drops.duplicate()   # M3 Task 14b
	d.ziplines = ziplines   # M3 Task 14a
	d.farm = FarmRules.to_save(farm)   # M3 Task 10
	d.rewind = rewind   # M3 Task 8
	d.gates = gates   # owner 39
	d.arrival_gate = arrival_gate
	d.terrain = terrain   # owner #45b
	d.places_found = places_found
	d.prospect = prospect   # spec §26
	d.market = MarketRules.clean(market)   # owner #37
	d.tutorial_props = tutorial_props   # M3 Task 15
	d.space_home = space_home   # owner #55
	d.space_return = space_return
	d.cars = cars   # owner #109
	return JSON.stringify(d, "\t")


func has_player_pos() -> bool:
	return player_pos.is_finite()


static func _default_hotbar() -> Array[int]:
	return [BlockIds.GRASS, BlockIds.STONE, BlockIds.PLANKS, BlockIds.BRICK, BlockIds.GLASS,
		BlockIds.RED, BlockIds.BLUE, ItemIds.WAND, ItemIds.STAMP_HOUSE]


## Time of day and homes (M1b Task 10). Anything broken falls back to the defaults.
static func _parse_time_and_homes(d: Dictionary, m: WorldMeta) -> void:
	if _num(d.get("time_of_day")):
		m.time_of_day = DayCycle.wrap_time(float(d.time_of_day))
	var list: Variant = d.get("homes")
	if not list is Dictionary:
		return
	for key: Variant in list:
		var pos: Variant = list[key]
		if str(key) == "" or not _nums3(pos) or m.homes.size() >= MAX_HOMES:
			continue
		m.homes[str(key)] = Vector3i(int(pos[0]), int(pos[1]), int(pos[2]))


func _homes_json() -> Dictionary:
	var out := {}
	for key: String in homes:
		var p: Vector3i = homes[key]
		out[key] = [p.x, p.y, p.z]
	return out


## A finite number (JSON has no NaN, but a buggy writer or a hand edit can put anything here).
static func _num(v: Variant) -> bool:
	return typeof(v) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(v))


## Exactly three finite numbers (a saved position).
static func _nums3(v: Variant) -> bool:
	return v is Array and (v as Array).size() == 3 and (v as Array).all(_num)


## Pickup bags (M2 Task 2). A broken bag is dropped; its items keep only real blocks (KnockoutRules).
static func _parse_bags(d: Dictionary, m: WorldMeta) -> void:
	var list: Variant = d.get("bags")
	if not list is Array:
		return
	for entry: Variant in list:
		if m.bags.size() >= KnockoutRules.MAX_BAGS:
			return
		if not entry is Dictionary or not _nums3((entry as Dictionary).get("pos")):
			continue
		var e: Dictionary = entry
		var items := KnockoutRules.clean_items(e.get("items"))
		if items.is_empty():
			continue
		var pos: Array = e.pos
		var age := float(e.age) if _num(e.get("age")) else 0.0
		var bag_owner: String = (e.owner as String).substr(0, 32) if e.get("owner") is String else ""   # "" = anyone's
		m.bags.append({"owner": bag_owner, "items": items, "age": maxf(age, 0.0),
			"pos": [float(pos[0]), float(pos[1]), float(pos[2])]})


# --- M2 Task 7: Tilly the trader ----------------------------------------------------------------

func has_trader() -> bool:
	return trader_pos.is_finite()


## A broken stall entry leaves the world without one (the sandbox places her again).
static func _parse_trader(entry: Variant, m: WorldMeta) -> void:
	if not entry is Dictionary or not _nums3((entry as Dictionary).get("pos")):
		return
	var e: Dictionary = entry
	m.trader_pos = Vector3(float(e.pos[0]), float(e.pos[1]), float(e.pos[2]))
	m.trader_yaw = float(e.yaw) if _num(e.get("yaw")) else 0.0
	m.trader_visited = e.get("visited") is bool and bool(e.visited)

# --- M2 Task 9: the Monster Totem -------------------------------------------------------------------

func has_totem() -> bool:
	return totem_pos.is_finite()


## A broken Totem entry leaves the world without one (the sandbox places it again, from wave 1).
static func _parse_totem(entry: Variant, m: WorldMeta) -> void:
	if not entry is Dictionary or not _nums3((entry as Dictionary).get("pos")):
		return
	var e: Dictionary = entry
	m.totem_pos = Vector3(float(e.pos[0]), float(e.pos[1]), float(e.pos[2]))
	m.totem_yaw = float(e.yaw) if _num(e.get("yaw")) else 0.0
	var wave: Variant = e.get("wave")
	m.wave_next = WaveRules.valid_wave(int(clampf(float(wave), -1.0, WaveRules.MAX_WAVE))) if _num(wave) else WaveRules.FIRST_WAVE

# --- M2 Task 10: the Stone Golem's honest help and the portal ------------------------------------

func has_portal() -> bool:
	return portal_pos.is_finite()


func _boss_json() -> Dictionary:
	var b := boss_help.duplicate()
	if has_portal():
		b.portal = [portal_pos.x, portal_pos.y, portal_pos.z]
	return b


## Broken help reads as none yet; a broken portal entry as no portal.
static func _parse_boss(entry: Variant, m: WorldMeta) -> void:
	m.boss_help = BossRules.clean_help(entry)
	if entry is Dictionary and _nums3((entry as Dictionary).get("portal")):
		var p: Array = entry.portal
		m.portal_pos = Vector3(float(p[0]), float(p[1]), float(p[2]))

# --- M2 Task 18: creature minds ------------------------------------------------------------------

## A pet's or friend's saved mind (Mind.to_save) goes along when it is a dictionary of at most 2 KB;
## its contents are checked where it is loaded (Mind.load_save, BotStyle.from_save).
static func _keep_mind(entry: Dictionary, out: Dictionary) -> void:
	var mind: Variant = entry.get("mind")
	if mind is Dictionary and JSON.stringify(mind).length() <= 2048:
		out.mind = mind

# --- M3 Task 5: the universe ladder ---------------------------------------------------------------

func _m3_task5_json(d: Dictionary) -> void:
	d.universe = universe
	d.portals = portals


## A broken universe reads as Green Meadows (1); a huge one as the last the scale knows.
static func _parse_m3_task5(d: Dictionary, m: WorldMeta) -> void:
	var u: Variant = d.get("universe")
	m.universe = UniverseRules.valid(int(clampf(float(u), -1.0, UniverseRules.MAX_UNIVERSE))) if _num(u) else 1
	m.portals = PortalLinks.from_save(d.get("portals")).to_save()

# --- M4 H: co-op games ------------------------------------------------------------------------------

## A broken or negative best reads as none yet.
static func _parse_m4h(d: Dictionary, m: WorldMeta) -> void:
	var best: Variant = d.get("storm_best")
	m.storm_best = int(clampf(float(best), 0.0, 999999.0)) if _num(best) else 0

# --- Survivor games and crafting (spec §12.18) ---------------------------------------------------------------

func _survivor_games_json(d: Dictionary) -> void:
	d.game = String(game)
	d.game_scores = game_scores
	d.arena = arena


## An unknown game reads as CLASSIC; broken scores as none (GameScores.clean_all).
static func _parse_survivor_games(d: Dictionary, m: WorldMeta) -> void:
	var g: Variant = d.get("game")
	m.game = SurvivorGames.valid(StringName(g)) if g is String else SurvivorGames.CLASSIC
	m.game_scores = GameScores.clean_all(d.get("game_scores"))
	m.arena = ArenaRules.clean_all(d.get("arena"))

# --- Owner feedback #39: universe portals ---------------------------------------------------------------------

## Broken gates read as none; an arrival from a universe without a crystal as none.
static func _parse_owner39(d: Dictionary, m: WorldMeta) -> void:
	m.gates = PortalGates.from_save(d.get("gates")).to_save()
	var a: Variant = d.get("arrival_gate", 0)
	m.arrival_gate = int(a) if _num(a) and CrystalRules.CORES.has(int(a)) else 0


# --- Owner #45b: a bigger world ---------------------------------------------------------------------------

## A world saved without a terrain version (or with nonsense) is the old meadows; the found places keep their
## valid ids (letters, digits, "_" and "-"), each once, at most MAX_PLACES_FOUND.
static func _parse_own45b(d: Dictionary, m: WorldMeta) -> void:
	var t: Variant = d.get("terrain")
	m.terrain = int(t) if typeof(t) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(t)) and float(t) == floorf(float(t)) \
		and float(t) >= 1.0 and float(t) <= TERRAIN_LATEST else 1
	m.places_found = clean_places(d.get("places_found"))


static func clean_places(v: Variant) -> Array[String]:
	var out: Array[String] = []
	if not v is Array:
		return out
	for e: Variant in v:
		if e is String and MeadowsPlaces.is_place_id(e) and not out.has(e) and out.size() < MAX_PLACES_FOUND:
			out.append(e)
	return out

# --- M3 Task 20b: buddy magic ----------------------------------------------------------------------------------

## A saved buddy's or pet's tricks (TrickRules: known emotes) and a pet's variant (a befriended monster's kind), kept
## only when clean.
static func _t20b_keep(e: Dictionary, out: Dictionary) -> void:
	var tricks := TrickRules.clean(e.get("tricks"))
	if not tricks.is_empty():
		out.tricks = tricks
	var variant := StringName(str(e.get("variant", "")))
	if variant != &"" and (BefriendRules.is_befriendable_kind(variant) or MiniRules.gives_mini(variant)):
		out.variant = String(variant)


# --- Owner #37: trading (market day) ------------------------------------------------------------------------

## The world's days, counted by the host at every sunrise, for market day (MarketRules): {"day": n}, from 1.
var market: Dictionary = {"day": 1}

# --- M3 Task 15: the tutorial's playground ------------------------------------------------------------------

## The cells "Pip's playground" changed, [x, y, z, what it held, what it put there] (TutorialProps), written the
## moment the course goes in and emptied when it goes: after a crash the next load puts every cell back.
var tutorial_props: Array = []

# --- Owner #55: space (spec §21) -------------------------------------------------------------------------------

## A space world's home: the ladder world its trip started from (SpaceRules.home_for; 1 for every other world).
var space_home := 1
## A ladder world a child took off from into space: [x, z] of the column they left from (coming home lands there);
## [] otherwise.
var space_return: Array = []


## A home that is not a ladder world reads as Green Meadows; a broken column as none.
static func _parse_space(d: Dictionary, m: WorldMeta) -> void:
	var h: Variant = d.get("space_home")
	m.space_home = int(h) if _num(h) and SpaceRules.is_home(int(h)) else 1
	m.space_return = SpaceRules.clean_column(d.get("space_return"))
