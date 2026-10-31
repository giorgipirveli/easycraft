class_name LifeAuto
extends RefCounted
## Owner #112: an automatic player that always does the right next thing, for the tests and the headless smoke
## (tools/life_smoke.gd): the sample that moves a step on (LifeCheck's keys), frame by frame. It never needs the coach.
## The room host's own smoke drives real fingers and hands at the rooms' targets; this one checks the data and rules.


static func sample(step: Dictionary, state: Dictionary, dt: float) -> Dictionary:
	var s := {"dt": dt, "low": true}
	var next := LifeCheck.next_targets(step, state)
	match str(step.get("kind", "")):
		"info":
			s.ok = true
		"touch", "go", "taps", "sequence", "find", "coins", "basket":
			s.pressed = next
		"hold", "hands":
			s.held = next
		"point":
			s.aimed = next
		"choose", "count":
			s.answer = int(step.get("answer", 0))
		"feel":
			s.answer = 0
		"look":
			var sides: Array = step.get("sides", [])
			if int(state.get("i", 0)) < sides.size():
				s.looked = str(sides[int(state.get("i", 0))])
		"cross":
			s.safe = true   # the data's player: the room's own traffic decides in a real try
			s.pressed = [str(step.target)]
		"rub":
			s.rubbing = [str(step.target)]
		"pour":
			if float(state.get("level", 0.0)) < float(step.get("want", 0.5)):
				s.held = [str(step.target)]
		"breathe":
			var phase := str(state.get("phase", "rest"))
			if phase == "rest" or (phase == "in" and float(state.get("t", 0.0)) < float(step.get("in", 3.0))):
				s.held = [str(step.target)]
		"steady":
			if float(state.get("value", 0.0)) < (float(step.get("lo", 0.0)) + float(step.get("hi", 0.0))) * 0.5:
				s.held = [str(step.target)]
		"action":
			s.action = str(step.get("action", ""))
		"rhythm":
			var count := int(state.get("count", 0))
			var at := float(count + 1) * LifeBeat.BEAT_SECONDS   # exactly on the beat: 110 a minute
			if float(state.get("clock", 0.0)) + dt >= at:
				s.pushes = 1
				s.time = at
		"sweep":
			s.sweep_u = -0.8 if int(state.get("side", 0)) > 0 else 0.8
	return s
