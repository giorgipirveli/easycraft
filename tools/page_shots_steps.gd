extends Node
## The steps of tools/page_shots.gd (a driver node: the SceneTree script stays bare).

const SIZE := Vector2i(2400, 1080)   # the emulator's landscape screen (Pixel 8)
const FOV := 70.0                    # the player's camera (entities/player/player.tscn)
## The blocks on the wall, one column of three per page: page 0 (the first atlas), then every page in its order.
const PAGES := [0, 1, 2, 8, 9, 10, 11, 12, 13, 14]
const SHOTS := {"phone": [Vector3(4.5, 1.9, 4.0), Vector3(4.5, 1.2, 0.0)],
	"close_left": [Vector3(1.0, 1.9, 1.6), Vector3(1.0, 1.4, 0.0)],
	"close_middle": [Vector3(4.5, 1.9, 1.6), Vector3(4.5, 1.4, 0.0)],
	"close_right": [Vector3(8.0, 1.9, 1.6), Vector3(8.0, 1.4, 0.0)]}

var _out := ""
var _tag := "now"


func _ready() -> void:
	for a: String in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			_out = a.trim_prefix("--out=")
		elif a.begins_with("--tag="):
			_tag = a.trim_prefix("--tag=")
	if _out == "" or DisplayServer.get_name() == "headless":
		print("PAGE_SHOT refused: needs a window and --out=<dir>")
		get_tree().quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_out)
	await _run()
	get_tree().quit()


## Three opaque blocks of `page` (the page's first ids), for the wall.
func _blocks_of(page: int) -> Array[int]:
	var out: Array[int] = []
	if page == 0:
		out.assign([BlockIds.STONE, BlockIds.PLANKS, BlockIds.GRASS])
		return out
	var table: Dictionary = BlockLibrary._pages[page].tiles
	var ids: Array = table.keys()
	ids.sort()
	for id: int in ids:
		var t: Array = table[id]
		if (t.size() <= 3 or t[3] == &"opaque") and not (t.size() > 4 and t[4] is Dictionary and (t[4] as Dictionary).has("cross")):
			out.append(id)
		if out.size() == 3:
			break
	return out


func _run() -> void:
	var lib := BlockLibrary.build()
	var vp := SubViewport.new()
	vp.size = SIZE
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.msaa_3d = Viewport.MSAA_DISABLED
	add_child(vp)
	var env := Environment.new()
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35.0, -60.0, 0.0)   # low and from the side: the relief shows
	sun.shadow_enabled = true
	vp.add_child(sun)
	var buf := VoxelBuffer.new()
	buf.create(PAGES.size() + 2, 5, 3)
	for i in PAGES.size():
		var ids := _blocks_of(PAGES[i])
		for y in ids.size():
			buf.set_voxel(ids[y], i + 1, y + 1, 1, VoxelBuffer.CHANNEL_TYPE)
	var mesher := VoxelMesherBlocky.new()
	mesher.library = lib
	var wall := MeshInstance3D.new()
	wall.mesh = mesher.build_mesh(buf, [], {})
	wall.position = Vector3(0.0, 0.0, -1.0)   # mesh coords = buffer coords - 1: block (i, y) at x = i, front face at z = 0
	vp.add_child(wall)
	var cam := Camera3D.new()
	cam.fov = FOV
	vp.add_child(cam)
	cam.current = true
	for style: String in ["blocky", "realistic"]:
		BlockLibrary.set_style(style)
		for shot: String in SHOTS:
			var at: Array = SHOTS[shot]
			cam.position = at[0]
			cam.look_at(at[1])
			for i in 8:
				await RenderingServer.frame_post_draw
			var path := _out.path_join("%s_%s_%s.png" % [_tag, style, shot])
			vp.get_texture().get_image().save_png(path)
			print("PAGE_SHOT %s" % path)
