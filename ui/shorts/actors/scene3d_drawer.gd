class_name Scene3DDrawer
extends ShortDrawer
## The Reel Studio (owner #96, spec §5.12b): the `scene3d` actor's drawer. The actor holds a Scene3DView (its 3D stage in
## a SubViewport of its own) in its box ({w, h}, 320 × 320 by default); update() shows the stage at the scene's time,
## so a seek shows the frame playing reaches. The actor pops, slides and fades like any other (ShortTimeline).

const DEFAULT := Vector2(320, 320)


func setup(actor: ShortActor) -> void:
	var box := Vector2(StudioRules.num(actor.data, "w", DEFAULT.x), StudioRules.num(actor.data, "h", DEFAULT.y))
	var view := Scene3DView.new()
	view.size = box
	actor.add_child(view)
	actor.size = box
	actor.animated = true
	actor.set_meta(&"view", view)
	view.build(actor.data.get("stage", {}))


func update(actor: ShortActor, _state: Dictionary, t: float) -> void:
	var view: Scene3DView = actor.get_meta(&"view") if actor.has_meta(&"view") else null
	if view != null:
		view.show_at(t)


## The stage in `actor` (tests, the bench).
static func view_of(actor: ShortActor) -> Scene3DView:
	return actor.get_meta(&"view") if actor.has_meta(&"view") else null
