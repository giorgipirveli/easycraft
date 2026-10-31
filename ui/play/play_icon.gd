class_name PlayIcon
extends Control
## Owner #122 (G0): a mechanic's little picture, drawn in code (no font needs an emoji): Make it (a stack of blocks),
## Sort it (two bins), Order it (a bridge of planks), Connect it (a lamp on a wire), Fix it (a pin and its tag), Build
## it (blocks on a board), Code it (a robot), Beat it (a drum), Mix it (a paint pot), Find it (a map's X), Choose by
## doing (a crate), Test it (a gate). On DISCOVER's map each place shows its main one; the unit page shows them all.

var mechanic := ""


func _init(id: String = "", side: float = 28.0) -> void:
	mechanic = id
	name = "PlayIcon"
	custom_minimum_size = Vector2(side, side)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	paint(self, mechanic, Rect2(Vector2.ZERO, size))


## Draws mechanic `id` into `r` on `c`.
static func paint(c: CanvasItem, id: String, r: Rect2) -> void:
	var u := minf(r.size.x, r.size.y)
	var o := r.position + (r.size - Vector2(u, u)) * 0.5
	var ink := Color("1f2a4a")
	c.draw_circle(o + Vector2(u, u) * 0.5, u * 0.5, Color(1, 1, 1, 0.92))
	var p := func(x: float, y: float) -> Vector2: return o + Vector2(x, y) * u
	match id:
		"make":
			for k in 3:
				c.draw_rect(Rect2(p.call(0.36, 0.62 - k * 0.16), Vector2(0.28, 0.15) * u), Color("f7d117"))
				c.draw_rect(Rect2(p.call(0.36, 0.62 - k * 0.16), Vector2(0.28, 0.15) * u), ink, false, maxf(1.0, u * 0.03))
		"sort":
			c.draw_rect(Rect2(p.call(0.18, 0.48), Vector2(0.28, 0.28) * u), Color("3a7be8"))
			c.draw_rect(Rect2(p.call(0.54, 0.48), Vector2(0.28, 0.28) * u), Color("f08a1c"))
			c.draw_circle(p.call(0.32, 0.32), u * 0.08, Color("2fae4e"))
		"order":
			for k in 4:
				c.draw_rect(Rect2(p.call(0.16 + k * 0.18, 0.46), Vector2(0.15, 0.1) * u), Color("b98a57"))
			c.draw_line(p.call(0.12, 0.62), p.call(0.88, 0.62), Color("5ab0e8"), maxf(1.5, u * 0.06))
		"connect":
			c.draw_line(p.call(0.2, 0.75), p.call(0.5, 0.45), ink, maxf(1.5, u * 0.05))
			c.draw_circle(p.call(0.6, 0.36), u * 0.14, Color("ffe066"))
			c.draw_rect(Rect2(p.call(0.12, 0.7), Vector2(0.16, 0.12) * u), Color("e0a325"))
		"fix":
			c.draw_rect(Rect2(p.call(0.2, 0.25), Vector2(0.6, 0.4) * u), Color("fdf6e3"))
			c.draw_rect(Rect2(p.call(0.2, 0.25), Vector2(0.6, 0.4) * u), ink, false, maxf(1.0, u * 0.03))
			c.draw_circle(p.call(0.5, 0.45), u * 0.07, Color("d6475a"))
			c.draw_rect(Rect2(p.call(0.4, 0.7), Vector2(0.3, 0.1) * u), Color("f6f2ea"))
		"build":
			for k in 3:
				c.draw_rect(Rect2(p.call(0.2 + k * 0.2, 0.55), Vector2(0.18, 0.18) * u), Color("c98d4f"))
			c.draw_rect(Rect2(p.call(0.4, 0.36), Vector2(0.18, 0.18) * u), Color("c98d4f"))
		"code":
			c.draw_rect(Rect2(p.call(0.3, 0.3), Vector2(0.4, 0.36) * u), Color("3a7be8"))
			c.draw_rect(Rect2(p.call(0.36, 0.38), Vector2(0.28, 0.1) * u), Color("9fd8ff"))
			c.draw_line(p.call(0.5, 0.3), p.call(0.5, 0.18), ink, maxf(1.0, u * 0.04))
		"beat":
			c.draw_rect(Rect2(p.call(0.25, 0.45), Vector2(0.5, 0.28) * u), Color("d6475a"))
			c.draw_rect(Rect2(p.call(0.25, 0.4), Vector2(0.5, 0.08) * u), Color("f6f2ea"))
			c.draw_line(p.call(0.3, 0.2), p.call(0.45, 0.4), ink, maxf(1.5, u * 0.05))
		"mix":
			c.draw_rect(Rect2(p.call(0.3, 0.42), Vector2(0.4, 0.32) * u), Color("c0c6d4"))
			c.draw_rect(Rect2(p.call(0.3, 0.38), Vector2(0.4, 0.1) * u), Color("d9437a"))
			c.draw_circle(p.call(0.62, 0.26), u * 0.07, Color("2a5fc4"))
		"find":
			c.draw_rect(Rect2(p.call(0.2, 0.25), Vector2(0.6, 0.5) * u), Color("f3e2b3"))
			c.draw_line(p.call(0.42, 0.42), p.call(0.58, 0.58), Color("d6475a"), maxf(1.5, u * 0.06))
			c.draw_line(p.call(0.58, 0.42), p.call(0.42, 0.58), Color("d6475a"), maxf(1.5, u * 0.06))
		"choose":
			c.draw_rect(Rect2(p.call(0.25, 0.4), Vector2(0.5, 0.36) * u), Color("c98d4f"))
			c.draw_line(p.call(0.25, 0.52), p.call(0.75, 0.52), ink, maxf(1.0, u * 0.03))
			c.draw_circle(p.call(0.5, 0.28), u * 0.09, Color("2fae4e"))
		"test":
			c.draw_rect(Rect2(p.call(0.22, 0.3), Vector2(0.24, 0.45) * u), Color("2fae4e"))
			c.draw_rect(Rect2(p.call(0.54, 0.3), Vector2(0.24, 0.45) * u), Color("f08a1c"))
		_:
			c.draw_circle(o + Vector2(u, u) * 0.5, u * 0.18, ink)
