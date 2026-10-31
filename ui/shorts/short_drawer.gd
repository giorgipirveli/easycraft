class_name ShortDrawer
extends RefCounted
## How one actor kind is drawn on a Short's stage (owner #96: pluggable kinds; the registry is ShortDrawers, the check
## ShortKinds). A ShortActor (a Control on the stage) asks its kind's drawer:
## - setup(actor): make what it shows (children, textures, a SubViewport for 3D, a VideoStreamPlayer) and set
##   `actor.size` (its box: the actor is placed, turned and scaled round its middle) and `actor.animated` (true when
##   its drawing changes with the time by itself: a flame, a wave, a 3D camera, a video);
## - draw(actor): its draw calls, from the actor's _draw (CanvasItem calls on `actor`);
## - update(actor, state, t): after each move of the timeline (state: ShortTimeline.actor_state; t: seconds into the
##   scene): a video seeks to `t`, a 3D camera turns, so that a seek shows exactly the frame playing reaches.
## Built-in kinds use BuiltinDrawer (ShortActor's own code); `scene3d` and `video` have their own (Scene3DDrawer,
## VideoDrawer: the Reel Studio, owner #96).


func setup(_actor: ShortActor) -> void:
	pass


func draw(_actor: ShortActor) -> void:
	pass


func update(_actor: ShortActor, _state: Dictionary, _t: float) -> void:
	pass
