extends GutTest
## The rooms' look brief (2026-10-17, docs/devlog/parts/rooms-look.md): every Life and Success practice room, on every
## track, looks like a real place and stays fast. It stands on a real floor under a sky; no sign covers a name tag from
## any step's view; its first view frames its people whole (their heads on the screen), crowds nothing against the camera
## across the middle of the view and cuts no text at its edges; its dressing never sits on a target, across a view's
## line to a target, across a VR reach or where the child stands; and from every place the child stands in VR, looking
## any of four ways, it draws within the Quest's budget (the HUD's canvas and the hands take the rest of the 100).

## The flat camera's canvas (the game's narrowest: 16:9) and its field of view (LifeRoomHost's camera).
const CANVAS := Vector2(1280, 720)
const FOV := 72.0
## The Quest's eye (about 100 degrees each way) for the draw budget.
const VR_FOV := 100.0
## The room's own draws from a VR stand, any way it looks: the frame's 100 less the HUD's canvas (25-29, measured with
## tools/room_shots.gd --vr) and the hands, the beam and the panel (about 4).
const VR_ROOM_DRAWS := 66
## Nothing nearer the first view's camera than this across the middle of the view.
const CROWD := 0.5

var _view: SubViewport
var _cam: Camera3D


func before_all() -> void:
	Profile.data.settings.reduce_motion = true


func after_all() -> void:
	Profile.data.settings.reduce_motion = false
	Audio.stop_all()


func before_each() -> void:
	_view = SubViewport.new()
	_view.size = Vector2i(CANVAS)
	add_child_autofree(_view)
	_cam = Camera3D.new()
	_cam.fov = FOV
	_view.add_child(_cam)


func _room(exp_id: String, track: String, seed: int = 1) -> LifeRoom:
	var r := LifeRooms.make(str(LifeExperience.data(exp_id).room), track, LifeExperience.vars(exp_id, track, seed, "ge"))
	add_child_autofree(r)
	return r


## Every Experience's room on every track (ROOM_LOOK_ONLY=talk_deal,my_shop in the environment: only those, while
## working on a room's look).
func _rooms() -> Array[Array]:
	var out: Array[Array] = []
	var only := OS.get_environment("ROOM_LOOK_ONLY").split(",", false)
	for id: String in LifeExperience.IDS:
		if id == RealBuilder.ID or (not only.is_empty() and not only.has(id)):
			continue   # the Tools' building site (entities/tools): its own look; it shares only the sky, the sun and the tone
		for track: String in LifeData.TRACKS:
			out.append([id, track])
	return out


func _first_view(room: LifeRoom, id: String, track: String) -> String:
	var steps := LifeExperience.steps(id, track, false, 2, "ge")
	return str(steps[0].get("view", room.start_view)) if not steps.is_empty() else room.start_view


## Plays a try's steps in order (their events as the host plays them), calling `at` with each step at its start.
func _walk(room: LifeRoom, id: String, track: String, at: Callable) -> void:
	for expert: bool in [false, true]:
		for step: Dictionary in LifeExperience.steps(id, track, expert, 2, "ge"):
			if str(step.get("react", "")) != "":
				room.react(str(step.react))
			room.step_started(step)
			at.call(step, expert)
			if str(step.get("after", "")) != "":
				room.react(str(step.after))
			room.step_done(step)
		if not expert:
			break


# --- 1. A real floor and a sky --------------------------------------------------------------------------------------

func test_every_room_stands_on_a_real_floor_under_a_sky() -> void:
	for pair in _rooms():
		var room := _room(pair[0], pair[1])
		var where := "%s.%s" % pair
		var skies := room.look_pieces.filter(func(p: Dictionary) -> bool: return str(p.kind) == LifeRoomDecor.SKY)
		assert_eq(skies.size(), 1, where + ": a sky round the room")
		var feet: Vector3 = room.view(room.start_view).feet
		var floors := room.look_pieces.filter(func(p: Dictionary) -> bool:
			var b: AABB = p.box
			return str(p.kind) == LifeRoomDecor.SHELL and absf(b.end.y) < 0.12 and b.size.y < 0.6 \
				and feet.x > b.position.x and feet.x < b.end.x and feet.z > b.position.z and feet.z < b.end.z)
		assert_gt(floors.size(), 0, where + ": a real floor under where the child starts (%s)" % feet)
		room.free()


# --- 2. Signs keep clear of name tags --------------------------------------------------------------------------------

func test_no_sign_covers_a_name_tag_from_any_steps_view() -> void:
	for pair in _rooms():
		var room := _room(pair[0], pair[1])
		var where := "%s.%s" % pair
		var seen := {}
		_walk(room, pair[0], pair[1], func(step: Dictionary, _expert: bool) -> void:
			var v := str(step.get("view", room.start_view))
			_cam.global_transform = room.camera_transform(v)
			for clash in LifeRoomLook.signs_over_tags(room, _cam, CANVAS):
				var k := "%s %s" % [v, clash]
				if not seen.has(k):
					seen[k] = true
					fail_test("%s %s (%s): %s" % [where, step.id, v, clash]))
		room.free()
	pass_test("checked")


func test_no_dressing_covers_a_signs_words() -> void:
	for pair in _rooms():
		var room := _room(pair[0], pair[1])
		_cam.global_transform = room.camera_transform(_first_view(room, pair[0], pair[1]))
		for clash in LifeRoomLook.words_covered(room, _cam):
			fail_test("%s.%s: %s" % [pair[0], pair[1], clash])
		room.free()
	pass_test("checked")


# --- 3. The first view ---------------------------------------------------------------------------------------------

func test_every_first_view_frames_its_people_whole() -> void:
	for pair in _rooms():
		var room := _room(pair[0], pair[1])
		_cam.global_transform = room.camera_transform(_first_view(room, pair[0], pair[1]))
		for cut in LifeRoomLook.heads_cut(room, _cam, CANVAS):
			fail_test("%s.%s: %s" % [pair[0], pair[1], cut])
		room.free()
	pass_test("checked")


func test_nothing_crowds_the_first_views_camera() -> void:
	for pair in _rooms():
		var room := _room(pair[0], pair[1])
		_cam.global_transform = room.camera_transform(_first_view(room, pair[0], pair[1]))
		for near in LifeRoomLook.crowding(room, _cam, CANVAS, CROWD):
			fail_test("%s.%s: %s" % [pair[0], pair[1], near])
		room.free()
	pass_test("checked")


func test_no_text_is_cut_at_the_first_views_edges() -> void:
	for pair in _rooms():
		var room := _room(pair[0], pair[1])
		_cam.global_transform = room.camera_transform(_first_view(room, pair[0], pair[1]))
		for cut in LifeRoomLook.text_cut(room, _cam, CANVAS):
			fail_test("%s.%s: %s" % [pair[0], pair[1], cut])
		room.free()
	pass_test("checked")


# --- 4. Never in the way -------------------------------------------------------------------------------------------

func test_the_dressing_keeps_clear_of_targets_lines_reaches_and_stands() -> void:
	for pair in _rooms():
		var room := _room(pair[0], pair[1])
		var where := "%s.%s" % pair
		var seen := {}
		_walk(room, pair[0], pair[1], func(step: Dictionary, _expert: bool) -> void:
			var v := str(step.get("view", room.start_view))
			for clash in LifeRoomLook.in_the_way(room, step, v):
				if not seen.has(clash):
					seen[clash] = true
					fail_test("%s %s (%s): %s" % [where, step.id, v, clash]))
		room.free()
	pass_test("checked")


# --- 5. The Quest's draws --------------------------------------------------------------------------------------------

func test_every_room_draws_within_the_quests_budget_from_every_vr_stand() -> void:
	var vr_cam := Camera3D.new()
	vr_cam.fov = VR_FOV
	var square := SubViewport.new()
	square.size = Vector2i(1000, 1000)
	add_child_autofree(square)
	square.add_child(vr_cam)
	var table: Array[String] = []
	for pair in _rooms():
		var room := _room(pair[0], pair[1])
		var most := {"n": 0, "at": "", "seen": []}   # a lambda's locals are copies: a Dictionary carries the answer out
		_walk(room, pair[0], pair[1], func(step: Dictionary, _expert: bool) -> void:
			var v := str(step.get("view", room.start_view))
			var stand := room.vr_stand(v)
			for turn in 4:
				vr_cam.global_transform = Transform3D(stand.basis.rotated(Vector3.UP, turn * PI * 0.5), stand.origin)
				var seen: Array = []
				var n := LifeRoomLook.draws_seen(room, vr_cam, seen)
				if n > int(most.n):
					most.n = n
					most.seen = seen
					most.at = "%s %s turn %d" % [step.id, v, turn])
		if OS.get_environment("ROOM_LOOK_DRAWS_LIST") != "":   # which draws the heaviest stand sees
			gut.p("ROOM_LOOK_DRAWS_LIST %s.%s: %s" % [pair[0], pair[1], ", ".join(most.seen)])
		table.append("%s.%s %d (%s)" % [pair[0], pair[1], most.n, most.at])
		assert_lte(int(most.n), VR_ROOM_DRAWS, "%s.%s: %d draws at %s" % [pair[0], pair[1], most.n, most.at])
		room.free()
	gut.p("ROOM_LOOK_VR_DRAWS " + ", ".join(table))
