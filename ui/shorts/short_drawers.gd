class_name ShortDrawers
extends RefCounted
## The drawers of the Shorts' actor kinds (owner #96: pluggable): kind -> ShortDrawer. The built-in kinds
## (ShortRules.ACTOR_KINDS) share BuiltinDrawer, which runs ShortActor's own code. A new kind registers its drawer in
## `_builtins()` below (and its check in ShortKinds._builtins()).

static var _drawers := {}
static var _loaded := false


static func register(kind: String, drawer: ShortDrawer) -> void:
	_builtins()
	_drawers[kind] = drawer


static func unregister(kind: String) -> void:
	_drawers.erase(kind)


## The kind's drawer (an empty one for a kind nobody registered: it draws nothing).
static func get_drawer(kind: String) -> ShortDrawer:
	_builtins()
	return _drawers.get(kind, _EMPTY)


static func has(kind: String) -> bool:
	_builtins()
	return _drawers.has(kind)


static var _EMPTY := ShortDrawer.new()


static func _builtins() -> void:
	if _loaded:
		return
	_loaded = true
	var builtin := BuiltinDrawer.new()
	for k: String in ShortRules.ACTOR_KINDS:
		_drawers[k] = builtin
	# The Reel Studio's kinds (owner #96; ui/shorts/actors/): a 3D stage in a scene, a clip of a rendered reel.
	_drawers["scene3d"] = Scene3DDrawer.new()
	_drawers["video"] = VideoDrawer.new()
	# MAKE MY SHORT (spec §5.12b "As built (My Shorts)"): a photo of the album, the child's avatar, a wonder's stamp, a build.
	for k: String in MyShortRules.ACTOR_KINDS:
		_drawers[k] = MyShortDrawers.drawer(k)


## Words, School pictures, icons, planets, characters, arrows and lines, shapes, maps and counts: ShortActor's own code.
class BuiltinDrawer:
	extends ShortDrawer

	func setup(actor: ShortActor) -> void:
		actor.setup_builtin()

	func draw(actor: ShortActor) -> void:
		actor.draw_builtin()

	func update(actor: ShortActor, _state: Dictionary, _t: float) -> void:
		actor.update_builtin()
