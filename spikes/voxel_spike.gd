extends Node3D
## Throwaway Voxel Tools feasibility check (plan Task 2). Logs lines prefixed "SPIKE".

const SAVE_DIR := "user://spike"
const EDIT_POS := Vector3i(0, 40, 0)
const STONE := 2

var _terrain: VoxelTerrain
var _cam: Camera3D
var _vt: VoxelTool
var _t := 0.0
var _fps_acc := 0.0
var _fps_frames := 0
var _max_frame_ms := 0.0
var _edited := false
var _checked := false


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	var lib := VoxelBlockyLibrary.new()
	var models: Array = [VoxelBlockyModelEmpty.new(), _cube(Color(0.35, 0.8, 0.3)), _cube(Color(0.55, 0.55, 0.6))]
	lib.models = models
	lib.bake()
	var mesher := VoxelMesherBlocky.new()
	mesher.library = lib
	_terrain = VoxelTerrain.new()
	_terrain.mesher = mesher
	_terrain.generator = preload("res://spikes/spike_generator.gd").new()
	var stream := VoxelStreamSQLite.new()
	stream.database_path = ProjectSettings.globalize_path(SAVE_DIR + "/voxels.sqlite")
	_terrain.stream = stream
	_terrain.max_view_distance = 128
	add_child(_terrain)
	_vt = _terrain.get_voxel_tool()
	_vt.channel = VoxelBuffer.CHANNEL_TYPE

	_cam = Camera3D.new()
	_cam.position = Vector3(0, 60, 0)
	_cam.rotation_degrees = Vector3(-25, 0, 0)
	_cam.add_child(VoxelViewer.new())
	add_child(_cam)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	add_child(sun)
	print("SPIKE start os=", OS.get_name(), " renderer=", RenderingServer.get_current_rendering_method())


func _cube(color: Color) -> VoxelBlockyModelCube:
	var m := VoxelBlockyModelCube.new()
	m.atlas_size_in_tiles = Vector2i(1, 1)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.vertex_color_use_as_albedo = true
	m.set_material_override(0, mat)
	return m


func _process(delta: float) -> void:
	_t += delta
	_cam.position.z -= 8.0 * delta
	_fps_acc += delta
	_fps_frames += 1
	if _t > 4.0:
		_max_frame_ms = maxf(_max_frame_ms, delta * 1000.0)
	if not _checked and _t > 2.0:
		_checked = true
		print("SPIKE persisted=", _vt.get_voxel(EDIT_POS))
	if not _edited and _t > 3.0:
		_edited = true
		_vt.set_voxel(EDIT_POS, STONE)
		print("SPIKE get_voxel=", _vt.get_voxel(EDIT_POS))
		_terrain.save_modified_blocks()
		print("SPIKE saved db=", ProjectSettings.globalize_path(SAVE_DIR + "/voxels.sqlite"), " user=", OS.get_user_data_dir())
		get_tree().create_timer(1.0).timeout.connect(func() -> void:
			var f := FileAccess.open("user://web_sync.txt", FileAccess.WRITE)
			f.store_string(str(Time.get_ticks_msec()))
			f.close()
			print("SPIKE synced"))
	if _fps_acc >= 5.0:
		print("SPIKE fps=%.1f max_frame_ms=%.1f t=%.0f" % [_fps_frames / _fps_acc, _max_frame_ms, _t])
		_fps_acc = 0.0
		_fps_frames = 0
