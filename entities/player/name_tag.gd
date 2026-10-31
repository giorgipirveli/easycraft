class_name NameTag
extends Label3D
## The name tag over another player (M3 Task 12, spec §5.8): the name (the host's chat name) and, under
## it, the level and title the player chose or plays most ("Lv 5 Master Builder", from its synced
## Player.progress_tag). This game's own player has none (it would sit in front of the camera). Hidden
## while that player hides or is invisible (a tag would give a hiding friend away). Looked at twice a
## second, redrawn only when the words change.

const HEIGHT := 2.35
const LOOK_EVERY := 0.5

var player: Player
var _t := LOOK_EVERY


func _ready() -> void:
	name = "NameTag"
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED   # M3 Task 21a: a player's name is never translated
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	font_size = 36
	outline_size = 10
	pixel_size = 0.01
	modulate = Color("fff3c4")
	no_depth_test = false
	position.y = HEIGHT


func _process(delta: float) -> void:
	_t += delta
	if _t < LOOK_EVERY or not is_instance_valid(player):
		return
	_t = 0.0
	var words := vr_marked(text_for(str(Session.chat_names.get(player.peer_id, "")), player.progress_tag),
		not player.vr_pose.is_empty())   # owner #101 (P4): a friend playing in a headset
	if text != words:
		text = words
	var hidden_now := player.is_hiding() or player.is_invisible()
	if visible == hidden_now:
		visible = not hidden_now
	var s := player.size_scale()
	if not is_equal_approx(position.y, HEIGHT * s):
		position.y = HEIGHT * s


## Owner #101 (P4): the VR mark after the name of a player in a headset (its first line); no name, no mark.
const VR_MARK := "  [VR]"


static func vr_marked(words: String, vr: bool) -> String:
	if not vr or words == "":
		return words
	var lines := words.split("\n")
	lines[0] += VR_MARK
	return "\n".join(lines)


## The tag's words: the name, and under it the level and title from `tag` ("<level>:<style>"). A tag
## this game can't read shows only the name; no name, no tag.
static func text_for(player_name: String, tag: String) -> String:
	if player_name == "":
		return ""
	var parts := tag.split(":")
	if parts.size() != 2 or not parts[0].is_valid_int():
		return player_name
	var style := StringName(parts[1]) if LevelRules.is_title(StringName(parts[1])) else &""   # owner #45a: quest titles too
	return "%s\n%s" % [player_name, LevelRules.tag_line(parts[0].to_int(), style)]
