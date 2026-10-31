extends GutTest
## Owner feedback #43 (spec §3c): the main menu's title is EasyCraft's own wordmark (bubble-block letters from
## tools/make_brand_art.py), not the name typed in capitals in the engine's font.

const WORDMARK := "res://assets/brand/wordmark.png"

var menu: Node


func before_each() -> void:
	menu = load("res://ui/menus/menu.tscn").instantiate()
	add_child_autofree(menu)
	await wait_frames(3)


func test_the_title_is_the_wordmark_picture() -> void:
	var logo: Variant = menu.get("_logo")
	assert_true(logo is TextureRect, "the title is a picture")
	if not logo is TextureRect:
		return
	var rect := logo as TextureRect
	assert_not_null(rect.texture)
	assert_eq(rect.texture.resource_path, WORDMARK)
	assert_true(rect.is_visible_in_tree())
	# Drawn at about the old title's size, at the top of the 1280 x 720 screen, fully on it.
	var r := rect.get_global_rect()
	assert_between(r.size.y, 90.0, 140.0, "its height: %s" % r.size)
	assert_true(Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(r), "on the screen: %s" % r)
	assert_lt(r.end.y, 150.0, "above the menu's buttons (they start 130 px down)")


func test_no_label_spells_the_name_in_capitals() -> void:
	for l in menu.find_children("*", "Label", true, false):
		assert_false((l as Label).text == "EASYCRAFT", "the old typed title is gone")


## Owner 2026-09-28: "under the name of the game, when it starts, add Made by Alexander Pirveli" (also on the web
## start page, web/shell.html).
func test_the_credit_sits_under_the_name() -> void:
	var credit: Label = null
	for l in menu.find_children("*", "Label", true, false):
		if (l as Label).text == "Made by Alexander Pirveli":
			credit = l
	assert_not_null(credit, "the credit line")
	if credit == null:
		return
	assert_true(credit.is_visible_in_tree())
	var logo := menu.get("_logo") as TextureRect
	var c := credit.get_global_rect()
	var r := logo.get_global_rect()
	assert_between(c.position.y, r.end.y - 16.0, r.end.y + 24.0, "right under the wordmark: %s / %s" % [c, r])
	assert_almost_eq(c.get_center().x, r.get_center().x, 40.0, "centred under it")
	assert_true(Rect2(Vector2.ZERO, Vector2(1280, 720)).encloses(c), "on the screen: %s" % c)
	assert_eq(credit.mouse_filter, Control.MOUSE_FILTER_IGNORE, "never takes a tap")
