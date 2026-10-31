class_name UiKit
extends RefCounted
## Shared look for menus: big rounded buttons and outlined text that read well on phones.

const GREEN := Color("2fae4e")
const ORANGE := Color("f08a1c")
const BLUE := Color("3a7be8")
const RED := Color("d9463b")
const DARK := Color(0.08, 0.1, 0.17, 0.9)
## Owner #90: the game controller's focus ring (PadFocus draws it over every screen while a pad is used; the theme's own
## "focus" stays empty, so the mouse and fingers never see a ring).
const FOCUS := Color("ffe14d")

static var _theme: Theme


static func theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font_size = 30
	t.set_stylebox("normal", "Button", box(Color(0.16, 0.2, 0.32, 0.95)))
	t.set_stylebox("hover", "Button", box(Color(0.22, 0.28, 0.44, 0.97)))
	t.set_stylebox("pressed", "Button", box(Color(0.32, 0.4, 0.6, 1.0)))
	t.set_stylebox("disabled", "Button", box(Color(0.22, 0.22, 0.26, 0.75)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(0.75, 0.75, 0.78))
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.8))
	t.set_constant("outline_size", "Label", 6)
	t.set_stylebox("panel", "PanelContainer", box(DARK, 26, 28))
	t.set_stylebox("normal", "LineEdit", box(Color(1, 1, 1, 0.95), 14, 14))
	t.set_stylebox("focus", "LineEdit", box(Color(1, 1, 1, 1), 14, 14))
	t.set_color("font_color", "LineEdit", Color(0.1, 0.1, 0.15))
	t.set_font_size("font_size", "LineEdit", 36)
	add_script_fallbacks()   # owner 49: Georgian letters
	_theme = t
	return t


static func box(color: Color, radius: int = 18, margin: int = 16) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = color
	b.set_corner_radius_all(radius)
	b.set_content_margin_all(margin)
	b.border_color = color.darkened(0.35)
	b.border_width_bottom = 5
	return b


## A big button. It clicks when pressed like every button (Audio, the audio pass; a toggle softer), and squashes and
## springs back (owner #94: UiMotion, the one motion helper: pop_in for panels, fly for gold and stars, burst, glow).
static func big_button(text: String, color: Color = Color(), min_size: Vector2 = Vector2(360, 96)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	UiMotion.squash_on_press(b)
	if color != Color():
		b.add_theme_stylebox_override("normal", box(color))
		b.add_theme_stylebox_override("hover", box(color.lightened(0.12)))
		b.add_theme_stylebox_override("pressed", box(color.darkened(0.15)))
	return b


## Owner #90: the focus ring's look: a thick bright yellow rounded frame, nothing inside (PadFocus.PadRing).
static func focus_ring() -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.draw_center = false
	b.border_color = FOCUS
	b.set_border_width_all(5)
	b.set_corner_radius_all(22)
	b.anti_aliasing = true
	return b


## The ring's dark edge, so it shows on yellow, white and bright buttons too.
static func focus_shadow() -> StyleBoxFlat:
	var b := focus_ring()
	b.border_color = Color(0.05, 0.06, 0.12, 0.7)
	b.set_border_width_all(9)
	b.set_corner_radius_all(24)
	return b


static func title(text: String, size: int = 46) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_constant_override("outline_size", 10)
	return l


# --- Owner 49: letters the built-in font lacks come from the device's own font ---------------------------

## Scripts children type that the engine's built-in font (Open Sans, which every Label, LineEdit, Button and
## name tag draws with; the game has no font of its own) has no letters for: the language, every letter, and
## the files Android keeps its font in (Noto Sans Georgian; the name changed over the years). The device's
## font is used, never a bundled one (CC0-only rule: Noto is OFL).
const SCRIPT_FONTS := {
	&"Geor": {"lang": "ka", "letters": "აბგდევზთიკლმნოპჟრსტუფქღყშჩცძწჭხჯჰ",
		"files": ["/system/fonts/NotoSansGeorgian-VF.ttf", "/system/fonts/NotoSansGeorgian-Regular.otf",
			"/system/fonts/NotoSansGeorgian-Regular.ttf", "/system/fonts/NotoSansGeorgian.ttf"]},
}

## Script -> the device's font file its letters come from ("" when none was found; the engine's own
## lookup of system fonts is then all there is).
static var script_font_paths := {}


## Once: the device's font for each of SCRIPT_FONTS joins the fallbacks of the engine's default font, so its
## letters never depend on the engine's automatic system-font lookup alone (on Android that reads only
## /system/etc/fonts.xml, which Android 15 deprecates). Found through the OS's own list of fonts for that
## text, else by Android's file names, and kept only if it has every letter.
static func add_script_fallbacks() -> void:
	var base := ThemeDB.fallback_font
	if base == null or not script_font_paths.is_empty():
		return
	var list: Array[Font] = []
	list.assign(base.fallbacks)
	for script: StringName in SCRIPT_FONTS:
		var spec: Dictionary = SCRIPT_FONTS[script]
		script_font_paths[script] = ""
		if covers(base, spec.letters):
			continue
		var paths := OS.get_system_font_path_for_text(base.get_font_name(), spec.letters, spec.lang, String(script),
			base.get_font_weight())
		paths.append_array(spec.files)
		for path in paths:
			var font := _device_font(path, spec.letters, base)
			if font:
				script_font_paths[script] = path
				list.append(font)
				break
	base.fallbacks = list


## True when `font` (or its fallbacks) has a glyph for every character of `text`.
static func covers(font: Font, text: String) -> bool:
	for ch in text:
		if not font.has_char(ch.unicode_at(0)):
			return false
	return true


## The font file at `path` drawn like `base` (the same weight on a variable font, the same rendering), or
## null when it is missing or lacks some of `letters`.
static func _device_font(path: String, letters: String, base: Font) -> Font:
	if not path.is_absolute_path() or not FileAccess.file_exists(path):
		return null
	var file := FontFile.new()
	if file.load_dynamic_font(path) != OK or not covers(file, letters):
		return null
	if base is FontFile:
		var b := base as FontFile
		file.antialiasing = b.antialiasing
		file.hinting = b.hinting
		file.subpixel_positioning = b.subpixel_positioning
		file.multichannel_signed_distance_field = b.multichannel_signed_distance_field
		file.generate_mipmaps = b.generate_mipmaps
	var wght := TextServerManager.get_primary_interface().name_to_tag("wght")
	if not file.get_supported_variation_list().has(wght):
		return file
	var weighted := FontVariation.new()   # Android's Noto Sans Georgian is one variable font
	weighted.base_font = file
	weighted.variation_opentype = {wght: base.get_font_weight()}
	return weighted
