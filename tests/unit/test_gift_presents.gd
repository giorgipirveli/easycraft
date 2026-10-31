extends GutTest
## Owner #81, #82 (brief 2026-09-30 item 3; the world game plan §1 "Giving"): presents a friend opens in the game. A
## rocket part, seeds, a buddy egg or a treasure map piece: ids only travel (nothing personal); opening one gives the
## thing in the game and says what it gave; THANK YOU sends a small gift back (the server's gold). The kinds and numbers
## are the server's (server/modules/src/rules/social_rules.ts).

const SOCIAL_TS := "res://server/modules/src/rules/social_rules.ts"

var profile: ProfileData


func before_each() -> void:
	profile = ProfileData.new()


func test_the_kinds_and_numbers_are_the_servers() -> void:
	var ts := FileAccess.get_file_as_string(SOCIAL_TS)
	assert_ne(ts, "", "the server's rules are readable")
	assert_string_contains(ts, "PRESENT_KINDS = %s;" % JSON.stringify(FriendPresents.KINDS).replace(",", ", "))
	assert_string_contains(ts, "THANK_GOLD = %d;" % FriendPresents.THANK_GOLD)
	assert_string_contains(ts, "SENDS_PER_DAY = %d;" % FriendPresents.SENDS_PER_DAY)
	assert_string_contains(ts, "LINK_GIFTS_MAX = %d;" % FriendPresents.LINK_GIFTS_MAX)


func test_a_rocket_part_goes_to_the_rocket_parts() -> void:
	var words := FriendPresents.open(profile, "rocket_part")
	assert_string_contains(words, BlockIds.display_name(FriendPresents.ROCKET_PART_BLOCK))
	assert_eq(int(profile.missions.parts.get(FriendPresents.ROCKET_PART_BLOCK, 0)), 1, "one more of the part")
	assert_true(RocketParts.is_part(FriendPresents.ROCKET_PART_BLOCK))


func test_seeds_wait_in_the_backpack_for_the_next_survivor_world() -> void:
	var words := FriendPresents.open(profile, "seeds")
	assert_eq(int(profile.backpack.get(BlockIds.WHEAT, 0)), FriendPresents.SEEDS)
	assert_eq(int(profile.backpack.get(BlockIds.FLOWERS, 0)), FriendPresents.SEEDS)
	assert_string_contains(words, "backpack")
	FriendPresents.open(profile, "seeds")
	assert_eq(int(profile.backpack.get(BlockIds.WHEAT, 0)), 2 * FriendPresents.SEEDS, "more seeds add up")


func test_a_buddy_egg_hatches_a_secret_buddy_shape_then_treats() -> void:
	var found_before := profile.buddy_magic.found.size()
	var words := FriendPresents.open(profile, "buddy_egg")
	assert_eq(profile.buddy_magic.found.size(), found_before + 1, "a secret shape")
	var recipe: Dictionary = BuddyRecipes.recipe(StringName(profile.buddy_magic.found[-1]))
	assert_string_contains(words, str(recipe.title))
	for r: Dictionary in BuddyRecipes.RECIPES:
		profile.buddy_magic.add_found(r.id)
	var treats := FriendPresents.open(profile, "buddy_egg")
	assert_string_contains(treats, "treat")
	assert_gt(int(profile.backpack.get(ItemIds.TREAT_BISCUIT, 0)), 0, "every shape found: pet treats")


func test_a_map_piece_is_kept_for_the_prospecting_quests() -> void:
	var words := FriendPresents.open(profile, "map_piece")
	assert_eq(profile.social.map_pieces, 1)
	assert_string_contains(words, "map")
	assert_eq(ProfileData.from_json(profile.to_json()).social.map_pieces, 1, "kept")


func test_unknown_kinds_give_nothing_and_every_kind_has_words() -> void:
	assert_eq(FriendPresents.open(profile, "cake"), "")
	for k: String in FriendPresents.KINDS:
		assert_ne(FriendPresents.name_of(k), "")
		assert_ne(FriendPresents.title_of(k), "")
		assert_ne(FriendPresents.what_it_is(k), "")
	assert_eq(FriendPresents.error_words("sent_today"), "You sent this friend a present today. Tomorrow you can send another!")
	assert_ne(FriendPresents.error_words("inbox_full"), "")
	assert_ne(FriendPresents.error_words("anything else"), "")
