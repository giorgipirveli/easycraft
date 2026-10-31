class_name CoinIcon
extends Control
## A gold coin drawn in code (no art asset), for the gold counter, prices and the shop's buttons.

const GOLD := Color("ffd23f")
const RIM := Color("c99a12")
const SHINE := Color(1, 1, 1, 0.6)

static var _texture: ImageTexture
## P5 (VR draws): redraws through the headset's one-draw path; tests count them.
var vr_draws := 0


func _init(px: float = 32.0) -> void:
	custom_minimum_size = Vector2(px, px)
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r := minf(size.x, size.y) * 0.5
	var c := size * 0.5
	if GraphicsPreset.vr_session:   # P5: a headset's HUD canvas: the coin's four shapes as one draw (CanvasBatch)
		vr_draws += 1
		var batch := CanvasBatch.new()
		batch.draw_circle(c, r, RIM)
		batch.draw_circle(c, r * 0.8, GOLD)
		batch.draw_arc(c, r * 0.55, 0.0, TAU, 24, RIM, maxf(1.0, r * 0.1), true)
		batch.draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.16, SHINE)
		batch.flush(self)
		return
	draw_circle(c, r, RIM)
	draw_circle(c, r * 0.8, GOLD)
	draw_arc(c, r * 0.55, 0.0, TAU, 24, RIM, maxf(1.0, r * 0.1), true)
	draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.16, SHINE)


## The same coin as a texture for button icons, built once.
static func texture() -> Texture2D:
	if _texture == null:
		var n := 32
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var d := Vector2(x + 0.5 - n * 0.5, y + 0.5 - n * 0.5).length() / (n * 0.5)
				var col := Color(0, 0, 0, 0)
				if d <= 1.0:
					col = RIM
				if d <= 0.8:
					col = GOLD
				if absf(d - 0.55) < 0.07:
					col = RIM
				if Vector2(x + 0.5 - n * 0.35, y + 0.5 - n * 0.35).length() < n * 0.08:
					col = GOLD.lightened(0.7)
				img.set_pixel(x, y, col)
		_texture = ImageTexture.create_from_image(img)
	return _texture
