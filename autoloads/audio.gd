extends Node
## Short sound effects from small player pools. play(&"place", pos) plays in 3D at pos;
## without a position it plays as a flat UI sound. Each play gets a small random pitch.
## The audio pass (owner feedback #27, docs/devlog/parts/audio-pass.md):
## - Every effect plays on the "Effects" bus (under Master), whose volume is the SOUND EFFECTS setting
##   (settings.sfx_volume); the music has its own bus (Music).
## - The pools never grow: a sound takes a free player of its pool, else the oldest one. The same sound
##   more than BURST times within BURST_TIME is dropped (ten slimes squishing at once are one squish), and
##   a world sound beyond HEARING of the listener is not played at all.
## - Every UI button (BaseButton) clicks by itself: a click for buttons, a softer one for toggles
##   (UiSoundRules). A button can set meta "ui_sound" to its own sound, or &"" for none. TouchButtons
##   (the HUD) call touch().
## - Local feedback: gold going up clinks, and Survivor blocks coming into the bag pop (host and solo).

const SFX := "res://assets/audio/sfx/"
const BUS := &"Effects"
const SOUNDS := {
	&"place": [SFX + "place_1.ogg", SFX + "place_2.ogg", SFX + "place_3.ogg"],
	&"break": [SFX + "break_1.ogg", SFX + "break_2.ogg", SFX + "break_3.ogg"],
	&"jump": [SFX + "jump.ogg"],
	&"air_jump": [SFX + "air_jump.ogg"],
	&"step": [SFX + "step_1.ogg", SFX + "step_2.ogg", SFX + "step_3.ogg", SFX + "step_4.ogg", SFX + "step_5.ogg"],
	&"ui_click": [SFX + "ui_click.ogg"],
	&"undo": [SFX + "undo.ogg"],
	# The audio pass (Kenney, CC0; tools/make_audio_pass_sfx.py): footsteps by block (FootstepRules), the
	# softer toggle click, the hotbar tick, the pickup pop, the gold clink, the jingles and the wave horn
	&"step_dirt": [SFX + "step_dirt_1.ogg", SFX + "step_dirt_2.ogg", SFX + "step_dirt_3.ogg", SFX + "step_dirt_4.ogg", SFX + "step_dirt_5.ogg"],
	&"step_stone": [SFX + "step_stone_1.ogg", SFX + "step_stone_2.ogg", SFX + "step_stone_3.ogg", SFX + "step_stone_4.ogg", SFX + "step_stone_5.ogg"],
	&"step_wood": [SFX + "step_wood_1.ogg", SFX + "step_wood_2.ogg", SFX + "step_wood_3.ogg", SFX + "step_wood_4.ogg", SFX + "step_wood_5.ogg"],
	&"step_snow": [SFX + "step_snow_1.ogg", SFX + "step_snow_2.ogg", SFX + "step_snow_3.ogg", SFX + "step_snow_4.ogg", SFX + "step_snow_5.ogg"],
	&"step_cloth": [SFX + "step_cloth_1.ogg", SFX + "step_cloth_2.ogg", SFX + "step_cloth_3.ogg", SFX + "step_cloth_4.ogg", SFX + "step_cloth_5.ogg"],
	&"step_sand": [SFX + "step_sand_1.ogg", SFX + "step_sand_2.ogg", SFX + "step_sand_3.ogg", SFX + "step_sand_4.ogg"],
	&"step_leaves": [SFX + "step_leaves_1.ogg", SFX + "step_leaves_2.ogg", SFX + "step_leaves_3.ogg", SFX + "step_leaves_4.ogg"],
	&"step_glass": [SFX + "step_glass_1.ogg", SFX + "step_glass_2.ogg", SFX + "step_glass_3.ogg"],
	&"ui_toggle": [SFX + "ui_toggle.ogg"],
	&"ui_tick": [SFX + "ui_tick.ogg"],
	&"pickup": [SFX + "pickup_pop.ogg"],
	&"gold": [SFX + "gold_clink.ogg"],
	&"jingle_level": [SFX + "jingle_level.ogg"],
	&"jingle_goal": [SFX + "jingle_goal.ogg"],
	&"jingle_badge": [SFX + "jingle_badge.ogg"],
	&"horn": [SFX + "wave_horn.ogg"],
	# Animal voices (the audio pass): real CC0 recordings, tools/make_audio_pass_sfx.py `animals`
	&"bark": [SFX + "dog_1.ogg", SFX + "dog_2.ogg", SFX + "dog_3.ogg"],
	&"meow": [SFX + "cat_1.ogg", SFX + "cat_2.ogg", SFX + "cat_3.ogg"],
	&"oink": [SFX + "pig_1.ogg", SFX + "pig_2.ogg", SFX + "pig_3.ogg"],
	&"moo": [SFX + "cow_1.ogg", SFX + "cow_2.ogg", SFX + "cow_3.ogg"],
	&"baa": [SFX + "sheep_1.ogg", SFX + "sheep_2.ogg", SFX + "sheep_3.ogg"],
	&"cluck": [SFX + "chicken_1.ogg", SFX + "chicken_2.ogg", SFX + "chicken_3.ogg"],
	&"squeak": [SFX + "rabbit_1.ogg", SFX + "rabbit_2.ogg", SFX + "rabbit_3.ogg"],
	&"blub": [SFX + "animal_blub.wav", SFX + "fish_splash_1.ogg", SFX + "fish_splash_2.ogg"],
	&"dog_happy": [SFX + "dog_happy_1.ogg", SFX + "dog_happy_2.ogg"],
	&"purr": [SFX + "cat_purr_1.ogg", SFX + "cat_purr_2.ogg"],
	&"dog_hurt": [SFX + "dog_hurt_1.ogg", SFX + "dog_hurt_2.ogg"],
	&"cat_hurt": [SFX + "cat_hurt_1.ogg"],
	&"pig_hurt": [SFX + "pig_hurt_1.ogg"],
	&"cow_hurt": [SFX + "cow_hurt_1.ogg"],
	&"sheep_hurt": [SFX + "sheep_hurt_1.ogg"],
	&"chicken_hurt": [SFX + "chicken_hurt_1.ogg"],
	&"rabbit_hurt": [SFX + "rabbit_hurt_1.ogg", SFX + "rabbit_hurt_2.ogg"],
	# M3 Task 11's pets: the fox's and the parrot's real voices (owner #41's animals pack); Pip beeps
	&"yip": [SFX + "fox_1.ogg", SFX + "fox_2.ogg", SFX + "fox_3.ogg"],
	&"squawk": [SFX + "parrot_1.ogg", SFX + "parrot_2.ogg", SFX + "parrot_3.ogg"],
	&"beep": [SFX + "ding.wav"],
	&"fox_hurt": [SFX + "fox_hurt_1.ogg"],
	&"parrot_hurt": [SFX + "parrot_hurt_1.ogg"],
	# Owner #41: the new animals' voices, real CC0 recordings (tools/make_audio_pass_sfx.py `pack`)
	&"neigh": [SFX + "horse_1.ogg", SFX + "horse_2.ogg", SFX + "horse_3.ogg"],
	&"horse_hurt": [SFX + "horse_hurt_1.ogg", SFX + "horse_hurt_2.ogg"],
	&"horse_happy": [SFX + "horse_happy_1.ogg", SFX + "horse_happy_2.ogg"],
	&"bray": [SFX + "donkey_1.ogg", SFX + "donkey_2.ogg"],
	&"donkey_hurt": [SFX + "donkey_hurt_1.ogg"],
	&"bleat": [SFX + "goat_1.ogg", SFX + "goat_2.ogg", SFX + "goat_3.ogg"],
	&"goat_hurt": [SFX + "goat_hurt_1.ogg", SFX + "goat_hurt_2.ogg"],
	&"deer_call": [SFX + "deer_1.ogg", SFX + "deer_2.ogg", SFX + "deer_3.ogg"],
	&"deer_hurt": [SFX + "deer_hurt_1.ogg"],
	&"quack": [SFX + "duck_1.ogg", SFX + "duck_2.ogg", SFX + "duck_3.ogg"],
	&"duck_hurt": [SFX + "duck_hurt_1.ogg"],
	&"croak": [SFX + "frog_1.ogg", SFX + "frog_2.ogg", SFX + "frog_3.ogg"],
	&"frog_hurt": [SFX + "frog_hurt_1.ogg", SFX + "frog_hurt_2.ogg"],
	&"turtle": [SFX + "turtle_1.ogg", SFX + "turtle_2.ogg"],
	&"turtle_hurt": [SFX + "turtle_hurt_1.ogg"],
	&"chatter": [SFX + "squirrel_1.ogg", SFX + "squirrel_2.ogg", SFX + "squirrel_3.ogg"],
	&"squirrel_hurt": [SFX + "squirrel_hurt_1.ogg", SFX + "squirrel_hurt_2.ogg"],
	&"hoot": [SFX + "owl_1.ogg", SFX + "owl_2.ogg", SFX + "owl_3.ogg"],
	&"owl_hurt": [SFX + "owl_hurt_1.ogg"],
	&"snuffle": [SFX + "hedgehog_1.ogg", SFX + "hedgehog_2.ogg"],
	&"hedgehog_hurt": [SFX + "hedgehog_hurt_1.ogg"],
	&"camel_grunt": [SFX + "camel_1.ogg", SFX + "camel_2.ogg"],
	&"camel_hurt": [SFX + "camel_hurt_1.ogg"],
	&"gecko": [SFX + "lizard_1.ogg", SFX + "lizard_2.ogg"],
	&"lizard_hurt": [SFX + "lizard_hurt_1.ogg"],
	&"fennec": [SFX + "fennec_1.ogg", SFX + "fennec_2.ogg", SFX + "fennec_3.ogg"],
	&"fennec_hurt": [SFX + "fennec_hurt_1.ogg"],
	&"penguin": [SFX + "penguin_1.ogg", SFX + "penguin_2.ogg"],
	&"penguin_hurt": [SFX + "penguin_hurt_1.ogg"],
	&"bear_huff": [SFX + "polar_bear_1.ogg", SFX + "polar_bear_2.ogg"],
	&"bear_hurt": [SFX + "polar_bear_hurt_1.ogg"],
	&"arctic_yip": [SFX + "arctic_fox_1.ogg", SFX + "arctic_fox_2.ogg", SFX + "arctic_fox_3.ogg"],
	&"arctic_fox_hurt": [SFX + "arctic_fox_hurt_1.ogg"],
	&"seal_bark": [SFX + "seal_1.ogg", SFX + "seal_2.ogg", SFX + "seal_3.ogg"],
	&"seal_hurt": [SFX + "seal_hurt_1.ogg"],
	&"gummy_squeak": [SFX + "gummy_bunny_1.ogg", SFX + "gummy_bunny_2.ogg", SFX + "gummy_bunny_3.ogg"],
	&"gummy_bunny_hurt": [SFX + "gummy_bunny_hurt_1.ogg"],
	&"chirp": [SFX + "candy_bird_1.ogg", SFX + "candy_bird_2.ogg", SFX + "candy_bird_3.ogg"],
	&"candy_bird_hurt": [SFX + "candy_bird_hurt_1.ogg"],
	# Weapons (M1b Task 11): original procedural sounds from tools/make_weapon_sfx.py
	&"swing": [SFX + "swing_1.wav", SFX + "swing_2.wav"],
	&"bow": [SFX + "bow.wav"],
	&"hit": [SFX + "hit_1.wav", SFX + "hit_2.wav"],
	&"thud": [SFX + "thud.wav"],
	&"smash": [SFX + "smash.wav"],
	&"whirr": [SFX + "whirr.wav"],
	&"ding": [SFX + "ding.wav"],
	# Water (M2 Task 14): original procedural sounds from tools/make_water_sfx.py
	&"splash": [SFX + "splash_big.wav"],
	&"splash_small": [SFX + "splash_small.wav"],
	&"swim": [SFX + "swim_1.wav", SFX + "swim_2.wav"],
	&"bubbles": [SFX + "bubbles.wav"],
	&"step_wet": [SFX + "step_wet_1.wav", SFX + "step_wet_2.wav"],

	# Photo mode (M3 Task 16): tools/make_photo_sfx.py
	&"shutter": [SFX + "shutter.wav"],

	# Monsters (M2 Task 4): original procedural sounds from tools/make_monster_sounds.py
	&"squish": [SFX + "monster_squish.wav"],
	&"growl": [SFX + "monster_growl.wav"],
	&"pop": [SFX + "monster_pop.wav"],
	&"poof": [SFX + "monster_poof.wav"],
	# Monster voices (the audio pass): tools/make_audio_pass_sfx.py `monsters` (original work)
	&"grunt": [SFX + "goblin_grunt_1.ogg", SFX + "goblin_grunt_2.ogg", SFX + "goblin_grunt_3.ogg"],
	&"goblin_hurt": [SFX + "goblin_hurt.ogg"],
	&"slime_hurt": [SFX + "slime_hurt.ogg"],
	&"mummy_hurt": [SFX + "mummy_hurt.ogg"],
	&"scorpion_click": [SFX + "scorpion_click.ogg"],
	&"scorpion_hurt": [SFX + "scorpion_hurt.ogg"],

	# Coin pickups (M2 Task 11): tools/make_feel_sfx.py
	&"coin": [SFX + "coin.wav"],

	# Secrets and treasures (M2 Task 16): original procedural sounds from tools/make_secret_sfx.py
	&"sparkle": [SFX + "sparkle.wav"],
	&"chime": [SFX + "chime.wav"],
	&"knock": [SFX + "knock.wav"],
	&"chest_open": [SFX + "chest_open.wav"],
	&"star_fall": [SFX + "star_fall.wav"],
	&"star_land": [SFX + "star_land.wav"],
	&"plate_click": [SFX + "plate_click.wav"],
	&"plate_wrong": [SFX + "plate_wrong.wav"],
	# Physics Lab pads (M3 Task 6): tools/make_pad_sfx.py
	&"boing": [SFX + "boing.wav"],
	&"whoosh": [SFX + "whoosh.wav"],
	# The Stone Golem (M2 Task 10): tools/make_boss_sounds.py (portal_wind.wav loops in the portal itself)
	&"golem_roar": [SFX + "golem_roar.wav"],
	&"golem_slam": [SFX + "golem_slam.wav"],
	&"golem_throw": [SFX + "golem_throw.wav"],
	&"golem_stomp": [SFX + "golem_stomp.wav"],
	&"rock_crash": [SFX + "rock_crash.wav"],
	&"golem_crumble": [SFX + "golem_crumble.wav"],
	# Defenses (M2 Task 8): tools/make_defense_sfx.py
	&"door_open": [SFX + "door_open.wav"],
	&"door_close": [SFX + "door_close.wav"],
	&"spikes": [SFX + "spikes.wav"],
	# The Sandstorm Desert (M3 Task 2): original procedural sounds from tools/make_desert_sounds.py
	&"moan": [SFX + "mummy_moan.wav"],
	&"hiss": [SFX + "scorpion_hiss.wav"],
	&"spit": [SFX + "spit.wav"],
	&"splat": [SFX + "splat.wav"],
	&"serpent_roar": [SFX + "serpent_roar.wav"],
	&"serpent_burst": [SFX + "serpent_burst.wav"],
	&"serpent_rumble": [SFX + "serpent_rumble.wav"],
	&"dart": [SFX + "dart.wav"],
	&"trap_click": [SFX + "trap_click.wav"],
	# Frostpeak (M3 Task 3): original procedural sounds from tools/make_frost_sounds.py
	&"yeti_roar": [SFX + "yeti_roar.wav"],
	&"screech": [SFX + "bat_screech.wav"],
	&"snow_throw": [SFX + "snow_throw.wav"],
	&"snow_splat": [SFX + "snow_splat.wav"],
	&"giant_roar": [SFX + "giant_roar.wav"],
	&"giant_stomp": [SFX + "giant_stomp.wav"],
	&"giant_breath": [SFX + "giant_breath.wav"],
	&"ice_crackle": [SFX + "ice_crackle.wav"],
	# Portals (M3 Task 5): tools/make_portal_sfx.py
	&"portal_whoosh": [SFX + "portal_whoosh.wav"],
	&"dragon_chirp": [SFX + "dragon_chirp_1.wav", SFX + "dragon_chirp_2.wav"],   # owner 39: the pet dragon
	&"egg_crack": [SFX + "egg_crack.wav"],                                # owner 39: a dragon egg hatching
	# The Candy Kingdom (M3 Task 4): original procedural sounds from tools/make_candy_sounds.py
	&"gummy": [SFX + "gummy_squeak.wav"],
	&"jingle": [SFX + "sneaker_jingle.wav"],
	&"cake_roar": [SFX + "cake_roar.wav"],
	&"cake_slam": [SFX + "cake_slam.wav"],
	&"cake_throw": [SFX + "cake_throw.wav"],
	&"cherry_splat": [SFX + "cherry_splat.wav"],
	&"layer_pop": [SFX + "layer_pop.wav"],
	&"fanfare": [SFX + "fanfare.wav"],
	# Owner 39, the Sky Dragon: original procedural sounds from tools/make_sky_dragon_sounds.py
	&"sky_dragon_roar": [SFX + "sky_dragon_roar.wav"],
	&"sky_dragon_wings": [SFX + "sky_dragon_wings.wav"],
	&"sky_dragon_dive": [SFX + "sky_dragon_dive.wav"],
	&"sky_crystal_hum": [SFX + "sky_crystal_hum.wav"],
	&"sky_crystal_shatter": [SFX + "sky_crystal_shatter.wav"],
	# The Dragon Realm's monsters (owner #39): original procedural sounds from tools/make_dragon_monster_sounds.py
	&"shadow_squeak": [SFX + "shadow_squeak.wav"],
	&"shadow_flutter": [SFX + "shadow_flutter.wav"],
	&"shadow_hurt": [SFX + "shadow_hurt.wav"],
	&"wisp_chime": [SFX + "wisp_chime.wav"],
	&"wisp_charge": [SFX + "wisp_charge.wav"],
	&"wisp_hum": [SFX + "wisp_hum.wav"],
	&"wisp_hurt": [SFX + "wisp_hurt.wav"],
	&"spark_pop": [SFX + "spark_pop.wav"],
	# Universe 6, the Glow Caves: original procedural sounds from tools/make_glow_sounds.py
	&"spore_puff": [SFX + "spore_puff.wav"],
	&"spore_swell": [SFX + "spore_swell.wav"],
	&"spore_hurt": [SFX + "spore_hurt.wav"],
	&"crawler_click": [SFX + "crawler_click.wav"],
	&"crawler_chitter": [SFX + "crawler_chitter.wav"],
	&"crawler_hurt": [SFX + "crawler_hurt.wav"],
	&"mother_hum": [SFX + "mother_hum.wav"],
	&"mother_spores": [SFX + "mother_spores.wav"],
	&"mother_puff": [SFX + "mother_puff.wav"],
	&"mother_ring": [SFX + "mother_ring.wav"],
	&"echo_click": [SFX + "echo_click.wav"],
	&"drip_plink": [SFX + "drip_plink.wav"],
	&"fizz": [SFX + "fizz.wav"],
	# The action kit (M3 Task 14b): original procedural sounds from tools/make_blaster_sfx.py
	&"foam_pop": [SFX + "foam_pop.wav"],
	&"paint_shot": [SFX + "paint_shot.wav"],
	&"bubble_shot": [SFX + "bubble_shot.wav"],
	&"bubble_pop": [SFX + "bubble_pop.wav"],
	&"rocket_whoosh": [SFX + "rocket_whoosh.wav"],
	&"confetti_boom": [SFX + "confetti_boom.wav"],
	&"party_horn": [SFX + "party_horn.wav"],
	&"pinata_burst": [SFX + "pinata_burst.wav"],
	# Owner 42, the treasure pack: original procedural sounds from tools/make_treasure_sfx.py
	&"giggle": [SFX + "giggle.wav"],
	&"coin_toss": [SFX + "coin_toss.wav"],
	&"rainbow": [SFX + "rainbow.wav"],
	# M3 Task 21c, the wonder pack: original procedural sounds from tools/make_tiny_sfx.py (the building notes play
	# from BuildMelody's own pool)
	&"mouse_squeak": [SFX + "mouse_squeak_1.wav", SFX + "mouse_squeak_2.wav"],
	&"mimic_hop": [SFX + "mimic_hop.wav"],
	# M3 Task 21a: the babble voices' syllables (BabbleVoices; tools/make_babble_sfx.py, original work)
	&"babble": [SFX + "babble_1.wav", SFX + "babble_2.wav", SFX + "babble_3.wav", SFX + "babble_4.wav",
		SFX + "babble_5.wav", SFX + "babble_6.wav", SFX + "babble_7.wav", SFX + "babble_8.wav", SFX + "babble_9.wav",
		SFX + "babble_10.wav", SFX + "babble_11.wav", SFX + "babble_12.wav"],
	# Owner #109, the cars: original procedural sounds from tools/make_car_sfx.py (VehicleSounds; the engine's loops
	# are played by each car itself)
	&"car_horn_small": [SFX + "car_horn_small.wav"],
	&"car_horn": [SFX + "car_horn.wav"],
	&"car_horn_big": [SFX + "car_horn_big.wav"],
	&"car_start": [SFX + "car_start.wav"],
}
const UI_POOL := 6
const MUFFLE_CUTOFF := 900.0   # Hz: under water every sound is muffled (M2 Task 14)
const WORLD_POOL := 12
const BURST := 3               # the same sound at most this many times ...
const BURST_TIME := 0.08       # ... within this many seconds
const HEARING := 40.0          # world sounds farther than this from the listener are not played (max_distance)

## Owner feedback #50: every sound that plays, by name, where (INF = flat) and how loud (the tools that
## count what a player hears: tools/animal_voices_measure.gd; tests).
signal sound_played(sound: StringName, at: Vector3, volume_db: float)

## Sounds played and dropped since the start (tests and diagnostics), and the last one played.
var played := 0
var dropped := 0
var last_sound: StringName = &""
## The pitch the last caller asked for (an animal's own voice), before the small random wobble.
var last_voice_pitch := 1.0
## Owner feedback #50: which take of its sound played last; a sound never plays the same take twice in a
## row (AnimalChorusRules.take).
var last_take := -1
var _last_takes := {}          # sound -> its last take
var _rng := RandomNumberGenerator.new()

var _streams := {}
var _ui: Array[AudioStreamPlayer] = []
var _world: Array[AudioStreamPlayer3D] = []
var _next_ui := 0
var _next_world := 0
var _muffle := AudioEffectLowPassFilter.new()
var _muffle_index := -1
var _recent := {}              # sound -> [msec of its latest plays]
var _flat_frame := {}          # flat sound -> the process frame it last played in
var _gold := -1                # the last gold balance heard (the profile's at start: the first coin clinks too)
var _bag: Inventory            # the bag whose total _bag_total is (a new bag is a new world: no pop)
var _bag_total := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_add_bus()   # M5 Task 3: the sounds' takes load when they first play (_takes), not all here
	for i in UI_POOL:
		var p := AudioStreamPlayer.new()
		p.bus = BUS
		add_child(p)
		_ui.append(p)
	for i in WORLD_POOL:
		var p := AudioStreamPlayer3D.new()
		p.unit_size = 6.0
		p.max_distance = HEARING
		p.bus = BUS
		add_child(p)
		_world.append(p)
	_muffle.cutoff_hz = MUFFLE_CUTOFF
	AudioServer.add_bus_effect(0, _muffle)
	_muffle_index = AudioServer.get_bus_effect_count(0) - 1
	AudioServer.set_bus_effect_enabled(0, _muffle_index, false)
	Game.settings_applied.connect(_apply_volume)
	_apply_volume(Profile.data.settings)
	get_tree().node_added.connect(_on_node_added)
	_gold = Profile.data.survivor_gold
	Session.gold_changed.connect(_on_gold)
	Session.inventory_changed.connect(_on_bag)


## A HUD touch button was pressed (TouchButton): its sound from UiSoundRules.
func touch(symbol: StringName, action: StringName) -> void:
	play(UiSoundRules.touch_sound(symbol, action))


## Every BaseButton that enters the tree clicks when pressed (once, however often it is moved).
func _on_node_added(node: Node) -> void:
	var b := node as BaseButton
	if b and not b.has_meta(&"_clicks"):
		b.set_meta(&"_clicks", true)
		b.pressed.connect(_on_button.bind(b))


func _on_button(b: BaseButton) -> void:
	if is_instance_valid(b):
		play(UiSoundRules.button_sound(b.toggle_mode or b is CheckButton or b is CheckBox,
			b.get_meta(&"ui_sound") if b.has_meta(&"ui_sound") else null))


## Gold going up clinks (every gain: coins, trades, chests, goals); spending is quiet.
func _on_gold(balance: int) -> void:
	if _gold >= 0 and balance > _gold:
		play(&"gold")
	_gold = balance


## Blocks and items coming into this game's bag pop (Survivor gathering). A different bag object is a new
## world's (or a LAN guest's snapshot): no pop, it only sets the count to compare with.
func _on_bag() -> void:
	var bag: Inventory = Session.my_inventory
	var total := 0
	if bag:
		for id: int in bag.ids():
			total += bag.count(id)
	if bag == _bag and total > _bag_total:
		play(&"pickup")
	_bag = bag
	_bag_total = total


## Plays `sound` at `at` (flat, as a UI sound, without it). `pitch_scale`: the caller's own pitch (an
## animal's voice); every play wobbles a little around it.
func play(sound: StringName, at: Vector3 = Vector3.INF, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var list := _takes(sound)
	if list.is_empty():
		return
	if not _burst_ok(sound) or (at.is_finite() and not _audible(at)) or (not at.is_finite() and not _flat_ok(sound)):
		dropped += 1
		return
	last_take = AnimalChorusRules.take(list.size(), int(_last_takes.get(sound, -1)), _rng)   # owner #50: no repeat
	_last_takes[sound] = last_take
	var stream: AudioStream = list[last_take]
	var pitch := randf_range(0.92, 1.08) * clampf(pitch_scale, 0.25, 4.0)
	played += 1
	last_sound = sound
	last_voice_pitch = pitch_scale
	sound_played.emit(sound, at, volume_db)   # owner feedback #50
	if at.is_finite():
		var p: AudioStreamPlayer3D = _world[_pick(_world, _next_world)]
		_next_world = (_world.find(p) + 1) % _world.size()
		p.global_position = at
		p.stream = stream
		p.pitch_scale = pitch
		p.volume_db = volume_db
		p.play()
	else:
		var p: AudioStreamPlayer = _ui[_pick(_ui, _next_ui)]
		_next_ui = (_ui.find(p) + 1) % _ui.size()
		p.stream = stream
		p.pitch_scale = pitch
		p.volume_db = volume_db
		p.play()


## M5 Task 3 (startup): `sound`'s takes, loaded the first time it plays (the loader keeps them). Loading all ~330
## files in _ready took 55-75 ms of the desktop's start, more on a phone reading them out of the APK; one sound's
## takes are a few small files (well under a millisecond here).
func _takes(sound: StringName) -> Array:
	if not _streams.has(sound):
		var list: Array[AudioStream] = []
		for path: String in SOUNDS.get(sound, []):
			list.append(load(path))
		_streams[sound] = list
	return _streams[sound]


## Every player of both pools (tests: the pools never grow).
func player_count() -> int:
	return _ui.size() + _world.size()


## How many sounds are playing now (never more than player_count()).
func playing_count() -> int:
	var n := 0
	for p in _ui:
		n += int(p.playing)
	for p in _world:
		n += int(p.playing)
	return n


## Stops every effect (tests and leaving a world; nothing is left playing at quit).
func stop_all() -> void:
	for p in _ui:
		p.stop()
	for p in _world:
		p.stop()
	_recent.clear()
	_flat_frame.clear()


## A free player from `next` on, else the one at `next` (the oldest in the round).
func _pick(pool: Array, next: int) -> int:
	for i in pool.size():
		var k := (next + i) % pool.size()
		if not pool[k].playing:
			return k
	return next


func _burst_ok(sound: StringName) -> bool:
	var now := Time.get_ticks_msec()
	var times: Array = _recent.get(sound, [])
	while not times.is_empty() and now - int(times[0]) > int(BURST_TIME * 1000.0):
		times.pop_front()
	if times.size() >= BURST:
		return false
	times.append(now)
	_recent[sound] = times
	return true


## A flat (UI) sound plays once a frame: a button that clicks by itself and the automatic click of every
## button are heard as one click.
func _flat_ok(sound: StringName) -> bool:
	var frame := Engine.get_process_frames()
	if int(_flat_frame.get(sound, -1)) == frame:
		return false
	_flat_frame[sound] = frame
	return true


func _audible(at: Vector3) -> bool:
	var cam := get_viewport().get_camera_3d() if is_inside_tree() else null
	return cam == null or cam.global_position.distance_squared_to(at) <= HEARING * HEARING


func _apply_volume(settings: Dictionary) -> void:
	var bus := AudioServer.get_bus_index(BUS)
	var v := clampf(float(settings.get("sfx_volume", 0.8)), 0.0, 1.0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(v, 0.0001)))
	AudioServer.set_bus_mute(bus, v <= 0.0)


func _add_bus() -> void:
	if AudioServer.get_bus_index(BUS) != -1:
		return
	AudioServer.add_bus()
	var i := AudioServer.bus_count - 1
	AudioServer.set_bus_name(i, BUS)
	AudioServer.set_bus_send(i, &"Master")


## Under water every sound is muffled: a low-pass on the Master bus (Ambience turns it on while the
## camera is in the water).
func set_muffled(on: bool) -> void:
	AudioServer.set_bus_effect_enabled(0, _muffle_index, on)


func is_muffled() -> bool:
	return AudioServer.is_bus_effect_enabled(0, _muffle_index)


## The muffle's place among the Master bus effects.
func muffle_index() -> int:
	return _muffle_index
