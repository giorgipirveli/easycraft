class_name BotBlockyAvatar
extends BlockyAvatar
## A bot friend's body in the BLOCKY style (M2 Task 15): the player's blocky avatar in the bot's own
## colours (BotRules.LOOKS) with a little antenna, so a friend never passes for a real player.
## Its boxes and colours come from AvatarParts' shared meshes and per-colour materials (M3 Task 9), like
## every player's, so three bots never add materials or meshes of their own.

const ANTENNA := Color("9aa3ad")

## Which of BotRules.LOOKS to wear; set before adding to the tree.
var bot_look := 0   # a BotRules.LOOKS index (AvatarModel.look() is a player's look)


func _ready() -> void:
	if not _look_applied:   # Owner 48: its girl or boy hair, face and clothes, dressed by super()
		_look = BotRules.avatar_look(bot_look)
		_look_applied = true
	super()
	var pivot := body_pivot()
	_box(pivot, Vector3(0.05, 0.22, 0.05), Vector3(0, 1.91 - PIVOT_Y, 0), ANTENNA, "AntennaStem")
	_box(pivot, Vector3(0.13, 0.13, 0.13), Vector3(0, 2.07 - PIVOT_Y, 0), colors().torso, "Antenna")


## This bot's colours: {torso, legs, skin}.
func colors() -> Dictionary:
	return BotRules.LOOKS[posmod(bot_look, BotRules.LOOKS.size())]


## The look in this bot's own colours: its skin, and its shirt and pants as the look's top and bottom
## (a skirt, a dress and the parts take them too).
func _resolved() -> Dictionary:
	var c := colors()
	return _look.resolve_in(c.torso, c.legs, c.skin)
