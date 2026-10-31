class_name BuddyTraits
extends RefCounted
## A living buddy's personality comes from what it is made of: small builds are zippy and bouncy,
## huge ones slow stompers; light blocks make it glow; a mostly-glass build floats like a ghost.


static func from_blocks(blocks: Dictionary) -> Dictionary:
	var n := blocks.size()
	var lights := 0
	var glass := 0
	for id: int in blocks.values():
		if id == BlockIds.LIGHT:
			lights += 1
		elif id == BlockIds.GLASS:
			glass += 1
	var speed := 7.0
	var hop := 1.4
	if n > 100:
		speed = 2.5
		hop = 0.5
	elif n > 30:
		speed = 3.5
		hop = 0.8
	elif n > 8:
		speed = 5.0
		hop = 1.1
	return {
		"speed": speed,
		"hop": hop,
		"glow": lights > 0,
		"glow_energy": clampf(0.6 + lights * 0.4, 0.6, 3.0),
		"floaty": glass * 2 > n,
	}
