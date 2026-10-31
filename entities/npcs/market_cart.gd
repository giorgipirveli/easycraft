class_name MarketCart
extends Trader
## Nico the traveller's cart on market day (owner #37, spec §14.23): a wooden cart on two wheels with a green and
## yellow awning, crates of village blocks, and Nico (a blocky traveller with a wide hat and a big backpack) who
## turns to the nearest player and waves, like Tilly. A Trader in the groups "traders" and "market_traders" (the
## host sells Nico's things only near one: Session._pt_market_sells); a tap opens the shop on MarketRules' stock.
## The host's TradeDirector puts it beside Tilly's stall from sunrise to sunset of market day and tells every game.
## Cheap: three shared vertex-coloured meshes (cart, Nico, his waving arm) with WeaponModels' one material, a label
## and one static body on the world layer.

const _CART_WOOD := Color("8d5a2b")
const _CART_DARK := Color("5d3a1a")
const _GREEN := Color("3fbf5f")
const _YELLOW := Color("ffd23f")
const _NICO_SKIN := Color("e0ac69")
const _COAT := Color("2e86c1")
const _HAT := Color("7a4a2a")
const _PACK := Color("c0392b")

static var _cart_meshes := {}

## What the shop shows at the cart and its title; `market`: the prices are MarketRules'.
var shop_stock: Array[int] = []
var shop_title := MarketRules.SHOP_TITLE
var market := true


## data = {pos: Vector3 (the cart's middle, on the ground), yaw: float}
func setup(data: Dictionary) -> void:
	name = "NicoCart"
	position = data.pos
	rotation.y = float(data.get("yaw", 0.0))
	shop_stock = MarketRules.stock()
	add_to_group(&"traders")
	add_to_group(&"market_traders")
	var cart := MeshInstance3D.new()
	cart.mesh = _mesh_of(&"cart")
	add_child(cart)
	_body.position = Vector3(0, 0, 0.75)   # Nico stands behind the cart, facing the way it faces
	add_child(_body)
	var nico := MeshInstance3D.new()
	nico.mesh = _mesh_of(&"nico")
	_body.add_child(nico)
	_arm.position = ARM_SHOULDER
	_body.add_child(_arm)
	var arm := MeshInstance3D.new()
	arm.mesh = _mesh_of(&"arm")
	_arm.add_child(arm)
	var label := Label3D.new()
	label.text = tr("%s\nthe traveller") % MarketRules.TRADER_NAME
	label.font_size = 40
	label.outline_size = 10
	label.pixel_size = 0.005
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 2.9, 0)
	add_child(label)
	_hint.visible = false
	add_child(_hint)
	var body := StaticBody3D.new()
	body.collision_layer = Player.WORLD_COLLISION_MASK
	body.collision_mask = 0
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.0, 1.0, 1.0)
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = Vector3(0, 0.6, 0)
	body.add_child(cs)


static func _mesh_of(kind: StringName) -> Mesh:
	if not _cart_meshes.has(kind):
		match kind:
			&"cart":
				_cart_meshes[kind] = WeaponModels.build(_cart_parts())
			&"nico":
				_cart_meshes[kind] = WeaponModels.build(_nico_parts())
			&"arm":
				_cart_meshes[kind] = WeaponModels.build([
					[Vector3(0, -0.26, 0), Vector3(0.18, 0.52, 0.22), _COAT],
					[Vector3(0, -0.58, 0), Vector3(0.16, 0.14, 0.2), _NICO_SKIN],
				])
	return _cart_meshes[kind]


## A cart box on two wheels, a handle, crates of village blocks, posts and a striped awning.
static func _cart_parts() -> Array:
	var parts: Array = [
		[Vector3(0, 0.75, 0), Vector3(2.0, 0.5, 1.0), _CART_WOOD],
		[Vector3(0, 0.52, 0), Vector3(2.1, 0.06, 1.1), _CART_DARK],
		[Vector3(-1.3, 0.62, 0), Vector3(0.6, 0.08, 0.1), _CART_DARK],   # the handle
		[Vector3(-0.55, 1.12, 0), Vector3(0.4, 0.3, 0.4), Color("9e9e9e")],   # stone bricks
		[Vector3(0.0, 1.12, 0), Vector3(0.4, 0.3, 0.4), Color("c0503a")],     # roof tiles
		[Vector3(0.55, 1.12, 0), Vector3(0.4, 0.3, 0.4), Color("e6c35c")],    # hay
	]
	for x: float in [-0.7, 0.7]:
		parts.append([Vector3(x, 0.35, -0.6), Vector3(0.6, 0.6, 0.08), _CART_DARK])   # wheels
		parts.append([Vector3(x, 0.35, 0.6), Vector3(0.6, 0.6, 0.08), _CART_DARK])
		parts.append([Vector3(x * 1.35, 1.6, 0.0), Vector3(0.08, 1.7, 0.08), _CART_DARK])   # posts
	for i in 5:
		parts.append([Vector3(-1.0 + i * 0.5, 2.48, 0), Vector3(0.5, 0.07, 1.3), _GREEN if i % 2 == 0 else _YELLOW])
	return parts


## Nico: a blocky traveller in a blue coat with a wide brown hat and a big red backpack, facing -Z. His right arm is
## its own mesh (it waves).
static func _nico_parts() -> Array:
	var face := -0.241
	return [
		[Vector3(-0.13, 0.3, 0), Vector3(0.24, 0.6, 0.26), Color("4e342e")],
		[Vector3(0.13, 0.3, 0), Vector3(0.24, 0.6, 0.26), Color("4e342e")],
		[Vector3(0, 0.95, 0), Vector3(0.6, 0.7, 0.32), _COAT],
		[Vector3(-0.4, 1.04, 0), Vector3(0.18, 0.52, 0.22), _COAT],
		[Vector3(-0.4, 0.72, 0), Vector3(0.16, 0.14, 0.2), _NICO_SKIN],
		[Vector3(0, 1.0, 0.3), Vector3(0.5, 0.6, 0.3), _PACK],   # the backpack
		[Vector3(0, 1.36, 0.3), Vector3(0.3, 0.12, 0.26), Color("e8e8e8")],   # a rolled blanket on it
		[Vector3(0, 1.55, 0), Vector3(0.48, 0.48, 0.48), _NICO_SKIN],
		[Vector3(-0.1, 1.6, face), Vector3(0.07, 0.09, 0.01), Color("1b1b1b")],
		[Vector3(0.1, 1.6, face), Vector3(0.07, 0.09, 0.01), Color("1b1b1b")],
		[Vector3(0, 1.46, face), Vector3(0.18, 0.04, 0.01), Color("1b1b1b")],
		[Vector3(-0.17, 1.5, face), Vector3(0.06, 0.04, 0.01), Color("ff9aa2")],
		[Vector3(0.17, 1.5, face), Vector3(0.06, 0.04, 0.01), Color("ff9aa2")],
		[Vector3(0, 1.84, 0), Vector3(0.86, 0.05, 0.86), _HAT],   # the wide hat
		[Vector3(0, 1.96, 0), Vector3(0.5, 0.2, 0.5), _HAT],
		[Vector3(0, 1.9, 0), Vector3(0.52, 0.05, 0.52), _YELLOW],   # its band
	]
