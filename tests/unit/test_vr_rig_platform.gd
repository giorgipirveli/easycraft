extends GutTest
## Owner #101 (VR on the Meta Quest): the headset as a platform. The `vr` graphics preset (the plan's ruling 2: Quest 2
## is the floor), every phone preset reading as VR's while a session runs (and only then), the Quest APK and the Web VR
## build in PlatformRules (no touch HUD, no pointer lock, no phone buzz: the controllers buzz), and the Quest's Touch
## controllers in GamepadRules (the QUEST family: the words on a Quest controller, and which pad input each control is).

const QUEST_APK := {PlatformRules.MOBILE: true, PlatformRules.ANDROID: true, PlatformRules.QUEST: true}
## The Web VR build (/vr/) in the Quest's browser: an Android browser to the engine.
const QUEST_BROWSER := {PlatformRules.WEB: true, PlatformRules.WEB_ANDROID: true, PlatformRules.WEBXR: true}
const ANDROID := {PlatformRules.MOBILE: true, PlatformRules.ANDROID: true}


func after_each() -> void:
	GraphicsPreset.vr_session = false
	PlatformRules.simulated = {}


func test_the_vr_preset_starts_from_low_for_a_quest_2() -> void:
	var vr := GraphicsPreset.params("vr")
	assert_false(vr.shadows, "no sun shadows (their pass alone is a third of Quest 2's draws)")
	assert_eq(vr.view_max, 64, "LOW's view")
	assert_eq(vr.scale_3d, 1.0, "full resolution: OpenXR's render target sets the size, not scale_3d")
	assert_eq(vr.msaa, Viewport.MSAA_2X, "a headset shows every jagged edge")
	assert_eq(vr.particles, 0.5)
	assert_true(vr.simple_water)
	assert_false(vr.sway)
	assert_eq(vr.monsters_near, 6)
	assert_eq(vr.animals_near, 8)
	assert_false(vr.glow, "glow turns foveation off")
	assert_eq(vr.style, "blocky", "realistic waits for vr_plus on a Quest 3")
	assert_eq(vr.mesh_block, 16, "P5: Voxel Tools' 16 (a 32-cube block's collision cost a 30-50 ms frame each)")


func test_in_a_session_every_phone_preset_reads_as_vrs_and_only_then() -> void:
	assert_true(GraphicsPreset.params("high").shadows, "off VR: the child's preset, as before")
	assert_eq(GraphicsPreset.style_in_use("realistic"), "realistic")
	assert_eq(GraphicsPreset.sky_interval(1.0), 1.0)
	GraphicsPreset.vr_session = true
	for p: String in ["low", "medium", "high", "nonsense"]:
		assert_eq(GraphicsPreset.params(p), GraphicsPreset.params("vr"), p)
	assert_eq(GraphicsPreset.view_distance({"graphics": "high", "view_distance": 192}), 64)
	assert_eq(GraphicsPreset.style_in_use("realistic"), "blocky")
	assert_eq(GraphicsPreset.sky_interval(1.0), 2.0, "the sky re-tinted every 2 s (each re-tint updates its light)")
	assert_eq(GraphicsPreset.mesh_block_size(), 16, "P5: the same in a headset (docs/devlog/parts/vr-perf.md)")
	GraphicsPreset.vr_session = false
	assert_eq(GraphicsPreset.mesh_block_size(), 16, "off VR: Voxel Tools' own 16")


func test_the_quest_apk_plays_with_controllers_not_a_touch_hud() -> void:
	assert_true(PlatformRules.vr_build(QUEST_APK))
	assert_false(PlatformRules.touch_device(QUEST_APK), "a Quest is Android, but no finger touches its screen")
	assert_false(PlatformRules.touch_ui(QUEST_APK))
	assert_false(PlatformRules.captures_mouse(QUEST_APK))
	assert_false(PlatformRules.keyboard_first(QUEST_APK), "no keyboard: the phone's 1280 × 720 canvas, big words")
	assert_eq(PlatformRules.ui_scale(QUEST_APK), 1.0)
	assert_false(PlatformRules.can_vibrate(QUEST_APK), "the controllers buzz (Vr.haptic), not a phone motor")
	assert_false(PlatformRules.reads_safe_area(QUEST_APK), "a headset has no notch")
	assert_true(PlatformRules.starts_vr(QUEST_APK), "the native APK starts its session by itself")


func test_the_web_vr_build_in_the_quest_browser_is_no_phone_either() -> void:
	assert_true(PlatformRules.vr_build(QUEST_BROWSER))
	assert_false(PlatformRules.touch_ui(QUEST_BROWSER), "an Android browser to the engine, but a headset")
	assert_false(PlatformRules.captures_mouse(QUEST_BROWSER), "no pointer lock on a laser click")
	assert_false(PlatformRules.can_vibrate(QUEST_BROWSER))
	assert_false(PlatformRules.starts_vr(QUEST_BROWSER), "a browser starts VR only from a tap (ENTER VR)")


func test_phones_and_the_desktop_are_unchanged() -> void:
	assert_false(PlatformRules.vr_build(ANDROID))
	assert_true(PlatformRules.touch_ui(ANDROID))
	assert_true(PlatformRules.can_vibrate(ANDROID))
	assert_false(PlatformRules.vr_build({}))
	assert_false(PlatformRules.starts_vr({}))
	assert_false(PlatformRules.starts_vr(ANDROID))


func test_the_quest_controllers_are_their_own_pad_family() -> void:
	assert_eq(GamepadRules.family(VrInput.JOY_NAME), GamepadRules.QUEST)
	assert_eq(GamepadRules.family("Oculus Touch"), GamepadRules.QUEST)
	assert_eq(GamepadRules.family("Xbox Wireless Controller"), GamepadRules.XBOX, "pads keep theirs")
	assert_eq(GamepadRules.button_word(JOY_BUTTON_A, GamepadRules.QUEST), "A")
	assert_eq(GamepadRules.button_word(JOY_BUTTON_DPAD_LEFT, GamepadRules.QUEST), "Y", "Y opens the blocks")
	assert_eq(GamepadRules.button_word(JOY_BUTTON_DPAD_RIGHT, GamepadRules.QUEST), "X", "X opens MORE")
	assert_eq(GamepadRules.button_word(JOY_BUTTON_START, GamepadRules.QUEST), "Menu button")
	assert_eq(GamepadRules.axis_word(JOY_AXIS_TRIGGER_RIGHT, GamepadRules.QUEST), "Trigger (hold)")
	assert_eq(GamepadRules.axis_word(JOY_AXIS_TRIGGER_LEFT, GamepadRules.QUEST), "Trigger (tap)")


func test_every_quest_control_plays_an_action_through_the_one_table() -> void:
	var by_button := {}
	for key: String in GamepadRules.QUEST_BUTTONS:
		by_button[GamepadRules.QUEST_BUTTONS[key]] = key
	for action: StringName in [&"jump", &"crouch", &"more", &"blocks", &"hotbar_prev", &"hotbar_next", &"pause",
			&"size_mode", &"physics_mode", &"attack"]:
		var spec: Dictionary = GamepadRules.specs_for(action)[0]
		assert_true(by_button.has(spec.button), "%s has a Quest control" % action)
	assert_false(by_button.has(JOY_BUTTON_RIGHT_STICK), "no CAMERA in VR: first person only")


func test_the_action_map_binds_the_touch_controllers_explicitly() -> void:
	var map := load("res://openxr_action_map.tres") as OpenXRActionMap
	assert_not_null(map, "res://openxr_action_map.tres (tools/vr_action_map.gd)")
	assert_eq(ProjectSettings.get_setting("xr/openxr/default_action_map"), "res://openxr_action_map.tres")
	for path: String in ["/interaction_profiles/oculus/touch_controller", "/interaction_profiles/meta/touch_plus_controller"]:
		var p := map.find_interaction_profile(path)
		assert_not_null(p, path)
		if p == null:
			continue
		var bound := {}
		for b: OpenXRIPBinding in p.bindings:
			bound["%s %s" % [b.action.resource_name, b.binding_path.get_slice("/", 3)]] = true
		for action: String in ["trigger", "grip_click", "primary", "primary_click", "ax_button", "by_button", "aim_pose",
				"haptic"]:
			for hand: String in ["left", "right"]:
				assert_true(bound.has("%s %s" % [action, hand]), "%s: %s on the %s hand (VrInput reads it)" % [path, action, hand])
		assert_true(bound.has("menu_button left"), "%s: the menu button pauses" % path)


func test_openxr_and_its_shaders_are_on_only_in_the_quest_build() -> void:
	assert_false(bool(ProjectSettings.get_setting("xr/openxr/enabled")), "phones, the web and the desktop: off")
	assert_false(bool(ProjectSettings.get_setting("xr/shaders/enabled")), "no multiview shader variants for them")
	assert_true(bool(ProjectSettings.get_setting("xr/openxr/enabled.quest", false)), "the Quest APK starts OpenXR")
	assert_true(bool(ProjectSettings.get_setting("xr/shaders/enabled.quest", false)), "and draws both eyes at once")


func test_the_quest_presets_build_an_openxr_apk_for_the_headset() -> void:
	var presets := ConfigFile.new()
	assert_eq(presets.load("res://export_presets.cfg"), OK)
	var found := {}
	for section: String in presets.get_sections():
		if section.ends_with(".options"):
			continue
		var preset_name := str(presets.get_value(section, "name"))
		if preset_name != "Quest" and preset_name != "Quest GL":
			continue
		found[preset_name] = true
		var o := section + ".options"
		assert_eq(presets.get_value(section, "custom_features"), "quest", preset_name)
		assert_true(presets.get_value(o, "gradle_build/use_gradle_build"), "%s: OpenXR needs a Gradle build" % preset_name)
		assert_eq(presets.get_value(o, "xr_features/xr_mode"), 1, "%s: OpenXR" % preset_name)
		assert_eq(presets.get_value(o, "gradle_build/min_sdk"), "32", preset_name)
		assert_eq(presets.get_value(o, "gradle_build/target_sdk"), "34", "%s: Meta's immersive range is 32-34" % preset_name)
		assert_true(presets.get_value(o, "architectures/arm64-v8a"), preset_name)
		assert_false(presets.get_value(o, "architectures/x86_64"), preset_name)
		assert_eq(presets.get_value(o, "package/unique_name"), "com.giorgi.easycraft.quest", preset_name)
	assert_eq(found.size(), 2, "Quest and its Compatibility twin")
	assert_true(str(presets.get_value("preset.15.options", "command_line/extra_args", "")).contains("gl_compatibility"))


func test_a_bench_line_says_every_number_the_budget_needs() -> void:
	var l := VrBench.line({"fps": 72.4, "worst_ms": 21.0, "over": 0, "draws": 131, "primitives": 410000, "objects": 90,
		"process_ms": 6.2, "physics_ms": 1.1, "gpu_ms": 9.8}, {"world": 1, "preset": true, "renderer": "mobile"})
	assert_true(l.begins_with("VR_BENCH "))
	for part: String in ["fps=72.4", "worst_ms=21.0", "over28=0", "draws=131", "primitives=410000", "process_ms=6.20",
			"gpu_ms=9.80", "renderer=mobile"]:
		assert_string_contains(l, part)
