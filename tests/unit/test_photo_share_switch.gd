extends GutTest
## M5 store readiness F1 (spec §5.9, §5.14): SHARE in photo mode sends a photo out of the game through the phone's
## share sheet, so it follows a grown-up's switch: off by default for under-13 children (and a profile without a
## band), on for 13+, and a grown-up's ON or OFF holds whatever the band. The switch lives in the profile (like the
## Theater's) and travels with the profile backup.


func test_by_default_only_13_plus_may_share() -> void:
	assert_false(PhotoRules.may_share(AgeBand.UNDER_13, PhotoRules.SHARE_AUTO), "a child: off until a grown-up says")
	assert_true(PhotoRules.may_share(AgeBand.TEEN_PLUS, PhotoRules.SHARE_AUTO), "13+: on")
	assert_false(PhotoRules.may_share(&"", PhotoRules.SHARE_AUTO), "no band yet: the child's rules")
	assert_false(PhotoRules.may_share(&"adult", PhotoRules.SHARE_AUTO), "an unknown band: the child's rules")


func test_a_grown_ups_choice_holds_whatever_the_band() -> void:
	for band: StringName in [AgeBand.UNDER_13, AgeBand.TEEN_PLUS, &""]:
		assert_true(PhotoRules.may_share(band, PhotoRules.SHARE_ON), "ON for %s" % band)
		assert_false(PhotoRules.may_share(band, PhotoRules.SHARE_OFF), "OFF for %s" % band)


func test_an_unknown_switch_reads_as_the_default() -> void:
	for bad: StringName in [&"", &"yes", &"ON", &"true"]:
		assert_eq(PhotoRules.valid_share_switch(bad), PhotoRules.SHARE_AUTO, String(bad))
		assert_false(PhotoRules.may_share(AgeBand.UNDER_13, bad), "a child with '%s'" % bad)


func test_the_profile_keeps_the_switch() -> void:
	var p := ProfileData.new()
	assert_eq(p.photo_share, PhotoRules.SHARE_AUTO, "a new profile: from the band")
	p.photo_share = PhotoRules.SHARE_ON
	assert_eq(ProfileData.from_json(p.to_json()).photo_share, PhotoRules.SHARE_ON)
	p.photo_share = PhotoRules.SHARE_OFF
	assert_eq(ProfileData.from_json(p.to_json()).photo_share, PhotoRules.SHARE_OFF)
	for bad: String in ['{"photo_share": "yes"}', '{"photo_share": 1}', '{"photo_share": true}', '{}']:
		assert_eq(ProfileData.from_json(bad).photo_share, PhotoRules.SHARE_AUTO, bad)


func test_the_switch_travels_with_the_profile_backup() -> void:
	var local := ProfileData.new()
	local.username = "Pip"
	local.age_band = AgeBand.UNDER_13
	var remote := ProfileData.new()
	remote.username = "Pip"
	remote.age_band = AgeBand.UNDER_13
	remote.survivor_gold = 900   # progress: the backup wins on a new install
	remote.updated_at = 1_800_000_000
	remote.photo_share = PhotoRules.SHARE_ON
	assert_true(ProfileBackup.to_backup(remote).contains("\"photo_share\""), "in the backup")
	var m: ProfileData = ProfileBackup.merge(local, ProfileBackup.to_backup(remote)).profile
	assert_eq(m.photo_share, PhotoRules.SHARE_ON, "a grown-up's ON comes back with the backup")
