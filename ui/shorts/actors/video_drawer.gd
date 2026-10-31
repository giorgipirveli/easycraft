class_name VideoDrawer
extends ShortDrawer
## The Reel Studio (owner #96, spec §5.12b): the `video` actor's drawer: a clip of a rendered reel (VideoView) in its box
## ({w, h}: 320 × 180 by default, the actor's own `start` into the file), played on the scene's clock: a seek shows
## the exact frame; until the reels pack is here (the browser) the reel's still and "coming…".

const DEFAULT := Vector2(320, 180)


func setup(actor: ShortActor) -> void:
	var box := Vector2(StudioRules.num(actor.data, "w", DEFAULT.x), StudioRules.num(actor.data, "h", DEFAULT.y))
	var view := VideoView.new(str(actor.data.get("file", "")), StudioRules.num(actor.data, "start", 0.0))
	view.size = box
	actor.add_child(view)
	actor.size = box
	actor.animated = true
	actor.set_meta(&"view", view)


func update(actor: ShortActor, _state: Dictionary, t: float) -> void:
	var view: VideoView = actor.get_meta(&"view") if actor.has_meta(&"view") else null
	if view == null:
		return
	var player := _player(actor)
	view.set_playing(player != null and player.playing)
	view.show_at(t)


static func view_of(actor: ShortActor) -> VideoView:
	return actor.get_meta(&"view") if actor.has_meta(&"view") else null


static func _player(actor: ShortActor) -> ShortPlayer:
	var n := actor.get_parent()
	while n != null:
		if n is ShortPlayer:
			return n
		n = n.get_parent()
	return null
