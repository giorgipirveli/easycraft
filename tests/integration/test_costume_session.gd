extends GutTest
## Owner feedback #36 (spec §14.6b): costumes are earned while playing. When a counted thing finishes a costume's
## way (a story, a level, a title, a find), this game's profile gets it at once with a message; a boss's costume
## comes with its win (the Sand Serpent: Hercules), like the Golem's Rock Helmet. A test's own progress never
## touches the profile. The real profile is swapped for a fresh one (user://profile.json is shared by worktrees).

var _saved_profile: ProfileData
var _toasts: Array[String] = []


func before_each() -> void:
	_saved_profile = Profile.data
	Profile.data = ProfileData.new()
	_toasts.clear()
	Session.magic_feedback.connect(_on_toast)


func after_each() -> void:
	Progress.end()
	Session.magic_feedback.disconnect(_on_toast)
	Profile.data = _saved_profile


func _on_toast(text: String) -> void:
	_toasts.append(text)


func test_a_story_done_while_playing_gives_its_costume_with_a_message() -> void:
	Progress.begin()
	QuestRules.finish(Profile.data.progress, &"tilly_pets")
	Progress.event(StringName("%s/tilly_pets" % LevelRules.QUEST_DONE))
	await wait_seconds(Session.COSTUME_CHECK_S + 0.25)
	assert_true(CostumeRules.is_complete(&"dorothy", Profile.data.cosmetics), "Dorothy, for the dog's new home")
	assert_eq(_toasts.filter(func(t: String) -> bool: return t.contains("Dorothy")).size(), 1, "said once")
	Progress.event(LevelRules.BLOCK)
	await wait_seconds(Session.COSTUME_CHECK_S + 0.25)
	assert_eq(_toasts.filter(func(t: String) -> bool: return t.contains("Dorothy")).size(), 1, "never again")


func test_a_level_reached_while_playing_gives_its_costume() -> void:
	Progress.begin()
	Profile.data.progress.xp = LevelRules.xp_to_reach(3) - 1
	Progress.event(LevelRules.BLOCK)
	await wait_seconds(Session.COSTUME_CHECK_S + 0.25)
	assert_true(CostumeRules.is_complete(&"alice", Profile.data.cosmetics), "level 3")
	assert_true(_toasts.any(func(t: String) -> bool: return t.contains("Alice")))


func test_nothing_is_given_outside_a_world_or_for_someone_elses_progress() -> void:
	var other := ProgressData.new()
	other.xp = LevelRules.xp_to_reach(10)
	Progress.begin(other)
	Progress.event(LevelRules.BLOCK)
	await wait_seconds(Session.COSTUME_CHECK_S + 0.25)
	assert_eq(Profile.data.cosmetics, [] as Array[String], "a test's own progress is not the child's")
	Progress.end()
	Profile.data.progress.xp = LevelRules.xp_to_reach(10)
	Progress.event(LevelRules.BLOCK)
	await wait_seconds(Session.COSTUME_CHECK_S + 0.25)
	assert_eq(Profile.data.cosmetics, [] as Array[String], "menus count nothing (the editor gives it later)")


func test_the_sand_serpent_earns_hercules_for_every_player() -> void:
	var d := BossDirector.new()
	var serpent := SandSerpent.new()
	d._earn_boss_items(serpent)
	serpent.free()
	d.free()
	assert_true(CostumeRules.is_complete(&"hercules", Profile.data.cosmetics), "the serpent's win")
	assert_true(_toasts.any(func(t: String) -> bool: return t.contains("Hercules")))


func test_the_golem_brings_king_arthur_with_its_helmet() -> void:
	var before := Profile.data.universe_unlocked
	assert_true(Session.boss_apply_unlock(2))
	assert_true(CostumeRules.is_complete(&"king_arthur", Profile.data.cosmetics), "the sword in the stone")
	assert_true(AvatarUnlocks.is_owned("hat.golem_helm", Profile.data.cosmetics), "the Rock Helmet as before")
	assert_gte(Profile.data.universe_unlocked, before)
	assert_true(_toasts.any(func(t: String) -> bool: return t.contains("King Arthur")), "and says so")
