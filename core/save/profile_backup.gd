class_name ProfileBackup
extends RefCounted
## The account's profile on the game server (M4 Wave 2, agent F; owner #67; spec §7.4, §17.1): the same JSON
## as user://profile.json minus what fits only this device, kept in the player's private Nakama storage
## (collection "profiles", key "profile"). ProfileSync (net/profile_sync.gd) uploads it, debounced, and merges
## it at sign-in on any device of the account (a sign-in key links a new phone or browser to it).
##
## Owner #67 (layout 2): the Survivor gold is never in it (the server's wallet ledger is the truth; the wallet
## sync brings it to the phone), and the server cleans every write the same way (server/modules ProfileRules).
##
## The merge, per kind of thing:
## - earned things are never lost, whichever copy is newer: codes used (so a code can't pay twice), things
##   owned and bought, the highest universe and crystal, Secret Book counts (the higher), treasures, stickers,
##   progress (levels, badges), the books, buddy magic, the tutorial's reward, hints seen, the wish list;
## - the child's choices (GROUPS: the look, the settings that travel, the grown-up switches, the pets' names):
##   the newest choice wins per group (ProfileData.stamps; a copy without one counts from its updated_at),
##   except that a new device (no progress yet) takes every choice from the account: it feels loaded;
## - the rest: the newer copy (ProfileData.updated_at); a local profile with no progress counts as older;
## - what fits one device stays on it: DEVICE_ONLY_SETTINGS, DEVICE_ONLY_FIELDS and the avatar's boy / girl.

const COLLECTION := "profiles"
const KEY := "profile"
## Owner #67: the backup's own layout (1: M4 F, with gold; 2: no gold, device-only fields left out, stamps).
const BACKUP_VERSION := 2
## Settings that depend on the device (its power, its screen, the browser's install card, the phone's farm note),
## never taken from another copy.
const DEVICE_ONLY_SETTINGS: Array[String] = ["graphics", "view_distance", "show_fps", "install_not_now", "install_asked_at",
	"farm_note",
	# owner #101: a headset's comfort and text size (a phone's backup never resets them)
	VrRules.TURN, VrRules.VIGNETTE, VrRules.WALK_DIR, VrRules.TELEPORT, VrRules.HEIGHT, VrRules.BREAK_MINUTES,
	VrRules.SWING, "vr_text_size"]
## Owner #67: top-level fields that stay on this device: the gold (the server's wallet decides it), the thumb
## controls moved for this screen, when this phone last rang the farm note.
const DEVICE_ONLY_FIELDS: Array[String] = ["survivor_gold", "hud_moves", "farm_note_at",
	"backpack",   # owner #83: the Gold Shop's weapons wait for this device's next Survivor world (never twice)
	"my_shorts",   # MAKE MY SHORT (spec §5.12b): a child's own Shorts never leave the device
	"codes_unsettled"]   # the gold-double bug's leftover: gold codes this phone paid itself, until the server's word
## Owner #67: the child's choices, merged per group (the newest wins). Each group's fields as they travel.
const GROUPS := {"look": ["avatar"], "settings": ["settings"], "switches": ["theater_switch", "photo_share"],
	"pets": ["pip", "baby_dragon"]}
## The server refuses objects over 1 MiB (server/modules ProfileRules; owner #70/#71: the School's progress for up to
## SchoolData.MAX_UNITS units makes a profile up to ~600 KB; most are a few KB).
const MAX_CHARS := 1000 * 1024
## An upload waits until the profile has been still this long...
const QUIET_MSEC := 5_000
## ...but never longer than this after the first change it carries.
const MAX_WAIT_MSEC := 30_000


## The backup's JSON text.
static func to_backup(p: ProfileData) -> String:
	var json := JSON.new()
	json.parse(p.to_json())
	var d: Dictionary = json.data
	_leave_out_device_only(d)
	d.backup = BACKUP_VERSION
	return JSON.stringify(d)


static func _leave_out_device_only(d: Dictionary) -> void:
	if d.get("settings") is Dictionary:
		var settings: Dictionary = (d.settings as Dictionary).duplicate()
		for key in DEVICE_ONLY_SETTINGS:
			settings.erase(key)
		d.settings = settings
	for key in DEVICE_ONLY_FIELDS:
		d.erase(key)
	if d.get("shorts") is Dictionary:   # MAKE MY SHORT: the hearts and seen marks of the child's own Shorts stay too
		var hearts: Variant = (d.shorts as Dictionary).get("liked")
		if hearts is Dictionary:
			for id: Variant in (hearts as Dictionary).keys():
				if MyShortRules.is_mine_id(id):
					(hearts as Dictionary).erase(id)
		var seen: Variant = (d.shorts as Dictionary).get("seen")
		if seen is Array:
			d.shorts.seen = (seen as Array).filter(func(id: Variant) -> bool: return not MyShortRules.is_mine_id(id))
	if d.get("avatar") is Dictionary:
		(d.avatar as Dictionary).erase("base")   # Owner 48: the boy/girl choice stays on this phone


## Whether `text` is a backup (a JSON object written by to_backup).
static func is_backup(text: String) -> bool:
	var json := JSON.new()   # not JSON.parse_string: that logs an engine error on bad text
	if text == "" or json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = json.data
	return d.has("version") and d.has("username")


## No progress yet: the start gold, the first universe, no codes, nothing owned, no secrets. A new
## install's profile after the age gate and the name looks like this.
static func is_new(p: ProfileData) -> bool:
	return p.survivor_gold == ProfileData.START_GOLD and p.universe_unlocked <= 1 and p.codes_redeemed.is_empty() \
		and p.cosmetics.is_empty() and p.secret_book.is_empty() and p.treasures.is_empty() and p.progress.is_empty() and p.stickers.is_empty() \
		and p.pip.is_empty() and p.purchases.is_empty() \
		and p.baby_dragon.is_empty() \
		and p.wonder.is_empty() and p.buddy_magic.is_empty() \
		and p.school.is_empty() \
		and p.lab.is_empty() and p.missions.is_empty() and p.prospect.is_empty() \
		and p.creatures.is_empty() and p.inventions.is_empty() \
		and p.tools.is_empty() \
		and p.life.units.is_empty() and p.life.skills.is_empty()   # owner #116: a Tool Book stamp; owner #112: Life progress; M3 Task 11; owner 35: a bought pack is progress; owner 39: a baby dragon; M3 Tasks 21b, 20b; owner #68; spec §23; §21d; §26; §21f; §21e


## {"profile": the merged ProfileData (new; `local` is not changed), "restored": the backup won}.
## A missing or broken backup gives a copy of `local`.
static func merge(local: ProfileData, remote_text: String) -> Dictionary:
	var mine := ProfileData.from_json(local.to_json())
	if not is_backup(remote_text):
		return {"profile": mine, "restored": false}
	var theirs := ProfileData.from_json(remote_text)
	var fresh := is_new(local)
	var restored := fresh or theirs.updated_at > local.updated_at
	var out := theirs if restored else mine
	var other := mine if restored else theirs
	if not fresh:
		_newest_choices(out, other)   # owner #67
	_keep_device_only(out, local)
	out.age_band = AgeSignalsRules.stricter(local.age_band, theirs.age_band)   # M4 Task 10 review: never lifted by a copy
	out.universe_unlocked = maxi(out.universe_unlocked, other.universe_unlocked)
	out.updated_at = maxi(out.updated_at, other.updated_at)
	for h in other.codes_redeemed:
		if not out.codes_redeemed.has(h) and out.codes_redeemed.size() < CodeRules.MAX_REDEEMED:
			out.codes_redeemed.append(h)
	for id in other.cosmetics:
		if not out.cosmetics.has(id) and out.cosmetics.size() < AvatarUnlocks.MAX_OWNED:
			out.cosmetics.append(id)
	for product in other.purchases:   # Owner 35: a purchase is never lost, whichever copy wins
		Entitlements.grant(out, product)
	for id in other.wishes:
		WishList.add(out, id)
	WishList.tidy(out)
	for kind: String in other.secret_book:
		out.secret_book[kind] = maxi(int(out.secret_book.get(kind, 0)), int(other.secret_book[kind]))
	for id in other.treasures:
		out.add_treasure(id)
	out.progress.merge_from(other.progress)   # M3 Task 12: levels, badges and stickers are never lost
	for kind: String in other.stickers:   # M4 H: a sticker is never lost
		out.stickers[kind] = maxi(int(out.stickers.get(kind, 0)), int(other.stickers[kind]))
	if out.pip.is_empty():   # M3 Task 11: Pip is never lost
		out.pip = other.pip.duplicate()
	if out.baby_dragon.is_empty():   # owner 39: nor the Sky Dragon's baby dragon
		out.baby_dragon = other.baby_dragon.duplicate()
	out.buddy_magic.merge_from(other.buddy_magic)   # M3 Task 20b: shapes found, the album, minis and tricks are never lost
	out.crystals_given = maxi(out.crystals_given, other.crystals_given)   # owner 39: a crystal is handed over once
	if out.crystal_gifts.is_empty():
		out.crystal_gifts = other.crystal_gifts.duplicate()
	out.wonder.merge_from(other.wonder)   # M3 Task 21b: the Animal Book, the saving list, pages rewarded, universes
	out.tutorial.merge_from(other.tutorial)   # M3 Task 15: a paid reward and a skip are never lost
	out.school.merge_from(other.school)   # owner #68: stars, rounds and mastery are never lost
	out.lab.merge_from(other.lab)   # spec §23: the Lab Book's stars, guesses and plantings are never lost
	out.invite.merge_from(other.invite)   # owner #79: a code used, the guide, the first unit learned and reports
	for id in other.bought:   # owner #83: what the Gold Shop opened is never lost
		if not out.bought.has(id) and out.bought.size() < SpendRules.MAX_BOUGHT:
			out.bought.append(id)
	out.missions.merge_from(other.missions)   # spec §21d: rocket parts bought and missions flown are never lost
	out.prospect.merge_from(other.prospect)   # spec §26: a prospecting quest done or a find is never lost
	out.creatures.merge_from(other.creatures)   # spec §21f: alien friends, paid questions and souvenirs are never lost
	out.daily.merge_from(other.daily)   # owner #85: a Daily Mission's day, its answers and the mission days are never lost
	out.social.merge_from(other.social)   # owner #81, #85: a postcard offered once stays offered; nothing waiting is lost
	out.inventions.merge_from(other.inventions)   # owner #78: an invention or a paid "try it" is never lost
	out.shorts.merge_from(other.shorts)   # owner #94: a Short seen stays seen; each heart is the one given or taken last
	out.life.merge_from(other.life)   # owner #112: a Passport stamp, a Life star, a run or a paid reward is never lost
	out.tools.merge_from(other.tools)   # owner #116, #117: a Tool Book stamp is never lost
	for h in other.hints_seen:
		if not out.hints_seen.has(h) and out.hints_seen.size() < ProfileData.MAX_HINTS:
			out.hints_seen.append(h)
	return {"profile": out, "restored": restored}


## Owner #67: per group of choices, the copy that changed it last gives it (a copy from before owner #67 has every
## group stamped with its updated_at: ProfileData.from_json). `out` is changed.
static func _newest_choices(out: ProfileData, other: ProfileData) -> void:
	for group: String in GROUPS:
		var mine := _stamp(out, group)
		var theirs := _stamp(other, group)
		if theirs > mine:
			for field: String in GROUPS[group]:
				out.set(field, _copy_field(other, field))
		var newest := maxi(mine, theirs)
		if newest > 0:
			out.stamps[group] = newest


static func _stamp(p: ProfileData, group: String) -> int:
	return int(p.stamps.get(group, 0))   # never changed since stamps exist: the oldest


static func _copy_field(p: ProfileData, field: String) -> Variant:
	var v: Variant = p.get(field)
	if v is AvatarLook:
		return (v as AvatarLook).duplicate()
	if v is Dictionary:
		return (v as Dictionary).duplicate(true)
	return v


## What fits one device comes from this device's own profile, whichever copy won.
static func _keep_device_only(out: ProfileData, local: ProfileData) -> void:
	for key in DEVICE_ONLY_SETTINGS:
		out.settings[key] = local.settings.get(key, ProfileData.DEFAULT_SETTINGS[key])
	out.survivor_gold = local.survivor_gold   # owner #67: the wallet sync decides it (OnlineService.sync_wallet)
	out.hud_moves = local.hud_moves.duplicate(true)
	out.farm_note_at = local.farm_note_at
	out.backpack = local.backpack.duplicate()   # owner #83
	out.my_shorts = MyShortsData.from_dict(local.my_shorts.to_dict())   # MAKE MY SHORT: this device's own
	out.codes_unsettled = local.codes_unsettled.duplicate()   # the gold-double bug's leftover (module 0.2.19)
	out.social.learned_day = local.social.learned_day   # owner #81, #85: what this device still owes the server
	out.social.units = local.social.units.duplicate()
	out.social.moments = local.social.moments.duplicate(true)
	out.avatar.base = local.avatar.base   # owner 48


## Owner #67: each group's choices as they travel (for Profile.save's stamps): {group: JSON text}.
static func group_texts(p: ProfileData) -> Dictionary:
	var json := JSON.new()
	json.parse(p.to_json())
	var d: Dictionary = json.data
	_leave_out_device_only(d)
	var out := {}
	for group: String in GROUPS:
		var parts := {}
		for field: String in GROUPS[group]:
			parts[field] = d.get(field)
		out[group] = {"text": JSON.stringify(parts), "stamp": int(p.stamps.get(group, 0))}
	return out


## Owner #67: stamps `now` on each group whose choices changed since `before` (group_texts at the last save),
## unless the change came with its own stamp (a merge brought another device's choice). The new group_texts.
static func stamp_changes(p: ProfileData, before: Dictionary, now: int) -> Dictionary:
	var after := group_texts(p)
	for group: String in after:
		var was: Dictionary = before.get(group, {})
		var changed: bool = (after[group] as Dictionary).text != was.get("text", "")
		if changed and int(p.stamps.get(group, 0)) == int(was.get("stamp", 0)) and not was.is_empty():
			p.stamps[group] = now
			(after[group] as Dictionary).stamp = now
	return after


## Makes `target` (the Profile autoload's object, which the game holds on to) a copy of `source`.
static func copy_into(target: ProfileData, source: ProfileData) -> void:
	var fresh := ProfileData.from_json(source.to_json())
	for prop in fresh.get_property_list():
		if int(prop.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			target.set(prop.name, fresh.get(prop.name))


## Debounce: the first unsent change and the latest one (msec, -1 = none) against now.
static func upload_due(first_change_msec: int, last_change_msec: int, now_msec: int) -> bool:
	if first_change_msec < 0:
		return false
	return now_msec - last_change_msec >= QUIET_MSEC or now_msec - first_change_msec >= MAX_WAIT_MSEC
