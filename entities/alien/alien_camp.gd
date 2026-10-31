class_name AlienCamp
extends Node3D
## A travelling alien explorers' camp on a real planet or moon (owner #86, spec §21f): a small ship on three legs, the
## trader's table with its souvenirs, a telescope looking at the sky and a lamp post (one merged mesh, one draw call:
## AlienModels.camp), a sign, and its two aliens: the explorer by the telescope and the trader behind the table. Two
## small boxes keep the child from walking through the ship's hull and the table (the world's layer). Every game
## builds its own from the seed (AlienRules.site), so nothing is sent.

const SIGN_Y := 4.2

var universe := 0
var explorer: Alien
var trader: Alien


## data = {universe: int, pos: Vector3 (the middle, on the ground), yaw: float (its front towards the pad),
## ground_y: Callable (x, z) -> float}
func setup(data: Dictionary) -> void:
	universe = int(data.universe)
	name = "AlienCamp"
	position = data.pos
	rotation.y = float(data.get("yaw", 0.0))
	CreatureLook.add(self, AlienModels.camp(universe), CreatureLook.CAMP_RANGE, "Camp")
	var sign := Label3D.new()
	sign.name = "Sign"
	sign.text = CreatureWords.CAMP_NAME
	sign.font_size = 56
	sign.outline_size = 14
	sign.pixel_size = 0.006
	sign.modulate = Color("ffd23f")
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.position = AlienModels.SHIP_SPOT + Vector3(0, SIGN_Y * AlienModels.SHIP_SCALE, 0)
	sign.visibility_range_end = CreatureLook.CAMP_RANGE
	add_child(sign)
	_solid(AlienModels.SHIP_SPOT + Vector3(0, 1.45, 0) * AlienModels.SHIP_SCALE, Vector3(2.4, 1.4, 2.4) * AlienModels.SHIP_SCALE)
	_solid(AlienModels.TABLE_SPOT + Vector3(0, 0.45, 0), Vector3(1.5, 0.9, 0.72))
	var c := CreatureWords.camp(universe)
	var ground: Callable = data.get("ground_y", Callable())
	explorer = _alien(c.explorer, AlienModels.EXPLORER_SPOT, ground)
	trader = _alien(c.trader, AlienModels.TRADER_SPOT, ground)


func aliens() -> Array[Alien]:
	return [explorer, trader]


func _alien(id: StringName, spot: Vector3, ground: Callable) -> Alien:
	var a := Alien.new()
	var at := spot
	if ground.is_valid():   # its own ground (the camp's may be a block off there)
		var world := transform * spot
		at.y = float(ground.call(floori(world.x), floori(world.z))) - position.y
	a.setup({"id": id, "pos": at, "yaw": 0.0})
	a.ground_y = ground
	add_child(a)
	return a


func _solid(center: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = Player.WORLD_COLLISION_MASK
	body.collision_mask = 0
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = size
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = center
	body.add_child(cs)
