extends RefCounted
## Is the development Nakama server up? For the tests that need it (their should_skip_script).
## A refused connection answers at once, so machines without Docker lose no time; a slow answer on a
## busy PC gets several patient tries (a 2 s probe once skipped the tests while the server was up).

const URL := "http://%s:%d/healthcheck" % [OnlineConfig.DEFAULT_HOST, OnlineConfig.DEFAULT_PORT]
const TRIES := 3
const TIMEOUT_SEC := 5.0


## "" when the server answers, else why not (the skip reason).
static func why_not_up(parent: Node) -> String:
	var last := ""
	for i in TRIES:
		var http := HTTPRequest.new()
		http.timeout = TIMEOUT_SEC
		http.process_mode = Node.PROCESS_MODE_ALWAYS
		parent.add_child(http)
		var err := http.request(URL)
		if err != OK:
			last = "request error %s" % error_string(err)
		else:
			var result: Array = await http.request_completed
			if int(result[0]) == HTTPRequest.RESULT_SUCCESS and int(result[1]) == 200:
				http.queue_free()
				return ""
			last = "result %d, HTTP %d" % [result[0], result[1]]
		http.queue_free()
		if last.contains("result %d," % HTTPRequest.RESULT_CANT_CONNECT):
			break   # nothing listens: no point waiting
	return "no Nakama server at %s (%s; start one: server/dev.sh up)" % [URL, last]
