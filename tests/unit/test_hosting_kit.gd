extends GutTest
## The hosting kit for the owner's server (M4 D, server/deploy, docs/hosting.md) stays in step with
## the game and the development server: the release key, the relay settings the game depends on,
## every secret in .env.example and start.sh, only 80/443 open to the world, TLS all the way.

const KIT := "res://server/deploy/"
const DEV_CONFIG := "res://server/nakama/local.yml"
const PROD_CONFIG := KIT + "nakama/production.yml"
## Settings the game depends on: the relay's message size and queue (RelayBridge pieces), the
## module's entry point, and the session lengths the game's sign-in expects.
const SHARED_SETTINGS := ["socket.max_message_size_bytes", "socket.max_request_size_bytes", "socket.outgoing_queue_size", "runtime.js_entrypoint",
	"session.token_expiry_sec", "session.refresh_token_expiry_sec"]
const SECRETS := ["POSTGRES_PASSWORD", "NAKAMA_SESSION_ENCRYPTION_KEY", "NAKAMA_SESSION_REFRESH_ENCRYPTION_KEY",
	"NAKAMA_CONSOLE_USERNAME", "NAKAMA_CONSOLE_PASSWORD", "NAKAMA_CONSOLE_SIGNING_KEY", "NAKAMA_RUNTIME_HTTP_KEY"]


func _text(path: String) -> String:
	var text := FileAccess.get_file_as_string(path)
	assert_ne(text, "", "readable: %s" % path)
	return text


## "section.key" -> value for a two-level YAML file (comments and quotes removed).
func _yaml_settings(path: String) -> Dictionary:
	var out := {}
	var section := ""
	var top := RegEx.create_from_string("^([a-z_]+):\\s*(#.*)?$")
	var nested := RegEx.create_from_string("^  ([a-z_]+):\\s*([^#]*?)\\s*(#.*)?$")
	for line: String in _text(path).split("\n"):
		var m := top.search(line)
		if m:
			section = m.get_string(1)
			continue
		m = nested.search(line)
		if m and section != "" and m.get_string(2) != "":
			out["%s.%s" % [section, m.get_string(1)]] = m.get_string(2).trim_prefix("\"").trim_suffix("\"")
	return out


## KEY=value lines of an env file.
func _env(path: String) -> Dictionary:
	var out := {}
	for line: String in _text(path).split("\n"):
		if line.begins_with("#") or not line.contains("="):
			continue
		out[line.get_slice("=", 0)] = line.substr(line.find("=") + 1)
	return out


func test_the_kit_ships_the_games_release_key() -> void:
	assert_eq(_env(KIT + ".env.example").get("NAKAMA_SERVER_KEY"), OnlineConfig.RELEASE_SERVER_KEY,
		"the server must accept the key the release game sends")


func test_production_keeps_the_relay_settings_of_the_development_server() -> void:
	var dev := _yaml_settings(DEV_CONFIG)
	var prod := _yaml_settings(PROD_CONFIG)
	for key: String in SHARED_SETTINGS:
		assert_true(dev.has(key), "the development server sets %s" % key)
		assert_eq(prod.get(key), dev.get(key), "%s is the same in production" % key)


func test_production_config_holds_no_secret() -> void:
	var prod := _yaml_settings(PROD_CONFIG)
	for key: String in ["socket.server_key", "session.encryption_key", "session.refresh_encryption_key",
			"console.username", "console.password", "console.signing_key", "runtime.http_key"]:
		assert_false(prod.has(key), "%s comes from .env through start.sh, never from git" % key)
	assert_null(RegEx.create_from_string("(?m)^\\s*(address|password|.*_key):").search(_text(PROD_CONFIG)),
		"no database address (it has the password), password or key in production.yml")


func test_every_secret_is_in_the_example_checked_at_start_and_required_by_compose() -> void:
	var example := _env(KIT + ".env.example")
	var start := _text(KIT + "nakama/start.sh")
	var compose := _text(KIT + "docker-compose.yml")
	for key: String in SECRETS + ["NAKAMA_SERVER_KEY"]:
		assert_true(example.has(key), ".env.example has %s" % key)
		assert_true(start.contains("check %s " % key), "start.sh refuses an empty or default %s" % key)
		assert_true(compose.contains("${%s:?" % key), "docker compose refuses to start without %s" % key)
	for key: String in SECRETS:
		if key != "NAKAMA_CONSOLE_USERNAME":
			assert_eq(example.get(key), "", "%s is left empty in the example: ./kit.sh keys makes it" % key)


func test_only_https_is_open_to_the_world() -> void:
	var published := RegEx.create_from_string("^\\s+- \"([0-9.]+:)?(\\d+):(\\d+)\"")
	var open_ports: Array[String] = []
	for line: String in _text(KIT + "docker-compose.yml").split("\n"):
		var m := published.search(line)
		if m == null:
			continue
		if m.get_string(1) == "127.0.0.1:":
			continue
		assert_eq(m.get_string(1), "", "a published port binds all addresses or 127.0.0.1: %s" % line)
		open_ports.append(m.get_string(2))
	assert_eq(open_ports, ["80", "443"] as Array[String],
		"only Caddy's 80 and 443 reach the internet (Nakama's API, console and the database never do)")


func test_secrets_and_backups_stay_out_of_git() -> void:
	var ignored := _text(KIT + ".gitignore").split("\n")
	assert_has(ignored, ".env")
	assert_has(ignored, "backups/")
	assert_has(ignored, "!.env.example")


func test_the_release_server_is_reached_over_tls() -> void:
	var address := "https://play.example.com"
	var server := OnlineConfig.release_server(address)
	var factory: Node = (load("res://addons/com.heroiclabs.nakama/Nakama.gd") as GDScript).new()
	add_child_autofree(factory)
	var client: NakamaClient = factory.create_client(OnlineConfig.key_for(server, address), server.host,
		int(server.port), server.scheme, 5, NakamaLogger.LOG_LEVEL.ERROR)
	assert_eq(client._api_client._base_uri, "https://play.example.com:443", "sign-in and RPCs over HTTPS")
	var socket: NakamaSocket = factory.create_socket_from(client)
	assert_eq(socket._base_uri, "wss://play.example.com", "the realtime socket over wss:// on 443")


# --- M4 Task 8b, agent G: what the server's logs keep (docs/store/data-retention-and-security.md) ---

## The service blocks of the kit's compose file: name -> its lines.
func _services(compose: String) -> Dictionary:
	var out := {}
	var name := ""
	var inside := false
	for line: String in compose.split("\n"):
		if line == "services:":
			inside = true
			continue
		if inside and line != "" and not line.begins_with(" ") and not line.begins_with("#"):
			inside = false   # the next top-level key (volumes:)
		if not inside:
			continue
		var m := RegEx.create_from_string("^  ([a-z_]+):\\s*$").search(line)
		if m:
			name = m.get_string(1)
			out[name] = []
		elif name != "":
			(out[name] as Array).append(line)
	return out


func test_every_service_keeps_its_docker_log_small() -> void:
	var compose := _text(KIT + "docker-compose.yml")
	var anchor := compose.substr(compose.find("x-logging: &logging"), 200)
	assert_string_contains(anchor, "driver: json-file")
	assert_string_contains(anchor, "max-size: \"10m\"")
	assert_string_contains(anchor, "max-file: \"5\"")
	var services := _services(compose)
	assert_eq(services.keys(), ["postgres", "nakama", "caddy", "backup"])
	for s: String in services:
		assert_true("\n".join(services[s]).contains("logging: *logging"), "%s rotates its Docker log" % s)


func test_caddys_access_log_is_rolled_every_midnight_and_gone_within_14_days() -> void:
	var caddy := _text(KIT + "caddy/Caddyfile")
	var at := caddy.find("output file /var/log/caddy/access.log")
	assert_gt(at, 0, "the access log goes to its own file, not to Docker's log")
	var block := caddy.substr(at, caddy.find("}", at) - at)
	assert_string_contains(block, "roll_at 00:00", "a new file every midnight, even when nobody connects")
	var keep := RegEx.create_from_string("roll_keep_for (\\d+)h").search(block)
	assert_not_null(keep, "rolled files are kept for a set time")
	if keep:
		# A line waits up to a day in the open file, then up to roll_keep_for, then up to a day for the
		# next roll's clean-up: never older than 14 days.
		assert_lte(24 + int(keep.get_string(1)) + 24, 14 * 24, "no line older than 14 days")
	var services := _services(_text(KIT + "docker-compose.yml"))
	assert_true("\n".join(services.caddy).contains(":/var/log/caddy"), "the log folder is a volume")


func test_caddys_logs_hold_no_tokens_or_headers_and_its_docker_log_no_addresses() -> void:
	var caddy := _text(KIT + "caddy/Caddyfile")
	var access := caddy.substr(caddy.find("output file /var/log/caddy/access.log"))
	for field: String in ["request>headers delete", "delete token", "delete http_key", "resp_headers delete"]:
		assert_string_contains(access, field, "the access log leaves out %s" % field)
	var global := caddy.substr(0, caddy.find("{$EASYCRAFT_DOMAIN}"))
	assert_string_contains(global, "log default", "Caddy's own log (to Docker) is set here")
	for field: String in ["request>remote_ip delete", "request>client_ip delete", "request>headers delete", "delete token"]:
		assert_string_contains(global, field, "Caddy's own log leaves out %s (Docker keeps it by size, not age)" % field)


func test_nakama_logs_at_info_to_docker() -> void:
	var prod := _yaml_settings(PROD_CONFIG)
	assert_eq(prod.get("logger.level"), "INFO", "INFO lines carry account ids, never addresses (measured)")
	assert_eq(prod.get("logger.stdout"), "true")


## Owner #70/#71: the profile backup of a child who practised the whole School is up to ProfileBackup.MAX_CHARS, sent
## as a JSON string inside the request (its quotes escaped). Nakama's HTTP limit (socket.max_request_size_bytes,
## 256 KiB by default) must take it with room to spare.
func test_the_server_takes_the_biggest_profile_backup() -> void:
	for path: String in [DEV_CONFIG, PROD_CONFIG]:
		var max_request := int(_yaml_settings(path).get("socket.max_request_size_bytes", "262144"))
		assert_gte(max_request, ProfileBackup.MAX_CHARS * 2, path)

