class_name ShopWeekBars
extends Control
## Owner #115 (S3): MY SHOP's ledger in pictures: the last seven days' profit as bars, green above the line, a loss red
## under it, the day's first letters under each (MyShopPage).

var values: Array[int] = []
var labels: Array[String] = []


func _init(v: Array[int] = [], l: Array[String] = []) -> void:
	values = v
	labels = l
	custom_minimum_size = Vector2(500, 160)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var most := 1
	for x in values:
		most = maxi(most, absi(x))
	var base := size.y * 0.62
	draw_line(Vector2(0, base), Vector2(size.x, base), Color(1, 1, 1, 0.7), 2.0)
	var w := size.x / maxf(values.size(), 1.0)
	var font := ThemeDB.fallback_font
	for i in values.size():
		var h := float(absi(values[i])) / most * size.y * (0.55 if values[i] >= 0 else 0.3)
		var r := Rect2(i * w + w * 0.2, base - h if values[i] >= 0 else base, w * 0.6, maxf(h, 2.0))
		draw_rect(r, Color("4fbf6a") if values[i] >= 0 else Color("e8705a"))
		if i < labels.size():
			draw_string(font, Vector2(i * w + w * 0.18, size.y - 4), labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
