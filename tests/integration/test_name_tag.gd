extends GutTest
## M3 Task 12 (spec §5.8): the level and title on the name tag. A player's own game sets its synced
## `progress_tag`; every other game shows "Name" and "Lv 5 Master Builder" over that player.

var _names := {}


func before_each() -> void:
	_names = Session.chat_names.duplicate()


func after_each() -> void:
	Session.chat_names = _names


func _player(peer: int) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer)
	add_child_autofree(p)
	p.set_physics_process(false)
	return p


func _tag(p: Player) -> NameTag:
	var found := p.find_children("*", "NameTag", false, false)
	return found[0] as NameTag if found.size() == 1 else null


func test_the_words_on_a_tag() -> void:
	assert_eq(NameTag.text_for("Kid", "5:builder"), "Kid\nLv 5 Master Builder")
	assert_eq(NameTag.text_for("Kid", "1:"), "Kid\nLv 1 Adventurer")
	assert_eq(NameTag.text_for("Kid", "12:nonsense"), "Kid\nLv 12 Adventurer", "an unknown style: the plain title")
	assert_eq(NameTag.text_for("Kid", ""), "Kid", "an older game sends no tag: the name only")
	assert_eq(NameTag.text_for("Kid", "lots:builder"), "Kid")
	assert_eq(NameTag.text_for("Kid", "7:builder:x"), "Kid")
	assert_eq(NameTag.text_for("", "5:builder"), "", "no name, no tag")


func test_the_tag_code_is_synced_with_the_body() -> void:
	var p := _player(multiplayer.get_unique_id())
	var cfg := (p.get_node("Sync") as MultiplayerSynchronizer).replication_config
	var path := NodePath(".:progress_tag")
	assert_true(cfg.has_property(path))
	assert_true(cfg.property_get_spawn(path), "a late joiner sees it at once")
	assert_eq(cfg.property_get_replication_mode(path), SceneReplicationConfig.REPLICATION_MODE_ON_CHANGE)
	p.progress_tag = "x".repeat(100)
	assert_eq(p.progress_tag, "", "a tag too long is dropped")


func test_other_players_wear_a_tag_and_mine_has_none() -> void:
	var me := _player(multiplayer.get_unique_id())
	var friend := _player(7)
	assert_null(_tag(me), "it would sit in front of my own camera")
	var tag := _tag(friend)
	assert_not_null(tag)
	Session.chat_names[7] = "Mia"
	friend.progress_tag = "4:hunter"
	await wait_process_frames(2)
	tag._t = NameTag.LOOK_EVERY
	tag._process(0.0)
	assert_eq(tag.text, "Mia\nLv 4 Secret Hunter")
	assert_true(tag.visible)
	assert_almost_eq(tag.position.y, NameTag.HEIGHT, 0.01)
