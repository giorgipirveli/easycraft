class_name PlayerCard
extends QuestOverlay
## Another player's card (owner #37, spec §14.23), opened by a tap on their name tag: their name and what a child can do
## about them. Spec §17.3 "Safety in the world" (the M4 Task 10 review's finding A, 2026-09-25): in every world with
## other players, not only Survivor. TRADE where trading is (Survivor: nothing opens on their side without their YES).
## Online: REPORT (what happened: the friends page's reasons; they are muted here too) and BLOCK (asks first), friend or
## not. The host: REMOVE FROM MY WORLD (asks first; offered again after BLOCK). On LAN there is no server to report to,
## but the host can still remove a player. Bots have no card: they are not players.

const THANKS := "Thank you for telling us. A grown-up will look at it."
const REASONS := {OnlineService.REPORT_MEAN: "MEAN WORDS", OnlineService.REPORT_SCARY: "SCARY",
	OnlineService.REPORT_SECRETS: "ASKED\nSECRETS", OnlineService.REPORT_OTHER: "SOMETHING\nELSE"}

var peer := 0
var player_name := ""
## What this card may offer (set before open_for): trading here, an online game, this game hosts.
var can_trade := true
var online := false
var host := false
## (peer) -> void: ask them to trade.
var on_trade: Callable
## (peer, reason) -> String; (peer) -> String; (peer) -> String: "" or plain words (they may await the server).
var on_report: Callable
var on_block: Callable
var on_remove: Callable
var trade_button: Button


func _init() -> void:
	box_width = 700.0


func open_for(peer_id: int, who: String) -> void:
	peer = peer_id
	player_name = who
	_show_main()
	show_overlay()


func _head() -> void:
	clear()
	var head := row(18)
	head.add_child(ProgressPicture.new(&"friends", 90))
	head.add_child(words(player_name, 36, 0.0, GOLD))
	content.add_child(head)


func _show_main(note: String = "") -> void:
	_head()
	if note != "":
		content.add_child(words(note, 26, 620.0, HINT))
	var buttons := row()
	trade_button = null
	if can_trade:
		trade_button = button("TRADE", OnlineUi.PURPLE, Vector2(200, 86), "TradeButton")
		trade_button.pressed.connect(func() -> void:
			close()
			if on_trade.is_valid():
				on_trade.call(peer))
		buttons.add_child(trade_button)
	if online:
		var report := button("REPORT", UiKit.ORANGE, Vector2(200, 86), "ReportButton")
		report.pressed.connect(_show_reasons)
		buttons.add_child(report)
		var block := button("BLOCK", UiKit.RED, Vector2(180, 86), "BlockButton")
		block.pressed.connect(_ask.bind("Block %s? They can't talk to you, invite you or join you again." % player_name,
			_do_block))
		buttons.add_child(block)
	if host:
		buttons.add_child(_remove_button())
	var bye := button("CLOSE", Color(), Vector2(180, 86), "Close")
	bye.pressed.connect(close)
	buttons.add_child(bye)
	content.add_child(buttons)


func _remove_button() -> Button:
	var remove := button("REMOVE", UiKit.RED, Vector2(200, 86), "RemoveButton")
	remove.pressed.connect(_ask.bind("Remove %s from your world?" % player_name, _do_remove))
	return remove


func _show_reasons() -> void:
	_head()
	content.add_child(words("What happened?", 30))
	var buttons := row()
	for reason: String in OnlineService.REPORT_REASONS:
		var b := button(REASONS[reason], UiKit.ORANGE, Vector2(150, 96), "Reason_" + reason)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(_do_report.bind(reason))
		buttons.add_child(b)
	content.add_child(buttons)


## Asks before a step that can't be taken back: YES does it, NO goes back to the card.
func _ask(question: String, then: Callable) -> void:
	_head()
	content.add_child(words(question, 28, 620.0))
	var yes := button("YES", UiKit.RED, Vector2(200, 86), "YesButton")
	yes.pressed.connect(then)
	var no := button("NO", UiKit.BLUE, Vector2(200, 86), "NoButton")
	no.pressed.connect(_show_main)
	var buttons := row()
	buttons.add_child(yes)
	buttons.add_child(no)
	content.add_child(buttons)


func _do_report(reason: String) -> void:
	var err: String = await on_report.call(peer, reason) if on_report.is_valid() else "?"
	_show_main(THANKS if err == "" else err)


func _do_block() -> void:
	var err: String = await on_block.call(peer) if on_block.is_valid() else "?"
	if err != "":
		_show_main(err)
		return
	if not host:
		_show_main("%s is blocked." % player_name)
		return
	_head()   # the host: remove them from this world too?
	content.add_child(words("%s is blocked. Remove them from your world too?" % player_name, 28, 620.0))
	var buttons := row()
	buttons.add_child(_remove_button())
	var bye := button("NOT NOW", Color(), Vector2(200, 86), "Close")
	bye.pressed.connect(close)
	buttons.add_child(bye)
	content.add_child(buttons)


func _do_remove() -> void:
	var err: String = await on_remove.call(peer) if on_remove.is_valid() else "?"
	if err != "":
		_show_main(err)
		return
	close()
