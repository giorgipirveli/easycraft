extends GutTest
## Owner #78: INVENT joins the MORE panel. With more than four rows of three buttons (a phone's Sandbox: the rare
## buttons, SHARE, QUESTS, MAP, DIG, INVENT, SHOP) the box takes a fourth column, so it never runs off a 720 px screen.

var more: MorePanel


func before_each() -> void:
	more = MorePanel.new()
	add_child_autofree(more)


func _fill(n: int) -> void:
	for i in n:
		var b := TouchButton.new()
		b.text = "B%d" % i
		more.add(b)


func test_twelve_buttons_stay_in_three_columns() -> void:
	_fill(12)
	more.open()
	assert_eq(more.grid.columns, MorePanel.COLUMNS)


func test_a_thirteenth_takes_a_fourth_column_and_fits_the_screen() -> void:
	_fill(13)
	more.open()
	assert_eq(more.grid.columns, MorePanel.COLUMNS + 1)
	await wait_frames(2)
	var rows := ceili(13.0 / more.grid.columns)
	var tall := rows * HudLayout.BUTTON + (rows - 1) * MorePanel.GAP + 2 * MorePanel.PAD
	assert_lte(118.0 + tall, 720.0, "from under MORE to the bottom of a 720 px screen")
	assert_eq(MorePanel.columns_for(16), MorePanel.COLUMNS + 1)
	assert_eq(MorePanel.columns_for(3), MorePanel.COLUMNS)
