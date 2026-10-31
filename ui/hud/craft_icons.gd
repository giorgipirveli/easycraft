class_name CraftIcons
extends RefCounted
## Pictures of the crafted-only things (spec §12.19; ItemIds.CRAFTED), drawn in code in the item icons'
## 16 px pixel style (no atlas tiles, so no other task's atlas changes). BlockIcons.icon asks here first.

const SIZE := 16
const BARK := Color("7a5230")
const BARK_DARK := Color("4e331c")
const BARK_LIGHT := Color("a8784a")


static func has(id: int) -> bool:
	return id == ItemIds.STICK


static func image(id: int) -> Image:
	var img := Image.create(SIZE, SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	if id == ItemIds.STICK:
		_stick(img)
	return img


## A stick from the bottom-left to the top-right: dark edges, a light top line, a small knot.
static func _stick(img: Image) -> void:
	for i in range(2, 14):
		var x := i
		var y := SIZE - 1 - i
		img.set_pixel(x, y, BARK)
		img.set_pixel(x + 1, y, BARK_LIGHT)
		img.set_pixel(x, y + 1, BARK_DARK)
		if x + 1 < SIZE and y + 1 < SIZE:
			img.set_pixel(x + 1, y + 1, BARK)
	img.set_pixel(7, 8, BARK_DARK)   # a knot
	img.set_pixel(6, 7, BARK_DARK)   # a little twig
	img.set_pixel(5, 6, BARK)
