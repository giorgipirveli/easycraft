extends GutTest
## M2 Task 5: the stealth HUD — the CROUCH button where DOWN sits when walking, a small eye (open /
## half / closed) and noise bars under the hearts (icons, not numbers), the cosy view from inside a
## hiding spot, and the danger arrow for a monster that sees you from behind or off-screen (research
## A3: it glows, fades and never nags).

const DT := 1.0 / 60.0


func _hud() -> Hud:
	var hud := Hud.new()
	add_child_autofree(hud)
	return hud


func _player(peer: int = 0) -> Player:
	var p: Player = load("res://entities/player/player.tscn").instantiate()
	p.name = str(peer if peer != 0 else multiplayer.get_unique_id())
	add_child_autofree(p)
	p.set_physics_process(false)
	p.viewer.free()
	p._spawned = true
	return p


func _director(p: Player) -> StealthDirector:
	var d := StealthDirector.new()
	d.local_player = p
	add_child_autofree(d)
	return d


# --- CROUCH ---

func test_crouch_sits_where_down_sits_when_walking() -> void:
	var hud := _hud()
	hud._on_physics_mode_changed(PhysicsMode.Mode.NORMAL)
	assert_true(hud.crouch_button.visible, "walking: CROUCH")
	assert_false(hud.fly_down_button.visible)
	assert_eq(hud.crouch_button.get_rect(), hud.fly_down_button.get_rect(), "the same spot")
	assert_eq(hud.crouch_button.action, &"crouch", "it presses the C key's action")
	hud._on_physics_mode_changed(PhysicsMode.Mode.FLY)
	assert_false(hud.crouch_button.visible, "flying: DOWN")
	assert_true(hud.fly_down_button.visible)
	hud._on_physics_mode_changed(PhysicsMode.Mode.NORMAL)
	hud.set_swimming(true)
	assert_false(hud.crouch_button.visible, "swimming: DOWN dives")


func test_desktop_has_no_crouch_button() -> void:
	var hud := _hud()
	hud.jump_button.visible = false     # setup() hides the touch controls on desktop
	hud._on_physics_mode_changed(PhysicsMode.Mode.NORMAL)
	assert_false(hud.crouch_button.visible, "C crouches there")


func test_the_crouch_button_lights_up_while_crouching() -> void:
	var hud := _hud()
	var p := _player()
	hud.player = p
	p.set_crouching(true)
	hud._update_stealth()
	assert_true(hud.crouch_button.selected)
	p.set_crouching(false)
	hud._update_stealth()
	assert_false(hud.crouch_button.selected)


# --- The eye and the noise bars ---

func test_the_eye_and_noise_bars_sit_under_the_hearts() -> void:
	var hud := _hud()
	var r := hud.stealth_meter.get_rect()
	assert_eq(r.position.x, Hud.HEARTS_POS.x, "lined up with the hearts")
	assert_gt(r.position.y, Hud.HEARTS_POS.y + HeartsBar.HEART_SIZE, "below them")
	assert_lt(r.end.y, 100.0, "clear of the potion chips and the toasts")
	assert_eq(hud.stealth_meter.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_the_eye_opens_and_closes_with_visibility() -> void:
	var p := _player()
	var meter := StealthMeter.new()
	add_child_autofree(meter)
	meter.player = p
	meter.director = _director(p)
	meter.refresh()
	assert_eq(meter.eye_state, StealthRules.EYE_OPEN, "daylight")
	p.stealth_light = StealthRules.NIGHT
	meter.refresh()
	assert_eq(meter.eye_state, StealthRules.EYE_HALF, "night")
	p.stealth_in_bush = true
	p.set_crouching(true)
	meter.refresh()
	assert_eq(meter.eye_state, StealthRules.EYE_CLOSED, "crouching in a bush: they can't see me")


func test_the_noise_bars_follow_the_noise() -> void:
	var p := _player()
	var meter := StealthMeter.new()
	add_child_autofree(meter)
	meter.player = p
	meter.director = _director(p)
	meter.refresh()
	assert_eq(meter.bars, 0, "standing still")
	p.velocity = Vector3(6, 0, 0)
	meter.refresh()
	assert_eq(meter.bars, 2, "walking")
	p.set_crouching(true)
	meter.refresh()
	assert_eq(meter.bars, 1, "crouching")
	p.set_crouching(false)
	p.velocity = Vector3(9, 0, 0)
	meter.refresh()
	assert_eq(meter.bars, 3, "running")


# --- Inside a hiding spot ---

func test_hiding_shows_a_cosy_view_and_says_they_cant_see_me() -> void:
	var hud := _hud()
	assert_false(hud.hide_overlay.visible)
	hud.hide_overlay.set_hidden(true)
	assert_true(hud.hide_overlay.visible)
	var texts: Array[String] = []
	for l in hud.hide_overlay.find_children("*", "Label", true, false):
		texts.append((l as Label).text)
	assert_has(texts, HideOverlay.TEXT)
	assert_eq(hud.hide_overlay.mouse_filter, Control.MOUSE_FILTER_IGNORE, "a tap still reaches the game (to come out)")
	hud.hide_overlay.set_hidden(false)
	await get_tree().create_timer(HideOverlay.FADE + 0.1).timeout
	assert_false(hud.hide_overlay.visible)


func test_hiding_muffles_the_sound() -> void:
	var hud := _hud()
	hud.hide_overlay.set_hidden(true)
	assert_true(Audio.is_muffled())
	hud.hide_overlay.set_hidden(false)
	assert_false(Audio.is_muffled())


# --- The danger arrow ---

func _arrows_with_camera() -> Array:
	var p := _player()                                                # its camera goes current first ...
	var arrows := DangerArrows.new()
	add_child_autofree(arrows)
	var cam := Camera3D.new()
	add_child_autofree(cam)
	cam.current = true                                                # ... then the test's camera
	cam.look_at_from_position(Vector3(0, 11.5, 0), Vector3(0, 11.5, -10))   # looking along -Z
	arrows.player = p
	return [arrows, p]


func _monster(pos: Vector3) -> Monster:
	var m := Monster.new()
	m.setup({"kind": MonsterRules.GOBLIN, "level": 1, "id": "arrow%d" % randi(), "pos": pos, "yaw": 0.0, "wild": true, "universe": 1})
	add_child_autofree(m)
	return m


func test_a_monster_that_sees_you_from_behind_shows_an_arrow() -> void:
	var a: Array = _arrows_with_camera()
	var arrows: DangerArrows = a[0]
	var p: Player = a[1]
	var m := _monster(Vector3(6, 10, 8))                              # behind, to the right
	arrows.poll()
	assert_eq(arrows.count(), 0)
	m.alert = StealthRules.MARK_BANG
	m.alert_peer = p.peer_id
	arrows.poll()
	assert_eq(arrows.count(), 1, "it glows at the screen edge")
	var at := arrows.arrow_point(0)
	assert_gt(arrows.size.x, 0.0, "full screen")
	assert_gt(at.x, arrows.size.x * 0.5 + 100.0, "on the right: the monster is behind, to the right")
	arrows.tick(StealthRules.ARROW_TIME + 0.1)
	assert_eq(arrows.count(), 0, "then fades away")


func test_no_arrow_for_a_monster_you_can_see_or_another_players_monster() -> void:
	var a: Array = _arrows_with_camera()
	var arrows: DangerArrows = a[0]
	var p: Player = a[1]
	var ahead := _monster(Vector3(0, 10, -8))                          # right in front
	ahead.alert = StealthRules.MARK_BANG
	ahead.alert_peer = p.peer_id
	var other := _monster(Vector3(0, 10, 8))
	other.alert = StealthRules.MARK_BANG
	other.alert_peer = p.peer_id + 10                                  # after someone else
	arrows.poll()
	assert_eq(arrows.count(), 0)


func test_the_arrow_never_nags() -> void:
	var a: Array = _arrows_with_camera()
	var arrows: DangerArrows = a[0]
	var p: Player = a[1]
	var m := _monster(Vector3(0, 10, 8))
	m.alert = StealthRules.MARK_BANG
	m.alert_peer = p.peer_id
	arrows.poll()
	assert_eq(arrows.count(), 1)
	arrows.poll()
	assert_eq(arrows.count(), 1, "one arrow per \"!\", not one per look")
	arrows.tick(StealthRules.ARROW_TIME + 0.1)
	m.alert = StealthRules.MARK_QUESTION
	arrows.poll()
	m.alert = StealthRules.MARK_BANG
	arrows.poll()
	assert_eq(arrows.count(), 0, "the same monster again so soon: no new arrow")
	arrows.tick(StealthRules.ARROW_COOLDOWN)
	m.alert = StealthRules.MARK_QUESTION
	arrows.poll()
	m.alert = StealthRules.MARK_BANG
	arrows.poll()
	assert_eq(arrows.count(), 1, "later: yes")
