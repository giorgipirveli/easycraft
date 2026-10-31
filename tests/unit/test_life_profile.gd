extends GutTest
## Owner #112: Life's progress lives in the profile (ProfileData.life), so the existing server backup carries it and
## nothing else is sent; the backup's merge never loses a Passport stamp; a profile with Life progress is not "new".


func test_the_profile_keeps_life() -> void:
	var p := ProfileData.new()
	p.life.track = "little"
	p.life.region = "ge"
	p.life.set_skill("fire_escape.little", {"s": LifeData.DONE, "r": 1})
	var q := ProfileData.from_json(p.to_json())
	assert_eq(q.life.track, "little")
	assert_eq(q.life.region, "ge")
	assert_true(q.life.has_stamp("fire_escape.little", LifeData.DONE))


func test_a_broken_life_field_is_an_empty_life() -> void:
	var q := ProfileData.from_json('{"version": 1, "life": "nonsense"}')
	assert_true(q.life.is_empty())


func test_the_backup_carries_life() -> void:
	var p := ProfileData.new()
	p.life.set_skill("money_stall.middle", {"s": LifeData.SELF})
	var json := JSON.new()
	json.parse(ProfileBackup.to_backup(p))
	assert_true((json.data as Dictionary).has("life"))


func test_the_backups_merge_never_loses_a_stamp() -> void:
	var local := ProfileData.new()
	local.updated_at = 100
	local.life.set_skill("fire_escape.big", {"s": LifeData.EXPERT, "r": 2})
	var remote := ProfileData.new()
	remote.updated_at = 200
	remote.life.set_skill("fire_escape.big", {"s": LifeData.DONE, "r": 1})
	remote.universe_unlocked = 2
	var out: ProfileData = ProfileBackup.merge(local, ProfileBackup.to_backup(remote)).profile
	assert_eq(int(out.life.skill("fire_escape.big").s), LifeData.DONE | LifeData.EXPERT)
	assert_eq(int(out.life.skill("fire_escape.big").r), 2)


func test_life_progress_is_progress() -> void:
	var p := ProfileData.new()
	assert_true(ProfileBackup.is_new(p))
	p.life.set_skill("money_stall.little", {"r": 1})
	assert_false(ProfileBackup.is_new(p))
