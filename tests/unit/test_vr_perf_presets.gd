extends GutTest
## P5 (owner #101, #108: "i have quest 3"): `vr_plus`, what a Quest 3 adds to the `vr` preset (the research's defaults:
## 90 Hz, near sun shadows, MSAA 4x, the REALISTIC style allowed; an 80-block view, P5's measurement), picked at the first start on a Quest 3 / 3S
## (the Quest 2 keeps `vr`), offered on the settings page beside `vr` in a headset; the refresh rate each asks for; the
## step down to the next rate when a session keeps missing frames. Off VR nothing changes.

const QUEST_APK := {PlatformRules.MOBILE: true, PlatformRules.ANDROID: true, PlatformRules.QUEST: true}
const QUEST_BROWSER := {PlatformRules.WEB: true, PlatformRules.WEB_ANDROID: true, PlatformRules.WEBXR: true}
const ANDROID := {PlatformRules.MOBILE: true, PlatformRules.ANDROID: true}


func after_each() -> void:
	GraphicsPreset.vr_session = false
	GraphicsPreset.headset = ""


func test_vr_plus_is_the_research_quest_3_preset() -> void:
	var plus := GraphicsPreset.params("vr_plus")
	assert_true(plus.shadows, "near sun shadows")
	assert_eq(plus.shadow_distance, 24.0)
	assert_eq(plus.msaa, Viewport.MSAA_4X)
	assert_eq(plus.view_max, 80, "the research's 96 was 213 draws in Green Meadows with 16-cube blocks (a Quest 3: 200)")
	assert_eq(plus.refresh, 90.0)
	assert_eq(plus.style, "", "the child's style: REALISTIC allowed")
	assert_false(plus.glow, "glow is not stereo-safe and turns the subsampled foveation off")
	assert_eq(plus.scale_3d, 1.0, "OpenXR's render target sets the size")
	assert_eq(plus.mesh_block, 16)
	assert_eq(GraphicsPreset.params("vr").refresh, 72.0, "Quest 2, the floor: 72 Hz")


func test_a_quest_3_or_3s_gets_vr_plus_and_every_other_headset_vr() -> void:
	for model: String in ["Quest 3", "Quest 3S", "Quest_3", "quest 3s", "Meta Quest 3"]:
		assert_eq(GraphicsPreset.vr_for_model(model), "vr_plus", model)
	for model: String in ["Quest 2", "Quest_2", "Quest Pro", "Quest", "Oculus Quest", "GenericDevice", ""]:
		assert_eq(GraphicsPreset.vr_for_model(model), "vr", model)


func test_in_a_session_a_phone_preset_reads_as_the_headsets_own() -> void:
	GraphicsPreset.vr_session = true
	GraphicsPreset.headset = "Quest 3"
	for p: String in ["low", "medium", "high", "nonsense"]:
		assert_eq(GraphicsPreset.params(p), GraphicsPreset.params("vr_plus"), p)
	assert_eq(GraphicsPreset.view_distance({"graphics": "medium", "view_distance": 192}), 80)
	GraphicsPreset.headset = "Quest 2"
	assert_eq(GraphicsPreset.params("medium"), GraphicsPreset.params("vr"))
	assert_eq(GraphicsPreset.view_distance({"graphics": "medium", "view_distance": 192}), 64)


func test_a_childs_vr_choice_stays_on_any_headset() -> void:
	GraphicsPreset.vr_session = true
	GraphicsPreset.headset = "Quest 3"
	assert_eq(GraphicsPreset.params("vr"), GraphicsPreset.PRESETS["vr"], "a Quest 3 child who picked VR keeps it")
	GraphicsPreset.headset = "Quest 2"
	assert_eq(GraphicsPreset.params("vr_plus"), GraphicsPreset.PRESETS["vr_plus"], "the owner may try VR PLUS anywhere")
	assert_eq(GraphicsPreset.vr_preset("vr_plus"), "vr_plus")
	assert_eq(GraphicsPreset.vr_preset("medium"), "vr", "a Quest 2's own pick")


func test_vr_plus_allows_the_realistic_style_and_vr_keeps_blocky() -> void:
	GraphicsPreset.vr_session = true
	assert_eq(GraphicsPreset.style_in_use("realistic", "vr"), "blocky")
	assert_eq(GraphicsPreset.style_in_use("realistic", "vr_plus"), "realistic")
	assert_eq(GraphicsPreset.style_in_use("blocky", "vr_plus"), "blocky")
	GraphicsPreset.headset = "Quest 3"
	assert_eq(GraphicsPreset.style_in_use("realistic", "medium"), "realistic", "a Quest 3's own pick is vr_plus")
	GraphicsPreset.headset = "Quest 2"
	assert_eq(GraphicsPreset.style_in_use("realistic", "medium"), "blocky")
	assert_eq(GraphicsPreset.style_in_use("realistic"), "blocky", "no choice known: the headset's own pick")
	GraphicsPreset.vr_session = false
	assert_eq(GraphicsPreset.style_in_use("realistic", "vr"), "realistic", "off VR: the child's style, as before")


func test_glow_only_off_a_headset() -> void:
	assert_true(GraphicsPreset.glow_allowed("medium"), "off VR: REALISTIC's glow, as before")
	assert_true(GraphicsPreset.glow_allowed("vr_plus"), "off a session nothing changes")
	GraphicsPreset.vr_session = true
	assert_false(GraphicsPreset.glow_allowed("vr_plus"))
	assert_false(GraphicsPreset.glow_allowed("medium"))


func test_each_vr_preset_asks_for_its_refresh_rate() -> void:
	assert_eq(GraphicsPreset.refresh_rate("vr"), 72.0)
	assert_eq(GraphicsPreset.refresh_rate("vr_plus"), 90.0)
	GraphicsPreset.headset = "Quest 3"
	assert_eq(GraphicsPreset.refresh_rate("medium"), 90.0, "a Quest 3 child who never picked: vr_plus")
	GraphicsPreset.headset = "Quest 2"
	assert_eq(GraphicsPreset.refresh_rate("medium"), 72.0)


func test_the_nearest_rate_the_headset_offers() -> void:
	assert_eq(GraphicsPreset.nearest_rate(90.0, [60.0, 72.0, 80.0, 90.0, 120.0]), 90.0)
	assert_eq(GraphicsPreset.nearest_rate(90.0, [72.0]), 72.0, "a Quest 2 without 90 Hz")
	assert_eq(GraphicsPreset.nearest_rate(90.0, [72.0, 80.0, 120.0]), 80.0)
	assert_eq(GraphicsPreset.nearest_rate(72.0, [60.0, 72.0, 90.0]), 72.0)
	assert_eq(GraphicsPreset.nearest_rate(72.0, []), 72.0, "nothing offered (WebXR): ask for it anyway")


func test_a_headset_offers_vr_and_vr_plus_and_a_phone_its_three() -> void:
	assert_eq(GraphicsPreset.choices(false), ["low", "medium", "high"] as Array[String])
	assert_eq(GraphicsPreset.choices(true), ["vr", "vr_plus"] as Array[String])
	assert_eq(GraphicsPreset.label("vr_plus"), "VR PLUS")
	assert_eq(GraphicsPreset.label("vr"), "VR")
	assert_eq(GraphicsPreset.label("medium"), "MEDIUM")


func test_the_first_start_on_a_quest_picks_its_vr_preset() -> void:
	assert_eq(GraphicsPreset.first_preset("medium", QUEST_APK, "Quest 3"), "vr_plus")
	assert_eq(GraphicsPreset.first_preset("medium", QUEST_APK, "Quest 3S"), "vr_plus")
	assert_eq(GraphicsPreset.first_preset("medium", QUEST_APK, "Quest 2"), "vr")
	assert_eq(GraphicsPreset.first_preset("low", ANDROID, "Quest 3"), "low", "a phone keeps its own pick")
	assert_eq(GraphicsPreset.first_preset("medium", {}, "GenericDevice"), "medium", "the desktop")
	assert_eq(GraphicsPreset.first_preset("medium", QUEST_BROWSER, "GenericDevice"), "medium",
		"a browser can't tell the headset: its session reads as vr (the headset's own pick there)")


func test_a_session_that_keeps_missing_frames_steps_down_once() -> void:
	var w := {}
	var offered := [72.0, 80.0, 90.0, 120.0]
	var rate := 90.0
	for i in 90 * 5:   # 5 s at the full rate: headroom
		rate = GraphicsPreset.watch_refresh(w, 1.0 / 90.0, rate, offered)
	assert_eq(rate, 90.0, "frames on time: stays")
	for i in 75 * 15:   # 15 s at 75 FPS: at least two whole windows short of 90
		rate = GraphicsPreset.watch_refresh(w, 1.0 / 75.0, rate, offered)
	assert_eq(rate, 80.0, "steps down to the next rate it offers")
	for i in 60 * 30:
		rate = GraphicsPreset.watch_refresh(w, 1.0 / 60.0, rate, offered)
	assert_eq(rate, 80.0, "once: never lower than one step, never back up (no see-saw)")


func test_a_load_hitch_is_no_reason_to_step_down() -> void:
	var w := {}
	var rate := 90.0
	for s in 20:   # 20 s at 80 FPS, but each second holds one world-load frame of 300 ms
		for i in 80:
			rate = GraphicsPreset.watch_refresh(w, 1.0 / 80.0, rate, [72.0, 90.0])
		rate = GraphicsPreset.watch_refresh(w, 0.3, rate, [72.0, 90.0])
	assert_eq(rate, 90.0, "a window with a frame over 100 ms is a load, not a steady miss")


func test_72_hz_is_the_floor_of_the_step_down() -> void:
	var w := {}
	var rate := 72.0
	for i in 50 * 20:
		rate = GraphicsPreset.watch_refresh(w, 1.0 / 50.0, rate, [60.0, 72.0, 90.0])
	assert_eq(rate, 72.0, "never under 72 (Quest 2's own rate, the plan's floor)")


func test_off_vr_the_phone_presets_are_as_before() -> void:
	assert_eq(GraphicsPreset.params("medium").shadow_distance, 40.0)
	assert_eq(GraphicsPreset.params("low").view_max, 64)
	assert_false(GraphicsPreset.params("medium").has("refresh"), "a phone asks for no refresh rate")
	GraphicsPreset.headset = "Quest 3"
	assert_eq(GraphicsPreset.params("medium"), GraphicsPreset.PRESETS["medium"], "off a session the model changes nothing")


func test_a_headset_streams_16_cube_terrain_blocks() -> void:
	# P5: a 32-cube block's collision shape is built on the main thread in one go: 30-50 ms on this desktop (several
	# times that on a Quest) for every block that streams in; 16-cube blocks split it eightfold (more draws: +40-50 in a
	# world of trees, within the budget once the HUD is batched).
	GraphicsPreset.vr_session = true
	for p: String in ["vr", "vr_plus"]:
		assert_eq(int(GraphicsPreset.params(p).mesh_block), GraphicsPreset.MESH_BLOCK, p)
	assert_eq(GraphicsPreset.mesh_block_size(), 16)
