// Checks an EasyCraft server from the outside, the way the game uses it (./kit.sh check runs it in
// a Node container; with Node 22+ it also runs anywhere: node smoke.mjs <url> <server key>).
//   1. HTTPS answers: Nakama's /healthcheck through Caddy, with a trusted certificate.
//   2. Two check players sign in by device with the server key (the same two accounts every run).
//   3. The module's healthcheck RPC answers.
//   4. The realtime socket opens over wss:// (Caddy passes the WebSocket upgrade) and answers a ping.
//   5. A relayed match: the first player creates it and sends a message as big as the game's
//      biggest piece (RelayBridge: 32 KiB, about 44 KB as base64 in JSON), which only fits when
//      the server's socket.max_message_size_bytes is the game's 65536, not Nakama's 4096.
//   6. The second player joins and messages cross both ways. When the server's join rules refuse
//      an uninvited player (the M4 MatchJoin hook), that step is skipped, not failed.
// Prints "CHECK <step> ok|FAIL|SKIP <detail>" and exits 0 when nothing failed.
// For a server with Caddy's local certificate (local-try.yml): NODE_EXTRA_CA_CERTS=<its root.crt>.

const [url, serverKey] = process.argv.slice(2);
if (!url || !serverKey) {
	console.error("usage: node smoke.mjs https://<server> <server key>");
	process.exit(2);
}
const base = url.replace(/\/+$/, "");
const wsBase = base.replace(/^http/, "ws");
const TIMEOUT_MS = 10000;
const PIECE_BYTES = 32 * 1024; // RelayPieces.PIECE_BYTES in the game
let failures = 0;

function report(step, status, detail) {
	if (status === "FAIL") failures++;
	console.log(`CHECK ${step} ${status}${detail ? " " + detail : ""}`);
}

async function http(path, options = {}) {
	const res = await fetch(base + path, { ...options, signal: AbortSignal.timeout(TIMEOUT_MS) });
	const text = await res.text();
	let body = null;
	try { body = JSON.parse(text); } catch { body = text; }
	return { status: res.status, body };
}

async function signIn(deviceId) {
	const basic = Buffer.from(serverKey + ":").toString("base64");
	const res = await http("/v2/account/authenticate/device?create=true", {
		method: "POST",
		headers: { Authorization: "Basic " + basic, "Content-Type": "application/json" },
		body: JSON.stringify({ id: deviceId }),
	});
	if (res.status !== 200 || !res.body.token) {
		throw new Error(`HTTP ${res.status} ${JSON.stringify(res.body)}`);
	}
	return res.body.token;
}

// A realtime socket with request/answer by cid and a queue of pushed messages.
class Socket {
	constructor(token) {
		this.token = token;
		this.nextCid = 1;
		this.waiting = new Map();
		this.pushed = [];
		this.watchers = [];
	}

	open() {
		return new Promise((resolve, reject) => {
			const timer = setTimeout(() => reject(new Error("no answer in time")), TIMEOUT_MS);
			this.ws = new WebSocket(`${wsBase}/ws?lang=en&status=false&token=${encodeURIComponent(this.token)}`);
			this.ws.onopen = () => { clearTimeout(timer); resolve(); };
			this.ws.onerror = (e) => { clearTimeout(timer); reject(new Error(e.message || "socket error")); };
			this.ws.onclose = (e) => {
				this.closed = `closed (${e.code} ${e.reason})`;
				for (const [, w] of this.waiting) w.reject(new Error(this.closed));
				this.waiting.clear();
			};
			this.ws.onmessage = (e) => this.onMessage(JSON.parse(e.data));
		});
	}

	onMessage(msg) {
		if (msg.cid && this.waiting.has(msg.cid)) {
			const w = this.waiting.get(msg.cid);
			this.waiting.delete(msg.cid);
			if (msg.error) w.reject(new Error(`${msg.error.code}: ${msg.error.message}`));
			else w.resolve(msg);
			return;
		}
		this.pushed.push(msg);
		for (const w of this.watchers.slice()) w();
	}

	request(envelope) {
		if (this.closed) return Promise.reject(new Error(this.closed));
		const cid = String(this.nextCid++);
		return new Promise((resolve, reject) => {
			const timer = setTimeout(() => {
				this.waiting.delete(cid);
				reject(new Error("no answer in time"));
			}, TIMEOUT_MS);
			this.waiting.set(cid, {
				resolve: (m) => { clearTimeout(timer); resolve(m); },
				reject: (e) => { clearTimeout(timer); reject(e); },
			});
			this.ws.send(JSON.stringify({ cid, ...envelope }));
		});
	}

	send(envelope) {
		this.ws.send(JSON.stringify(envelope));
	}

	// Resolves with the first pushed message that `test` accepts.
	waitFor(test) {
		return new Promise((resolve, reject) => {
			const check = () => {
				const i = this.pushed.findIndex(test);
				if (i >= 0) {
					done();
					resolve(this.pushed.splice(i, 1)[0]);
				} else if (this.closed) {
					done();
					reject(new Error(this.closed));
				}
			};
			const timer = setTimeout(() => { done(); reject(new Error("nothing arrived in time")); }, TIMEOUT_MS);
			const done = () => {
				clearTimeout(timer);
				this.watchers = this.watchers.filter((w) => w !== check);
			};
			this.watchers.push(check);
			check();
		});
	}

	close() {
		if (this.ws && !this.closed) this.ws.close();
	}
}

function b64(size, fill) {
	return Buffer.alloc(size, fill).toString("base64");
}

async function main() {
	// 1. HTTPS
	try {
		const res = await http("/healthcheck");
		if (res.status !== 200) throw new Error(`HTTP ${res.status}`);
		report("https", "ok", base);
	} catch (e) {
		report("https", "FAIL", `${base}: ${e.cause?.code || e.cause?.message || e.message}`);
		return;
	}

	// 2. Sign-in
	let hostToken, guestToken;
	try {
		hostToken = await signIn("easycraft-server-check-host-01");
		guestToken = await signIn("easycraft-server-check-guest-01");
		report("sign-in", "ok", "two check players signed in with the server key");
	} catch (e) {
		report("sign-in", "FAIL", `${e.message} (is NAKAMA_SERVER_KEY the game's RELEASE_SERVER_KEY?)`);
		return;
	}

	// 3. RPC
	try {
		const res = await http("/v2/rpc/healthcheck", {
			method: "POST",
			headers: { Authorization: "Bearer " + hostToken, "Content-Type": "application/json" },
			body: JSON.stringify(""),
		});
		if (res.status !== 200) throw new Error(`HTTP ${res.status} ${JSON.stringify(res.body)}`);
		report("rpc", "ok", `healthcheck: ${res.body.payload}`);
	} catch (e) {
		report("rpc", "FAIL", `healthcheck: ${e.message} (is the server module loaded?)`);
	}

	// 4. Realtime socket
	const host = new Socket(hostToken);
	const guest = new Socket(guestToken);
	try {
		const t0 = Date.now();
		await host.open();
		await host.request({ ping: {} });
		report("socket", "ok", `wss:// open, ping answered in ${Date.now() - t0} ms`);
	} catch (e) {
		report("socket", "FAIL", `${e.message} (does the proxy pass the WebSocket upgrade?)`);
		return;
	}

	// 5. A relayed match and a message as big as the game's biggest piece
	let matchId;
	try {
		const created = await host.request({ match_create: {} });
		matchId = created.match.match_id;
		const data = b64(PIECE_BYTES, 7);
		host.send({ match_data_send: { match_id: matchId, op_code: "9003", data } });
		await host.request({ ping: {} });
		report("big-message", "ok", `match ${matchId}: a ${data.length}-character message was accepted`);
	} catch (e) {
		report("big-message", "FAIL", `${e.message} (socket.max_message_size_bytes must be 65536)`);
		host.close();
		return;
	}

	// 6. A second player joins; messages cross both ways
	try {
		await guest.open();
		try {
			await guest.request({ match_join: { match_id: matchId } });
		} catch (e) {
			report("relay", "SKIP", `the server refused an uninvited player (${e.message}): its join rules work`);
			return;
		}
		const toGuest = guest.waitFor((m) => m.match_data && m.match_data.op_code === "1");
		host.send({ match_data_send: { match_id: matchId, op_code: "1", data: b64(64, 1) } });
		await toGuest;
		const toHost = host.waitFor((m) => m.match_data && m.match_data.op_code === "2");
		const t0 = Date.now();
		guest.send({ match_data_send: { match_id: matchId, op_code: "2", data: b64(64, 2) } });
		await toHost;
		report("relay", "ok", `messages crossed both ways (guest to host ${Date.now() - t0} ms)`);
	} catch (e) {
		report("relay", "FAIL", e.message);
	} finally {
		guest.close();
		host.close();
	}
}

try {
	await main();
} catch (e) {
	report("unexpected", "FAIL", e.stack || String(e));
}
console.log(failures === 0 ? "CHECK done: the server works" : `CHECK done: ${failures} problem(s)`);
process.exit(failures === 0 ? 0 : 1);
