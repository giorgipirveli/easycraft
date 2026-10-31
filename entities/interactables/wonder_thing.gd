class_name WonderThing
extends SecretThing
## Universe 6, the Glow Caves: a tap spot of a Cave Wonder (GlowWondersDirector): an invisible box a little bigger than
## one block of the wonder (the drip stone's stump, the bat roost, a crystal over a tunnel, the rainwater basin, a block
## of the wall, the lamp stone, the ripple stone), on the secret things' layer so a tap ray finds it before the block.
## Local to this game (each game's director makes its own near its own child); a tap goes to the director.

const BOX := Vector3(1.1, 1.1, 1.1)

var director: Node
var wonder_id := ""
var part: StringName = &""
var index := 0


static func make(owner_director: Node, id: String, what: StringName, i: int, cell: Vector3i) -> WonderThing:
	var t := WonderThing.new()
	t.director = owner_director
	t.wonder_id = id
	t.part = what
	t.index = i
	t._base({"id": "%s_%s_%d" % [id, what, i], "pos": Vector3(cell) + Vector3(0.5, -0.05, 0.5)}, BOX,
		Vector3(0, BOX.y * 0.5, 0))
	return t


## SecretTaps: the director plays the tap.
func tapped() -> bool:
	return is_instance_valid(director) and bool(director.call(&"tap", wonder_id, part, index))
