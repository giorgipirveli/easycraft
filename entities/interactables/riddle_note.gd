class_name RiddleNote
extends SecretThing
## A riddle note on a little stand (M2 Task 16): a hidden room's hint, or a temple's order of the plates.
## Tapping it shows the note (text and pictures) on this device only; nothing to ask the host.

var text := ""
var pictures: Array = []


## data = {id, pos, yaw, secret, text, pictures}
func setup(data: Dictionary) -> void:
	_base(data, Vector3(0.55, 0.9, 0.3), Vector3(0, 0.45, 0))
	text = str(data.get("text", ""))
	pictures = data.get("pictures", [])
	_mesh(InteractableModels.note())
