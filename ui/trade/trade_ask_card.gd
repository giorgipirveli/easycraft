class_name TradeAskCard
extends QuestOverlay
## Another player asks this child to trade (owner #37, spec §14.23): "Bob would like to trade." with YES and NO
## THANKS, as equal buttons. Nothing opens without YES; a tap outside the card is NO THANKS. The card goes away by
## itself when the asker takes the ask back or leaves.

var asker := 0
## (asker, yes) -> void: the answer to the host.
var answer: Callable = func(peer: int, yes: bool) -> void: Session.player_trade_answer(peer, yes)
var yes_button: Button
var no_button: Button

var _answered := true


func _init() -> void:
	box_width = 660.0


func _ready() -> void:
	super()
	closed.connect(func() -> void:
		if not _answered:
			_reply(false))


func ask(peer: int, from_name: String) -> void:
	if visible and not _answered and asker != peer:
		_reply(false)   # one ask at a time: the older one is answered NO THANKS
	asker = peer
	_answered = false
	clear()
	var head := row(18)
	head.add_child(ProgressPicture.new(&"friends", 90))
	head.add_child(words(tr("%s would like to trade.") % from_name, 32, 360.0, GOLD))
	content.add_child(head)
	var buttons := row()
	yes_button = button("YES", UiKit.GREEN, Vector2(240, 86), "YesButton")
	yes_button.pressed.connect(func() -> void:
		_reply(true)
		close())
	buttons.add_child(yes_button)
	no_button = button("NO THANKS", UiKit.ORANGE, Vector2(240, 86), "NoButton")
	no_button.pressed.connect(close)
	buttons.add_child(no_button)
	content.add_child(buttons)
	show_overlay()


## The asker took the ask back or left: the card goes without an answer.
func ask_gone(peer: int) -> void:
	if peer == asker and not _answered:
		_answered = true
		close()


func _reply(yes: bool) -> void:
	if _answered:
		return
	_answered = true
	answer.call(asker, yes)
