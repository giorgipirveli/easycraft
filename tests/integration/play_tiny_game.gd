extends PlayStation
## A stand-in signature game for test_play_games.gd: it plays true-or-false claims only (any other exercise keeps G0's
## mechanic); its move is a single tap on its lever.


static func expresses(ex: Dictionary) -> bool:
	return str(ex.get("type", "")) == "truefalse"


var said := -1


func build() -> void:
	add("lever_true", LifeRoomKit.box(self, "True", Vector3(0.1, 0.1, 0.1), Vector3(-0.2, 0.9, 0.5), Color.GREEN), 0.1)
	add("lever_false", LifeRoomKit.box(self, "False", Vector3(0.1, 0.1, 0.1), Vector3(0.2, 0.9, 0.5), Color.ORANGE), 0.1)


func answers_by_acting() -> bool:
	return true


func press(t: String) -> void:
	said = 0 if t == "lever_true" else 1
	acted.emit()


func response() -> Variant:
	return said == 0


func ghost() -> Array[String]:
	var out: Array[String] = []
	if said != PlayChoose.right_option(ex):
		out.append("lever_true" if bool(ex.get("answer", false)) else "lever_false")
	return out
