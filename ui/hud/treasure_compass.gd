class_name TreasureCompass
extends Control
## The treasure map's compass (M2 Task 16): while the player holds a treasure map, an arrow points to the
## nearest buried treasure not opened yet, with the distance under it. The target is looked up once a
## second; the arrow follows the camera every frame. Hidden otherwise. Top right, left of the buttons.

const LOOKUP_EVERY := 1.0
const SIZE := Vector2(104, 128)
const DIAL := 44.0

## Owner #88: on a planet with a guide (PlanetGuideRules), with no treasure map in hand, the arrow points to the guide's
## next place: (from: Vector3) -> {"chest": Vector3i} or {} (the sandbox sets it).
var guide := Callable()
var director: SecretDirector
var interactor: BlockInteractor
var player: Player
var angle := 0.0                  # radians from straight ahead, positive to the right
var distance := -1                # blocks (sideways); -1: no treasure near
var _target := {}
var _lookup := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	HudLayout.place(self, &"compass")   # top right, left of WALK (M2 Task 17)
	visible = false


func setup(secrets: SecretDirector, block_interactor: BlockInteractor, p: Player) -> void:
	director = secrets
	interactor = block_interactor
	player = p


func holding_map() -> bool:
	return is_instance_valid(interactor) and interactor.selected_block() == ItemIds.TREASURE_MAP


func _process(delta: float) -> void:
	var show := (holding_map() and director != null or guided()) and is_instance_valid(player) and player.is_spawned()
	if visible != show:
		visible = show
		_lookup = 0.0
	if not show:
		return
	_lookup -= delta
	if _lookup <= 0.0:
		_lookup = LOOKUP_EVERY
		_target = current_target(player.global_position)
	update(player.global_position, player.rig.yaw)


## Points the arrow from `from` for a camera turned to `yaw` (tests call it directly).
func update(from: Vector3, yaw: float) -> void:
	if _target.is_empty():
		distance = -1
	else:
		var c: Vector3i = _target.chest
		var r := SurpriseRules.compass(from, Vector3(c) + Vector3(0.5, 0.5, 0.5), yaw)
		angle = r.angle
		distance = r.distance
	queue_redraw()


## The treasure's chest while a map is in hand, else the guide's next place ({} = none).
func current_target(from: Vector3) -> Dictionary:
	if holding_map() and director != null:
		return director.map_target(from)
	return guide.call(from) if guide.is_valid() else {}


## Pointing for the planet guide (no map in hand, a guide with a place left).
func guided() -> bool:
	return guide.is_valid() and not holding_map() and not (guide.call(Player.position_or_none(player) \
		if is_instance_valid(player) else Vector3.ZERO) as Dictionary).is_empty()


func set_target(target: Dictionary) -> void:
	_target = target
	_lookup = LOOKUP_EVERY


func _draw() -> void:
	var c := Vector2(SIZE.x * 0.5, DIAL + 6.0)
	draw_circle(c, DIAL, Color(0.93, 0.86, 0.68, 0.95))
	draw_arc(c, DIAL, 0.0, TAU, 40, Color("7a4a24"), 4.0)
	var font := get_theme_default_font()
	if distance < 0:
		draw_string(font, c + Vector2(-10, 14), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 40, Color("7a4a24"))
		return
	var tip := c + Vector2(sin(angle), -cos(angle)) * (DIAL - 8.0)
	var back := c - Vector2(sin(angle), -cos(angle)) * (DIAL * 0.45)
	var side := Vector2(cos(angle), sin(angle)) * 12.0
	draw_colored_polygon(PackedVector2Array([tip, back + side, c, back - side]), Color("d9302a"))
	draw_circle(c, 5.0, Color("7a4a24"))
	var text := tr("%d m") % distance
	draw_string_outline(font, Vector2(0, SIZE.y - 6), text, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 26, 6, Color(0, 0, 0, 0.85))
	draw_string(font, Vector2(0, SIZE.y - 6), text, HORIZONTAL_ALIGNMENT_CENTER, SIZE.x, 26, Color("fff3c4"))
