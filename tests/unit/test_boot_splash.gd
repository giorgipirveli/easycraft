extends GutTest
## Owner feedback #43 (spec §3c): while a slow phone loads the game (up to 25 s), it shows EasyCraft's own
## splash, the buddy mark and the wordmark on our teal, never Godot's logo on grey; the launcher icon is the
## buddy mark, never a lone grass block. The pictures are made by tools/make_brand_art.py (our own work).

const SPLASH := "res://assets/brand/splash.png"
const ICON := "res://icon.png"
const TEAL := Color("139e9b")
## Godot's own boot splash: its logo (no image set) on this grey.
const GODOT_GREY := Color(0.14, 0.14, 0.14)
const MAX_SPLASH_BYTES := 80 * 1024


func test_the_boot_splash_is_ours_not_godots() -> void:
	assert_true(ProjectSettings.get_setting("application/boot_splash/show_image"), "an image is shown")
	assert_eq(ProjectSettings.get_setting("application/boot_splash/image"), SPLASH,
		"our splash, not Godot's built-in logo (an empty image)")
	var bg: Color = ProjectSettings.get_setting("application/boot_splash/bg_color")
	assert_false(bg.is_equal_approx(GODOT_GREY), "not Godot's grey")
	assert_true(bg.is_equal_approx(TEAL), "our teal: %s" % bg.to_html(false))


func test_the_splash_is_a_small_picture_drawn_at_its_own_size() -> void:
	assert_true(FileAccess.file_exists(SPLASH))
	var bytes := FileAccess.get_file_as_bytes(SPLASH)
	assert_gt(bytes.size(), 0)
	assert_lt(bytes.size(), MAX_SPLASH_BYTES, "small for the APK")
	var img := Image.new()
	assert_eq(img.load_png_from_buffer(bytes), OK)
	assert_between(img.get_width(), 400, 1024)
	assert_lt(img.get_height(), img.get_width(), "a wide mark: the phone is held sideways")
	assert_eq(img.get_pixel(0, 0).a, 0.0, "transparent round it: the splash colour shows")
	# Drawn at its own size (never stretched blurry over a 2400 x 1080 screen).
	assert_eq(ProjectSettings.get_setting("application/boot_splash/stretch_mode"), 0)


func test_the_splash_is_exported_once_as_it_is() -> void:
	# Godot's exporter always stores the boot splash (and the icon) raw, outside the import system. With the
	# "keep" importer the raw file went in a second time, and apksigner refused the 0.4.0 APK ("Multiple ZIP
	# entries with the same name: assets/assets/brand/splash.png"). Imported as a texture, like icon.png: the
	# exporter's raw copy is the only file at that path.
	var cfg := ConfigFile.new()
	assert_eq(cfg.load(SPLASH + ".import"), OK)
	assert_eq(cfg.get_value("remap", "importer"), "texture")


## Presets that export a pack of chosen files for a game already running, not a game (M7: the browser's background
## music, the REALISTIC style's pictures and the game's media, each in its texture format, tools/export_web.sh): no
## splash in them.
const CONTENT_PACK_PRESETS := ["Web Music", "Web Realistic", "Web Realistic Mobile", "Web Assets", "Web Assets Mobile",
	"Web Reels"]


func test_every_game_preset_carries_the_splash() -> void:
	var presets := ConfigFile.new()
	assert_eq(presets.load("res://export_presets.cfg"), OK)
	var checked := 0
	var packs := 0
	for section in presets.get_sections():
		if not section.begins_with("preset.") or section.ends_with(".options"):
			continue
		if presets.get_value(section, "name") in CONTENT_PACK_PRESETS:
			packs += 1
			continue
		assert_eq(presets.get_value(section, "export_filter"), "all_resources", section)
		for f in str(presets.get_value(section, "exclude_filter", "")).split(",", false):
			var pattern := f.strip_edges()
			assert_false(SPLASH.trim_prefix("res://").match(pattern) or SPLASH.match(pattern),
				"%s leaves the splash out (%s)" % [section, pattern])
		checked += 1
	assert_gt(checked, 3)
	assert_eq(packs, CONTENT_PACK_PRESETS.size(), "every content-pack preset named here exists")


func test_the_launcher_icon_is_the_buddy_mark_on_our_teal() -> void:
	assert_eq(ProjectSettings.get_setting("application/config/icon"), ICON)
	var img := Image.new()
	assert_eq(img.load_png_from_buffer(FileAccess.get_file_as_bytes(ICON)), OK)
	assert_eq(img.get_size(), Vector2i(512, 512))
	# Full bleed (the launcher rounds it), our teal in the corners, not a lone grass block on sky blue.
	for p: Vector2i in [Vector2i(4, 4), Vector2i(507, 4), Vector2i(4, 507), Vector2i(507, 507)]:
		var c := img.get_pixelv(p)
		assert_eq(c.a, 1.0, "full bleed at %s" % p)
		assert_almost_eq(c.h, TEAL.h, 0.06, "teal at %s" % p)
	# The buddy's orange fills the middle.
	var mid := img.get_pixel(256, 300)
	assert_almost_eq(mid.h, Color("ff8a34").h, 0.06, "the orange buddy in the middle: %s" % mid.to_html(false))
