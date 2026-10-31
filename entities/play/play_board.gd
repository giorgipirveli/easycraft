class_name PlayBoard
extends Node3D
## Owner #122 (G0, the brief: "the exercise's picture shows in the place on a board"): a picture of the School
## (SchoolPicture, any kind) drawn once into its own small 2D canvas (a SubViewport: it draws again only while the
## picture moves) and shown on a framed board in the place. The board's face is a copy of Life's room kit's see-through
## material with the picture as its texture: the mirror wall's settings, a shader the warm-up already holds.

const FRAME := Color("8a6239")

var picture: SchoolPicture
var canvas: SubViewport
var face: MeshInstance3D
var size := Vector2.ONE


## `data` is SchoolPicture data, `board_size` the face in metres, `pixels` the canvas it is drawn at.
func _init(data: Dictionary = {}, board_size: Vector2 = Vector2(1.3, 0.56), pixels: Vector2i = Vector2i(580, 250)) -> void:
	name = "PlayBoard"
	size = board_size
	canvas = SubViewport.new()
	canvas.name = "Canvas"
	canvas.size = pixels
	canvas.disable_3d = true
	canvas.transparent_bg = false
	picture = SchoolPicture.new(data, Vector2(pixels))
	picture.size = Vector2(pixels)
	picture.playing = SchoolPicture.should_play(data, true)   # still unless it asks to move (as the School's panel)
	canvas.render_target_update_mode = SubViewport.UPDATE_ALWAYS if picture.playing else SubViewport.UPDATE_ONCE
	var paper := ColorRect.new()
	paper.color = SchoolUi.PAPER
	paper.size = Vector2(pixels)
	canvas.add_child(paper)
	canvas.add_child(picture)
	add_child(canvas)
	LifeRoomKit.box(self, "Frame", Vector3(size.x + 0.06, size.y + 0.06, 0.03), Vector3(0, 0, -0.02), FRAME)
	face = MeshInstance3D.new()
	face.name = "Face"
	var quad := QuadMesh.new()
	quad.size = size
	face.mesh = quad
	var mat := LifeRoomKit.material(Color.WHITE, true).duplicate() as StandardMaterial3D
	mat.albedo_texture = canvas.get_texture()
	face.material_override = mat
	face.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(face)


## The face's four corners (global): the flat view keeps them all on the screen.
func corners() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for c: Vector2 in [Vector2(-0.5, -0.5), Vector2(0.5, -0.5), Vector2(0.5, 0.5), Vector2(-0.5, 0.5)]:
		out.append(to_global(Vector3(c.x * size.x, c.y * size.y, 0)))
	return out
