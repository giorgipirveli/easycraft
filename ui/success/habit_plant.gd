class_name HabitPlant
extends Control
## Owner #115 (the brief: "a plant grows on each day it is kept; a missed day never kills it"): the habit garden's plant,
## drawn in code for its kept days (SuccessHabits.stage and .flowers): a pot, a seed, then a sprout, leaves, a bud and a
## flower, more flowers for a habit kept for weeks. It never wilts or shrinks.

var days := 0


func _init(kept_days: int = 0, px: float = 220.0) -> void:
	days = kept_days
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	name = "HabitPlant"


func _draw() -> void:
	var s := minf(size.x, size.y)
	var o := (size - Vector2(s, s)) * 0.5
	var u := s / 100.0
	var p := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * u
	var stage := SuccessHabits.stage(days)
	draw_colored_polygon(PackedVector2Array([p.call(30, 74), p.call(70, 74), p.call(64, 98), p.call(36, 98)]), Color("c0563a"))
	draw_rect(Rect2(p.call(26, 70), Vector2(48, 7) * u), Color("a8452c"))
	draw_rect(Rect2(p.call(31, 70), Vector2(38, 4) * u), Color("5a3a24"))
	if stage == 0:
		draw_circle(p.call(50, 69), 3.5 * u, Color("8b5a2b"))
		return
	var top := 70.0 - 8.0 * stage
	draw_line(p.call(50, 70), p.call(50, top), Color("4f9a3e"), 3.2 * u, true)
	for i in mini(stage, 5):
		var y := 64.0 - i * 8.0
		var side := -1.0 if i % 2 == 0 else 1.0
		draw_circle(p.call(50 + side * 7, y), (4.0 + i * 0.6) * u, Color("62b04e"))
	if stage == 6:
		draw_circle(p.call(50, top - 3), 4.5 * u, Color("7cc46a"))
	elif stage >= 7:
		_flower(p.call(50, top - 4), 7 * u)
		var extra := SuccessHabits.flowers(days) - 1
		for i in maxi(extra, 0):
			var a := -PI / 2 + (i + 1) * (TAU / (SuccessHabits.MAX_FLOWERS + 1))
			_flower(p.call(50, top + 8) + Vector2(cos(a), sin(a)) * 16 * u, 4.5 * u)


func _flower(c: Vector2, r: float) -> void:
	for i in 5:
		var a := i * TAU / 5.0
		draw_circle(c + Vector2(cos(a), sin(a)) * r, r * 0.7, Color("f39ac0"))
	draw_circle(c, r * 0.6, Color("ffd23f"))
