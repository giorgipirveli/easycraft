class_name OnlineConfig
extends RefCounted
## Settings for online play (M4 early spike, spec §7.3): which Nakama server, and whether this
## game hosts a relayed match or joins one by its id. Read from the developer args until M4 adds
## invites: --online-host, --online-join=<match id>, --online-server=<[http[s]://]host[:port]|release>.
## Release builds talk to RELEASE_SERVER over TLS (https, so the realtime socket is wss); developer
## builds keep this PC's server (default_server(), M4 D, docs/hosting.md).

const DEFAULT_SCHEME := "http"
const DEFAULT_HOST := "127.0.0.1"
const DEFAULT_PORT := 7350          # Nakama's HTTP API and realtime socket (server/docker-compose.yml)
const HTTPS_PORT := 443
## The development server's socket.server_key (server/nakama/local.yml). It ships inside the game,
## so it is not a secret. The release server has its own: key_for().
const SERVER_KEY := "defaultkey"
## How the Android emulator reaches this PC's 127.0.0.1.
const EMULATOR_HOST := "10.0.2.2"

## The game's server on the internet, "https://<domain>" (server/deploy, docs/hosting.md step 8).
## Empty until the owner has one: release builds then offer no online play.
const RELEASE_SERVER := "https://178-104-20-64.sslip.io"   # the Hetzner server easycraft-1 (2026-09-24; docs/hosting.md)
## The release server's socket.server_key, the same as NAKAMA_SERVER_KEY in
## server/deploy/.env.example. It ships inside the game like SERVER_KEY, so it is not a secret; it
## only has to differ from Nakama's default, which scanners try on every server they find.
const RELEASE_SERVER_KEY := "easycraft-3d4365aad6885d9a2e4bcc05"
## --online-server=release: the release server, from a developer build.
const RELEASE_ARG := "release"
## M5 Task 4: the public pages the release server serves (server/deploy/caddy/Caddyfile; made from docs/store/ by
## tools/make_store_pages.py). Google Play links to them, and the grown-up area's PRIVACY page opens them.
const PRIVACY_PAGE := "/privacy"
const DELETE_PAGE := "/delete-account"
## Where parents write (the privacy policy's contact, the store listing's e-mail).
const SUPPORT_EMAIL := "parkingi-support@googlegroups.com"

const HOST := &"host"
const JOIN := &"join"

## A Nakama match id: the match's UUID, a dot, then the node name (empty for a relayed match).
const _MATCH_ID := "^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\\.[A-Za-z0-9_-]{0,64}$"
const _HOST_NAME := "^[A-Za-z0-9._-]+$"
const _IPV6 := "^[0-9A-Fa-f:.]+$"


## "[scheme://]host[:port]" -> {scheme, host, port}, or {error} saying what is wrong. Empty text is
## the development server on this PC. IPv6 hosts need brackets: [::1]:7350.
static func parse_server(text: String) -> Dictionary:
	var rest := text.strip_edges()
	if rest == "":
		return {"scheme": DEFAULT_SCHEME, "host": DEFAULT_HOST, "port": DEFAULT_PORT}
	var scheme := DEFAULT_SCHEME
	var sep := rest.find("://")
	if sep >= 0:
		scheme = rest.substr(0, sep).to_lower()
		rest = rest.substr(sep + 3)
		if scheme not in ["http", "https"]:
			return {"error": "the server address must start with http:// or https://"}
	if rest.ends_with("/"):
		rest = rest.left(-1)
	if rest.contains("/"):
		return {"error": "the server address has no path, only host and port"}
	var host := rest
	var port_text := ""
	if rest.begins_with("["):
		var close := rest.find("]")
		if close < 0:
			return {"error": "an IPv6 address needs a closing ]"}
		host = rest.substr(1, close - 1)
		var after := rest.substr(close + 1)
		if after != "" and not after.begins_with(":"):
			return {"error": "only :port may follow an IPv6 address"}
		port_text = after.substr(1) if after != "" else ""
		if after == ":":
			return {"error": "the port is missing after the colon"}
		if not RegEx.create_from_string(_IPV6).search(host):
			return {"error": "not an IPv6 address: %s" % host}
	else:
		var parts := rest.split(":")
		if parts.size() > 2:
			return {"error": "put an IPv6 address in brackets, like [::1]:7350"}
		host = parts[0]
		if parts.size() == 2:
			port_text = parts[1]
			if port_text == "":
				return {"error": "the port is missing after the colon"}
		if not RegEx.create_from_string(_HOST_NAME).search(host):
			return {"error": "not a host name: '%s'" % host}
	var port := HTTPS_PORT if scheme == "https" else DEFAULT_PORT
	if port_text != "":
		if not port_text.is_valid_int() or port_text.to_int() < 1 or port_text.to_int() > 65535:
			return {"error": "the port must be a number from 1 to 65535"}
		port = port_text.to_int()
	return {"scheme": scheme, "host": host, "port": port}


## True in builds exported with a release template (what players get); false in the editor, in
## tests and in debug APKs.
static func is_release_build() -> bool:
	return not OS.is_debug_build()


## The server this build talks to: {scheme, host, port}, or {error} when a release build has no
## server yet (it then offers no online play).
static func default_server() -> Dictionary:
	return server_for_build(is_release_build(), OS.has_feature("android"), RELEASE_SERVER, WebGlue.page_host())


## default_server() for any build: release builds use `release_address` over TLS (M7: the web build too, served from
## that host's /play/); developer builds this PC's server (server/dev.sh), which the Android emulator reaches as
## EMULATOR_HOST, and a developer web build the server on `page_host`, the machine that served the page.
static func server_for_build(release: bool, android: bool, release_address: String,
		page_host: String = "") -> Dictionary:
	if release:
		return release_server(release_address)
	if page_host != "":
		var page := parse_server(page_host)
		if not page.has("error"):
			return page
	return parse_server(EMULATOR_HOST if android else "")


## A release server's address -> {scheme, host, port}, or {error}. Only https: children's accounts
## never cross the internet unencrypted. Without a scheme, https is assumed.
static func release_server(address: String) -> Dictionary:
	var text := address.strip_edges()
	if text == "":
		return {"error": "there is no online server yet"}
	if not text.contains("://"):
		text = "https://" + text
	var server := parse_server(text)
	if server.has("error"):
		return server
	if server.scheme != "https":
		return {"error": "the release server must use https (TLS)"}
	return server


## The socket.server_key to sign in to `server` with: the release server's own key when it is the
## release server, else the development server's.
static func key_for(server: Dictionary, release_address: String = RELEASE_SERVER) -> String:
	var release := release_server(release_address)
	if release.has("error"):
		return SERVER_KEY
	var same: bool = server.get("scheme") == "https" \
		and str(server.get("host", "")).to_lower() == str(release.host).to_lower() \
		and int(server.get("port", 0)) == int(release.port)
	return RELEASE_SERVER_KEY if same else SERVER_KEY


## The match id in `text` (trimmed, its UUID in lower case), or "" when it is not one.
static func normalize_match_id(text: String) -> String:
	var t := text.strip_edges()
	var dot := t.find(".")
	if dot < 0:
		return ""
	t = t.substr(0, dot).to_lower() + t.substr(dot)
	return t if RegEx.create_from_string(_MATCH_ID).search(t) else ""


static func is_match_id(text: String) -> bool:
	return text != "" and normalize_match_id(text) == text


## The online settings in the command line's user args: {} when neither --online-host nor
## --online-join is there; else {role, match_id, server}; or {error} when the args are wrong.
## Without --online-server the server is this build's own (default_server()).
static func from_args(args: Array) -> Dictionary:
	var role: StringName = &""
	var match_id := ""
	var server_text := ""
	for a: String in args:
		if a == "--online-host":
			if role == JOIN:
				return {"error": "--online-host and --online-join can't be used together"}
			role = HOST
		elif a.begins_with("--online-join="):
			if role == HOST:
				return {"error": "--online-host and --online-join can't be used together"}
			role = JOIN
			match_id = normalize_match_id(a.trim_prefix("--online-join="))
			if match_id == "":
				return {"error": "--online-join needs the match id the host printed"}
		elif a.begins_with("--online-server="):
			server_text = a.trim_prefix("--online-server=")
	if role == &"":
		return {}
	var server := default_server()
	if server_text == RELEASE_ARG:
		server = release_server(RELEASE_SERVER)
	elif server_text != "":
		server = parse_server(server_text)
	if server.has("error"):
		return {"error": "--online-server: %s" % server.error}
	return {"role": role, "match_id": match_id, "server": server}


## M5 Task 4: the privacy policy on the release server ("" when the game has no server yet).
static func privacy_url() -> String:
	return page_url(PRIVACY_PAGE)


## M5 Task 4: how to delete an online account, or only some data, on the release server.
static func delete_account_url() -> String:
	return page_url(DELETE_PAGE)


static func page_url(path: String) -> String:
	return RELEASE_SERVER + path if RELEASE_SERVER != "" else ""
