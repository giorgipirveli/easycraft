extends GutTest
## Bot friends as pure rules (M2 Task 15, owner feedback #18): follow at a comfortable distance and
## catch up, rest far from everyone, pick monsters and behaviours by personality, one chat line per
## bot per 20 s, friendly made-up names and own looks, small builds that only fill empty cells, and
## shiny ores an explorer can point at.

const B := preload("res://core/rules/bot_rules.gd")


func test_up_to_three_bot_friends_with_three_personalities() -> void:
	assert_eq(B.MAX_BOTS, 3)
	assert_eq(B.PERSONALITIES, [B.BUILDER, B.EXPLORER, B.FIGHTER] as Array[StringName])
	for p in B.PERSONALITIES:
		assert_true(B.valid_personality(p))
	assert_false(B.valid_personality(&"pirate"))
	assert_false(B.valid_personality(&""))


# --- Following ---

func test_follows_at_a_comfortable_distance() -> void:
	var far := B.follow_far(B.FIGHTER)
	assert_false(B.wants_follow(B.FOLLOW_NEAR + 0.5, false, B.FIGHTER), "close enough: stays")
	assert_true(B.wants_follow(far + 0.5, false, B.FIGHTER), "too far: walks back")
	assert_true(B.wants_follow(far - 0.5, true, B.FIGHTER), "once walking, keeps going until close")
	assert_false(B.wants_follow(B.FOLLOW_NEAR - 0.1, true, B.FIGHTER), "close: stops")
	assert_gt(B.follow_far(B.EXPLORER), B.follow_far(B.FIGHTER), "explorers roam further, fighters stay close")
	for p in B.PERSONALITIES:
		assert_gt(B.follow_far(p), B.WANDER_RADIUS[p], "%s wanders inside its comfortable distance" % p)


func test_catches_up_when_the_player_is_far_away() -> void:
	var feet := Vector3(0, 10, 0)
	assert_false(B.needs_catch_up(feet, Vector3(B.CATCH_UP - 1.0, 10, 0), true))
	assert_true(B.needs_catch_up(feet, Vector3(B.CATCH_UP + 1.0, 10, 0), true), "far to the side")
	assert_true(B.needs_catch_up(feet, Vector3(0, 10 + B.CATCH_UP_DROP + 1.0, 0), true), "far above, standing")
	assert_false(B.needs_catch_up(feet, Vector3(0, 10 + B.CATCH_UP_DROP + 1.0, 0), false),
		"a player flying high: waits below instead of popping up in the air")
	assert_true(B.needs_catch_up(Vector3(0, SpawnRules.FALL_LIMIT_Y - 1.0, 0), Vector3(0, 10, 0), false),
		"fell out of the world")


func test_rests_when_nobody_is_near() -> void:
	var players: Array[Vector3] = [Vector3(100, 10, 0)]
	assert_false(B.is_active(Vector3.ZERO, players))
	players.append(Vector3(B.ACTIVE_DISTANCE - 1.0, 40, 0))
	assert_true(B.is_active(Vector3.ZERO, players), "distance is measured sideways, like animals")
	assert_false(B.is_active(Vector3.ZERO, [] as Array[Vector3]))


func test_wander_spots_stay_near_the_player() -> void:
	var leader := Vector3(10, 20, -5)
	for p in B.PERSONALITIES:
		for i in 20:
			var spot := B.wander_spot(p, leader, i * 0.7, i / 19.0)
			var d := Vector2(spot.x - leader.x, spot.z - leader.z).length()
			assert_between(d, B.WANDER_MIN - 0.001, B.WANDER_RADIUS[p] + 0.001, "%s wanders near the player" % p)


# --- Fighting ---

func test_fighters_defend_the_player_from_further_away() -> void:
	var leader := Vector3(0, 10, 0)
	var bot := Vector3(2, 10, 0)
	var monsters: Array[Vector3] = [Vector3(-12, 10, 0)]
	assert_eq(B.choose_target(B.FIGHTER, bot, leader, monsters), 0, "a fighter goes for it")
	assert_eq(B.choose_target(B.BUILDER, bot, leader, monsters), -1, "a builder leaves it")
	assert_eq(B.choose_target(B.EXPLORER, bot, leader, monsters), -1, "so does an explorer")
	monsters = [Vector3(-4, 10, 0)]
	for p in B.PERSONALITIES:
		assert_eq(B.choose_target(p, bot, leader, monsters), 0, "%s fights a monster right next to the player" % p)


func test_everyone_fights_back_and_picks_the_nearest() -> void:
	var leader := Vector3(0, 10, 0)
	var bot := Vector3(30, 10, 0)
	var monsters: Array[Vector3] = [Vector3(-50, 10, 0), Vector3(31, 10, 1), Vector3(29, 10, 0)]
	assert_eq(B.choose_target(B.BUILDER, bot, leader, monsters), 2, "the one right next to the bot")
	assert_eq(B.choose_target(B.FIGHTER, bot, leader, [] as Array[Vector3]), -1)
	monsters = [Vector3(8, 10, 0), Vector3(3, 10, 0), Vector3(-5, 10, 0)]
	assert_eq(B.choose_target(B.FIGHTER, Vector3(2, 10, 0), leader, monsters), 1)


# --- Behaviours by personality ---

func _facts(overrides: Dictionary) -> Dictionary:
	var f := {"target": false, "far": false, "sight": false, "build_ready": false, "wander_due": false}
	f.merge(overrides, true)
	return f


func test_personalities_pick_their_behaviours() -> void:
	for p in B.PERSONALITIES:
		assert_eq(B.choose_behaviour(p, _facts({})), B.IDLE, "%s: nothing to do" % p)
		assert_eq(B.choose_behaviour(p, _facts({"far": true})), B.FOLLOW, "%s follows" % p)
		assert_eq(B.choose_behaviour(p, _facts({"wander_due": true})), B.WANDER, "%s wanders" % p)
		assert_eq(B.choose_behaviour(p, _facts({"target": true, "far": true, "sight": true, "build_ready": true})),
			B.FIGHT, "%s: a monster comes first" % p)
	assert_eq(B.choose_behaviour(B.EXPLORER, _facts({"sight": true, "far": true})), B.POINT, "explorers point")
	assert_eq(B.choose_behaviour(B.BUILDER, _facts({"build_ready": true, "far": true})), B.BUILD, "builders build")
	assert_eq(B.choose_behaviour(B.FIGHTER, _facts({"sight": true, "build_ready": true})), B.IDLE,
		"a fighter neither points nor builds")
	assert_eq(B.choose_behaviour(B.BUILDER, _facts({"sight": true})), B.IDLE, "a builder doesn't point")
	assert_eq(B.choose_behaviour(B.EXPLORER, _facts({"build_ready": true})), B.IDLE, "an explorer doesn't build")


func test_fighters_hold_a_sword_and_builders_a_hammer() -> void:
	assert_eq(B.held_item(B.FIGHTER, B.IDLE), ItemIds.SWORD)
	assert_eq(B.held_item(B.BUILDER, B.IDLE), ItemIds.HAMMER)
	assert_eq(B.held_item(B.EXPLORER, B.IDLE), 0)
	for p in B.PERSONALITIES:
		assert_eq(B.held_item(p, B.FIGHT), B.WEAPON, "%s fights with the sword" % p)


# --- Chat ---

func test_at_most_one_chat_line_per_bot_every_twenty_seconds() -> void:
	assert_true(B.can_say(-INF, 0.0), "the first line")
	assert_false(B.can_say(10.0, 29.9))
	assert_true(B.can_say(10.0, 10.0 + B.CHAT_GAP))
	assert_eq(B.CHAT_GAP, 20.0)


func test_every_line_is_short_and_friendly() -> void:
	for kind: StringName in B.LINE_KINDS:
		for p in B.PERSONALITIES:
			for pick in 5:
				var text := B.line(kind, p, pick, "Pip")
				assert_ne(text, "", "%s/%s" % [kind, p])
				assert_lte(text.length(), 60, text)
				assert_eq(ChatRules.clean(text), text, "plain text the chat shows as is: %s" % text)
	assert_string_contains(B.line(&"hello", B.BUILDER, 0, "Pip"), "Pip", "says its name hello")
	assert_eq(B.line(&"shiny", B.EXPLORER, 0, "Pip"), "Look! Something shiny over here!")
	assert_eq(B.line(&"nonsense", B.EXPLORER, 0, "Pip"), "")


func test_the_chat_shows_it_is_a_bot() -> void:
	assert_eq(B.chat_name("Pip"), "Pip (bot)")


## Every line a bot can say, for every personality (all picks).
func _all_lines() -> Array[String]:
	var out: Array[String] = []
	for kind: StringName in B.LINE_KINDS:
		for p in B.PERSONALITIES:
			for pick in 8:
				var text := B.line(kind, p, pick, "Pip").to_lower()
				if not out.has(text):
					out.append(text)
	return out


## Child-psychology ruling (lead, docs/design/): bots are cheerful and helpful and never make a
## child feel guilty or rushed about playing or leaving.
func test_bots_never_say_guilt_or_pressure_lines() -> void:
	var banned: Array[String] = ["miss you", "miss me", "don't go", "dont go", "last chance", "hurry",
		"only today", "you'll lose", "youll lose", "come back", "don't leave", "dont leave", "lonely", "sad"]
	for text in _all_lines():
		for phrase in banned:
			assert_false(text.contains(phrase), "\"%s\" contains \"%s\"" % [text, phrase])


## ... and never ask for personal information (they never read the chat either).
func test_bots_never_ask_for_personal_information() -> void:
	var banned: Array[String] = ["your name", "how old", "your age", "where do you live", "school", "address",
		"phone", "password", "email", "photo", "your mom", "your dad", "real name"]
	for text in _all_lines():
		for phrase in banned:
			assert_false(text.contains(phrase), "\"%s\" asks \"%s\"" % [text, phrase])


func test_builders_admire_the_players_builds() -> void:
	var admiring := 0
	for pick in 8:
		var text := B.line(&"idle", B.BUILDER, pick, "Pip").to_lower()
		if text.contains("your build") or text.contains("you build"):
			admiring += 1
	assert_gte(admiring, 2)


# --- Names and looks ---

func test_names_are_made_up_unique_and_pass_the_name_filter() -> void:
	var seen := {}
	for n in B.NAMES:
		assert_false(seen.has(n.to_lower()), "unique: %s" % n)
		seen[n.to_lower()] = true
		assert_eq(UsernameRules.validate(n), "", n)
		assert_false(Animal.PET_NAMES.has(n), "not a pet's name: %s" % n)
	assert_gte(B.NAMES.size(), 12)


func test_a_new_bot_never_takes_a_name_in_use() -> void:
	var taken: Array[String] = []
	for i in B.NAMES.size():
		var n := B.pick_name(taken, i * 7)
		assert_false(taken.has(n), n)
		taken.append(n)
	assert_ne(B.pick_name(taken, 3), "", "all names in use: still a name")


func test_each_bot_has_its_own_look() -> void:
	assert_gte(B.LOOKS.size(), B.MAX_BOTS * 2)
	var taken: Array[int] = []
	for i in B.MAX_BOTS:
		var look := B.pick_look(taken)
		assert_false(taken.has(look))
		taken.append(look)
	for look: Dictionary in B.LOOKS:
		assert_ne(look.torso, BlockyAvatar.TORSO, "never the player's own blue shirt")
		assert_true(look.base in [0, 1], "a realistic body to recolour")
	assert_eq(B.valid_look(99), false)
	assert_eq(B.valid_look(0), true)


# --- Builders ---

func test_survivor_builds_use_only_leaves_so_nobody_gets_free_blocks() -> void:
	for pick in 10:
		var design := B.build_design(ModeRules.SURVIVOR, pick)
		assert_gt(design.size(), 0)
		for cell: Array in design:
			assert_eq(cell[1], BlockIds.LEAVES, "leaves give nothing when broken (§12.2)")


func test_sandbox_builds_are_small_and_colourful() -> void:
	var ids := {}
	for pick in B.SANDBOX_DESIGNS.size():
		var design := B.build_design(ModeRules.SANDBOX, pick)
		assert_between(design.size(), 2, B.MAX_BUILD_BLOCKS, "a few blocks")
		for cell: Array in design:
			assert_true(BlockIds.is_valid(cell[1]) and cell[1] != BlockIds.AIR)
			assert_eq((cell[0] as Vector3i).y >= 0, true, "built upwards from the ground")
			ids[cell[1]] = true
	assert_gt(ids.size(), 3)


## Stone below y = 10; the player built a 2-block post at (0, 10, 0)..(0, 11, 0).
func _yard(extra: Dictionary = {}) -> Callable:
	var cells := {Vector3i(0, 10, 0): BlockIds.BRICK, Vector3i(0, 11, 0): BlockIds.BRICK}
	cells.merge(extra, true)
	return func(p: Vector3i) -> int: return cells.get(p, BlockIds.STONE if p.y < 10 else BlockIds.AIR)


func test_a_build_goes_next_to_the_players_build_on_empty_ground() -> void:
	var block_at := _yard()
	var design := B.build_design(ModeRules.SANDBOX, 0)
	for start in 8:
		var plan := B.plan_build(Vector3i(0, 11, 0), design, block_at, start)
		assert_eq(plan.size(), design.size(), "found a spot (start %d)" % start)
		for cell: Array in plan:
			var pos: Vector3i = cell[0]
			assert_eq(block_at.call(pos), BlockIds.AIR, "only empty cells: never the player's blocks")
			var d := Vector2(pos.x, pos.z).length()
			assert_between(d, float(B.BUILD_GAP), float(B.BUILD_GAP + 3) * 1.5, "next to the build, not on it")
		var base: Vector3i = plan[0][0]
		assert_true(BlockIds.is_solid(block_at.call(base + Vector3i.DOWN)), "stands on the ground")


func test_no_build_where_there_is_no_room() -> void:
	var full := func(p: Vector3i) -> int: return BlockIds.STONE if p.y < 20 else BlockIds.AIR
	assert_eq(B.plan_build(Vector3i(0, 11, 0), B.build_design(ModeRules.SANDBOX, 0), full, 0), [])
	var water := func(p: Vector3i) -> int: return BlockIds.STONE if p.y < 9 else (BlockIds.WATER if p.y == 9 else BlockIds.AIR)
	assert_eq(B.plan_build(Vector3i(0, 10, 0), B.build_design(ModeRules.SANDBOX, 1), water, 0), [], "never on water")


func test_a_build_keeps_a_gap_from_other_blocks() -> void:
	var extra := {}
	for x in range(-6, 7):
		for z in range(-6, 7):
			if (x + z) % 2 == 0 and Vector2i(x, z) != Vector2i.ZERO:
				extra[Vector3i(x, 10, z)] = BlockIds.PLANKS      # a checkerboard floor of player blocks
	assert_eq(B.plan_build(Vector3i(0, 11, 0), B.build_design(ModeRules.SANDBOX, 0), _yard(extra), 0), [],
		"never squeezed in between (or onto) the player's blocks")


# --- Explorers ---

func test_explorers_find_shiny_ores_they_can_see() -> void:
	var cells := {Vector3i(3, 9, 2): BlockIds.GOLD}          # in the ground's top layer: open to the air
	var block_at := func(p: Vector3i) -> int: return cells.get(p, BlockIds.STONE if p.y < 10 else BlockIds.AIR)
	var seen := {}
	assert_eq(B.find_shiny(Vector3i(0, 10, 0), block_at, Vector3i(5, 3, 5), seen), Vector3i(3, 9, 2))
	seen[Vector3i(3, 9, 2)] = true
	assert_eq(B.find_shiny(Vector3i(0, 10, 0), block_at, Vector3i(5, 3, 5), seen), B.NO_CELL, "each find once")
	cells.clear()
	cells[Vector3i(3, 5, 2)] = BlockIds.DIAMOND                # buried: nobody can see it
	assert_eq(B.find_shiny(Vector3i(0, 10, 0), block_at, Vector3i(5, 6, 5), {}), B.NO_CELL)
	cells.clear()
	cells[Vector3i(3, 9, 2)] = BlockIds.COAL
	assert_eq(B.find_shiny(Vector3i(0, 10, 0), block_at, Vector3i(5, 3, 5), {}), B.NO_CELL, "coal isn't shiny")
	for id in [BlockIds.GOLD, BlockIds.DIAMOND, BlockIds.CRYSTAL]:
		assert_true(B.is_shiny(id))


# --- Boss fights ---

func test_bots_count_for_boss_health_like_players() -> void:
	assert_eq(B.team_size(1, 0), 1)
	assert_eq(B.team_size(2, 3), 5)
	assert_eq(B.team_size(0, 2), 2)


func test_a_build_never_goes_where_someone_stands() -> void:
	var block_at := _yard()
	var design := B.build_design(ModeRules.SANDBOX, 0)
	var plan := B.plan_build(Vector3i(0, 11, 0), design, block_at, 0)
	var base: Vector3i = plan[0][0]
	var body := PlacementRules.player_aabb(Vector3(base) + Vector3(0.5, 0.0, 0.5))
	var bodies: Array[AABB] = [body]
	var other := B.plan_build(Vector3i(0, 11, 0), design, block_at, 0, bodies)
	assert_gt(other.size(), 0, "another spot")
	for cell: Array in other:
		assert_false(body.intersects(AABB(Vector3(cell[0]), Vector3.ONE)), "never inside a player or a friend")


func test_a_planned_build_is_checked_again_before_it_goes_up() -> void:
	var extra := {}
	var block_at := _yard(extra)
	var plan := B.plan_build(Vector3i(0, 11, 0), B.build_design(ModeRules.SANDBOX, 2), block_at, 3)
	assert_true(B.plan_fits(plan, block_at, [] as Array[AABB]))
	var base: Vector3i = plan[0][0]
	var bodies: Array[AABB] = [PlacementRules.player_aabb(Vector3(base) + Vector3(0.5, 0.0, 0.5))]
	assert_false(B.plan_fits(plan, block_at, bodies), "someone stands there now")
	extra[base + Vector3i(1, 0, 0)] = BlockIds.RED
	var moved := _yard(extra)
	assert_false(B.plan_fits(plan, moved, [] as Array[AABB]), "the player built right next to it meanwhile")
	assert_false(B.plan_fits([], block_at, [] as Array[AABB]))


## Found by the bots smoke run on real terrain: hills around the player's build left no spot where
## every neighbour was air. A build may lean on natural ground (a hillside, a tree), never on the
## player's blocks.
func test_a_build_may_lean_on_a_hillside() -> void:
	var extra := {}
	for x in range(-6, 7):
		for z in range(-6, 7):
			if (x + z) % 2 == 0 and Vector2i(x, z) != Vector2i.ZERO:
				for y in range(10, 14):
					extra[Vector3i(x, y, z)] = BlockIds.GRASS if y == 13 else BlockIds.DIRT   # tall natural bumps
	var plan := B.plan_build(Vector3i(0, 11, 0), B.build_design(ModeRules.SANDBOX, 0), _yard(extra), 0)
	assert_gt(plan.size(), 0)
	for cell: Array in plan:
		assert_eq(_yard(extra).call(cell[0]), BlockIds.AIR, "still only empty cells")


## Found by the bots smoke run (2 of 11 real worlds had no build): the tries went round one side of
## the player's block. Now they spread all around it, so a single good corner is always found (with
## the tries side by side, 6 of the 72 starts missed it).
func test_the_tries_go_all_around_the_block() -> void:
	var cells := {Vector3i(0, 10, 0): BlockIds.BRICK, Vector3i(0, 11, 0): BlockIds.BRICK}
	var one_side := func(p: Vector3i) -> int:
		if cells.has(p):
			return cells[p]
		if p.y == 9 and not (p.x <= -2 and p.z <= -2):
			return BlockIds.WATER                                # no ground except in one corner
		return BlockIds.STONE if p.y < 10 else BlockIds.AIR
	for start in 72:
		var plan := B.plan_build(Vector3i(0, 11, 0), B.build_design(ModeRules.SANDBOX, 0), one_side, start)
		assert_gt(plan.size(), 0, "start %d" % start)


## Found by the bots smoke run: looking at every cell of the explorer's box through a Callable cost
## 4.5 ms per look on the desktop (15-25 ms on a phone). The ore ids are now found by a native search
## of the copied box's bytes; only the few matches are checked one by one.
func test_ores_are_found_in_a_copied_box_like_a_cell_by_cell_search() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for depth in [VoxelBuffer.DEPTH_16_BIT, VoxelBuffer.DEPTH_8_BIT]:
		var buf := VoxelBuffer.new()
		buf.set_channel_depth(VoxelBuffer.CHANNEL_TYPE, depth)
		buf.create(7, 5, 9)
		var origin := Vector3i(-40, 3, 12)
		var want := {}
		for z in 9:
			for x in 7:
				for y in 5:
					var id: int = [BlockIds.AIR, BlockIds.STONE, BlockIds.GOLD, BlockIds.DIAMOND, BlockIds.CRYSTAL,
						BlockIds.COAL, BlockIds.GRASS][rng.randi() % 7] if rng.randf() < 0.3 else BlockIds.STONE
					buf.set_voxel(id, x, y, z, VoxelBuffer.CHANNEL_TYPE)
					if B.is_shiny(id):
						want[origin + Vector3i(x, y, z)] = true
		var got := {}
		for cell in B.find_in_buffer(buf, origin, B.SHINY):
			assert_false(got.has(cell), "each cell once")
			got[cell] = true
		assert_gt(want.size(), 5)
		assert_eq(got.keys().size(), want.size(), "depth %d" % depth)
		for cell: Vector3i in want:
			assert_true(got.has(cell), "found %s" % cell)


func test_a_box_of_one_block_is_searched_too() -> void:
	var buf := VoxelBuffer.new()
	buf.create(3, 3, 3)
	buf.fill(BlockIds.GOLD, VoxelBuffer.CHANNEL_TYPE)         # stored as one value until decompressed
	assert_eq(B.find_in_buffer(buf, Vector3i.ZERO, B.SHINY).size(), 27)
	buf.fill(BlockIds.STONE, VoxelBuffer.CHANNEL_TYPE)
	assert_eq(B.find_in_buffer(buf, Vector3i.ZERO, B.SHINY).size(), 0)


func test_the_nearest_open_find_wins() -> void:
	var cells := {Vector3i(3, 9, 2): BlockIds.GOLD, Vector3i(1, 9, 1): BlockIds.DIAMOND, Vector3i(0, 5, 0): BlockIds.GOLD}
	var block_at := func(p: Vector3i) -> int: return cells.get(p, BlockIds.STONE if p.y < 10 else BlockIds.AIR)
	var finds: Array[Vector3i] = [Vector3i(3, 9, 2), Vector3i(1, 9, 1), Vector3i(0, 5, 0)]
	assert_eq(B.nearest_open(Vector3i(0, 10, 0), finds, block_at, {}), Vector3i(1, 9, 1))
	assert_eq(B.nearest_open(Vector3i(0, 10, 0), finds, block_at, {Vector3i(1, 9, 1): true}), Vector3i(3, 9, 2))
	var buried: Array[Vector3i] = [Vector3i(0, 5, 0)]
	assert_eq(B.nearest_open(Vector3i(0, 10, 0), buried, block_at, {}), B.NO_CELL, "buried: nobody sees it")


## M3 (lead, after the desert merge): a builder friend builds on desert ground too, and leans builds on
## the desert's natural blocks — never on a player's build.
func test_desert_ground_is_natural_ground_for_builders() -> void:
	for id: int in BlockIds.DESERT_GROUND:
		assert_true(BotRules.GROUND.has(id), BlockIds.display_name(id))
		assert_true(BotRules.NATURAL.has(id), BlockIds.display_name(id))
	for id: int in [BlockIds.CACTUS, BlockIds.PALM_LOG, BlockIds.PALM_LEAVES, BlockIds.DEAD_BUSH]:
		assert_true(BotRules.NATURAL.has(id), BlockIds.display_name(id))
	for id: int in [BlockIds.CUT_SANDSTONE, BlockIds.DESERT_GLASS, BlockIds.DESERT_LAMP]:
		assert_false(BotRules.NATURAL.has(id), "%s is built, not natural" % BlockIds.display_name(id))
