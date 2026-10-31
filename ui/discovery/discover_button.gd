class_name DiscoverButton
extends Button
## Owner #132 (W1): DISCOVER as a picture (owner #133: no child has to read): HudIcons' magnifying glass with its
## sparkle, big, and the one word under it, on the School's teal. Its word is spoken when a pointer (a mouse, the
## headset's laser) or a game controller's focus comes to it. Hoot's card and the pause menu show it; MORE has the HUD's
## own TouchButton with the same picture (DiscoveryDirector.more_button).

const COLOUR := Color("139e9b")   # the menu's SCHOOL button's teal

## The picture over the word.
var picture: Picture


## The magnifying glass, drawn in code (HudIcons' "discover").
class Picture:
	extends Control
	var symbol := &"discover"

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var side := minf(size.x, size.y)
		HudIcons.draw(self, symbol, Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side)))


## A DISCOVER picture button `min_size` big; `word_size` is the word's font size.
static func make(min_size: Vector2, word_size: int = 22) -> DiscoverButton:
	var b := DiscoverButton.new()
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", word_size)
	var top := min_size.y * 0.62   # the picture's band; the word sits under it
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var box := UiKit.box(COLOUR.lightened(0.12) if state == "hover" else COLOUR.darkened(0.15) if state == "pressed"
			else COLOUR)
		box.content_margin_top = top
		box.content_margin_bottom = 6
		if state == "focus":
			box.draw_center = false
		b.add_theme_stylebox_override(state, box)
	b.picture.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	b.picture.offset_top = 8
	b.picture.offset_bottom = top - 2
	return b


func _init() -> void:
	name = "Discover"
	text = DiscoveryRules.DISCOVER_LABEL
	picture = Picture.new()
	picture.name = "Picture"
	add_child(picture)
	UiMotion.squash_on_press(self)
	mouse_entered.connect(_say)
	focus_entered.connect(_say)


func _say() -> void:
	PlayVoice.say(DiscoveryRules.DISCOVER_WORD)
