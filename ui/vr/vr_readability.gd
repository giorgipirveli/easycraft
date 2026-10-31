class_name VrReadability
extends RefCounted
## VR on the Meta Quest (owner #101, P2: the readability pass; docs/devlog/parts/vr-research.md "Text readability"): the
## eye panel is 1.4 m away at about 21 canvas pixels a degree, so a word under 24 px (about 1.1°) is too small to read
## in a headset, and white letters on the game's bright buttons (green 2.9:1, orange 2.6:1) are too faint. While VR runs,
## every text control in the VR canvas is drawn at MIN_PX or more (its own size kept and put back when VR ends; a size
## its screen sets again later is lifted again: watch), and buttons with light words get the labels' dark outline, so
## their letters' edges stand out on any colour (dark ink on a light button keeps none). A picture's own words (a
## Short's stage: PICTURE) keep their size. Nothing changes off VR. `too_small` lists what is still under MIN_PX as
## drawn (the canvas's scale counted): the audit's check (tests/integration/test_vr_ui_audit.gd).

const MIN_PX := 24
## Meta's and WCAG's floor for text against its background.
const MIN_CONTRAST := 4.5
## The labels' outline (UiKit.theme), given to buttons in VR.
const OUTLINE_PX := 6
const OUTLINE_COLOR := Color(0, 0, 0, 0.8)
## Meta: the control's own font size override before VR lifted it (-1: it had none).
const KEPT := &"vr_font_kept"
## Meta: the callable that watches a text control's theme (its screen may size its words again later).
const WATCHED := &"vr_font_watched"
## Meta: VR gave this button's light words the dark outline (taken off again when VR ends).
const OUTLINED := &"vr_outlined"
## Words this light or lighter get the outline (white, yellow; never the books' dark ink on paper).
const LIGHT := 0.45
## Meta on a node whose words are part of a picture drawn for its own size (a Short's stage): left as they are.
const PICTURE := &"vr_picture"


## The font size a control draws its words at (a RichTextLabel's normal text; a TouchButton's word), before any scale.
static func font_px(c: Control) -> int:
	if c is RichTextLabel:
		return c.get_theme_font_size(&"normal_font_size")
	if c is TouchButton:
		return (c as TouchButton).font_size
	return c.get_theme_font_size(&"font_size")


## A control that draws words.
static func is_text(c: Control) -> bool:
	return c is Label or c is Button or c is LinkButton or c is LineEdit or c is TextEdit or c is RichTextLabel \
		or c is TabBar or c is TouchButton


## The size the words show at on the canvas: the font size times the control's drawn scale (a menu panel too tall for the
## screen is drawn smaller).
static func drawn_px(c: Control) -> float:
	var s := c.get_global_transform().get_scale()
	return font_px(c) * minf(absf(s.x), absf(s.y))


## Lifts one control's words to MIN_PX (keeping its own size to put back), and watches it: a screen that sizes its words
## again later (a map's labels as it lays out) is lifted again (relift).
static func lift(c: Control) -> bool:
	if not is_text(c) or in_picture(c):
		return false
	watch(c)
	outline(c)
	if c.has_meta(KEPT) or font_px(c) >= MIN_PX:
		return false
	if c is TouchButton:
		c.set_meta(KEPT, (c as TouchButton).font_size)
		(c as TouchButton).font_size = MIN_PX
		c.queue_redraw()
		return true
	var item := &"normal_font_size" if c is RichTextLabel else &"font_size"
	c.set_meta(KEPT, c.get_theme_font_size(item) if c.has_theme_font_size_override(item) else -1)
	c.add_theme_font_size_override(item, MIN_PX)
	return true


## A button whose words are light and have no outline gets the labels' dark one (white on the game's green is 2.9:1).
static func outline(c: Control) -> void:
	if not (c is Button) or c.has_meta(OUTLINED) or c.get_theme_constant(&"outline_size") > 0:
		return
	if _luminance(c.get_theme_color(&"font_color")) < LIGHT:
		return
	c.set_meta(OUTLINED, true)
	c.add_theme_constant_override(&"outline_size", OUTLINE_PX)
	c.add_theme_color_override(&"font_outline_color", OUTLINE_COLOR)


## `c` is inside a picture (PICTURE): its words keep their own size.
static func in_picture(c: Node) -> bool:
	var n := c
	while n != null:
		if n.has_meta(PICTURE):
			return true
		n = n.get_parent()
	return false


## Watches `c`'s theme while VR runs (an override set on it later comes through theme_changed).
static func watch(c: Control) -> void:
	if c.has_meta(WATCHED) or c is TouchButton:
		return
	var w: WeakRef = weakref(c)
	var cb := func() -> void: VrReadability.relift(w)
	c.set_meta(WATCHED, cb)
	c.theme_changed.connect(cb)


## A watched control's theme changed: its screen gave it a size under MIN_PX again; that becomes its own size (put back
## when VR ends) and it is drawn at MIN_PX.
static func relift(w: WeakRef) -> void:
	var c := w.get_ref() as Control
	if c == null or not Vr.active() or font_px(c) >= MIN_PX:
		return
	var item := &"normal_font_size" if c is RichTextLabel else &"font_size"
	if c.has_meta(KEPT):
		c.set_meta(KEPT, c.get_theme_font_size(item) if c.has_theme_font_size_override(item) else -1)
		c.add_theme_font_size_override(item, MIN_PX)
	else:
		lift(c)


## Puts one control's own size back (and stops watching it).
static func restore(c: Control) -> void:
	if c.has_meta(WATCHED):
		var cb: Callable = c.get_meta(WATCHED)
		c.remove_meta(WATCHED)
		if c.theme_changed.is_connected(cb):
			c.theme_changed.disconnect(cb)
	if c.has_meta(OUTLINED):
		c.remove_meta(OUTLINED)
		c.remove_theme_constant_override(&"outline_size")
		c.remove_theme_color_override(&"font_outline_color")
	if not c.has_meta(KEPT):
		return
	var kept := int(c.get_meta(KEPT))
	c.remove_meta(KEPT)
	if c is TouchButton:
		(c as TouchButton).font_size = kept
		c.queue_redraw()
		return
	var item := &"normal_font_size" if c is RichTextLabel else &"font_size"
	if kept < 0:
		c.remove_theme_font_size_override(item)
	else:
		c.add_theme_font_size_override(item, kept)


## Lifts every text control under `n` (and `n`); how many were lifted.
static func lift_tree(n: Node) -> int:
	var count := 0
	if n is Control and lift(n as Control):
		count += 1
	for child in n.get_children():
		count += lift_tree(child)
	return count


static func restore_tree(n: Node) -> void:
	if n is Control:
		restore(n as Control)
	for child in n.get_children():
		restore_tree(child)


## The visible text controls under `root` drawn under MIN_PX (with words in them), as "name 'text' 20px".
static func too_small(root: Node) -> Array[String]:
	var out: Array[String] = []
	_find_small(root, out)
	return out


static func _find_small(n: Node, out: Array[String]) -> void:
	var c := n as Control
	if n.has_meta(PICTURE):
		return
	if c != null:
		if not c.is_visible_in_tree():
			return
		if is_text(c) and _words(c) != "" and drawn_px(c) < MIN_PX - 0.01:
			out.append("%s (in %s) '%s' %.1fpx" % [c.name, c.get_parent().name, _words(c).left(30).replace("\n", " "), drawn_px(c)])
	for child in n.get_children():
		_find_small(child, out)


static func _words(c: Control) -> String:
	if c is RichTextLabel:
		return (c as RichTextLabel).get_parsed_text()
	var t: Variant = c.get("text")
	if t == null or str(t) == "":
		t = c.get("placeholder_text")
	return str(t) if t != null else ""


## The contrast ratio of two colours (WCAG 2: 1 to 21), alpha ignored.
static func contrast(a: Color, b: Color) -> float:
	var la := _luminance(a)
	var lb := _luminance(b)
	return (maxf(la, lb) + 0.05) / (minf(la, lb) + 0.05)


static func _luminance(c: Color) -> float:
	var ch := func(v: float) -> float: return v / 12.92 if v <= 0.03928 else pow((v + 0.055) / 1.055, 2.4)
	return 0.2126 * ch.call(c.r) + 0.7152 * ch.call(c.g) + 0.0722 * ch.call(c.b)
