extends GutTest
## Owner #122 (G0) in a headset (owner #101's readability audit): the play place's words are on the VR panel (UiLayers),
## every word 24 px or more as drawn there (VrReadability), and nothing past the panel's edge; the see-why card, the
## break card and a picture shown big too. The child stands at the station, and the board's picture faces their eyes.

const CONTENT := {"id": "g4.maths.big_numbers", "lesson": [{"text": "A digit's place tells what it is worth."}],
	"exercises": [
		{"type": "number", "prompt": "300 + 40 + 7 = ?", "answer": "347", "hint": "Put the parts together.", "level": 1,
			"picture": {"kind": "blocks", "hundreds": 3, "tens": 4, "ones": 7}},
		{"type": "sort", "prompt": "More than 100 or not?", "hint": "Hundreds.", "groups": ["more", "not more"],
			"items": ["347", "99", "120"], "answer": [0, 1, 0], "level": 2}]}

var host: PlayHost
var _profile: ProfileData


func before_each() -> void:
	_profile = Profile.data
	Profile.data = ProfileData.new()
	Vr.simulate(true)
	await wait_process_frames(2)


func after_each() -> void:
	if is_instance_valid(host) and not host.closed:
		host.close()
	Vr.simulate(false)
	Profile.data = _profile
	await wait_process_frames(2)


func _open() -> void:
	var parent := Node.new()
	add_child_autofree(parent)
	host = PlayHost.new()
	host.setup("g4.maths.big_numbers", CONTENT.duplicate(true), 3, 0, {"title": "Big numbers"})
	host.open(parent)
	await wait_physics_frames(2)
	await wait_process_frames(3)


func _outside(n: Node, out: Array[String]) -> void:
	var c := n as Control
	if c != null and not c.is_visible_in_tree():
		return
	if c != null and VrReadability.is_text(c) and VrReadability._words(c) != "":
		var t := c.get_global_transform()
		var r := Rect2(t.origin, c.size * t.get_scale())
		if not Rect2(Vector2.ZERO, Vector2(VrPanelRules.CANVAS)).grow(1.0).encloses(r):
			out.append("%s '%s' %s" % [c.name, VrReadability._words(c).left(24), r])
	for child in n.get_children():
		_outside(child, out)


func _check(what: String) -> void:
	await get_tree().create_timer(0.3).timeout   # pop-ins settle
	await wait_process_frames(2)
	assert_eq(VrReadability.too_small(host.hud.root), [] as Array[String], "%s: every word 24 px or more" % what)
	var out: Array[String] = []
	_outside(host.hud.root, out)
	assert_eq(out, [] as Array[String], "%s: no words past the panel's edge" % what)


func test_the_play_hud_is_readable_on_the_vr_panel() -> void:
	await _open()
	assert_true(host.vr)
	assert_eq(host.hud.get_parent(), Vr.ui_viewport(), "the HUD is on the VR panel")
	await _check("the hook")
	host.end_hook()
	await _check("a challenge")
	host.station().show_answer()
	host.check()
	await _check("answered")
	host.next()
	await _check("see why")
	host.hud.show_picture({"kind": "blocks", "hundreds": 3})
	await _check("the picture big")
	host.hud.hide_picture()
	host.hud.open_break()
	await _check("the break card")


func test_vr_the_board_faces_the_child_s_eyes() -> void:
	await _open()
	var board := host.arena.board
	assert_not_null(board)
	var to_eye := (host.stand.global_position - board.global_position).normalized()
	assert_gt(board.global_basis.z.normalized().dot(to_eye), 0.98, "the picture's face looks at the child")
