class_name TraderStand
extends Trader
## A universe helper's stand (owner #37, spec §14.23): a small table beside Zara, Bram, Mimi or Nell with crates of
## the universe's own things under an awning in its colours, and a sign ("Zara's stand"). No figure of its own (the
## helper stands beside it and keeps their quest card). A Trader in the group "traders" (the host's reach check and
## Trader.find for taps) and "stands": a tap opens the shop on the universe's own things (shop_stock). Every game
## places it from the helper's spot (TradeDirector), so nothing is sent. Cheap: one shared vertex-coloured mesh per
## universe (WeaponModels' one material), a label and one small static body on the world layer.

const SIGN_Y := 2.35

static var _stands := {}

## What the shop shows at this stand (StandRules.stock) and its title (StandRules.title).
var shop_stock: Array[int] = []
var shop_title := ""
var universe := 2


## data = {pos: Vector3 (feet), yaw: float, universe: int}
func setup(data: Dictionary) -> void:
	universe = int(data.get("universe", 2))
	name = "Stand%d" % universe
	position = data.pos
	rotation.y = float(data.get("yaw", 0.0))
	shop_stock = StandRules.stock(universe)
	shop_title = StandRules.title(universe)
	add_to_group(&"traders")
	add_to_group(&"stands")
	var mi := MeshInstance3D.new()
	mi.mesh = stand_mesh(universe)
	add_child(mi)
	var label := Label3D.new()
	label.text = shop_title
	label.font_size = 40
	label.outline_size = 10
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, SIGN_Y, 0)
	add_child(label)
	_hint.visible = false   # Tilly's shop arrow: never over a stand
	add_child(_hint)
	var body := StaticBody3D.new()
	body.collision_layer = Player.WORLD_COLLISION_MASK
	body.collision_mask = 0
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.6, 0.9, 0.7)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = Vector3(0, 0.45, 0)
	body.add_child(cs)
	set_process(false)   # nobody behind the table to turn or wave


## One mesh per universe: a table, four posts, the awning and three crates in the universe's colours.
static func stand_mesh(u: int) -> Mesh:
	if not _stands.has(u):
		var colors := UniverseRegistry.card_colors(u)
		var top: Color = colors.get("top", Color("e04b3c"))
		var ground: Color = colors.get("ground", Color("fbf3e4"))
		var wood := Color("a0703f")
		var dark := Color("6e4526")
		var parts: Array = [
			[Vector3(0, 0.45, 0), Vector3(1.6, 0.9, 0.7), wood],
			[Vector3(0, 0.92, 0), Vector3(1.75, 0.06, 0.8), Color("c8995c")],
		]
		for x: float in [-0.8, 0.8]:
			for z: float in [-0.35, 0.35]:
				parts.append([Vector3(x, 1.0, z), Vector3(0.1, 2.0, 0.1), dark])
		for i in 4:
			parts.append([Vector3(-0.66 + i * 0.44, 2.04, 0), Vector3(0.44, 0.07, 1.0), top if i % 2 == 0 else ground])
		var bottom: Color = colors.get("bottom", Color("ffd23f"))
		var crates: Array[Color] = [bottom, top.lightened(0.3), ground]
		for i in 3:
			parts.append([Vector3(-0.5 + i * 0.5, 1.1, -0.05), Vector3(0.34, 0.3, 0.34), crates[i]])
		_stands[u] = WeaponModels.build(parts)
	return _stands[u]
