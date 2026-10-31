class_name LifeRoomSun
extends DirectionalLight3D
## The rooms' look brief (2026-10-17): a practice room's own warm key light. The room hangs far above the world it was
## opened from (LifeRoomHost.ROOM_ORIGIN), and that world's sun lit it as the world's clock said: a white noon, a red
## sunset, the moon. While the room shows, its own sun is the only one: the world's suns are put away (hidden: the
## rocket flight does the same, `flight.world_light`) and given back when the room goes, those it hid only. No shadows
## (the Quest's budget, and the rooms' rule), and no disc in a sky (the rooms draw their own).

var _away: Array[WeakRef] = []


func _init(colour: Color = Color(1.0, 0.95, 0.86), energy: float = 1.0, pitch_deg: float = -52.0, yaw_deg: float = -28.0) -> void:
	name = "RoomSun"
	light_color = colour
	light_energy = energy
	rotation_degrees = Vector3(pitch_deg, yaw_deg, 0)
	shadow_enabled = false
	sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	light_specular = 0.4


func _enter_tree() -> void:
	_away.clear()
	var tree := get_tree()
	if tree == null:
		return
	for n: Node in tree.root.find_children("*", "DirectionalLight3D", true, false):
		var l := n as DirectionalLight3D
		if l == self or l is LifeRoomSun or not l.visible:
			continue
		l.visible = false
		_away.append(weakref(l))


func _exit_tree() -> void:
	for w in _away:
		var l := w.get_ref() as DirectionalLight3D
		if l != null:
			l.visible = true
	_away.clear()
