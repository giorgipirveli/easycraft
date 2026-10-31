class_name QrView
extends Control
## Owner #79 (spec §25.2): an invite link as a QR code (QrCode), black on white with its quiet zone of four modules,
## every module a whole number of pixels so a phone's camera reads it off the screen.

var text := ""
var qr := {}


func _init(link: String = "", side: float = 300.0) -> void:
	name = "Qr"
	text = link
	qr = QrCode.encode(link)
	custom_minimum_size = Vector2(side, side)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)
	if qr.is_empty():
		return
	var n: int = qr.size
	var cells := n + 8
	var px := floorf(minf(size.x, size.y) / cells)
	if px < 1.0:
		return
	var origin := ((size - Vector2(px * cells, px * cells)) * 0.5).floor() + Vector2(4.0 * px, 4.0 * px)
	var dark: PackedByteArray = qr.dark
	for y in n:
		for x in n:
			if dark[y * n + x] == 1:
				draw_rect(Rect2(origin + Vector2(x, y) * px, Vector2(px, px)), Color.BLACK)
