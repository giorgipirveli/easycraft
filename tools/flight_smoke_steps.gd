extends Node
## The steps of tools/flight_smoke.gd: the rocket flight through the real sandbox.

const TIMEOUT := 600.0
const SEED := 12345

var _t := 0.0
var _step := 0
var _wait := 0.0
var _step_t := 0.0
var _fails := 0
var _scene: Node
var _left: Node
var _flight_time := 0.0
var _seen_landing := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for slot: String in ["sandbox_1", "sandbox_16", "sandbox_23"]:
		WorldSaves.delete(slot)
	Profile.data.settings.keys_seen = true
	Game.new_world_seed = SEED
	Game.start_world(ModeRules.SANDBOX, true, DifficultyRules.NORMAL, 1)
	print("FLIGHT_SMOKE begin")


func _process(delta: float) -> void:
	_t += delta
	if _t > TIMEOUT:
		_check(false, "timeout at step %d" % _step)
		_finish()
		return
	var sandbox := get_tree().current_scene
	if sandbox == null or sandbox.get("player") == null or not (sandbox.player as Player).is_spawned():
		return
	if sandbox != _scene:
		_scene = sandbox
		_wait = 1.5
	if _wait > 0.0:
		_wait -= delta
		return
	_step_t += delta
	_run_step(sandbox, delta)


func _run_step(sandbox: Node, delta: float) -> void:
	var p: Player = sandbox.player
	match _step:
		0:
			var r := RocketStages.test_rocket(SpaceRules.MOON, 2)
			var feet := p.global_position
			r.origin = Vector3(floorf(feet.x) + 6.0, float(p.world.find_standing_y(floori(feet.x) + 8, floori(feet.z) + 2)),
				floorf(feet.z))
			var why: String = sandbox.fly_rocket(r)
			_check(why == "", "LAUNCH: the sandbox flies the missions' rocket (%s)" % why)
			var flight: Node = sandbox.get("flight")
			_check(flight != null and flight.is_active(), "a flight is on")
			if flight == null:
				_finish()
				return
			_check(not p.visible and not (sandbox.hud as Control).visible, "the child sits in the rocket: the player and the HUD hidden")
			_check(not p.is_physics_processing(), "the player holds still on the pad")
			var cockpit: Control = flight.get("cockpit")
			_check(cockpit.get_index() < (sandbox.pause_menu as Control).get_index(), "the cockpit is under the pause menu")
			_check((flight.get("camera") as Camera3D).current, "the flight's camera")
			_check(sandbox.fly_rocket(RocketStages.test_rocket(SpaceRules.MOON, 1)) == "" and sandbox.get("flight") == flight,
				"one flight at a time")
			_next(2.0)
		1:
			var flight: Node = sandbox.get("flight")
			var t: float = flight.run.time
			(sandbox.pause_menu as PauseMenu).open()
			_check(get_tree().paused, "the pause menu holds the flight")
			_flight_time = t
			_next(0.0)
		2:
			if _step_t < 0.5:
				return
			var flight: Node = sandbox.get("flight")
			_check(is_equal_approx(flight.run.time, _flight_time), "paused: the flight's clock stands still")
			(sandbox.pause_menu as PauseMenu).close()
			flight.abort()
			_check(sandbox.get("flight") == null, "QUIT: the flight is gone")
			_check(p.visible and (sandbox.hud as Control).visible and p.is_physics_processing(), "the player and the HUD are back")
			_check(p.camera().current, "the player's camera is back")
			_check((p.world.sun() as DirectionalLight3D).visible, "the world's sun is back")
			_next(1.0)
		3:
			_check(sandbox.fly_rocket({"destination": 99, "cells": RocketStages.test_rocket(SpaceRules.MOON).cells}) != "",
				"a world that does not exist says why")
			var why: String = sandbox.fly_rocket(RocketStages.test_rocket(SpaceRules.MOON, 2))
			_check(why == "", "a test rocket in front of the child")
			_left = sandbox
			_next(0.0)
		4:
			var flight: Node = sandbox.get("flight")
			if flight != null and is_instance_valid(flight):
				_play_child(flight)
				if _step_t > 300.0:
					_check(false, "the flight lands")
					_finish()
				return
			if sandbox == _left:
				return
			_check(Game.universe == SpaceRules.MOON, "landed: the Moon world (%d)" % Game.universe)
			_check(_step_t < 240.0, "the whole flight took %.0f s (2-3 minutes)" % _step_t)
			_next(1.0)
		5:
			var lander := sandbox.get_node_or_null("Lander") as Node3D
			_check(lander != null, "the lander stands by the pad")
			if lander:
				var d := Vector2(lander.global_position.x - p.global_position.x, lander.global_position.z - p.global_position.z).length()
				_check(d > 4.0 and d < 10.0, "a few steps from the child (%.1f m)" % d)
			var why: String = sandbox.land_on_space(SpaceRules.MERCURY)
			_check(why == "", "the Star Map's LAND to Mercury plays the landing (%s)" % why)
			_left = sandbox
			_next(0.5)
		6:
			var flight: Node = sandbox.get("flight")
			if sandbox == _left:
				if flight != null and is_instance_valid(flight) and not _seen_landing:
					_seen_landing = true
					_check(not flight.get("flown"), "a landing on its own, not a whole flight")
				if flight != null and is_instance_valid(flight):
					_play_child(flight)   # owner #106: its practice descent flown
				if _step_t > 60.0:
					_check(false, "the landing on Mercury ends")
					_finish()
				return
			_check(Game.universe == SpaceRules.MERCURY, "landed on Mercury (%d)" % Game.universe)
			_check(_step_t < 45.0, "the landing (its practice descent flown) and the loading took %.1f s" % _step_t)
			_next(1.0)
		7:
			_check(sandbox.get_node_or_null("Lander") != null, "Mercury: the lander by the pad too")
			_finish()


func _play_child(flight: Node) -> void:
	var run: FlightRun = flight.get("run")
	var cockpit: FlightCockpit = flight.get("cockpit")
	if run == null or cockpit == null:
		return
	var waiting := run.waiting_for()
	cockpit.lever.held = waiting in [FlightPlan.THROTTLE, FlightPlan.BURN, FlightPlan.DESCEND]   # owner #106: the descent too
	cockpit.lever.value = run.test_throttle() if cockpit.lever.held else 0.0
	if run.descent != null and run.descent.held():
		run.descent.release()   # GO on the first try's hint card
	if waiting in [FlightPlan.STAGE, FlightPlan.LEGS, FlightPlan.PARACHUTE]:
		cockpit.action_pressed.emit()


func _next(wait: float) -> void:
	_step += 1
	_wait = wait
	_step_t = 0.0


func _check(ok: bool, what: String) -> void:
	print("FLIGHT_SMOKE %s %s" % ["ok" if ok else "FAIL", what])
	if not ok:
		_fails += 1


func _finish() -> void:
	print("FLIGHT_SMOKE result fails=%d" % _fails)
	get_tree().quit(0 if _fails == 0 else 1)
