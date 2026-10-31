extends GutTest
## Owner #101 (VR on the Meta Quest, P2; the research's acceptance: "no text under 22 px on the eye panel", the plan's
## 24): the readability audit of the screens a child reads in a headset, each made in the VR canvas as its own tests make
## it (tools/vr_ui_screens.gd: the School's map, a unit and a round; the Mission Board's MISSIONS, MY ROCKET with BUILD
## IT FOR ME, PARTS and the buy card; the Gold Shop; Gemma's board; the inventions book; the Star Map; the Secret Book;
## MY MAP; the Shorts feed and maker; the chat; SETTINGS' VR COMFORT). On each, no word is drawn under 24 px (the
## canvas's scale counted) and the screen fits the 1280 × 720 canvas. Words drawn inside the School's pictures (a
## diagram's labels, drawn with draw_string) are the pictures' own: tools/vr_ui_shots.gd shows them.

const SCREENS := preload("res://tools/vr_ui_screens.gd")

var _old_pad: PadFocus
var _profile: ProfileData


class Owner:
	extends Node


func before_each() -> void:
	_old_pad = PadFocus.instance
	PadFocus.instance = null
	_profile = Profile.data
	Profile.data = ProfileData.new()
	Profile.data.username = "Mia"
	Profile.data.age_band = AgeBand.TEEN_PLUS
	Vr.simulate(true)


func after_each() -> void:
	Vr.simulate(false)
	get_tree().paused = false
	Profile.data = _profile
	PadFocus.instance = _old_pad
	Curriculum.clear_cache()
	SpendRules.clear_extra()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _in_canvas() -> Control:
	var o := Owner.new()
	add_child_autofree(o)
	var layer := CanvasLayer.new()
	var holder := Control.new()
	holder.name = "Screen"
	holder.theme = UiKit.theme()
	holder.size = Vector2(VrPanelRules.CANVAS)
	layer.add_child(holder)
	UiLayers.route(layer, o)
	return holder


func _audit(screen_name: String) -> void:
	var holder := _in_canvas()
	var screen: Control = SCREENS.build(screen_name, holder)
	assert_not_null(screen, screen_name)
	if screen == null:
		return
	await _frames(1)
	SCREENS.open(screen_name, screen)
	await _frames(2)
	if screen_name == "shorts_maker":
		var v := screen as ShortsView
		v.filter_buttons[ShortFeed.MINE].pressed.emit()
		await _frames(1)
		v.make_big.pressed.emit()
		await _frames(2)
	await get_tree().create_timer(0.3).timeout   # every panel's pop-in has settled
	await _frames(2)
	var small := VrReadability.too_small(holder)
	assert_eq(small, [] as Array[String], "%s: every word 24 px or more on the eye panel" % screen_name)
	var root: Control = SCREENS.root_of(screen)
	var need := root.get_combined_minimum_size()
	gut.p("VR_AUDIT %s: needs %s, %d words checked" % [screen_name, need, _words(holder)])
	assert_lte(need.x, float(VrPanelRules.CANVAS.x), "%s fits the canvas's width" % screen_name)
	assert_lte(need.y, float(VrPanelRules.CANVAS.y), "%s fits the canvas's height" % screen_name)
	var out: Array[String] = []
	_outside(holder, out)
	assert_eq(out, [] as Array[String], "%s: no words past the panel's edge (a scroll's own aside)" % screen_name)
	var cut: Array[String] = []
	_clipped(holder, cut)
	assert_eq(cut, [] as Array[String], "%s: no lifted word cut off by its box" % screen_name)


## One-line words their box cuts off (clip_text, or no room on a label that will not wrap).
func _clipped(n: Node, out: Array[String]) -> void:
	if n.has_meta(VrReadability.PICTURE):
		return
	var c := n as Control
	if c != null and not c.is_visible_in_tree():
		return
	var l := n as Label
	if l != null and l.text != "" and l.autowrap_mode == TextServer.AUTOWRAP_OFF and l.clip_text \
			and l.text_overrun_behavior == TextServer.OVERRUN_NO_TRIMMING and not l.text.contains("\n"):
		var w := l.get_theme_font("font").get_string_size(l.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			l.get_theme_font_size("font_size")).x
		if w > l.size.x + 1.0:
			out.append("%s '%s' %.0f px in %.0f" % [l.name, l.text, w, l.size.x])
	for child in n.get_children():
		_clipped(child, out)


## Visible words drawn past the canvas's edge (not inside a scroll, which brings them in; not in a picture).
func _outside(n: Node, out: Array[String]) -> void:
	if n is ScrollContainer or n.has_meta(VrReadability.PICTURE):
		return
	var c := n as Control
	if c != null and not c.is_visible_in_tree():
		return
	if c != null and VrReadability.is_text(c) and VrReadability._words(c) != "":
		var t := c.get_global_transform()
		var r := Rect2(t.origin, c.size * t.get_scale())
		if not Rect2(Vector2.ZERO, Vector2(VrPanelRules.CANVAS)).grow(1.0).encloses(r):
			out.append("%s '%s' %s" % [c.name, VrReadability._words(c).left(24), r])
	for child in n.get_children():
		_outside(child, out)


func _words(n: Node) -> int:
	var count := 0
	if n is Control and VrReadability.is_text(n as Control) and (n as Control).is_visible_in_tree():
		count += 1
	for c in n.get_children():
		count += _words(c)
	return count


func test_the_schools_pages() -> void:
	for n: String in ["school_map", "school_unit", "school_round"]:
		await _audit(n)


func test_the_mission_boards_pages_and_its_buy_card() -> void:
	for n: String in ["board_missions", "board_rocket", "board_parts", "board_buy"]:
		await _audit(n)


func test_the_gold_shop_gemmas_board_and_the_inventions_book() -> void:
	for n: String in ["gold_shop", "gemma", "inventions"]:
		await _audit(n)


func test_the_star_map_the_secret_book_and_my_map() -> void:
	for n: String in ["star_map", "secret_book", "my_map"]:
		await _audit(n)


func test_the_shorts_the_maker_and_the_chat() -> void:
	for n: String in ["shorts_feed", "shorts_maker", "chat"]:
		await _audit(n)


func test_vr_comfort() -> void:
	await _audit("settings_vr")


func test_the_account_screens_and_the_moon_landings_dashboard() -> void:
	for n: String in ["log_in", "password_make", "logged_out", "cockpit_descent"]:
		await _audit(n)


func test_the_school_maps_tiles_keep_their_words_inside() -> void:
	var holder := _in_canvas()
	var screen: Control = SCREENS.build("school_map", holder)
	await _frames(1)
	SCREENS.open("school_map", screen)
	await get_tree().create_timer(0.3).timeout
	await _frames(2)
	var stops := screen.find_children("Stop_*", "UnitStop", true, false)
	assert_gt(stops.size(), 3)
	for s: Node in stops:
		var tile := s as Control
		for c: Node in tile.get_children():
			if c is VBoxContainer:
				var inner := (c as Control).get_global_rect()
				assert_true(tile.get_global_rect().grow(1.0).encloses(inner), "%s: its title and stars inside the tile (%s in %s)" % [
					tile.name, inner, tile.get_global_rect()])
