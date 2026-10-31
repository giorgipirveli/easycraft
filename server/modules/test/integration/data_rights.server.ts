// M4 Task 8b, agent G, against a REAL Nakama (like nakama.server.ts): deleting an online account (the
// player's two calls, and the owner's by name through the HTTP key and the console's API Explorer),
// the retention clean-up (a sign-in records itself and runs the day's clean-up; retention_run for the
// owner only; an account 13 months quiet is deleted) and the snapshot of a reported message.
// Not part of `npm test`:
//
//   EASYCRAFT_SERVER=http://127.0.0.1:7350 npm run test:server
//
// It needs server/nakama/local.yml's switches and the console (EASYCRAFT_CONSOLE, default the HTTP
// port + 1; EASYCRAFT_CONSOLE_PASSWORD) and the runtime HTTP key (EASYCRAFT_HTTP_KEY, default Nakama's
// development "defaulthttpkey").
import { test, after } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";

const BASE = (process.env.EASYCRAFT_SERVER || "http://127.0.0.1:7350").replace(/\/$/, "");
const CONSOLE = process.env.EASYCRAFT_CONSOLE || BASE.replace(/:(\d+)$/, (_m, p) => ":" + (Number(p) + 1));
const WS = BASE.replace(/^http/, "ws");
const SERVER_KEY = "Basic " + Buffer.from("defaultkey:").toString("base64");
const HTTP_KEY = process.env.EASYCRAFT_HTTP_KEY || "defaulthttpkey";
const SYSTEM = "00000000-0000-0000-0000-000000000000";
const FIRST_CODE = "sasa192974"; // only in tests; the module holds its hash
const TAG = Date.now().toString(36).slice(-5);
const MONTH = 31 * 24 * 60 * 60 * 1000;

type Json = { [key: string]: any };

interface Player {
  id: string;
  token: string;
  name: string;
  device: string;
}

async function http(method: string, path: string, token: string | null, body?: unknown): Promise<{ status: number; body: Json }> {
  const r = await fetch(BASE + path, {
    method,
    headers: { Authorization: token ? "Bearer " + token : SERVER_KEY, "Content-Type": "application/json" },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await r.text();
  let parsed: Json = {};
  try {
    parsed = text ? JSON.parse(text) : {};
  } catch {
    parsed = { raw: text };
  }
  return { status: r.status, body: parsed };
}

async function rpc(p: Player, id: string, payload: Json = {}): Promise<Json> {
  const r = await http("POST", "/v2/rpc/" + id, p.token, JSON.stringify(payload));
  assert.equal(r.status, 200, id + ": " + JSON.stringify(r.body));
  return JSON.parse(r.body.payload);
}

// An RPC as the owner: the runtime HTTP key, no session (what a curl on the server does).
async function ownerRpc(id: string, payload: Json): Promise<Json> {
  const r = await fetch(`${BASE}/v2/rpc/${id}?http_key=${encodeURIComponent(HTTP_KEY)}&unwrap`, {
    method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify(payload),
  });
  const text = await r.text();
  assert.equal(r.status, 200, id + ": " + text);
  return JSON.parse(text);
}

async function authenticate(device: string): Promise<{ id: string; token: string }> {
  const r = await http("POST", "/v2/account/authenticate/device?create=true", null, { id: device });
  assert.equal(r.status, 200, JSON.stringify(r.body));
  const token = r.body.token as string;
  return { id: JSON.parse(Buffer.from(token.split(".")[1], "base64url").toString()).uid as string, token };
}

let counter = 0;

async function player(band = "13_plus", prefix = "Del"): Promise<Player> {
  const device = "gtest-" + randomUUID();
  const a = await authenticate(device);
  const p: Player = { id: a.id, token: a.token, name: prefix + TAG + ++counter, device };
  const claim = await rpc(p, "claim_username", { username: p.name, age_band: band });
  assert.equal(claim.ok, true, JSON.stringify(claim));
  return p;
}

async function befriend(a: Player, b: Player): Promise<void> {
  for (const [from, to] of [[a, b], [b, a]]) {
    const r = await http("POST", "/v2/friend?ids=" + to.id, from.token);
    assert.equal(r.status, 200, JSON.stringify(r.body));
  }
}

let consoleToken = "";

async function consoleApi(method: string, path: string, body?: unknown): Promise<{ status: number; body: Json }> {
  if (consoleToken === "") {
    const login = await fetch(CONSOLE + "/v2/console/authenticate", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ username: "admin", password: process.env.EASYCRAFT_CONSOLE_PASSWORD || "easycraft-dev" }),
    });
    consoleToken = (await login.json()).token;
  }
  const r = await fetch(CONSOLE + path, {
    method, headers: { Authorization: "Bearer " + consoleToken, "Content-Type": "application/json" },
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  const text = await r.text();
  return { status: r.status, body: text ? JSON.parse(text) : {} };
}

async function storageOf(userId: string, collection = ""): Promise<Json[]> {
  const q = "user_id=" + userId + (collection ? "&collection=" + collection : "");
  return ((await consoleApi("GET", "/v2/console/storage?" + q)).body.objects || []) as Json[];
}

async function stored(collection: string, key: string, userId: string): Promise<Json | null> {
  const r = await consoleApi("GET", `/v2/console/storage/${collection}/${encodeURIComponent(key)}/${userId}`);
  return r.status === 200 ? { ...r.body, value: JSON.parse(r.body.value) } : null;
}

const openSockets: Socket[] = [];

after(() => {
  openSockets.forEach((s) => s.close());
});

class Socket {
  ws: WebSocket;
  cid = 0;
  waiting = new Map<string, (m: Json) => void>();
  events: Json[] = [];
  ready: Promise<unknown>;

  constructor(p: Player) {
    openSockets.push(this);
    this.ws = new WebSocket(`${WS}/ws?lang=en&status=true&format=json&token=${p.token}`);
    this.ws.onmessage = (m: MessageEvent) => {
      const msg = JSON.parse(String(m.data));
      if (msg.cid && this.waiting.has(msg.cid)) {
        this.waiting.get(msg.cid)!(msg);
        this.waiting.delete(msg.cid);
      } else {
        this.events.push(msg);
      }
    };
    this.ready = new Promise((ok, bad) => {
      this.ws.onopen = ok;
      this.ws.onerror = bad;
    });
  }

  async send(message: Json): Promise<Json> {
    await this.ready;
    const cid = String(++this.cid);
    return new Promise((ok) => {
      this.waiting.set(cid, ok);
      this.ws.send(JSON.stringify({ cid, ...message }));
    });
  }

  async message(timeoutMs = 3000): Promise<Json> {
    const end = Date.now() + timeoutMs;
    while (Date.now() < end) {
      const e = this.events.find((x) => x.channel_message);
      if (e) {
        return e.channel_message;
      }
      await new Promise((done) => setTimeout(done, 50));
    }
    throw new Error("no channel message");
  }

  close(): void {
    this.ws.close();
  }
}

test("the module is 0.2.20", async () => {
  const p = await player();
  assert.equal((await rpc(p, "healthcheck")).version, "0.2.20");
});

test("delete_account: two calls; the account, its storage, friends, invites sent and DMs go; reports stay as they should", async () => {
  const me = await player();
  const pal = await player();
  const bad = await player();
  await befriend(me, pal);
  assert.equal((await rpc(me, "redeem_code", { code: FIRST_CODE })).ok, true, "a wallet with a ledger");
  const put = await http("PUT", "/v2/storage", me.token, { objects: [{ collection: "profiles", key: "profile", value: '{"version":1}' }] });
  assert.equal(put.status, 200, JSON.stringify(put.body));
  const ms = new Socket(me);
  const matchId = (await ms.send({ match_create: {} })).match.match_id as string;
  assert.equal((await rpc(me, "invite_friend", { user_id: pal.id, match_id: matchId })).ok, true);
  const dm = await ms.send({ channel_join: { target: pal.id, type: 2, persistence: true, hidden: false } });
  const sent = await ms.send({ channel_message_send: { channel_id: dm.channel.id, content: JSON.stringify({ text: "see you tomorrow" }) } });
  assert.equal(sent.channel_message_ack?.persistent, true, JSON.stringify(sent));
  assert.deepEqual(await rpc(me, "report_user", { user_id: bad.id, reason: "mean_words" }), { ok: true });
  assert.deepEqual(await rpc(bad, "report_user", { user_id: me.id, reason: "bad_name" }), { ok: true });
  assert.ok((await storageOf(me.id)).length >= 5, "profiles, codes, invites, limits, activity");

  const first = await rpc(me, "delete_account", {});
  assert.equal(first.ok, true, JSON.stringify(first));
  assert.equal(first.username, me.name);
  assert.equal((await consoleApi("GET", "/v2/console/account/" + me.id)).status, 200, "nothing deleted by the first call");
  assert.deepEqual(await rpc(me, "delete_account", { confirm: "nope" }), { ok: false, error: "confirm_wrong" });
  const done = await rpc(me, "delete_account", { confirm: first.confirm });
  assert.equal(done.ok, true, JSON.stringify(done));
  assert.equal(done.deleted, true);
  assert.equal(done.friends, 1);
  assert.ok(done.notifications >= 1, "the invite to the friend (and Nakama's own friend-request notes, which name the player)");
  assert.equal(done.messages, 1, "the kept DM");

  assert.equal((await consoleApi("GET", "/v2/console/account/" + me.id)).status, 404, "the account is gone");
  assert.deepEqual(await storageOf(me.id), [], "no storage left");
  assert.notEqual((await http("GET", "/v2/account", me.token)).status, 200, "its session is gone too");
  const friends = await http("GET", "/v2/friend", pal.token);
  assert.equal((friends.body.friends || []).some((f: Json) => f.user?.id === me.id), false, "gone from the friend's list");
  const notes = await http("GET", "/v2/notification?limit=100", pal.token);
  assert.equal((notes.body.notifications || []).some((n: Json) => n.sender_id === me.id), false, "its invite is gone");
  const history = await http("GET", "/v2/channel/" + encodeURIComponent(dm.channel.id) + "?limit=10", pal.token);
  assert.equal((history.body.messages || []).length, 0, JSON.stringify(history.body));

  const reports = (await storageOf(SYSTEM, "reports")).map((o) => o.key);
  assert.equal(reports.some((k: string) => k.endsWith("_" + me.id)), false, "no report key names the deleted player");
  let made: Json | null = null;
  let about: Json | null = null;
  for (const key of reports) {
    const o = await stored("reports", key, SYSTEM);
    if (o && o.value.reported_id === bad.id && o.value.reporter_id === "") {
      made = o.value;
    }
    if (o && o.value.reported_id === me.id) {
      about = o.value;
    }
  }
  assert.ok(made, "the report the player made stays, without its reporter");
  assert.equal(made!.reporter_username, "");
  assert.equal(made!.reason, "mean_words");
  assert.ok(about, "the report about the player stays for the reviewer");
  assert.equal(about!.reported_username, me.name);

  // Owner #105 (0.2.20): a deleted claimed account's device ids are refused for good (device_logged_out), so a device
  // that rejoins never makes a new empty account and re-claims the freed name; the game starts a new id after DELETE.
  const again = await http("POST", "/v2/account/authenticate/device?create=true", null, { id: me.device });
  assert.equal(again.status, 403, JSON.stringify(again.body));
  assert.equal(again.body.message, "device_logged_out");
  ms.close();
});

test("delete_account: the owner deletes by name without a session (the HTTP key, and the console's API Explorer)", async () => {
  const a = await player();
  const c = await ownerRpc("delete_account", { username: a.name.toUpperCase() });
  assert.equal(c.ok, true, JSON.stringify(c));
  assert.equal(c.user_id, a.id);
  assert.equal((await ownerRpc("delete_account", { username: a.name, confirm: c.confirm })).deleted, true);
  assert.equal((await consoleApi("GET", "/v2/console/account/" + a.id)).status, 404);

  const b = await player();
  const explorer = async (body: Json): Promise<Json> => {
    const r = await consoleApi("POST", "/v2/console/api/endpoints/rpc/delete_account", { body: JSON.stringify(body), user_id: "" });
    assert.equal(r.status, 200, JSON.stringify(r.body));
    return JSON.parse(r.body.body);
  };
  const step = await explorer({ username: b.name });
  assert.equal(step.user_id, b.id, JSON.stringify(step));
  assert.equal((await explorer({ username: b.name, confirm: step.confirm })).deleted, true);
  assert.equal((await consoleApi("GET", "/v2/console/account/" + b.id)).status, 404);
});

test("Nakama's own DELETE /v2/account is refused: the game uses delete_account", async () => {
  const p = await player();
  const r = await http("DELETE", "/v2/account", p.token);
  assert.notEqual(r.status, 200);
  assert.equal(r.body.message, "use_delete_account", JSON.stringify(r.body));
  assert.equal((await consoleApi("GET", "/v2/console/account/" + p.id)).status, 200);
});

test("a sign-in records itself (server only) and the day's clean-up has run", async () => {
  const p = await player();
  const seen = await stored("activity", "signed_in", p.id);
  assert.ok(seen, "activity/signed_in");
  assert.ok(Math.abs(seen!.value.at_ms - Date.now()) < 60_000, JSON.stringify(seen));
  assert.equal(seen!.permission_read, 0);
  const guard = await stored("activity", "retention", SYSTEM);
  assert.ok(guard && Number.isInteger(guard.value.last_run_ms), JSON.stringify(guard));
  assert.equal(guard!.value.result.error, undefined, "the clean-up's SQL runs on this PostgreSQL: " + JSON.stringify(guard!.value));
});

test("retention_run: only the owner; an account quiet for 13 months is deleted, a report about it stays", async () => {
  const p = await player();
  assert.deepEqual(await rpc(p, "retention_run", {}), { ok: false, error: "not_allowed" });
  const quiet = await player();
  const r0 = await consoleApi("PUT", `/v2/console/storage/activity/signed_in/${quiet.id}`, {
    value: JSON.stringify({ at_ms: Date.now() - 14 * MONTH }), permission_read: 0, permission_write: 0,
  });
  assert.equal(r0.status, 200, JSON.stringify(r0.body));
  const r = await ownerRpc("retention_run", {});
  assert.equal(r.ok, true, JSON.stringify(r));
  assert.ok(r.accounts >= 1, JSON.stringify(r));
  for (const k of ["messages", "orphan_notifications", "orphan_messages", "reports_deleted", "reports_stamped", "report_windows"]) {
    assert.ok(Number.isInteger(r[k]), k);
  }
  assert.equal((await consoleApi("GET", "/v2/console/account/" + quiet.id)).status, 404, "13 months without a sign-in");
  assert.equal((await consoleApi("GET", "/v2/console/account/" + p.id)).status, 200);
});

test("report_user: a reported team-room message is kept with the report from the server's own copy", async () => {
  const host = await player("13_plus", "Host");
  const guest = await player("13_plus", "Guest");
  await befriend(host, guest);
  const hs = new Socket(host);
  const matchId = (await hs.send({ match_create: {} })).match.match_id as string;
  const room = await hs.send({ channel_join: { target: matchId, type: 1, persistence: false, hidden: false } });
  assert.equal((await rpc(host, "invite_friend", { user_id: guest.id, match_id: matchId })).ok, true);
  const gs = new Socket(guest);
  assert.equal((await gs.send({ match_join: { match_id: matchId } })).match?.match_id, matchId);
  assert.ok((await gs.send({ channel_join: { target: matchId, type: 1, persistence: false, hidden: false } })).channel);
  const ack = await hs.send({ channel_message_send: { channel_id: room.channel.id, content: JSON.stringify({ text: "you   build badly" }) } });
  assert.ok(ack.channel_message_ack?.message_id, JSON.stringify(ack));
  const heard = await gs.message();
  assert.equal(heard.message_id, ack.channel_message_ack.message_id);
  assert.deepEqual(await rpc(guest, "report_user", {
    user_id: host.id, reason: "mean_words", channel_id: heard.channel_id, message_id: heard.message_id,
    message: { text: "(as the guest's game showed it)", at_ms: Date.now() },
  }), { ok: true });
  const reports = (await storageOf(SYSTEM, "reports")).filter((o) => o.key.endsWith("_" + guest.id));
  assert.equal(reports.length, 1);
  const v = (await stored("reports", reports[0].key, SYSTEM))!.value;
  assert.equal(v.message_id, heard.message_id);
  assert.equal(v.message.source, "server", JSON.stringify(v));
  assert.equal(v.message.text, "you build badly", "what the server passed on, cleaned");
  assert.ok(Math.abs(v.message.at_ms - Date.now()) < 60_000);
  hs.close();
  gs.close();
});
