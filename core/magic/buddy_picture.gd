class_name BuddyPicture
extends RefCounted
## A buddy's small picture for the Buddy Album and My Stamps (M3 Task 20b): the front of its build (its face is
## the -Z side, the z = 0 blocks of its offsets), at most MAX x MAX cells, each the block seen there (0: empty).
## Drawn with the blocks' own tiles (BuildPictureView), so it needs no image and no photo. Pure.
## The code: "<w>.<h>:" then the cells row by row from the top left, comma separated, a run as "<id>*<n>".

const MAX := 8
const MAX_CODE := 400


## The picture code of `blocks` (offsets -> ids, lowest corner at 0); "" for no blocks.
static func code_of(blocks: Dictionary) -> String:
	if blocks.is_empty():
		return ""
	var hi := Vector3i.ZERO
	for p: Vector3i in blocks:
		hi = Vector3i(maxi(hi.x, p.x), maxi(hi.y, p.y), maxi(hi.z, p.z))
	var sw := hi.x + 1
	var sh := hi.y + 1
	var front := {}                  # Vector2i(x, y) -> [z, id] of the front-most block
	for p: Vector3i in blocks:
		var k := Vector2i(p.x, p.y)
		if not front.has(k) or p.z < int(front[k][0]):
			front[k] = [p.z, int(blocks[p])]
	var w := mini(sw, MAX)
	var h := mini(sh, MAX)
	var cells := PackedInt32Array()
	for row in h:
		var y := sh - 1 - floori((row + 0.5) * sh / float(h))
		for col in w:
			var x := floori((col + 0.5) * sw / float(w))
			var k := Vector2i(x, y)
			cells.append(int(front[k][1]) if front.has(k) else 0)
	return encode(w, h, cells)


static func encode(w: int, h: int, cells: PackedInt32Array) -> String:
	var tokens: Array[String] = []
	var i := 0
	while i < cells.size():
		var n := 1
		while i + n < cells.size() and cells[i + n] == cells[i]:
			n += 1
		tokens.append(str(cells[i]) if n == 1 else "%d*%d" % [cells[i], n])
		i += n
	return "%d.%d:%s" % [w, h, ",".join(tokens)]


## {w, h, cells: PackedInt32Array} or {} when the code is broken (hand-edited saves never break the album).
static func decode(code: String) -> Dictionary:
	if code == "" or code.length() > MAX_CODE:
		return {}
	var colon := code.find(":")
	if colon < 0:
		return {}
	var size := code.substr(0, colon).split(".")
	if size.size() != 2 or not size[0].is_valid_int() or not size[1].is_valid_int():
		return {}
	var w := size[0].to_int()
	var h := size[1].to_int()
	if w < 1 or h < 1 or w > MAX or h > MAX:
		return {}
	var cells := PackedInt32Array()
	for t in code.substr(colon + 1).split(","):
		var parts := t.split("*")
		if parts.size() > 2 or not parts[0].is_valid_int() or (parts.size() == 2 and not parts[1].is_valid_int()):
			return {}
		var id := parts[0].to_int()
		var n := parts[1].to_int() if parts.size() == 2 else 1
		if (id != 0 and not BlockIds.is_valid(id)) or n < 1 or cells.size() + n > w * h:
			return {}
		for k in n:
			cells.append(id)
	if cells.size() != w * h:
		return {}
	return {"w": w, "h": h, "cells": cells}


## Whether `code` is a picture (or "": none).
static func is_valid(code: String) -> bool:
	return code == "" or not decode(code).is_empty()
