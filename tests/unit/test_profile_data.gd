extends GutTest


func test_round_trip() -> void:
	var p := ProfileData.new()
	p.username = "Hopper"
	p.age_band = AgeBand.TEEN_PLUS
	p.settings.graphics = "high"
	var q := ProfileData.from_json(p.to_json())
	assert_eq(q.username, "Hopper")
	assert_eq(q.age_band, AgeBand.TEEN_PLUS)
	assert_eq(q.settings.graphics, "high")
	assert_true(q.is_onboarded())


func test_from_json_truncated_returns_defaults() -> void:
	var q := ProfileData.from_json('{"version":1,"username":"Hop')
	assert_eq(q.username, "")
	assert_false(q.is_onboarded())
	assert_eq(q.settings.graphics, "medium")


func test_from_json_wrong_type_returns_defaults() -> void:
	var q := ProfileData.from_json('[1,2,3]')
	assert_eq(q.username, "")


func test_missing_settings_get_defaults() -> void:
	var q := ProfileData.from_json('{"version":1,"username":"Hop","age_band":"13_plus"}')
	assert_eq(q.settings.graphics, "medium")
	assert_eq(q.settings.view_distance, 128)
	assert_eq(q.settings.volume, 0.8)
	assert_false(q.settings.show_fps)


func test_unknown_age_band_is_not_onboarded() -> void:
	var q := ProfileData.from_json('{"version":1,"username":"Hop","age_band":"adult"}')
	assert_false(q.is_onboarded())


func test_onboarded_requires_name_and_age() -> void:
	var q := ProfileData.from_json('{"version":1,"username":"Hop"}')
	assert_false(q.is_onboarded())


func test_jumps_default_to_triple() -> void:
	assert_eq(ProfileData.new().settings.max_jumps, 3)


func test_jumps_are_clamped_to_double_or_triple() -> void:
	assert_eq(ProfileData.from_json('{"version":1,"settings":{"max_jumps":7}}').settings.max_jumps, 3)
	assert_eq(ProfileData.from_json('{"version":1,"settings":{"max_jumps":1}}').settings.max_jumps, 2)
	assert_eq(ProfileData.from_json('{"version":1,"settings":{"max_jumps":2}}').settings.max_jumps, 2)


func test_graphics_style_defaults_to_blocky() -> void:
	assert_eq(ProfileData.new().settings.style, "blocky")
	assert_eq(ProfileData.from_json('{"version":1,"settings":{"style":"realistic"}}').settings.style, "realistic")
	assert_eq(ProfileData.from_json('{"version":1,"settings":{"style":"neon"}}').settings.style, "blocky")
	assert_eq(ProfileData.from_json('{"version":1,"settings":{"style":5}}').settings.style, "blocky")


## M2 §12.1: Survivor gold and the unlocked universe live in the profile (never negative; ≥ 1).
func test_survivor_gold_and_universe_defaults_and_bad_values() -> void:
	var fresh := ProfileData.from_json("{}")
	assert_eq(fresh.survivor_gold, ProfileData.START_GOLD)
	assert_eq(fresh.universe_unlocked, 1)
	var bad := ProfileData.from_json('{"survivor_gold": -9, "universe_unlocked": 0}')
	assert_eq(bad.survivor_gold, 0)
	assert_eq(bad.universe_unlocked, 1)
	var odd := ProfileData.from_json('{"survivor_gold": "lots", "universe_unlocked": "two"}')
	assert_eq(odd.survivor_gold, ProfileData.START_GOLD)
	assert_eq(odd.universe_unlocked, 1)
	var p := ProfileData.new()
	p.survivor_gold = 321
	p.universe_unlocked = 2
	var back := ProfileData.from_json(p.to_json())
	assert_eq(back.survivor_gold, 321)
	assert_eq(back.universe_unlocked, 2)


## M2 Task 11 (§12.10): a music volume of its own, saved like the other settings, always 0..1.
func test_music_volume_default_saved_and_coerced() -> void:
	assert_eq(ProfileData.new().settings.music_volume, 0.6)
	assert_eq(ProfileData.from_json("{}").settings.music_volume, 0.6)
	var p := ProfileData.new()
	p.settings.music_volume = 0.25
	assert_almost_eq(float(ProfileData.from_json(p.to_json()).settings.music_volume), 0.25, 0.0001)
	assert_eq(ProfileData.from_json('{"settings":{"music_volume":"loud"}}').settings.music_volume, 0.6)
	assert_eq(ProfileData.from_json('{"settings":{"music_volume":3}}').settings.music_volume, 1.0)
	assert_eq(ProfileData.from_json('{"settings":{"music_volume":-1}}').settings.music_volume, 0.0)
	assert_eq(ProfileData.from_json('{"settings":{"music_volume":0}}').settings.music_volume, 0.0)


## M2 Task 11: Vibration (phone buzz and screen shake) is ON unless turned off; Reduce motion
## (no shake or camera bob, softer flashes; the lead's child-psychology notes) is OFF unless turned on.
func test_vibration_and_reduce_motion_defaults_saved_and_coerced() -> void:
	var fresh := ProfileData.from_json("{}")
	assert_true(fresh.settings.vibration)
	assert_false(fresh.settings.reduce_motion)
	var p := ProfileData.new()
	p.settings.vibration = false
	p.settings.reduce_motion = true
	var back := ProfileData.from_json(p.to_json())
	assert_false(back.settings.vibration)
	assert_true(back.settings.reduce_motion)
	var odd := ProfileData.from_json('{"settings":{"vibration":"no","reduce_motion":1}}')
	assert_true(odd.settings.vibration)
	assert_false(odd.settings.reduce_motion)

## M2 Task 3: first-time picture hints are shown once per profile (by name).
func test_hints_seen_round_trip_and_bad_values() -> void:
	assert_eq(ProfileData.new().hints_seen, [] as Array[String])
	var p := ProfileData.new()
	p.hints_seen.append("iron_pickaxe")
	assert_eq(ProfileData.from_json(p.to_json()).hints_seen, ["iron_pickaxe"] as Array[String])
	var odd := ProfileData.from_json('{"hints_seen": ["a", 5, "a", null, "%s"]}' % "x".repeat(40))
	assert_eq(odd.hints_seen, ["a"] as Array[String], "junk, repeats and overlong names are dropped")
	assert_eq(ProfileData.from_json('{"hints_seen": "junk"}').hints_seen, [] as Array[String])

## M2 Task 16: the Secret Book is account-wide: how many of each kind of secret were found, and the
## treasure-only things found (its shelf). Unknown kinds and things are dropped.
func test_secret_book_round_trip_and_bad_values() -> void:
	var fresh := ProfileData.from_json("{}")
	assert_eq(fresh.secret_book, {})
	assert_eq(fresh.treasures, [] as Array[int])
	var p := ProfileData.new()
	assert_eq(p.record_secret(SecretRules.TEMPLE), 1)
	assert_eq(p.record_secret(SecretRules.TEMPLE), 2)
	assert_eq(p.record_secret(&"dragon"), 0, "not a kind of secret")
	assert_true(p.add_treasure(BlockIds.TROPHY))
	assert_false(p.add_treasure(BlockIds.TROPHY), "once on the shelf")
	assert_false(p.add_treasure(BlockIds.DIRT), "not treasure")
	var back := ProfileData.from_json(p.to_json())
	assert_eq(back.secret_book, {"temple": 2})
	assert_eq(back.treasures, [BlockIds.TROPHY] as Array[int])
	var odd := ProfileData.from_json('{"secret_book": {"temple": -4, "room": "lots", "dragon": 3, "star": 2}, "treasures": [34, 34, 2, "x", 170]}')
	assert_eq(odd.secret_book, {"star": 2})
	assert_eq(odd.treasures, [BlockIds.TROPHY, ItemIds.TREASURE_MAP] as Array[int])


## The audio pass (owner feedback #27, #31): a SOUND EFFECTS volume (0..1, default 0.8), the MUSIC style
## (game / classical / mix, default mix) and Song names (the "Now playing" toast, default on), saved and
## parsed defensively; profiles saved before the audio pass get the defaults.
func test_sound_effects_volume_default_saved_and_coerced() -> void:
	assert_eq(ProfileData.new().settings.sfx_volume, 0.8)
	assert_eq(ProfileData.from_json("{}").settings.sfx_volume, 0.8)
	var p := ProfileData.new()
	p.settings.sfx_volume = 0.35
	assert_almost_eq(float(ProfileData.from_json(p.to_json()).settings.sfx_volume), 0.35, 0.0001)
	assert_eq(ProfileData.from_json('{"settings":{"sfx_volume":"loud"}}').settings.sfx_volume, 0.8)
	assert_eq(ProfileData.from_json('{"settings":{"sfx_volume":7}}').settings.sfx_volume, 1.0)
	assert_eq(ProfileData.from_json('{"settings":{"sfx_volume":-2}}').settings.sfx_volume, 0.0)


func test_music_style_default_saved_and_coerced() -> void:
	assert_eq(ProfileData.new().settings.music_style, "mix")
	for s: String in ["game", "classical", "mix"]:
		var p := ProfileData.new()
		p.settings.music_style = s
		assert_eq(ProfileData.from_json(p.to_json()).settings.music_style, s)
	assert_eq(ProfileData.from_json('{"settings":{"music_style":"jazz"}}').settings.music_style, "mix")
	assert_eq(ProfileData.from_json('{"settings":{"music_style":5}}').settings.music_style, "mix")
	assert_eq(ProfileData.from_json('{"settings":{"music_style":null}}').settings.music_style, "mix")


func test_song_names_default_saved_and_coerced() -> void:
	assert_true(ProfileData.new().settings.song_names)
	var p := ProfileData.new()
	p.settings.song_names = false
	assert_false(ProfileData.from_json(p.to_json()).settings.song_names)
	assert_true(ProfileData.from_json('{"settings":{"song_names":"no"}}').settings.song_names)


func test_a_profile_from_before_the_audio_pass_keeps_its_settings_and_gets_the_new_ones() -> void:
	var old := '{"version":1,"username":"Mia","age_band":"6-8","settings":{"graphics":"low","volume":0.5,' \
		+ '"music_volume":0.3,"vibration":false}}'
	var p := ProfileData.from_json(old)
	assert_eq(p.settings.graphics, "low")
	assert_almost_eq(float(p.settings.volume), 0.5, 0.0001)
	assert_almost_eq(float(p.settings.music_volume), 0.3, 0.0001)
	assert_false(p.settings.vibration)
	assert_eq(p.settings.sfx_volume, 0.8)
	assert_eq(p.settings.music_style, "mix")
	assert_true(p.settings.song_names)


## M7 (owner 2026-09-28, InstallOffer): the menu's "Add EasyCraft to this device" card remembers how often the child
## said NOT NOW and when the card was last answered (unix seconds); a profile from before starts at none.
func test_the_install_offer_counts_default_saved_and_coerced() -> void:
	var fresh := ProfileData.from_json('{"version":1,"username":"Mia","settings":{"graphics":"low"}}')
	assert_eq(int(fresh.settings.install_not_now), 0)
	assert_eq(int(fresh.settings.install_asked_at), 0)
	assert_eq(int(ProfileData.new().settings.install_not_now), 0)
	var p := ProfileData.new()
	p.settings.install_not_now = 2
	p.settings.install_asked_at = 1_790_000_000
	var back := ProfileData.from_json(p.to_json())
	assert_eq(int(back.settings.install_not_now), 2)
	assert_eq(int(back.settings.install_asked_at), 1_790_000_000)
	var odd := ProfileData.from_json('{"settings":{"install_not_now":"lots","install_asked_at":"soon"}}')
	assert_eq(int(odd.settings.install_not_now), 0)
	assert_eq(int(odd.settings.install_asked_at), 0)
	var wild := ProfileData.from_json('{"settings":{"install_not_now":-4,"install_asked_at":-9}}')
	assert_eq(int(wild.settings.install_not_now), 0)
	assert_eq(int(wild.settings.install_asked_at), 0)
	var many := ProfileData.from_json('{"settings":{"install_not_now":900,"install_asked_at":1e14}}')
	assert_eq(int(many.settings.install_not_now), InstallOffer.MAX_NOT_NOW, "still no more card")
	assert_eq(int(many.settings.install_asked_at), 0, "a broken time reads as never")


## Owner #133 (2026-10-17: "consider no one will start reading in the game … deliver education without just
## reading"): the voice ("Read to me") is on for everyone: a new profile, and once for every profile saved before
## (theirs said off by default, never by choice); a grown-up's later off is kept.
func test_the_voice_is_on_for_a_new_profile() -> void:
	assert_true(bool(ProfileData.new().settings.read_to_me))


func test_a_profile_saved_before_133_gets_the_voice_once() -> void:
	var old := '{"version": 1, "username": "Pip", "settings": {"read_to_me": false, "volume": 0.5}}'
	assert_true(bool(ProfileData.from_json(old).settings.read_to_me), "off by the old default: on now")


func test_a_grown_ups_off_after_133_is_kept() -> void:
	var p := ProfileData.new()
	p.settings.read_to_me = false   # a grown-up turned it off in SETTINGS
	var back := ProfileData.from_json(p.to_json())
	assert_false(bool(back.settings.read_to_me))
