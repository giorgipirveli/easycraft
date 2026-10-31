class_name EmoteButton
extends TouchButton
## The HUD's emote button (M3 Task 9): a round button with a little cheering figure on it (in the MORE
## panel since M2 Task 17, with its word under it). Pressing it opens the emote wheel.

const FIGURE_POSE_TIME := 0.45

var _look := AvatarLook.new().resolve()
var _pose := EmotePoses.sample(&"cheer", FIGURE_POSE_TIME)


func _init() -> void:
	symbol = &"emote"


## The player's own figure cheering, in the picture's place.
func _draw_icon(r: Rect2) -> void:
	AvatarIcon.figure(self, r.grow(r.size.x * 0.06), _look, _pose)
