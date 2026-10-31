class_name MonsterIcon
extends Control
## A little green slime drawn in code (no art asset), for the wave line and the Monster Totem's panel
## (M2 Task 9); texture() is the same slime for button icons.

const BODY := Color("009e73")      # the level-1 slime's colour (MonsterRules.LEVEL_COLORS)
const DARK := Color("00664a")
const EYE := Color("fbf3e4")
const PUPIL := Color("1b1b1b")
const SHINE := Color(1, 1, 1, 0.45)

static var _texture: ImageTexture


func _init(px: float = 40.0) -> void:
	custom_minimum_size = Vector2(px, px)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var s := minf(size.x, size.y)
	var o := (size - Vector2(s, s)) * 0.5
	var c := o + Vector2(s * 0.5, s * 0.6)
	draw_circle(c, s * 0.42, DARK)
	draw_circle(c + Vector2(0, -s * 0.03), s * 0.38, BODY)
	draw_rect(Rect2(o + Vector2(s * 0.08, s * 0.6), Vector2(s * 0.84, s * 0.3)), BODY)
	draw_rect(Rect2(o + Vector2(s * 0.04, s * 0.86), Vector2(s * 0.92, s * 0.08)), DARK)
	for x: float in [0.36, 0.64]:
		draw_circle(o + Vector2(s * x, s * 0.52), s * 0.1, EYE)
		draw_circle(o + Vector2(s * x, s * 0.54), s * 0.05, PUPIL)
	draw_circle(o + Vector2(s * 0.3, s * 0.34), s * 0.06, SHINE)


## The same slime as a texture for button icons, built once.
static func texture() -> Texture2D:
	if _texture == null:
		var n := 32
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var p := Vector2(x + 0.5, y + 0.5) / n
				var col := Color(0, 0, 0, 0)
				var d := p.distance_to(Vector2(0.5, 0.6))
				if d <= 0.42 or (p.y >= 0.6 and p.y <= 0.94 and p.x >= 0.04 and p.x <= 0.96):
					col = DARK
				if d <= 0.38 or (p.y >= 0.6 and p.y <= 0.86 and p.x >= 0.08 and p.x <= 0.92):
					col = BODY
				for ex: float in [0.36, 0.64]:
					var e := p.distance_to(Vector2(ex, 0.52))
					if e <= 0.1:
						col = EYE
					if p.distance_to(Vector2(ex, 0.54)) <= 0.05:
						col = PUPIL
				img.set_pixel(x, y, col)
		_texture = ImageTexture.create_from_image(img)
	return _texture
