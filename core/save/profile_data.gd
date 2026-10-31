class_name ProfileData
extends RefCounted
## The player's profile. from_json never fails: missing or broken data falls back to defaults.

const VERSION := 1
const DEFAULT_SETTINGS := {"graphics": "medium", "view_distance": 128, "volume": 0.8, "show_fps": false, "max_jumps": JumpCounter.MAX_JUMPS,
	"style": "blocky",
	# M2 Task 11 (§12.10): music volume (on top of volume), phone buzz and screen shake, and Reduce motion
	# (no shake or camera bob, softer flashes)
	"music_volume": 0.6, "vibration": true, "reduce_motion": false,
	# The audio pass (owner feedback #27, #31): the SOUND EFFECTS volume (Audio's Effects bus), the MUSIC
	# style (MusicPlan: game / classical / mix) and Song names (the "Now playing" toast)
	"sfx_volume": 0.8, "music_style": "mix", "song_names": true,
	# M3 Task 10: the opt-in "Your farm is full!" note (off; for an under-13 child a grown-up turns it on)
	"farm_note": false,
	# M3 Task 21c: block music (every placed block sings a note of the pentatonic scale; off: the plain pop)
	"build_notes": true,
	# M3 Task 21a: Read to me (ReadAloud), Simple controls (SimpleControls) and whether the first-launch card was
	# shown (owner #52: English only, so no LANGUAGE setting)
	# Owner #133 ("no one will start reading in the game"): Read to me is on for everyone; "voice_first" marks a profile
	# saved since (one saved before had the old off by default, never by choice: it is turned on once on loading)
	"read_to_me": true, "voice_first": true, "simple_controls": false, "simple_asked": false,
	# M5 Task 1 (spec §15.1a): BUTTON SIZE (HudLayout.STEPS), the left hand's mirror, TEXT SIZE (TextSize.STEPS) and
	# Sound captions (on: phones are often muted)
	"button_size": "normal", "left_handed": false, "text_size": "normal", "captions": true,
	# M7 (InstallOffer): the menu's "Add EasyCraft to this device" card: how many NOT NOWs, and when it was last answered
	# (unix seconds; 0 = never)
	"install_not_now": 0, "install_asked_at": 0,
	# Owner #84: the PC's KEYS card was shown (once, at the first world; F1 opens it again)
	"keys_seen": false,
	# Owner #90: the CONTROLLER card was shown (once, the first time a game controller plays in a world) and how fast the
	# right stick looks (GamepadRules.LOOK_SPEEDS: slow / normal / fast; SETTINGS → HELP)
	"pad_seen": false, "pad_look": "normal",
	# Owner #101 (VR on the Meta Quest): the headset's comfort (VrRules' keys and the plan's defaults: snap 45, a light
	# vignette, walking where the head looks, teleport, the avatar's eye height, a break card after 30 minutes) and its
	# own TEXT SIZE, BIG first (VrComfortPage, TextSize.VR_KEY). This device's only (ProfileBackup).
	VrRules.TURN: VrRules.TURN_DEFAULT, VrRules.VIGNETTE: VrRules.VIGNETTE_DEFAULT,
	VrRules.WALK_DIR: VrRules.WALK_DIR_DEFAULT, VrRules.TELEPORT: VrRules.TELEPORT_DEFAULT,
	VrRules.HEIGHT: VrRules.HEIGHT_DEFAULT, VrRules.BREAK_MINUTES: VrRules.BREAK_MINUTES_DEFAULT,
	VrRules.SWING: VrRules.SWING_DEFAULT,   # (owner #128: a held sword hits by swinging it)
	"vr_text_size": "big",
	# Owner #132 (W1): discovery crystals while playing (DiscoveryCrystalRules.SETTING); a grown-up's switch (PLAY & PHOTOS)
	"discovery_crystals": true}

const START_GOLD := 25           # a new player's Survivor gold (M2 §12.1)
const MAX_HINTS := 64
const MAX_HINT_NAME := 32

var username := ""
var age_band: StringName = &""
var settings: Dictionary = DEFAULT_SETTINGS.duplicate()
var survivor_gold := START_GOLD  # Survivor mode's gold (Sandbox gold is ∞ and never saved)
var universe_unlocked := 1        # the highest Survivor universe opened (the Golem opens the next)
var codes_redeemed: Array[String] = []   # salted hashes of the secret codes used (M3 Task 13, CodeRules)
## The gold-double bug's leftover (module 0.2.19): gold codes this phone paid by its own check (offline, or the
## server's answer was lost), hash -> gold, until the server says whether it paid them itself (OnlineService). This
## device's alone (ProfileBackup.DEVICE_ONLY_FIELDS).
var codes_unsettled := {}
var avatar := AvatarLook.new()           # the avatar look (M3 Task 9), worn in both styles
var cosmetics: Array[String] = []        # avatar items bought or earned, account-wide (AvatarUnlocks)
## Owner 35 (spec §18): what a grown-up bought (ShopCatalog product ids; Entitlements) and the child's
## wish list (WishList: pack items and products a grown-up could give).
var purchases: Array[String] = []
var wishes: Array[String] = []

var hints_seen: Array[String] = []  # first-time picture hints already shown, by name (M2 Task 3)

## The Secret Book (M2 Task 16), account-wide: kind of secret (String, SecretRules.KINDS) -> how many found.
var secret_book := {}
## The treasure-only things this player has found (LootRules.TREASURE_ONLY): the Secret Book's shelf.
var treasures: Array[int] = []

var theater_switch: StringName = &"auto"   # the Shorts Theater's parent switch (M3 Task 17, TheaterRules)
## M5 store readiness F1: photo mode's SHARE, a grown-up's switch (PhotoRules.may_share: AUTO = on for 13+ only).
var photo_share: StringName = &"auto"
var progress := ProgressData.new()         # levels, the adventure board, badges, presents (M3 Task 12)
## The co-op games' stickers (M4 Wave 3, agent H; GameRules.STICKERS): sticker id -> how many.
var stickers := {}
## The Gold Farm's note (M3 Task 10, FarmNotifyRules): when the last "Your farm is full!" was asked for
## (unix seconds; one still waiting has not rung; 0 = none). At most one a day.
var farm_note_at := 0
## When this profile last changed (unix seconds; Profile.save sets it). The newer of this phone's
## profile and its server backup wins (ProfileBackup, M4 Wave 2 agent F); 0 = never.
var updated_at := 0
## Pip the robot pet (M3 Task 11, PetRules): {} until the tutorial gives him, then {name, collar,
## happiness}. He lives here, not in a world, so he follows the child into every world.
var pip := {}
## Owner 39 (CrystalRules): the highest universe whose crystal was handed into the child's bag, and crystals still
## to hand over as gifts (universes; the Sky Dragon gives a Dragon Crystal).
var crystals_given := 0
var crystal_gifts: Array[int] = []
## Owner 39: the baby dragon the Sky Dragon gives (like Pip: {} until then, then {name, collar, happiness}); it
## lives here and comes into every world.
var baby_dragon := {}
## M3 Task 21b: the books (the Animal Book, the saving list, Secret Book pages rewarded, universes explored for
## the Hub Tree). The Memory Book is not here: it stays on this device (MemoryBook).
var wonder := WonderData.new()
## Owner #68 (spec §22): the School: the grade, a grown-up's lock and each unit's stars and practice (SchoolData).
var school := SchoolData.new()
## Spec §23.2 (owner #74): the Science Lab's Lab Book: each experiment's guess, its runs (a star) and the plants' planting.
var lab := LabData.new()
## Spec §21d (missions): the rocket parts bought for Sandbox rockets and the worlds flown to by a mission (MissionData).
var missions := MissionData.new()
## Spec §26 (prospecting): the quests finished at least once, the deposits found, today's finding gold (ProspectData).
var prospect := ProspectData.new()
## Owner #86 (spec §21f): the planets' aliens met and befriended, the alien buddy, the robots' quiz questions paid and
## the souvenirs owned (CreatureData).
var creatures := CreatureData.new()
## Owner #78 (spec §21e): the inventions made (flight in history's order), the "try it" moments paid and the flying
## machine picked for Survivor (InventionData).
var inventions := InventionData.new()
## M3 Task 20b (buddy magic): the secret buddy shapes found, the Buddy Album, the bosses' mini-buddies and the tricks
## of the profile's own pets (BuddyMagicData).
var buddy_magic := BuddyMagicData.new()
## M3 Task 15: the tutorial with Pip (TutorialData: offered, skipped, the step it goes on from, the reward paid once,
## SETTINGS' replay).
var tutorial := TutorialData.new()
## M5 Task 1: the thumb controls the child moved, per button size ({size: {spot: [x, y]}}; HudLayout.sanitize_moves).
var hud_moves := {}
## Owner #67: when each group of the child's choices last changed (ProfileBackup.GROUPS: group -> unix seconds;
## Profile.save stamps them). When copies of the account's profile merge, the newest choice wins per group.
var stamps := {}
const MAX_STAMP_NAME := 32
## Owner #79 (spec §25.1): today's School answer gold ({"d": day, "g": gold}; EarnRules' daily cap).
var earn_today := {}
## Owner #79 (spec §25.2): the invite program's part (InviteData: a code waiting for the server, the guide, the first
## unit mastered and what the server has heard).
var invite := InviteData.new()
## Owner #83 (spec §25.5): what the Gold Shop opened for good, account-wide (SpendRules ids: "lesson:<unit id>", later
## rocket parts and decorations); never lost when copies merge.
var bought: Array[String] = []
## Owner #83: weapons and tools bought in the Gold Shop, waiting for the next Survivor world (item id -> count;
## SpendRules.unpack_backpack empties it into that world's bag). Stays on this device.
var backpack := {}
## Owner #85: the Daily Mission (DailyData: each day's stars, mission days that never go down, the day's gold paid).
var daily := DailyData.new()
## Owner #81, #85: better together (SocialData: postcards offered once, what friends' servers have not heard yet, the
## presents' things kept for later).
var social := SocialData.new()
## Owner #94 (spec §5.12b): EasyCraft Shorts' hearts and the Shorts already seen (ShortsData).
var shorts := ShortsData.new()
## MAKE MY SHORT (spec §5.12b "As built (My Shorts)"): the Shorts this child made, as small recipes (MyShortsData). On this
## device only: the server backup leaves them out (ProfileBackup.DEVICE_ONLY_FIELDS).
var my_shorts := MyShortsData.new()
## Owner #112 (spec §27): Life: the track, the region, the careful switches, Life units' progress and the Passport's
## stamps (LifeData). In the backup like the School; first-time measurements stay on the device (LifeMeasure).
var life := LifeData.new()
## Owner #116, #117 (spec §27.3): the Tool Book's stamps, each tool's Done it, By myself and Expert (ToolData). In the
## backup like Life.
var tools := ToolData.new()


## M5 Task 3: a new profile on this phone (its first start): the graphics preset the phone's memory and cores
## suggest (GraphicsPreset.for_device: LOW on weak phones). Only here: a saved choice is never changed.
## M7: `low` (PlatformRules.starts_low_graphics: a phone or tablet in a browser) starts on LOW whatever the device says.
static func first_start(ram_bytes: int, cores: int, low: bool = false) -> ProfileData:
	var p := ProfileData.new()
	p.settings.graphics = "low" if low else GraphicsPreset.for_device(ram_bytes, cores)
	return p


static func from_json(text: String) -> ProfileData:
	var p := ProfileData.new()
	var json := JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return p
	var d: Dictionary = json.data
	p.username = str(d.get("username", ""))
	var band := StringName(str(d.get("age_band", "")))
	p.age_band = band if AgeBand.is_valid(band) else &""
	var s: Variant = d.get("settings", {})
	if typeof(s) == TYPE_DICTIONARY:
		for key: String in DEFAULT_SETTINGS:
			if (s as Dictionary).has(key):
				p.settings[key] = _coerce(s[key], DEFAULT_SETTINGS[key])
	p.settings.max_jumps = clampi(int(p.settings.max_jumps), JumpCounter.MIN_JUMPS, JumpCounter.MAX_JUMPS)
	if not GraphicsPreset.STYLES.has(p.settings.style):
		p.settings.style = "blocky"
	p.settings.music_volume = clampf(float(p.settings.music_volume), 0.0, 1.0)
	p.settings.sfx_volume = clampf(float(p.settings.sfx_volume), 0.0, 1.0)
	p.settings.music_style = String(MusicPlan.valid_style(p.settings.music_style))
	if not GamepadRules.LOOK_SPEED_ORDER.has(str(p.settings.pad_look)):
		p.settings.pad_look = "normal"   # owner #90
	p.settings.erase("language")   # owner #52: English only (a profile saved with M3 Task 21a's LANGUAGE drops it)
	if typeof(s) == TYPE_DICTIONARY and not (s as Dictionary).has("voice_first"):
		p.settings.read_to_me = true   # owner #133: saved before the voice was on for everyone: on, once
	_parse_access(d, p)   # M5 Task 1
	p.settings.install_not_now = clampi(int(p.settings.install_not_now), 0, InstallOffer.MAX_NOT_NOW)   # M7
	if int(p.settings.install_asked_at) < 0 or float(p.settings.install_asked_at) >= 1e12:
		p.settings.install_asked_at = 0
	p.survivor_gold = maxi(int(_coerce(d.get("survivor_gold", START_GOLD), START_GOLD)), 0)
	p.universe_unlocked = maxi(int(_coerce(d.get("universe_unlocked", 1), 1)), 1)
	p.codes_redeemed = CodeRules.sanitize_redeemed(d.get("codes_redeemed", []))
	p.codes_unsettled = CodeRules.sanitize_unsettled(d.get("codes_unsettled", {}))

	var hints: Variant = d.get("hints_seen", [])
	if hints is Array:
		for h: Variant in hints:
			if h is String and h != "" and (h as String).length() <= MAX_HINT_NAME and not p.hints_seen.has(h) \
					and p.hints_seen.size() < MAX_HINTS:
				p.hints_seen.append(h)
	_parse_secret_book(d, p)
	p.cosmetics = AvatarUnlocks.sanitize_owned(d.get("cosmetics", []))
	p.purchases = Entitlements.sanitize(d.get("purchases", []))   # Owner 35
	p.wishes = WishList.sanitize(d.get("wishes", []))
	# Owner 43: a saved look keeps the classic default for anything it lacks (a profile from before avatars: all of it)
	p.avatar = AvatarUnlocks.wearable(AvatarLook.from_dict(d.get("avatar", {}), AvatarLook.classic()), p.cosmetics)
	p.theater_switch = TheaterRules.valid_switch(StringName(str(d.get("theater_switch", ""))))
	p.photo_share = PhotoRules.valid_share_switch(StringName(str(d.get("photo_share", ""))))   # M5 F1
	p.progress = ProgressData.from_dict(d.get("progress"))   # M3 Task 12
	_parse_stickers(d.get("stickers"), p)   # M4 H
	p.pip = PetRules.clean_pip(d.get("pip"))   # M3 Task 11
	var note: Variant = d.get("farm_note_at", 0)   # M3 Task 10
	if typeof(note) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(note)) and float(note) > 0.0 and float(note) < 1e12:
		p.farm_note_at = int(note)
	_parse_owner39(d, p)   # owner 39: universe crystals, the Sky Dragon's baby dragon
	p.wonder = WonderData.from_dict(d.get("wonder"))   # M3 Task 21b: the books
	p.buddy_magic = BuddyMagicData.from_dict(d.get("buddy_magic"))   # M3 Task 20b
	p.tutorial = TutorialData.from_dict(d.get("tutorial"))   # M3 Task 15
	p.school = SchoolData.from_dict(d.get("school"))   # owner #68
	p.lab = LabData.from_dict(d.get("lab"))   # spec §23: the Lab Book
	p.missions = MissionData.from_dict(d.get("missions"))   # spec §21d: rocket parts and missions flown
	p.prospect = ProspectData.from_dict(d.get("prospect"))   # spec §26: prospecting
	p.creatures = CreatureData.from_dict(d.get("creatures"))   # spec §21f: aliens, the alien buddy, quizzes, souvenirs
	p.inventions = InventionData.from_dict(d.get("inventions"))   # owner #78: invent it
	var at: Variant = d.get("updated_at", 0)
	if typeof(at) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(at)) and float(at) > 0.0 and float(at) < 1e15:
		p.updated_at = int(at)
	p.stamps = _parse_stamps(d.get("stamps"))   # owner #67
	p.earn_today = EarnRules.clean_today(d.get("earn_today"))   # owner #79
	p.invite = InviteData.from_dict(d.get("invite"))   # owner #79
	p.bought = SpendRules.clean_bought(d.get("bought"))   # owner #83
	p.backpack = SpendRules.clean_backpack(d.get("backpack"))   # owner #83
	p.daily = DailyData.from_dict(d.get("daily"))   # owner #85
	p.social = SocialData.from_dict(d.get("social"))   # owner #81, #85
	p.shorts = ShortsData.from_dict(d.get("shorts"))   # owner #94
	p.my_shorts = MyShortsData.from_dict(d.get("my_shorts"))   # MAKE MY SHORT (this device only)
	p.life = LifeData.from_dict(d.get("life"))   # owner #112: Life
	p.tools = ToolData.from_dict(d.get("tools"))   # owner #116, #117: the Tool Book
	if not d.has("stamps") and p.updated_at > 0:
		for group: String in ProfileBackup.GROUPS:   # a profile from before owner #67: every choice as old as the profile
			p.stamps[group] = p.updated_at
	return p


## Owner #67: short names with a unix time in seconds (after 0, before the year 33658).
static func _parse_stamps(v: Variant) -> Dictionary:
	var out := {}
	if not v is Dictionary:
		return out
	for k: Variant in v:
		var t: Variant = v[k]
		if k is String and (k as String).length() <= MAX_STAMP_NAME and typeof(t) in [TYPE_INT, TYPE_FLOAT] \
				and is_finite(float(t)) and float(t) > 0.0 and float(t) < 1e12:
			out[k] = int(t)
	return out


## The Secret Book (M2 Task 16): known kinds with a finite count above 0, and known treasure, once each.
static func _parse_secret_book(d: Dictionary, p: ProfileData) -> void:
	var book: Variant = d.get("secret_book")
	if book is Dictionary:
		for kind: Variant in book:
			var n: Variant = book[kind]
			if SecretRules.is_kind(StringName(str(kind))) and typeof(n) in [TYPE_INT, TYPE_FLOAT] \
					and is_finite(float(n)) and float(n) >= 1.0:
				p.secret_book[str(kind)] = mini(int(n), 999999)
	var shelf: Variant = d.get("treasures")
	if shelf is Array:
		for id: Variant in shelf:
			if typeof(id) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(id)):
				p.add_treasure(int(id))


## Counts one more secret of `kind` found; returns the new count (0 for an unknown kind).
func record_secret(kind: StringName) -> int:
	if not SecretRules.is_kind(kind):   # owner 42: the treasure pack's kinds too
		return 0
	var n := mini(int(secret_book.get(String(kind), 0)) + 1, 999999)
	secret_book[String(kind)] = n
	return n


## Puts a treasure-only thing on the Secret Book's shelf; true the first time.
func add_treasure(id: int) -> bool:
	if not LootRules.TREASURE_ONLY.has(id) or treasures.has(id):
		return false
	treasures.append(id)
	return true


static func _coerce(value: Variant, default: Variant) -> Variant:
	match typeof(default):
		TYPE_INT:
			return int(value) if typeof(value) in [TYPE_INT, TYPE_FLOAT] else default
		TYPE_FLOAT:
			return float(value) if typeof(value) in [TYPE_INT, TYPE_FLOAT] else default
		TYPE_BOOL:
			return value if typeof(value) == TYPE_BOOL else default
		_:
			return str(value)


func to_json() -> String:
	var d := {"version": VERSION, "username": username, "age_band": String(age_band), "settings": settings,
		"codes_redeemed": codes_redeemed, "codes_unsettled": codes_unsettled,
		"avatar": avatar.to_dict(), "cosmetics": cosmetics, "purchases": purchases, "wishes": wishes,
		"theater_switch": String(theater_switch), "photo_share": String(photo_share),
		"survivor_gold": survivor_gold, "universe_unlocked": universe_unlocked, "hints_seen": hints_seen,
		"secret_book": secret_book, "treasures": treasures, "stickers": stickers, "updated_at": updated_at,
		"progress": progress.to_dict(), "pip": pip, "farm_note_at": farm_note_at}
	_owner39_json(d)
	d.wonder = wonder.to_dict()   # M3 Task 21b
	d.school = school.to_dict()   # owner #68
	d.lab = lab.to_dict()   # spec §23: the Lab Book
	d.missions = missions.to_dict()   # spec §21d
	d.prospect = prospect.to_dict()   # spec §26
	d.creatures = creatures.to_dict()   # spec §21f
	d.inventions = inventions.to_dict()   # owner #78
	d.buddy_magic = buddy_magic.to_dict()   # M3 Task 20b
	d.tutorial = tutorial.to_dict()   # M3 Task 15
	d.hud_moves = hud_moves   # M5 Task 1
	d.stamps = stamps   # owner #67
	d.earn_today = earn_today   # owner #79
	d.invite = invite.to_dict()   # owner #79
	d.bought = bought   # owner #83
	d.backpack = backpack   # owner #83
	d.daily = daily.to_dict()   # owner #85
	d.social = social.to_dict()   # owner #81, #85
	d.shorts = shorts.to_dict()   # owner #94
	d.my_shorts = my_shorts.to_dict()   # MAKE MY SHORT (this device only: ProfileBackup leaves it out)
	d.life = life.to_dict()   # owner #112: Life
	d.tools = tools.to_dict()   # owner #116, #117: the Tool Book
	return JSON.stringify(d, "\t")


# --- M4 H: the co-op games' stickers ---

## One more sticker of the game `kind` (everyone who played gets one); the new count, 0 for no such game.
func add_sticker(kind: StringName) -> int:
	if not GameRules.STICKERS.has(String(kind)):
		return 0
	var n := mini(int(stickers.get(String(kind), 0)) + 1, GameRules.MAX_STICKERS)
	stickers[String(kind)] = n
	return n


## Known stickers with a whole, finite count of at least 1.
static func _parse_stickers(v: Variant, p: ProfileData) -> void:
	if not v is Dictionary:
		return
	for kind: Variant in v:
		var n: Variant = v[kind]
		if GameRules.STICKERS.has(str(kind)) and typeof(n) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(n)) \
				and float(n) >= 1.0:
			p.stickers[str(kind)] = mini(int(n), GameRules.MAX_STICKERS)


func is_onboarded() -> bool:
	return UsernameRules.validate(username) == "" and AgeBand.is_valid(age_band)

# --- Owner feedback #39: universe crystals and the baby dragon ----------------------------------------------

func _owner39_json(d: Dictionary) -> void:
	d.crystals_given = crystals_given
	d.crystal_gifts = crystal_gifts
	d.baby_dragon = baby_dragon


## A broken count reads as none given (the crystals come again: nothing is lost); gifts and the dragon are cleaned.
static func _parse_owner39(d: Dictionary, p: ProfileData) -> void:
	var given: Variant = d.get("crystals_given", 0)
	if typeof(given) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(given)):
		p.crystals_given = clampi(int(given), 0, UniverseRules.MAX_UNIVERSE)
	p.crystal_gifts = CrystalRules.clean_gifts(d.get("crystal_gifts"))
	p.baby_dragon = PetRules.clean_pip(d.get("baby_dragon"))


# --- M5 Task 1: the accessibility settings (spec §15.1a) ---

## Known button and text sizes only; the moves cleaned (HudLayout).
static func _parse_access(d: Dictionary, p: ProfileData) -> void:
	if not HudLayout.FACTORS.has(StringName(str(p.settings.button_size))):
		p.settings.button_size = "normal"
	if not TextSize.FACTORS.has(StringName(str(p.settings.text_size))):
		p.settings.text_size = "normal"
	p.hud_moves = HudLayout.sanitize_moves(d.get("hud_moves"))
	for key: String in VrComfortPage.ROWS_KEYS:   # owner #101: known VR choices only
		p.settings[key] = VrComfortPage.value_of(p.settings, key)
