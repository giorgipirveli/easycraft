class_name LookChoice
extends VBoxContainer
## Owner feedback #48 (spec §14.6a): the first-launch look step, after the name: BOY / GIRL / JUST ME as three
## big pictures drawn in the child's own skin tone. A tap puts on that starting look (AvatarLook.start: the
## skin tone and the dance wheel stay) and saves; the avatar editor can change anything, any time. It is a
## starting point, never a lock. profile / save_profile can be swapped (tests).

signal chosen(base: StringName)

const CHOICE_SIZE := Vector2(250, 250)
const TITLE := "Pick your look"
const HINT := "You can change it any time: AVATAR on the main screen."

var profile: ProfileData          # default: Profile.data
var save_profile := Callable()    # default: Profile.save + Profile.avatar_changed

var _choices: Array[AvatarTile] = []


func _ready() -> void:
	if profile == null:
		profile = Profile.data
	if not save_profile.is_valid():
		save_profile = func() -> void:
			Profile.save()
			Profile.avatar_changed.emit()
	add_theme_constant_override("separation", 20)
	add_child(ReadAloud.with_speaker(UiKit.title(TITLE), self))   # M5 Task 1: read aloud on every screen
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	for b: StringName in AvatarCatalog.BASES:
		var t := AvatarTile.new(AvatarIcon.BASE, b, CHOICE_SIZE)
		t.caption = AvatarEditor.BASE_WORDS[b]
		t.caption_size = 34
		t.look = profile.avatar
		t.pressed.connect(choose.bind(b))
		row.add_child(t)
		_choices.append(t)
	add_child(row)
	var hint := Label.new()
	hint.text = HINT
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 24)
	add_child(hint)


func choices() -> Array[AvatarTile]:
	return _choices


## Puts on the starting look of `b` and saves.
func choose(b: StringName) -> void:
	profile.avatar = AvatarLook.start(b, profile.avatar)
	save_profile.call()
	chosen.emit(b)
