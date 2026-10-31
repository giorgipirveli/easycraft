extends GutTest
## M7 (docs/devlog/parts/m7-shader-warmup.md): the warm-up draws the block pages (BlockLibrary.warmup_materials) and the
## census of everything else the game draws (data/shader_warmup.json, made by playing: tools/shader_probe_steps.gd
## --shader-census). New content must come along: the census has to hold the shaders of the game's own material
## makers, and every script that makes a material, a 3D label or sprite, particles or a shader is listed here with how
## its shaders are warmed. A new one fails the last test until someone decides (and usually runs the census again).

const PATTERN := "StandardMaterial3D\\.new\\(\\)|ShaderMaterial\\.new\\(\\)|ORMMaterial3D\\.new\\(\\)|Label3D\\.new\\(\\)" \
	+ "|Sprite3D\\.new\\(\\)|CPUParticles3D\\.new\\(\\)|GPUParticles3D\\.new\\(\\)|MultiMeshInstance3D\\.new\\(\\)|\\.gdshader" \
	+ "|extends (Label3D|Sprite3D|CPUParticles3D|MultiMeshInstance3D)"
const ROOTS := ["res://autoloads", "res://core", "res://entities", "res://scenes", "res://ui", "res://world"]

## Every script that makes something with a shader of its own, and how its shaders are warmed. "census": the census saw
## it drawn; "shares": its settings are a shader the census has; "own world": drawn in a SubViewport with its own
## lights (not the game's: its first sight compiles); "2D": a canvas shader; "rare": a feature the census does not
## play (its first sight compiles; run the census through it when it matters).
const COVERED := {
	"world/wonders/wonders_director.gd": "shares: the wonders' plaques are billboard Label3Ds like the animals' tags",
	"world/wonders/nature_sky.gd": "shares: owner #78's northern lights and the falls' rainbow are vertex-colour ribbons drawn with the night sky's star material settings (SkyCycle._night_material), like Venus's lightning",
	"entities/alien/alien.gd": "shares: its name tag is the animals' billboard tag (a Label3D, billboard, outlined)",
	"entities/alien/alien_camp.gd": "shares: the camp's sign is a billboard Label3D like the animals' tags",
	"entities/alien/alien_village.gd": "shares: the village's sign is a billboard Label3D like the animals' tags",
	"entities/robot/creature_look.gd": "shares: the animals' soft material and Pip's metal (Animal.pip_material)",
	"entities/vr/vr_comfort.gd": "rare: VR only (owner #101): the Quest APK's Vulkan compiles in the background (no warm-up); the Web VR build's first sight compiles until P5's census in an XR viewport (docs/devlog/parts/vr-rig.md)",
	"entities/vr/vr_hand.gd": "rare: VR only (owner #101): the laser's two unshaded alpha materials; as vr_comfort.gd",
	"entities/vr/vr_teleport.gd": "rare: VR only (owner #101, P3): the teleport arc's dots (a MultiMesh) and ring, two unshaded alpha materials; as vr_comfort.gd",
	"entities/vr/vr_capsule.gd": "rare: VR only (owner #101, P3): the rocket's capsule round the seated child (its window shader); as vr_comfort.gd",
	"entities/vr/vr_photo_camera.gd": "rare: VR only (owner #101, P3): the held camera's little screen (an unshaded picture of its viewport); as vr_comfort.gd",
	"entities/vr/vr_mirror.gd": "rare: VR only (owner #101, P4), and only while the optional mirror is open: the glass (an unshaded picture of its viewport, flipped) and its frame (AvatarParts.material, warmed); as vr_comfort.gd",
	"entities/vr/vr_grabber.gd": "rare: VR only (owner #110, round 4): the hover's glow (an unshaded additive sphere); as vr_comfort.gd",
	"entities/vr/vr_hand_model.gd": "rare: VR only (owner #110, round 4): the real hand's faint outline at a wall (an unshaded alpha sphere); the hands themselves are AvatarParts.material (warmed); as vr_comfort.gd",
	"entities/vr/vr_bricks.gd": "rare: VR only (owner #116): a brick's life-size ghost (an unshaded alpha box); the brick in the hand is the blocks' own mesh (warmed); as vr_comfort.gd",
	"entities/vr/vr_gestures.gd": "rare: VR only (owner #110, idea 3): the buddy's paw (a lit box with emission); as vr_comfort.gd",
	"entities/vr/vr_build_table.gd": "rare: VR only (owner #110, idea 5), while the Build Table is open: its vertex-colour frame, unshaded alpha ghost, mirror sheet and backboard; its blocks are the blocks' own mesh (warmed); as vr_comfort.gd",
	"entities/vr/vr_model_view.gd": "rare: VR only (owner #110, idea 6), while MODEL VIEW is open: the figure (a lit capsule with emission) and the landing ring (unshaded alpha); as vr_comfort.gd",
	"entities/vr/vr_orrery.gd": "rare: VR only (owner #110, idea 1, VR-WONDER), while the Star Map is open in a headset: the planets' MultiMesh shader (unshaded, lit from the orrery's Sun), the Sun's, Saturn's ring's, the orbits' and the landing ring's unshaded materials, two billboard labels; as vr_comfort.gd",
	"entities/vr/vr_lab_bench.gd": "rare: VR only (owner #110, idea 4, VR-WONDER), while float-or-sink or magnets shows in a headset: the bench, baskets, magnet and cubes are AvatarParts.part_material (warmed; the cubes instanced), the tank's glass and water the mirror wall's see-through settings, billboard labels; as vr_comfort.gd",
	"entities/vr/vr_lens.gd": "rare: VR only (owner #110, idea 2, VR-WONDER), while a telescope or magnifier is in the hand: the disc (an unshaded picture of its own viewport or of a close-up: VrPhotoCamera's screen's settings, both sides), a billboard label; the tubes and the rim are AvatarParts.material (warmed); as vr_comfort.gd",
	"entities/robot/helper_robot.gd": "shares: its tag is the animals' billboard tag; its ! is Tilly's no-depth billboard",
	"entities/robot/space_creature.gd": "shares: its speech bubble is the animals' billboard bubble",
	"core/photo/photo_filters.gd": "2D: the photo filters' canvas shader (compiled when a filter is first picked)",
	"entities/animal/animal.gd": "census: the animals' tags, collars, the golden look and Pip's",
	"entities/animal/blocky_animal.gd": "census: the animals' vertex-colour material (a known maker below)",
	"entities/books/hub_tree.gd": "shares: unshaded vertex colours (the golem's glow)",
	"entities/bots/bot_friend.gd": "census: the bot friend's tag and badge (a Sprite3D)",
	"entities/bots/bot_realistic_avatar.gd": "census: REALISTIC, the skinned character",
	"entities/buddy/buddy.gd": "shares: a billboard tag, plain and vertex-colour materials",
	"entities/flight/flight_looks.gd": "census: the flight's planet and tunnel shaders (tools/flight_census.gd, phase flight); the ground, the Sun and the nebula share the blocks' and the night sky's settings",
	"entities/flight/flight_moments.gd": "shares: the asteroids are Fx's material instanced, the wormhole's mouth the portal swirl, the lines the night sky's",
	"entities/flight/flight_set.gd": "shares: the engine's dust is Fx's particles; the stars the night sky's",
	"entities/flight/rocket_body.gd": "census: the flame is the golem's glow instanced (tools/flight_census.gd); the smoke Fx's particles",
	"entities/flight/rocket_flight.gd": "shares: the pad's smoke is Fx's particles; its own warm-up draws the flight's looks one a frame as it boards",
	"entities/fx/fx.gd": "census: the particles' material, instanced (a known maker below)",
	"entities/ghosts/ghost_look.gd": "rare: a friend's ghost race (its see-through look)",
	"entities/ghosts/ghost_runner.gd": "shares: a billboard tag",
	"entities/gifts/gift_bottle.gd": "rare: a friend's bottle washing up (see-through glass)",
	"entities/interactables/interactable_models.gd": "census: the secrets' sparkle and shine",
	"entities/interactables/totem.gd": "census: the Monster Totem's glow and tag",
	"entities/interactables/treasure_models.gd": "census: the secrets' ghost and rainbow",
	"entities/mind/thought_pictures.gd": "census: the thought bubbles' pictures",
	"entities/monsters/golem_models.gd": "census: the golem's glow (a known maker below)",
	"entities/npcs/market_cart.gd": "shares: a billboard label",
	"entities/npcs/quest_giver.gd": "census: the quest giver's labels",
	"entities/npcs/trader.gd": "shares: billboard labels (one over everything)",
	"entities/npcs/trader_stand.gd": "shares: a billboard label",
	"entities/npcs/villager.gd": "shares: a billboard label",
	"entities/pickups/pickup_bag.gd": "shares: vertex colours with emission (the totem's)",
	"entities/player/avatar_parts.gd": "census: the blocky avatar (known makers below)",
	"entities/player/avatar_skin.gd": "census: REALISTIC, the realistic avatar's skin shader",
	"entities/player/avatar_trail.gd": "census: particles, instanced (Fx's material)",
	"entities/player/break_ring.gd": "census: the break ring and the place pop (a known maker below)",
	"entities/player/mirror_wall.gd": "census: the mirror wall",
	"entities/player/name_tag.gd": "shares: a billboard label",
	"entities/player/player.gd": "shares: the sleep Zs (a label) and the ghost look (see-through unshaded)",
	"entities/player/realistic_avatar.gd": "census: REALISTIC, the skinned character",
	"entities/player/target_highlight.gd": "census: the target highlight",
	"entities/portal/desert_portal.gd": "census: the desert window shader, its label and sand",
	"entities/portal/hub_circle.gd": "shares: the stones are the animals' material, instanced (the sprinkles')",
	"entities/portal/portal_swirl.gd": "census: the portals' swirl shader (a known maker below)",
	"entities/targets/practice_target.gd": "census: a billboard label over everything",
	"entities/vr/vr_pointer.gd": "rare: VR only (owner #101): the UI laser's beam, unshaded and no-depth like the panel; the WebXR census (P5)",
	"entities/vr/vr_wrist.gd": "rare: VR only (owner #101): the wrist's and the toast's strips, the panel's settings; the WebXR census (P5)",
	"entities/vr/vr_panel.gd": "rare: VR only (owner #101): the panels' unshaded, premultiplied, no-depth quad; a native Quest (Vulkan) compiles in the background, the WebXR census (P5) is to draw it with the multiview variants",
	"entities/discovery/discovery_crystal.gd": "shares: owner #132 (W1)'s discovery crystal and its gems are vertex-colour meshes with AvatarParts.part_glow_material (unshaded, warmed); its numbers are billboard Label3Ds like the animals' tags; the burst and confetti are Fx's",
	"entities/life/life_room_decor.gd": "shares: the rooms' look (2026-10-17): the lit pieces are the Theater's vertex-colour settings, the glowing pieces and the sky the launch blinker's unshaded vertex colours, the floors the blocks' own page-0 material, the glass the mirror wall's (LifeRoomKit.material); each key proved below (LifeRoomDecor's makers)",
	"entities/life/life_room_kit.gd": "shares: owner #112's practice rooms: lit props are AvatarParts.material, see-through and glowing things the mirror wall's settings (unshaded, alpha, two-sided), signs the animals' billboard tags; a plain colour background (no sky shader)",
	"entities/launch/launch_buildings.gd": "shares: the Theater's vertex-colour material and labels (spec §21d)",
	"entities/play/leaf/leaf_kit.gd": "shares: owner #133's Inside a Leaf draws only on three materials the census holds: LeafKit.lit is the Theater's lit vertex colours (instanced: the hub circle's stones, the butterflies), LeafKit.glow the launch site blinker's unshaded vertex colours (instanced: the fireflies), LeafKit.glass the rainbow arch's see-through vertex colours (never instanced); test_leaf_place checks every draw's key against the census (a census phase through the leaf comes with B2: docs/devlog/parts/game-leaf-b.md, finding 5)",
	"entities/play/leaf/leaf_place.gd": "shares: the leaf's mist and sparks are CPU particles on LeafKit.glow (the fireflies' instanced unshaded vertex colours); as leaf_kit.gd",
	"entities/play/leaf/leaf_dive.gd": "shares: the dive's mist is CPU particles on LeafKit.glow (the fireflies' instanced unshaded vertex colours); as leaf_kit.gd",
	"entities/play/altar/altar_kit.gd": "shares: owner #133's Balance Altar draws only on materials the census holds (proved in test_the_census_has_the_game_s_own_material_makers): AltarKit.lit and AltarKit.shiny are the Theater's lit vertex colours (instanced: the hub circle's stones, the butterflies), AltarKit.glow the launch site blinker's unshaded vertex colours (instanced: the fireflies), AltarKit.glass the rainbow arch's see-through vertex colours (never instanced); test_altar_place checks every draw's key against the census; no labels (the rune line is carved geometry)",
	"entities/theater/theater_building.gd": "census: the Theater and its sign",
	"entities/weapons/blaster_models.gd": "census: the paint mark and the bubble (a known maker below)",
	"entities/weapons/weapon_models.gd": "shares: vertex colours",
	"ui/building/rewind_preview.gd": "own world: Build Rewind's stage (rewind_view.gd's SubViewport)",
	"ui/shorts/actors/scene3d_effects.gd": "own world: owner #96's Reel Studio stage (a SubViewport of its own); its particles are the golem's glow and Fx's material instanced like a CPUParticles3D's (test_scene3d_view.gd: every stage material is a census or block shader)",
	"ui/shorts/actors/scene3d_models.gd": "own world: the Reel Studio stage's models are the game's own looks (blocks, the flight's planets, Sun, pad and ground, the night sky's settings, Fx's material instanced for Saturn's ring bits, the blocky avatar); test_scene3d_view.gd checks every one",
	"ui/flight/flight_cockpit.gd": "2D: the hologram's canvas shader (compiled as the flight boards)",
	"ui/gifts/build_outline.gd": "shares: see-through unshaded two-sided (the mirror wall's)",
	"ui/hud/pictures.gd": "census: the thought pictures' material",
	"ui/menus/title_diorama.gd": "census: the menu draws it itself (its island, buddy, dog and sparkle)",
	"ui/photo/photo_mode.gd": "2D: the photo filters' canvas shader",
	"ui/vr/vr_ui.gd": "rare: VR only (owner #101): the rocket dashboard's quad (the panel's settings, depth-tested, inside the capsule); the WebXR census (P5)",
	"ui/vr/vr_loading_room.gd": "rare: VR only (owner #101): the loading room's unshaded, no-depth sky, floor grid and horizon, drawn while a world loads (behind its card); the WebXR census (P5)",
	"world/blaster_director.gd": "census: the blaster's bubbles and marks",
	"world/block_library.gd": "blocks: BlockLibrary.warmup_materials, every page in both styles, and the water",
	"world/candy_sprinkles.gd": "census: the Candy Kingdom's sprinkles, instanced",
	"world/games/game_ring.gd": "census: the game ring's shader (a known maker below)",
	"world/games/star_pool.gd": "census: the game stars' shader",
	"world/meadow_insects.gd": "shares: butterflies and bees, instanced vertex colours",
	"world/music_director.gd": "shares: owner #110's note letter is a billboard Label3D like the animals' tags (outlined); the VR mallets are the blocky avatar's material (AvatarParts.material)",
	"world/life/birds.gd": "shares: owner #94's birds are Fx's particle material in a multimesh laid out like a CPUParticles3D's (colours and custom data): the meadow insects' instanced draw",
	"world/life/fireflies.gd": "shares: owner #94's fireflies are the golem's glow instanced (the rocket's flame, tools/flight_census.gd); census again to see them at night in the meadow (the play phase's night)",
	"world/quest_director.gd": "census: the quest giver's bubble",
	"world/prospecting/prospect_camp.gd": "shares: billboard labels, Gemma's bubble over everything (the quest giver's)",
	"world/prospecting/prospect_models.gd": "shares: the Theater's vertex-colour material and billboard labels (spec §26)",
	"world/shader_warmup.gd": "the warm-up itself",
	"world/sky_cycle.gd": "census: the stars and the moon",
	"world/venus_lightning.gd": "shares: Venus's lightning is drawn with the stars' material settings (SkyCycle._night_material, vertex colours)",
	"world/visit/visit_world.gd": "rare: a friend's showcase visit (its sign and wood)",
}


func _census_materials() -> Dictionary:
	var keys := {}
	for d: Dictionary in ShaderWarmup.census_draws():
		if d.has("material"):
			keys[ShaderWarmup.key(d.material)] = true
	return keys


func test_the_census_is_there_and_every_draw_builds() -> void:
	var draws := ShaderWarmup.census_draws()
	assert_gt(draws.size(), 20, "data/shader_warmup.json")
	for d: Dictionary in draws:
		assert_false((d.get("styles", []) as Array).is_empty(), "the styles it was seen in: %s" % str(d))
		if d.has("material") and d.material.class != "default":
			assert_not_null(ShaderWarmup.build(d.material), str(d.material))
		else:
			assert_true(d.has("label") or d.has("sprite") or d.has("material"), str(d))


func test_the_census_has_the_game_s_own_material_makers() -> void:
	var census := _census_materials()
	var makers := {
		"Fx.material": Fx.material(),
		"BreakRing.feedback_material": BreakRing.feedback_material(Color.WHITE),
		"PortalSwirl.material": PortalSwirl.material(),
		"GameRing.material": GameRing.material(),
		"BlasterModels.mark_material": BlasterModels.mark_material(),
		"GolemModels.glow_material": GolemModels.glow_material(),
		"AvatarParts.part_material": AvatarParts.part_material(),
		"AvatarParts.part_glow_material": AvatarParts.part_glow_material(),
		"AvatarParts.material": AvatarParts.material(Color.RED),
		"BlockyAnimal (a dog)": BlockyAnimal.mesh_for(&"dog").surface_get_material(0),
		"LifeRoomDecor.lit_material": LifeRoomDecor.lit_material(),   # the rooms' look (2026-10-17)
		"LifeRoomDecor.glow_material": LifeRoomDecor.glow_material(),
		"LifeRoomDecor.sky_material": LifeRoomDecor.sky_material(),
		"LifeRoomDecor.tiles_material": LifeRoomDecor.tiles_material(),
		"LifeRoomDecor glass (LifeRoomKit.material)": LifeRoomKit.material(Color(0.82, 0.92, 1.0, 0.22)),
		"AltarKit.lit": AltarKit.lit(),   # Balance Altar B1 (owner #133)
		"AltarKit.shiny": AltarKit.shiny(),
		"AltarKit.glow": AltarKit.glow(),
		"AltarKit.glass": AltarKit.glass(),
	}
	for what: String in makers:
		assert_true(census.has(ShaderWarmup.key(ShaderWarmup.describe(makers[what]))),
			"%s is warmed (run the census again: tools/shader_probe_steps.gd --shader-census)" % what)


func test_every_script_that_makes_a_shader_is_warmed_or_explained() -> void:
	var re := RegEx.create_from_string(PATTERN)
	var found: Array[String] = []
	for root: String in ROOTS:
		_scan(root, re, found)
	for path: String in found:
		assert_true(COVERED.has(path), ("%s makes a material, a 3D label or sprite, particles or a shader: warm it (the "
			+ "census, BlockLibrary.warmup_materials) and list it in COVERED") % path)
	for path: String in COVERED:
		assert_has(found, path, "COVERED lists %s, which makes nothing of the kind any more" % path)


func _scan(dir: String, re: RegEx, out: Array[String]) -> void:
	for sub: String in DirAccess.get_directories_at(dir):
		_scan(dir.path_join(sub), re, out)
	for file: String in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			var path := dir.path_join(file)
			if re.search(FileAccess.get_file_as_string(path)):
				out.append(path.trim_prefix("res://"))
