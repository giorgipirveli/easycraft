class_name TextSize
extends RefCounted
## TEXT SIZE (M5 Task 1, spec §15.1a): NORMAL or BIG (×1.25) for the words a child reads while playing: toasts,
## banners, first-time picture hints, notes and riddles, the knock-out words, the chat's lines and bar, the name.
## Menus keep their size (their buttons are big already and every page must fit 720 px).
## A control marked here keeps its NORMAL size and gets the chosen one; refresh() applies a new choice to every
## marked control in the tree (the Hud calls it when the settings change).

const NORMAL := &"normal"
const BIG := &"big"
const STEPS: Array[StringName] = [NORMAL, BIG]
const FACTORS := {NORMAL: 1.0, BIG: 1.25}
const GROUP := &"text_size"
const BASE := &"text_size_base"
## Owner #101 (VR on the Meta Quest): in a headset the text size is its own choice (SETTINGS → VR COMFORT), BIG until the
## child picks NORMAL there (the panel is 1.4 m away; docs/devlog/parts/vr-research.md "Text readability").
const VR_KEY := "vr_text_size"
const VR_DEFAULT := "big"


## The factor the settings choose (1.0 for anything unknown); in a headset, its own choice.
static func factor(settings: Dictionary = Profile.data.settings) -> float:
	if Vr.active():
		return float(FACTORS.get(StringName(str(settings.get(VR_KEY, VR_DEFAULT))), FACTORS[BIG]))
	return float(FACTORS.get(StringName(str(settings.get("text_size", "normal"))), 1.0))


## A NORMAL font size at the chosen text size.
static func px(base: int) -> int:
	return roundi(base * factor())


## Gives `c` the chosen size of `base` and keeps `base` for later changes (a RichTextLabel's normal font, any other
## control's font).
static func mark(c: Control, base: int) -> void:
	c.set_meta(BASE, base)
	if not c.is_in_group(GROUP):
		c.add_to_group(GROUP)
	_apply(c)


## Every marked control in `tree` at the chosen size.
static func refresh(tree: SceneTree) -> void:
	for n in tree.get_nodes_in_group(GROUP):
		_apply(n as Control)


static func _apply(c: Control) -> void:
	if c == null or not c.has_meta(BASE):
		return
	var size := px(int(c.get_meta(BASE)))
	if c is RichTextLabel:
		c.add_theme_font_size_override("normal_font_size", size)
	else:
		c.add_theme_font_size_override("font_size", size)
