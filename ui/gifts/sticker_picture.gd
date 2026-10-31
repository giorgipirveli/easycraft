class_name StickerPicture
extends Control
## A guestbook sticker's picture (M4 Wave 3, agent I; GiftRules.STICKERS), drawn in code like the HUD's
## pictures (no textures, CC0 by construction): a star, a heart, a smile, WOW, a thumb up, a rainbow, a
## trophy, a flower. Colour is never the only sign: every sticker has its own shape.

const COLORS := {"star": Color("ffd23f"), "heart": Color("ff5c8a"), "smile": Color("ffd23f"), "wow": Color("7ee0ff"),
	"thumbs_up": Color("8cf07a"), "rainbow": Color("ff7b54"), "trophy": Color("ffc93c"), "flower": Color("ff8fd8")}

var sticker := "star":
	set(value):
		sticker = value
		queue_redraw()


func _init(which: String = "star") -> void:
	sticker = which
	custom_minimum_size = Vector2(64, 64)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var side := minf(size.x, size.y)
	var r := Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side))
	draw_sticker(self, sticker, r)


## Draws `which` into the square `r` of `ci`.
static func draw_sticker(ci: CanvasItem, which: String, r: Rect2) -> void:
	var c: Color = COLORS.get(which, Color.WHITE)
	var at := func(x: float, y: float) -> Vector2: return r.position + Vector2(x, y) * r.size
	var ink := Color(0.12, 0.13, 0.2)
	match which:
		"star":
			var pts := PackedVector2Array()
			for i in 10:
				var a := -PI / 2.0 + TAU * i / 10.0
				var rad := 0.46 if i % 2 == 0 else 0.2
				pts.append(at.call(0.5 + cos(a) * rad, 0.53 + sin(a) * rad))
			ci.draw_colored_polygon(pts, c)
		"heart":
			ci.draw_circle(at.call(0.33, 0.38), 0.19 * r.size.x, c)
			ci.draw_circle(at.call(0.67, 0.38), 0.19 * r.size.x, c)
			ci.draw_colored_polygon(PackedVector2Array([at.call(0.15, 0.46), at.call(0.85, 0.46), at.call(0.5, 0.9)]), c)
		"smile":
			ci.draw_circle(at.call(0.5, 0.5), 0.42 * r.size.x, c)
			ci.draw_circle(at.call(0.36, 0.4), 0.06 * r.size.x, ink)
			ci.draw_circle(at.call(0.64, 0.4), 0.06 * r.size.x, ink)
			ci.draw_arc(at.call(0.5, 0.52), 0.22 * r.size.x, 0.3, PI - 0.3, 16, ink, 0.06 * r.size.x, true)
		"wow":
			ci.draw_circle(at.call(0.5, 0.5), 0.44 * r.size.x, c)
			ci.draw_circle(at.call(0.35, 0.38), 0.07 * r.size.x, ink)
			ci.draw_circle(at.call(0.65, 0.38), 0.07 * r.size.x, ink)
			ci.draw_circle(at.call(0.5, 0.66), 0.11 * r.size.x, ink)
		"thumbs_up":
			ci.draw_rect(Rect2(at.call(0.18, 0.46), Vector2(0.18, 0.4) * r.size), c)
			ci.draw_colored_polygon(PackedVector2Array([at.call(0.4, 0.46), at.call(0.52, 0.12), at.call(0.62, 0.14),
				at.call(0.6, 0.42), at.call(0.84, 0.44), at.call(0.8, 0.86), at.call(0.4, 0.86)]), c)
		"rainbow":
			var bands := [Color("ff5c5c"), Color("ffd23f"), Color("8cf07a"), Color("5cb8ff")]
			for i in bands.size():
				ci.draw_arc(at.call(0.5, 0.78), (0.42 - i * 0.09) * r.size.x, PI, TAU, 24, bands[i], 0.08 * r.size.x, true)
		"trophy":
			ci.draw_colored_polygon(PackedVector2Array([at.call(0.24, 0.14), at.call(0.76, 0.14), at.call(0.66, 0.5),
				at.call(0.34, 0.5)]), c)
			ci.draw_rect(Rect2(at.call(0.45, 0.5), Vector2(0.1, 0.22) * r.size), c)
			ci.draw_rect(Rect2(at.call(0.3, 0.72), Vector2(0.4, 0.12) * r.size), c)
			ci.draw_arc(at.call(0.24, 0.28), 0.1 * r.size.x, PI * 0.5, PI * 1.5, 12, c, 0.05 * r.size.x, true)
			ci.draw_arc(at.call(0.76, 0.28), 0.1 * r.size.x, -PI * 0.5, PI * 0.5, 12, c, 0.05 * r.size.x, true)
		"flower":
			for i in 5:
				var a := TAU * i / 5.0
				ci.draw_circle(at.call(0.5 + cos(a) * 0.22, 0.45 + sin(a) * 0.22), 0.16 * r.size.x, c)
			ci.draw_circle(at.call(0.5, 0.45), 0.12 * r.size.x, Color("ffd23f"))
			ci.draw_line(at.call(0.5, 0.62), at.call(0.5, 0.95), Color("5cc95c"), 0.06 * r.size.x)
		_:
			ci.draw_circle(at.call(0.5, 0.5), 0.4 * r.size.x, c)
