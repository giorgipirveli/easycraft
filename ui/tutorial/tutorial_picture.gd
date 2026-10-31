class_name TutorialPicture
extends Control
## A tutorial step's picture (M3 Task 15): a HUD button's own picture (HudIcons: WALK, JUMP, SHOP) or a block or
## item icon (BlockIcons: planks, the pickaxe, a bush, a stick), drawn in its own square. UI draw calls only.

## [&"hud", symbol] or [&"block", id] (TutorialRules.STEPS' pictures).
var picture: Array = []:
	set(value):
		picture = value
		queue_redraw()


func _init(pic: Array = [], px: float = 80.0) -> void:
	picture = pic
	custom_minimum_size = Vector2(px, px)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## True when the picture has something to draw.
static func draws(pic: Array) -> bool:
	if pic.size() != 2:
		return false
	match pic[0]:
		&"hud":
			return HudIcons.knows(pic[1])
		&"block":
			return BlockIcons.icon(int(pic[1])) != null
	return false


func _draw() -> void:
	if picture.size() != 2:
		return
	var s := minf(size.x, size.y)
	var r := Rect2((size - Vector2(s, s)) * 0.5, Vector2(s, s))
	match picture[0]:
		&"hud":
			HudIcons.draw(self, picture[1], r.grow(-s * 0.06), Color.WHITE)
		&"block":
			var tex := BlockIcons.icon(int(picture[1]))
			if tex:
				draw_texture_rect(tex, r.grow(-s * 0.08), false)
