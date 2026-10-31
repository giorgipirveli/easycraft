// The module against a REAL Nakama (plan M4 Wave 1, agent B): every RPC and hook through the HTTP
// API and the realtime socket, as the game uses them. Not part of `npm test` (it needs a server):
//
//   EASYCRAFT_SERVER=http://127.0.0.1:7350 npm run test:server        # the development server
//
// The server must run this module with server/nakama/local.yml's switches (the fake consent
// provider with its 2 s delay, EASYCRAFT_DEV_OPEN_MATCHES=true). Every run makes new accounts with
// random device ids, so it can run again on the same database.
import { test, after } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";

const BASE = (process.env.EASYCRAFT_SERVER || "http://127.0.0.1:7350").replace(/\/$/, "");
const CONSOLE = process.env.EASYCRAFT_CONSOLE || BASE.replace(/:(\d+)$/, (_m, p) => ":" + (Number(p) + 1));
const WS = BASE.replace(/^http/, "ws");
const SERVER_KEY = "Basic " + Buffer.from("defaultkey:").toString("base64");
const FIRST_CODE = "sasa192974"; // only in tests; the module holds its hash
const TAG = Date.now().toString(36).slice(-5);

type Json = { [key: string]: any };

interface Player {
  id: string;
  token: string;
  name: string;
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

async function signIn(username?: string): Promise<{ status: number; body: Json }> {
  const q = "create=true" + (username ? "&username=" + encodeURIComponent(username) : "");
  return http("POST", "/v2/account/authenticate/device?" + q, null, { id: "itest-" + randomUUID() });
}

async function rpc(p: Player, id: string, payload: Json = {}): Promise<Json> {
  const r = await http("POST", "/v2/rpc/" + id, p.token, JSON.stringify(payload));
  assert.equal(r.status, 200, id + ": " + JSON.stringify(r.body));
  return JSON.parse(r.body.payload);
}

let counter = 0;

// A new account; with a band, it claims a username ("<prefix><tag><n>").
async function player(band?: string, prefix = "It"): Promise<Player> {
  const r = await signIn();
  assert.equal(r.status, 200, JSON.stringify(r.body));
  const token = r.body.token as string;
  const id = JSON.parse(Buffer.from(token.split(".")[1], "base64url").toString()).uid as string;
  const p: Player = { id, token, name: "" };
  if (band) {
    p.name = prefix + TAG + ++counter;
    const claim = await rpc(p, "claim_username", { username: p.name, age_band: band });
    assert.equal(claim.ok, true, JSON.stringify(claim));
  }
  return p;
}

// An under_13 player whose (fake) parent said yes.
async function consentedKid(): Promise<Player> {
  const kid = await player("under_13", "Kid");
  assert.equal((await rpc(kid, "consent_start", {})).consent, "pending");
  await new Promise((done) => setTimeout(done, 2200));
  const r = await rpc(kid, "consent_status", {});
  assert.equal(r.consent, "verified", JSON.stringify(r));
  return kid;
}

// (M4 Wave 2, agent F: an under-13 player's side waits for a grown-up's yes, given through approve_friend.)
async function befriend(a: Player, b: Player): Promise<void> {
  for (const [from, to] of [[a, b], [b, a]]) {
    const r = await http("POST", "/v2/friend?ids=" + to.id, from.token);
    if (r.status === 403 && r.body.message === "needs_grown_up") {
      assert.equal((await rpc(from, "approve_friend", { user_id: to.id, approve: true })).ok, true);
    } else {
      assert.equal(r.status, 200, JSON.stringify(r.body));
    }
  }
}

const openSockets: Socket[] = [];

// Sockets left open (a failed test) would keep the run from ending.
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

  async notification(code: number, timeoutMs = 3000): Promise<Json> {
    const end = Date.now() + timeoutMs;
    while (Date.now() < end) {
      for (const e of this.events) {
        for (const n of e.notifications?.notifications || []) {
          if (n.code === code) {
            return { ...n, content: JSON.parse(n.content) };
          }
        }
      }
      await new Promise((done) => setTimeout(done, 50));
    }
    throw new Error("no notification " + code);
  }

  close(): void {
    this.ws.close();
  }
}

test("the module is loaded", async () => {
  const p = await player();
  const r = await rpc(p, "healthcheck");
  assert.equal(r.ok, true);
  assert.equal(r.module, "easycraft");
  assert.equal(r.version, "0.2.20");
});

test("claim_username: unique whatever the case; Nakama's own paths run the filter too", async () => {
  const a = await player("13_plus");
  const b = await player();
  assert.deepEqual(await rpc(b, "claim_username", { username: a.name.toUpperCase(), age_band: "13_plus" }), { ok: false, error: "taken" });
  assert.deepEqual(await rpc(b, "claim_username", { username: "BigDick", age_band: "13_plus" }), { ok: false, error: "blocked_word" });
  const upd = await http("PUT", "/v2/account", b.token, { username: "iamstupid" });
  assert.equal(upd.status, 400);
  assert.equal(upd.body.message, "blocked_word");
  const upd2 = await http("PUT", "/v2/account", b.token, { username: a.name.toLowerCase() });
  assert.equal(upd2.body.message, "taken");
  const display = await http("PUT", "/v2/account", b.token, { display_name: "call me 5551234567" });
  assert.equal(display.body.message, "field_not_allowed");
  const bad = await signIn("Hitler_1");
  assert.equal(bad.status, 400);
  assert.equal(bad.body.message, "blocked_word");
});

test("get_account_state and set_parent_settings: defaults, the parent's switches, the rules", async () => {
  const kid = await player("under_13");
  const s = await rpc(kid, "get_account_state");
  assert.equal(s.age_band, "under_13");
  assert.equal(s.can_play_online, false);
  assert.equal(s.consent_available, true, "the development server has the fake provider");
  assert.deepEqual(await rpc(kid, "set_parent_settings", { online_allowed: true }), { ok: false, error: "consent_needed" });
  const teen = await player("13_plus");
  const off = await rpc(teen, "set_parent_settings", { online_allowed: false });
  assert.equal(off.can_play_online, false);
  assert.equal((await rpc(teen, "set_parent_settings", { chat: "quick" })).chat, "quick");
  const stored = await http("GET", `/v2/storage/parent?user_id=${teen.id}&limit=10`, teen.token);
  assert.equal(stored.status, 200);
  const settings = (stored.body.objects || []).find((o: Json) => o.key === "settings");
  assert.ok(settings, "the game can read its parent settings");
  assert.equal(JSON.parse(settings.value).history.length, 2, "a stored list read back and grown on the server");
});

test("consent (fake provider): pending, then verified 2 s later, with notification 103", async () => {
  const kid = await player("under_13");
  const start = await rpc(kid, "consent_start", { parent_contact: "not-stored@example.com" });
  assert.equal(start.consent, "pending");
  assert.equal((await rpc(kid, "consent_status")).consent, "pending");
  await new Promise((done) => setTimeout(done, 2200));
  const done = await rpc(kid, "consent_status");
  assert.equal(done.consent, "verified");
  assert.equal(done.can_play_online, true);
  assert.equal(done.chat_level, "quick");
  const notes = await http("GET", "/v2/notification?limit=10", kid.token);
  assert.ok((notes.body.notifications || []).some((n: Json) => n.code === 103), JSON.stringify(notes.body));
});

test("friends: found by name whatever the case; a child without consent is never found", async () => {
  const teen = await player("13_plus");
  const kid = await consentedKid();
  const hidden = await player("under_13", "Hid");
  const found = await http("GET", "/v2/user?usernames=" + kid.name.toLowerCase(), teen.token);
  assert.deepEqual((found.body.users || []).map((u: Json) => u.id), [kid.id]);
  const notFound = await http("GET", `/v2/user?usernames=${hidden.name}&ids=${hidden.id}`, teen.token);
  assert.deepEqual(notFound.body.users || [], []);
  assert.equal((await http("POST", "/v2/friend?usernames=" + kid.name.toUpperCase(), teen.token)).status, 200);
  const refused = await http("POST", "/v2/friend?usernames=" + hidden.name, teen.token);
  assert.equal(refused.status, 404);
  assert.equal(refused.body.message, "not_found");
  const fromHidden = await http("POST", "/v2/friend?ids=" + teen.id, hidden.token);
  assert.equal(fromHidden.body.message, "not_allowed_online");
});

test("host wallets: the host reads and reports a guest's gold in its match, nobody else's (M4 F)", async () => {
  const host = await player("13_plus", "Hwal");
  const guest = await player("13_plus", "Gwal");
  const stranger = await player("13_plus", "Swal");
  await befriend(host, guest);
  const hs = new Socket(host);
  const created = await hs.send({ match_create: {} });
  const matchId = created.match.match_id as string;
  assert.equal((await rpc(host, "invite_friend", { user_id: guest.id, match_id: matchId })).ok, true);
  const gs = new Socket(guest);
  const joined = await gs.send({ match_join: { match_id: matchId } });
  assert.equal(joined.match?.match_id, matchId, JSON.stringify(joined));
  assert.deepEqual(await rpc(host, "get_gold_of", { user_id: guest.id, match_id: matchId }), { ok: true, user_id: guest.id, gold: 0 });
  assert.deepEqual(await rpc(host, "wallet_award", { amount: 40, reason: "wave", user_id: guest.id, match_id: matchId }),
    { ok: true, credited: 40, capped: false, gold: 40 });
  assert.equal((await rpc(guest, "get_account_state")).gold, 40, "the guest's own balance on the server");
  assert.equal((await rpc(host, "get_gold_of", { user_id: stranger.id, match_id: matchId })).error, "not_in_match");
  assert.equal((await rpc(guest, "wallet_award", { amount: 5, user_id: host.id, match_id: matchId })).error, "not_host");
  hs.close();
  gs.close();
});

// 0.2.19 (docs/devlog/parts/gold-double.md): the host's last batch for a guest who has left still lands (it carries a
// seq), and the guest's account tells the game the host's last word (get_account_state's "hosted").
test("host wallets: the host's last batch for a guest who left lands with its seq; hosted tells the guest (0.2.19)", async () => {
  const host = await player("13_plus", "Hseq");
  const guest = await player("13_plus", "Gseq");
  await befriend(host, guest);
  const hs = new Socket(host);
  const matchId = (await hs.send({ match_create: {} })).match.match_id as string;
  assert.equal((await rpc(host, "invite_friend", { user_id: guest.id, match_id: matchId })).ok, true);
  const gs = new Socket(guest);
  const joined = await gs.send({ match_join: { match_id: matchId } });
  assert.equal(joined.match?.match_id, matchId, JSON.stringify(joined));
  assert.equal((await rpc(host, "get_gold_of", { user_id: guest.id, match_id: matchId })).gold, 0);
  assert.deepEqual((await rpc(guest, "get_account_state")).hosted, { match_id: matchId, seq: 0 });
  assert.deepEqual(await rpc(host, "wallet_award", { amount: 40, reason: "wave", user_id: guest.id, match_id: matchId, seq: 2 }),
    { ok: true, credited: 40, capped: false, gold: 40, seq: 2 });
  await gs.send({ match_leave: { match_id: matchId } });
  gs.close();
  assert.equal((await rpc(host, "wallet_award", { amount: 7, user_id: guest.id, match_id: matchId })).error, "not_in_match",
    "without a seq: as before");
  assert.deepEqual(await rpc(host, "wallet_award", { amount: 7, reason: "wave", user_id: guest.id, match_id: matchId, seq: 3 }),
    { ok: true, credited: 7, capped: false, gold: 47, seq: 3 }, "the batch the host flushed when the guest left");
  hs.close(); // the host closes its world too: what it still held goes after
  assert.deepEqual(await rpc(host, "wallet_award", { amount: 0, user_id: guest.id, match_id: matchId, seq: 4 }),
    { ok: true, credited: 0, capped: false, gold: 47, seq: 4 });
  const state = await rpc(guest, "get_account_state");
  assert.equal(state.gold, 47);
  assert.deepEqual(state.hosted, { match_id: matchId, seq: 4 });
});

// 0.2.19: a phone whose answer was lost asks again; the server says it paid the code, and when.
test("economy: a code the server paid answers already_used with what it paid; a record of it says so too (0.2.19)", async () => {
  const p = await player("13_plus", "Cpaid");
  assert.equal((await rpc(p, "redeem_code", { code: FIRST_CODE })).status, "accepted");
  const again = await rpc(p, "redeem_code", { code: FIRST_CODE });
  assert.equal(again.error, "already_used");
  assert.equal(again.paid.gold, 1000);
  assert.ok(Math.abs(again.paid.at_ms - Date.now()) < 120_000, JSON.stringify(again));
  const hash = "a59f43a363322b8e2604d1c43fcb5005cf099fdf8e4230fb593e8a918ec46f0a";
  const rec = await rpc(p, "redeem_code", { hashes: [hash] });
  assert.deepEqual(rec.paid, [{ hash: hash, gold: 1000, at_ms: again.paid.at_ms }]);
  assert.equal(rec.gold, 1000, "nothing paid twice");
});

test("match_players: the host learns its players' names, bands and chat levels from the server (0.2.11)", async () => {
  const host = await player("13_plus", "Hmp");
  const kid = await consentedKid();
  await befriend(host, kid);
  const hs = new Socket(host);
  const matchId = (await hs.send({ match_create: {} })).match.match_id as string;
  assert.equal((await rpc(host, "invite_friend", { user_id: kid.id, match_id: matchId })).ok, true);
  const ks = new Socket(kid);
  const joined = await ks.send({ match_join: { match_id: matchId } });
  assert.equal(joined.match?.match_id, matchId, JSON.stringify(joined));
  const r = await rpc(host, "match_players", { match_id: matchId });
  assert.equal(r.ok, true, JSON.stringify(r));
  const byId: Json = {};
  for (const p of r.players) {
    byId[p.user_id] = p;
  }
  assert.deepEqual(byId[kid.id], { user_id: kid.id, username: kid.name, age_band: "under_13", chat_level: "quick" });
  assert.equal(byId[host.id].age_band, "13_plus");
  assert.equal((await rpc(kid, "match_players", { match_id: matchId })).error, "not_host", "only the host");
  hs.close();
  ks.close();
});

test("invites: notification 101, the invited friend joins, strangers and a 5th player can't", async () => {
  const host = await player("13_plus", "Host");
  const kid = await consentedKid();
  const stranger = await player("13_plus");
  const pals = [await player("13_plus"), await player("13_plus"), await player("13_plus")];
  await befriend(host, kid);
  for (const p of pals) {
    await befriend(host, p);
  }
  const hs = new Socket(host);
  const created = await hs.send({ match_create: {} });
  const matchId = created.match.match_id as string;

  const ss = new Socket(stranger);
  const refused = await ss.send({ match_join: { match_id: matchId } });
  assert.equal(refused.error?.message, "not_invited", JSON.stringify(refused));

  const ks = new Socket(kid);
  await ks.ready;
  const inv = await rpc(host, "invite_friend", { username: kid.name.toLowerCase(), match_id: matchId, world_name: "Castle Hill" });
  assert.equal(inv.ok, true, JSON.stringify(inv));
  const note = await ks.notification(101);
  assert.deepEqual(note.content, { match_id: matchId, from_username: host.name, from_user_id: host.id, world_name: "Castle Hill" });
  assert.equal(note.sender_id, host.id);
  const joined = await ks.send({ match_join: { match_id: matchId } });
  assert.equal(joined.match?.match_id, matchId, JSON.stringify(joined));

  assert.deepEqual(await rpc(host, "invite_friend", { user_id: stranger.id, match_id: matchId }), { ok: false, error: "not_friends" });
  assert.deepEqual(await rpc(kid, "invite_friend", { user_id: host.id, match_id: matchId }), { ok: false, error: "not_host" });

  const sockets = [hs, ss, ks];
  for (const p of pals.slice(0, 2)) {
    assert.equal((await rpc(host, "invite_friend", { user_id: p.id, match_id: matchId })).ok, true);
    const s = new Socket(p);
    sockets.push(s);
    assert.equal((await s.send({ match_join: { match_id: matchId } })).match?.match_id, matchId);
  }
  assert.deepEqual(await rpc(host, "invite_friend", { user_id: pals[2].id, match_id: matchId }), { ok: false, error: "match_full" });
  const fifth = new Socket(pals[2]);
  sockets.push(fifth);
  const full = await fifth.send({ match_join: { match_id: matchId } });
  assert.equal(full.error?.message, "match_full", "the cap is checked first, invited or not");
  sockets.forEach((s) => s.close());
});

test("invites: a developer account (no username) joins by match id on the development server", async () => {
  const host = await player();
  const guest = await player();
  const hs = new Socket(host);
  const matchId = (await hs.send({ match_create: {} })).match.match_id;
  const gs = new Socket(guest);
  assert.equal((await gs.send({ match_join: { match_id: matchId } })).match?.match_id, matchId);
  hs.close();
  gs.close();
});

test("matchmaking is switched off", async () => {
  const p = await player("13_plus");
  const s = new Socket(p);
  const r = await s.send({ matchmaker_add: { min_count: 2, max_count: 4, query: "*" } });
  assert.equal(r.error?.message, "not_available");
  s.close();
});

test("chat: a DM between a teen and an under-13 carries quick phrases only; public rooms are closed", async () => {
  const teen = await player("13_plus");
  const kid = await consentedKid();
  await befriend(teen, kid);
  const ts = new Socket(teen);
  const ch = await ts.send({ channel_join: { target: kid.id, type: 2, persistence: false, hidden: false } });
  assert.ok(ch.channel?.id, JSON.stringify(ch));
  const free = await ts.send({ channel_message_send: { channel_id: ch.channel.id, content: JSON.stringify({ text: "want to build a castle?" }) } });
  assert.equal(free.error?.message, "quick_chat_only");
  const quick = await ts.send({ channel_message_send: { channel_id: ch.channel.id, content: JSON.stringify({ text: " Hi! " }) } });
  assert.ok(quick.channel_message_ack, JSON.stringify(quick));
  const lobby = await ts.send({ channel_join: { target: "lobby", type: 1, persistence: false, hidden: false } });
  assert.equal(lobby.error?.message, "room_not_allowed");
  ts.close();
});

test("chat: a match's team room takes the strictest level of the players in it", async () => {
  const host = await player("13_plus");
  const kid = await consentedKid();
  await befriend(host, kid);
  const hs = new Socket(host);
  const matchId = (await hs.send({ match_create: {} })).match.match_id as string;
  const room = await hs.send({ channel_join: { target: matchId, type: 1, persistence: false, hidden: false } });
  assert.ok(room.channel?.id, JSON.stringify(room));
  const free = JSON.stringify({ text: "who wants to build a tower?" });
  assert.ok((await hs.send({ channel_message_send: { channel_id: room.channel.id, content: free } })).channel_message_ack,
    "only a 13_plus player in the room: filtered free text");
  assert.equal((await rpc(host, "invite_friend", { user_id: kid.id, match_id: matchId })).ok, true);
  const ks = new Socket(kid);
  assert.equal((await ks.send({ match_join: { match_id: matchId } })).match?.match_id, matchId);
  assert.ok((await ks.send({ channel_join: { target: matchId, type: 1, persistence: false, hidden: false } })).channel);
  const refused = await hs.send({ channel_message_send: { channel_id: room.channel.id, content: free } });
  assert.equal(refused.error?.message, "quick_chat_only", "an under_13 player is in the room now");
  const quick = await hs.send({ channel_message_send: { channel_id: room.channel.id, content: JSON.stringify({ text: "Wow!" }) } });
  assert.ok(quick.channel_message_ack);
  hs.close();
  ks.close();
});

test("storage: a game writes its profile backup only", async () => {
  const p = await player("13_plus");
  const sneaky = await http("PUT", "/v2/storage", p.token, { objects: [{ collection: "parent", key: "consent", value: '{"status":"verified"}' }] });
  assert.equal(sneaky.status, 403);
  assert.equal(sneaky.body.message, "not_allowed");
  const ok = await http("PUT", "/v2/storage", p.token, { objects: [{ collection: "profiles", key: "profile", value: '{"version":1}' }] });
  assert.equal(ok.status, 200, JSON.stringify(ok.body));
  // Owner #67 (module 0.2.12): one object only, and a profile at that.
  const other = await http("PUT", "/v2/storage", p.token, { objects: [{ collection: "profiles", key: "backup", value: '{"version":1}' }] });
  assert.equal(other.status, 403);
  const broken = await http("PUT", "/v2/storage", p.token, { objects: [{ collection: "profiles", key: "profile", value: '{"v":1}' }] });
  assert.equal(broken.status, 400);
  assert.equal(broken.body.message, "bad_profile");
});

test("economy: the first code once, the farm by the server clock, wallet awards", async () => {
  const p = await player("13_plus");
  assert.deepEqual(await rpc(p, "redeem_code", { code: " " + FIRST_CODE.toUpperCase() }),
    { ok: true, status: "accepted", reward: { kind: "gold", amount: 1000 }, gold: 1000 });
  assert.equal((await rpc(p, "redeem_code", { code: FIRST_CODE })).error, "already_used");
  assert.equal((await rpc(p, "get_account_state")).gold, 1000);
  assert.equal((await rpc(p, "farm_collect", { action: "start", world: "survivor_u1", rate_per_hour: 100 })).ok, true);
  const peek = await rpc(p, "farm_collect", { action: "peek", world: "survivor_u1" });
  assert.equal(peek.ok, true);
  assert.ok(peek.away_ms >= 0 && peek.away_ms < 60_000);
  const got = await rpc(p, "farm_collect", { action: "collect", world: "survivor_u1" });
  assert.equal(got.ok, true);
  assert.deepEqual(await rpc(p, "farm_collect", { action: "collect", world: "survivor_u1" }), { ok: false, error: "not_started" });
  const award = await rpc(p, "wallet_award", { amount: 120, reason: "wave" });
  assert.equal(award.gold, 1000 + got.earned + 120);
  const ledger = await http("GET", "/v2/account", p.token);
  assert.equal(JSON.parse(ledger.body.wallet).survivor_gold, award.gold);
});

test("wallet_award: the hourly limit holds across calls (a stored window read back)", async () => {
  const p = await player("13_plus");
  let total = 0;
  let last: Json = {};
  for (let i = 0; i < 12 && last.error === undefined; i++) {
    last = await rpc(p, "wallet_award", { amount: 2000, reason: "boss" });
    total += last.credited || 0;
  }
  assert.equal(total, 20000);
  assert.deepEqual(last, { ok: false, error: "limit" });
});

test("report_user: the report reaches the Nakama console", async () => {
  const me = await player("13_plus");
  const bad = await player("13_plus", "Bad");
  assert.deepEqual(await rpc(me, "report_user", { username: bad.name, reason: "mean_words" }), { ok: true });
  const login = await fetch(CONSOLE + "/v2/console/authenticate", {
    method: "POST", headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ username: "admin", password: process.env.EASYCRAFT_CONSOLE_PASSWORD || "easycraft-dev" }),
  });
  const consoleToken = (await login.json()).token;
  const list = await fetch(`${CONSOLE}/v2/console/storage?collection=reports&user_id=00000000-0000-0000-0000-000000000000`,
    { headers: { Authorization: "Bearer " + consoleToken } });
  const objects = ((await list.json()).objects || []) as Json[];
  const mine = objects.filter((o) => o.key.endsWith("_" + me.id));
  assert.equal(mine.length, 1, JSON.stringify(objects.slice(0, 3)));
  const detail = await fetch(`${CONSOLE}/v2/console/storage/reports/${encodeURIComponent(mine[0].key)}/00000000-0000-0000-0000-000000000000`,
    { headers: { Authorization: "Bearer " + consoleToken } });
  const value = JSON.parse((await detail.json()).value);
  assert.equal(value.reported_id, bad.id);
  assert.equal(value.reason, "mean_words");
  assert.equal(value.status, "new");
});

test("chat history (agent E): kept for two teens with text chat, never with quick chat or in a team room", async () => {
  const a = await player("13_plus");
  const b = await player("13_plus");
  const q = await player("13_plus");
  assert.equal((await rpc(q, "set_parent_settings", { chat: "quick" })).chat, "quick");
  await befriend(a, b);
  await befriend(a, q);
  const s = new Socket(a);
  const ab = await s.send({ channel_join: { target: b.id, type: 2, persistence: true, hidden: false } });
  assert.ok(ab.channel?.id, JSON.stringify(ab));
  const kept = await s.send({ channel_message_send: { channel_id: ab.channel.id, content: JSON.stringify({ text: "see you tomorrow" }) } });
  assert.equal(kept.channel_message_ack?.persistent, true, JSON.stringify(kept));
  const listAb = await http("GET", "/v2/channel/" + encodeURIComponent(ab.channel.id) + "?limit=10", b.token);
  assert.equal((listAb.body.messages || []).length, 1, JSON.stringify(listAb.body));
  const aq = await s.send({ channel_join: { target: q.id, type: 2, persistence: true, hidden: false } });
  assert.ok(aq.channel?.id, JSON.stringify(aq));
  const gone = await s.send({ channel_message_send: { channel_id: aq.channel.id, content: JSON.stringify({ text: "Hi!" }) } });
  assert.ok(gone.channel_message_ack, JSON.stringify(gone));
  assert.notEqual(gone.channel_message_ack.persistent, true, "quick chat: nothing kept, whatever the game asked");
  const listAq = await http("GET", "/v2/channel/" + encodeURIComponent(aq.channel.id) + "?limit=10", q.token);
  assert.equal((listAq.body.messages || []).length, 0, JSON.stringify(listAq.body));
  const hostSocket = new Socket(a);
  const created = await hostSocket.send({ match_create: {} });
  const matchId = created.match?.match_id as string;
  assert.ok(matchId, JSON.stringify(created));
  const room = await hostSocket.send({ channel_join: { target: matchId, type: 1, persistence: true, hidden: false } });
  assert.ok(room.channel?.id, JSON.stringify(room));
  const roomAck = await hostSocket.send({ channel_message_send: { channel_id: room.channel.id, content: JSON.stringify({ text: "Wow!" }) } });
  assert.notEqual(roomAck.channel_message_ack?.persistent, true, "team rooms keep nothing");
  s.close();
  hostSocket.close();
});
