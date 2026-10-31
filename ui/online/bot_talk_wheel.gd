class_name BotTalkWheel
extends RefCounted
## The quick-chat wheel's BOTS page (owner feedback #38, spec §12.14a): eight picture phrases a child who
## can't type (under-13 players chat with the wheel only) says to their own bot friends. They go to the
## child's friends only, never to other players (ChatPanel). Pictures are drawn with shapes like
## ChatPictures' (no image files): the arrow (Follow me!), an open hand (Wait here!), stacked blocks
## (Build a house!), a treasure chest, a shield, a music note, Tilly's gold coin and a race flag.

## Clockwise from the top; each one BotIntents understands.
const PHRASES: Array[String] = ["Follow me!", "Wait here!", "Build a house!", "Find treasure!", "Guard me!",
	"Let's dance!", "Where is Tilly?", "Race me!"]
const PICTURES := {
	"Follow me!": &"follow", "Wait here!": &"wait", "Build a house!": &"build", "Find treasure!": &"chest",
	"Guard me!": &"shield", "Let's dance!": &"note", "Where is Tilly?": &"coin", "Race me!": &"flag",
}


## Draws picture `kind` into `rect` of `canvas` in `color` (a phrase's picture: PICTURES).
static func draw(canvas: CanvasItem, kind: StringName, rect: Rect2, color: Color = Color.WHITE) -> void:
	var u := minf(rect.size.x, rect.size.y) / 16.0   # 16 x 16 units, like ChatPictures
	var c := rect.get_center()
	var dark := Color(0.08, 0.1, 0.17)
	var gold := Color(1.0, 0.82, 0.25) if color == Color.WHITE else color
	match kind:
		&"follow":
			ChatPictures.draw(canvas, &"follow", rect, color)
		&"wait":
			ChatPictures.draw(canvas, &"hi", rect, color)
		&"build":
			ChatPictures.draw(canvas, &"build", rect, color)
		&"chest":
			canvas.draw_rect(Rect2(c + Vector2(-6.5, -1.0) * u, Vector2(13, 7) * u), Color(0.62, 0.38, 0.18) if color == Color.WHITE else color)
			canvas.draw_rect(Rect2(c + Vector2(-6.5, -5.0) * u, Vector2(13, 4) * u), Color(0.75, 0.47, 0.22) if color == Color.WHITE else color)
			canvas.draw_rect(Rect2(c + Vector2(-6.5, -1.6) * u, Vector2(13, 1.2) * u), gold)
			canvas.draw_rect(Rect2(c + Vector2(-1.2, -2.5) * u, Vector2(2.4, 3.2) * u), gold)
			canvas.draw_rect(Rect2(c + Vector2(-6.5, -5.0) * u, Vector2(13, 11) * u), dark, false, 0.6 * u)
		&"shield":
			var pts := PackedVector2Array([c + Vector2(-5.5, -6) * u, c + Vector2(5.5, -6) * u, c + Vector2(5.5, 0) * u,
				c + Vector2(0, 7) * u, c + Vector2(-5.5, 0) * u])
			canvas.draw_colored_polygon(pts, Color(0.35, 0.6, 1.0) if color == Color.WHITE else color)
			var star := PackedVector2Array()   # a gold star on it
			for i in 10:
				var a := -PI * 0.5 + TAU * i / 10.0
				star.append(c + Vector2(cos(a), sin(a)) * (3.2 if i % 2 == 0 else 1.4) * u + Vector2(0, -0.8) * u)
			canvas.draw_colored_polygon(star, gold)
		&"note":
			canvas.draw_circle(c + Vector2(-3, 4.5) * u, 2.4 * u, color)
			canvas.draw_circle(c + Vector2(4, 3) * u, 2.4 * u, color)
			canvas.draw_rect(Rect2(c + Vector2(-1.2, -6) * u, Vector2(1.3, 10.5) * u), color)
			canvas.draw_rect(Rect2(c + Vector2(5.8, -7.5) * u, Vector2(1.3, 10.5) * u), color)
			canvas.draw_colored_polygon(PackedVector2Array([c + Vector2(-1.2, -6) * u, c + Vector2(7.1, -7.5) * u,
				c + Vector2(7.1, -5) * u, c + Vector2(-1.2, -3.5) * u]), color)
		&"coin":
			canvas.draw_circle(c, 6.5 * u, gold)
			canvas.draw_arc(c, 6.5 * u, 0.0, TAU, 32, dark, 0.7 * u, true)
			canvas.draw_arc(c + Vector2(0, -1.5) * u, 2.2 * u, PI, TAU + 0.8, 12, dark, 1.2 * u, true)
			canvas.draw_rect(Rect2(c + Vector2(-0.6, 0.5) * u, Vector2(1.2, 1.8) * u), dark)
			canvas.draw_rect(Rect2(c + Vector2(-0.6, 3.2) * u, Vector2(1.2, 1.2) * u), dark)
		&"flag":
			canvas.draw_rect(Rect2(c + Vector2(-5.5, -7) * u, Vector2(1.3, 14) * u), color)
			for row in 3:
				for col in 4:
					var box := Rect2(c + Vector2(-4.2 + col * 2.5, -7 + row * 2.3) * u, Vector2(2.5, 2.3) * u)
					canvas.draw_rect(box, color if (row + col) % 2 == 0 else dark)
