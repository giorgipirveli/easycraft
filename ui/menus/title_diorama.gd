class_name TitleDiorama
extends Node3D
## The living title diorama (M5 Task 2, spec §15.2): beside the menu's wordmark, a floating grass island rides in
## front of the menu's orbiting camera (a child of it; the visuals brief, 2026-10-01: left of the wordmark, small
## enough for every screen shape, TitleDioramaRules.place: under the wordmark it hid behind the menu's panels). On it
## the brand's orange buddy (googly eyes, the wand's star in its hand) sleeps; the star sparkles,
## it wakes, hops twice and waves; the dog beside it hops and wags; then it dozes off again (TitleDioramaRules, a
## 12 s loop). The island turns slowly to and fro.
## Cheap: its meshes are made once and shared (the island by the voxel mesher with the world's own block materials,
## the buddy and the dog with the animals' one vertex-colour material, the sparkle with Fx's), nothing is made per
## frame (the sparkle is one emitter, restarted), no shadows. With Reduce motion it is hidden and does nothing.

const TILT := 0.32                          # radians: its top turned towards the camera
const BUDDY_AT := Vector3(-1.1, 0.0, 0.2)
const DOG_AT := Vector3(1.4, 0.0, 0.45)
const ARM_PIVOT := Vector3(0.58, 0.62, 0.0)
const EYES_AT := Vector3(0.0, 0.64, 0.0)
const STAR_AT := Vector3(-0.72, 1.3, 0.12)  # the wand's star, in the buddy's space
const ORANGE := Color("f28c28")
const ORANGE_DARK := Color("c96a12")
const GOLD := Color("ffd23f")
const WAND := Color("8a5a2b")
const SPARKLES := 10

var stage := Node3D.new()
var island := MeshInstance3D.new()
var buddy := Node3D.new()
var body := MeshInstance3D.new()
var eyes := MeshInstance3D.new()
var arm := MeshInstance3D.new()
var star := MeshInstance3D.new()
var dog := MeshInstance3D.new()
var tail := MeshInstance3D.new()
var sparkle := CPUParticles3D.new()
## Its own small warm light from the camera's side: the world's sun turns round it as the camera orbits (it would
## light the buddy from behind half the time). No shadows; it reaches nothing but the island.
var light := OmniLight3D.new()
var rest_y := 0.0

var _t := 0.0

static var _island_mesh: Mesh
static var _body_mesh: ArrayMesh
static var _eyes_mesh: ArrayMesh
static var _arm_mesh: ArrayMesh
static var _star_mesh: ArrayMesh


func _ready() -> void:
	name = "TitleDiorama"
	_place()
	get_viewport().size_changed.connect(_place)
	add_child(stage)
	island.name = "Island"
	island.mesh = island_mesh()
	island.position = Vector3(-3.5, -3.0, -1.5)   # the mesh's blocks from 0: its grass top at y 0, centred
	stage.add_child(island)
	buddy.name = "Buddy"
	buddy.position = BUDDY_AT
	buddy.rotation.y = 0.35                        # a little towards the dog
	stage.add_child(buddy)
	body.name = "Body"
	body.mesh = body_mesh()
	buddy.add_child(body)
	eyes.name = "Eyes"
	eyes.mesh = eyes_mesh()
	eyes.position = EYES_AT
	buddy.add_child(eyes)
	arm.name = "Arm"
	arm.mesh = arm_mesh()
	arm.position = ARM_PIVOT
	buddy.add_child(arm)
	star.name = "Star"
	star.mesh = star_mesh()
	star.position = STAR_AT
	buddy.add_child(star)
	dog.name = "Dog"
	dog.mesh = BlockyAnimal.mesh_for(&"dog")
	dog.position = DOG_AT
	dog.rotation.y = PI - 0.7                      # facing the camera, turned towards the buddy
	stage.add_child(dog)
	tail.name = "Tail"
	tail.mesh = BlockyAnimal.part_mesh_for(&"dog")
	tail.position = BlockyAnimal.PART_PIVOT[&"dog"]
	dog.add_child(tail)
	for m: MeshInstance3D in [island, body, eyes, arm, star, dog, tail]:
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_setup_sparkle()
	light.name = "Light"
	light.position = Vector3(0.5, 3.0, 5.0)
	light.omni_range = 8.0
	light.light_energy = 1.8
	light.light_color = Color(1.0, 0.95, 0.85)
	light.shadow_enabled = false
	add_child(light)
	rest_y = buddy.position.y
	if not Game.settings_applied.is_connected(_apply):
		Game.settings_applied.connect(_apply)
	_apply(Profile.data.settings)
	step(0.0)


func _exit_tree() -> void:
	if Game.settings_applied.is_connected(_apply):
		Game.settings_applied.disconnect(_apply)
	if get_viewport().size_changed.is_connected(_place):
		get_viewport().size_changed.disconnect(_place)


## Beside the wordmark, sized for the screen's shape (TitleDioramaRules.place; the visuals brief).
func _place() -> void:
	var size := get_viewport().get_visible_rect().size
	var p := TitleDioramaRules.place(size.x / maxf(size.y, 1.0))
	position = p.position
	# its top and its front turned a little more towards the camera, which sees it from below and from its right
	rotation = Vector3(TILT + 0.5 * atan2(position.y, -position.z), -0.6 * atan2(position.x, -position.z), 0.0)
	scale = Vector3.ONE * float(p.scale)


## Reduce motion: hidden and still.
func _apply(settings: Dictionary) -> void:
	visible = not bool(settings.get("reduce_motion", false))
	set_process(visible)


func _process(delta: float) -> void:
	step(delta)


## Seconds into its loop, counted from the start.
func time() -> float:
	return _t


## `delta` seconds of the diorama (tests step it): only transforms change.
func step(delta: float) -> void:
	var before := _t
	_t += delta
	if delta > 0.0 and TitleDioramaRules.sparkles(before, _t):
		Fx.calm(sparkle, SPARKLES)   # M5 Tasks 1 and 3: Reduce motion and the graphics preset (a pooled burst)
		sparkle.restart()
		sparkle.emitting = true
	stage.rotation.y = TitleDioramaRules.sway(_t)
	buddy.position.y = rest_y + TitleDioramaRules.buddy_lift(_t)
	buddy.scale.y = 1.0 + TitleDioramaRules.breath(_t) * (1.0 - smoothstep(0.1, 0.3, TitleDioramaRules.eyes(_t)))
	eyes.scale.y = TitleDioramaRules.eyes(_t)
	arm.rotation.z = TitleDioramaRules.wave(_t)
	dog.position.y = DOG_AT.y + TitleDioramaRules.dog_lift(_t)
	tail.rotation.y = TitleDioramaRules.wag(_t)


## The wand's sparkle: one emitter of Fx's gold stars (Fx's shared material), restarted once a loop.
func _setup_sparkle() -> void:
	sparkle.name = "Sparkle"
	sparkle.one_shot = true
	sparkle.emitting = false
	sparkle.amount = SPARKLES
	sparkle.lifetime = 0.9
	sparkle.explosiveness = 0.9
	sparkle.mesh = Fx.star_mesh()
	sparkle.color = Fx.WAKE_GOLD
	sparkle.direction = Vector3.UP
	sparkle.spread = 180.0
	sparkle.initial_velocity_min = 0.8
	sparkle.initial_velocity_max = 1.6
	sparkle.gravity = Vector3(0, 1.2, 0)
	sparkle.scale_amount_min = 0.4
	sparkle.scale_amount_max = 0.8
	sparkle.angular_velocity_min = -180.0
	sparkle.angular_velocity_max = 180.0
	sparkle.position = STAR_AT
	buddy.add_child(sparkle)


# --- The shared meshes (made once) ------------------------------------------------------------------------------

## A floating island: 7 x 3 grass on top, dirt tapering below, meshed by the voxel mesher with the world's own
## block library (its materials are the terrain's, already compiled by the menu's world).
static func island_mesh() -> Mesh:
	if _island_mesh == null:
		var buf := VoxelBuffer.new()
		buf.create(7 + 2, 3 + 2, 3 + 2)
		for x in 7:
			for z in 3:
				buf.set_voxel(BlockIds.GRASS, x + 1, 3, z + 1, VoxelBuffer.CHANNEL_TYPE)
				if x >= 1 and x <= 5:
					buf.set_voxel(BlockIds.DIRT, x + 1, 2, z + 1, VoxelBuffer.CHANNEL_TYPE)
				if x >= 2 and x <= 4 and z == 1:
					buf.set_voxel(BlockIds.DIRT, x + 1, 1, z + 1, VoxelBuffer.CHANNEL_TYPE)
		var mesher := VoxelMesherBlocky.new()
		mesher.library = WorldService.library()
		_island_mesh = mesher.build_mesh(buf, [], {})
	return _island_mesh


## The buddy: an orange block with a darker bottom, a short left arm holding the wand (the star is its own mesh).
static func body_mesh() -> ArrayMesh:
	if _body_mesh == null:
		_body_mesh = BlockyAnimal._build([
			[Vector3(0, 0.5, 0), Vector3(1.0, 0.8, 1.0), ORANGE],
			[Vector3(0, 0.05, 0), Vector3(1.02, 0.1, 1.02), ORANGE_DARK],
			[Vector3(0, 0.95, 0), Vector3(0.9, 0.1, 0.9), ORANGE],
			[Vector3(-0.6, 0.55, 0.1), Vector3(0.2, 0.2, 0.2), ORANGE],         # the left hand
			[Vector3(-0.72, 0.85, 0.12), Vector3(0.07, 0.8, 0.07), WAND],       # the wand
		])
	return _body_mesh


## Two googly eyes on its front (+Z faces the camera): white squares with dark pupils; scaled in y to blink.
static func eyes_mesh() -> ArrayMesh:
	if _eyes_mesh == null:
		var boxes := []
		for side in [-0.22, 0.22]:
			boxes.append([Vector3(side, 0.0, 0.51), Vector3(0.3, 0.3, 0.04), BlockyAnimal.WHITE])
			boxes.append([Vector3(side + 0.04, -0.03, 0.535), Vector3(0.13, 0.13, 0.03), BlockyAnimal.BLACK])
		_eyes_mesh = BlockyAnimal._build(boxes)
	return _eyes_mesh


## The right arm, hanging from its shoulder (its pivot): it swings up to wave.
static func arm_mesh() -> ArrayMesh:
	if _arm_mesh == null:
		_arm_mesh = BlockyAnimal._build([[Vector3(0.1, -0.2, 0.0), Vector3(0.2, 0.42, 0.2), ORANGE]])
	return _arm_mesh


## The wand's star: a gold plus with a white middle (blocky, like everything else).
static func star_mesh() -> ArrayMesh:
	if _star_mesh == null:
		_star_mesh = BlockyAnimal._build([
			[Vector3.ZERO, Vector3(0.42, 0.12, 0.06), GOLD],
			[Vector3.ZERO, Vector3(0.12, 0.42, 0.06), GOLD],
			[Vector3(0, 0, 0.02), Vector3(0.1, 0.1, 0.06), Color.WHITE],
		])
	return _star_mesh
