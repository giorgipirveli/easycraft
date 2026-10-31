extends Node
## The steps of tools/delete_test_account.gd: sign in with this folder's saved device id, delete the account (with
## --password=<the account's password> once it has one: owner #105).

const TIMEOUT := 150.0   # the live server answers in about 200 ms a call; a sign-in takes several
const NAKAMA_BACKEND := "res://net/nakama_online_backend.gd"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var server := ""
	var password := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--server="):
			server = a.trim_prefix("--server=")
		elif a.begins_with("--password="):
			password = a.trim_prefix("--password=")
	get_tree().create_timer(TIMEOUT).timeout.connect(func() -> void: _done(false, "timeout"))
	var service := OnlineService.new()
	service.backend = (load(NAKAMA_BACKEND) as GDScript).new()
	service.server = OnlineConfig.parse_server(server)
	service.logged_out_card = false
	Session.use_online_service(service)
	if not service.has_online_link():
		_done(true, "no account on this device")
		return
	var err: String = await service.sign_in()
	if err != "":
		_done(false, "sign in: %s" % err)
		return
	var start: Dictionary = await service.delete_account_start()
	if str(start.get("text", "")) != "":
		_done(false, "start: %s" % start.text)
		return
	err = await service.delete_account(str(start.get("confirm", "")), password)
	_done(err == "", "deleted %s" % start.get("username", "") if err == "" else err)


func _done(ok: bool, why: String) -> void:
	print("DELETE_ACCOUNT %s %s" % ["ok" if ok else "FAIL", why])
	get_tree().quit(0 if ok else 1)
