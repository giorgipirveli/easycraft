extends GutTest
## M5 Task 3 (spec §15.3): the LOW graphics preset for weak phones: a short view (64 blocks), no shadows, half the
## particles, simpler water, fewer monsters and animals around each child. A phone with little memory or few cores
## starts on it (the first start only; the child can pick another in SETTINGS, and that choice stays).

const GIB := 1024 * 1024 * 1024

var _scale := 1.0
var _graphics := ""


func before_each() -> void:
	_scale = Fx.particle_scale
	_graphics = str(Profile.data.settings.graphics)


func after_each() -> void:
	Fx.particle_scale = _scale
	Profile.data.settings.graphics = _graphics
	BlockLibrary.set_simple_water(false)


func test_low_is_the_light_preset() -> void:
	var low := GraphicsPreset.params("low")
	assert_false(low.shadows, "no shadows")
	assert_eq(low.view_max, 64, "a short view")
	assert_eq(low.particles, 0.5, "half the particles")
	assert_true(low.simple_water, "simpler water")
	assert_eq(low.monsters_near, 6, "at most 6 monsters near a child (every one within 32 blocks among them)")
	assert_eq(low.animals_near, 12, "fewer animals around a child")
	for p: String in ["medium", "high"]:
		var d := GraphicsPreset.params(p)
		assert_eq(d.view_max, GraphicsPreset.MAX_VIEW_DISTANCE, p)
		assert_eq(d.particles, 1.0, p)
		assert_false(d.simple_water, p)
		assert_eq(d.monsters_near, 0, "%s: no cap of the phone's own (the game's caps)" % p)
		assert_eq(d.animals_near, 0, p)


func test_the_view_distance_on_low_is_at_most_64_blocks() -> void:
	assert_eq(GraphicsPreset.view_distance({"graphics": "low", "view_distance": 160}), 64)
	assert_eq(GraphicsPreset.view_distance({"graphics": "low", "view_distance": 64}), 64)
	assert_eq(GraphicsPreset.view_distance({"graphics": "medium", "view_distance": 160}), 160)
	assert_eq(GraphicsPreset.view_distance({"graphics": "high", "view_distance": 9999}), GraphicsPreset.MAX_VIEW_DISTANCE)
	assert_eq(GraphicsPreset.view_distance({"graphics": "medium", "view_distance": 10}), GraphicsPreset.MIN_VIEW_DISTANCE)
	assert_eq(GraphicsPreset.view_distance({}), 128, "an old profile: medium, 128")


func test_a_weak_phone_starts_on_low() -> void:
	assert_eq(GraphicsPreset.for_device(2 * GIB, 8), "low", "2 GB (a cheap phone or tablet)")
	assert_eq(GraphicsPreset.for_device(int(2.8 * GIB), 8), "low", "3 GB")
	assert_eq(GraphicsPreset.for_device(int(3.7 * GIB), 8), "medium", "4 GB")
	assert_eq(GraphicsPreset.for_device(8 * GIB, 8), "medium")
	assert_eq(GraphicsPreset.for_device(6 * GIB, 4), "low", "four cores or fewer")
	assert_eq(GraphicsPreset.for_device(-1, 8), "medium", "memory unknown: the cores decide")
	assert_eq(GraphicsPreset.for_device(0, 0), "medium", "nothing known: medium, as before")
	assert_eq(GraphicsPreset.for_device(64 * GIB, 32), "medium", "never high by itself")


func test_a_new_profile_takes_the_phones_preset_and_a_saved_choice_stays() -> void:
	assert_eq(ProfileData.first_start(2 * GIB, 8).settings.graphics, "low")
	assert_eq(ProfileData.first_start(8 * GIB, 8).settings.graphics, "medium")
	assert_eq(ProfileData.first_start(8 * GIB, 8).settings.view_distance, 128, "everything else as a new profile")
	var picked := ProfileData.first_start(2 * GIB, 8)
	picked.settings.graphics = "high"   # the child picked HIGH in SETTINGS
	assert_eq(ProfileData.from_json(picked.to_json()).settings.graphics, "high", "a saved choice is never changed")


## M7 (spec §20.3): phones and tablets in a browser start on LOW whatever they report (a browser tells little about
## the phone, and the web build runs slower than the app); the child can raise it, and that choice stays.
func test_a_new_profile_in_a_phone_browser_starts_on_low() -> void:
	assert_eq(ProfileData.first_start(8 * GIB, 8, true).settings.graphics, "low", "a strong phone in a browser")
	assert_eq(ProfileData.first_start(8 * GIB, 8, false).settings.graphics, "medium", "elsewhere the device decides")
	var raised := ProfileData.first_start(8 * GIB, 8, true)
	raised.settings.graphics = "medium"   # the child raised it in SETTINGS
	assert_eq(ProfileData.from_json(raised.to_json()).settings.graphics, "medium", "a saved choice is never changed")


func test_low_bursts_have_half_the_particles() -> void:
	var parent := Node3D.new()
	add_child_autofree(parent)
	Fx.particle_scale = 1.0
	assert_eq(Fx.burst(parent, Vector3.ZERO, Color.WHITE, 14).amount, 14)
	Fx.particle_scale = 0.5
	assert_eq(Fx.burst(parent, Vector3.ZERO, Color.WHITE, 14).amount, 7)
	assert_eq(Fx.burst(parent, Vector3.ZERO, Color.WHITE, 1).amount, 1, "never none")
	assert_eq(Fx.scaled(16), 8)


func test_the_settings_set_the_particles() -> void:
	Profile.data.settings.graphics = "low"
	Game.apply_settings()
	assert_eq(Fx.particle_scale, 0.5)
	Profile.data.settings.graphics = "medium"
	Game.apply_settings()
	assert_eq(Fx.particle_scale, 1.0)


func test_simple_water_is_one_uniform_of_the_shared_water_material() -> void:
	var lib := BlockLibrary.build()
	var water := lib.models[BlockIds.WATER].get_material_override(0) as ShaderMaterial
	BlockLibrary.set_simple_water(true)
	assert_eq(water.get_shader_parameter("simple"), true)
	BlockLibrary.set_simple_water(false)
	assert_eq(water.get_shader_parameter("simple"), false)


func test_low_caps_the_monsters_near_a_child() -> void:
	var d := MonsterDirector.new()
	autofree(d)
	assert_eq(d._budget(0, 5), 5, "medium: up to 10 near a child")
	d.apply_preset("low")
	assert_eq(d._budget(0, 5), 1, "low: up to 6")
	assert_eq(d._budget(0, 6), 0)
	d.per_player_cap = SurvivorGames.BUILD_PER_PLAYER   # Build to Survive brings more, but not on a weak phone
	assert_eq(d._budget(0, 6), 0)
	d.apply_preset("medium")
	assert_eq(d._budget(0, 6), SurvivorGames.BUILD_PER_PLAYER - 6)


func test_low_brings_fewer_animals() -> void:
	var d := AnimalDirector.new()
	autofree(d)
	assert_eq(d.spawn_budget(10), AnimalRules.MAX_PER_PLAYER - 10)
	d.apply_preset("low")
	assert_eq(d.spawn_budget(10), 2)
	assert_eq(d.spawn_budget(12), 0)
	d.apply_preset("high")
	assert_eq(d.spawn_budget(10), AnimalRules.MAX_PER_PLAYER - 10)


## Merging M5 T1 (Reduce motion halves a burst) and M5 T3 (LOW halves particles) on 2026-09-25: Fx.calm set the burst
## back to its unscaled amount, so LOW lost its half. Both apply now, and the coin shower is not scaled twice.
func test_low_and_reduce_motion_both_calm_a_burst() -> void:
	var parent := Node3D.new()
	add_child_autofree(parent)
	var reduce_before: Variant = Profile.data.settings.get("reduce_motion", false)
	Profile.data.settings.reduce_motion = true
	Fx.particle_scale = 0.5
	var b := Fx.burst(parent, Vector3.ZERO, Color.WHITE, 16)
	var coins := Fx.coin_shower(parent, Vector3.ZERO, 0)
	Profile.data.settings.reduce_motion = reduce_before
	Fx.particle_scale = 1.0
	assert_eq(b.amount, FeelRules.burst_amount(8, true), "LOW's half, then Reduce motion's half")
	var coins_on_low := maxi(roundi(Fx.COIN_SHOWER_MIN * 0.5), 1)
	assert_eq(coins.amount, FeelRules.burst_amount(coins_on_low, true), "the coin shower scaled once")
