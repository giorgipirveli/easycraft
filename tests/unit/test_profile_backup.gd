extends GutTest
## The profile's backup on the game server (M4 Wave 2, agent F; spec §7.4, §17.1): what goes up
## (the profile minus what only fits this phone), when a local profile counts as new, the merge
## (the newer one wins, gold never goes backwards on this phone, nothing earned is ever lost) and
## the upload's pace (debounced).

const H1 := "a59f43a363322b8e2604d1c43fcb5005cf099fdf8e4230fb593e8a918ec46f0a"
const H2 := "8764c42a183660d928b90caff8f0be2a5b9d811dde5df56970079ea15e439208"


func _played(gold: int, at: int) -> ProfileData:
	var p := ProfileData.new()
	p.username = "Pip"
	p.age_band = AgeBand.UNDER_13
	p.survivor_gold = gold
	p.updated_at = at
	p.universe_unlocked = 2
	return p


func test_the_profile_keeps_when_it_changed() -> void:
	var p := ProfileData.new()
	assert_eq(p.updated_at, 0, "a new profile never changed")
	p.updated_at = 1_800_000_123
	assert_eq(ProfileData.from_json(p.to_json()).updated_at, 1_800_000_123)
	for bad in ['"soon"', "-5", "1e400", "null"]:
		assert_eq(ProfileData.from_json('{"updated_at": %s}' % bad).updated_at, 0, "bad time: %s" % bad)


func test_the_backup_leaves_out_what_only_fits_this_phone() -> void:
	var p := _played(300, 1_800_000_000)
	p.settings.graphics = "high"
	p.settings.view_distance = 256
	p.settings.show_fps = true
	p.settings.reduce_motion = true
	p.settings.install_not_now = 2   # M7: the browser's install card
	p.settings.install_asked_at = 1_800_000_000
	p.settings.farm_note = true   # the phone's own note
	p.farm_note_at = 1_800_000_000
	p.hud_moves = {"big": {"jump": [10, 20]}}   # moved for this screen
	p.stamps = {"look": 1_800_000_000}
	var d: Dictionary = JSON.parse_string(ProfileBackup.to_backup(p))
	assert_eq(d.username, "Pip")
	assert_eq(int(d.updated_at), 1_800_000_000)
	assert_eq(int(d.backup), ProfileBackup.BACKUP_VERSION, "owner #67: the backup's own layout number")
	assert_eq(ProfileBackup.BACKUP_VERSION, 2)
	for key in ProfileBackup.DEVICE_ONLY_SETTINGS:
		assert_false((d.settings as Dictionary).has(key), "%s stays on the phone" % key)
	for key in ["install_not_now", "install_asked_at", "farm_note"]:
		assert_true(ProfileBackup.DEVICE_ONLY_SETTINGS.has(key), key)
	for key in ["survivor_gold", "hud_moves", "farm_note_at"]:
		assert_false(d.has(key), "%s stays on the phone (gold: the server's wallet)" % key)
	assert_true(d.settings.reduce_motion, "a child's own choices travel")
	assert_eq(int(d.stamps.look), 1_800_000_000, "when each choice changed travels")
	assert_lt(ProfileBackup.to_backup(p).length(), ProfileBackup.MAX_CHARS)


func test_a_profile_with_no_progress_is_new() -> void:
	var p := ProfileData.new()
	p.username = "Pip"
	p.age_band = AgeBand.UNDER_13
	p.hints_seen.append("iron_pickaxe")   # hints are no progress
	p.settings.graphics = "low"
	assert_true(ProfileBackup.is_new(p))
	for change: Callable in [
			func(q: ProfileData) -> void: q.survivor_gold = ProfileData.START_GOLD + 1,
			func(q: ProfileData) -> void: q.universe_unlocked = 2,
			func(q: ProfileData) -> void: q.codes_redeemed.append(H1),
			func(q: ProfileData) -> void: q.cosmetics.append("hat.party"),
			func(q: ProfileData) -> void: q.record_secret(&"treasure"),
			func(q: ProfileData) -> void: q.survivor_gold = 0]:
		var q := ProfileData.from_json(p.to_json())
		change.call(q)
		assert_false(ProfileBackup.is_new(q), "progress: %s" % q.to_json())


func test_a_new_profile_is_restored_from_the_backup() -> void:
	var local := ProfileData.new()
	local.username = "Pip"
	local.age_band = AgeBand.UNDER_13
	local.updated_at = 1_900_000_000   # newer, but new: the backup wins
	local.settings.graphics = "low"
	var remote := _played(900, 1_800_000_000)
	remote.codes_redeemed.append(H1)
	remote.settings.graphics = "high"
	remote.settings.music_volume = 0.2
	remote.theater_switch = TheaterRules.SWITCH_OFF
	var r := ProfileBackup.merge(local, ProfileBackup.to_backup(remote))
	assert_true(r.restored)
	var m: ProfileData = r.profile
	assert_eq(m.survivor_gold, ProfileData.START_GOLD, "owner #67: gold comes from the wallet (OnlineService.sync_wallet)")
	assert_eq(m.universe_unlocked, 2)
	assert_eq(m.codes_redeemed, [H1] as Array[String])
	assert_eq(m.theater_switch, TheaterRules.SWITCH_OFF)
	assert_almost_eq(float(m.settings.music_volume), 0.2, 0.001)
	assert_eq(m.settings.graphics, "low", "the phone's own settings stay")


## M4 Task 10 review: a backup from before the phone knew better (a 13+ answer, then the store's age signal said
## under 13) won on a new install and lifted the band back to 13+: the phone's chat and LAN rules followed it.
## The band only ever gets stricter, whichever copy wins.
func test_a_restored_backup_never_lifts_the_phones_under_13_band() -> void:
	var local := ProfileData.new()
	local.username = "Pip"
	local.age_band = AgeBand.UNDER_13
	var remote := _played(900, 1_800_000_000)
	remote.age_band = AgeBand.TEEN_PLUS
	var r := ProfileBackup.merge(local, ProfileBackup.to_backup(remote))
	assert_true(r.restored, "a new install takes the backup")
	assert_eq((r.profile as ProfileData).age_band, AgeBand.UNDER_13)
	var teen := _played(100, 1_800_000_900)
	teen.age_band = AgeBand.TEEN_PLUS
	var kid_backup := _played(100, 1_800_000_000)   # under 13 (_played)
	assert_eq((ProfileBackup.merge(teen, ProfileBackup.to_backup(kid_backup)).profile as ProfileData).age_band,
		AgeBand.UNDER_13, "an older backup that knew the player is under 13 keeps it so")
	var unknown := ProfileData.new()
	assert_eq((ProfileBackup.merge(unknown, ProfileBackup.to_backup(remote)).profile as ProfileData).age_band,
		AgeBand.TEEN_PLUS, "no band on the phone yet: the backup's")


func test_the_newer_one_wins_and_the_gold_is_the_phones() -> void:
	# The phone is newer: it wins; its gold stays (owner #67: the wallet sync brings the server's).
	var r := ProfileBackup.merge(_played(100, 1_800_000_500), ProfileBackup.to_backup(_played(500, 1_800_000_000)))
	assert_false(r.restored)
	assert_eq((r.profile as ProfileData).survivor_gold, 100)
	# The backup is newer: its things win, the gold is still the phone's.
	var newer_remote := _played(40, 1_800_000_900)
	newer_remote.username = "Pip_2"
	var r2 := ProfileBackup.merge(_played(70, 1_800_000_000), ProfileBackup.to_backup(newer_remote))
	assert_true(r2.restored)
	assert_eq((r2.profile as ProfileData).username, "Pip_2")
	assert_eq((r2.profile as ProfileData).survivor_gold, 70)
	var old_backup := JSON.parse_string(ProfileBackup.to_backup(_played(95, 1_800_000_900))) as Dictionary
	old_backup.survivor_gold = 95   # a backup from before owner #67 (layout 1) had gold in it
	var r3 := ProfileBackup.merge(_played(70, 1_800_000_000), JSON.stringify(old_backup))
	assert_eq((r3.profile as ProfileData).survivor_gold, 70, "never taken from a copy: the wallet is the truth")


# --- Owner #67: the account on every device: per-choice merge, device-only fields ---

func _look(hat: String) -> AvatarLook:
	var look := AvatarLook.classic()
	look.hat = StringName(hat)
	return look


func test_the_newest_choice_wins_per_group_whichever_copy_is_newer() -> void:
	var local := _played(100, 1_800_000_500)   # newer overall: its settings changed last
	local.avatar = _look("none")
	local.settings.music_volume = 0.3
	local.stamps = {"look": 1_800_000_100, "settings": 1_800_000_500}
	var remote := _played(100, 1_800_000_300)   # older overall, but its look is the newest choice
	remote.avatar = _look("bow")
	remote.settings.music_volume = 0.9
	remote.theater_switch = TheaterRules.SWITCH_OFF
	remote.stamps = {"look": 1_800_000_300, "settings": 1_800_000_200, "switches": 1_800_000_250}
	var r := ProfileBackup.merge(local, ProfileBackup.to_backup(remote))
	assert_false(r.restored, "the phone is newer")
	var m: ProfileData = r.profile
	assert_eq(String(m.avatar.hat), "bow", "the look chosen last, on the other device")
	assert_almost_eq(float(m.settings.music_volume), 0.3, 0.001, "the settings changed last here")
	assert_eq(m.theater_switch, TheaterRules.SWITCH_OFF, "a switch only the other copy changed")
	assert_eq(int(m.stamps.look), 1_800_000_300)
	assert_eq(int(m.stamps.settings), 1_800_000_500)
	assert_eq(int(m.stamps.switches), 1_800_000_250)


func test_a_copy_without_stamps_counts_from_when_it_changed() -> void:
	var local := _played(100, 1_800_000_500)
	local.avatar = _look("none")
	local.stamps = {"look": 1_800_000_100}
	var old := _played(100, 1_800_000_300)   # a backup from before owner #67: no stamps, changed at 300
	old.avatar = _look("bow")
	var d := JSON.parse_string(ProfileBackup.to_backup(old)) as Dictionary
	d.erase("stamps")
	d.erase("backup")
	var text := JSON.stringify(d)
	var m: ProfileData = ProfileBackup.merge(local, text).profile
	assert_eq(String(m.avatar.hat), "bow", "300 is newer than the look's 100")
	local.stamps = {"look": 1_800_000_400}
	m = ProfileBackup.merge(local, text).profile
	assert_eq(String(m.avatar.hat), "none")


func test_a_new_phone_takes_every_choice_from_the_account() -> void:
	var fresh := ProfileData.new()   # a new phone: the name and age, a starting look picked just now
	fresh.username = "Pip"
	fresh.age_band = AgeBand.UNDER_13
	fresh.avatar = _look("none")
	fresh.updated_at = 1_900_000_000
	fresh.stamps = {"look": 1_900_000_000, "settings": 1_900_000_000}
	var account := _played(100, 1_800_000_000)
	account.avatar = _look("flower_crown")
	account.settings.simple_controls = true
	account.stamps = {"look": 1_800_000_000}
	var r := ProfileBackup.merge(fresh, ProfileBackup.to_backup(account))
	assert_true(r.restored)
	var m: ProfileData = r.profile
	assert_eq(String(m.avatar.hat), "flower_crown", "the account feels loaded")
	assert_true(m.settings.simple_controls)


func test_what_fits_one_device_stays_whichever_copy_wins() -> void:
	var local := _played(100, 1_800_000_000)
	local.hud_moves = {"big": {"jump": [10, 20]}}
	local.farm_note_at = 1_700_000_000
	local.settings.install_not_now = 1
	local.settings.farm_note = true
	local.avatar = _look("none")
	local.avatar.base = AvatarCatalog.GIRL
	var remote := _played(100, 1_800_000_900)   # newer: it wins
	remote.hud_moves = {"big": {"jump": [900, 20]}}
	remote.settings.install_not_now = 3
	var d := JSON.parse_string(ProfileBackup.to_backup(remote)) as Dictionary
	d.hud_moves = remote.hud_moves   # even a copy that carries them (a modified game)
	var r := ProfileBackup.merge(local, JSON.stringify(d))
	assert_true(r.restored)
	var m: ProfileData = r.profile
	assert_eq(m.hud_moves, local.hud_moves)
	assert_eq(m.farm_note_at, 1_700_000_000)
	assert_eq(int(m.settings.install_not_now), 1)
	assert_true(m.settings.farm_note)
	assert_eq(m.avatar.base, AvatarCatalog.GIRL, "boy or girl stays on this phone (owner #48)")


func test_a_save_stamps_the_choices_that_changed() -> void:
	var p := _played(100, 1_800_000_000)
	var before := ProfileBackup.group_texts(p)
	p.avatar = _look("bow")
	p.settings.volume = 0.1
	p.settings.graphics = "high"   # device-only: no choice that travels
	var after := ProfileBackup.stamp_changes(p, before, 1_800_000_777)
	assert_eq(int(p.stamps.look), 1_800_000_777)
	assert_eq(int(p.stamps.settings), 1_800_000_777)
	assert_false(p.stamps.has("switches"))
	assert_false(p.stamps.has("pets"))
	ProfileBackup.stamp_changes(p, after, 1_800_000_999)
	assert_eq(int(p.stamps.look), 1_800_000_777, "nothing changed since")
	var only_graphics := ProfileBackup.group_texts(p)
	p.settings.graphics = "low"
	ProfileBackup.stamp_changes(p, only_graphics, 1_800_001_000)
	assert_eq(int(p.stamps.settings), 1_800_000_777, "graphics is this device's own")


func test_a_choice_that_came_with_its_own_stamp_is_not_stamped_again() -> void:
	var p := _played(100, 1_800_000_000)
	var before := ProfileBackup.group_texts(p)
	p.avatar = _look("flower_crown")   # the merge brought the other device's look...
	p.stamps.look = 1_700_000_000   # ...with its stamp
	ProfileBackup.stamp_changes(p, before, 1_800_000_500)
	assert_eq(int(p.stamps.look), 1_700_000_000, "an older choice stays older")


func test_stamps_are_read_carefully() -> void:
	var p := ProfileData.new()
	p.stamps = {"look": 1_800_000_000, "settings": 1_800_000_001}
	assert_eq(ProfileData.from_json(p.to_json()).stamps, p.stamps)
	var bad := ProfileData.from_json('{"stamps": {"look": "x", "settings": -4, "switches": 1e20, "pets": 1800000000, "%s": 5}}'
		% "k".repeat(40))
	assert_eq(bad.stamps, {"pets": 1_800_000_000})
	assert_eq(ProfileData.from_json('{"stamps": [1]}').stamps, {})


func test_a_profile_from_before_stamps_has_every_choice_as_old_as_itself() -> void:
	var old := ProfileData.from_json('{"username": "Pip", "updated_at": 1800000000}')
	for group: String in ProfileBackup.GROUPS:
		assert_eq(int(old.stamps.get(group, 0)), 1_800_000_000, group)
	assert_eq(ProfileData.from_json('{"username": "Pip"}').stamps, {}, "never saved: nothing to stamp")
	assert_eq(ProfileData.new().stamps, {})


func test_nothing_earned_is_lost_whichever_wins() -> void:
	var local := _played(100, 1_800_000_500)
	local.codes_redeemed.append(H2)
	local.cosmetics.append("hat.party")
	local.record_secret(&"treasure")
	local.treasures.append(LootRules.TREASURE_ONLY[0])
	var remote := _played(500, 1_800_000_000)
	remote.universe_unlocked = 3
	remote.codes_redeemed.append(H1)
	remote.cosmetics.append("face.cool")
	remote.record_secret(&"treasure")
	remote.record_secret(&"treasure")
	remote.record_secret(&"island")
	var m: ProfileData = ProfileBackup.merge(local, ProfileBackup.to_backup(remote)).profile
	assert_eq(m.universe_unlocked, 3, "the highest universe")
	assert_eq(m.codes_redeemed, [H2, H1] as Array[String], "a code used on either can't pay twice")
	assert_true(m.cosmetics.has("hat.party") and m.cosmetics.has("face.cool"), "things owned stay owned")
	assert_eq(int(m.secret_book.treasure), 2, "the Secret Book keeps the higher count")
	assert_eq(int(m.secret_book.island), 1)
	assert_eq(m.treasures, [LootRules.TREASURE_ONLY[0]] as Array[int])


func test_a_broken_or_missing_backup_changes_nothing() -> void:
	var local := _played(100, 1_800_000_500)
	for bad in ["", "not json", "[1, 2]", "{}", '{"hello": 1}']:
		var r := ProfileBackup.merge(local, bad)
		assert_false(r.restored, "bad backup: %s" % bad)
		assert_eq((r.profile as ProfileData).to_json(), local.to_json())
	assert_false(ProfileBackup.is_backup(""))
	assert_true(ProfileBackup.is_backup(ProfileBackup.to_backup(local)))


func test_the_merge_never_changes_the_profiles_it_was_given() -> void:
	var local := _played(100, 1_800_000_500)
	var before := local.to_json()
	ProfileBackup.merge(local, ProfileBackup.to_backup(_played(500, 1_800_000_900)))
	assert_eq(local.to_json(), before)


func test_copy_into_changes_the_same_profile_object() -> void:
	var target := ProfileData.new()
	var source := _played(777, 1_800_000_000)
	source.cosmetics.append("hat.party")
	ProfileBackup.copy_into(target, source)
	assert_eq(target.to_json(), source.to_json())
	source.cosmetics.append("face.cool")
	assert_false(target.cosmetics.has("face.cool"), "a copy, not shared lists")


func test_uploads_wait_for_a_quiet_moment_but_not_forever() -> void:
	var q := ProfileBackup.QUIET_MSEC
	var w := ProfileBackup.MAX_WAIT_MSEC
	assert_false(ProfileBackup.upload_due(-1, -1, 99_999), "nothing changed")
	assert_false(ProfileBackup.upload_due(1000, 1000, 1000 + q - 1), "still changing")
	assert_true(ProfileBackup.upload_due(1000, 1000, 1000 + q))
	assert_false(ProfileBackup.upload_due(1000, 1000 + w - q, 1000 + w - 1), "a change came just now")
	assert_true(ProfileBackup.upload_due(1000, 1000 + w - 1, 1000 + w), "changes all the time: goes anyway")


## Owner #68 with #67: the School's progress follows the account; from either device nothing learned is lost (the
## better stars, the most rounds), whichever copy wins, and a device whose only progress is school work is not "new"
## (a new device takes everything from the account, which would drop it).
func test_school_progress_is_never_lost_whichever_wins() -> void:
	var local := _played(100, 1_800_000_500)
	local.school.grade = 4
	local.school.set_progress("g4.maths.place_value", {"s": 2, "r": 3})
	var remote := _played(500, 1_800_000_000)
	remote.school.set_progress("g4.maths.place_value", {"s": 1, "r": 5})
	remote.school.set_progress("g4.science.rocks", {"s": 3, "r": 2})
	var m: ProfileData = ProfileBackup.merge(local, ProfileBackup.to_backup(remote)).profile
	assert_eq(int(m.school.progress("g4.maths.place_value").s), 2, "the better stars")
	assert_eq(int(m.school.progress("g4.maths.place_value").r), 5, "the most rounds")
	assert_eq(int(m.school.progress("g4.science.rocks").s), 3, "a unit done on the other device")
	assert_eq(m.school.grade, 4)


func test_a_device_with_only_school_work_is_not_new() -> void:
	var p := ProfileData.new()
	assert_true(ProfileBackup.is_new(p), "an untouched profile is new")
	p.school.set_progress("g4.maths.place_value", {"s": 1, "r": 1})
	assert_false(ProfileBackup.is_new(p), "school work is progress")


## Owner #70/#71 (2026-09-29): the School grows to every subject of every grade. A child who has practised as many
## units as the School can hold (SchoolData.MAX_UNITS) still backs up.
func test_a_school_of_every_unit_practised_still_backs_up() -> void:
	var p := ProfileData.new()
	p.username = "Pip"
	var full := {"l": true, "s": 3, "r": 12, "a": 72, "f": 60, "b": 100, "x": 3, "d": 20400, "t": 20380, "m": 20370,
		"p": true}
	for i in SchoolData.MAX_UNITS:
		p.school.set_progress("g%d.geography.unit_number_%d" % [3 + i % 6, i], full)
	assert_eq(p.school.units.size(), SchoolData.MAX_UNITS)
	var text := ProfileBackup.to_backup(p)
	assert_lt(text.length(), ProfileBackup.MAX_CHARS, "%d characters" % text.length())


## The gold-double bug's leftover (module 0.2.19): the codes this phone paid itself, whose server's word it has not
## heard yet, are this phone's alone (another device never settles them).
func test_codes_this_phone_paid_itself_stay_on_it() -> void:
	var local := _played(100, 1_800_000_000)
	local.codes_unsettled = {H1: 1000}
	var d: Dictionary = JSON.parse_string(ProfileBackup.to_backup(local))
	assert_false(d.has("codes_unsettled"), "never in the backup")
	var remote := _played(100, 1_800_000_900)
	remote.codes_unsettled = {H2: 5}
	var r := ProfileBackup.merge(local, remote.to_json())
	assert_eq((r.profile as ProfileData).codes_unsettled, {H1: 1000}, "this phone's own, whichever copy wins")

