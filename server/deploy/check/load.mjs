// Relay load for sizing a server (docs/hosting.md, "How big a server"). For a TEST server only:
// it signs in many made-up players. Each match has a host and guests, like the game over Nakama's
// relay: the host sends MSG_RATE messages a second of MSG_BYTES to every guest (world edits and
// player sync), each guest sends the same to the host (its player sync and requests).
// Usage: node load.mjs <url> <server key> [matches=10] [players per match=4] [seconds=60]
//        [msg rate=20] [msg bytes=300]
// The defaults are about 48 kbit/s each way per guest: the spike's measured guest upload and the
// M4 target for what a guest receives (< 50 kbit/s, spec §17.0).
// Prints what the players sent and received; measure the server's CPU and traffic around it.

const [url, serverKey, ...rest] = process.argv.slice(2);
if (!url || !serverKey) {
	console.error("usage: node load.mjs <url> <server key> [matches] [players] [seconds] [rate] [bytes]");
	process.exit(2);
}
const [matches, players, seconds, rate, bytes] = [10, 4, 60, 20, 300].map((d, i) => Number(rest[i] ?? d));
const base = url.replace(/\/+$/, "");
const wsBase = base.replace(/^http/, "ws");
const payload = Buffer.alloc(bytes, 42).toString("base64");
const stats = { sent: 0, sentBytes: 0, received: 0, receivedBytes: 0, errors: 0 };

async function signIn(id) {
	const res = await fetch(`${base}/v2/account/authenticate/device?create=true`, {
		method: "POST",
		headers: { Authorization: "Basic " + Buffer.from(serverKey + ":").toString("base64"), "Content-Type": "application/json" },
		body: JSON.stringify({ id }),
	});
	if (res.status !== 200) throw new Error(`sign-in ${res.status}`);
	return (await res.json()).token;
}

function open(token) {
	return new Promise((resolve, reject) => {
		const ws = new WebSocket(`${wsBase}/ws?status=false&token=${encodeURIComponent(token)}`);
		const answers = new Map();
		let cid = 1;
		ws.onopen = () => resolve({
			ws,
			request(envelope) {
				const id = String(cid++);
				return new Promise((ok, fail) => {
					answers.set(id, { ok, fail });
					ws.send(JSON.stringify({ cid: id, ...envelope }));
				});
			},
		});
		ws.onerror = () => { stats.errors++; reject(new Error("socket error")); };
		ws.onmessage = (e) => {
			const msg = JSON.parse(e.data);
			if (msg.cid && answers.has(msg.cid)) {
				const a = answers.get(msg.cid);
				answers.delete(msg.cid);
				msg.error ? a.fail(new Error(msg.error.message)) : a.ok(msg);
			} else if (msg.match_data) {
				stats.received++;
				stats.receivedBytes += e.data.length;
			}
		};
	});
}

function send(sock, matchId, presences) {
	const text = JSON.stringify({ match_data_send: { match_id: matchId, op_code: "1", data: payload, presences } });
	sock.ws.send(text);
	stats.sent++;
	stats.sentBytes += text.length;
}

async function startMatch(m) {
	const host = await open(await signIn(`easycraft-load-${m}-host-000`));
	const created = await host.request({ match_create: {} });
	const matchId = created.match.match_id;
	const hostPresence = created.match.self;
	const guests = [];
	for (let g = 1; g < players; g++) {
		const guest = await open(await signIn(`easycraft-load-${m}-guest-${g}00`));
		await guest.request({ match_join: { match_id: matchId } });
		guests.push(guest);
	}
	return { host, guests, matchId, hostPresence };
}

const all = [];
for (let m = 0; m < matches; m++) all.push(await startMatch(m));
console.log(`LOAD ready: ${matches} matches x ${players} players, ${rate} msg/s of ${bytes} bytes each way`);

const t0 = Date.now();
const timer = setInterval(() => {
	for (const { host, guests, matchId, hostPresence } of all) {
		send(host, matchId, undefined); // to everyone in the match
		for (const g of guests) send(g, matchId, [hostPresence]); // to the host only
	}
}, 1000 / rate);
await new Promise((r) => setTimeout(r, seconds * 1000));
clearInterval(timer);
await new Promise((r) => setTimeout(r, 1000));
const secs = (Date.now() - t0) / 1000;
const kbit = (b) => ((b * 8) / 1000 / secs).toFixed(0);
console.log(`LOAD done: ${secs.toFixed(1)} s, sent ${stats.sent} msgs (${kbit(stats.sentBytes)} kbit/s of JSON), ` +
	`received ${stats.received} msgs (${kbit(stats.receivedBytes)} kbit/s), errors ${stats.errors}`);
console.log(`LOAD per player: received ${(stats.receivedBytes * 8 / 1000 / secs / (matches * players)).toFixed(1)} kbit/s, ` +
	`expected ${stats.sent === 0 ? 0 : ((matches * (players - 1) * 2) * rate * secs)} msgs, got ${stats.received}`);
for (const { host, guests } of all) {
	host.ws.close();
	for (const g of guests) g.ws.close();
}
process.exit(0);
